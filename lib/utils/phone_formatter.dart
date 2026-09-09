import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Keeps the phone field to digits, and follows a pasted international number
/// back to the country it belongs to.
///
/// What it deliberately does *not* do is take the national trunk `0` off while
/// the user types. A Saudi mobile is written `0501234567` on every sign and
/// business card in the country, so that is how people key it in — and a field
/// that swallows the first digit pressed reads as broken, not as helpful. The
/// `0` stays on screen; it comes off once, in [toNationalNumber], on the way
/// into `PhoneNumber.parse` and the API, which both want the international
/// form.
class GlobalPhoneFormatter extends TextInputFormatter {
  final void Function(Country) onCountryDetected;

  GlobalPhoneFormatter({required this.onCountryDetected});

  /// Countries that write a leading trunk `0` the international form drops.
  static const _trunkPrefixPhoneCodes = ['966', '971', '974', '968', '973'];

  /// The digits of [rawText] and nothing else — all the field may hold.
  static String formatText(String rawText) =>
      rawText.replaceAll(RegExp(r'[^\d]'), '');

  /// [rawText] as `PhoneNumber.parse` and the API want it: digits only, minus
  /// the trunk prefix, so `0501234567` and `501234567` both arrive as
  /// `501234567` behind `+966`.
  static String toNationalNumber(String rawText, Country country) {
    final text = formatText(rawText);
    if (!_trunkPrefixPhoneCodes.contains(country.phoneCode)) return text;
    return text.replaceFirst(RegExp(r'^0+'), '');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    bool isPaste = (newValue.text.length - oldValue.text.length) > 1;

    if (isPaste) {
      String toParse = text.trim();
      bool hasInternationalPrefix = false;

      if (toParse.startsWith('+')) {
        hasInternationalPrefix = true;
      } else if (toParse.startsWith('00')) {
        hasInternationalPrefix = true;
        toParse = '+' + toParse.substring(2);
      }

      if (hasInternationalPrefix) {
        // Try to parse it internationally
        PhoneNumber? parsed;
        try {
          final p = PhoneNumber.parse(toParse);
          parsed = p;
        } catch (e) {
          // Parsing failed, ignore
        }

        if (parsed != null) {
          final detectedIsoCode = parsed.isoCode.name; // e.g., 'SA', 'AE'
          text = parsed.nsn;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final matchedCountry = CountryService().findByCode(
              detectedIsoCode,
            );
            if (matchedCountry != null) {
              onCountryDetected(matchedCountry);
            }
          });
        }
      }
    }

    text = formatText(text);

    if (text != newValue.text) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    return newValue;
  }
}
