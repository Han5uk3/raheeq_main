import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/meqat_mosque.dart';
import 'package:raheeq_main/models/orphanage.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:raheeq_main/utils/colors.dart';
import 'package:shimmer/shimmer.dart';

// Orphanages load this many at a time, and the next page once the grid is
// scrolled near its end. Their search runs on the server, once typing has
// paused for [_searchDelay].
const int _orphanagePageSize = 30;
const Duration _searchDelay = Duration(milliseconds: 400);
// Miqat mosques load whole, with no search: their endpoint ignores `page`.
const int _miqatPageSize = 1000;

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

  // Orphanages only; see [_fetchOrphanages].
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;
  String _searchQuery = '';
  int _loadedPages = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _fetchGeneration = 0;

  bool get _isOrphanages => widget.slug == 'orphanages';

  @override
  void initState() {
    super.initState();
    if (_isOrphanages) {
      _searchController.addListener(_onSearchChanged);
      _scrollController.addListener(_onScroll);
      _fetchOrphanages();
    } else {
      _fetchMiqatMosques();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    // The controller also notifies when only the cursor moves.
    if (query == _searchQuery) return;
    _searchQuery = query;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDelay, _fetchOrphanages);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchOrphanages(loadMore: true);
    }
  }

  // One page of the orphanages matching the search. The first page (again,
  // for a new search) starts a new generation, and a fetch whose generation
  // is no longer current drops what it fetched: results for an older search
  // never land in the grid. A page only counts as loaded once it arrives, so
  // one that fails is asked for again on the next scroll rather than skipped.
  Future<void> _fetchOrphanages({bool loadMore = false}) async {
    final int generation = loadMore ? _fetchGeneration : ++_fetchGeneration;
    final int page = loadMore ? _loadedPages + 1 : 1;
    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final response = await _apiService.getOrphanages(
        page: page,
        limit: _orphanagePageSize,
        search: _searchQuery,
      );
      if (!mounted || generation != _fetchGeneration) return;
      if (response.statusCode != 200 || response.data['success'] != true) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final List<dynamic> data = response.data['data'] ?? [];
      final Map<String, dynamic>? meta = response.data['meta'];
      final orphanages = data.map<Place>(
        (e) => Orphanage.fromJson(e as Map<String, dynamic>),
      );
      setState(() {
        _places = loadMore ? [..._places, ...orphanages] : orphanages.toList();
        _loadedPages = page;
        // Without paging info, a short page is the last one.
        _hasMore = meta != null
            ? page < (meta['totalPages'] ?? 1)
            : data.length == _orphanagePageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || generation != _fetchGeneration) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // The same requests the place page's list makes for miqat mosques, every
  // page of them.
  Future<void> _fetchMiqatMosques() async {
    final places = <Place>[];
    int page = 1;
    try {
      while (true) {
        final response = await _apiService.getMiqatMosques(
          page: page,
          limit: _miqatPageSize,
        );
        if (response.statusCode != 200 || response.data['success'] != true) {
          break;
        }

        final List<dynamic> data = response.data['data'] ?? [];
        final Map<String, dynamic>? meta = response.data['meta'];
        places.addAll(
          data.map<Place>(
            (e) => MeqatMosque.fromJson(e as Map<String, dynamic>),
          ),
        );

        // Without paging info, a short page is the last one. The miqat
        // endpoint sends none and ignores `page`.
        final bool hasMore = meta != null
            ? page < (meta['totalPages'] ?? 1)
            : data.length == _miqatPageSize;
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Padding(
      // Keeps the search box clear of the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        // The orphanage grid grows as it is scrolled and changes with every
        // search, so its sheet keeps its full height rather than jumping
        // with each result.
        height: _isOrphanages ? maxHeight : null,
        constraints: BoxConstraints(maxHeight: maxHeight),
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
            if (_isOrphanages) ...[
              _buildSearchField(),
              const SizedBox(height: 12),
            ],
            Flexible(
              fit: _isOrphanages ? FlexFit.tight : FlexFit.loose,
              child: _buildGrid(isAr),
            ),
            _buildButtons(),
            SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
          ],
        ),
      ),
    );
  }

  // Styled like the search box on the place page.
  Widget _buildSearchField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.buttonBlueDark),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 50,
        child: TextField(
          controller: _searchController,
          cursorColor: AppColors.buttonBlueDark,
          style: const TextStyle(color: AppColors.buttonBlueDark, fontSize: 14),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.search_orphanages,
            hintStyle: TextStyle(
              color: AppColors.buttonBlueDark.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.buttonBlueDark,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.buttonBlueDark,
                width: 1.5,
              ),
            ),
          ),
        ),
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
          itemBuilder: (context, index) => _buildPlaceholderCard(),
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
      controller: _scrollController,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: _gridPadding,
      // A row of placeholders while the next page loads.
      itemCount: _places.length + (_isLoadingMore ? 2 : 0),
      gridDelegate: _gridDelegate,
      itemBuilder: (context, index) {
        if (index >= _places.length) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: _buildPlaceholderCard(),
          );
        }
        return _buildCard(_places[index], isAr);
      },
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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
