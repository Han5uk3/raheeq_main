import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Rahiq'**
  String get appTitle;

  /// A welcome message shown on the home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rahiq!'**
  String get welcomeMessage;

  /// No description provided for @onboard1_title.
  ///
  /// In en, this message translates to:
  /// **'Give with Purpose'**
  String get onboard1_title;

  /// No description provided for @onboard1_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Make a meaningful difference by providing water to those who need it most.'**
  String get onboard1_subtitle;

  /// No description provided for @onboard2_title.
  ///
  /// In en, this message translates to:
  /// **'Simple. Transparent. Reliable.'**
  String get onboard2_title;

  /// No description provided for @onboard2_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose where to give, and we’ll handle the rest.'**
  String get onboard2_subtitle;

  /// No description provided for @onboard3_title.
  ///
  /// In en, this message translates to:
  /// **'Start Your Journey of Giving'**
  String get onboard3_title;

  /// No description provided for @onboard3_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your small act can serve hundreds and create continuous الخير.'**
  String get onboard3_subtitle;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get skip;

  /// No description provided for @continue_btn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_btn;

  /// No description provided for @start_donating.
  ///
  /// In en, this message translates to:
  /// **'Start Donating'**
  String get start_donating;

  /// No description provided for @new_to_donate.
  ///
  /// In en, this message translates to:
  /// **'New to donate?'**
  String get new_to_donate;

  /// No description provided for @terms_agree_prefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get terms_agree_prefix;

  /// No description provided for @terms_conditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms_conditions;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @enter_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Mobile Number'**
  String get enter_phone;

  /// No description provided for @otp_message.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to continue.\nWe will send an OTP for verification.'**
  String get otp_message;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @google_signin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get google_signin;

  /// No description provided for @apple_signin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get apple_signin;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @impact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get impact;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logout_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of Raheeq?'**
  String get logout_confirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @no_session.
  ///
  /// In en, this message translates to:
  /// **'No session found. Please log in.'**
  String get no_session;

  /// No description provided for @personal_information.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personal_information;

  /// No description provided for @saved_mosques.
  ///
  /// In en, this message translates to:
  /// **'Saved Mosques'**
  String get saved_mosques;

  /// No description provided for @recurring_donations.
  ///
  /// In en, this message translates to:
  /// **'Recurring Donations'**
  String get recurring_donations;

  /// No description provided for @tax_receipts.
  ///
  /// In en, this message translates to:
  /// **'Tax Receipts'**
  String get tax_receipts;

  /// No description provided for @my_wallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get my_wallet;

  /// No description provided for @payment_methods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get payment_methods;

  /// No description provided for @order_history.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get order_history;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @app_settings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get app_settings;

  /// No description provided for @help_center.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get help_center;

  /// No description provided for @contact_us.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contact_us;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get last_name;

  /// No description provided for @email_address.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email_address;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profile_updated;

  /// No description provided for @profile_pic_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profile_pic_updated;

  /// No description provided for @orders_live_soon.
  ///
  /// In en, this message translates to:
  /// **'Orders will be live soon...'**
  String get orders_live_soon;

  /// No description provided for @impact_page.
  ///
  /// In en, this message translates to:
  /// **'Impact Page'**
  String get impact_page;

  /// No description provided for @no_products_selected.
  ///
  /// In en, this message translates to:
  /// **'No products selected'**
  String get no_products_selected;

  /// No description provided for @guest_user_email.
  ///
  /// In en, this message translates to:
  /// **'guest_user@suqyarahiq.com'**
  String get guest_user_email;

  /// No description provided for @guest_user.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guest_user;

  /// No description provided for @login_successful.
  ///
  /// In en, this message translates to:
  /// **'Login Successful'**
  String get login_successful;

  /// No description provided for @enter_valid_otp.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid OTP'**
  String get enter_valid_otp;

  /// No description provided for @removed_from_saved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from saved mosques.'**
  String removed_from_saved(String name);

  /// No description provided for @failed_to_remove_mosque.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove mosque.'**
  String get failed_to_remove_mosque;

  /// No description provided for @failed_to_update_favorite.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite.'**
  String get failed_to_update_favorite;

  /// No description provided for @failed_to_load_wallet.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wallet data.'**
  String get failed_to_load_wallet;

  /// No description provided for @minimum_quantity_is.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity is {min}'**
  String minimum_quantity_is(String min);

  /// No description provided for @example_quantity.
  ///
  /// In en, this message translates to:
  /// **'e.g., 50'**
  String get example_quantity;

  /// No description provided for @error_msg.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error_msg(String error);

  /// No description provided for @failed_to_pick_image.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failed_to_pick_image(String error);

  /// No description provided for @failed_upload_simulation.
  ///
  /// In en, this message translates to:
  /// **'Failed upload simulation: {error}'**
  String failed_upload_simulation(String error);

  /// No description provided for @track_mosque_donations.
  ///
  /// In en, this message translates to:
  /// **'Track your mosque donations'**
  String get track_mosque_donations;

  /// No description provided for @ongoing_charity_rewards.
  ///
  /// In en, this message translates to:
  /// **'Your ongoing charity rewards'**
  String get ongoing_charity_rewards;

  /// No description provided for @manage_account_settings.
  ///
  /// In en, this message translates to:
  /// **'Manage your account settings'**
  String get manage_account_settings;

  /// No description provided for @raheeq.
  ///
  /// In en, this message translates to:
  /// **'Raheeq'**
  String get raheeq;

  /// No description provided for @my_orders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get my_orders;

  /// No description provided for @new_orders.
  ///
  /// In en, this message translates to:
  /// **'New Orders'**
  String get new_orders;

  /// No description provided for @out_for_delivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get out_for_delivery;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @transaction_history.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transaction_history;

  /// No description provided for @no_transactions_found.
  ///
  /// In en, this message translates to:
  /// **'No transactions found.'**
  String get no_transactions_found;

  /// No description provided for @current_balance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get current_balance;

  /// No description provided for @account_section.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account_section;

  /// No description provided for @payment_orders_section.
  ///
  /// In en, this message translates to:
  /// **'Payment & orders'**
  String get payment_orders_section;

  /// No description provided for @settings_section.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_section;

  /// No description provided for @support_section.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support_section;

  /// No description provided for @feature_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon'**
  String get feature_coming_soon;

  /// No description provided for @redirecting_payment_methods.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to My Payment Methods...'**
  String get redirecting_payment_methods;

  /// No description provided for @redirecting_terms.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to Terms and Conditions...'**
  String get redirecting_terms;

  /// No description provided for @donations_label.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get donations_label;

  /// No description provided for @mosques_label.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get mosques_label;

  /// No description provided for @people_label.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people_label;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
