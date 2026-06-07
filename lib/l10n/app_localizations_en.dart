// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rahiq';

  @override
  String get welcomeMessage => 'Welcome to Rahiq!';

  @override
  String get onboard1_title => 'Give with Purpose';

  @override
  String get onboard1_subtitle =>
      'Make a meaningful difference by providing water to those who need it most.';

  @override
  String get onboard2_title => 'Simple. Transparent. Reliable.';

  @override
  String get onboard2_subtitle =>
      'Choose where to give, and we’ll handle the rest.';

  @override
  String get onboard3_title => 'Start Your Journey of Giving';

  @override
  String get onboard3_subtitle =>
      'Your small act can serve hundreds and create continuous الخير.';

  @override
  String get skip => 'SKIP';

  @override
  String get continue_btn => 'Continue';

  @override
  String get start_donating => 'Start Donating';

  @override
  String get new_to_donate => 'New to donate?';

  @override
  String get terms_agree_prefix => 'By continuing, you agree to our ';

  @override
  String get terms_conditions => 'Terms & Conditions';

  @override
  String get and => ' and ';

  @override
  String get privacy_policy => 'Privacy Policy';

  @override
  String get login => 'Login';

  @override
  String get enter_phone => 'Enter Your Mobile Number';

  @override
  String get otp_message =>
      'Enter your mobile number to continue.\nWe will send an OTP for verification.';

  @override
  String get or => 'or';

  @override
  String get google_signin => 'Sign in with Google';

  @override
  String get apple_signin => 'Sign in with Apple';

  @override
  String get search => 'Search';

  @override
  String get home => 'Home';

  @override
  String get orders => 'Orders';

  @override
  String get impact => 'Impact';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get logout_confirmation =>
      'Are you sure you want to log out of Raheeq?';

  @override
  String get cancel => 'Cancel';

  @override
  String get no_session => 'No session found. Please log in.';

  @override
  String get personal_information => 'Personal Information';

  @override
  String get saved_mosques => 'Saved Mosques';

  @override
  String get recurring_donations => 'Recurring Donations';

  @override
  String get tax_receipts => 'Tax Receipts';

  @override
  String get my_wallet => 'My Wallet';

  @override
  String get payment_methods => 'Payment Methods';

  @override
  String get order_history => 'Order History';

  @override
  String get notifications => 'Notifications';

  @override
  String get app_settings => 'App Settings';

  @override
  String get help_center => 'Help Center';

  @override
  String get contact_us => 'Contact Us';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get first_name => 'First Name';

  @override
  String get last_name => 'Last Name';

  @override
  String get email_address => 'Email Address';

  @override
  String get phone_number => 'Phone Number';

  @override
  String get profile_updated => 'Profile updated successfully!';

  @override
  String get profile_pic_updated => 'Profile picture updated successfully!';

  @override
  String get orders_live_soon => 'Orders will be live soon...';

  @override
  String get impact_page => 'Impact Page';

  @override
  String get no_products_selected => 'No products selected';

  @override
  String get guest_user_email => 'guest_user@suqyarahiq.com';

  @override
  String get guest_user => 'Guest User';

  @override
  String get login_successful => 'Login Successful';

  @override
  String get enter_valid_otp => 'Please enter valid OTP';

  @override
  String removed_from_saved(String name) {
    return '$name removed from saved mosques.';
  }

  @override
  String get failed_to_remove_mosque => 'Failed to remove mosque.';

  @override
  String get failed_to_update_favorite => 'Failed to update favorite.';

  @override
  String get failed_to_load_wallet => 'Failed to load wallet data.';

  @override
  String minimum_quantity_is(String min) {
    return 'Minimum quantity is $min';
  }

  @override
  String get example_quantity => 'e.g., 50';

  @override
  String error_msg(String error) {
    return 'Error: $error';
  }

  @override
  String failed_to_pick_image(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String failed_upload_simulation(String error) {
    return 'Failed upload simulation: $error';
  }

  @override
  String get track_mosque_donations => 'Track your mosque donations';

  @override
  String get ongoing_charity_rewards => 'Your ongoing charity rewards';

  @override
  String get manage_account_settings => 'Manage your account settings';

  @override
  String get raheeq => 'Raheeq';

  @override
  String get my_orders => 'My Orders';

  @override
  String get new_orders => 'New Orders';

  @override
  String get out_for_delivery => 'Out for Delivery';

  @override
  String get delivered => 'Delivered';

  @override
  String get transaction_history => 'Transaction History';

  @override
  String get no_transactions_found => 'No transactions found.';

  @override
  String get current_balance => 'Current Balance';

  @override
  String get account_section => 'Account';

  @override
  String get payment_orders_section => 'Payment & orders';

  @override
  String get settings_section => 'Settings';

  @override
  String get support_section => 'Support';

  @override
  String get feature_coming_soon => 'This feature is coming soon';

  @override
  String get redirecting_payment_methods =>
      'Redirecting to My Payment Methods...';

  @override
  String get redirecting_terms => 'Redirecting to Terms and Conditions...';

  @override
  String get donations_label => 'Donations';

  @override
  String get mosques_label => 'Mosques';

  @override
  String get people_label => 'People';

  @override
  String get serveTheGuestOfAllah => 'Serve The Guest of Allah';

  @override
  String get build_number => 'Build Number';

  @override
  String get version => 'Version';

  @override
  String get app_information => 'App Information';

  @override
  String get theme_switching_coming_soon => 'Theme switching coming soon';

  @override
  String get dark_mode => 'Dark Mode';

  @override
  String get app_language => 'App Language';

  @override
  String get manage_preferences_and_app_info =>
      'Manage preferences and app info';

  @override
  String get recurring_impact => 'Recurring impact';

  @override
  String get monthly => 'Monthly';

  @override
  String get single_donation => 'Single donation';

  @override
  String get one_time => 'One-Time';

  @override
  String get support_once_or_make_a_lasting_impact =>
      'Support once or make a lasting impact';

  @override
  String get choose_donation_type => 'Choose Donation Type';

  @override
  String get payable_amount => 'Payable Amount';

  @override
  String get add_note => 'Add note';

  @override
  String get enter_quantity => 'Enter quantity';

  @override
  String get or_enter_custom_quantity_min_min =>
      'Or enter custom quantity (min. \$min)';

  @override
  String get select_your_impact => 'Select Your Impact';

  @override
  String get select_a_product_to_continue => 'Select a product to continue';

  @override
  String get no_cities_found => 'No cities found';

  @override
  String get search_for_a_city => 'Search for a city...';

  @override
  String get select_the_most_needy_cities => 'Select the most needy cities';

  @override
  String get choose_cities => 'Choose Cities';

  @override
  String get confirm_selection => 'Confirm Selection';

  @override
  String get clear_all => 'Clear All';

  @override
  String get deliver_blessings => 'Deliver Blessings.';

  @override
  String get give_water => 'Give Water.';

  @override
  String get we => 'We';

  @override
  String get coming_soon => 'Coming Soon...';

  @override
  String get your_impact => 'Your Impact';

  @override
  String get view_status_and_delivery_details =>
      'View status and delivery details.';

  @override
  String get recent_donations => 'Recent Donations';

  @override
  String get sar => 'SAR';

  @override
  String get starting_from => 'Starting from';

  @override
  String get high_need => 'High Need';

  @override
  String get essential_mosque_supplies => 'Essential Mosque Supplies';

  @override
  String get choose_your_cause_and_make_an_impact =>
      'Choose your cause and make an impact';

  @override
  String get quick_actions => 'Quick Actions';

  @override
  String get donate_now => 'Donate Now   ';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get i_understand => 'I understand';

  @override
  String
  get your_current_basket_will_be_cleared_and_you_will_be_moved_to_targetname =>
      'Your current basket will be cleared and you will be moved to \$targetName.';

  @override
  String get warning => 'Warning';

  @override
  String get retry => 'Retry';

  @override
  String get failed_to_load_home_page => 'Failed to load home page';

  @override
  String get choose_mosques => 'Choose Mosques';

  @override
  String get order_now => 'Order Now';

  @override
  String get assalamu_alaikum => 'Assalamu Alaikum';

  @override
  String get latest_updates_and_alerts => 'Latest updates and alerts';

  @override
  String get no_delivered_orders => 'No delivered orders';

  @override
  String get no_new_orders => 'No new orders';

  @override
  String get total_amount => 'Total Amount';

  @override
  String get minimum_order_min_units => 'Minimum order: \$min units';

  @override
  String get enter_quantity_min_min => 'Enter quantity (min: \$min)';

  @override
  String get custom => 'Custom';

  @override
  String get for_name => 'for: \$name';

  @override
  String get select_quantity => 'Select Quantity';

  @override
  String get quick_services => 'Quick Services';

  @override
  String get no_products_available => 'No products available';

  @override
  String get select_a_product => 'Select a Product';

  @override
  String get no_active_subscriptions => 'No active subscriptions';

  @override
  String get manage_your_subscriptions => 'Manage your subscriptions';

  @override
  String get no_saved_mosques_found => 'No saved mosques found.';

  @override
  String get your_favorite_mosques => 'Your favorite mosques';

  @override
  String get no_mosques_found => 'No mosques found';

  @override
  String get no_meqat_mosques_found => 'No meqat mosques found';

  @override
  String get no_orphanages_found => 'No orphanages found';

  @override
  String get select_city => 'Select city';

  @override
  String get search_mosques => 'Search mosques...';

  @override
  String get search_meqat_mosques => 'Search meqat mosques...';

  @override
  String get search_orphanages => 'Search orphanages...';

  @override
  String get choose_from_map => 'Choose from Map';

  @override
  String get list_of_mosques => 'List of Mosques';

  @override
  String get select_a_mosque_to_deliver_water_to =>
      'Select a mosque to deliver water to';

  @override
  String get choose_specific_mosque => 'Choose Specific Mosque';

  @override
  String get list_of_meqat_mosques => 'List of Meqat mosques';

  @override
  String get choose_specific_meqat_mosque => 'Choose Specific Meqat Mosque';

  @override
  String get list_of_orphanages => 'List of Orphanages';

  @override
  String get select_an_orphanage_to_deliver_water_to =>
      'Select an orphanage to deliver water to';

  @override
  String get choose_specific_orphanage => 'Choose Specific Orphanage';

  @override
  String get clear_selection => 'Clear Selection';

  @override
  String get choose_donation_type_108 => 'Choose donation type';

  @override
  String get specific => 'Specific';

  @override
  String get most_needy => 'Most needy';

  @override
  String get two_year_guarantee => '2 Year Guarantee';

  @override
  String get select_the_water_package_that_suits_you =>
      'Select the water package that suits you';

  @override
  String get choose_water_package => 'Choose Water Package';

  @override
  String get free => 'Free';

  @override
  String get confirm_pay => 'Confirm & Pay';

  @override
  String get wallet_applied => 'Wallet Applied';

  @override
  String get discount => 'Discount';

  @override
  String get vat => 'VAT';

  @override
  String get delivery_fee => 'Delivery Fee';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get contribution_details => 'Contribution Details';

  @override
  String get apply => 'Apply';

  @override
  String get remove => 'Remove';

  @override
  String get use_wallet_balance => 'Use Wallet Balance';

  @override
  String get enter_coupon_code => 'Enter coupon code';

  @override
  String get coupon_code => 'Coupon Code';

  @override
  String get do_you_want_to_give_a_gift_to_someone_close_to_you =>
      'Do you want to give a gift to someone close to you?';

  @override
  String get donation_type => 'Donation Type';

  @override
  String get final_review_and_payment => 'Final review and payment';

  @override
  String get payment => 'Payment';

  @override
  String get subscription_details => 'Subscription Details';

  @override
  String get delivery_days => 'Delivery Days';

  @override
  String get months => 'Months';

  @override
  String get start_date => 'Start Date';

  @override
  String get end_date => 'End Date';

  @override
  String get total_days => 'Total Days';

  @override
  String get payment_was_cancelled => 'Payment was cancelled';

  @override
  String get error_verifying_payment => 'Error verifying payment';

  @override
  String get pay_with_card => 'Pay with Card';

  @override
  String get payment_method => 'Payment Method';

  @override
  String get stc_pay => 'STC Pay';

  @override
  String get apple_pay => 'Apple Pay';

  @override
  String get credit_card_mada => 'Credit Card / Mada';

  @override
  String get failed_to_apply_wallet => 'Failed to apply wallet';

  @override
  String get insufficient_balance_to_apply_wallet =>
      'Insufficient balance to apply wallet';

  @override
  String get failed_to_remove_coupon => 'Failed to remove coupon';

  @override
  String get coupon_removed_successfully => 'Coupon removed successfully';

  @override
  String get invalid_coupon_code => 'Invalid coupon code';

  @override
  String get coupon_applied_successfully => 'Coupon applied successfully';

  @override
  String get confirm_submit => 'Confirm & Submit';

  @override
  String get tap_to_select_image => 'Tap to select image';

  @override
  String get two_attach_transfer_receipt => '2. Attach Transfer Receipt';

  @override
  String get enter_transaction_number => 'Enter transaction number';

  @override
  String get enter_verification_code => 'Enter Verification Code';

  @override
  String get otp_sent_message => 'We have sent OTP on your mobile number';

  @override
  String get your_verification_code => 'Your Verification Code';

  @override
  String get did_not_receive_code => 'Didn\'t receive code? ';

  @override
  String get resend_code_in => 'Resend code in ';

  @override
  String get resend => 'Resend';

  @override
  String get one_transaction_number => '1. Transaction Number :';

  @override
  String get account_number => 'Account Number:';

  @override
  String get no_bank_accounts_available => 'No bank accounts available';

  @override
  String get our_bank_accounts => 'Our Bank Accounts';

  @override
  String get iban_bank_transfer => 'IBAN Bank Transfer';

  @override
  String get please_enter_transaction_number =>
      'Please enter transaction number';

  @override
  String get please_attach_the_transfer_receipt =>
      'Please attach the transfer receipt';

  @override
  String
  get please_attach_the_transfer_receipt_and_enter_the_transaction_number =>
      'Please attach the transfer receipt and enter the transaction number';

  @override
  String get failed_to_load_bank_accounts => 'Failed to load bank accounts';

  @override
  String get total_price => 'Total Price';

  @override
  String get verify_your_order_details => 'Verify your order details';

  @override
  String get order_details => 'Order Details';

  @override
  String get would_you_like_to_add_a_note_to_the_delivery_agent =>
      'Would you like to add a note to the delivery agent?';

  @override
  String get general => 'General';

  @override
  String get most_in_need => 'Most in need';

  @override
  String get most_needy_meqat_mosque => 'Most needy meqat mosque';

  @override
  String get most_needy_orphanage => 'Most needy orphanage';

  @override
  String get subscription => 'Subscription';

  @override
  String get back_to_home => 'Back to Home';

  @override
  String get retry_payment => 'Retry Payment';

  @override
  String get bank_transfer_receipt_received_awaiting_admin_approval =>
      'Bank transfer receipt received. Awaiting admin approval.';

  @override
  String get pending_approval => 'Pending Approval';

  @override
  String get an_error_occurred_while_processing_the_payment =>
      'An error occurred while processing the payment.';

  @override
  String get payment_failed => 'Payment Failed';

  @override
  String get thank_you_for_your_donation => 'Thank you for your donation.';

  @override
  String get payment_successful => 'Payment Successful!';

  @override
  String get confirm => 'Confirm';

  @override
  String get enter_quantity_204 => 'Enter Quantity';

  @override
  String get notes_optional => 'Notes (Optional)';

  @override
  String get quantity => 'Quantity';

  @override
  String get save_return => 'Save & Return';

  @override
  String get select_quantities_and_notes => 'Select quantities and notes';

  @override
  String get most_in_need_in => 'Most in need in ';

  @override
  String get choose_products_for_each_category =>
      'Choose products for each category';

  @override
  String get select_products => 'Select Products';

  @override
  String get no_plans_available_at_the_moment =>
      'No plans available at the moment';

  @override
  String get choose_a_subscription_plan => 'Choose a subscription plan';

  @override
  String get subscription_plans => 'Subscription Plans';

  @override
  String get customize_plan => 'Customize Plan';

  @override
  String get delivery_days_select_maxallowed =>
      'Delivery Days (Select \$maxAllowed)';

  @override
  String get sun => 'Sun';

  @override
  String get sat => 'Sat';

  @override
  String get fri => 'Fri';

  @override
  String get thu => 'Thu';

  @override
  String get wed => 'Wed';

  @override
  String get tue => 'Tue';

  @override
  String get mon => 'Mon';

  @override
  String get subscription_duration_months => 'Subscription Duration (Months)';

  @override
  String get select_date => 'Select Date';

  @override
  String get recurring_donation => 'Recurring Donation';
}
