import re

with open('c:/Hansuke/Work/raheeq_main/lib/pages/home/pages/saved_mosques_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add _selectedItemsList
content = content.replace('List<Place> _savedMosques = [];', 'List<Place> _savedMosques = [];\n  List<Place> _selectedItemsList = [];')

# Replace _addToOrder with _toggleSelection and _confirmSelection
old_add_to_order = '''  void _addToOrder(Place item) {
    // Find the real Category from HomeTab cache if available
    final realCategory = HomeTab.cachedCategories.firstWhere(
      (c) => c.slug == 'mosques',
      orElse: () => _mosquesCategory,
    );

    // Queue the item into HomeTab's pending list
    HomeTab.scheduleMosqueItem(
      SelectedCategoryItem(
        category: realCategory,
        optionType: 'specific',
        specificData: item,
      ),
    );

    // Switch the bottom nav to the Home tab (index 0)
    HomeScreen.switchTabNotifier.value = 0;

    // Pop all routes back to the HomeScreen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }'''

new_add_to_order = '''  void _toggleSelection(Place item) {
    setState(() {
      if (_selectedItemsList.any((m) => m.id == item.id)) {
        _selectedItemsList.removeWhere((m) => m.id == item.id);
      } else {
        _selectedItemsList.add(item);
      }
    });
  }

  void _confirmSelection() {
    final realCategory = HomeTab.cachedCategories.firstWhere(
      (c) => c.slug == 'mosques',
      orElse: () => _mosquesCategory,
    );

    for (var item in _selectedItemsList) {
      HomeTab.scheduleMosqueItem(
        SelectedCategoryItem(
          category: realCategory,
          optionType: 'specific',
          specificData: item,
        ),
      );
    }

    HomeScreen.switchTabNotifier.value = 0;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }'''

content = content.replace(old_add_to_order, new_add_to_order)

# Update Card in build method
old_card_start = '''                      return Card(
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: () => _addToOrder(item),'''

new_card_start = '''                      final isSelected = _selectedItemsList.any((m) => m.id == item.id);
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
                        ),
                        child: InkWell(
                          onTap: () => _toggleSelection(item),'''

content = content.replace(old_card_start, new_card_start)


# Update bottom nav bar logic
end_of_build = '''          ),
        ],
      ),
    );
  }
}'''

new_end_of_build = '''          ),
          if (_selectedItemsList.isNotEmpty) _buildBottomBar(isAr),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
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
                        onTap: () => _toggleSelection(item),
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
                  child: Text(isAr ? 'مسح الكل' : 'Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBlueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isAr ? 'متابعة' : 'Continue',
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
}'''

content = content.replace(end_of_build, new_end_of_build)


with open('c:/Hansuke/Work/raheeq_main/lib/pages/home/pages/saved_mosques_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

