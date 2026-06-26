import 'package:raheeq_main/models/product.dart';
import 'package:raheeq_main/models/selected_category_item.dart';

class SelectedProduct {
  final Product product;
  int quantity;
  String? notes;

  SelectedProduct({required this.product, required this.quantity, this.notes});
}

class OrderCategoryState {
  final SelectedCategoryItem categoryItem;
  List<SelectedProduct> selectedProducts;

  OrderCategoryState({
    required this.categoryItem,
    List<SelectedProduct>? selectedProducts,
  }) : selectedProducts = selectedProducts ?? [];

  double get totalPrice {
    return selectedProducts.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }
}
