import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:raheeq_main/utils/apple_id_token.dart';

String _token(Map<String, dynamic> claims) {
  String seg(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${seg({'alg': 'RS256', 'kid': 'abc'})}.${seg(claims)}.c2ln';
}

void main() {
  _profileTests();

  test('reads the email claim from a real-shaped Apple token', () {
    final token = _token({
      'iss': 'https://appleid.apple.com',
      'aud': 'com.rahiq.app',
      'sub': '001234.abcdef.1234',
      'email': 'user@example.com',
      'email_verified': 'true',
      'is_private_email': 'false',
    });
    expect(AppleIdToken.email(token), 'user@example.com');
  });

  test('reads a Hide My Email relay address', () {
    final token = _token({
      'sub': '001234.abcdef.1234',
      'email': 'xyz123@privaterelay.appleid.com',
      'is_private_email': 'true',
    });
    expect(AppleIdToken.email(token), 'xyz123@privaterelay.appleid.com');
  });

  test('survives padding-sensitive payload lengths', () {
    // Payload lengths that base64 would need 1 and 2 '=' of padding for.
    for (final pad in ['a', 'ab', 'abc', 'abcd']) {
      final token = _token({'sub': pad, 'email': 'p$pad@example.com'});
      expect(AppleIdToken.email(token), 'p$pad@example.com');
    }
  });

  test('returns null instead of throwing on unusable input', () {
    expect(AppleIdToken.email(null), isNull);
    expect(AppleIdToken.email(''), isNull);
    expect(AppleIdToken.email('not-a-jwt'), isNull);
    expect(AppleIdToken.email('one.two'), isNull);
    expect(AppleIdToken.email('aaa.!!!not-base64!!!.ccc'), isNull);
    expect(AppleIdToken.email(_token({'sub': 'x'})), isNull);
    expect(AppleIdToken.email(_token({'sub': 'x', 'email': '   '})), isNull);
    expect(AppleIdToken.email(_token({'sub': 'x', 'email': 42})), isNull);
  });
}

void _profileTests() {
  group('AppleProfile.resolve', () {
    const relayToken = 'x';

    test('first-ever authorization uses the credential', () {
      final p = AppleProfile.resolve(
        credentialEmail: 'first@example.com',
        credentialGivenName: 'Sam',
        credentialFamilyName: 'Rae',
        identityToken: _token({'email': 'first@example.com'}),
      );
      expect(p.email, 'first@example.com');
      expect(p.firstName, 'Sam');
      expect(p.lastName, 'Rae');
    });

    test(
      'deleted account signing up again still resolves the email and name',
      () {
        // Apple sees a repeat authorization: credential fields all null.
        final p = AppleProfile.resolve(
          credentialEmail: null,
          credentialGivenName: null,
          credentialFamilyName: null,
          identityToken: _token({
            'sub': '001234.abcdef',
            'email': 'first@example.com',
          }),
          cached: const {'firstName': 'Sam', 'lastName': 'Rae'},
        );
        expect(p.email, 'first@example.com');
        expect(p.firstName, 'Sam');
        expect(p.lastName, 'Rae');
      },
    );

    test('email resolves from the token even with nothing cached', () {
      final p = AppleProfile.resolve(
        identityToken: _token({'email': 'only-in-token@example.com'}),
        cached: null,
      );
      expect(p.email, 'only-in-token@example.com');
      expect(p.firstName, isNull);
      expect(p.lastName, isNull);
    });

    test('a Hide My Email relay survives the same round trip', () {
      final p = AppleProfile.resolve(
        identityToken: _token({'email': 'abc@privaterelay.appleid.com'}),
      );
      expect(p.email, 'abc@privaterelay.appleid.com');
    });

    test('the token wins over a stale cached address', () {
      final p = AppleProfile.resolve(
        identityToken: _token({'email': 'current@example.com'}),
        cached: const {'email': 'stale@example.com'},
      );
      expect(p.email, 'current@example.com');
    });

    test('falls back to the cache when the token carries no email', () {
      final p = AppleProfile.resolve(
        identityToken: _token({'sub': 'x'}),
        cached: const {'email': 'cached@example.com'},
      );
      expect(p.email, 'cached@example.com');
    });

    test('blank and whitespace-only values are treated as absent', () {
      final p = AppleProfile.resolve(
        credentialEmail: '  ',
        credentialGivenName: '',
        identityToken: relayToken,
        cached: const {'email': 'cached@example.com', 'firstName': '  '},
      );
      expect(p.email, 'cached@example.com');
      expect(p.firstName, isNull);
    });

    test('resolves to nulls when no source has anything', () {
      final p = AppleProfile.resolve(identityToken: _token({'sub': 'x'}));
      expect(p.email, isNull);
      expect(p.firstName, isNull);
      expect(p.lastName, isNull);
    });
  });
}
