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
