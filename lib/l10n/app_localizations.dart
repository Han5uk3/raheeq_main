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

  /// No description provided for @available_colon.
  ///
  /// In en, this message translates to:
  /// **'Available :'**
  String get available_colon;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Ahlan'**
  String get welcome;

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

  /// No description provided for @select_mosques_to_deliver_to.
  ///
  /// In en, this message translates to:
  /// **'Select mosques to deliver to'**
  String get select_mosques_to_deliver_to;

  /// No description provided for @continue_btn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_btn;

  /// No description provided for @iban_accounts.
  ///
  /// In en, this message translates to:
  /// **'IBAN Accounts'**
  String get iban_accounts;

  /// No description provided for @copied_to_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied_to_clipboard;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @saved_to_downloads.
  ///
  /// In en, this message translates to:
  /// **'Saved to Downloads'**
  String get saved_to_downloads;

  /// No description provided for @saved_to_files.
  ///
  /// In en, this message translates to:
  /// **'Saved to Files'**
  String get saved_to_files;

  /// No description provided for @download_failed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get download_failed;

  /// No description provided for @select_bank_transfer.
  ///
  /// In en, this message translates to:
  /// **'Select a bank for the transfer'**
  String get select_bank_transfer;

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

  /// No description provided for @login_terms_prefix.
  ///
  /// In en, this message translates to:
  /// **'By signing in, you agree to the '**
  String get login_terms_prefix;

  /// No description provided for @login_terms_suffix.
  ///
  /// In en, this message translates to:
  /// **' of the Rahiq app.'**
  String get login_terms_suffix;

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
  /// **'Are you sure you want to log out of Rahiq?'**
  String get logout_confirmation;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account;

  /// No description provided for @delete_account_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account? All your data will be lost and this action cannot be undone.'**
  String get delete_account_confirmation;

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
  /// **'Recurring Orders'**
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

  /// No description provided for @contact_us_desc.
  ///
  /// In en, this message translates to:
  /// **'Reach out to us via live chat for immediate support.'**
  String get contact_us_desc;

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

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

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

  /// No description provided for @no_orders_out_for_delivery.
  ///
  /// In en, this message translates to:
  /// **'No orders out for delivery'**
  String get no_orders_out_for_delivery;

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

  /// No description provided for @track_your_donations.
  ///
  /// In en, this message translates to:
  /// **'Track your Orders'**
  String get track_your_donations;

  /// No description provided for @manage_account_settings.
  ///
  /// In en, this message translates to:
  /// **'Manage your account settings'**
  String get manage_account_settings;

  /// No description provided for @raheeq.
  ///
  /// In en, this message translates to:
  /// **'Rahiq'**
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

  /// No description provided for @serveTheGuestOfAllah.
  ///
  /// In en, this message translates to:
  /// **'Serve The Guest of Allah'**
  String get serveTheGuestOfAllah;

  /// No description provided for @build_number.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get build_number;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @app_information.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get app_information;

  /// No description provided for @theme_switching_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Theme switching coming soon'**
  String get theme_switching_coming_soon;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @app_language.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get app_language;

  /// No description provided for @manage_preferences_and_app_info.
  ///
  /// In en, this message translates to:
  /// **'Manage preferences and app info'**
  String get manage_preferences_and_app_info;

  /// No description provided for @recurring_impact.
  ///
  /// In en, this message translates to:
  /// **'Recurring impact'**
  String get recurring_impact;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @single_donation.
  ///
  /// In en, this message translates to:
  /// **'Single order'**
  String get single_donation;

  /// No description provided for @one_time.
  ///
  /// In en, this message translates to:
  /// **'One-Time'**
  String get one_time;

  /// No description provided for @support_once_or_make_a_lasting_impact.
  ///
  /// In en, this message translates to:
  /// **'Order once or make a lasting impact'**
  String get support_once_or_make_a_lasting_impact;

  /// No description provided for @choose_donation_type.
  ///
  /// In en, this message translates to:
  /// **'Choose order destination'**
  String get choose_donation_type;

  /// No description provided for @payable_amount.
  ///
  /// In en, this message translates to:
  /// **'Payable Amount'**
  String get payable_amount;

  /// No description provided for @add_note.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get add_note;

  /// No description provided for @enter_quantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enter_quantity;

  /// No description provided for @or_enter_custom_quantity_min_min.
  ///
  /// In en, this message translates to:
  /// **'Or enter custom quantity (min. \$min)'**
  String get or_enter_custom_quantity_min_min;

  /// No description provided for @select_your_impact.
  ///
  /// In en, this message translates to:
  /// **'Rahiq delivers your generosity.'**
  String get select_your_impact;

  /// No description provided for @select_a_product_to_continue.
  ///
  /// In en, this message translates to:
  /// **'Select a product to continue'**
  String get select_a_product_to_continue;

  /// No description provided for @no_cities_found.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get no_cities_found;

  /// No description provided for @search_for_a_city.
  ///
  /// In en, this message translates to:
  /// **'Search for a city...'**
  String get search_for_a_city;

  /// No description provided for @select_the_most_needy_cities.
  ///
  /// In en, this message translates to:
  /// **'Select the most needy cities'**
  String get select_the_most_needy_cities;

  /// No description provided for @choose_cities.
  ///
  /// In en, this message translates to:
  /// **'Choose Cities'**
  String get choose_cities;

  /// No description provided for @confirm_selection.
  ///
  /// In en, this message translates to:
  /// **'Confirm Selection'**
  String get confirm_selection;

  /// No description provided for @clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clear_all;

  /// No description provided for @deliver_blessings.
  ///
  /// In en, this message translates to:
  /// **'Deliver Blessings.'**
  String get deliver_blessings;

  /// No description provided for @give_water.
  ///
  /// In en, this message translates to:
  /// **'Give Water.'**
  String get give_water;

  /// No description provided for @we.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get we;

  /// No description provided for @kilometer.
  ///
  /// In en, this message translates to:
  /// **'Km'**
  String get kilometer;

  /// No description provided for @meter.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get meter;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon...'**
  String get coming_soon;

  /// No description provided for @your_impact.
  ///
  /// In en, this message translates to:
  /// **'Your Impact'**
  String get your_impact;

  /// No description provided for @view_status_and_delivery_details.
  ///
  /// In en, this message translates to:
  /// **'View status and delivery details.'**
  String get view_status_and_delivery_details;

  /// No description provided for @recent_donations.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recent_donations;

  /// No description provided for @products_overview.
  ///
  /// In en, this message translates to:
  /// **'Products Overview'**
  String get products_overview;

  /// No description provided for @donations_overview.
  ///
  /// In en, this message translates to:
  /// **'Orders Overview'**
  String get donations_overview;

  /// No description provided for @orphanages_helped.
  ///
  /// In en, this message translates to:
  /// **'Orphanages Helped'**
  String get orphanages_helped;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'⃁'**
  String get sar;

  /// No description provided for @starting_from.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get starting_from;

  /// No description provided for @high_need.
  ///
  /// In en, this message translates to:
  /// **'High Need'**
  String get high_need;

  /// No description provided for @essential_mosque_supplies.
  ///
  /// In en, this message translates to:
  /// **'Essential Mosque Supplies'**
  String get essential_mosque_supplies;

  /// No description provided for @choose_where_to_give_and_create_a_lasting_impact.
  ///
  /// In en, this message translates to:
  /// **'Choose where to give and create a lasting impact.'**
  String get choose_where_to_give_and_create_a_lasting_impact;

  /// No description provided for @giving_opportunities.
  ///
  /// In en, this message translates to:
  /// **'Giving Opportunities'**
  String get giving_opportunities;

  /// No description provided for @donate_now.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get donate_now;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @no_new_notifications.
  ///
  /// In en, this message translates to:
  /// **'No New Notifications'**
  String get no_new_notifications;

  /// No description provided for @i_understand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get i_understand;

  /// No description provided for @your_current_basket_will_be_cleared_and_you_will_be_moved_to_targetname.
  ///
  /// In en, this message translates to:
  /// **'Your current basket will be cleared and you will be moved to \$targetName.'**
  String
  get your_current_basket_will_be_cleared_and_you_will_be_moved_to_targetname;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @failed_to_load_home_page.
  ///
  /// In en, this message translates to:
  /// **'Failed to load home page'**
  String get failed_to_load_home_page;

  /// No description provided for @choose_mosques.
  ///
  /// In en, this message translates to:
  /// **'Choose Mosques'**
  String get choose_mosques;

  /// No description provided for @order_now.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get order_now;

  /// No description provided for @order_new_chiller.
  ///
  /// In en, this message translates to:
  /// **'Order a new chiller'**
  String get order_new_chiller;

  /// No description provided for @unknown_product.
  ///
  /// In en, this message translates to:
  /// **'Unknown Product'**
  String get unknown_product;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @delivered_at.
  ///
  /// In en, this message translates to:
  /// **'Delivered At'**
  String get delivered_at;

  /// No description provided for @not_available.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get not_available;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @unknown_location.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknown_location;

  /// No description provided for @location_not_selected.
  ///
  /// In en, this message translates to:
  /// **'Location not selected'**
  String get location_not_selected;

  /// No description provided for @order_water_to_this_chiller.
  ///
  /// In en, this message translates to:
  /// **'Order water to this chiller'**
  String get order_water_to_this_chiller;

  /// No description provided for @assalamu_alaikum.
  ///
  /// In en, this message translates to:
  /// **'Assalamu Alaikum'**
  String get assalamu_alaikum;

  /// No description provided for @latest_updates_and_alerts.
  ///
  /// In en, this message translates to:
  /// **'Latest updates and alerts'**
  String get latest_updates_and_alerts;

  /// No description provided for @no_delivered_orders.
  ///
  /// In en, this message translates to:
  /// **'No delivered orders'**
  String get no_delivered_orders;

  /// No description provided for @no_new_orders.
  ///
  /// In en, this message translates to:
  /// **'No new orders'**
  String get no_new_orders;

  /// No description provided for @total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get total_amount;

  /// No description provided for @minimum_order_min_units.
  ///
  /// In en, this message translates to:
  /// **'Minimum order: \$min units'**
  String get minimum_order_min_units;

  /// No description provided for @enter_quantity_min_min.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity (min: \$min)'**
  String get enter_quantity_min_min;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @for_name.
  ///
  /// In en, this message translates to:
  /// **'for: \$name'**
  String get for_name;

  /// No description provided for @select_quantity.
  ///
  /// In en, this message translates to:
  /// **'Select Quantity'**
  String get select_quantity;

  /// No description provided for @quick_services.
  ///
  /// In en, this message translates to:
  /// **'Quick Services'**
  String get quick_services;

  /// No description provided for @no_products_available.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get no_products_available;

  /// No description provided for @select_a_product.
  ///
  /// In en, this message translates to:
  /// **'Select a Product'**
  String get select_a_product;

  /// No description provided for @no_active_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'No active subscriptions'**
  String get no_active_subscriptions;

  /// No description provided for @manage_your_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscriptions'**
  String get manage_your_subscriptions;

  /// No description provided for @no_saved_mosques_found.
  ///
  /// In en, this message translates to:
  /// **'No saved mosques found.'**
  String get no_saved_mosques_found;

  /// No description provided for @your_favorite_mosques.
  ///
  /// In en, this message translates to:
  /// **'Your favorite mosques'**
  String get your_favorite_mosques;

  /// No description provided for @no_mosques_found.
  ///
  /// In en, this message translates to:
  /// **'No mosques found'**
  String get no_mosques_found;

  /// No description provided for @no_meqat_mosques_found.
  ///
  /// In en, this message translates to:
  /// **'No meqat mosques found'**
  String get no_meqat_mosques_found;

  /// No description provided for @no_orphanages_found.
  ///
  /// In en, this message translates to:
  /// **'No orphanages found'**
  String get no_orphanages_found;

  /// No description provided for @no_mosques_available_in_selected_city.
  ///
  /// In en, this message translates to:
  /// **'No mosques available in the selected city'**
  String get no_mosques_available_in_selected_city;

  /// No description provided for @no_meqat_mosques_available_in_selected_city.
  ///
  /// In en, this message translates to:
  /// **'No meqat mosques available in the selected city'**
  String get no_meqat_mosques_available_in_selected_city;

  /// No description provided for @no_orphanages_available_in_selected_city.
  ///
  /// In en, this message translates to:
  /// **'No orphanages available in the selected city'**
  String get no_orphanages_available_in_selected_city;

  /// No description provided for @select_city.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get select_city;

  /// No description provided for @search_mosques.
  ///
  /// In en, this message translates to:
  /// **'Search mosques...'**
  String get search_mosques;

  /// No description provided for @search_meqat_mosques.
  ///
  /// In en, this message translates to:
  /// **'Search meqat mosques...'**
  String get search_meqat_mosques;

  /// No description provided for @search_orphanages.
  ///
  /// In en, this message translates to:
  /// **'Search orphanages...'**
  String get search_orphanages;

  /// No description provided for @choose_from_map.
  ///
  /// In en, this message translates to:
  /// **'Choose from Map'**
  String get choose_from_map;

  /// No description provided for @list_of_mosques.
  ///
  /// In en, this message translates to:
  /// **'List of Mosques'**
  String get list_of_mosques;

  /// No description provided for @select_a_mosque_to_deliver_water_to.
  ///
  /// In en, this message translates to:
  /// **'Select a mosque to deliver water to'**
  String get select_a_mosque_to_deliver_water_to;

  /// No description provided for @choose_specific_mosque.
  ///
  /// In en, this message translates to:
  /// **'Choose Specific Mosque'**
  String get choose_specific_mosque;

  /// No description provided for @list_of_meqat_mosques.
  ///
  /// In en, this message translates to:
  /// **'List of Meqat mosques'**
  String get list_of_meqat_mosques;

  /// No description provided for @choose_specific_meqat_mosque.
  ///
  /// In en, this message translates to:
  /// **'Choose Specific Meqat Mosque'**
  String get choose_specific_meqat_mosque;

  /// No description provided for @list_of_orphanages.
  ///
  /// In en, this message translates to:
  /// **'List of Orphanages'**
  String get list_of_orphanages;

  /// No description provided for @select_an_orphanage_to_deliver_water_to.
  ///
  /// In en, this message translates to:
  /// **'Select an orphanage to deliver water to'**
  String get select_an_orphanage_to_deliver_water_to;

  /// No description provided for @choose_specific_orphanage.
  ///
  /// In en, this message translates to:
  /// **'Choose Specific Orphanage'**
  String get choose_specific_orphanage;

  /// No description provided for @clear_selection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clear_selection;

  /// No description provided for @choose_donation_type_108.
  ///
  /// In en, this message translates to:
  /// **'Choose type of order'**
  String get choose_donation_type_108;

  /// No description provided for @specific.
  ///
  /// In en, this message translates to:
  /// **'Specific'**
  String get specific;

  /// No description provided for @most_needy.
  ///
  /// In en, this message translates to:
  /// **'Most needy'**
  String get most_needy;

  /// No description provided for @two_year_guarantee.
  ///
  /// In en, this message translates to:
  /// **'2 Year Guarantee'**
  String get two_year_guarantee;

  /// No description provided for @select_the_water_package_that_suits_you.
  ///
  /// In en, this message translates to:
  /// **'Select the water package that suits you'**
  String get select_the_water_package_that_suits_you;

  /// No description provided for @choose_water_package.
  ///
  /// In en, this message translates to:
  /// **'Choose what the mosque needs'**
  String get choose_water_package;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @confirm_pay.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay'**
  String get confirm_pay;

  /// No description provided for @wallet_applied.
  ///
  /// In en, this message translates to:
  /// **'Wallet Applied'**
  String get wallet_applied;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @vat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vat;

  /// No description provided for @vat_with_percentage.
  ///
  /// In en, this message translates to:
  /// **'VAT ({percentage}%)'**
  String vat_with_percentage(String percentage);

  /// No description provided for @delivery_fee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get delivery_fee;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @contribution_details.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get contribution_details;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @selected_text.
  ///
  /// In en, this message translates to:
  /// **'selected: '**
  String get selected_text;

  /// No description provided for @use_wallet_balance.
  ///
  /// In en, this message translates to:
  /// **'Use Wallet Balance'**
  String get use_wallet_balance;

  /// No description provided for @enter_coupon_code.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get enter_coupon_code;

  /// No description provided for @feedback_submitted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted successfully'**
  String get feedback_submitted_successfully;

  /// No description provided for @coupon_code.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code'**
  String get coupon_code;

  /// No description provided for @day_of_month.
  ///
  /// In en, this message translates to:
  /// **'Day of Month'**
  String get day_of_month;

  /// No description provided for @gift_your_loved_ones_the_blessing_of_providing_water_in_the_holiest_places.
  ///
  /// In en, this message translates to:
  /// **'Gift your loved ones the blessing of providing water in the holiest places.'**
  String
  get gift_your_loved_ones_the_blessing_of_providing_water_in_the_holiest_places;

  /// No description provided for @donation_type.
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get donation_type;

  /// No description provided for @final_review_and_payment.
  ///
  /// In en, this message translates to:
  /// **'Final review and payment'**
  String get final_review_and_payment;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @subscription_details.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subscription_details;

  /// No description provided for @delivery_days.
  ///
  /// In en, this message translates to:
  /// **'Delivery Days'**
  String get delivery_days;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @start_date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get start_date;

  /// No description provided for @end_date.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get end_date;

  /// No description provided for @total_days.
  ///
  /// In en, this message translates to:
  /// **'Total Days'**
  String get total_days;

  /// No description provided for @no_of_orders.
  ///
  /// In en, this message translates to:
  /// **'No. of Orders'**
  String get no_of_orders;

  /// No description provided for @payment_was_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment was cancelled'**
  String get payment_was_cancelled;

  /// No description provided for @error_verifying_payment.
  ///
  /// In en, this message translates to:
  /// **'Error verifying payment'**
  String get error_verifying_payment;

  /// No description provided for @expires_on.
  ///
  /// In en, this message translates to:
  /// **'Expires on'**
  String get expires_on;

  /// No description provided for @subscription_duration.
  ///
  /// In en, this message translates to:
  /// **'Subscription Duration'**
  String get subscription_duration;

  /// No description provided for @pay_with_card.
  ///
  /// In en, this message translates to:
  /// **'Pay with Card'**
  String get pay_with_card;

  /// No description provided for @payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get payment_method;

  /// No description provided for @stc_pay.
  ///
  /// In en, this message translates to:
  /// **'STC Pay'**
  String get stc_pay;

  /// No description provided for @status_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get status_failed;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @apple_pay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get apple_pay;

  /// No description provided for @credit_card_mada.
  ///
  /// In en, this message translates to:
  /// **'Credit Card / Mada'**
  String get credit_card_mada;

  /// No description provided for @failed_to_apply_wallet.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply wallet'**
  String get failed_to_apply_wallet;

  /// No description provided for @insufficient_balance_to_apply_wallet.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance to apply wallet'**
  String get insufficient_balance_to_apply_wallet;

  /// No description provided for @failed_to_remove_coupon.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove coupon'**
  String get failed_to_remove_coupon;

  /// No description provided for @coupon_removed_successfully.
  ///
  /// In en, this message translates to:
  /// **'Coupon removed successfully'**
  String get coupon_removed_successfully;

  /// No description provided for @invalid_coupon_code.
  ///
  /// In en, this message translates to:
  /// **'Invalid coupon code'**
  String get invalid_coupon_code;

  /// No description provided for @coupon_applied_successfully.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied successfully'**
  String get coupon_applied_successfully;

  /// No description provided for @confirm_submit.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Submit'**
  String get confirm_submit;

  /// No description provided for @tap_to_select_image.
  ///
  /// In en, this message translates to:
  /// **'Tap to select image'**
  String get tap_to_select_image;

  /// No description provided for @two_attach_transfer_receipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Transfer Receipt'**
  String get two_attach_transfer_receipt;

  /// No description provided for @enter_transaction_number.
  ///
  /// In en, this message translates to:
  /// **'Enter transaction number'**
  String get enter_transaction_number;

  /// No description provided for @enter_verification_code.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enter_verification_code;

  /// No description provided for @otp_sent_message.
  ///
  /// In en, this message translates to:
  /// **'We have sent OTP on your mobile number'**
  String get otp_sent_message;

  /// No description provided for @your_verification_code.
  ///
  /// In en, this message translates to:
  /// **'Your Verification Code'**
  String get your_verification_code;

  /// No description provided for @did_not_receive_code.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? '**
  String get did_not_receive_code;

  /// No description provided for @resend_code_in.
  ///
  /// In en, this message translates to:
  /// **'Resend code in '**
  String get resend_code_in;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @one_transaction_number.
  ///
  /// In en, this message translates to:
  /// **'Transaction Number'**
  String get one_transaction_number;

  /// No description provided for @account_number.
  ///
  /// In en, this message translates to:
  /// **'Account Number:'**
  String get account_number;

  /// No description provided for @no_bank_accounts_available.
  ///
  /// In en, this message translates to:
  /// **'No bank accounts available'**
  String get no_bank_accounts_available;

  /// No description provided for @our_bank_accounts.
  ///
  /// In en, this message translates to:
  /// **'Our Bank Accounts'**
  String get our_bank_accounts;

  /// No description provided for @iban_bank_transfer.
  ///
  /// In en, this message translates to:
  /// **'IBAN Bank Transfer'**
  String get iban_bank_transfer;

  /// No description provided for @please_enter_transaction_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter transaction number'**
  String get please_enter_transaction_number;

  /// No description provided for @please_attach_the_transfer_receipt.
  ///
  /// In en, this message translates to:
  /// **'Please attach the transfer receipt'**
  String get please_attach_the_transfer_receipt;

  /// No description provided for @please_attach_the_transfer_receipt_and_enter_the_transaction_number.
  ///
  /// In en, this message translates to:
  /// **'Please attach the transfer receipt and enter the transaction number'**
  String
  get please_attach_the_transfer_receipt_and_enter_the_transaction_number;

  /// No description provided for @failed_to_load_bank_accounts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bank accounts'**
  String get failed_to_load_bank_accounts;

  /// No description provided for @total_price.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get total_price;

  /// No description provided for @verify_your_order_details.
  ///
  /// In en, this message translates to:
  /// **'Verify your order details'**
  String get verify_your_order_details;

  /// No description provided for @order_details.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get order_details;

  /// No description provided for @would_you_like_to_add_a_note_to_the_delivery_agent.
  ///
  /// In en, this message translates to:
  /// **'Would you like to add a note to the delivery agent?'**
  String get would_you_like_to_add_a_note_to_the_delivery_agent;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @iban_note.
  ///
  /// In en, this message translates to:
  /// **'Please attach a copy of the transfer receipt to complete the review and approval of your request.'**
  String get iban_note;

  /// No description provided for @most_in_need.
  ///
  /// In en, this message translates to:
  /// **'Most in need'**
  String get most_in_need;

  /// No description provided for @most_needy_meqat_mosque.
  ///
  /// In en, this message translates to:
  /// **'Most needy meqat mosque'**
  String get most_needy_meqat_mosque;

  /// No description provided for @most_needy_orphanage.
  ///
  /// In en, this message translates to:
  /// **'Most needy orphanage'**
  String get most_needy_orphanage;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @back_to_home.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get back_to_home;

  /// No description provided for @back_to_orders.
  ///
  /// In en, this message translates to:
  /// **'Back to Orders'**
  String get back_to_orders;

  /// No description provided for @retry_payment.
  ///
  /// In en, this message translates to:
  /// **'Retry Payment'**
  String get retry_payment;

  /// No description provided for @bank_transfer_receipt_received_awaiting_admin_approval.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer receipt received. Awaiting admin approval.'**
  String get bank_transfer_receipt_received_awaiting_admin_approval;

  /// No description provided for @pending_approval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pending_approval;

  /// No description provided for @an_error_occurred_while_processing_the_payment.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while processing the payment.'**
  String get an_error_occurred_while_processing_the_payment;

  /// No description provided for @payment_failed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get payment_failed;

  /// No description provided for @thank_you_for_your_donation.
  ///
  /// In en, this message translates to:
  /// **'Our team has begun processing your order, and—God willing—it will be delivered within 24 hours.\nOnce completed, you will receive photos and a documentary video via WhatsApp on your registered number, allowing you to witness the impact of your generosity with confidence and transparency.'**
  String get thank_you_for_your_donation;

  /// No description provided for @payment_successful.
  ///
  /// In en, this message translates to:
  /// **'Your order has been successfully placed ✅'**
  String get payment_successful;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @enter_quantity_204.
  ///
  /// In en, this message translates to:
  /// **'Enter Quantity'**
  String get enter_quantity_204;

  /// No description provided for @notes_optional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notes_optional;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @save_return.
  ///
  /// In en, this message translates to:
  /// **'Save & Return'**
  String get save_return;

  /// No description provided for @select_quantities_and_notes.
  ///
  /// In en, this message translates to:
  /// **'Select quantities and notes'**
  String get select_quantities_and_notes;

  /// No description provided for @most_in_need_in.
  ///
  /// In en, this message translates to:
  /// **'Most in need in '**
  String get most_in_need_in;

  /// No description provided for @choose_products_for_each_category.
  ///
  /// In en, this message translates to:
  /// **'Choose products for each category'**
  String get choose_products_for_each_category;

  /// No description provided for @select_products.
  ///
  /// In en, this message translates to:
  /// **'Select Products'**
  String get select_products;

  /// No description provided for @no_plans_available_at_the_moment.
  ///
  /// In en, this message translates to:
  /// **'No plans available at the moment'**
  String get no_plans_available_at_the_moment;

  /// No description provided for @choose_a_subscription_plan.
  ///
  /// In en, this message translates to:
  /// **'Choose a subscription plan'**
  String get choose_a_subscription_plan;

  /// No description provided for @subscription_plans.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscription_plans;

  /// No description provided for @customize_plan.
  ///
  /// In en, this message translates to:
  /// **'Customize Plan'**
  String get customize_plan;

  /// No description provided for @delivery_days_select_maxallowed.
  ///
  /// In en, this message translates to:
  /// **'Delivery Days (Select \$maxAllowed)'**
  String get delivery_days_select_maxallowed;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @subscription_duration_months.
  ///
  /// In en, this message translates to:
  /// **'Subscription Duration (Months)'**
  String get subscription_duration_months;

  /// No description provided for @select_date.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get select_date;

  /// No description provided for @recurring_donation.
  ///
  /// In en, this message translates to:
  /// **'Recurring Order'**
  String get recurring_donation;

  /// No description provided for @too_many_attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get too_many_attempts;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @complaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// No description provided for @complaints_desc.
  ///
  /// In en, this message translates to:
  /// **'Report any issues you faced with your orders.'**
  String get complaints_desc;

  /// No description provided for @your_suggestions_hint.
  ///
  /// In en, this message translates to:
  /// **'Your suggestions are important to us, we are happy to receive them.'**
  String get your_suggestions_hint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @select_complaint.
  ///
  /// In en, this message translates to:
  /// **'Select complaint'**
  String get select_complaint;

  /// No description provided for @complaint_option_1.
  ///
  /// In en, this message translates to:
  /// **'Payment was made but no order was created.'**
  String get complaint_option_1;

  /// No description provided for @complaint_option_2.
  ///
  /// In en, this message translates to:
  /// **'Order was not delivered in the specified time.'**
  String get complaint_option_2;

  /// No description provided for @complaint_option_3.
  ///
  /// In en, this message translates to:
  /// **'Order was delivered to a different mosque than the one specified.'**
  String get complaint_option_3;

  /// No description provided for @complaint_option_4.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get complaint_option_4;

  /// No description provided for @enter_complaint_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your complaint here.'**
  String get enter_complaint_hint;

  /// No description provided for @select_order.
  ///
  /// In en, this message translates to:
  /// **'Select Order'**
  String get select_order;

  /// No description provided for @sign_in_with_provider.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider}'**
  String sign_in_with_provider(String provider);

  /// No description provided for @choose_account_to_continue.
  ///
  /// In en, this message translates to:
  /// **'Choose an account to continue with Rahiq:'**
  String get choose_account_to_continue;

  /// No description provided for @authentication_failed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authentication_failed;

  /// No description provided for @failed_to_send_otp.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP'**
  String get failed_to_send_otp;

  /// No description provided for @otp_sent_successfully.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully!'**
  String get otp_sent_successfully;

  /// No description provided for @failed_to_resend_otp.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP'**
  String get failed_to_resend_otp;

  /// No description provided for @verification_failed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verification_failed;

  /// No description provided for @invalid_otp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalid_otp;

  /// No description provided for @complete_profile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get complete_profile;

  /// No description provided for @enter_first_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get enter_first_name;

  /// No description provided for @enter_last_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get enter_last_name;

  /// No description provided for @enter_email_optional_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enter_email_optional_hint;

  /// No description provided for @enter_phone_number_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enter_phone_number_hint;

  /// No description provided for @order_number.
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get order_number;

  /// No description provided for @registration_failed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registration_failed;

  /// No description provided for @validation_error.
  ///
  /// In en, this message translates to:
  /// **'Validation error'**
  String get validation_error;

  /// No description provided for @validation_error_check_inputs.
  ///
  /// In en, this message translates to:
  /// **'Validation error. Please check your inputs.'**
  String get validation_error_check_inputs;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @field_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get field_required;

  /// No description provided for @enter_valid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enter_valid_email;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @select_gender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get select_gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other_gender.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other_gender;

  /// No description provided for @please_select_gender.
  ///
  /// In en, this message translates to:
  /// **'Please select gender'**
  String get please_select_gender;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get show_more;

  /// No description provided for @all_transactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get all_transactions;

  /// No description provided for @filter_by.
  ///
  /// In en, this message translates to:
  /// **'Filter By'**
  String get filter_by;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @see_the_difference.
  ///
  /// In en, this message translates to:
  /// **'See the difference you\'ve made'**
  String get see_the_difference;

  /// No description provided for @total_donations.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get total_donations;

  /// No description provided for @products_donated.
  ///
  /// In en, this message translates to:
  /// **'Products Donated'**
  String get products_donated;

  /// No description provided for @total_given.
  ///
  /// In en, this message translates to:
  /// **'Total Given'**
  String get total_given;

  /// No description provided for @mosques_helped.
  ///
  /// In en, this message translates to:
  /// **'Mosques Helped'**
  String get mosques_helped;

  /// No description provided for @view_all.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get view_all;

  /// No description provided for @items_donated.
  ///
  /// In en, this message translates to:
  /// **'items donated'**
  String get items_donated;

  /// No description provided for @current_donation_streak.
  ///
  /// In en, this message translates to:
  /// **'Current order streak 🔥'**
  String get current_donation_streak;

  /// No description provided for @no_impact_data_found.
  ///
  /// In en, this message translates to:
  /// **'No impact data found'**
  String get no_impact_data_found;

  /// No description provided for @error_loading_impact.
  ///
  /// In en, this message translates to:
  /// **'Error loading impact statistics'**
  String get error_loading_impact;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @specific_donation.
  ///
  /// In en, this message translates to:
  /// **'Specific'**
  String get specific_donation;

  /// No description provided for @please_select_template.
  ///
  /// In en, this message translates to:
  /// **'Please select template and sub-order'**
  String get please_select_template;

  /// No description provided for @error_applying_gift_card.
  ///
  /// In en, this message translates to:
  /// **'Error applying gift card'**
  String get error_applying_gift_card;

  /// No description provided for @add_gift_card.
  ///
  /// In en, this message translates to:
  /// **'Add gift card'**
  String get add_gift_card;

  /// No description provided for @select_card_template.
  ///
  /// In en, this message translates to:
  /// **'Select Card Template'**
  String get select_card_template;

  /// No description provided for @select_sub_order.
  ///
  /// In en, this message translates to:
  /// **'Select Sub-Order'**
  String get select_sub_order;

  /// No description provided for @sender_name_title.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender_name_title;

  /// No description provided for @enter_sender_name.
  ///
  /// In en, this message translates to:
  /// **'Enter sender name'**
  String get enter_sender_name;

  /// No description provided for @receiver_name_title.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver_name_title;

  /// No description provided for @enter_receiver_name.
  ///
  /// In en, this message translates to:
  /// **'Enter recipient name'**
  String get enter_receiver_name;

  /// No description provided for @receiver_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'Recipient\'s WhatsApp Number'**
  String get receiver_whatsapp;

  /// No description provided for @phone_number_required.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phone_number_required;

  /// No description provided for @invalid_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalid_phone_number;

  /// No description provided for @phone_number_hint.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number_hint;

  /// No description provided for @no_templates_available.
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get no_templates_available;

  /// No description provided for @save_gift_card_info.
  ///
  /// In en, this message translates to:
  /// **'Save Gift Card Info'**
  String get save_gift_card_info;

  /// No description provided for @enter_valid_number_gc.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enter_valid_number_gc;

  /// No description provided for @invalid_phone_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format'**
  String get invalid_phone_format;

  /// No description provided for @field_is_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get field_is_required;

  /// No description provided for @total_orders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get total_orders;

  /// No description provided for @amount_paid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get amount_paid;

  /// No description provided for @sar_currency.
  ///
  /// In en, this message translates to:
  /// **'⃁'**
  String get sar_currency;

  /// No description provided for @people_helped.
  ///
  /// In en, this message translates to:
  /// **'People Helped'**
  String get people_helped;

  /// No description provided for @water_cartons.
  ///
  /// In en, this message translates to:
  /// **'Water Cartons'**
  String get water_cartons;

  /// No description provided for @chillers.
  ///
  /// In en, this message translates to:
  /// **'Chillers'**
  String get chillers;

  /// No description provided for @selected_items_count.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count} items'**
  String selected_items_count(int count);

  /// No description provided for @customer_reviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customer_reviews;

  /// No description provided for @track_order.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get track_order;

  /// No description provided for @view_receipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get view_receipt;

  /// No description provided for @one_time_donation.
  ///
  /// In en, this message translates to:
  /// **'One-time Order'**
  String get one_time_donation;

  /// No description provided for @error_occurred_try_again.
  ///
  /// In en, this message translates to:
  /// **'Error occurred. Try again'**
  String get error_occurred_try_again;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get unit;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get units;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @no_reviews_found.
  ///
  /// In en, this message translates to:
  /// **'No reviews found'**
  String get no_reviews_found;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @no_deliveries_found.
  ///
  /// In en, this message translates to:
  /// **'No deliveries found'**
  String get no_deliveries_found;

  /// No description provided for @purchased_date.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchased_date;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @meal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get meal;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @umbrella.
  ///
  /// In en, this message translates to:
  /// **'Umbrella'**
  String get umbrella;

  /// No description provided for @umbrellas.
  ///
  /// In en, this message translates to:
  /// **'Umbrellas'**
  String get umbrellas;

  /// No description provided for @bottle.
  ///
  /// In en, this message translates to:
  /// **'Bottle'**
  String get bottle;

  /// No description provided for @bottles.
  ///
  /// In en, this message translates to:
  /// **'Bottles'**
  String get bottles;

  /// No description provided for @note_prefix.
  ///
  /// In en, this message translates to:
  /// **'Note -'**
  String get note_prefix;

  /// No description provided for @incl_sar.
  ///
  /// In en, this message translates to:
  /// **'* Incl. ⃁'**
  String get incl_sar;

  /// No description provided for @delivery_suffix.
  ///
  /// In en, this message translates to:
  /// **'delivery'**
  String get delivery_suffix;

  /// No description provided for @inclusive_of_sar.
  ///
  /// In en, this message translates to:
  /// **'Inclusive of ⃁'**
  String get inclusive_of_sar;

  /// No description provided for @delivery_charge.
  ///
  /// In en, this message translates to:
  /// **'delivery charge'**
  String get delivery_charge;

  /// No description provided for @product_details.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get product_details;

  /// No description provided for @location_details.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get location_details;

  /// No description provided for @financial_details.
  ///
  /// In en, this message translates to:
  /// **'Financial Details'**
  String get financial_details;

  /// No description provided for @payment_details.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get payment_details;

  /// No description provided for @payment_status.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get payment_status;

  /// No description provided for @payment_status_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payment_status_paid;

  /// No description provided for @payment_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get payment_status_pending;

  /// No description provided for @payment_status_awaiting_verification.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Verification'**
  String get payment_status_awaiting_verification;

  /// No description provided for @payment_status_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get payment_status_failed;

  /// No description provided for @payment_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get payment_status_cancelled;

  /// No description provided for @payment_status_refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get payment_status_refunded;

  /// No description provided for @payment_method_wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get payment_method_wallet;

  /// No description provided for @payment_method_free.
  ///
  /// In en, this message translates to:
  /// **'Free Order'**
  String get payment_method_free;

  /// No description provided for @payment_method_manual.
  ///
  /// In en, this message translates to:
  /// **'Cash / Offline'**
  String get payment_method_manual;

  /// No description provided for @payment_method_apple_pay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get payment_method_apple_pay;

  /// No description provided for @payment_method_stc_pay.
  ///
  /// In en, this message translates to:
  /// **'STC Pay'**
  String get payment_method_stc_pay;

  /// No description provided for @payment_method_credit_card.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get payment_method_credit_card;

  /// No description provided for @payment_method_iban.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get payment_method_iban;

  /// No description provided for @manual_payment_note.
  ///
  /// In en, this message translates to:
  /// **'Payment collected offline or handled by customer support.'**
  String get manual_payment_note;

  /// No description provided for @total_paid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get total_paid;

  /// No description provided for @amount_value.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount_value;

  /// No description provided for @please_select_bank_account.
  ///
  /// In en, this message translates to:
  /// **'Please select a bank account'**
  String get please_select_bank_account;

  /// No description provided for @please_select_designated_bank_account.
  ///
  /// In en, this message translates to:
  /// **'Please select your designated bank account for the transfer.'**
  String get please_select_designated_bank_account;

  /// No description provided for @order_received_iban_message.
  ///
  /// In en, this message translates to:
  /// **'Your order is received and will be confirmed after payment verification.'**
  String get order_received_iban_message;

  /// No description provided for @products_selected.
  ///
  /// In en, this message translates to:
  /// **'Products Selected'**
  String get products_selected;

  /// No description provided for @available_balance_colon.
  ///
  /// In en, this message translates to:
  /// **'Available balance: '**
  String get available_balance_colon;

  /// No description provided for @gift_card_fees.
  ///
  /// In en, this message translates to:
  /// **'Gift card fees'**
  String get gift_card_fees;

  /// No description provided for @gift_card_added.
  ///
  /// In en, this message translates to:
  /// **'Gift card added'**
  String get gift_card_added;

  /// No description provided for @show_gift_cards.
  ///
  /// In en, this message translates to:
  /// **'Show gift cards'**
  String get show_gift_cards;

  /// No description provided for @added_gift_cards.
  ///
  /// In en, this message translates to:
  /// **'Added gift cards'**
  String get added_gift_cards;

  /// No description provided for @view_and_delete_gift_cards.
  ///
  /// In en, this message translates to:
  /// **'View and delete gift cards'**
  String get view_and_delete_gift_cards;

  /// No description provided for @error_removing_gift_card.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while removing the gift card'**
  String get error_removing_gift_card;

  /// No description provided for @delete_all_cards.
  ///
  /// In en, this message translates to:
  /// **'Delete all cards'**
  String get delete_all_cards;

  /// No description provided for @choose_water_package_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose the water package that suits you'**
  String get choose_water_package_desc;

  /// No description provided for @sar_per_unit.
  ///
  /// In en, this message translates to:
  /// **'⃁ / unit'**
  String get sar_per_unit;

  /// No description provided for @my_chillers.
  ///
  /// In en, this message translates to:
  /// **'My Chillers'**
  String get my_chillers;

  /// No description provided for @my_chillers_subtitle.
  ///
  /// In en, this message translates to:
  /// **'View the status of donated chillers'**
  String get my_chillers_subtitle;

  /// No description provided for @rate_order.
  ///
  /// In en, this message translates to:
  /// **'Rate Order'**
  String get rate_order;

  /// No description provided for @submit_review.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submit_review;

  /// No description provided for @write_review.
  ///
  /// In en, this message translates to:
  /// **'Write your review...'**
  String get write_review;

  /// No description provided for @review_submitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully'**
  String get review_submitted;

  /// No description provided for @rate_order_title.
  ///
  /// In en, this message translates to:
  /// **'Rate your order'**
  String get rate_order_title;

  /// No description provided for @how_was_your_experience.
  ///
  /// In en, this message translates to:
  /// **'How was your experience?'**
  String get how_was_your_experience;

  /// No description provided for @track_donation.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get track_donation;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'Since '**
  String get since;

  /// No description provided for @everyday.
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get everyday;

  /// No description provided for @once_a_week.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get once_a_week;

  /// No description provided for @once_a_month.
  ///
  /// In en, this message translates to:
  /// **'Once a month'**
  String get once_a_month;

  /// No description provided for @tap_to_view.
  ///
  /// In en, this message translates to:
  /// **'Tap item to view media'**
  String get tap_to_view;

  /// No description provided for @twice_a_week.
  ///
  /// In en, this message translates to:
  /// **'Twice a week'**
  String get twice_a_week;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @status_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get status_active;

  /// No description provided for @mosques.
  ///
  /// In en, this message translates to:
  /// **'mosques'**
  String get mosques;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get status_cancelled;

  /// No description provided for @status_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get status_expired;

  /// No description provided for @status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get status_pending;

  /// No description provided for @status_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get status_completed;

  /// No description provided for @choose_quantity.
  ///
  /// In en, this message translates to:
  /// **'Choose Quantity'**
  String get choose_quantity;

  /// No description provided for @view_invoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get view_invoice;

  /// No description provided for @could_not_open_invoice.
  ///
  /// In en, this message translates to:
  /// **'Could not open invoice'**
  String get could_not_open_invoice;

  /// No description provided for @error_loading_order_details.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order details'**
  String get error_loading_order_details;

  /// No description provided for @error_occurred_loading_order.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading order details.'**
  String get error_occurred_loading_order;

  /// No description provided for @error_title.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error_title;

  /// No description provided for @order_placed.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get order_placed;

  /// No description provided for @current_status.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get current_status;

  /// No description provided for @delivering_to.
  ///
  /// In en, this message translates to:
  /// **'Delivering to'**
  String get delivering_to;

  /// No description provided for @delivery_progress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Progress'**
  String get delivery_progress;

  /// No description provided for @delivery_completed.
  ///
  /// In en, this message translates to:
  /// **'Delivery completed'**
  String get delivery_completed;

  /// No description provided for @proof_of_delivery.
  ///
  /// In en, this message translates to:
  /// **'Proof of Delivery'**
  String get proof_of_delivery;

  /// No description provided for @mosque_front.
  ///
  /// In en, this message translates to:
  /// **'Mosque Front'**
  String get mosque_front;

  /// No description provided for @mosque_inside.
  ///
  /// In en, this message translates to:
  /// **'Mosque Inside'**
  String get mosque_inside;

  /// No description provided for @packages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packages;

  /// No description provided for @proof_product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get proof_product;

  /// No description provided for @delivery_video.
  ///
  /// In en, this message translates to:
  /// **'Delivery Video'**
  String get delivery_video;

  /// No description provided for @mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get mark_all_read;

  /// No description provided for @clear_notifications.
  ///
  /// In en, this message translates to:
  /// **'Clear notifications'**
  String get clear_notifications;

  /// No description provided for @no_deliveries_found_for_this_order.
  ///
  /// In en, this message translates to:
  /// **'No deliveries found for this order.'**
  String get no_deliveries_found_for_this_order;

  /// No description provided for @no_details_found.
  ///
  /// In en, this message translates to:
  /// **'No details found.'**
  String get no_details_found;

  /// No description provided for @no_orders_found.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get no_orders_found;

  /// No description provided for @failed_to_mark_all_as_read.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark all as read'**
  String get failed_to_mark_all_as_read;

  /// No description provided for @failed_to_clear_notifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear notifications'**
  String get failed_to_clear_notifications;

  /// No description provided for @failed_to_retrieve_google_id_token.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve Google ID token'**
  String get failed_to_retrieve_google_id_token;

  /// No description provided for @failed_to_retrieve_apple_identity_token.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve Apple Identity token'**
  String get failed_to_retrieve_apple_identity_token;

  /// No description provided for @failed_to_sign_in_google.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with Google'**
  String get failed_to_sign_in_google;

  /// No description provided for @failed_to_sign_in_apple.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with Apple'**
  String get failed_to_sign_in_apple;

  /// No description provided for @google_sign_in_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign in was cancelled'**
  String get google_sign_in_cancelled;

  /// No description provided for @apple_sign_in_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Apple sign in was cancelled'**
  String get apple_sign_in_cancelled;

  /// No description provided for @failed_to_submit_review.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review'**
  String get failed_to_submit_review;

  /// No description provided for @failed_to_load_orders_page.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders page'**
  String get failed_to_load_orders_page;

  /// No description provided for @no_chillers_found.
  ///
  /// In en, this message translates to:
  /// **'No chillers found'**
  String get no_chillers_found;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @gift_card.
  ///
  /// In en, this message translates to:
  /// **'Gift Card'**
  String get gift_card;

  /// No description provided for @chiller_info.
  ///
  /// In en, this message translates to:
  /// **'Chiller Info'**
  String get chiller_info;

  /// No description provided for @chiller_available.
  ///
  /// In en, this message translates to:
  /// **'Chiller Available'**
  String get chiller_available;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @delivered_to.
  ///
  /// In en, this message translates to:
  /// **'Delivered To'**
  String get delivered_to;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @coupon_not_applicable.
  ///
  /// In en, this message translates to:
  /// **'Coupon codes cannot be applied to this order'**
  String get coupon_not_applicable;

  /// No description provided for @profile_picture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profile_picture;

  /// No description provided for @back_online.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get back_online;

  /// No description provided for @no_delivery_video_available.
  ///
  /// In en, this message translates to:
  /// **'No delivery video is available for this order yet.'**
  String get no_delivery_video_available;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @failed_to_load_notifications.
  ///
  /// In en, this message translates to:
  /// **'failed_to_load_notifications'**
  String get failed_to_load_notifications;

  /// No description provided for @failed_to_load_orders.
  ///
  /// In en, this message translates to:
  /// **'failed_to_load_orders'**
  String get failed_to_load_orders;

  /// No description provided for @priceIncludesDistributionDeliveryAndDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Price includes distribution, delivery, and documention.'**
  String get priceIncludesDistributionDeliveryAndDocumentation;

  /// No description provided for @deliveredToDifferentLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivered to a different location'**
  String get deliveredToDifferentLocation;

  /// No description provided for @reasonForDifferentLocation.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonForDifferentLocation;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get error;

  /// No description provided for @minimum_quantity_for_location_is.
  ///
  /// In en, this message translates to:
  /// **'minimum quantity for one location is {min}'**
  String minimum_quantity_for_location_is(String min);

  /// No description provided for @internet_error.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get internet_error;

  /// Displays how far something is from the user
  ///
  /// In en, this message translates to:
  /// **'{distance} km away from you'**
  String distanceAway(String distance);

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @filter_orders.
  ///
  /// In en, this message translates to:
  /// **'Filter Orders'**
  String get filter_orders;

  /// No description provided for @order_type.
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get order_type;

  /// No description provided for @general_orders.
  ///
  /// In en, this message translates to:
  /// **'General Orders'**
  String get general_orders;

  /// No description provided for @gift_orders.
  ///
  /// In en, this message translates to:
  /// **'Gift Orders'**
  String get gift_orders;

  /// No description provided for @order_date.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get order_date;

  /// No description provided for @select_month.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get select_month;

  /// No description provided for @last_6_months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get last_6_months;

  /// No description provided for @this_year.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get this_year;

  /// No description provided for @follow_us.
  ///
  /// In en, this message translates to:
  /// **'Follow us'**
  String get follow_us;

  /// No description provided for @refills.
  ///
  /// In en, this message translates to:
  /// **'Refills'**
  String get refills;

  /// No description provided for @last_refilled.
  ///
  /// In en, this message translates to:
  /// **'Last refilled'**
  String get last_refilled;

  /// No description provided for @chiller_not_found.
  ///
  /// In en, this message translates to:
  /// **'Chiller not found.'**
  String get chiller_not_found;

  /// No description provided for @invalid_chiller_product.
  ///
  /// In en, this message translates to:
  /// **'Invalid chiller product.'**
  String get invalid_chiller_product;

  /// No description provided for @chiller_must_be_delivered_before_refilling.
  ///
  /// In en, this message translates to:
  /// **'Chiller must be delivered before refilling.'**
  String get chiller_must_be_delivered_before_refilling;

  /// No description provided for @chiller_currently_unavailable_for_refills.
  ///
  /// In en, this message translates to:
  /// **'Chiller is currently unavailable for refills.'**
  String get chiller_currently_unavailable_for_refills;

  /// No description provided for @chiller_has_no_assigned_location.
  ///
  /// In en, this message translates to:
  /// **'Chiller has no assigned location.'**
  String get chiller_has_no_assigned_location;

  /// No description provided for @chiller_refill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get chiller_refill;

  /// Message shared by the user when inviting others to install the app
  ///
  /// In en, this message translates to:
  /// **'Rahiq App 💧:- A water delivery service for mosques and orphanages 🚚🕌. The Prophet ﷺ said: \"Whoever guides someone to good will have a reward like the one who did it\" 🌷: Share the app - {link}'**
  String share_app_message(String link);

  /// Time left on a subscription, shown once 30 or more days remain
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month left} other{{count} months left}}'**
  String months_left(int count);

  /// Time left on a subscription, shown while fewer than 30 days remain
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Ends today} =1{1 day left} other{{count} days left}}'**
  String days_left(int count);

  /// Progress through the orders of a subscription
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Delivered {completed} of 1 order} other{Delivered {completed} of {total} orders}}'**
  String delivered_x_of_y_orders(int completed, int total);

  /// No description provided for @subscription_expired.
  ///
  /// In en, this message translates to:
  /// **'Subscription expired'**
  String get subscription_expired;

  /// No description provided for @delivery_calendar.
  ///
  /// In en, this message translates to:
  /// **'Delivery Calendar'**
  String get delivery_calendar;
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
