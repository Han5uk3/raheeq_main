import 'package:raheeq_main/models/category.dart';
import 'package:raheeq_main/models/chiller_model.dart';
import 'package:raheeq_main/models/mosque.dart';
import 'package:raheeq_main/models/selected_category_item.dart';
import 'package:raheeq_main/pages/home/pages/home_tab.dart';

/// The order destination a refill for a chiller at [location] is filed under.
///
/// A refill goes back to the venue the chiller was seeded at, so the location
/// is carried through as the selected place and the checkout sends its id as
/// `locationId`. A chiller with no assigned location leaves the destination
/// open — the backend answers that with `chillerHasNoLocation`, which reads far
/// better than an order aimed at an empty id.
SelectedCategoryItem refillCategoryItem(ChillerDeliveredLocation? location) {
  final category = _categoryFor(location);
  if (location == null || location.id.isEmpty) {
    return SelectedCategoryItem(category: category, optionType: 'none');
  }

  return SelectedCategoryItem(
    category: category,
    optionType: 'specific',
    specificData: Mosque(
      id: location.id,
      name: location.name,
      nameAr: location.nameAr,
      beneficiaryCount: 0,
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      image: '',
      zone: null,
      isActive: true,
    ),
  );
}

/// The cached category matching the location's own type, falling back to the
/// specific-mosque category since that is where chillers are usually seeded.
Category _categoryFor(ChillerDeliveredLocation? location) {
  final categories = HomeTab.cachedCategories;
  final slug = location?.categorySlug ?? 'specific_mosque';
  return categories.firstWhere(
    (c) => c.slug == slug,
    orElse: () => categories.firstWhere(
      (c) => c.slug == 'specific_mosque',
      orElse: () => categories.first,
    ),
  );
}
