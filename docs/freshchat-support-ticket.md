# Freshchat Mobile SDK — support request

**To:** support@freshchat.com
**Subject:** Mobile SDK opens a stale resolved conversation while bot replies route to a new conversation ID (+ two related SDK defects)

---

Hello,

We are seeing three defects in the Freshchat Mobile SDK. The first makes our
bot flow effectively unusable; the other two are visible in the same logs and
appear related. All three reproduce on a physical device with a release build.

## Account and environment

| | |
|---|---|
| Freshchat account | `suqyarahiq.myfreshworks.com` |
| App ID | `1141129437814646` |
| SDK domain | `msdk.freshchat.com` |
| Channel | "Chat with us" — `4c0973a1-2c00-4ad6-b2a8-49d79cab8382` (channel_id `1826248`) |
| Bot | Freddy AI agent, "Rahiq Support" |
| User authentication | **Strict JWT mode enabled** (Admin → Channels → Web Chat → User authentication, "Enforce user authentication" on) |
| Flutter plugin | `freshchat_sdk` 0.10.34 |
| Android SDK | `com.github.freshworks-oss:freshchat-android` 6.5.10 |
| iOS SDK | `FreshchatSDK` 6.4.9 |
| Test device | Android 15, physical device, release build |
| Affected platforms | Android and iOS |

Our integration authenticates with `restoreUserWithIdToken`, confirms
`getUserIdTokenStatus == TOKEN_VALID` before opening the chat, registers the
FCM token via `setPushRegistrationToken`, and forwards Freshchat pushes from
`FirebaseMessaging.onMessage` and the background handler using
`isFreshchatNotification` / `handlePushNotification`.

---

## Issue 1 — SDK opens a stale resolved conversation; bot replies go to a different conversation ID

**Severity: blocking.** The customer sees nothing until they leave the chat
screen and re-enter it.

### What happens

After a bot flow ends with a **Resolve conversation** action, the conversation
is correctly marked resolved in the Conversations inbox. On the next visit:

1. `showConversations(tags: ["chat_with_us"])` opens the **old, resolved**
   conversation.
2. The customer's input is sent into that same old conversation.
3. The bot's reply arrives by push carrying a **different, newly created**
   conversation ID.
4. Nothing renders on the open screen. The customer must exit the SDK screen
   and re-enter for the bot's messages to appear.

### Evidence

Single session, chat screen open and foregrounded throughout:

```
[FreshchatService] Freshchat JWT status: JwtTokenStatus.TOKEN_VALID

FCEventConversationOpen  {FCPropertyConversationID: 1141219366823673,
                          FCPropertyChannelName: Chat with us,
                          FCPropertyChannelID: 4c0973a1-2c00-4ad6-b2a8-49d79cab8382,
                          FCPropertyInputTags: [chat_with_us]}

FCEventButtonSent        {FCPropertyIsMultiSelect: false,
                          FCPropertyOption: Continue in English}

FCEventMessageSent       {FCPropertyConversationID: 1141219366823673, ...}

--- bot reply arrives by push, app still in foreground on the chat screen ---

Message data: {msg_alias: dab65bc0-d3c1-41c1-9915-c55290269aa3,
               user_name: Rahiq Support, notif_type: 1, source: freshchat_user,
               body: "Please choose one of the following options:",
               channel_id: 1826248, app_id: 1141129437814646,
               conv_id: 1163163383469067, timestamp: 1786730636626}

FCEventNotificationReceive {FCPropertyConversationID: 1163163383469067, ...}
FCEventMessageReceive      {}
```

The customer is in conversation **`1141219366823673`**. The bot answers into
**`1163163383469067`**.

A second run of the same scenario shows the identical pattern with a different
new ID:

```
FCEventConversationOpen    {FCPropertyConversationID: 1141219366823673, ...}
FCEventMessageSent         {FCPropertyConversationID: 1141219366823673, ...}
conv_id in push            1163162435925873
FCEventNotificationReceive {FCPropertyConversationID: 1163162435925873, ...}
```

So the opened conversation is always the same resolved one
(`1141219366823673`), while each session's bot replies land in a freshly
created conversation.

### What we have already ruled out

- **Push delivery.** The message reaches the device and the SDK immediately,
  in the foreground, as the log above shows. `FCEventNotificationReceive` and
  `FCEventMessageReceive` both fire.
- **Authentication.** `getUserIdTokenStatus` returns `TOKEN_VALID` immediately
  before the screen opens, on every attempt.
- **Push token registration.** `setPushRegistrationToken` is called after user
  restore and logs success.
- **Bot configuration.** The conversation is confirmed resolved in the
  Conversations inbox each time.
- **The tag filter / entry path.** We tested calling `showConversations()` with
  no tags at all. The SDK then opens `ChannelListActivity`
  (`FCEventChannelListOpen`) instead of going straight into the conversation,
  and entering the channel from that list **still requires two visits** before
  the bot's opening message appears. How the customer enters the conversation
  makes no difference to the defect.

### The data is already on the device

This is the part we find hardest to explain. On the unfiltered channel list,
the "Chat with us" row **previews the genuinely latest message** — the bot's
new opening message, the one the customer cannot yet see. Opening that same
channel then shows the stale conversation without it.

So the SDK has already synced the new message into its local store and can
render it at channel level. Nothing is missing from the device. Only the
conversation the detail screen resolves to is wrong.

That row also shows **no unread count**, and `getUnreadCountAsync` returns
`{count: 0, status: STATUS_SUCCESS}` while that unseen bot message exists — so
the message is present enough to preview, but is not counted as unread.

The behaviour is identical whether the app is foregrounded on the chat screen
or backgrounded when the bot replies.

### Questions

1. Why does `showConversations(tags:)` open a resolved conversation instead of
   the active one the backend is routing bot replies into?
2. Is there any supported way for the app to open the current conversation?
   `showConversationWithReferenceID` takes a customer-assigned reference ID,
   not the `conv_id` we receive in the push payload, so we cannot use the ID we
   are given.
3. Should a resolved conversation be reused at all, or is creating a new
   conversation per session the intended behaviour with the SDK failing to
   follow it?

---

## Issue 2 — `MessageFragment` subtype 8 cannot be deserialized

Logged hundreds of times per conversation load, on the latest Android SDK:

```
W/FRESHCHAT_WARNING: cannot deserialize class
  com.freshchat.consumer.sdk.beans.fragment.MessageFragment
  subtype named 8; did you forget to register a subtype?
```

`freshchat-android` 6.5.10 is the newest published release, so we have no
version to upgrade to. This appears to be your Freddy AI agent emitting a
message fragment type your own Android SDK does not register. It floods
during exactly the conversation loads described in Issue 1.

**Question:** what is fragment subtype 8, which SDK version registers it, and
does failing to deserialize it affect message rendering or conversation state?

---

## Issue 3 — `getUnreadCountAsync` callback is not always invoked

The callback passed to `getUnreadCountAsync` sometimes never fires. We had to
add a 5-second timeout to stop it hanging our calling code indefinitely:

```
[FreshchatService] Failed to read Freshchat unread count:
  TimeoutException after 0:00:05.000000: Future not completed
...
[FreshchatService] Freshchat unread lookup: {count: 1, status: STATUS_SUCCESS}
```

A later call succeeds, so this is not a permanent failure — individual calls
are simply abandoned. It correlates with periods of heavy Issue 2 logging.
We have since serialised our calls so only one is outstanding at a time, and
it still occurs.

**Question:** under what conditions can that callback be dropped, and is there
a supported way to bound it?

---

## What we need

Issue 1 is blocking a release. We would appreciate confirmation of whether it
is a known defect, and either a fix timeline or a supported workaround that
lets the SDK open the conversation the backend is actually routing to.

Happy to supply full unredacted logs, a screen recording, or a minimal
reproduction project on request.

Thank you,
Rahiq mobile team
