import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raheeq_main/l10n/app_localizations.dart';
import 'package:raheeq_main/pages/authentication/registration.dart';

/// The form paints a country flag from flagcdn.com. Real sockets are blocked in
/// the test harness, so every request is answered with a 1x1 transparent PNG.
class _OfflineImages extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeClient();
}

final _transparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _FakeClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest();
}

class _FakeRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHeaders();
  @override
  Future<HttpClientResponse> close() async => _FakeResponse();
}

class _FakeHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _transparentPng.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: const [
    CountryLocalizations.delegate,
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

/// The email field is the only one built with `isEmail: true`.
TextFormField _emailField(WidgetTester tester) {
  return tester
      .widgetList<TextFormField>(find.byType(TextFormField))
      .firstWhere(
        (f) => f.controller?.text.contains('@') ?? false,
        orElse: () => tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .elementAt(2),
      );
}

void main() {
  // Set per-test: the test binding installs its own overrides (which 400 every
  // request) when it initialises, so a one-shot assignment here gets clobbered.
  setUp(() => HttpOverrides.global = _OfflineImages());

  testWidgets('social login pre-fills the email and locks the field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Registration(
          phoneNumber: '',
          countryCode: '',
          registrationToken: 'tok',
          isSocialLogin: true,
          email: 'someone@example.com',
          firstName: 'Sam',
          lastName: 'Rae',
        ),
      ),
    );
    await tester.pump();

    // Autofilled...
    expect(find.text('someone@example.com'), findsOneWidget);

    // ...and not interactable.
    final email = _emailField(tester);
    expect(email.controller!.text, 'someone@example.com');
    expect(email.enabled, isFalse);

    // Typing into it must not change the value.
    await tester.enterText(
      find.byWidget(email),
      'attacker@evil.com',
    );
    await tester.pump();
    expect(email.controller!.text, 'someone@example.com');
  });

  testWidgets('a relay address from Hide My Email is locked the same way', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Registration(
          phoneNumber: '',
          countryCode: '',
          registrationToken: 'tok',
          isSocialLogin: true,
          email: 'xyz123@privaterelay.appleid.com',
        ),
      ),
    );
    await tester.pump();

    final email = _emailField(tester);
    expect(email.controller!.text, 'xyz123@privaterelay.appleid.com');
    expect(email.enabled, isFalse);
  });

  testWidgets('an unresolvable email stays editable rather than dead-ending', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Registration(
          phoneNumber: '',
          countryCode: '',
          registrationToken: 'tok',
          isSocialLogin: true,
          email: null,
        ),
      ),
    );
    await tester.pump();

    final email = _emailField(tester);
    expect(email.controller!.text, isEmpty);
    expect(email.enabled, isTrue);
  });
}
