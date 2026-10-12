import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/meqat_mosque.dart';
import 'package:raheeq_main/models/orphanage.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:shimmer/shimmer.dart';

// The page size the place page's list asks for.
const int _pageSize = 1000;

const SliverGridDelegate _gridDelegate =
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );
const EdgeInsets _gridPadding = EdgeInsets.fromLTRB(16, 0, 16, 8);

/// Picks specific orphanages or miqat mosques ([slug] `orphanages` or
/// `meqat_mosques`) from a grid of photo cards, two to a row. These have no
/// map, so they get this sheet instead of the place page.
///
/// Open it with [show]. The result follows [SpecificMosqueRoute]: Confirm
/// gives the places picked, and so does closing the sheet any other way,
/// except that a sheet opened and closed with nothing picked gives null, so
/// the caller's selection (an orphanage's "Most in need", say) stays as it
/// was.
class PlacePickerSheet extends StatefulWidget {
  final String slug;
  final String title;

  /// Owned by [show], which reads it back if the sheet is dismissed.
  final List<Place> selection;

  const PlacePickerSheet._({
    required this.slug,
    required this.title,
    required this.selection,
  });

  static Future<List<Place>?> show(
    BuildContext context, {
    required String slug,
    required String title,
    List<Place> initialSelections = const [],
  }) async {
    final selection = List<Place>.of(initialSelections);
    final confirmed = await showModalBottomSheet<List<Place>>(
      isDismissible: false,
      enableDrag: true,

      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) =>
          PlacePickerSheet._(slug: slug, title: title, selection: selection),
    );
    if (confirmed != null) return confirmed;
    if (initialSelections.isEmpty && selection.isEmpty) return null;
    return selection;
  }

  @override
  State<PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<PlacePickerSheet> {
  final ApiService _apiService = ApiService();
  List<Place> _places = [];
  bool _isLoading = true;

  bool get _isOrphanages => widget.slug == 'orphanages';

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  // The same requests the place page's list makes for these slugs, every page
  // of them.
  Future<void> _fetchPlaces() async {
    final places = <Place>[];
    int page = 1;
    try {
      while (true) {
        final response = _isOrphanages
            ? await _apiService.getOrphanages(page: page, limit: _pageSize)
            : await _apiService.getMiqatMosques(page: page, limit: _pageSize);
        if (response.statusCode != 200 || response.data['success'] != true) {
          break;
        }

        final List<dynamic> data = response.data['data'] ?? [];
        final Map<String, dynamic>? meta = response.data['meta'];
        places.addAll(
          data.map<Place>(
            (e) => _isOrphanages
                ? Orphanage.fromJson(e as Map<String, dynamic>)
                : MeqatMosque.fromJson(e as Map<String, dynamic>),
          ),
        );

        // Without paging info, a short page is the last one. The miqat
        // endpoint sends none and ignores `page`.
        final bool hasMore = meta != null
            ? page < (meta['totalPages'] ?? 1)
            : data.length == _pageSize;
        if (!hasMore) break;
        page++;
      }
    } catch (e) {
      // Show what did load; with nothing, the sheet says none were found.
    }

    if (!mounted) return;
    setState(() {
      _places = places;
      _isLoading = false;
    });
  }

  bool _isSelected(Place place) =>
      widget.selection.any((selected) => selected.id == place.id);

  void _toggle(Place place) {
    setState(() {
      if (_isSelected(place)) {
        widget.selection.removeWhere((selected) => selected.id == place.id);
      } else {
        widget.selection.add(place);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 20),
          Flexible(child: _buildGrid(isAr)),
          _buildButtons(),
          SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final subtitle = _isOrphanages
        ? AppLocalizations.of(context)!.select_an_orphanage_to_deliver_water_to
        : AppLocalizations.of(context)!.select_a_mosque_to_deliver_water_to;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(bool isAr) {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: _gridPadding,
          itemCount: 6,
          gridDelegate: _gridDelegate,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        child: Text(
          _isOrphanages
              ? AppLocalizations.of(context)!.no_orphanages_found
              : AppLocalizations.of(context)!.no_meqat_mosques_found,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: _gridPadding,
      itemCount: _places.length,
      gridDelegate: _gridDelegate,
      itemBuilder: (context, index) => _buildCard(_places[index], isAr),
    );
  }

  Widget _buildCard(Place place, bool isAr) {
    final isSelected = _isSelected(place);
    final image = place.image;

    return GestureDetector(
      onTap: () => _toggle(place),
      child: Material(
        color: Colors.grey[100],
        elevation: isSelected ? 3 : 1,
        // Material draws the border over its child, so the photo never
        // covers it.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.buttonBlueDark : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null && image.isNotEmpty)
              CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => _buildImageFallback(),
              )
            else
              _buildImageFallback(),
            // Darkens the bottom so the name reads over any photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 1.0],
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  place.localizedName(isAr),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 8,
              end: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.buttonBlueDark : Colors.black26,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Center(
      child: Icon(
        _isOrphanages ? Icons.home : Icons.mosque,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  // As on the place page, both act on a selection, so with none they are off.
  Widget _buildButtons() {
    final hasSelection = widget.selection.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SizedBox(
        height: 56,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: hasSelection
                    ? () => setState(() => widget.selection.clear())
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(
                    color: hasSelection ? Colors.red : Colors.grey[300]!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.clear_all),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: hasSelection
                    ? () => Navigator.of(
                        context,
                      ).pop(List<Place>.of(widget.selection))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBlueDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.confirm_selection,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
