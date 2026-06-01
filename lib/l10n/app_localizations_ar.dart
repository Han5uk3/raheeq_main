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
  String get guest_user_email => 'guest_user@suqyarahiq.com';

  @override
  String get guest_user => 'مستخدم زائر';

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
  String get track_mosque_donations => 'تتبع تبرعاتك للمساجد';

  @override
  String get ongoing_charity_rewards => 'أجور صدقتك الجارية';

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
}
