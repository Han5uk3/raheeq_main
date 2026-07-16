import 'package:raheeq_main/models/category.dart';

class SelectedCategoryItem {
  final Category category;
  final String? optionType;
  final dynamic specificData;

  SelectedCategoryItem({
    required this.category,
    this.optionType,
    this.specificData,
  });
}

class EssentialSelection {
  final dynamic product; // using dynamic to avoid importing Product if not needed, but better to import it
  final dynamic place;

  EssentialSelection({required this.product, this.place});
}
