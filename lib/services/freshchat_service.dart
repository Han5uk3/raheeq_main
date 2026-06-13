import 'dart:developer';

import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:freshchat_sdk/freshchat_user.dart';
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

  static Future<void> identifyUser(User user) async {
    log(
      "Starting identifyUser flow for user: ${user.id}, existing restoreId: ${user.freshchatRestoreId}",
      name: "FreshchatService",
    );
    try {
      // 1. Get the Freshchat UUID
      final freshchatUuid = await Freshchat.getFreshchatUserId;
      log(
        "Fetched Freshchat UUID from SDK: $freshchatUuid",
        name: "FreshchatService",
      );

      if (freshchatUuid.isNotEmpty) {
        log(
          "Generating Freshchat Token from backend...",
          name: "FreshchatService",
        );
        // 2. Generate the Freshchat signed JWT token from the backend
        final response = await ApiService().generateFreshchatToken(
          freshchatUuid,
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          final token = response.data['data']['token'];
          log(
            "Successfully retrieved JWT Token from backend.",
            name: "FreshchatService",
          );

          if (token != null) {
            // 3. Identify user with the SDK, passing the restore ID if available
            final restoreId = user.freshchatRestoreId ?? "";
            log(
              "Identifying user in SDK with externalId: ${user.id} and restoreId: $restoreId",
              name: "FreshchatService",
            );
            Freshchat.identifyUser(externalId: user.id, restoreId: restoreId);

            // 4. Set the user identity using the signed JWT token
            log("Setting user ID token in SDK...", name: "FreshchatService");
            Freshchat.setUserWithIdToken(token);
            log("User ID token set successfully.", name: "FreshchatService");
          } else {
            log(
              "JWT token from backend is null. Skipping identifyUser and setUserWithIdToken.",
              name: "FreshchatService",
            );
          }
        } else {
          log(
            "Failed to generate JWT token. Response: ${response.data}",
            name: "FreshchatService",
          );
        }
      } else {
        log(
          "Freshchat UUID is null or empty. Skipping token generation.",
          name: "FreshchatService",
        );
      }

      // 5. Update user profile details
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
