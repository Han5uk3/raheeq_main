// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'رحيق';

  @override
  String get welcomeMessage => 'مرحبًا بك في رحيق!';

  @override
  String get available_colon => 'متاح :';

  @override
  String get welcome => 'مرحباً';

  @override
  String get onboard1_title => 'تبرع بهدف';

  @override
  String get onboard1_subtitle =>
      'اصنع فرقًا حقيقيًا من خلال توفير المياه لمن هم في أمسّ الحاجة إليها.';

  @override
  String get onboard2_title => 'بسيط. شفاف. موثوق.';

  @override
  String get onboard2_subtitle =>
      'اختر الجهة التي ترغب بالتبرع لها، وسنتولى الباقي.';

  @override
  String get onboard3_title => 'ابدأ رحلتك في العطاء';

  @override
  String get onboard3_subtitle =>
      'يمكن لعملك البسيط أن يخدم المئات ويحقق خيرًا مستمرًا.';

  @override
  String get skip => 'تخطي';

  @override
  String get continue_btn => 'متابعة';

  @override
  String get start_donating => 'ابدأ التبرع';

  @override
  String get new_to_donate => 'جديد في التبرع؟';

  @override
  String get terms_agree_prefix => 'بالمتابعة، فإنك توافق على ';

  @override
  String get terms_conditions => 'الشروط والأحكام';

  @override
  String get and => ' و ';

  @override
  String get privacy_policy => 'سياسة الخصوصية';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get enter_phone => 'أدخل رقم هاتفك المحمول';

  @override
  String get otp_message =>
      'أدخل رقم هاتفك المحمول للمتابعة.\nسنرسل رمز تحقق (OTP) للتأكيد.';

  @override
  String get or => 'أو';

  @override
  String get google_signin => 'تسجيل الدخول باستخدام Google';

  @override
  String get apple_signin => 'تسجيل الدخول باستخدام Apple';

  @override
  String get search => 'بحث';

  @override
  String get home => 'الرئيسية';

  @override
  String get orders => 'الطلبات';

  @override
  String get impact => 'الأثر';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logout_confirmation =>
      'هل أنت متأكد أنك تريد تسجيل الخروج من رحيق؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get no_session => 'لم يتم العثور على جلسة. يرجى تسجيل الدخول.';

  @override
  String get personal_information => 'المعلومات الشخصية';

  @override
  String get saved_mosques => 'المساجد المحفوظة';

  @override
  String get recurring_donations => 'التبرعات المتكررة';

  @override
  String get tax_receipts => 'الإيصالات الضريبية';

  @override
  String get my_wallet => 'محفظتي';

  @override
  String get payment_methods => 'طرق الدفع';

  @override
  String get order_history => 'سجل الطلبات';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get app_settings => 'إعدادات التطبيق';

  @override
  String get help_center => 'مركز المساعدة';

  @override
  String get contact_us => 'اتصل بنا';

  @override
  String get contact_us_desc =>
      'تواصل معنا عبر الدردشة المباشرة للحصول على دعم فوري.';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get first_name => 'الاسم الأول';

  @override
  String get last_name => 'اسم العائلة';

  @override
  String get email_address => 'البريد الإلكتروني';

  @override
  String get phone_number => 'رقم الهاتف';

  @override
  String get profile_updated => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get profile_pic_updated => 'تم تحديث صورة الملف الشخصي بنجاح!';

  @override
  String get orders_live_soon => 'سيتم تفعيل الطلبات قريبًا...';

  @override
  String get impact_page => 'صفحة الأثر';

  @override
  String get no_products_selected => 'لم يتم اختيار أي منتجات';

  @override
  String get order => 'طلب';

  @override
  String get date => 'التاريخ';

  @override
  String get time => 'الوقت';

  @override
  String get guest_user_email => 'guest_user@suqyarahiq.com';

  @override
  String get guest_user => 'مستخدم زائر';

  @override
  String get no_orders_out_for_delivery => 'لا توجد طلبات جاري توصيلها';

  @override
  String get login_successful => 'تم تسجيل الدخول بنجاح';

  @override
  String get enter_valid_otp => 'يرجى إدخال رمز تحقق صالح';

  @override
  String removed_from_saved(String name) {
    return 'تمت إزالة $name من المساجد المحفوظة.';
  }

  @override
  String get failed_to_remove_mosque => 'فشل في إزالة المسجد.';

  @override
  String get failed_to_update_favorite => 'فشل في تحديث المفضلة.';

  @override
  String get failed_to_load_wallet => 'فشل في تحميل بيانات المحفظة.';

  @override
  String minimum_quantity_is(String min) {
    return 'الحد الأدنى للكمية هو $min';
  }

  @override
  String get example_quantity => 'مثال: 50';

  @override
  String error_msg(String error) {
    return 'خطأ: $error';
  }

  @override
  String failed_to_pick_image(String error) {
    return 'فشل في اختيار الصورة: $error';
  }

  @override
  String failed_upload_simulation(String error) {
    return 'فشل في محاكاة رفع الملف: $error';
  }

  @override
  String get track_your_donations => 'تتبع تبرعاتك';

  @override
  String get manage_account_settings => 'إدارة إعدادات حسابك';

  @override
  String get raheeq => 'رحيق';

  @override
  String get my_orders => 'طلباتي';

  @override
  String get new_orders => 'طلبات جديدة';

  @override
  String get out_for_delivery => 'قيد التوصيل';

  @override
  String get delivered => 'تم التسليم';

  @override
  String get transaction_history => 'سجل المعاملات';

  @override
  String get no_transactions_found => 'لم يتم العثور على معاملات.';

  @override
  String get current_balance => 'الرصيد الحالي';

  @override
  String get account_section => 'الحساب';

  @override
  String get payment_orders_section => 'المدفوعات والطلبات';

  @override
  String get settings_section => 'الإعدادات';

  @override
  String get support_section => 'الدعم';

  @override
  String get feature_coming_soon => 'هذه الميزة ستتوفر قريبًا';

  @override
  String get redirecting_payment_methods =>
      'جارٍ التحويل إلى طرق الدفع الخاصة بي...';

  @override
  String get redirecting_terms => 'جارٍ التحويل إلى الشروط والأحكام...';

  @override
  String get donations_label => 'التبرعات';

  @override
  String get mosques_label => 'المساجد';

  @override
  String get people_label => 'الأشخاص';

  @override
  String get serveTheGuestOfAllah => 'خدمة ضيوف الرحمن';

  @override
  String get build_number => 'رقم البناء';

  @override
  String get version => 'الإصدار';

  @override
  String get app_information => 'معلومات التطبيق';

  @override
  String get theme_switching_coming_soon => 'تبديل السمة قريباً';

  @override
  String get dark_mode => 'الوضع الداكن';

  @override
  String get app_language => 'لغة التطبيق';

  @override
  String get manage_preferences_and_app_info =>
      'إدارة التفضيلات ومعلومات التطبيق';

  @override
  String get recurring_impact => 'أثر مستدام';

  @override
  String get monthly => 'شهري';

  @override
  String get single_donation => 'تبرع لمرة واحدة';

  @override
  String get one_time => 'مرة واحدة';

  @override
  String get support_once_or_make_a_lasting_impact =>
      'ادعم مرة واحدة أو اصنع أثراً مستداماً';

  @override
  String get choose_donation_type => 'اختر نوع التبرع';

  @override
  String get payable_amount => 'المبلغ المستحق';

  @override
  String get add_note => 'إضافة ملاحظة';

  @override
  String get enter_quantity => 'أدخل الكمية';

  @override
  String get or_enter_custom_quantity_min_min =>
      'أو أدخل كمية مخصصة (الأدنى. \$min)';

  @override
  String get select_your_impact => 'اختر تأثيرك';

  @override
  String get select_a_product_to_continue => 'اختر منتجاً للمتابعة';

  @override
  String get no_cities_found => 'لا توجد مدن';

  @override
  String get search_for_a_city => 'ابحث عن مدينة...';

  @override
  String get select_the_most_needy_cities => 'اختر المدن الأكثر احتياجاً';

  @override
  String get choose_cities => 'اختر مدناً';

  @override
  String get confirm_selection => 'تأكيد الاختيار';

  @override
  String get clear_all => 'مسح الكل';

  @override
  String get deliver_blessings => 'يُسلِّم البركات.';

  @override
  String get give_water => 'أعطِ الماء.';

  @override
  String get we => 'نعمل على تجهيز إحصائيات تأثيرك.';

  @override
  String get coming_soon => 'قريباً...';

  @override
  String get your_impact => 'تأثيرك';

  @override
  String get view_status_and_delivery_details => 'عرض الحالة وتفاصيل التسليم.';

  @override
  String get recent_donations => 'التبرعات الأخيرة';

  @override
  String get sar => '⃁';

  @override
  String get starting_from => 'السعر';

  @override
  String get high_need => 'الأكثر احتياجاً';

  @override
  String get essential_mosque_supplies => 'مستلزمات المساجد الأساسية';

  @override
  String get choose_your_cause_and_make_an_impact => 'اختر قضيتك واصنع فرقاً';

  @override
  String get quick_actions => 'أعمال سريعة';

  @override
  String get donate_now => 'تبرع الآن   ';

  @override
  String get subscribe => 'اشتراك متاح';

  @override
  String get i_understand => 'مفهوم';

  @override
  String
  get your_current_basket_will_be_cleared_and_you_will_be_moved_to_targetname =>
      'سيتم مسح السلة الحالية والانتقال إلى \$targetName.';

  @override
  String get warning => 'تحذير';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get failed_to_load_home_page => 'حدث خطأ أثناء تحميل البيانات';

  @override
  String get choose_mosques => 'اختر المساجد';

  @override
  String get order_now => 'اطلب الآن';

  @override
  String get assalamu_alaikum => 'السلام عليكم';

  @override
  String get latest_updates_and_alerts => 'آخر التحديثات والتنبيهات';

  @override
  String get no_delivered_orders => 'لا توجد طلبات تم توصيلها';

  @override
  String get no_new_orders => 'لا توجد طلبات جديدة';

  @override
  String get total_amount => 'إجمالي المبلغ';

  @override
  String get minimum_order_min_units => 'الحد الأدنى للطلب: \$min وحدة';

  @override
  String get enter_quantity_min_min => 'أدخل الكمية (الحد الأدنى: \$min)';

  @override
  String get custom => 'كمية مخصصة';

  @override
  String get for_name => 'لـ: \$name';

  @override
  String get select_quantity => 'اختر الكمية';

  @override
  String get quick_services => 'خدمات سريعة';

  @override
  String get no_products_available => 'لا توجد منتجات متاحة';

  @override
  String get select_a_product => 'اختر منتجاً';

  @override
  String get no_active_subscriptions => 'لا توجد اشتراكات نشطة';

  @override
  String get manage_your_subscriptions => 'إدارة اشتراكاتك';

  @override
  String get no_saved_mosques_found => 'لا توجد مساجد محفوظة.';

  @override
  String get your_favorite_mosques => 'المساجد المفضلة لديك';

  @override
  String get no_mosques_found => 'لا توجد مساجد';

  @override
  String get no_meqat_mosques_found => 'لا توجد مواقيت';

  @override
  String get no_orphanages_found => 'لا توجد دور أيتام';

  @override
  String get select_city => 'اختر المدينة';

  @override
  String get search_mosques => 'بحث في المساجد...';

  @override
  String get search_meqat_mosques => 'بحث في المواقيت...';

  @override
  String get search_orphanages => 'بحث في دور الأيتام...';

  @override
  String get choose_from_map => 'الاختيار من الخريطة';

  @override
  String get list_of_mosques => 'قائمة المساجد';

  @override
  String get select_a_mosque_to_deliver_water_to =>
      'اختر مسجداً لإيصال المياه إليه';

  @override
  String get choose_specific_mosque => 'اختر مسجداً محدداً';

  @override
  String get list_of_meqat_mosques => 'قائمة المواقيت';

  @override
  String get choose_specific_meqat_mosque => 'اختر ميقات محدد';

  @override
  String get list_of_orphanages => 'قائمة دور الأيتام';

  @override
  String get select_an_orphanage_to_deliver_water_to =>
      'اختر داراً لإيصال المياه إليها';

  @override
  String get choose_specific_orphanage => 'اختر دار أيتام محددة';

  @override
  String get clear_selection => 'إزالة التحديد';

  @override
  String get choose_donation_type_108 => 'اختر نوع التبرع';

  @override
  String get specific => 'تحديد';

  @override
  String get most_needy => 'الأكثر احتياجاً';

  @override
  String get two_year_guarantee => '2 سنة ضمان';

  @override
  String get select_the_water_package_that_suits_you =>
      'اختر باقة المياه التي تناسبك';

  @override
  String get choose_water_package => 'اختر باقة المياه';

  @override
  String get free => 'مجانًا';

  @override
  String get confirm_pay => 'تأكيد ودفع';

  @override
  String get wallet_applied => 'رصيد المحفظة المستخدم';

  @override
  String get discount => 'الخصم';

  @override
  String get vat => 'ضريبة القيمة المضافة';

  @override
  String get delivery_fee => 'رسوم التوصيل';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get contribution_details => 'تفاصيل المساهمة';

  @override
  String get apply => 'تطبيق';

  @override
  String get remove => 'إزالة';

  @override
  String get use_wallet_balance => 'استخدام المحفظة';

  @override
  String get enter_coupon_code => 'أدخل كود الخصم';

  @override
  String get coupon_code => 'كود الخصم';

  @override
  String get do_you_want_to_give_a_gift_to_someone_close_to_you =>
      'هل ترغب في إهداء شخص قريب منك؟';

  @override
  String get donation_type => 'نوع التبرع';

  @override
  String get final_review_and_payment => 'مراجعة نهائية ودفع';

  @override
  String get payment => 'الدفع';

  @override
  String get subscription_details => 'تفاصيل الاشتراك';

  @override
  String get delivery_days => 'أيام التوصيل';

  @override
  String get months => 'عدد الأشهر';

  @override
  String get start_date => 'تاريخ البدء';

  @override
  String get end_date => 'تاريخ الانتهاء';

  @override
  String get total_days => 'عدد الأيام';

  @override
  String get payment_was_cancelled => 'تم إلغاء عملية الدفع';

  @override
  String get error_verifying_payment => 'حدث خطأ أثناء التحقق من الدفع';

  @override
  String get pay_with_card => 'الدفع';

  @override
  String get payment_method => 'طريقة الدفع';

  @override
  String get stc_pay => 'STC Pay';

  @override
  String get apple_pay => 'أبل باي';

  @override
  String get credit_card_mada => 'بطاقة الائتمان / مدى';

  @override
  String get failed_to_apply_wallet => 'حدث خطأ أثناء تطبيق المحفظة';

  @override
  String get insufficient_balance_to_apply_wallet =>
      'رصيد غير كافٍ لتطبيق المحفظة';

  @override
  String get failed_to_remove_coupon => 'حدث خطأ أثناء إزالة الكوبون';

  @override
  String get coupon_removed_successfully => 'تم إزالة الكوبون بنجاح';

  @override
  String get invalid_coupon_code => 'كوبون غير صالح';

  @override
  String get coupon_applied_successfully => 'تم تطبيق الكوبون بنجاح';

  @override
  String get confirm_submit => 'تأكيد وإرسال';

  @override
  String get tap_to_select_image => 'اضغط لاختيار صورة';

  @override
  String get two_attach_transfer_receipt => 'أرفق إيصال التحويل';

  @override
  String get enter_transaction_number => 'أدخل رقم العملية';

  @override
  String get enter_verification_code => 'أدخل رمز التحقق';

  @override
  String get otp_sent_message => 'لقد أرسلنا رمز التحقق إلى رقم هاتفك المحمول';

  @override
  String get your_verification_code => 'رمز التحقق الخاص بك';

  @override
  String get did_not_receive_code => 'لم تستلم الرمز؟ ';

  @override
  String get resend_code_in => 'إعادة إرسال الرمز خلال ';

  @override
  String get resend => 'إعادة إرسال';

  @override
  String get one_transaction_number => 'رقم العملية';

  @override
  String get account_number => 'رقم الحساب:';

  @override
  String get no_bank_accounts_available => 'لا توجد حسابات بنكية متاحة';

  @override
  String get our_bank_accounts => 'حساباتنا المصرفية';

  @override
  String get iban_bank_transfer => 'تحويل بنكي (IBAN)';

  @override
  String get please_enter_transaction_number => 'الرجاء إدخال رقم العملية';

  @override
  String get please_attach_the_transfer_receipt => 'الرجاء إرفاق إيصال التحويل';

  @override
  String
  get please_attach_the_transfer_receipt_and_enter_the_transaction_number =>
      'الرجاء إرفاق إيصال التحويل وإدخال رقم العملية';

  @override
  String get failed_to_load_bank_accounts => 'فشل تحميل الحسابات البنكية';

  @override
  String get total_price => 'الإجمالي';

  @override
  String get verify_your_order_details => 'تحقق من تفاصيل طلبك';

  @override
  String get order_details => 'تفاصيل الطلب';

  @override
  String get would_you_like_to_add_a_note_to_the_delivery_agent =>
      'هل تود إضافة ملاحظة لمندوب التوصيل؟';

  @override
  String get general => 'غير محدد';

  @override
  String get most_in_need => 'الأشد حاجة';

  @override
  String get most_needy_meqat_mosque => 'مسجد ميقات الأشد حاجة';

  @override
  String get most_needy_orphanage => 'دار أيتام الأشد حاجة';

  @override
  String get subscription => 'شهري';

  @override
  String get back_to_home => 'العودة للرئيسية';

  @override
  String get retry_payment => 'إعادة المحاولة';

  @override
  String get bank_transfer_receipt_received_awaiting_admin_approval =>
      'تم استلام طلب التحويل البنكي وهو قيد المراجعة.';

  @override
  String get pending_approval => 'قيد المراجعة';

  @override
  String get an_error_occurred_while_processing_the_payment =>
      'حدث خطأ أثناء معالجة الدفع.';

  @override
  String get payment_failed => 'فشلت عملية الدفع';

  @override
  String get thank_you_for_your_donation =>
      'شكراً لتبرعك. جعله الله في ميزان حسناتك.';

  @override
  String get payment_successful => 'تم الدفع بنجاح!';

  @override
  String get confirm => 'تأكيد';

  @override
  String get enter_quantity_204 => 'أدخل الكمية';

  @override
  String get notes_optional => 'ملاحظات (اختياري)';

  @override
  String get quantity => 'الكمية';

  @override
  String get save_return => 'حفظ والعودة';

  @override
  String get select_quantities_and_notes => 'تحديد الكميات والملاحظات';

  @override
  String get most_in_need_in => 'الأشد حاجة في ';

  @override
  String get choose_products_for_each_category => 'اختر المنتجات لكل فئة';

  @override
  String get select_products => 'تحديد المنتجات';

  @override
  String get no_plans_available_at_the_moment => 'لا توجد خطط متاحة حالياً';

  @override
  String get choose_a_subscription_plan => 'اختر خطة الاشتراك المناسبة لك';

  @override
  String get subscription_plans => 'خطط الاشتراك';

  @override
  String get customize_plan => 'تخصيص الخطة';

  @override
  String get delivery_days_select_maxallowed =>
      'أيام التوصيل (اختر \$maxAllowed)';

  @override
  String get sun => 'الأحد';

  @override
  String get sat => 'السبت';

  @override
  String get fri => 'الجمعة';

  @override
  String get thu => 'الخميس';

  @override
  String get wed => 'الأربعاء';

  @override
  String get tue => 'الثلاثاء';

  @override
  String get mon => 'الاثنين';

  @override
  String get subscription_duration_months => 'مدة الاشتراك (بالأشهر)';

  @override
  String get select_date => 'اختر التاريخ';

  @override
  String get recurring_donation => 'تبرع شهري متكرر';

  @override
  String get too_many_attempts =>
      'محاولات كثيرة جدًا. يرجى المحاولة مرة أخرى لاحقًا.';

  @override
  String get suggestions => 'الاقتراحات';

  @override
  String get complaints => 'الشكاوى';

  @override
  String get complaints_desc => 'أبلغ عن أي مشاكل واجهتها في طلباتك.';

  @override
  String get your_suggestions_hint => 'اقتراحاتكم تهمنا، نسعد باستقبالها.';

  @override
  String get send => 'إرسال';

  @override
  String get select_complaint => 'اختر الشكوى';

  @override
  String get complaint_option_1 => 'تم الدفع ولم يتم إنشاء طلب.';

  @override
  String get complaint_option_2 => 'لم يتم توصيل الطلب في الوقت المحدد.';

  @override
  String get complaint_option_3 => 'تم توصيل الطلب لمسجد مختلف عن المحدد.';

  @override
  String get complaint_option_4 => 'أخرى';

  @override
  String get enter_complaint_hint => 'أدخل شكواك هنا.';

  @override
  String get select_order => 'اختر الطلب';

  @override
  String sign_in_with_provider(String provider) {
    return 'تسجيل الدخول باستخدام $provider';
  }

  @override
  String get choose_account_to_continue => 'اختر حسابًا للمتابعة مع رحيق:';

  @override
  String get authentication_failed => 'فشلت المصادقة';

  @override
  String get failed_to_send_otp => 'فشل في إرسال رمز التحقق';

  @override
  String get otp_sent_successfully => 'تم إرسال رمز التحقق بنجاح!';

  @override
  String get failed_to_resend_otp => 'فشل في إعادة إرسال رمز التحقق';

  @override
  String get verification_failed => 'فشل التحقق';

  @override
  String get invalid_otp => 'رمز التحقق غير صالح';

  @override
  String get complete_profile => 'إكمال الملف الشخصي';

  @override
  String get enter_first_name => 'أدخل الاسم الأول';

  @override
  String get enter_last_name => 'أدخل اسم العائلة';

  @override
  String get enter_email_optional_hint => 'أدخل البريد الإلكتروني (اختياري)';

  @override
  String get enter_phone_number_hint => 'أدخل رقم الهاتف';

  @override
  String get registration_failed => 'فشل التسجيل';

  @override
  String get validation_error => 'خطأ في التحقق';

  @override
  String get validation_error_check_inputs =>
      'خطأ في التحقق. يرجى مراجعة مدخلاتك.';

  @override
  String get register => 'تسجيل';

  @override
  String get field_required => 'هذا الحقل مطلوب';

  @override
  String get enter_valid_email => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get gender => 'الجنس';

  @override
  String get select_gender => 'اختر الجنس';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get other_gender => 'آخر';

  @override
  String get please_select_gender => 'يرجى اختيار الجنس';

  @override
  String get show_more => 'عرض المزيد';

  @override
  String get all_transactions => 'جميع المعاملات';

  @override
  String get filter_by => 'تصفية حسب';

  @override
  String get day => 'يوم';

  @override
  String get month => 'شهر';

  @override
  String get year => 'سنة';

  @override
  String get all => 'الكل';

  @override
  String get see_the_difference => 'شاهد الفرق الذي صنعته';

  @override
  String get total_donations => 'إجمالي التبرعات';

  @override
  String get products_donated => 'المنتجات المتبرع بها';

  @override
  String get total_given => 'إجمالي المبالغ';

  @override
  String get mosques_helped => 'المساجد المدعومة';

  @override
  String get view_all => 'عرض الكل';

  @override
  String get items_donated => 'منتج تم التبرع به';

  @override
  String get current_donation_streak => 'سلسلة التبرعات الحالية 🔥';

  @override
  String get no_impact_data_found => 'لا توجد بيانات للأثر';

  @override
  String get error_loading_impact => 'خطأ في تحميل إحصائيات الأثر';

  @override
  String get optional => 'اختياري';

  @override
  String get specific_donation => 'تحديد';

  @override
  String get please_select_template => 'يرجى اختيار القالب والعنصر';

  @override
  String get error_applying_gift_card => 'حدث خطأ أثناء التطبيق';

  @override
  String get add_gift_card => 'إضافة بطاقة';

  @override
  String get select_card_template => 'اختر قالب البطاقة';

  @override
  String get select_sub_order => 'اختر العنصر';

  @override
  String get sender_name_title => 'اسم المرسل';

  @override
  String get enter_sender_name => 'ادخل اسم المرسل';

  @override
  String get receiver_name_title => 'اسم المستلم';

  @override
  String get enter_receiver_name => 'ادخل اسم المستلم';

  @override
  String get receiver_whatsapp => 'رقم الواتساب للمستلم';

  @override
  String get phone_number_required => 'رقم الهاتف مطلوب';

  @override
  String get invalid_phone_number => 'رقم هاتف غير صالح';

  @override
  String get phone_number_hint => 'رقم الهاتف';

  @override
  String get no_templates_available => 'لا توجد قوالب متاحة';

  @override
  String get save_gift_card_info => 'حفظ بيانات الإهداء';

  @override
  String get enter_valid_number_gc => 'يرجى إدخال رقم صحيح';

  @override
  String get invalid_phone_format => 'رقم هاتف غير صالح';

  @override
  String get field_is_required => 'هذا الحقل مطلوب';

  @override
  String get total_orders => 'إجمالي الطلبات';

  @override
  String get amount_paid => 'إجمالي المدفوعات';

  @override
  String get sar_currency => '⃁';

  @override
  String get people_helped => 'الأشخاص المستفيدين';

  @override
  String get water_cartons => 'كراتين المياه';

  @override
  String get chillers => 'البرادات';

  @override
  String selected_items_count(int count) {
    return 'محدد: $count عناصر';
  }

  @override
  String get customer_reviews => 'تقييمات العملاء';

  @override
  String get track_order => 'تتبع الطلب';

  @override
  String get view_receipt => 'عرض الإيصال';

  @override
  String get one_time_donation => 'تبرع لمرة واحدة';

  @override
  String get error_occurred_try_again => 'حدث خطأ. حاول مرة أخرى';

  @override
  String get items => 'عنصر';

  @override
  String get unit => 'وحدة';

  @override
  String get units => 'وحدة';

  @override
  String get user => 'مستخدم';

  @override
  String get no_reviews_found => 'لا توجد تقييمات';

  @override
  String get deliveries => 'الطلبات';

  @override
  String get no_deliveries_found => 'لا توجد طلبات';

  @override
  String get purchased_date => 'تاريخ الشراء';

  @override
  String get scheduled => 'مجدول';

  @override
  String get created => 'تاريخ الإنشاء';

  @override
  String get meal => 'وجبة';

  @override
  String get meals => 'وجبات';

  @override
  String get umbrella => 'مظلة';

  @override
  String get umbrellas => 'مظلات';

  @override
  String get bottle => 'زجاجة';

  @override
  String get bottles => 'زجاجات';

  @override
  String get note_prefix => 'ملاحظة -';

  @override
  String get incl_sar => '* شامل ⃁';

  @override
  String get delivery_suffix => 'توصيل';

  @override
  String get inclusive_of_sar => 'شامل ⃁';

  @override
  String get delivery_charge => 'رسوم التوصيل';

  @override
  String get product_details => 'تفاصيل المنتج';

  @override
  String get location_details => 'تفاصيل الموقع';

  @override
  String get financial_details => 'التفاصيل المالية';

  @override
  String get amount_value => 'قيمة المنتجات';

  @override
  String get please_select_bank_account => 'الرجاء اختيار حساب بنكي';

  @override
  String get please_select_designated_bank_account =>
      'يرجى تحديد الحساب البنكي المخصص للتحويل الخاص بك.';

  @override
  String get order_received_iban_message =>
      'تم استلام طلبك، وسيتم التأكيد بعد التحقق من الدفع.';

  @override
  String get products_selected => 'منتجات تم اختيارها';

  @override
  String get available_balance_colon => 'الرصيد المتاح: ';

  @override
  String get gift_card_fees => 'رسوم بطاقة الإهداء';

  @override
  String get gift_card_added => 'تمت إضافة بطاقة إهداء';

  @override
  String get show_gift_cards => 'عرض البطاقات';

  @override
  String get added_gift_cards => 'البطاقات المضافة';

  @override
  String get view_and_delete_gift_cards => 'عرض وحذف بطاقات الإهداء';

  @override
  String get error_removing_gift_card => 'حدث خطأ أثناء إزالة بطاقة الإهداء';

  @override
  String get delete_all_cards => 'حذف كل البطاقات';

  @override
  String get choose_water_package_desc => 'اختر باقة المياه التي تناسبك';

  @override
  String get sar_per_unit => '⃁ / وحدة';

  @override
  String get my_chillers => 'ثلاجاتي';

  @override
  String get my_chillers_subtitle => 'عرض حالة الثلاجات المتبرع بها';
}
