import re

with open('c:/Hansuke/Work/raheeq_main/lib/pages/home/pages/specific_mosque_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace _selectedItem with _selectedItemsList
content = content.replace('Place? _selectedItem;', 'final List<Place> _selectedItemsList = [];')
content = content.replace('if (_selectedItem != null)', '')

# 2. Add favorite variables and methods
init_state_idx = content.find('void initState() {')
favorites_code = '''List<String> _favoriteMosqueIds = [];

  Future<void> _fetchFavorites() async {
    try {
      final response = await _apiService.getFavoriteMosques();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _favoriteMosqueIds = data.map((e) => e['mosqueId'].toString()).toList();
          });
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final isFav = _favoriteMosqueIds.contains(id);
    setState(() {
      if (isFav) {
        _favoriteMosqueIds.remove(id);
      } else {
        _favoriteMosqueIds.add(id);
      }
    });

    try {
      if (isFav) {
        await _apiService.deleteFavoriteMosque(id);
      } else {
        await _apiService.addFavoriteMosque(id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isFav) {
            _favoriteMosqueIds.add(id);
          } else {
            _favoriteMosqueIds.remove(id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite.')),
        );
      }
    }
  }

  @override
  '''
content = content.replace('@override\n  void initState() {', favorites_code + 'void initState() {\n    _fetchFavorites();')

# 3. Add bottom bar to the main view
bottom_bar_insertion = '''
          Expanded(
            child: Column(
'''
content = content.replace('Expanded(\n            child: Column(', 'Expanded(\n            child: Column(')

# Wait, we can just replace the end of the build method
end_of_build = '''                ),
              ],
            ),
          ),
        ],
      ),
    );'''

new_end_of_build = '''                ),
              ],
            ),
          ),
          if (_selectedItemsList.isNotEmpty) _buildBottomBar(isAr),
        ],
      ),
    );'''
content = content.replace(end_of_build, new_end_of_build)


# 4. Modify _buildListTab card onTap
old_on_tap = '''            onTap: () {
              Navigator.of(context).pop(item);
            },'''
new_on_tap = '''            onTap: () {
              setState(() {
                if (_selectedItemsList.any((m) => m.id == item.id)) {
                  _selectedItemsList.removeWhere((m) => m.id == item.id);
                } else {
                  _selectedItemsList.add(item);
                }
              });
            },'''
content = content.replace(old_on_tap, new_on_tap)

# 5. Modify Card UI in _buildListTab
old_card_start = '''        return Card(
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          elevation: 3,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),'''
new_card_start = '''        final isSelected = _selectedItemsList.any((m) => m.id == item.id);
        return Card(
          clipBehavior: Clip.antiAlias,
          color: isSelected ? const Color(0xFFE8F4FA) : Colors.white,
          elevation: isSelected ? 5 : 3,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.buttonBlue : Colors.transparent,
              width: 2,
            ),
          ),'''
content = content.replace(old_card_start, new_card_start)

# 6. Add Heart icon in Card
expanded_col_end = '''                                  ),
                              ],
                            ),
                          ),'''
new_expanded_col_end = '''                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _favoriteMosqueIds.contains(item.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _favoriteMosqueIds.contains(item.id)
                                  ? Colors.redAccent
                                  : Colors.grey,
                            ),
                            onPressed: () => _toggleFavorite(item.id),
                          ),'''
content = content.replace(expanded_col_end, new_expanded_col_end)


# 7. Modify _buildMapTab marker onTap and icon
old_marker = '''      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(207.0),
        infoWindow: InfoWindow(
          title: item.localizedName(isAr),
          snippet: item.address,
        ),
        onTap: () {
          setState(() {
            _selectedItem = item;
          });
        },
      );'''
new_marker = '''      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            _selectedItemsList.any((m) => m.id == item.id) ? BitmapDescriptor.hueGreen : 207.0),
        infoWindow: InfoWindow(
          title: item.localizedName(isAr),
          snippet: item.address,
        ),
        onTap: () {
          setState(() {
            if (_selectedItemsList.any((m) => m.id == item.id)) {
              _selectedItemsList.removeWhere((m) => m.id == item.id);
            } else {
              _selectedItemsList.add(item);
            }
          });
        },
      );'''
content = content.replace(old_marker, new_marker)

# 8. Remove Positioned from _buildMapTab
# I'll use regex to remove it
import re
content = re.sub(r'        if \(_selectedItem != null\).*?                \],\n              \),\n            \),\n          \),', '', content, flags=re.DOTALL)


# 9. Add _buildBottomBar at the end of the class
bottom_bar_method = '''

  Widget _buildBottomBar(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedItemsList.length,
              itemBuilder: (context, index) {
                final item = _selectedItemsList[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.buttonBlue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.localizedName(isAr),
                        style: const TextStyle(
                          color: AppColors.buttonBlueDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedItemsList.remove(item);
                          });
                        },
                        child: const Icon(Icons.close, size: 16, color: AppColors.buttonBlueDark),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedItemsList.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(isAr ? '??? ????' : 'Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedItemsList);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isAr ? '????? ????????' : 'Confirm Selection',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
'''
content = content.replace('}\n', bottom_bar_method, 1) if content.endswith('}\n') else content[:-1] + bottom_bar_method

with open('c:/Hansuke/Work/raheeq_main/lib/pages/home/pages/specific_mosque_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done writing")
