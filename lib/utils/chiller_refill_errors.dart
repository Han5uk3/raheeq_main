import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';

/// The refill validation errors `POST /checkout` returns when it is given a
/// `chillerRefillSubOrderId` it will not accept.
///
/// The backend reports these as error keys; everything else about the response
/// (status code, message wording) is not something the app should depend on, so
/// the key is what gets matched.
const _refillErrorKeys = <String>{
  'chillerSubOrderNotFound',
  'notAChillerSubOrder',
  'chillerNotConfirmed',
  'chillerNotAvailable',
  'chillerHasNoLocation',
};

/// The localized message for a refill checkout failure, or null when [error] is
/// not one — callers fall back to their usual error handling.
String? chillerRefillErrorMessage(BuildContext context, Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;

  final key = _refillErrorKeyIn(data);
  if (key == null) return null;

  final l10n = AppLocalizations.of(context)!;
  switch (key) {
    case 'chillerSubOrderNotFound':
      return l10n.chiller_not_found;
    case 'notAChillerSubOrder':
      return l10n.invalid_chiller_product;
    case 'chillerNotConfirmed':
      return l10n.chiller_must_be_delivered_before_refilling;
    case 'chillerNotAvailable':
      return l10n.chiller_currently_unavailable_for_refills;
    case 'chillerHasNoLocation':
      return l10n.chiller_has_no_assigned_location;
  }
  return null;
}

/// The refill error key carried by an error body, if any.
///
/// The key can arrive under any of the fields the API uses to name an error, or
/// inside the message itself, so each is checked for an exact match before
/// falling back to a contains-check on the message.
String? _refillErrorKeyIn(Map<dynamic, dynamic> data) {
  for (final field in const ['errorKey', 'error', 'code', 'key', 'message']) {
    final value = data[field];
    if (value is String && _refillErrorKeys.contains(value.trim())) {
      return value.trim();
    }
  }

  final message = data['message'];
  if (message is String) {
    for (final key in _refillErrorKeys) {
      if (message.contains(key)) return key;
    }
  }
  return null;
}
