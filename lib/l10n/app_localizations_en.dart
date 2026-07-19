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
  String get available_colon => 'Available :';

  @override
  String get welcome => 'Ahlan';

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
  String get recurring_donations => 'Recurring Orders';

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
  String get contact_us_desc =>
      'Reach out to us via live chat for immediate support.';

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
  String get order => 'Order';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get guest_user_email => 'guest_user@suqyarahiq.com';

  @override
  String get guest_user => 'Guest User';

  @override
  String get no_orders_out_for_delivery => 'No orders out for delivery';

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
  String get track_your_donations => 'Track your Orders';

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
  String get single_donation => 'Single order';

  @override
  String get one_time => 'One-Time';

  @override
  String get support_once_or_make_a_lasting_impact =>
      'Support once or make a lasting impact';

  @override
  String get choose_donation_type => 'Choose order destination';

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
  String get select_your_impact => 'Make An Impact That Lasts';

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
  String get kilometer => 'Km';

  @override
  String get meter => 'm';

  @override
  String get coming_soon => 'Coming Soon...';

  @override
  String get your_impact => 'Your Impact';

  @override
  String get view_status_and_delivery_details =>
      'View status and delivery details.';

  @override
  String get recent_donations => 'Recent Orders';

  @override
  String get products_overview => 'Products Overview';

  @override
  String get donations_overview => 'Orders Overview';

  @override
  String get orphanages_helped => 'Orphanages Helped';

  @override
  String get sar => '⃁';

  @override
  String get starting_from => 'Starting from';

  @override
  String get high_need => 'High Need';

  @override
  String get essential_mosque_supplies => 'Essential Mosque Supplies';

  @override
  String get choose_where_to_give_and_create_a_lasting_impact =>
      'Choose where to give and create a lasting impact.';

  @override
  String get giving_opportunities => 'Giving Opportunities';

  @override
  String get donate_now => 'Donate Now';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get no_new_notifications => 'No New Notifications';

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
  String get choose_donation_type_108 => 'Choose type of order';

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
  String get choose_water_package => 'Choose what the mosque needs';

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
  String get feedback_submitted_successfully =>
      'Feedback submitted successfully';

  @override
  String get coupon_code => 'Coupon Code';

  @override
  String
  get gift_your_loved_ones_the_blessing_of_providing_water_in_the_holiest_places =>
      'Gift your loved ones the blessing of providing water in the holiest places.';

  @override
  String get donation_type => 'Order Type';

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
  String get two_attach_transfer_receipt => 'Upload Transfer Receipt';

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
  String get one_transaction_number => 'Transaction Number';

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
  String get thank_you_for_your_donation => 'Thank you for your order.';

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
  String get recurring_donation => 'Recurring Order';

  @override
  String get too_many_attempts => 'Too many attempts. Please try again later.';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get complaints => 'Complaints';

  @override
  String get complaints_desc => 'Report any issues you faced with your orders.';

  @override
  String get your_suggestions_hint =>
      'Your suggestions are important to us, we are happy to receive them.';

  @override
  String get send => 'Send';

  @override
  String get select_complaint => 'Select complaint';

  @override
  String get complaint_option_1 => 'Payment was made but no order was created.';

  @override
  String get complaint_option_2 =>
      'Order was not delivered in the specified time.';

  @override
  String get complaint_option_3 =>
      'Order was delivered to a different mosque than the one specified.';

  @override
  String get complaint_option_4 => 'Other';

  @override
  String get enter_complaint_hint => 'Enter your complaint here.';

  @override
  String get select_order => 'Select Order';

  @override
  String sign_in_with_provider(String provider) {
    return 'Sign in with $provider';
  }

  @override
  String get choose_account_to_continue =>
      'Choose an account to continue with Raheeq:';

  @override
  String get authentication_failed => 'Authentication failed';

  @override
  String get failed_to_send_otp => 'Failed to send OTP';

  @override
  String get otp_sent_successfully => 'OTP sent successfully!';

  @override
  String get failed_to_resend_otp => 'Failed to resend OTP';

  @override
  String get verification_failed => 'Verification failed';

  @override
  String get invalid_otp => 'Invalid OTP';

  @override
  String get complete_profile => 'Complete Profile';

  @override
  String get enter_first_name => 'Enter your first name';

  @override
  String get enter_last_name => 'Enter your last name';

  @override
  String get enter_email_optional_hint => 'Enter your email';

  @override
  String get enter_phone_number_hint => 'Enter phone number';

  @override
  String get order_number => 'Order Number';

  @override
  String get registration_failed => 'Registration failed';

  @override
  String get validation_error => 'Validation error';

  @override
  String get validation_error_check_inputs =>
      'Validation error. Please check your inputs.';

  @override
  String get register => 'Register';

  @override
  String get field_required => 'This field is required';

  @override
  String get enter_valid_email => 'Please enter a valid email address';

  @override
  String get gender => 'Gender';

  @override
  String get select_gender => 'Select Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other_gender => 'Other';

  @override
  String get please_select_gender => 'Please select gender';

  @override
  String get show_more => 'Show More';

  @override
  String get all_transactions => 'All Transactions';

  @override
  String get filter_by => 'Filter By';

  @override
  String get day => 'Day';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get all => 'All';

  @override
  String get see_the_difference => 'See the difference you\'ve made';

  @override
  String get total_donations => 'Total Orders';

  @override
  String get products_donated => 'Products Donated';

  @override
  String get total_given => 'Total Given';

  @override
  String get mosques_helped => 'Mosques Helped';

  @override
  String get view_all => 'View All';

  @override
  String get items_donated => 'items donated';

  @override
  String get current_donation_streak => 'Current order streak 🔥';

  @override
  String get no_impact_data_found => 'No impact data found';

  @override
  String get error_loading_impact => 'Error loading impact statistics';

  @override
  String get optional => 'Optional';

  @override
  String get specific_donation => 'Specific';

  @override
  String get please_select_template => 'Please select template and sub-order';

  @override
  String get error_applying_gift_card => 'Error applying gift card';

  @override
  String get add_gift_card => 'Add gift card';

  @override
  String get select_card_template => 'Select Card Template';

  @override
  String get select_sub_order => 'Select Sub-Order';

  @override
  String get sender_name_title => 'Sender';

  @override
  String get enter_sender_name => 'Enter sender name';

  @override
  String get receiver_name_title => 'Receiver';

  @override
  String get enter_receiver_name => 'Enter recipient name';

  @override
  String get receiver_whatsapp => 'Recipient\'s WhatsApp Number';

  @override
  String get phone_number_required => 'Phone number is required';

  @override
  String get invalid_phone_number => 'Invalid phone number';

  @override
  String get phone_number_hint => 'Phone Number';

  @override
  String get no_templates_available => 'No templates available';

  @override
  String get save_gift_card_info => 'Save Gift Card Info';

  @override
  String get enter_valid_number_gc => 'Please enter a valid number';

  @override
  String get invalid_phone_format => 'Invalid phone number format';

  @override
  String get field_is_required => 'This field is required';

  @override
  String get total_orders => 'Total Orders';

  @override
  String get amount_paid => 'Amount Paid';

  @override
  String get sar_currency => '⃁';

  @override
  String get people_helped => 'People Helped';

  @override
  String get water_cartons => 'Water Cartons';

  @override
  String get chillers => 'Chillers';

  @override
  String selected_items_count(int count) {
    return 'Selected: $count items';
  }

  @override
  String get customer_reviews => 'Customer Reviews';

  @override
  String get track_order => 'Track Order';

  @override
  String get view_receipt => 'View Receipt';

  @override
  String get one_time_donation => 'One-time Order';

  @override
  String get error_occurred_try_again => 'Error occurred. Try again';

  @override
  String get items => 'items';

  @override
  String get unit => 'unit';

  @override
  String get units => 'units';

  @override
  String get user => 'User';

  @override
  String get no_reviews_found => 'No reviews found';

  @override
  String get deliveries => 'Deliveries';

  @override
  String get no_deliveries_found => 'No deliveries found';

  @override
  String get purchased_date => 'Purchased';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get created => 'Created';

  @override
  String get meal => 'Meal';

  @override
  String get meals => 'Meals';

  @override
  String get umbrella => 'Umbrella';

  @override
  String get umbrellas => 'Umbrellas';

  @override
  String get bottle => 'Bottle';

  @override
  String get bottles => 'Bottles';

  @override
  String get note_prefix => 'Note -';

  @override
  String get incl_sar => '* Incl. ⃁';

  @override
  String get delivery_suffix => 'delivery';

  @override
  String get inclusive_of_sar => 'Inclusive of ⃁';

  @override
  String get delivery_charge => 'delivery charge';

  @override
  String get product_details => 'Product Details';

  @override
  String get location_details => 'Location Details';

  @override
  String get financial_details => 'Financial Details';

  @override
  String get amount_value => 'Amount';

  @override
  String get please_select_bank_account => 'Please select a bank account';

  @override
  String get please_select_designated_bank_account =>
      'Please select your designated bank account for the transfer.';

  @override
  String get order_received_iban_message =>
      'Your order is received and will be confirmed after payment verification.';

  @override
  String get products_selected => 'Products Selected';

  @override
  String get available_balance_colon => 'Available balance: ';

  @override
  String get gift_card_fees => 'Gift card fees';

  @override
  String get gift_card_added => 'Gift card added';

  @override
  String get show_gift_cards => 'Show gift cards';

  @override
  String get added_gift_cards => 'Added gift cards';

  @override
  String get view_and_delete_gift_cards => 'View and delete gift cards';

  @override
  String get error_removing_gift_card =>
      'An error occurred while removing the gift card';

  @override
  String get delete_all_cards => 'Delete all cards';

  @override
  String get choose_water_package_desc =>
      'Choose the water package that suits you';

  @override
  String get sar_per_unit => '⃁ / unit';

  @override
  String get my_chillers => 'My Chillers';

  @override
  String get my_chillers_subtitle => 'View the status of donated chillers';

  @override
  String get rate_order => 'Rate Order';

  @override
  String get submit_review => 'Submit Review';

  @override
  String get write_review => 'Write your review...';

  @override
  String get review_submitted => 'Review submitted successfully';

  @override
  String get rate_order_title => 'Rate your order';

  @override
  String get how_was_your_experience => 'How was your experience?';

  @override
  String get track_donation => 'Track Order';

  @override
  String get since => 'Since ';

  @override
  String get everyday => 'Everyday';

  @override
  String get once_a_week => 'Once a week';

  @override
  String get once_a_month => 'Once a month';

  @override
  String get tap_to_view => 'Tap item to view media';

  @override
  String get twice_a_week => 'Twice a week';

  @override
  String get account => 'Account';

  @override
  String get status_active => 'Active';

  @override
  String get mosques => 'mosques';

  @override
  String get reorder => 'Reorder';

  @override
  String get status_cancelled => 'Cancelled';

  @override
  String get status_expired => 'Expired';

  @override
  String get status_pending => 'Pending';

  @override
  String get status_completed => 'Completed';

  @override
  String get choose_quantity => 'Choose Quantity';

  @override
  String get view_invoice => 'View Invoice';

  @override
  String get could_not_open_invoice => 'Could not open invoice';

  @override
  String get error_loading_order_details => 'Failed to load order details';

  @override
  String get error_occurred_loading_order =>
      'An error occurred while loading order details.';

  @override
  String get error_title => 'Error';

  @override
  String get order_placed => 'Order Placed';

  @override
  String get current_status => 'Current Status';

  @override
  String get delivering_to => 'Delivering to';

  @override
  String get delivery_progress => 'Delivery Progress';

  @override
  String get delivery_completed => 'Delivery completed';

  @override
  String get proof_of_delivery => 'Proof of Delivery';

  @override
  String get mosque_front => 'Mosque Front';

  @override
  String get mosque_inside => 'Mosque Inside';

  @override
  String get packages => 'Packages';

  @override
  String get delivery_video => 'Delivery Video';

  @override
  String get mark_all_read => 'Mark all as read';

  @override
  String get clear_notifications => 'Clear notifications';

  @override
  String get no_deliveries_found_for_this_order =>
      'No deliveries found for this order.';

  @override
  String get no_details_found => 'No details found.';

  @override
  String get no_orders_found => 'No orders found';

  @override
  String get failed_to_mark_all_as_read => 'Failed to mark all as read';

  @override
  String get failed_to_clear_notifications => 'Failed to clear notifications';

  @override
  String get failed_to_retrieve_google_id_token =>
      'Failed to retrieve Google ID token';

  @override
  String get failed_to_retrieve_apple_identity_token =>
      'Failed to retrieve Apple Identity token';

  @override
  String get failed_to_submit_review => 'Failed to submit review';

  @override
  String get failed_to_load_orders_page => 'Failed to load orders page';

  @override
  String get no_chillers_found => 'No chillers found';

  @override
  String get location => 'Location';

  @override
  String get address => 'Address';

  @override
  String get gift_card => 'Gift Card';

  @override
  String get chiller_info => 'Chiller Info';

  @override
  String get chiller_available => 'Chiller Available';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get delivered_to => 'Delivered To';

  @override
  String get review => 'Review';

  @override
  String get coupon_not_applicable =>
      'Coupon codes cannot be applied to this order';

  @override
  String get profile_picture => 'Profile Picture';

  @override
  String get no_delivery_video_available =>
      'No delivery video is available for this order yet.';

  @override
  String get ok => 'OK';

  @override
  String get priceIncludesDistributionDeliveryAndDocumentation =>
      'Price includes distribution, delivery, and documention.';

  @override
  String get deliveredToDifferentLocation =>
      'Delivered to a different location';

  @override
  String get reasonForDifferentLocation => 'Reason';

  @override
  String minimum_quantity_for_location_is(String min) {
    return 'minimum quantity for one location is $min';
  }

  @override
  String get internet_error =>
      'Internet error. Please check your internet connection';

  @override
  String distanceAway(String distance) {
    return '$distance km away from you';
  }

  @override
  String get product => 'Product';
}
