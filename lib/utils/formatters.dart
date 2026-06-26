class Formatters {
  static String formatCount(num value) {
    if (value >= 1000000000) {
      return _formatDouble(value / 1000000000) + 'B';
    } else if (value >= 1000000) {
      return _formatDouble(value / 1000000) + 'M';
    } else if (value >= 1000) {
      return _formatDouble(value / 1000) + 'K';
    } else {
      if (value is int || value == value.toInt()) {
        return value.toInt().toString();
      }
      return _formatDouble(value.toDouble());
    }
  }

  static String _formatDouble(double value) {
    String str = value.toStringAsFixed(2);
    if (str.endsWith('.00')) {
      return str.substring(0, str.length - 3);
    } else if (str.endsWith('0') && str.contains('.')) {
      return str.substring(0, str.length - 1);
    }
    return str;
  }
}
