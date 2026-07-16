import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/models/place.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:raheeq_main/utils/colors.dart';

Widget mosqueCard({
  bool? isFromSavedMosques,
  required bool isSelected,
  required Place item,
  required String slug,
  required Function? onTapCard,
  required BuildContext context,
  required bool isAr,
  required bool isHighNeed,
  required Function? toggleFavorite,
  required dynamic favoriteMosqueIds,
  double? currentLat,
  double? currentLong,
}) {
  String distanceText = "";
  if (currentLat != null && currentLong != null) {
    double distanceInMeters = Geolocator.distanceBetween(
      currentLat,
      currentLong,
      item.latitude,
      item.longitude,
    );
    if (distanceInMeters > 1000) {
      distanceText = (distanceInMeters / 1000).toStringAsFixed(2);
    } else {
      distanceText = (distanceInMeters).toStringAsFixed(2);
    }
  }

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: isSelected ? AppColors.buttonBlueDark : Colors.transparent,
        width: 1.5,
      ),
    ),
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => onTapCard?.call(),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.all(12),
            child: SizedBox(
              height: 73,
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (item.image != null && item.image!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: item.image!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[200]!,
                          highlightColor: Colors.grey[500]!,
                          child: Container(height: 80, color: Colors.grey[200]),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 75,
                          color: Colors.grey[100],
                          child: Icon(
                            slug == 'orphanages' ? Icons.home : Icons.mosque,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Container(
                        height: 75,
                        color: Colors.grey[100],
                        child: Icon(
                          slug == 'orphanages' ? Icons.home : Icons.mosque,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.localizedName(isAr),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isAr ? 16 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (slug != 'orphanages')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GestureDetector(
                          onTap: () => toggleFavorite?.call(),
                          child: Icon(
                            favoriteMosqueIds.contains(item.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: favoriteMosqueIds.contains(item.id)
                                ? Colors.redAccent
                                : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.address.isNotEmpty && isFromSavedMosques == true) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.address,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                if (distanceText.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.distanceAway(distanceText),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
