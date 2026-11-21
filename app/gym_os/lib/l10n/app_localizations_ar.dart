// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Gymmy';

  @override
  String get currency => 'ج.م';

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get refresh => 'تحديث';

  @override
  String get error => 'حدث خطأ';

  @override
  String errorWithMessage(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get navDashboard => 'الرئيسية';

  @override
  String get navMembers => 'المشتركين';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get loginTitle => 'Gymmy';

  @override
  String get loginSubtitle => 'سجل دخول لإدارة صالتك الرياضية';

  @override
  String get phoneNumber => 'رقم الموبايل';

  @override
  String get phoneHint => 'أدخل رقم الموبايل المسجل';

  @override
  String get phoneRequired => 'مطلوب إدخال رقم الموبايل';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'مطلوب إدخال كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get invalidPhoneOrPassword => 'رقم الهاتف أو كلمة المرور غير صحيحة';

  @override
  String get welcomeToGymOS => 'أهلاً بك في Gymmy';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح';

  @override
  String get goodMorningCaptain => 'صباح الخير، يا كابتن 👋';

  @override
  String get gymOverview => 'نظرة عامة على الجيم';

  @override
  String get currentlyInGym => 'متواجد في الجيم الآن';

  @override
  String get tapToViewAndCheckout => 'اضغط لعرض القائمة وتسجيل الخروج';

  @override
  String get activeMembers => 'اشتراكات سارية';

  @override
  String get todayCheckIns => 'حضور اليوم';

  @override
  String get expiredSubscriptions => 'اشتراكات منتهية';

  @override
  String get monthlyRevenue => 'إيرادات الشهر';

  @override
  String errorLoadingStats(String error) {
    return 'خطأ في تحميل الإحصائيات: $error';
  }

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get newMember => 'عضو جديد';

  @override
  String get renewPlan => 'تجديد باقة';

  @override
  String get checkIn => 'تسجيل حضور';

  @override
  String get quickCheckIn => 'تسجيل حضور سريع';

  @override
  String get checkingIn => 'جاري تسجيل الحضور...';

  @override
  String get checkInSuccess => 'تم تسجيل الحضور بنجاح';

  @override
  String get recentMembers => 'أحدث المشتركين';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get noMembersYet => 'لا يوجد مشتركين بعد';

  @override
  String get memberUnit => 'عضو';

  @override
  String get heroBadge => 'بطل';

  @override
  String get currentInsideTitle => 'المتواجدون في الجيم الآن';

  @override
  String get noMembersInside => 'لا يوجد أعضاء متواجدون حالياً';

  @override
  String get realtimeGateUpdate =>
      'يتم التحديث لحظياً عند تسجيل الدخول من البوابة';

  @override
  String get checkOut => 'تسجيل خروج';

  @override
  String get checkOutSuccess => 'تم تسجيل الخروج بنجاح';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int minutes) {
    return 'منذ $minutes دقيقة';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'منذ $hours ساعة';
  }

  @override
  String timeHoursAndMinutesAgo(int hours, int minutes) {
    return 'منذ $hours ساعة و $minutes د';
  }

  @override
  String memberCountBadge(int count) {
    return '$count عضو';
  }

  @override
  String get membersTitle => 'المشتركين';

  @override
  String get newMemberButton => 'مشترك جديد';

  @override
  String get search => 'بحث';

  @override
  String get searchMemberHint => 'ابحث بالاسم أو رقم الموبايل...';

  @override
  String get noMembersFound => 'لم يتم العثور على نتائج';

  @override
  String get noMembersYetList => 'لا يوجد مشتركين حتى الآن';

  @override
  String get activeStatus => 'نشط';

  @override
  String get expiredStatus => 'منتهي';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterActive => 'سارية';

  @override
  String get filterExpired => 'منتهية';

  @override
  String get filterTodayAttendance => 'حضور اليوم';

  @override
  String expiresOn(String date) {
    return 'ينتهي $date';
  }

  @override
  String get memberProfileTitle => 'ملف المشترك';

  @override
  String get activeSubscription => 'اشتراك نشط';

  @override
  String get expiredSubscription => 'اشتراك منتهي';

  @override
  String get subscriptionDetails => 'تفاصيل الاشتراك';

  @override
  String get plan => 'الباقة';

  @override
  String get noPlan => 'بدون باقة';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get recordAttendance => 'تسجيل الحضور';

  @override
  String get renewSubscription => 'تجديد الاشتراك';

  @override
  String get addNewMemberTitle => 'إضافة مشترك جديد';

  @override
  String get enterMemberDataHint => 'أدخل بيانات المشترك لتفعيل الحساب';

  @override
  String get fullName => 'الاسم بالكامل';

  @override
  String get fullNameHint => 'مثال: محمود سعيد';

  @override
  String get nameRequired => 'مطلوب إدخال الاسم';

  @override
  String get phoneInvalid => 'أدخل رقم صحيح';

  @override
  String get planOptional => 'الباقة (اختياري)';

  @override
  String get chooseImmediatePlan => 'اختر باقة التفعيل الفوري...';

  @override
  String get failedToLoadPlans => 'تعذر تحميل الباقات';

  @override
  String get saveAndActivate => 'حفظ وتفعيل الاشتراك';

  @override
  String get memberAddedSuccess => 'تم إضافة المشترك بنجاح ✅';

  @override
  String renewSubscriptionFor(String memberName) {
    return 'تجديد اشتراك: $memberName';
  }

  @override
  String get selectPlanToRenew => 'اختر الباقة المراد تجديدها...';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String amountPaid(String currency) {
    return 'المبلغ المدفوع ($currency)';
  }

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get notesHint => 'مثال: محول على إنستاباي رقم كذا';

  @override
  String get confirmPaymentAndRenew => 'تأكيد الدفع والتجديد';

  @override
  String get pleaseSelectPlan => 'برجاء اختيار الباقة';

  @override
  String get pleaseEnterValidAmount => 'برجاء إدخال مبلغ صحيح';

  @override
  String get paymentCash => 'كاش';

  @override
  String get paymentVisa => 'فيزا';

  @override
  String get paymentInstaPay => 'إنستاباي';

  @override
  String get paymentVodafoneCash => 'فودافون كاش';

  @override
  String get paymentOther => 'أخرى';

  @override
  String get searchForMember => 'ابحث عن مشترك';

  @override
  String get nameOrPhoneHint => 'الاسم أو رقم الموبايل...';

  @override
  String get noMembersMatched => 'لم يتم العثور على مشتركين';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appCustomization => 'تخصيص التطبيق';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get language => 'اللغة (Language)';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get account => 'الحساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get managePlans => 'إدارة الباقات';

  @override
  String get managePlansAndSubscriptions => 'إدارة الباقات والاشتراكات';

  @override
  String get addPlan => 'إضافة باقة';

  @override
  String get editPlan => 'تعديل الباقة';

  @override
  String get planName => 'اسم الباقة';

  @override
  String get planNameHint => 'مثال: اشتراك شهري، 3 شهور...';

  @override
  String get planNameRequired => 'مطلوب إدخال اسم الباقة';

  @override
  String get planDescriptionOptional => 'الوصف (اختياري)';

  @override
  String get planDescriptionHint => 'تفاصيل إضافية عن الباقة أو المميزات...';

  @override
  String planPrice(String currency) {
    return 'سعر الباقة ($currency)';
  }

  @override
  String get planPriceRequired => 'مطلوب إدخال سعر صحيح';

  @override
  String get durationInDays => 'المدة بالأيام';

  @override
  String get durationRequired => 'مطلوب إدخال عدد الأيام';

  @override
  String get activePlan => 'نشطة';

  @override
  String get inactivePlan => 'غير نشطة';

  @override
  String get noPlansYet => 'لا توجد باقات مضافة بعد';

  @override
  String get savePlan => 'حفظ الباقة';

  @override
  String get planSavedSuccess => 'تم حفظ الباقة بنجاح ✅';

  @override
  String durationDays(int count) {
    return '$count يوم';
  }

  @override
  String get commonDurations => 'المدد الشائعة';

  @override
  String get days30 => '30 يوم (شهر)';

  @override
  String get days90 => '90 يوم (3 شهور)';

  @override
  String get days180 => '180 يوم (6 شهور)';

  @override
  String get days365 => '365 يوم (سنة)';

  @override
  String get planStatusUpdated => 'تم تحديث حالة الباقة بنجاح';

  @override
  String planPriceFormatted(String price, String currency) {
    return '$price $currency';
  }

  @override
  String get paymentsHistory => 'سجل المدفوعات والإيرادات';

  @override
  String get totalCollected => 'إجمالي المحصل';

  @override
  String get periodToday => 'اليوم';

  @override
  String get periodThisMonth => 'هذا الشهر';

  @override
  String get periodAllTime => 'كل الأوقات';

  @override
  String get cashBreakdown => 'كاش';

  @override
  String get instaPayBreakdown => 'إنستاباي';

  @override
  String get vodafoneCashBreakdown => 'فودافون كاش';

  @override
  String get visaBreakdown => 'فيزا';

  @override
  String get noPaymentsFound => 'لا توجد مدفوعات مسجلة';

  @override
  String get registerBreakdown => 'تفاصيل الخزينة';

  @override
  String get sendWhatsappReminder => 'تذكير واتساب';

  @override
  String whatsappRenewalMessage(String memberName) {
    return 'أهلاً كابتن $memberName 💪، بنفكرك إن اشتراكك في الجيم انتهى. مستنيينك تنورنا لتجديد الباقة وتكمل تمرينك!';
  }

  @override
  String get whatsappLaunchError => 'تعذر فتح واتساب على هذا الجهاز';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get sortNewest => 'الأحدث اشتراكاً';

  @override
  String get sortExpiringSoon => 'الأقرب للانتهاء';

  @override
  String get sortEndDateDesc => 'تاريخ الانتهاء (الأبعد)';

  @override
  String get sortNameAsc => 'الاسم (أ - ي)';

  @override
  String get sortByPlan => 'الباقة';

  @override
  String get sortLastCheckIn => 'آخر حضور';

  @override
  String get splashTagline => 'إدارة ذكية للجيم';

  @override
  String get operations => 'العمليات';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get searchByNameOrPhone => 'البحث بالاسم أو الهاتف...';

  @override
  String get latestMembers => 'أحدث المشتركين';

  @override
  String get revenueSummary => 'ملخص الإيرادات';

  @override
  String get checkInMember => 'تسجيل حضور';

  @override
  String get appLogoSemanticLabel => 'شعار جيمي';

  @override
  String get todayRevenue => 'إيراد اليوم';

  @override
  String includesDropIns(String amount) {
    return 'منها حصص مفردة: $amount';
  }

  @override
  String get dropInSession => 'حصة مفردة';

  @override
  String get dropInSessionTitle => 'تسجيل حصة مفردة';

  @override
  String get guestNameOptional => 'اسم الزائر (اختياري)';

  @override
  String get guestPhoneOptional => 'رقم الهاتف (اختياري)';

  @override
  String get recordAndCheckIn => 'تسجيل الحصة والدخول';

  @override
  String get dropInSuccess => 'تم تسجيل الحصة والدخول بنجاح ✅';

  @override
  String get amountRequired => 'يرجى إدخال مبلغ صالح';

  @override
  String get dropInNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get attendance => 'الحضور';

  @override
  String get revenue => 'الإيرادات';

  @override
  String weeklyTotalAttendance(int count) {
    return 'إجمالي: $count حضور';
  }

  @override
  String weeklyTotalRevenue(String amount) {
    return 'إجمالي: $amount';
  }

  @override
  String get noActivityYet => 'لا توجد بيانات بعد';

  @override
  String selectedDaySummary(String date, String value) {
    return '$date: $value';
  }

  @override
  String get syncStatusSynced => 'متزامن';

  @override
  String syncStatusSyncing(int count) {
    return 'جاري المزامنة ($count)';
  }

  @override
  String get syncStatusOffline => 'أوفلاين';

  @override
  String syncStatusOfflineWithQueued(int count) {
    return 'أوفلاين • $count بالانتظار';
  }

  @override
  String get syncStatusChecking => 'جاري التحقق من المزامنة...';

  @override
  String get appFont => 'خط التطبيق';

  @override
  String get fontDefault => 'الافتراضي';

  @override
  String get fontAzer => 'آزر';

  @override
  String get fontAlyamama => 'اليمامة';

  @override
  String get accentColor => 'لون التطبيق';

  @override
  String get colorRoyalBlue => 'أزرق ملكي';

  @override
  String get colorEnergyOrange => 'برتقالي حيوي';

  @override
  String get colorEmerald => 'زمردي';

  @override
  String get colorCrimson => 'قرمزي';

  @override
  String get colorViolet => 'بنفسجي';

  @override
  String get expiringSoonStatus => 'ينتهي قريباً';

  @override
  String get signOutConfirmationTitle => 'تسجيل الخروج';

  @override
  String get signOutConfirmationMessage =>
      'هل أنت متأكد من رغبتك في تسجيل الخروج؟';

  @override
  String signOutUnsyncedWarning(int count) {
    return 'تنبيه: يوجد $count عمليات محلية لم تتم مزامنتها بعد. قد تفقد هذه البيانات في حال تسجيل الخروج الآن.';
  }

  @override
  String get pressBackAgainToExit => 'اضغط مرة أخرى للخروج';

  @override
  String get discardChangesTitle => 'تراجع عن التغييرات';

  @override
  String get discardChangesMessage =>
      'هل تريد تجاهل التغييرات الحالية؟ ستفقد البيانات التي قمت بإدخالها.';

  @override
  String get discard => 'تجاهل';

  @override
  String get keepEditing => 'متابعة التعديل';
}
