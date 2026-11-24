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

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'Gymmy'**
  String get appTitle;

  /// No description provided for @currency.
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get currency;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get error;

  /// No description provided for @errorWithMessage.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @navDashboard.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navDashboard;

  /// No description provided for @navMembers.
  ///
  /// In ar, this message translates to:
  /// **'المشتركين'**
  String get navMembers;

  /// No description provided for @navSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'Gymmy'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخول لإدارة صالتك الرياضية'**
  String get loginSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get phoneNumber;

  /// No description provided for @phoneHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الموبايل المسجل'**
  String get phoneHint;

  /// No description provided for @phoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب إدخال رقم الموبايل'**
  String get phoneRequired;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In ar, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب إدخال كلمة المرور'**
  String get passwordRequired;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginButton;

  /// No description provided for @invalidPhoneOrPassword.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف أو كلمة المرور غير صحيحة'**
  String get invalidPhoneOrPassword;

  /// No description provided for @welcomeToGymOS.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في Gymmy'**
  String get welcomeToGymOS;

  /// No description provided for @loginSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح'**
  String get loginSuccess;

  /// No description provided for @goodMorningCaptain.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير، يا كابتن 👋'**
  String get goodMorningCaptain;

  /// No description provided for @gymOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة على الجيم'**
  String get gymOverview;

  /// No description provided for @currentlyInGym.
  ///
  /// In ar, this message translates to:
  /// **'متواجد في الجيم الآن'**
  String get currentlyInGym;

  /// No description provided for @tapToViewAndCheckout.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لعرض القائمة وتسجيل الخروج'**
  String get tapToViewAndCheckout;

  /// No description provided for @activeMembers.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكات سارية'**
  String get activeMembers;

  /// No description provided for @todayCheckIns.
  ///
  /// In ar, this message translates to:
  /// **'حضور اليوم'**
  String get todayCheckIns;

  /// No description provided for @expiredSubscriptions.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكات منتهية'**
  String get expiredSubscriptions;

  /// No description provided for @monthlyRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إيرادات الشهر'**
  String get monthlyRevenue;

  /// No description provided for @errorLoadingStats.
  ///
  /// In ar, this message translates to:
  /// **'خطأ في تحميل الإحصائيات: {error}'**
  String errorLoadingStats(String error);

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quickActions;

  /// No description provided for @newMember.
  ///
  /// In ar, this message translates to:
  /// **'عضو جديد'**
  String get newMember;

  /// No description provided for @renewPlan.
  ///
  /// In ar, this message translates to:
  /// **'تجديد باقة'**
  String get renewPlan;

  /// No description provided for @checkIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حضور'**
  String get checkIn;

  /// No description provided for @quickCheckIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حضور سريع'**
  String get quickCheckIn;

  /// No description provided for @checkingIn.
  ///
  /// In ar, this message translates to:
  /// **'جاري تسجيل الحضور...'**
  String get checkingIn;

  /// No description provided for @checkInSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الحضور بنجاح'**
  String get checkInSuccess;

  /// No description provided for @recentMembers.
  ///
  /// In ar, this message translates to:
  /// **'أحدث المشتركين'**
  String get recentMembers;

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get viewAll;

  /// No description provided for @noMembersYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مشتركين بعد'**
  String get noMembersYet;

  /// No description provided for @memberUnit.
  ///
  /// In ar, this message translates to:
  /// **'عضو'**
  String get memberUnit;

  /// No description provided for @heroBadge.
  ///
  /// In ar, this message translates to:
  /// **'بطل'**
  String get heroBadge;

  /// No description provided for @currentInsideTitle.
  ///
  /// In ar, this message translates to:
  /// **'المتواجدون في الجيم الآن'**
  String get currentInsideTitle;

  /// No description provided for @noMembersInside.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أعضاء متواجدون حالياً'**
  String get noMembersInside;

  /// No description provided for @realtimeGateUpdate.
  ///
  /// In ar, this message translates to:
  /// **'يتم التحديث لحظياً عند تسجيل الدخول من البوابة'**
  String get realtimeGateUpdate;

  /// No description provided for @checkOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل خروج'**
  String get checkOut;

  /// No description provided for @checkOutSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الخروج بنجاح'**
  String get checkOutSuccess;

  /// No description provided for @timeJustNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {minutes} دقيقة'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {hours} ساعة'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeHoursAndMinutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {hours} ساعة و {minutes} د'**
  String timeHoursAndMinutesAgo(int hours, int minutes);

  /// No description provided for @memberCountBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} عضو'**
  String memberCountBadge(int count);

  /// No description provided for @membersTitle.
  ///
  /// In ar, this message translates to:
  /// **'المشتركين'**
  String get membersTitle;

  /// No description provided for @newMemberButton.
  ///
  /// In ar, this message translates to:
  /// **'مشترك جديد'**
  String get newMemberButton;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get search;

  /// No description provided for @searchMemberHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو رقم الموبايل...'**
  String get searchMemberHint;

  /// No description provided for @noMembersFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على نتائج'**
  String get noMembersFound;

  /// No description provided for @noMembersYetList.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مشتركين حتى الآن'**
  String get noMembersYetList;

  /// No description provided for @activeStatus.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get activeStatus;

  /// No description provided for @expiredStatus.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get expiredStatus;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In ar, this message translates to:
  /// **'سارية'**
  String get filterActive;

  /// No description provided for @filterExpiringSoon.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي قريباً'**
  String get filterExpiringSoon;

  /// No description provided for @filterExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get filterExpired;

  /// No description provided for @filterTodayAttendance.
  ///
  /// In ar, this message translates to:
  /// **'حضور اليوم'**
  String get filterTodayAttendance;

  /// No description provided for @totalMembers.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشتركين'**
  String get totalMembers;

  /// No description provided for @expiresOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي {date}'**
  String expiresOn(String date);

  /// No description provided for @memberProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف المشترك'**
  String get memberProfileTitle;

  /// No description provided for @activeSubscription.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك نشط'**
  String get activeSubscription;

  /// No description provided for @expiredSubscription.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك منتهي'**
  String get expiredSubscription;

  /// No description provided for @subscriptionDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الاشتراك'**
  String get subscriptionDetails;

  /// No description provided for @plan.
  ///
  /// In ar, this message translates to:
  /// **'الباقة'**
  String get plan;

  /// No description provided for @noPlan.
  ///
  /// In ar, this message translates to:
  /// **'بدون باقة'**
  String get noPlan;

  /// No description provided for @endDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء'**
  String get endDate;

  /// No description provided for @recordAttendance.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحضور'**
  String get recordAttendance;

  /// No description provided for @renewSubscription.
  ///
  /// In ar, this message translates to:
  /// **'تجديد الاشتراك'**
  String get renewSubscription;

  /// No description provided for @addNewMemberTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مشترك جديد'**
  String get addNewMemberTitle;

  /// No description provided for @enterMemberDataHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بيانات المشترك لتفعيل الحساب'**
  String get enterMemberDataHint;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالكامل'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: محمود سعيد'**
  String get fullNameHint;

  /// No description provided for @nameRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب إدخال الاسم'**
  String get nameRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم صحيح'**
  String get phoneInvalid;

  /// No description provided for @planOptional.
  ///
  /// In ar, this message translates to:
  /// **'الباقة (اختياري)'**
  String get planOptional;

  /// No description provided for @chooseImmediatePlan.
  ///
  /// In ar, this message translates to:
  /// **'اختر باقة التفعيل الفوري...'**
  String get chooseImmediatePlan;

  /// No description provided for @failedToLoadPlans.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الباقات'**
  String get failedToLoadPlans;

  /// No description provided for @saveAndActivate.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وتفعيل الاشتراك'**
  String get saveAndActivate;

  /// No description provided for @memberAddedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إضافة المشترك بنجاح ✅'**
  String get memberAddedSuccess;

  /// No description provided for @renewSubscriptionFor.
  ///
  /// In ar, this message translates to:
  /// **'تجديد اشتراك: {memberName}'**
  String renewSubscriptionFor(String memberName);

  /// No description provided for @selectPlanToRenew.
  ///
  /// In ar, this message translates to:
  /// **'اختر الباقة المراد تجديدها...'**
  String get selectPlanToRenew;

  /// No description provided for @paymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get paymentMethod;

  /// No description provided for @amountPaid.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المدفوع ({currency})'**
  String amountPaid(String currency);

  /// No description provided for @notesOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get notesOptional;

  /// No description provided for @notesHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: محول على إنستاباي رقم كذا'**
  String get notesHint;

  /// No description provided for @confirmPaymentAndRenew.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الدفع والتجديد'**
  String get confirmPaymentAndRenew;

  /// No description provided for @pleaseSelectPlan.
  ///
  /// In ar, this message translates to:
  /// **'برجاء اختيار الباقة'**
  String get pleaseSelectPlan;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال مبلغ صحيح'**
  String get pleaseEnterValidAmount;

  /// No description provided for @paymentCash.
  ///
  /// In ar, this message translates to:
  /// **'كاش'**
  String get paymentCash;

  /// No description provided for @paymentVisa.
  ///
  /// In ar, this message translates to:
  /// **'فيزا'**
  String get paymentVisa;

  /// No description provided for @paymentInstaPay.
  ///
  /// In ar, this message translates to:
  /// **'إنستاباي'**
  String get paymentInstaPay;

  /// No description provided for @paymentVodafoneCash.
  ///
  /// In ar, this message translates to:
  /// **'فودافون كاش'**
  String get paymentVodafoneCash;

  /// No description provided for @paymentOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get paymentOther;

  /// No description provided for @searchForMember.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مشترك'**
  String get searchForMember;

  /// No description provided for @nameOrPhoneHint.
  ///
  /// In ar, this message translates to:
  /// **'الاسم أو رقم الموبايل...'**
  String get nameOrPhoneHint;

  /// No description provided for @noMembersMatched.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على مشتركين'**
  String get noMembersMatched;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @appCustomization.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص التطبيق'**
  String get appCustomization;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة (Language)'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @managePlans.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الباقات'**
  String get managePlans;

  /// No description provided for @managePlansAndSubscriptions.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الباقات والاشتراكات'**
  String get managePlansAndSubscriptions;

  /// No description provided for @addPlan.
  ///
  /// In ar, this message translates to:
  /// **'إضافة باقة'**
  String get addPlan;

  /// No description provided for @editPlan.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الباقة'**
  String get editPlan;

  /// No description provided for @planName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الباقة'**
  String get planName;

  /// No description provided for @planNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: اشتراك شهري، 3 شهور...'**
  String get planNameHint;

  /// No description provided for @planNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب إدخال اسم الباقة'**
  String get planNameRequired;

  /// No description provided for @planDescriptionOptional.
  ///
  /// In ar, this message translates to:
  /// **'الوصف (اختياري)'**
  String get planDescriptionOptional;

  /// No description provided for @planDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل إضافية عن الباقة أو المميزات...'**
  String get planDescriptionHint;

  /// No description provided for @planPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الباقة ({currency})'**
  String planPrice(String currency);

  /// No description provided for @planPriceRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب إدخال سعر صحيح'**
  String get planPriceRequired;

  /// No description provided for @durationInDays.
  ///
  /// In ar, this message translates to:
  /// **'المدة بالأيام'**
  String get durationInDays;

  /// No description provided for @durationRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب إدخال عدد الأيام'**
  String get durationRequired;

  /// No description provided for @activePlan.
  ///
  /// In ar, this message translates to:
  /// **'نشطة'**
  String get activePlan;

  /// No description provided for @inactivePlan.
  ///
  /// In ar, this message translates to:
  /// **'غير نشطة'**
  String get inactivePlan;

  /// No description provided for @noPlansYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد باقات مضافة بعد'**
  String get noPlansYet;

  /// No description provided for @savePlan.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الباقة'**
  String get savePlan;

  /// No description provided for @planSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الباقة بنجاح ✅'**
  String get planSavedSuccess;

  /// No description provided for @durationDays.
  ///
  /// In ar, this message translates to:
  /// **'{count} يوم'**
  String durationDays(int count);

  /// No description provided for @commonDurations.
  ///
  /// In ar, this message translates to:
  /// **'المدد الشائعة'**
  String get commonDurations;

  /// No description provided for @days30.
  ///
  /// In ar, this message translates to:
  /// **'30 يوم (شهر)'**
  String get days30;

  /// No description provided for @days90.
  ///
  /// In ar, this message translates to:
  /// **'90 يوم (3 شهور)'**
  String get days90;

  /// No description provided for @days180.
  ///
  /// In ar, this message translates to:
  /// **'180 يوم (6 شهور)'**
  String get days180;

  /// No description provided for @days365.
  ///
  /// In ar, this message translates to:
  /// **'365 يوم (سنة)'**
  String get days365;

  /// No description provided for @planStatusUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث حالة الباقة بنجاح'**
  String get planStatusUpdated;

  /// No description provided for @planPriceFormatted.
  ///
  /// In ar, this message translates to:
  /// **'{price} {currency}'**
  String planPriceFormatted(String price, String currency);

  /// No description provided for @paymentsHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل المدفوعات والإيرادات'**
  String get paymentsHistory;

  /// No description provided for @totalCollected.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المحصل'**
  String get totalCollected;

  /// No description provided for @periodToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get periodToday;

  /// No description provided for @periodThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get periodThisMonth;

  /// No description provided for @periodAllTime.
  ///
  /// In ar, this message translates to:
  /// **'كل الأوقات'**
  String get periodAllTime;

  /// No description provided for @cashBreakdown.
  ///
  /// In ar, this message translates to:
  /// **'كاش'**
  String get cashBreakdown;

  /// No description provided for @instaPayBreakdown.
  ///
  /// In ar, this message translates to:
  /// **'إنستاباي'**
  String get instaPayBreakdown;

  /// No description provided for @vodafoneCashBreakdown.
  ///
  /// In ar, this message translates to:
  /// **'فودافون كاش'**
  String get vodafoneCashBreakdown;

  /// No description provided for @visaBreakdown.
  ///
  /// In ar, this message translates to:
  /// **'فيزا'**
  String get visaBreakdown;

  /// No description provided for @noPaymentsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مدفوعات مسجلة'**
  String get noPaymentsFound;

  /// No description provided for @registerBreakdown.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الخزينة'**
  String get registerBreakdown;

  /// No description provided for @sendWhatsappReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير واتساب'**
  String get sendWhatsappReminder;

  /// No description provided for @whatsappRenewalMessage.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً كابتن {memberName} 💪، بنفكرك إن اشتراكك في الجيم انتهى. مستنيينك تنورنا لتجديد الباقة وتكمل تمرينك!'**
  String whatsappRenewalMessage(String memberName);

  /// No description provided for @whatsappLaunchError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح واتساب على هذا الجهاز'**
  String get whatsappLaunchError;

  /// No description provided for @sortBy.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب حسب'**
  String get sortBy;

  /// No description provided for @sortNewest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث اشتراكاً'**
  String get sortNewest;

  /// No description provided for @sortExpiringSoon.
  ///
  /// In ar, this message translates to:
  /// **'الأقرب للانتهاء'**
  String get sortExpiringSoon;

  /// No description provided for @sortEndDateDesc.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الانتهاء (الأبعد)'**
  String get sortEndDateDesc;

  /// No description provided for @sortNameAsc.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (أ - ي)'**
  String get sortNameAsc;

  /// No description provided for @sortByPlan.
  ///
  /// In ar, this message translates to:
  /// **'الباقة'**
  String get sortByPlan;

  /// No description provided for @sortLastCheckIn.
  ///
  /// In ar, this message translates to:
  /// **'آخر حضور'**
  String get sortLastCheckIn;

  /// No description provided for @splashTagline.
  ///
  /// In ar, this message translates to:
  /// **'إدارة ذكية للجيم'**
  String get splashTagline;

  /// No description provided for @operations.
  ///
  /// In ar, this message translates to:
  /// **'العمليات'**
  String get operations;

  /// No description provided for @overview.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة'**
  String get overview;

  /// No description provided for @quickOperations.
  ///
  /// In ar, this message translates to:
  /// **'العمليات السريعة'**
  String get quickOperations;

  /// No description provided for @searchByNameOrPhone.
  ///
  /// In ar, this message translates to:
  /// **'البحث بالاسم أو الهاتف...'**
  String get searchByNameOrPhone;

  /// No description provided for @latestMembers.
  ///
  /// In ar, this message translates to:
  /// **'أحدث المشتركين'**
  String get latestMembers;

  /// No description provided for @revenueSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الإيرادات'**
  String get revenueSummary;

  /// No description provided for @checkInMember.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حضور'**
  String get checkInMember;

  /// No description provided for @appLogoSemanticLabel.
  ///
  /// In ar, this message translates to:
  /// **'شعار جيمي'**
  String get appLogoSemanticLabel;

  /// No description provided for @todayRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إيراد اليوم'**
  String get todayRevenue;

  /// No description provided for @includesDropIns.
  ///
  /// In ar, this message translates to:
  /// **'منها حصص مفردة: {amount}'**
  String includesDropIns(String amount);

  /// No description provided for @dropInSession.
  ///
  /// In ar, this message translates to:
  /// **'حصة مفردة'**
  String get dropInSession;

  /// No description provided for @dropInSessionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حصة مفردة'**
  String get dropInSessionTitle;

  /// No description provided for @guestNameOptional.
  ///
  /// In ar, this message translates to:
  /// **'اسم الزائر (اختياري)'**
  String get guestNameOptional;

  /// No description provided for @guestPhoneOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف (اختياري)'**
  String get guestPhoneOptional;

  /// No description provided for @recordAndCheckIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحصة والدخول'**
  String get recordAndCheckIn;

  /// No description provided for @dropInSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الحصة والدخول بنجاح ✅'**
  String get dropInSuccess;

  /// No description provided for @amountRequired.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال مبلغ صالح'**
  String get amountRequired;

  /// No description provided for @dropInNotesOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get dropInNotesOptional;

  /// No description provided for @last7Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر 7 أيام'**
  String get last7Days;

  /// No description provided for @attendance.
  ///
  /// In ar, this message translates to:
  /// **'الحضور'**
  String get attendance;

  /// No description provided for @revenue.
  ///
  /// In ar, this message translates to:
  /// **'الإيرادات'**
  String get revenue;

  /// No description provided for @weeklyTotalAttendance.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي: {count} حضور'**
  String weeklyTotalAttendance(int count);

  /// No description provided for @weeklyTotalRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي: {amount}'**
  String weeklyTotalRevenue(String amount);

  /// No description provided for @noActivityYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات بعد'**
  String get noActivityYet;

  /// No description provided for @selectedDaySummary.
  ///
  /// In ar, this message translates to:
  /// **'{date}: {value}'**
  String selectedDaySummary(String date, String value);

  /// No description provided for @syncStatusSynced.
  ///
  /// In ar, this message translates to:
  /// **'متزامن'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In ar, this message translates to:
  /// **'جاري المزامنة ({count})'**
  String syncStatusSyncing(int count);

  /// No description provided for @syncStatusOffline.
  ///
  /// In ar, this message translates to:
  /// **'أوفلاين'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusOfflineWithQueued.
  ///
  /// In ar, this message translates to:
  /// **'أوفلاين • {count} بالانتظار'**
  String syncStatusOfflineWithQueued(int count);

  /// No description provided for @syncStatusChecking.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحقق من المزامنة...'**
  String get syncStatusChecking;

  /// No description provided for @appFont.
  ///
  /// In ar, this message translates to:
  /// **'خط التطبيق'**
  String get appFont;

  /// No description provided for @fontDefault.
  ///
  /// In ar, this message translates to:
  /// **'الافتراضي'**
  String get fontDefault;

  /// No description provided for @fontAzer.
  ///
  /// In ar, this message translates to:
  /// **'آزر'**
  String get fontAzer;

  /// No description provided for @fontAlyamama.
  ///
  /// In ar, this message translates to:
  /// **'اليمامة'**
  String get fontAlyamama;

  /// No description provided for @accentColor.
  ///
  /// In ar, this message translates to:
  /// **'لون التطبيق'**
  String get accentColor;

  /// No description provided for @colorRoyalBlue.
  ///
  /// In ar, this message translates to:
  /// **'أزرق ملكي'**
  String get colorRoyalBlue;

  /// No description provided for @colorEnergyOrange.
  ///
  /// In ar, this message translates to:
  /// **'برتقالي حيوي'**
  String get colorEnergyOrange;

  /// No description provided for @colorEmerald.
  ///
  /// In ar, this message translates to:
  /// **'زمردي'**
  String get colorEmerald;

  /// No description provided for @colorCrimson.
  ///
  /// In ar, this message translates to:
  /// **'قرمزي'**
  String get colorCrimson;

  /// No description provided for @colorViolet.
  ///
  /// In ar, this message translates to:
  /// **'بنفسجي'**
  String get colorViolet;

  /// No description provided for @expiringSoonStatus.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي قريباً'**
  String get expiringSoonStatus;

  /// No description provided for @signOutConfirmationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOutConfirmationTitle;

  /// No description provided for @signOutConfirmationMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من رغبتك في تسجيل الخروج؟'**
  String get signOutConfirmationMessage;

  /// No description provided for @signOutUnsyncedWarning.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: يوجد {count} عمليات محلية لم تتم مزامنتها بعد. قد تفقد هذه البيانات في حال تسجيل الخروج الآن.'**
  String signOutUnsyncedWarning(int count);

  /// No description provided for @pressBackAgainToExit.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مرة أخرى للخروج'**
  String get pressBackAgainToExit;

  /// No description provided for @discardChangesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تراجع عن التغييرات'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تجاهل التغييرات الحالية؟ ستفقد البيانات التي قمت بإدخالها.'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التعديل'**
  String get keepEditing;

  /// No description provided for @gender.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In ar, this message translates to:
  /// **'ذكر'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In ar, this message translates to:
  /// **'أنثى'**
  String get genderFemale;

  /// No description provided for @deletePhotoTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف صورة المشترك'**
  String get deletePhotoTitle;

  /// No description provided for @deletePhotoConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف صورة المشترك؟'**
  String get deletePhotoConfirmMessage;

  /// No description provided for @deletePhotoSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الصورة بنجاح'**
  String get deletePhotoSuccess;

  /// No description provided for @removePhoto.
  ///
  /// In ar, this message translates to:
  /// **'حذف الصورة'**
  String get removePhoto;

  /// No description provided for @photoSourceCamera.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا'**
  String get photoSourceCamera;

  /// No description provided for @photoSourceGallery.
  ///
  /// In ar, this message translates to:
  /// **'المعرض'**
  String get photoSourceGallery;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @singleSession.
  ///
  /// In ar, this message translates to:
  /// **'حصة منفردة'**
  String get singleSession;

  /// No description provided for @singleSessionToday.
  ///
  /// In ar, this message translates to:
  /// **'حصة منفردة • اليوم'**
  String get singleSessionToday;

  /// No description provided for @serverEnvironment.
  ///
  /// In ar, this message translates to:
  /// **'بيئة الخادم'**
  String get serverEnvironment;

  /// No description provided for @selectServerEnvironment.
  ///
  /// In ar, this message translates to:
  /// **'اختر بيئة الخادم'**
  String get selectServerEnvironment;

  /// No description provided for @envStaging.
  ///
  /// In ar, this message translates to:
  /// **'تطوير (Staging)'**
  String get envStaging;

  /// No description provided for @envProduction.
  ///
  /// In ar, this message translates to:
  /// **'الإنتاج (Production)'**
  String get envProduction;

  /// No description provided for @envLocal.
  ///
  /// In ar, this message translates to:
  /// **'محلي (Local)'**
  String get envLocal;

  /// No description provided for @envCustom.
  ///
  /// In ar, this message translates to:
  /// **'مخصص (Custom URL)'**
  String get envCustom;

  /// No description provided for @customServerUrl.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الخادم المخصص'**
  String get customServerUrl;

  /// No description provided for @customUrlHint.
  ///
  /// In ar, this message translates to:
  /// **'http://10.0.2.2:5158 أو النطاق'**
  String get customUrlHint;

  /// No description provided for @environmentSwitched.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير بيئة الخادم إلى: {env}'**
  String environmentSwitched(String env);

  /// No description provided for @invalidUrl.
  ///
  /// In ar, this message translates to:
  /// **'عنوان URL غير صالح'**
  String get invalidUrl;
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
