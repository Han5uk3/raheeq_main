import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:raheeq_main/utils/colors.dart';

/// The tile used by the Home tab's "giving opportunities" grid.
///
/// Shared so any other entry point into the same selection flow (for example
/// the "order a new chiller" sheet) draws exactly the same card.
Widget buildQuickServiceGridCard(
  BuildContext context,
  String title,
  String imgPath, {
  bool isSelected = false,
  bool requiresChoosing = false,
  VoidCallback? onClear,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Material(
        color: Colors.white,
        elevation: isSelected ? 3 : 1,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.buttonBlueDark, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFDDEEF7),
                      child: imgPath.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.water_drop_outlined,
                                color: AppColors.buttonBlueDark,
                                size: 32,
                              ),
                            )
                          : imgPath.startsWith('assets/')
                          ? Image.asset(imgPath, fit: BoxFit.contain)
                          : CachedNetworkImage(
                              imageUrl: imgPath,
                              fit: BoxFit.contain,
                              placeholder: (context, url) =>
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(color: Colors.white),
                                  ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Icon(
                                      Icons.water_drop_outlined,
                                      color: AppColors.buttonBlueDark,
                                      size: 32,
                                    ),
                                  ),
                            ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
      if (onClear != null)
        PositionedDirectional(
          top: -8,
          end: -8,
          child: GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
    ],
  );
}
