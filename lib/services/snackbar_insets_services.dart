import 'package:flutter/material.dart';

class SnackbarInsets {
  SnackbarInsets._();

  static final ValueNotifier<double> bottom = ValueNotifier<double>(0);

  static void setBottomInset(double value) {
    if (bottom.value != value) {
      bottom.value = value;
    }
  }

  static void clear() {
    bottom.value = 0;
  }
}
