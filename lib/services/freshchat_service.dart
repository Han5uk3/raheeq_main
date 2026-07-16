import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:freshchat_sdk/freshchat_user.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import '../api/apis.dart';
import '../models/user.dart';

class FreshchatService {
  static void init() {
    log(
      "Initializing Freshchat Service listeners...",
      name: "FreshchatService",
    );
    // Listen for the restore ID generation when the user sends their first message
    Freshchat.onRestoreIdGenerated.listen((event) async {
      log(
        "Freshchat onRestoreIdGenerated event fired. Data: $event",
        name: "FreshchatService",
      );
      if (event == true) {
        FreshchatUser freshchatUser = await Freshchat.getUser;
        final restoreId = freshchatUser.getRestoreId();

        if (restoreId != null && restoreId.isNotEmpty) {
          log(
            "Attempting to save freshchat restore ID ($restoreId) to backend...",
            name: "FreshchatService",
          );
          try {
            await ApiService().saveFreshchatRestoreId(restoreId);
            log(
              "Freshchat restore ID saved successfully to backend.",
              name: "FreshchatService",
            );
          } catch (e) {
            log(
              "Failed to save Freshchat restore ID to backend: $e",
              name: "FreshchatService",
              error: e,
            );
          }
        } else {
          log(
            "Restore ID from FreshchatUser is null or empty. Skipping backend update.",
            name: "FreshchatService",
          );
        }
      } else {
        log(
          "Restore ID generated event is false. Skipping backend update.",
          name: "FreshchatService",
        );
      }
    });
  }

  static bool _isTokenExpired(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);
      if (payloadMap.containsKey('exp')) {
        // give it a 5-minute buffer
        final exp = (payloadMap['exp'] * 1000) - 300000;
        return DateTime.now().millisecondsSinceEpoch > exp;
      }
    } catch (e) {
      return true;
    }
    return true;
  }

  static Future<void> refreshTokenIfNeeded() async {
    final user = AuthStorage.user;
    if (user == null) return;

    final currentToken = AuthStorage.freshchatToken;
    if (!_isTokenExpired(currentToken)) {
      log(
        "Freshchat token is still valid. Skipping refresh.",
        name: "FreshchatService",
      );
      return;
    }

    try {
      final freshchatUuid = await Freshchat.getFreshchatUserId;
      if (freshchatUuid.isNotEmpty) {
        log(
          "Generating Freshchat Token from backend...",
          name: "FreshchatService",
        );
        final response = await ApiService().generateFreshchatToken(
          freshchatUuid,
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          final token = response.data['data']['token'];
          if (token != null) {
            await AuthStorage.saveFreshchatToken(token);
            Freshchat.setUserWithIdToken(token);
            log(
              "User ID token refreshed successfully.",
              name: "FreshchatService",
            );
          }
        }
      }
    } catch (e) {
      log(
        "Failed to refresh Freshchat token: $e",
        name: "FreshchatService",
        error: e,
      );
    }
  }

  static Future<void> showConversations(
    BuildContext context, {
    List<String> tags = const [],
    String? filteredViewTitle,
  }) async {
    await refreshTokenIfNeeded();
    Freshchat.showConversations(
      tags: tags,
      filteredViewTitle: filteredViewTitle,
    );
  }

  static Future<void> identifyUser(User user) async {
    log(
      "Starting identifyUser flow for user: ${user.id}, existing restoreId: ${user.freshchatRestoreId}",
      name: "FreshchatService",
    );
    try {
      final restoreId = user.freshchatRestoreId ?? "";
      log(
        "Identifying user in SDK with externalId: ${user.id} and restoreId: $restoreId",
        name: "FreshchatService",
      );
      Freshchat.identifyUser(externalId: user.id, restoreId: restoreId);

      log(
        "Updating Freshchat user profile details for user: ${user.email}...",
        name: "FreshchatService",
      );
      FreshchatUser freshchatUser = await Freshchat.getUser;
      freshchatUser.setFirstName(user.firstName);
      freshchatUser.setLastName(user.lastName);
      freshchatUser.setEmail(user.email);
      freshchatUser.setPhone(user.countryCode, user.phoneNumber);
      Freshchat.setUser(freshchatUser);
      log(
        "Freshchat user profile details updated successfully.",
        name: "FreshchatService",
      );
    } catch (e) {
      log(
        "Failed to identify Freshchat user: $e",
        name: "FreshchatService",
        error: e,
      );
    }
  }
}
