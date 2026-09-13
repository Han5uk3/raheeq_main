import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

/// The one place API traffic is logged.
///
/// Every [Dio] that talks to the backend adds this interceptor, so requests,
/// responses and errors all come out in the same shape under the `API` log
/// name. Nothing else should log API calls; flip [enabled] instead.
class ApiLogger extends Interceptor {
  /// Turns all API request/response logging on or off.
  static const bool enabled = true;

  static const String _startedAtKey = '_api_logger_started_at';

  // Falls back to toString so an unencodable value can't break logging.
  static final JsonEncoder _encoder = JsonEncoder.withIndent(
    '  ',
    (value) => value.toString(),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      options.extra[_startedAtKey] = DateTime.now();
      _log([
        '--> ${options.method} ${options.uri}',
        'Headers: ${_format(options.headers)}',
        if (options.data != null) 'Body: ${_format(options.data)}',
      ]);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      _log([
        '<-- ${response.statusCode} ${_describe(response.requestOptions)}',
        'Body: ${_format(response.data)}',
      ]);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      final response = err.response;
      _log([
        '<-- ${response?.statusCode ?? 'FAILED'} ${_describe(err.requestOptions)}',
        if (response != null)
          'Body: ${_format(response.data)}'
        else
          'Error: ${err.type.name}: ${err.message ?? err.error}',
      ]);
    }
    handler.next(err);
  }

  /// Method, URL and how long the request took.
  static String _describe(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    final elapsed = startedAt is DateTime
        ? ' (${DateTime.now().difference(startedAt).inMilliseconds} ms)'
        : '';
    return '${options.method} ${options.uri}$elapsed';
  }

  static String _format(Object? data) => _encoder.convert(
    data is FormData
        ? {
            for (final field in data.fields) field.key: field.value,
            for (final file in data.files)
              file.key: '<file: ${file.value.filename}>',
          }
        : data,
  );

  static void _log(List<String> lines) => log(lines.join('\n'), name: 'API');
}
