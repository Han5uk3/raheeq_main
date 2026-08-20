import 'dart:convert';
import 'dart:developer';

/// Reads the claims Apple puts inside the Sign in with Apple identity token.
///
/// Apple hands back `email`, `givenName` and `familyName` on the
/// [AppleIDCredential] **only for the very first authorization** of an Apple ID
/// against this app. Every subsequent sign-in returns those fields as null —
/// including after a reinstall, and including the very common case where the
/// user abandoned registration the first time round. The identity token,
/// however, still carries the `email` claim on every single sign-in, so that is
/// the reliable source for the address that pre-fills the locked email field on
/// the registration form.
///
/// This decodes only; the token is verified server side during /auth/apple.
/// Nothing security-sensitive is decided from these claims locally.
class AppleIdToken {
  const AppleIdToken._();

  /// Decodes the JWT payload of [idToken], or returns null if it is not a
  /// well-formed JWT. Never throws.
  static Map<String, dynamic>? decodePayload(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        log('Apple identity token is not a 3-part JWT', name: 'AuthFlow');
        return null;
      }
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      log('Failed to decode Apple identity token: $e', name: 'AuthFlow');
      return null;
    }
  }

  /// The `email` claim, or null when the token carries no usable address.
  ///
  /// This is the user's real address, or their `@privaterelay.appleid.com`
  /// alias when they chose "Hide My Email" — both are valid addresses that the
  /// backend can deliver to, so both are returned as-is.
  static String? email(String? idToken) {
    final claims = decodePayload(idToken);
    final value = claims?['email'];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// The user details Sign in with Apple gives us, gathered from every source
/// that can still hold them.
///
/// Apple treats "first authorization" as a property of the Apple ID against
/// the app, not of the account in our backend. A customer who registered with
/// Apple, deleted their account, and signs up again is a brand new registration
/// to us but a repeat authorization to Apple — so the credential comes back
/// with `email`, `givenName` and `familyName` all null, and no consent sheet is
/// shown to re-share them. Resolving from the identity token is what keeps that
/// path working.
class AppleProfile {
  const AppleProfile({this.email, this.firstName, this.lastName});

  final String? email;
  final String? firstName;
  final String? lastName;

  /// Picks each field from the best source available, in order:
  ///
  ///  1. the credential — populated only on the first-ever authorization;
  ///  2. the identity token — carries `email` on *every* sign-in, so this is
  ///     what covers the delete-then-sign-up-again case;
  ///  3. the local cache — the only route back to the name, which Apple never
  ///     repeats and the token never carries.
  static AppleProfile resolve({
    String? credentialEmail,
    String? credentialGivenName,
    String? credentialFamilyName,
    String? identityToken,
    Map<String, String>? cached,
  }) {
    String? pick(String? value) {
      final trimmed = value?.trim();
      return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    }

    return AppleProfile(
      email:
          pick(credentialEmail) ??
          AppleIdToken.email(identityToken) ??
          pick(cached?['email']),
      firstName: pick(credentialGivenName) ?? pick(cached?['firstName']),
      lastName: pick(credentialFamilyName) ?? pick(cached?['lastName']),
    );
  }
}
