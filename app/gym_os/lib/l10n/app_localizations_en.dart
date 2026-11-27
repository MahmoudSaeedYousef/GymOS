// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gymmy';

  @override
  String get currency => 'EGP';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get error => 'Error';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navMembers => 'Members';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginTitle => 'Gymmy';

  @override
  String get loginSubtitle => 'Sign in to manage your gym';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneHint => 'Enter registered phone number';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get quickSettings => 'Quick Settings';

  @override
  String get serverStatus => 'Server Status';

  @override
  String get serverOnline => 'Connected';

  @override
  String get loginButton => 'Sign In';

  @override
  String get invalidPhoneOrPassword => 'Invalid phone number or password';

  @override
  String get rateLimitTitle => 'Too Many Attempts';

  @override
  String rateLimitMessage(int seconds) {
    return 'Too many login attempts. Please wait $seconds seconds before trying again.';
  }

  @override
  String rateLimitCooldown(int seconds) {
    return 'Please wait ${seconds}s';
  }

  @override
  String get rateLimitExceeded =>
      'Too many login attempts. Please wait before trying again.';

  @override
  String get welcomeToGymOS => 'Welcome to Gymmy';

  @override
  String get loginSuccess => 'Signed in successfully';

  @override
  String get goodMorningCaptain => 'Good morning, Captain 👋';

  @override
  String get gymOverview => 'Gym Overview';

  @override
  String get currentlyInGym => 'Currently Inside Gym';

  @override
  String get tapToViewAndCheckout => 'Tap to view list & check out';

  @override
  String get activeMembers => 'Active Subscriptions';

  @override
  String get todayCheckIns => 'Today\'s Check-ins';

  @override
  String get expiredSubscriptions => 'Expired Subscriptions';

  @override
  String get monthlyRevenue => 'Monthly Revenue';

  @override
  String errorLoadingStats(String error) {
    return 'Error loading stats: $error';
  }

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get newMember => 'New Member';

  @override
  String get renewPlan => 'Renew Plan';

  @override
  String get checkIn => 'Check In';

  @override
  String get quickCheckIn => 'Quick Check-in';

  @override
  String get checkingIn => 'Checking in...';

  @override
  String get checkInSuccess => 'Check-in successful';

  @override
  String get recentMembers => 'Recent Members';

  @override
  String get viewAll => 'View All';

  @override
  String get noMembersYet => 'No members yet';

  @override
  String get memberUnit => 'Members';

  @override
  String get heroBadge => 'Hero';

  @override
  String get currentInsideTitle => 'Currently Inside Gym';

  @override
  String get noMembersInside => 'No members currently inside';

  @override
  String get realtimeGateUpdate => 'Updated in real-time from access gates';

  @override
  String get checkOut => 'Check Out';

  @override
  String get checkOutSuccess => 'Checked out successfully';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeHoursAndMinutesAgo(int hours, int minutes) {
    return '${hours}h ${minutes}m ago';
  }

  @override
  String memberCountBadge(int count) {
    return '$count members';
  }

  @override
  String get membersTitle => 'Members';

  @override
  String get newMemberButton => 'New Member';

  @override
  String get search => 'Search';

  @override
  String get searchMemberHint => 'Search by name or phone...';

  @override
  String get noMembersFound => 'No results found';

  @override
  String get noMembersYetList => 'No members yet';

  @override
  String get activeStatus => 'Active';

  @override
  String get expiredStatus => 'Expired';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterExpiringSoon => 'Expiring Soon';

  @override
  String get filterExpired => 'Expired';

  @override
  String get filterTodayAttendance => 'Today\'s Check-ins';

  @override
  String get totalMembers => 'Total Members';

  @override
  String expiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get memberProfileTitle => 'Member Profile';

  @override
  String get activeSubscription => 'Active Subscription';

  @override
  String get expiredSubscription => 'Expired Subscription';

  @override
  String get subscriptionDetails => 'Subscription Details';

  @override
  String get plan => 'Plan';

  @override
  String get noPlan => 'No plan';

  @override
  String get endDate => 'End Date';

  @override
  String get recordAttendance => 'Record Check-in';

  @override
  String get renewSubscription => 'Renew Subscription';

  @override
  String get addNewMemberTitle => 'Add New Member';

  @override
  String get enterMemberDataHint => 'Enter member details to activate account';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'e.g. Mahmoud Saeed';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get phoneInvalid => 'Enter a valid phone number';

  @override
  String get planOptional => 'Plan (Optional)';

  @override
  String get chooseImmediatePlan => 'Select instant activation plan...';

  @override
  String get failedToLoadPlans => 'Failed to load plans';

  @override
  String get saveAndActivate => 'Save & Activate';

  @override
  String get memberAddedSuccess => 'Member added successfully ✅';

  @override
  String renewSubscriptionFor(String memberName) {
    return 'Renew Subscription: $memberName';
  }

  @override
  String get selectPlanToRenew => 'Select plan to renew...';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String amountPaid(String currency) {
    return 'Amount Paid ($currency)';
  }

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get notesHint => 'e.g. Transferred via InstaPay';

  @override
  String get confirmPaymentAndRenew => 'Confirm Payment & Renew';

  @override
  String get pleaseSelectPlan => 'Please select a plan';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentVisa => 'Visa / Card';

  @override
  String get paymentInstaPay => 'InstaPay';

  @override
  String get paymentVodafoneCash => 'Vodafone Cash';

  @override
  String get paymentOther => 'Other';

  @override
  String get searchForMember => 'Search for a member';

  @override
  String get nameOrPhoneHint => 'Name or phone number...';

  @override
  String get noMembersMatched => 'No matching members found';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appCustomization => 'App Customization';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get account => 'Account';

  @override
  String get logout => 'Sign Out';

  @override
  String get managePlans => 'Manage Plans';

  @override
  String get managePlansAndSubscriptions => 'Manage Plans & Subscriptions';

  @override
  String get addPlan => 'Add Plan';

  @override
  String get editPlan => 'Edit Plan';

  @override
  String get planName => 'Plan Name';

  @override
  String get planNameHint => 'e.g., Monthly, 3 Months...';

  @override
  String get planNameRequired => 'Plan name is required';

  @override
  String get planDescriptionOptional => 'Description (Optional)';

  @override
  String get planDescriptionHint => 'Extra details or perks of this plan...';

  @override
  String planPrice(String currency) {
    return 'Plan Price ($currency)';
  }

  @override
  String get planPriceRequired => 'Please enter a valid price';

  @override
  String get durationInDays => 'Duration in Days';

  @override
  String get durationRequired => 'Duration is required';

  @override
  String get activePlan => 'Active';

  @override
  String get inactivePlan => 'Inactive';

  @override
  String get noPlansYet => 'No plans added yet';

  @override
  String get savePlan => 'Save Plan';

  @override
  String get planSavedSuccess => 'Plan saved successfully ✅';

  @override
  String durationDays(int count) {
    return '$count Days';
  }

  @override
  String get commonDurations => 'Common Durations';

  @override
  String get days30 => '30 Days (Month)';

  @override
  String get days90 => '90 Days (3 Months)';

  @override
  String get days180 => '180 Days (6 Months)';

  @override
  String get days365 => '365 Days (Year)';

  @override
  String get planStatusUpdated => 'Plan status updated successfully';

  @override
  String planPriceFormatted(String price, String currency) {
    return '$price $currency';
  }

  @override
  String get paymentsHistory => 'Payments & Revenue History';

  @override
  String get totalCollected => 'Total Collected';

  @override
  String get periodToday => 'Today';

  @override
  String get periodThisMonth => 'This Month';

  @override
  String get periodAllTime => 'All Time';

  @override
  String get cashBreakdown => 'Cash';

  @override
  String get instaPayBreakdown => 'InstaPay';

  @override
  String get vodafoneCashBreakdown => 'Vodafone Cash';

  @override
  String get visaBreakdown => 'Visa';

  @override
  String get noPaymentsFound => 'No payments recorded';

  @override
  String get registerBreakdown => 'Register Breakdown';

  @override
  String get sendWhatsappReminder => 'WhatsApp Reminder';

  @override
  String whatsappRenewalMessage(String memberName) {
    return 'Hi $memberName 💪, just a friendly reminder that your gym subscription has expired. We\'d love to see you back soon to renew and keep up your progress!';
  }

  @override
  String get whatsappLaunchError => 'Could not launch WhatsApp on this device';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortNewest => 'Newest First';

  @override
  String get sortExpiringSoon => 'Expiring Soonest';

  @override
  String get sortEndDateDesc => 'End Date (Latest)';

  @override
  String get sortNameAsc => 'Name (A - Z)';

  @override
  String get sortByPlan => 'Subscription Plan';

  @override
  String get sortLastCheckIn => 'Last Check-In';

  @override
  String get splashTagline => 'Smart Gym Management';

  @override
  String get operations => 'Operations';

  @override
  String get overview => 'Insights';

  @override
  String get quickOperations => 'Quick Operations';

  @override
  String get searchByNameOrPhone => 'Search name or phone...';

  @override
  String get latestMembers => 'Latest Members';

  @override
  String get revenueSummary => 'Revenue Summary';

  @override
  String get checkInMember => 'Check In';

  @override
  String get appLogoSemanticLabel => 'Gymmy logo';

  @override
  String get todayRevenue => 'Today\'s Revenue';

  @override
  String includesDropIns(String amount) {
    return 'Includes drop-ins: $amount';
  }

  @override
  String get dropInSession => 'Drop-in session';

  @override
  String get dropInSessionTitle => 'Record Drop-in Session';

  @override
  String get guestNameOptional => 'Guest name (optional)';

  @override
  String get guestPhoneOptional => 'Guest phone (optional)';

  @override
  String get recordAndCheckIn => 'Record & Check In';

  @override
  String get dropInSuccess =>
      'Drop-in visit recorded and checked in successfully ✅';

  @override
  String get amountRequired => 'Please enter a valid amount';

  @override
  String get dropInNotesOptional => 'Notes (optional)';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get attendance => 'Attendance';

  @override
  String get revenue => 'Revenue';

  @override
  String weeklyTotalAttendance(int count) {
    return 'Total: $count check-ins';
  }

  @override
  String weeklyTotalRevenue(String amount) {
    return 'Total: $amount';
  }

  @override
  String get noActivityYet => 'No activity data yet';

  @override
  String selectedDaySummary(String date, String value) {
    return '$date: $value';
  }

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String syncStatusSyncing(int count) {
    return 'Syncing ($count)';
  }

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String syncStatusOfflineWithQueued(int count) {
    return 'Offline • $count queued';
  }

  @override
  String get syncStatusChecking => 'Checking sync status...';

  @override
  String get appFont => 'App Font';

  @override
  String get fontDefault => 'Default';

  @override
  String get fontAzer => 'Azer';

  @override
  String get fontAlyamama => 'Al-Yamama';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get colorRoyalBlue => 'Royal Blue';

  @override
  String get colorEnergyOrange => 'Energy Orange';

  @override
  String get colorEmerald => 'Emerald';

  @override
  String get colorCrimson => 'Crimson';

  @override
  String get colorViolet => 'Violet';

  @override
  String get expiringSoonStatus => 'Expiring Soon';

  @override
  String get signOutConfirmationTitle => 'Sign Out';

  @override
  String get signOutConfirmationMessage => 'Are you sure you want to sign out?';

  @override
  String signOutUnsyncedWarning(int count) {
    return 'Warning: You have $count unsynced local records. You may lose this data if you sign out now.';
  }

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get discardChangesTitle => 'Discard Changes';

  @override
  String get discardChangesMessage =>
      'Are you sure you want to discard your changes? Any entered data will be lost.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep Editing';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get deletePhotoTitle => 'Remove Member Photo';

  @override
  String get deletePhotoConfirmMessage =>
      'Are you sure you want to remove this member\'s photo?';

  @override
  String get deletePhotoSuccess => 'Photo removed successfully';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get photoSourceCamera => 'Camera';

  @override
  String get photoSourceGallery => 'Gallery';

  @override
  String get delete => 'Delete';

  @override
  String get singleSession => 'Single Session';

  @override
  String get singleSessionToday => 'Single Session • Today';

  @override
  String get serverEnvironment => 'Server Environment';

  @override
  String get selectServerEnvironment => 'Select Server Environment';

  @override
  String get envStaging => 'Staging';

  @override
  String get envProduction => 'Production';

  @override
  String get envLocal => 'Local (Emulator)';

  @override
  String get envCustom => 'Custom URL';

  @override
  String get customServerUrl => 'Custom Server URL';

  @override
  String get customUrlHint => 'http://10.0.2.2:5158 or domain';

  @override
  String environmentSwitched(String env) {
    return 'Server environment switched to: $env';
  }

  @override
  String get invalidUrl => 'Invalid URL';
}
