import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class GlobalPhoneFormatter extends TextInputFormatter {
  final Country Function() getCurrentCountry;
  final void Function(Country) onCountryDetected;

  GlobalPhoneFormatter({
    required this.getCurrentCountry,
    required this.onCountryDetected,
  });

  /// Formats the raw phone number string based on the provided country rules
  static String formatText(String rawText, Country country) {
    String text = rawText.replaceAll(RegExp(r'[^\d]'), '');
    final gccCodes = ['966', '971', '974', '968', '973'];
    if (gccCodes.contains(country.phoneCode)) {
      if (text.startsWith('0')) {
        text = text.replaceFirst(RegExp(r'^0+'), '');
      }
    }
    return text;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    bool isPaste = (newValue.text.length - oldValue.text.length) > 1;
    String? newDetectedIsoCode;

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
          newDetectedIsoCode = parsed.isoCode.name; // e.g., 'SA', 'AE'
          text = parsed.nsn;
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final matchedCountry = CountryService().findByCode(newDetectedIsoCode);
            if (matchedCountry != null) {
              onCountryDetected(matchedCountry);
            }
          });
        }
      }
    }

    final effectiveCountry = newDetectedIsoCode != null 
        ? CountryService().findByCode(newDetectedIsoCode) ?? getCurrentCountry() 
        : getCurrentCountry();

    // Format the number based on the effective country rules
    text = formatText(text, effectiveCountry);

    if (text != newValue.text) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    return newValue;
  }
}
