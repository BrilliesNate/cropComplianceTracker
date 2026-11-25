// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAfrikaans => 'Afrikaans';

  @override
  String get appTitle => 'Crop Compliance';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonSwitch => 'Switch';

  @override
  String get commonRetry => 'Try again';

  @override
  String get navHome => 'Home';

  @override
  String get navAuditChecklist => 'Audit checklist';

  @override
  String get navPayslips => 'Payslips';

  @override
  String get navProfile => 'Profile';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get signOut => 'Sign out';

  @override
  String get farm => 'Farm';

  @override
  String get farmOpenLabel => 'Farm open';

  @override
  String get farmNoneViewingAll => 'None — viewing all farms';

  @override
  String get farmOpenAFarm => 'Open a farm';

  @override
  String get farmSwitchFarm => 'Switch farm';

  @override
  String get farmChooseAFarm => 'Choose a farm';

  @override
  String get farmBackToAll => 'Back to all farms';

  @override
  String farmViewing(String name) {
    return 'Viewing farm $name';
  }

  @override
  String unreadCountNew(int count) {
    return '$count new';
  }

  @override
  String get syncOffline => 'Offline — your work is saved on this phone';

  @override
  String syncFilesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files waiting to upload',
      one: '1 file waiting to upload',
    );
    return '$_temp0';
  }

  @override
  String get syncAllSynced => 'Everything is synced';

  @override
  String get syncUploadNow => 'Upload now';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String signOutPendingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files are still waiting to upload.',
      one: '1 file is still waiting to upload.',
    );
    return '$_temp0 They stay on this phone and upload next time someone signs in here with signal.';
  }

  @override
  String get signOutCanSignInAgain => 'You can sign in again any time.';

  @override
  String get languageHint =>
      'Choose the language for the app, your notifications and downloads.';

  @override
  String get farmWhichFarm => 'Which farm?';

  @override
  String get farmPickForChecklist =>
      'Pick the farm whose audit checklist you want to see.';

  @override
  String get farmPickForPayslips =>
      'Pick the farm whose payslips you want to manage.';

  @override
  String get farmSearchHint => 'Search farms…';

  @override
  String get farmLoadFailed =>
      'Could not load the farms. Check your signal and try again.';

  @override
  String get farmNoSearchMatch => 'No farms match your search.';

  @override
  String offlineWithFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You’re offline — your work is saved on this phone. $count files will upload when you’re back online.',
      one:
          'You’re offline — your work is saved on this phone. 1 file will upload when you’re back online.',
    );
    return '$_temp0';
  }

  @override
  String get offlineNoFiles =>
      'You’re offline — your work is saved on this phone and will sync when you’re back online.';

  @override
  String offlineUploading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Back online — uploading $count files…',
      one: 'Back online — uploading 1 file…',
    );
    return '$_temp0';
  }

  @override
  String offlineRetrying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files waiting to upload — retrying shortly.',
      one: '1 file waiting to upload — retrying shortly.',
    );
    return '$_temp0';
  }

  @override
  String get offlineRetryNow => 'Retry now';

  @override
  String pendingSavedOfflineTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Saved offline — $count files will upload automatically when the phone is back online.',
      one:
          'Saved offline — 1 file will upload automatically when the phone is back online.',
    );
    return '$_temp0';
  }

  @override
  String get pendingWaitingToUpload => 'Waiting to upload';

  @override
  String pendingSavedOnThisPhone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count files saved on this phone — uploading automatically when you’re online.',
      one:
          '1 file saved on this phone — uploading automatically when you’re online.',
    );
    return '$_temp0';
  }

  @override
  String pendingUploadingFromOtherPhone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files still uploading from the phone they were saved on.',
      one: '1 file still uploading from the phone it was saved on.',
    );
    return '$_temp0';
  }

  @override
  String get adminSortMostPending => 'Most pending first';

  @override
  String get adminSortName => 'Name (A–Z)';

  @override
  String get adminSortLowest => 'Lowest progress first';

  @override
  String get adminSortHighest => 'Highest progress first';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get adminTools => 'Admin tools';

  @override
  String get commonSearchHint => 'Search…';

  @override
  String get adminShowTwoPerRow => 'Show two farms per row';

  @override
  String get adminShowOnePerRow => 'Show one farm per row';

  @override
  String get adminSortAndFilter => 'Sort and filter';

  @override
  String get adminLoadFailed =>
      'Could not load the farms. If you are offline, connect and try again.';

  @override
  String get adminNoFarmsYet => 'There are no farms yet.';

  @override
  String get adminNoFarmsMatch => 'No farms match your search or filters.';

  @override
  String get adminAddFarm => 'Add a farm';

  @override
  String get adminClearSearchFilters => 'Clear search and filters';

  @override
  String get commonReset => 'Reset';

  @override
  String get adminSortBy => 'Sort by';

  @override
  String get adminStandards => 'Standards';

  @override
  String get adminOnlyPending => 'Only farms with pending documents';

  @override
  String adminShowFarms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count farms',
      one: 'Show 1 farm',
    );
    return '$_temp0';
  }

  @override
  String get menuCompanyManagement => 'Company Management';

  @override
  String get menuUserManagement => 'User Management';

  @override
  String get menuCategoryManagement => 'Category Management';

  @override
  String get menuDocumentSettings => 'Document Settings';

  @override
  String get menuDataFixUtility => 'Data Fix Utility';

  @override
  String get menuFarmableConsole => 'Farmable API Console';

  @override
  String adminFarmCardSemantics(String name, int pending, int percent) {
    return '$name, $pending pending documents, $percent percent complete';
  }

  @override
  String get farmNoAddress => 'No address yet';

  @override
  String pendingDocumentsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pending Documents',
      one: 'Pending Document',
    );
    return '$_temp0';
  }

  @override
  String employeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Employees',
      one: '1 Employee',
    );
    return '$_temp0';
  }

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusInReview => 'In review';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusNotApplicable => 'N/A';

  @override
  String get statusToUpload => 'To upload';

  @override
  String get trackerTitle => 'Compliance Tracker';

  @override
  String get trackerNoStandards =>
      'No audit standards are switched on for this farm yet.';

  @override
  String get trackerAskAdmin =>
      'Ask your Crop Compliance administrator to turn on SIZA/WIETA, GlobalG.A.P., IPW, Fairtrade or SIZA Environmental for your farm.';

  @override
  String get trackerOpenChecklist => 'Open audit checklist';

  @override
  String get trackerOverallProgress => 'Overall progress';

  @override
  String get trackerYouAreHere => 'You are here';

  @override
  String get trackerBehindYou => 'Behind you';

  @override
  String trackerDoneCount(int count) {
    return '$count done';
  }

  @override
  String get trackerFirstUploadHere => 'Your first upload will show here';

  @override
  String trackerAndMore(int count) {
    return '…and $count more';
  }

  @override
  String get trackerAllCaughtUp =>
      'All caught up — every requirement has been submitted.';

  @override
  String get statusRequired => 'Required';

  @override
  String trackerHintRejectedReason(String reason) {
    return 'It was rejected: $reason. Upload a corrected version.';
  }

  @override
  String get trackerHintRejected =>
      'It was rejected. Upload a corrected version.';

  @override
  String get trackerHintExpired =>
      'It has expired. Upload the renewed document.';

  @override
  String trackerHintUpload(String type, String category) {
    return 'Upload the $type for $category.';
  }

  @override
  String get trackerRightNow => 'Right now';

  @override
  String get trackerInFront => 'In front of you';

  @override
  String trackerToGo(int count) {
    return '$count to go';
  }

  @override
  String get trackerNothingLeft => 'Nothing left';

  @override
  String get trackerLastOne => 'This is the last one';

  @override
  String actionResubmitType(String type) {
    return 'Resubmit $type';
  }

  @override
  String actionRenewType(String type) {
    return 'Renew $type';
  }

  @override
  String actionUploadType(String type) {
    return 'Upload $type';
  }

  @override
  String get checklistTitle => 'Audit Checklist';

  @override
  String get checklistAskAdmin =>
      'Ask your Crop Compliance administrator to turn one on for your farm.';

  @override
  String get checklistNothingInCategory =>
      'Nothing to upload in this category.';

  @override
  String get checklistSeeAllUploaded => 'See all uploaded documents';

  @override
  String get ruleMultipleAllowed => 'Multiple documents allowed';

  @override
  String get ruleHasExpiry => 'Has an expiry date';

  @override
  String get ruleFilledInApp => 'Filled in on the app';

  @override
  String get actionUpload => 'Upload';

  @override
  String get actionFillIn => 'Fill in';

  @override
  String get actionFix => 'Fix';

  @override
  String get actionRenew => 'Renew';

  @override
  String get uploadTakePhoto => 'Take a photo';

  @override
  String get uploadChooseFileTypes => 'Choose a file (PDF, Word, photo)';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get uploadNeedFileFirst => 'Choose a file or take a photo first.';

  @override
  String get uploadNeedExpiry => 'Tap the expiry date on the calendar.';

  @override
  String get uploadNeedReviewed => 'Choose the date it was last reviewed.';

  @override
  String get uploadNeedSpec =>
      'Add a specification — what does this upload cover?';

  @override
  String get uploadNoFarm =>
      'No farm selected — open the dashboard and try again.';

  @override
  String errorSomethingWrong(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get uploadFailed => 'The upload didn’t go through — please try again.';

  @override
  String get uploadSavedOffline =>
      'Saved on your phone — it will upload automatically when you’re online.';

  @override
  String get uploadDoneWaitingReview =>
      'Uploaded — it’s now waiting for review.';

  @override
  String get uploadTapExpiry => 'Tap the expiry date';

  @override
  String get uploadSubtitleWithExpiry =>
      'Upload the document and set its expiry date';

  @override
  String get uploadSubtitle => 'Upload the document';

  @override
  String get uploadSpecRequired => 'Specification (required)';

  @override
  String get uploadSpecOptional => 'Specification (optional)';

  @override
  String get uploadSpecHint => 'What does it cover? e.g. site, period';

  @override
  String get uploadChooseFileOrPhoto => 'Choose a file or photo';

  @override
  String get uploadTypeLoadFailed => 'This document type couldn’t be loaded.';

  @override
  String get expiryDate => 'Expiry date';

  @override
  String get uploadNoFileYet => 'No file chosen yet';

  @override
  String uploadFileAndMore(String name, int count) {
    return '$name + $count more';
  }

  @override
  String get actionChange => 'Change';

  @override
  String get uploadExpiryLabel => 'Expiry date: ';

  @override
  String get uploadNotSet => 'not set';

  @override
  String uploadSelectedDocs(int count) {
    return 'Selected documents ($count)';
  }

  @override
  String get actionPreview => 'Preview';

  @override
  String get dateLastReviewed => 'Date last reviewed';

  @override
  String get dateLastReviewedRequired => 'Date last reviewed (required)';

  @override
  String lastReviewedOn(String date) {
    return 'Last reviewed: $date';
  }

  @override
  String get hoursTabRate => 'Rate\n(R/hr)';

  @override
  String get hoursTabNormal => 'Norm\nhrs';

  @override
  String get hoursTabOvertime => 'OT\nhrs';

  @override
  String get hoursTabDouble => 'DT\nhrs';

  @override
  String get hoursTabPublicHoliday => 'PH\nhrs';

  @override
  String get hoursTabSick => 'SL\nhrs';

  @override
  String get hoursTabHoliday => 'HL\nhrs';

  @override
  String get hoursTabFamily => 'FL\nhrs';

  @override
  String get hoursTypeNumber => 'Type a number, e.g. 8 or 7.5';

  @override
  String hoursSetRateFirst(String name) {
    return 'Set $name’s hourly rate first.';
  }

  @override
  String get hoursEnterFirst => 'Enter the hours worked first.';

  @override
  String get payslipReplaceTitle => 'Replace this payslip?';

  @override
  String payslipReplaceBody(String name, String start, String end) {
    return '$name already has a payslip for $start – $end. Replace it with these hours?';
  }

  @override
  String get actionReplace => 'Replace';

  @override
  String get payslipSaveFailed =>
      'The payslip couldn’t be saved — please try again.';

  @override
  String payslipSavedFor(String name, String amount) {
    return 'Payslip saved for $name — net $amount';
  }

  @override
  String get periodStart => 'Period start';

  @override
  String get periodEnd => 'Period end';

  @override
  String payslipsHeaderTitle(String farm) {
    return '$farm – Payslips';
  }

  @override
  String get employeesLabel => 'Employees';

  @override
  String get chooseFarmFirst => 'Choose a farm first.';

  @override
  String get employeeLabel => 'Employee';

  @override
  String get actionViewAll => 'View All';

  @override
  String get hoursWorked => 'Hours Worked';

  @override
  String payslipNoneYetFor(String name) {
    return 'No payslip yet for $name. Enter the hours below and save.';
  }

  @override
  String payslipNormalPayHours(String hours) {
    return 'Normal Pay ($hours h)';
  }

  @override
  String payslipOvertimePayHours(String hours) {
    return 'Overtime Pay ($hours h)';
  }

  @override
  String payslipDoubleTimeHours(String hours) {
    return 'Double Time ($hours h)';
  }

  @override
  String payslipPublicHolidayHours(String hours) {
    return 'Public Holiday ($hours h)';
  }

  @override
  String payslipSickLeaveHours(String hours) {
    return 'Sick Leave ($hours h)';
  }

  @override
  String payslipAnnualLeaveHours(String hours) {
    return 'Annual Leave ($hours h)';
  }

  @override
  String payslipFamilyLeaveHours(String hours) {
    return 'Family Responsibility Leave ($hours h)';
  }

  @override
  String get payslipTitle => 'PAYSLIP';

  @override
  String get payslipName => 'Name';

  @override
  String get payslipIdNumber => 'ID Number';

  @override
  String get payslipPeriod => 'Period';

  @override
  String get payslipPayDate => 'Pay Date';

  @override
  String get payslipEarnings => 'EARNINGS';

  @override
  String get payslipTotalEarnings => 'TOTAL EARNINGS';

  @override
  String get payslipDeductions => 'DEDUCTIONS';

  @override
  String get payslipUifEmployee => 'UIF Employee (1%)';

  @override
  String get payslipPayeTax => 'PAYE Tax';

  @override
  String get payslipTotalDeductions => 'TOTAL DEDUCTIONS';

  @override
  String get payslipNetSalary => 'Net Salary';

  @override
  String get actionDownloadPdf => 'Download PDF';

  @override
  String pdfOpenFailed(String error) {
    return 'Could not open the PDF: $error';
  }

  @override
  String get employeesNoneYetTapAdd =>
      'No employees yet — tap to add your first one.';

  @override
  String get employeeNoId => 'No ID';

  @override
  String employeeIdShort(String id) {
    return 'ID $id';
  }

  @override
  String get employeeSearchHint => 'Search name or ID';

  @override
  String get employeeAdd => 'Add employee';

  @override
  String get actionEdit => 'Edit';

  @override
  String saveFailedReason(String reason) {
    return 'Could not save: $reason';
  }

  @override
  String get errorUnknown => 'unknown error';

  @override
  String hoursLeft(String hours) {
    return '$hours h left';
  }

  @override
  String get hoursHelpRate =>
      'Employee’s base hourly wage in Rand, used to calculate all earnings';

  @override
  String get hoursHelpNormal => 'Ordinary hours worked in this period';

  @override
  String get hoursHelpOvertime => 'Overtime hours — paid at 1.5 × the rate';

  @override
  String get hoursHelpDouble =>
      'Double-time hours (e.g. Sundays) — paid at 2 × the rate';

  @override
  String get hoursHelpPublicHoliday => 'Paid public-holiday hours';

  @override
  String hoursHelpSick(String balance) {
    return 'Sick leave taken · $balance';
  }

  @override
  String hoursHelpHoliday(String balance) {
    return 'Annual leave taken · $balance';
  }

  @override
  String hoursHelpFamily(String balance) {
    return 'Family responsibility leave · $balance';
  }

  @override
  String employeeIdLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get dateStart => 'Start';

  @override
  String get dateEnd => 'End';

  @override
  String get actionSetDone => 'Set ✓';

  @override
  String get actionSet => 'Set';

  @override
  String hoursEntered(String list) {
    return 'Entered: $list';
  }

  @override
  String payslipSaveFor(String name) {
    return 'Save payslip for $name';
  }

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get kpiCompletionRate => 'Completion Rate';

  @override
  String get kpiApprovalRate => 'Approval Rate';

  @override
  String get kpiPendingReview => 'Pending Review';

  @override
  String get docsNoneYet => 'No documents yet.';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentLabel => 'Document';

  @override
  String get statusPending => 'Pending';

  @override
  String get dashboardDocumentComments => 'Document Comments';

  @override
  String get dashboardAllGood => 'All documents in good standing';

  @override
  String rejectedOnDate(String date) {
    return 'Rejected - $date';
  }

  @override
  String get actionResubmit => 'Resubmit';

  @override
  String get farmPickForPage =>
      'This page shows one farm. Pick the farm you want to work on.';

  @override
  String get menuComplianceReport => 'Compliance Report';

  @override
  String get menuAuditIndex => 'Audit Index';

  @override
  String get menuPayslipManager => 'Payslip Manager';

  @override
  String get menuMyFarms => 'My Farms';

  @override
  String get menuFarmRegister => 'Farm Register';

  @override
  String get menuSprayRecords => 'Spray Records';

  @override
  String get menuFarmableSection => 'FARMABLE';

  @override
  String get logout => 'Logout';

  @override
  String get menuCollapse => 'Collapse';

  @override
  String get farmSelect => 'Select farm';

  @override
  String farmSwitchTooltip(String name) {
    return 'Switch farm — $name';
  }

  @override
  String get farmSwitchFailed => 'Could not switch farm. Please try again.';

  @override
  String get adminModeManagingFor => 'ADMIN MODE: Managing documents for ';

  @override
  String get adminModeOwnDocs => 'Admin Mode: Managing your own documents';

  @override
  String get actionSwitchBack => 'Switch Back';

  @override
  String get selectUserToManage => 'Select User to Manage';

  @override
  String get selectUserToManageHint =>
      'Choose a user to manage their documents and compliance status.';

  @override
  String get you => 'You';

  @override
  String get manageOwnDocs => 'Manage your own documents';

  @override
  String get farmTapToSwitch => 'Tap to switch farm';

  @override
  String farmAccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have access to $count farms.',
      one: 'You have access to 1 farm.',
    );
    return '$_temp0';
  }

  @override
  String farmNoMatchQuery(String query) {
    return 'No farms match “$query”';
  }

  @override
  String get errorTitle => 'Error';

  @override
  String get actionRetry => 'Retry';

  @override
  String get statusExpiresSoon => 'Expires Soon';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleAuditor => 'Auditor';

  @override
  String get roleUser => 'User';

  @override
  String get loginTagline1 => 'Simplified Compliance,';

  @override
  String get loginTagline2 => 'Guaranteed Success';

  @override
  String get loginFeature1 => 'Streamlined document management';

  @override
  String get loginFeature2 => 'Real-time compliance tracking';

  @override
  String get loginFeature3 => 'Effortless audit preparation';

  @override
  String get loginFeature4 => 'Comprehensive compliance reports';

  @override
  String loginCopyright(String year) {
    return '© $year Crop Compliance. All rights reserved.';
  }

  @override
  String get loginWelcomeBack => 'Welcome back!';

  @override
  String get loginEnterCredentials =>
      'Enter your credentials to access your account';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldEmailHint => 'Enter your email';

  @override
  String get validationEmailRequired => 'Please enter your email';

  @override
  String get validationEmailInvalid => 'Please enter a valid email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordHint => 'Enter your password';

  @override
  String get validationPasswordRequired => 'Please enter your password';

  @override
  String get loginRememberMe => 'Remember me';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get loginNoAccount => 'Don’t have an account? ';

  @override
  String get loginContactSupport => 'Contact Support';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordBody =>
      'Enter your account email. We’ll send a reset link if an account exists.';

  @override
  String get resetPasswordSpamHint =>
      'If it doesn’t arrive within a few minutes, check your spam folder — or contact your admin, who can set a new password for you directly.';

  @override
  String get validationEmailValidAddress => 'Enter a valid email address';

  @override
  String resetPasswordSent(String email) {
    return 'If an account exists for $email, a reset email is on its way. Check spam if it doesn’t arrive soon.';
  }

  @override
  String get resetPasswordFailed =>
      'Something went wrong. Please contact your admin for help resetting your password.';

  @override
  String get resetPasswordSend => 'Send Reset Link';

  @override
  String get authSignedOut => 'You have been signed out. Please sign in again.';

  @override
  String get authOtherAccount =>
      'This browser is now signed in as a different account. Please sign in again.';

  @override
  String authInitFailed(String error) {
    return 'Failed to initialize user: $error';
  }

  @override
  String authLoadUsersFailed(String error) {
    return 'Failed to load users: $error';
  }

  @override
  String authAdminView(String name) {
    return '$name (Admin View)';
  }

  @override
  String get unknownUser => 'Unknown User';

  @override
  String authManaging(String name) {
    return 'Managing $name';
  }

  @override
  String get authPersonalAccount => 'Personal account';

  @override
  String get authInvalidLogin => 'Invalid email or password';

  @override
  String authLoginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get authRegisterFailed => 'Registration failed';

  @override
  String authRegisterFailedReason(String error) {
    return 'Registration failed: $error';
  }

  @override
  String authLogoutFailed(String error) {
    return 'Logout failed: $error';
  }

  @override
  String authResetFailed(String error) {
    return 'Password reset failed: $error';
  }

  @override
  String get authDeactivated =>
      'This account has been deactivated. Please contact your administrator.';

  @override
  String get pleaseLogIn => 'Please log in to continue';

  @override
  String get dashboardLoading => 'Loading dashboard data...';

  @override
  String get adminModeManagingCompany => 'ADMIN MODE: Managing Company';

  @override
  String get adminModeManagingUser => 'ADMIN MODE: Managing User';

  @override
  String viaUser(String name) {
    return 'via $name';
  }

  @override
  String get switchBackOwnAccount => 'Switch back to your own account';

  @override
  String get userFallbackName => 'User';

  @override
  String dashboardManagingName(String name) {
    return 'Managing: $name';
  }

  @override
  String dashboardHiName(String name) {
    return 'Hi, $name';
  }

  @override
  String get dashboardOverview => 'Document compliance overview';

  @override
  String get dashboardWelcomeBackShort => 'Welcome back.';

  @override
  String get kpiActionNeeded => 'Action Needed';

  @override
  String get kpiRejectedItem => 'Rejected Item';

  @override
  String get kpiNeedsAttention => 'Needs Attention';

  @override
  String teamAllUsersManaging(String name) {
    return 'All Users (Managing: $name)';
  }

  @override
  String get teamAllUsers => 'All Users';

  @override
  String get teamMembers => 'Team Members';

  @override
  String get teamAddUser => 'Add User';

  @override
  String pageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get teamNoUsers => 'No users found';

  @override
  String get noMatches => 'No matches';

  @override
  String get teamLoadError => 'Error loading team';

  @override
  String get teamNoMembers => 'No team members';

  @override
  String teamLoadingDocsFor(String name) {
    return 'Loading $name’s documents...';
  }

  @override
  String teamNowManaging(String name) {
    return 'Now managing: $name';
  }

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String docsTotalCount(int count) {
    return '$count total';
  }

  @override
  String get colDocumentType => 'Document Type';

  @override
  String get colStatus => 'Status';

  @override
  String get colUpdated => 'Updated';

  @override
  String get colExpires => 'Expires';

  @override
  String get docsNoneFound => 'No documents found';

  @override
  String get commentsCardTitle => 'Document Comment';

  @override
  String get commentsNoRejected => 'No rejected documents with comments';

  @override
  String get commentsAllGood => 'All documents are in good standing';

  @override
  String get unknownDocument => 'Unknown Document';

  @override
  String get commentsActionRequired => 'Action required: Update and resubmit';

  @override
  String get actionDetails => 'Details';

  @override
  String get adminDashLoadFailed => 'Could not load the dashboard.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get kpiCompanies => 'Companies';

  @override
  String get kpiUsers => 'Users';

  @override
  String get adminSearchCompanies => 'Search companies...';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get adminNoCompanies => 'No companies found';

  @override
  String get categoriesLoading => 'Loading categories...';

  @override
  String get categoriesNoneFound => 'No categories found';

  @override
  String docCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count docs',
      one: '1 doc',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedEllipsis => 'Delete Selected...';

  @override
  String deleteAllCount(int count) {
    return 'Delete All ($count)';
  }

  @override
  String get deleteAllDocsTitle => 'Delete All Documents?';

  @override
  String deleteAllDocsIn(int count) {
    return 'You are about to delete ALL $count documents in:';
  }

  @override
  String get cannotBeUndone => '⚠️ This action CANNOT be undone!';

  @override
  String deleteAllCaps(int count) {
    return 'DELETE ALL ($count)';
  }

  @override
  String get selectDocsToDelete => 'Select Documents to Delete';

  @override
  String selectedOfTotal(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get actionSelectAll => 'Select All';

  @override
  String get actionClear => 'Clear';

  @override
  String get unknownType => 'Unknown Type';

  @override
  String docDeleteLine(String status, int files, String date) {
    return 'Status: $status | Files: $files\nCreated: $date';
  }

  @override
  String deleteCaps(int count) {
    return 'DELETE ($count)';
  }

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String confirmDeleteDocs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Are you sure you want to delete $count documents?',
      one: 'Are you sure you want to delete 1 document?',
    );
    return '$_temp0';
  }

  @override
  String deletingDocs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleting $count documents...',
      one: 'Deleting 1 document...',
    );
    return '$_temp0';
  }

  @override
  String deletedDocsOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '✓ Deleted $count documents',
      one: '✓ Deleted 1 document',
    );
    return '$_temp0';
  }

  @override
  String deletedSomeFailed(int ok, int failed) {
    return 'Deleted $ok, failed $failed';
  }

  @override
  String get docsLoading => 'Loading documents...';

  @override
  String get filterLabel => 'Filter';

  @override
  String get filterAll => 'All';

  @override
  String get docsSearchHint => 'Search documents...';

  @override
  String get docsTryAdjusting =>
      'Try adjusting your filters or search criteria';

  @override
  String documentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents',
      one: '1 document',
    );
    return '$_temp0';
  }

  @override
  String get unknownDocumentType => 'Unknown Document Type';

  @override
  String get specification => 'Specification';

  @override
  String get specNone => 'No specification provided';

  @override
  String lastReviewedShort(String date) {
    return 'Last reviewed $date';
  }

  @override
  String reviewedSuffix(String date) {
    return ' · reviewed $date';
  }

  @override
  String get uploadedBy => 'Uploaded By';

  @override
  String get uploadDate => 'Upload Date';

  @override
  String get expiryDateTitle => 'Expiry Date';

  @override
  String get expiryNone => 'No expiry date';

  @override
  String get statusLabelColon => 'Status: ';

  @override
  String get actionViewDetails => 'View Details';

  @override
  String get filterDocsTitle => 'Filter Documents';

  @override
  String get category => 'Category';

  @override
  String get allCategories => 'All Categories';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get notApplicable => 'Not Applicable';

  @override
  String get searchLabel => 'Search';

  @override
  String get searchByDocType => 'Search by document type';

  @override
  String get unknownCategory => 'Unknown Category';

  @override
  String categoryWithName(String name) {
    return 'Category: $name';
  }

  @override
  String get previousVersion => 'Previous version';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get files => 'Files';

  @override
  String get signatures => 'Signatures';

  @override
  String get comments => 'Comments';

  @override
  String get rejectionComment => 'Rejection Comment:';

  @override
  String get photoDefaultName => 'Photo';

  @override
  String get trackerLoading => 'Loading audit data...';

  @override
  String get kpiApproval => 'Approval';

  @override
  String get kpiAllClear => 'All clear';

  @override
  String get kpiFixRequired => 'Fix required';

  @override
  String get kpiRejectedItems => 'Rejected Items';

  @override
  String get trackerNoApproved => 'No approved documents';

  @override
  String get trackerNoActionItems => 'No action items found';

  @override
  String get filterColon => 'Filter: ';

  @override
  String get trackerActionItems => 'Action Items';

  @override
  String get trackerApprovedCurrent => 'Approved & Current';

  @override
  String get unknown => 'Unknown';

  @override
  String percentOverall(String percent) {
    return '$percent% overall';
  }

  @override
  String get trackerNoApprovedCurrent =>
      'No approved documents that are current and not expiring soon';

  @override
  String get expiredCaps => 'EXPIRED';

  @override
  String get expiresSoonCaps => 'EXPIRES SOON';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get expiresToday => 'Expires today';

  @override
  String get docExpiredRenew =>
      'This document has expired and needs to be renewed';

  @override
  String get docExpiresSoonRenew =>
      'This document expires soon and may need renewal';

  @override
  String get commentsColon => 'Comments:';

  @override
  String get uploadNewVersion => 'Upload New Version';

  @override
  String get actionDelete => 'Delete';

  @override
  String get deleteDocTitle => 'Delete Document';

  @override
  String get deleteDocConfirm =>
      'Are you sure you want to delete this document?';

  @override
  String get deleteDocWarning =>
      'This action cannot be undone. The document and all its files will be permanently deleted.';

  @override
  String get deletingDoc => 'Deleting document...';

  @override
  String get docDeleted => 'Document deleted successfully';

  @override
  String get docDeleteFailed => 'Failed to delete document';

  @override
  String docDeleteError(String error) {
    return 'Error deleting document: $error';
  }

  @override
  String expiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String get noExpiryDate => 'No Expiry Date';

  @override
  String get docTypesNoneInCategory =>
      'No document types found for this category';

  @override
  String docsUploadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents uploaded',
      one: '1 document uploaded',
    );
    return '$_temp0';
  }

  @override
  String get viewDocuments => 'View Documents';

  @override
  String get specNoneShort => 'No specification';

  @override
  String uploadedOn(String date) {
    return 'Uploaded: $date';
  }

  @override
  String get addAnotherDocument => 'Add Another Document';

  @override
  String get addAnotherForm => 'Add Another Form';

  @override
  String get actionFillForm => 'Fill Form';

  @override
  String get actionAddMore => 'Add More';

  @override
  String get actionAddForm => 'Add Form';

  @override
  String get actionUpdateForm => 'Update Form';

  @override
  String get statusNotUploaded => 'Not Uploaded';

  @override
  String get ruleRequiresExpiry => 'Requires expiry date';

  @override
  String get ruleRequiresSignature => 'Requires signature';

  @override
  String get ruleCanBeNa => 'Can be marked N/A';

  @override
  String get catNoDocsAvailable => 'No documents available';

  @override
  String catCompletedStatus(int done, int total, String percent) {
    return 'Completed: $done / $total ($percent%)';
  }

  @override
  String get catProgress => 'Category Progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get viewDocument => 'View Document';

  @override
  String get markNotApplicable => 'Mark as Not Applicable';

  @override
  String get rejectionReason => 'Rejection Reason:';

  @override
  String ruleRequiresSignatures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Requires $count signatures',
      one: 'Requires 1 signature',
    );
    return '$_temp0';
  }

  @override
  String get reviewedPolicyHelp => 'Date this policy was last reviewed';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String uploadSelectFilesError(String error) {
    return 'Error selecting files: $error';
  }

  @override
  String get uploadSelectFilesFirst => 'Please select files to upload';

  @override
  String get uploadSelectExpiryAll =>
      'Please select an expiry date for all documents';

  @override
  String get uploadNeedSpecPlease =>
      'Please add a specification — what does this upload cover?';

  @override
  String get uploadNeedReviewedPlease =>
      'Please enter the date this was last reviewed';

  @override
  String get uploadNoContext => 'Error: No user or company context';

  @override
  String uploadedFileOk(String name) {
    return 'Successfully uploaded: $name';
  }

  @override
  String uploadedFileFailed(String name) {
    return 'Failed to upload: $name';
  }

  @override
  String uploadedFileError(String name) {
    return 'Error uploading: $name';
  }

  @override
  String get uploadAllOk => 'All documents uploaded successfully!';

  @override
  String uploadSomeFailed(int ok, int failed) {
    return '$ok uploaded, $failed failed';
  }

  @override
  String get uploadAllFailed => 'All uploads failed';

  @override
  String uploadDocsError(String error) {
    return 'Error uploading documents: $error';
  }

  @override
  String get uploadCardSubtitleExpiry =>
      'Upload documents and set expiry dates for each';

  @override
  String get uploadCardSubtitle => 'Upload documents for this category';

  @override
  String get uploadSpecHintLong =>
      'What does this cover? e.g. site, period, worker group';

  @override
  String get uploadSpecHintOptional =>
      'Enter document specification (optional)';

  @override
  String get uploadChooseReviewDate => 'Choose the review date';

  @override
  String get uploadTapToSelect => 'Tap to select files';

  @override
  String get uploadSupportedFormats =>
      'Supported formats: PDF, JPG, JPEG, PNG, DOC, DOCX';

  @override
  String uploadSelectedDocsTitle(int count) {
    return 'Selected Documents ($count)';
  }

  @override
  String get actionSetDate => 'Set Date';

  @override
  String get uploadingDocs => 'Uploading Documents...';

  @override
  String get uploadingDoc => 'Uploading Document...';

  @override
  String uploadNDocs(int count) {
    return 'Upload $count Documents';
  }

  @override
  String get uploadOneDoc => 'Upload Document';

  @override
  String get uploadSelectAndUpload => 'Select and Upload Documents';

  @override
  String get docDetailsTitle => 'Document Details';

  @override
  String get docLoading => 'Loading document...';

  @override
  String docLoadError(String error) {
    return 'Error loading document: $error';
  }

  @override
  String get docNotAvailable => 'This document is not available.';

  @override
  String get docNotFound => 'Document not found';

  @override
  String get bannerExpired => 'DOCUMENT EXPIRED';

  @override
  String get bannerExpiredSub =>
      'This document has expired and needs to be updated';

  @override
  String get bannerRejected => 'DOCUMENT REJECTED';

  @override
  String get bannerRejectedSub => 'Please review the feedback and resubmit';

  @override
  String get bannerPending => 'PENDING REVIEW';

  @override
  String get bannerAwaitingYou => 'Awaiting your review';

  @override
  String get bannerAwaitingAdmin => 'Awaiting admin review';

  @override
  String bannerValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get bannerApproved => 'Document is approved';

  @override
  String get bannerApprovedCaps => 'APPROVED';

  @override
  String get bannerUnknown => 'UNKNOWN STATUS';

  @override
  String get docInformation => 'Document Information';

  @override
  String get created => 'Created';

  @override
  String get actions => 'Actions';

  @override
  String get resubmitDocCaps => 'RESUBMIT DOCUMENT';

  @override
  String get uploadNewVersionCaps => 'UPLOAD NEW VERSION';

  @override
  String addSignatureCaps(int done, int total) {
    return 'ADD SIGNATURE ($done/$total)';
  }

  @override
  String docFilesCount(int count) {
    return 'Document Files ($count)';
  }

  @override
  String get noFilesUploaded => 'No files uploaded';

  @override
  String commentsHistoryCount(int count) {
    return 'Comments & History ($count)';
  }

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get adminReview => 'Admin Review';

  @override
  String get editSpecHint => 'Edit document specification (optional)...';

  @override
  String get strayExpiryNote =>
      'This document type does not use an expiry date. Clear it so the document never shows as expired.';

  @override
  String get selectExpiryOptional => 'Select expiry date (optional)';

  @override
  String get comment => 'Comment';

  @override
  String get commentHintReject => 'Add a comment (required for rejection)...';

  @override
  String get reviewSaveNote =>
      'Changes to specification and expiry date will be saved when you approve or reject.';

  @override
  String get selectExpiryDate => 'Select Expiry Date';

  @override
  String get actionSelect => 'Select';

  @override
  String get addYourSignature => 'Add Your Signature';

  @override
  String get signatureAdded => 'Signature added successfully';

  @override
  String get rejectReasonRequired => 'Please provide a reason for rejection';

  @override
  String get docApprovedOk => 'Document approved';

  @override
  String get docRejectedOk => 'Document rejected';

  @override
  String get docTypeLoading => 'Loading document type...';

  @override
  String get docTypeNotFound => 'Document type not found';

  @override
  String get selectExpiryPlease => 'Please select an expiry date';

  @override
  String get docCreated => 'Document created successfully';

  @override
  String formSubmitError(String error) {
    return 'Error submitting form: $error';
  }

  @override
  String get fillDocForm => 'Fill Document Form';

  @override
  String fillTypeName(String type) {
    return 'Fill $type';
  }

  @override
  String get selectExpiryDateLower => 'Select expiry date';

  @override
  String get submitForm => 'Submit Form';

  @override
  String get reportLoading => 'Loading compliance data...';

  @override
  String get reportComplete => 'Complete';

  @override
  String updatedOn(String date) {
    return 'Updated: $date';
  }

  @override
  String notifUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get notifAllCaughtUp => 'All caught up';

  @override
  String get notifMarkAllRead => 'Mark all read';

  @override
  String get notifNoneYet => 'No notifications yet';

  @override
  String get notifEmptyHint =>
      'You’ll be notified about rejections and expiring documents.';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get farmsLoadFailed => 'Could not load your farms.';

  @override
  String get farmOpenFailed => 'Could not open this farm. Please try again.';

  @override
  String farmsAuditorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can review approved documents for $count farms.',
      one: 'You can review approved documents for 1 farm.',
    );
    return '$_temp0';
  }

  @override
  String get farmsSearchHint => 'Search farms...';

  @override
  String get farmsNoneFound => 'No farms found';

  @override
  String get farmCurrent => 'Current';

  @override
  String get docFilesTitle => 'Document Files';

  @override
  String get imagePreview => 'Image Preview';

  @override
  String get openingInBrowser => 'Opening in browser...';

  @override
  String fileViewError(String error) {
    return 'Error viewing file: $error';
  }

  @override
  String urlOpenError(String error) {
    return 'Error opening URL: $error';
  }

  @override
  String get actionSave => 'Save';

  @override
  String get signFirst => 'Please sign before saving';

  @override
  String signatureSaveError(String error) {
    return 'Error saving signature: $error';
  }

  @override
  String get psEnterHoursFirst =>
      'Enter hours for at least one employee first.';

  @override
  String get psSaveFailedShort => 'Save failed';

  @override
  String psSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payslips saved',
      one: '1 payslip saved',
    );
    return '$_temp0';
  }

  @override
  String psSavedSomeFailed(int ok, int failed) {
    return '$ok saved, $failed failed';
  }

  @override
  String get psFamilyLeaveNeedsStart =>
      'Family leave starts once an employment start date is set — add it via Edit employee if it should apply.';

  @override
  String get psDeleteTitle => 'Delete Payslip';

  @override
  String psNetAmount(String amount) {
    return 'Net: $amount';
  }

  @override
  String get cannotUndo => 'This cannot be undone.';

  @override
  String get employeeAdded => 'Employee added';

  @override
  String get employeeUpdated => 'Employee updated';

  @override
  String get couldNotSave => 'Could not save';

  @override
  String get employeeRemoveTitle => 'Remove Employee';

  @override
  String employeeRemoveBody(String name) {
    return 'Remove $name? Their payslips are kept. If you add them again later, use the same ID number so old payslips link back to them (e.g. for bank payments).';
  }

  @override
  String get actionRemove => 'Remove';

  @override
  String get companyFallback => 'Company';

  @override
  String psAllPdfName(String company) {
    return '$company Payslips.pdf';
  }

  @override
  String get payeTax => 'PAYE (Tax)';

  @override
  String get freqWeekly => 'weekly';

  @override
  String get freqFortnightly => 'fortnightly';

  @override
  String get freqMonthly => 'monthly';

  @override
  String payeAutoAmount(String freq, String amount) {
    return 'Auto ($freq): $amount';
  }

  @override
  String get payeAmountLabel => 'PAYE amount (R)';

  @override
  String get payeBlankAuto => 'Leave blank to use auto';

  @override
  String get payeUseAuto => 'Use auto';

  @override
  String get payeManualNote => 'Manual PAYE — this exact amount will be used.';

  @override
  String payeAutoNote(String freq) {
    return 'Auto PAYE is calculated on the taxable gross for this $freq period.';
  }

  @override
  String get additionalDeductions => 'Additional Deductions';

  @override
  String get noDeductionsYet => 'No deductions yet';

  @override
  String get fieldReason => 'Reason';

  @override
  String get fieldAmountR => 'Amount (R)';

  @override
  String totalAmount(String amount) {
    return 'Total: $amount';
  }

  @override
  String get addDeduction => 'Add Deduction';

  @override
  String get actionDone => 'Done';

  @override
  String get additionalIncome => 'Additional Income';

  @override
  String get noAdditionsYet => 'No additions yet';

  @override
  String get fieldDescription => 'Description';

  @override
  String get addIncome => 'Add Income';

  @override
  String get uifSummary => 'UIF Summary';

  @override
  String get noPayslipsForPeriod => 'No payslips for this period.';

  @override
  String pdfError(String error) {
    return 'PDF error: $error';
  }

  @override
  String get downloadUifPdf => 'Download UIF Summary PDF';

  @override
  String get colEmployee => 'Employee';

  @override
  String get colEarnings => 'Earnings';

  @override
  String get colTotalDed => 'Total Ded';

  @override
  String get companyColon => 'Company:';

  @override
  String get selectCompany => 'Select a company';

  @override
  String get defaultStart => 'Default Start';

  @override
  String get defaultEnd => 'Default End';

  @override
  String get fillsAllRows => 'fills all rows';

  @override
  String get payDate => 'Pay Date';

  @override
  String get companyAddressOnPayslip => 'Company Address (on payslip)';

  @override
  String get companyAddress => 'Company Address';

  @override
  String get tapToSet => 'Tap to set';

  @override
  String get employerUifRegNr => 'Employer UIF Reg Nr';

  @override
  String get saving => 'Saving…';

  @override
  String saveChangesCount(int count) {
    return 'Save Changes ($count)';
  }

  @override
  String saveAllCount(int count) {
    return 'Save All ($count)';
  }

  @override
  String savePayslipsCount(int count) {
    return 'Save Payslips ($count)';
  }

  @override
  String get savePayslips => 'Save Payslips';

  @override
  String get timesheet => 'Timesheet';

  @override
  String get leaveRecords => 'Leave Records';

  @override
  String get payslipRecords => 'Payslip Records';

  @override
  String get actionDownload => 'Download';

  @override
  String get noEmployeesFound => 'No employees found';

  @override
  String get colIdNumber => 'ID Number';

  @override
  String get colNetPay => 'Net Pay';

  @override
  String get colPayslipPeriod => 'Payslip Period';

  @override
  String get employeePermanent => 'Permanent employee';

  @override
  String get employeeSeasonal => 'Seasonal worker';

  @override
  String get bankingOnFile => 'Banking details on file — included in Bank CSV';

  @override
  String bankingIncomplete(String issues) {
    return 'Banking details incomplete ($issues) — not included in Bank CSV';
  }

  @override
  String get editEmployeeDetails => 'Edit employee details';

  @override
  String get removeEmployee => 'Remove employee';

  @override
  String get editThisPayslip => 'Edit this payslip';

  @override
  String get cancelEdit => 'Cancel edit';

  @override
  String get addIncomeLower => 'Add income';

  @override
  String additionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count additions',
      one: '1 addition',
    );
    return '$_temp0';
  }

  @override
  String get noAdditionsEditToAdd => 'No additions (edit to add)';

  @override
  String additionsEditToChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count additions (edit to change)',
      one: '1 addition (edit to change)',
    );
    return '$_temp0';
  }

  @override
  String get addDeductionsLower => 'Add deductions';

  @override
  String deductionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deductions',
      one: '1 deduction',
    );
    return '$_temp0';
  }

  @override
  String get noDeductionsEditToAdd => 'No deductions (edit to add)';

  @override
  String deductionsEditToChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deductions (edit to change)',
      one: '1 deduction (edit to change)',
    );
    return '$_temp0';
  }

  @override
  String get deletePayslip => 'Delete payslip';

  @override
  String get finishEditingFirst => 'Finish editing first';

  @override
  String get newPayslip => 'New Payslip';

  @override
  String get searchEmployees => 'Search employees…';

  @override
  String showingRange(int from, int to, int total) {
    return 'Showing $from–$to of $total';
  }

  @override
  String get failedToLoadData => 'Failed to load data';

  @override
  String get selectCompanyForPayslips => 'Select a company to manage payslips';

  @override
  String get addFirstEmployee => 'Add First Employee';

  @override
  String tsLinePhWorkedNormal(
      String date, String hours, String daily, String rate) {
    return 'Public holiday worked ($date, $hours h): greater of 2 × daily wage or daily wage $daily + $hours h × $rate';
  }

  @override
  String tsLinePhWorkedOff(
      String date, String hours, String daily, String rate) {
    return 'Public holiday worked ($date, $hours h): daily wage $daily + $hours h × $rate';
  }

  @override
  String tsLineSundayMin(int count, Object daily) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sunday minimum pay ($count days: at least the daily wage $daily)',
      one: 'Sunday minimum pay (1 day: at least the daily wage $daily)',
    );
    return '$_temp0';
  }

  @override
  String tsLineNight(int count, Object perDay) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Night-shift allowance ($count days × $perDay)',
      one: 'Night-shift allowance (1 day × $perDay)',
    );
    return '$_temp0';
  }

  @override
  String tsLinePiece(String units, String unit, String rate, String task) {
    return 'Piecework: $units $unit × $rate ($task)';
  }

  @override
  String tsLineTopUpDays(int count, Object wage) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Minimum wage top-up ($count days below $wage/h)',
      one: 'Minimum wage top-up (1 day below $wage/h)',
    );
    return '$_temp0';
  }

  @override
  String tsLineTopUpWeeks(int count, Object wage) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Minimum wage top-up ($count weeks below $wage/h)',
      one: 'Minimum wage top-up (1 week below $wage/h)',
    );
    return '$_temp0';
  }

  @override
  String tsWarnDay(String hours, String date, String limit) {
    return '$hours h on $date (over $limit h a day)';
  }

  @override
  String tsWarnWeek(String hours, String week, String limit) {
    return '$hours h overtime in week of $week (over $limit h)';
  }

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get periodFortnightly => 'Fortnightly';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get leaveSick => 'sick leave';

  @override
  String get leaveAnnual => 'annual (holiday) leave';

  @override
  String get leaveFamily => 'family responsibility leave';

  @override
  String tsLoadPeriodFailed(String error) {
    return 'Could not load that period: $error';
  }

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get tsUnsavedBody =>
      'You have changes on this timesheet that are not saved yet.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String tsFixRedCells(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Fix the $count red cells first (hours like 9 or 7.5, codes SL / AL / PH / A, finish times like 21:30).',
      one:
          'Fix the red cell first (hours like 9 or 7.5, codes SL / AL / PH / A, finish times like 21:30).',
    );
    return '$_temp0';
  }

  @override
  String tsSavedUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved · $count payslips updated',
      one: 'Saved · 1 payslip updated',
    );
    return '$_temp0';
  }

  @override
  String tsSavedSkipped(int skipped) {
    return '$skipped waiting for rates (see the banner)';
  }

  @override
  String saveFailedError(String error) {
    return 'Save failed: $error';
  }

  @override
  String get tsFinaliseTitle => 'Finalise period?';

  @override
  String tsFinaliseBody(String start, String end) {
    return 'This saves the timesheet, locks all three sheets for $start – $end and finalises the payslips. You can unlock it again if something needs fixing.';
  }

  @override
  String get tsFinalisePeriod => 'Finalise period';

  @override
  String get tsUnlockTitle => 'Unlock this period?';

  @override
  String get tsUnlockBody =>
      'The sheets become editable again and the payslips go back to Draft until you finalise again. This is recorded in the audit log.';

  @override
  String get actionUnlock => 'Unlock';

  @override
  String get tsFinalisedToast =>
      'Period finalised — sheets locked, payslips finalised';

  @override
  String get tsUnlockedToast => 'Period unlocked — payslips are Draft again';

  @override
  String tsPeriodUpdateFailed(String error) {
    return 'Could not update the period: $error';
  }

  @override
  String get tsNeedRatesTitle => 'Some payslips need rates first';

  @override
  String tsNeedRatesBody(int count, Object missing, Object names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payslips ($names) can’t be calculated until these are set: $missing.',
      one:
          '1 payslip ($names) can’t be calculated until these are set: $missing.',
    );
    return '$_temp0';
  }

  @override
  String get later => 'Later';

  @override
  String get setThemNow => 'Set them now';

  @override
  String get tsRatesSaved => 'Rates saved — press Save to update the payslips';

  @override
  String tsRatesSaveFailed(String error) {
    return 'Could not save rates: $error';
  }

  @override
  String tsPieceRateAddFailed(String error) {
    return 'Could not add the piece rate: $error';
  }

  @override
  String tsPayPeriodTitle(String type) {
    return '$type pay period';
  }

  @override
  String get tsChooseStartDate => 'Choose a start date…';

  @override
  String get tsFirstDayHelp => 'First day of the pay period';

  @override
  String tsTitle(String company) {
    return 'Timesheet – $company';
  }

  @override
  String get tsRates => 'Rates';

  @override
  String get tsLoadFailed => 'The timesheet could not be loaded.';

  @override
  String get tsNormalHours => 'Normal hours';

  @override
  String get tsOvertime => 'Overtime';

  @override
  String get tsPiecework => 'Piecework';

  @override
  String get tsPayPeriod => 'Pay period';

  @override
  String tsDaysWorkers(int days, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workers',
      one: '1 worker',
    );
    return '$days days · $_temp0';
  }

  @override
  String get tsNsLegend => 'NS = night work (finish after 20:00, before 04:00)';

  @override
  String get tsFinalised => 'Finalised';

  @override
  String tsFinalisedBy(String name) {
    return 'Finalised by $name';
  }

  @override
  String get tsPieceRate => 'Piece rate';

  @override
  String get chooseEllipsis => 'Choose…';

  @override
  String get tsAddPieceRateMenu => '+ Add piece rate…';

  @override
  String tsNotUpdatedBanner(int count, Object missing) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payslips not updated yet — set: $missing.',
      one: '1 payslip not updated yet — set: $missing.',
    );
    return '$_temp0';
  }

  @override
  String get colHours => 'Hours';

  @override
  String get colLeave => 'Leave';

  @override
  String get colComment => 'Comment';

  @override
  String get colOtHours => 'OT hours';

  @override
  String get colNsDays => 'NS days';

  @override
  String get colUnits => 'Units';

  @override
  String get colPiecePay => 'Piece pay';

  @override
  String get colTopUp => 'Top-up';

  @override
  String get tsNoEmployees => 'No employees yet.';

  @override
  String get tsAddEmployeesHint => 'Add employees in the Payslip Manager';

  @override
  String get colWorker => 'Worker';

  @override
  String get tsPhTooltip =>
      'Public holiday. Not worked: type PH (paid one daily wage). Worked: type the hours — paid per SD13 (greater of 2 × daily wage or daily wage + hours, on a normal work day).';

  @override
  String get tsSundayTooltip =>
      'Sunday: hours worked are paid at double the ordinary wage, and at least the daily wage (SD13).';

  @override
  String get tsBelowMinTooltip =>
      'Piece pay is below the minimum wage — a top-up is added to the payslip.';

  @override
  String get tsOk => 'OK';

  @override
  String get viewPayslip => 'View payslip';

  @override
  String get viewDraft => 'View draft';

  @override
  String tsSummaryNormal(int count, Object hours) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Normal hours · All workers · Hours $hours · Leave / absent $count days',
      one: 'Normal hours · All workers · Hours $hours · Leave / absent 1 day',
    );
    return '$_temp0';
  }

  @override
  String tsSummaryOvertime(String hours, int ns) {
    return 'Overtime · All workers · OT hours $hours · Night-shift days $ns';
  }

  @override
  String tsSummaryPiece(String units) {
    return 'Piecework · All workers · Units $units';
  }

  @override
  String get tsChoosePieceRateSuffix => ' · choose a piece rate';

  @override
  String get tsHelpNormal =>
      'Type the hours worked (9, 7.5…) in each day. Leave goes in with the leave codes above the grid. Overtime and piecework go on their own sheets.';

  @override
  String get tsHelpOvertime =>
      'Each day: overtime hours + finish time. NS is marked automatically when the finish time is after 20:00 or before 04:00 (SD13 cl 17) and adds a night-shift allowance line to the payslip.';

  @override
  String get tsHelpPiece =>
      'Each day: hours worked + units. Piece pay = units × the piece rate. Top-up is flagged when piece pay is below the minimum wage for the hours worked.';

  @override
  String get tsRatesTitle => 'Timesheet rates';

  @override
  String get tsRatesConfirmedNote =>
      'Confirmed figures: overtime 1.5×, night-shift 10% of the daily wage per night-shift day, minimum wage R30.23 (check each March). Sundays and public holidays are paid per SD13 automatically. Leave a field blank and the payslips that need it show “R —” until it’s set.';

  @override
  String get tsFillConfirmed => 'Fill in the confirmed figures';

  @override
  String get tsOtMultiplier => 'Overtime multiplier';

  @override
  String get tsOtMultiplierHelp => 'SD13 cl 14: at least 1.5 × the wage.';

  @override
  String get tsNightAllowance =>
      'Night-shift allowance (% of ordinary daily wage)';

  @override
  String get tsNightAllowanceHelp =>
      'SD13 cl 17: at least 10%, per day with night work.';

  @override
  String get tsMinWage => 'Minimum wage per ordinary hour (R)';

  @override
  String get tsMinWageHelp =>
      'Farm-worker NMW from 1 March 2026: R30.23 — check the current gazette.';

  @override
  String get tsDayHours => 'Ordinary hours per day';

  @override
  String get tsDayHoursHelp =>
      'Used for leave days (SL / AL / PH) and the daily wage.';

  @override
  String get tsWarnWeekLabel => 'Warn above overtime hours per week';

  @override
  String get tsWarnWeekHelp =>
      'SD13 cl 13: max 15 h overtime a week (warning only).';

  @override
  String get tsWarnDayLabel => 'Warn above total hours per day';

  @override
  String get tsWarnDayHelp =>
      'SD13 cl 13: max 12 h a day including overtime (warning only).';

  @override
  String get tsTopUpTitle => 'Minimum-wage top-up for piecework';

  @override
  String get tsTopUpHelp =>
      'Checked per day or per week, depending on this farm. Workers below the minimum are shown in red.';

  @override
  String get perDay => 'Per day';

  @override
  String get perWeek => 'Per week';

  @override
  String get tsWorkDaysTitle => 'Normal work days';

  @override
  String get tsWorkDaysHelp =>
      'Decides how a worked public holiday is paid: on a normal work day the greater of 2 × daily wage or daily wage + hours; otherwise daily wage + hours.';

  @override
  String get tsSaveRates => 'Save rates';

  @override
  String get tsAddPieceRate => 'Add piece rate';

  @override
  String get tsTaskOrCrop => 'Task or crop';

  @override
  String get tsTaskHint => 'e.g. Harvest';

  @override
  String get tsTaskRequired => 'Enter the task or crop';

  @override
  String get tsUnit => 'Unit';

  @override
  String get tsUnitHint => 'bins, crates, …';

  @override
  String get tsUnitDefault => 'bins';

  @override
  String get tsUnitRequired => 'Enter the unit';

  @override
  String get tsRatePerUnit => 'Rate per unit (R)';

  @override
  String get tsRatePerUnitHelp =>
      'From your configured tariff — not an example figure.';

  @override
  String get tsRateRequired => 'Enter the rate per unit';

  @override
  String get actionAdd => 'Add';

  @override
  String get missOvertime => 'overtime multiplier';

  @override
  String get missNight => 'night-shift allowance %';

  @override
  String get missPieceRate => 'piece rate';

  @override
  String get missMinWage => 'minimum hourly wage';

  @override
  String get missTopUp => 'top-up per day or per week';

  @override
  String get missWorkDays => 'normal work days';

  @override
  String leaveRecordsTitle(String company) {
    return 'Leave Records – $company';
  }

  @override
  String get noEmployeesFoundDot => 'No employees found.';

  @override
  String get leaveCodeHL => 'HL';

  @override
  String get leaveCodeSL => 'SL';

  @override
  String get leaveCodeFL => 'FL';

  @override
  String get leaveHoliday => 'Holiday Leave';

  @override
  String get leaveHolidayRule => '1 hr per 17 hrs worked';

  @override
  String get leaveSickTitle => 'Sick Leave';

  @override
  String get leaveSickRule => '1 hr per 26 hrs (pre-6mo) / 30 days per 3 yrs';

  @override
  String get leaveFamilyTitle => 'Family Resp. Leave';

  @override
  String get leaveFamilyRule => '3 days/yr after 4 months (needs start date)';

  @override
  String get leaveReportPdf => 'Leave Report (PDF)';

  @override
  String employedSince(String date) {
    return 'Employed $date';
  }

  @override
  String get setOpeningLeave => 'Set opening leave';

  @override
  String get hoursWorkedInSystem => 'Hours worked in system: ';

  @override
  String hoursAmount(String hours) {
    return '$hours hrs';
  }

  @override
  String get accrualNote =>
      '(drives new accrual; opening balances set separately)';

  @override
  String get allocated30Day => 'Allocated (30-day batches)';

  @override
  String get accrued126 => 'Accrued (1/26 hrs)';

  @override
  String get entitlement3Days => 'Entitlement (3 days/yr)';

  @override
  String get setStartDateToEnable => 'Set employment start date to enable';

  @override
  String get eligibleAfter4Months => 'Eligible after 4 months employment';

  @override
  String get openingPreSystem => 'Opening (pre-system)';

  @override
  String get accrued => 'Accrued';

  @override
  String get taken => 'Taken';

  @override
  String get balance => 'Balance';

  @override
  String get balanceHoursHelp => 'Balance in hours (8 hrs = 1 day)';

  @override
  String get openingLeaveTitle => 'Leave Accumulated Before Using the System';

  @override
  String openingLeaveBody(String name) {
    return 'For $name — enter the leave this employee had already banked BEFORE you started using the app. This is the opening balance; the system adds new accrual on top and subtracts leave taken. Enter each type separately — holiday and sick leave are not the same.';
  }

  @override
  String get openingHL => 'Holiday Leave (HL) opening';

  @override
  String get openingSL => 'Sick Leave (SL) opening';

  @override
  String get openingFL => 'Family Resp. Leave (FL) opening';

  @override
  String sickAllocationTitle(String name) {
    return 'Sick Leave Allocation – $name';
  }

  @override
  String get sickPost6Months =>
      'Employee has passed 6 months — grant 30-day batches';

  @override
  String get sickPre6Months =>
      'Pre-6 months: auto-accrues 1 hr per 26 hrs worked';

  @override
  String get previousAllocations => 'Previous allocations';

  @override
  String hoursOnDate(String hours, String date) {
    return '$hours hrs on $date';
  }

  @override
  String get sickAutoNote =>
      'Sick leave is auto-calculated at 1 hour per 26 hours worked. No manual allocation needed until 6 months of employment.';

  @override
  String get grantSickBatch => 'Grant new 30-day sick leave batch';

  @override
  String get hours240Hint => '240 (= 30 days × 8 hrs)';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get grantSickLeave => 'Grant Sick Leave';

  @override
  String familyAllocateBody(String name) {
    return '$name — allocate annual family responsibility leave. SA law provides 3 days per year for employees employed > 4 months.';
  }

  @override
  String get hoursAllocated => 'Hours allocated';

  @override
  String get hours24Hint => '24 (= 3 days × 8 hrs)';

  @override
  String get hours24Help => 'Typically 24 hrs (3 working days at 8 hrs/day)';

  @override
  String get actionAllocate => 'Allocate';

  @override
  String actionFailed(String action, String error) {
    return '$action failed: $error';
  }

  @override
  String get deletePayslipsTitle => 'Delete Payslips';

  @override
  String deletePayslipsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Permanently delete $count payslips? This cannot be undone.',
      one: 'Permanently delete 1 payslip? This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String deleteCount(int count) {
    return 'Delete $count';
  }

  @override
  String payslipsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payslips deleted',
      one: '1 payslip deleted',
    );
    return '$_temp0';
  }

  @override
  String get bankFile => 'Bank file';

  @override
  String payslipRecordsTitle(String company) {
    return 'Payslip Records – $company';
  }

  @override
  String get presetThisWeek => 'This week';

  @override
  String get presetLastWeek => 'Last week';

  @override
  String get presetThisMonth => 'This month';

  @override
  String get presetLastMonth => 'Last month';

  @override
  String get dateFrom => 'From';

  @override
  String get dateTo => 'To';

  @override
  String get any => 'Any';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String payslipsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payslips',
      one: '1 payslip',
    );
    return '$_temp0';
  }

  @override
  String get bankCsv => 'Bank CSV';

  @override
  String get noPayslipsInRange => 'No payslips in this date range.';

  @override
  String get payslipWord => 'Payslip';

  @override
  String get payslipNotFound => 'Payslip not found';

  @override
  String get printSavePdf => 'Print / Save PDF';

  @override
  String deletePayslipFor(String name) {
    return 'Delete this payslip for $name?';
  }

  @override
  String get psPersonalDetails => 'PERSONAL DETAILS';

  @override
  String get psPeriodStart => 'Period Start';

  @override
  String get psPeriodEnd => 'Period End';

  @override
  String get psHourlyRate => 'Hourly Rate';

  @override
  String get psOvertimeRate => 'Overtime Rate';

  @override
  String get psDoubleTimeRate => 'Double Time Rate';

  @override
  String get psNormalPay => 'Normal Pay';

  @override
  String get psOvertimePay => 'Overtime Pay';

  @override
  String get psDoubleTime => 'Double Time';

  @override
  String get psPublicHoliday => 'Public Holiday';

  @override
  String get psSickLeaveCoded => 'Sick Leave (SL)';

  @override
  String get psHolidayLeaveCoded => 'Annual Leave (HL)';

  @override
  String get psFamilyLeaveCoded => 'Family Leave (FL)';

  @override
  String get psOtherDetails => 'OTHER DETAILS';

  @override
  String get psUifRegNr => 'UIF Reg No';

  @override
  String get psNetSalaryCaps => 'NET SALARY';

  @override
  String pdfGenerateFailed(String error) {
    return 'Could not generate PDF: $error';
  }

  @override
  String get payslipFinalised => 'This payslip has been finalised';

  @override
  String get payslipIsDraft => 'This payslip is a draft';

  @override
  String get selectEmployeePlease => 'Please select an employee';

  @override
  String get finalisePayslipTitle => 'Finalise Payslip';

  @override
  String get finalisePayslipBody =>
      'Once finalised this payslip cannot be edited. Continue?';

  @override
  String get actionFinalise => 'Finalise';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String get viewPayslipTitle => 'View Payslip';

  @override
  String get editPayslipTitle => 'Edit Payslip';

  @override
  String get employeePayPeriod => 'Employee & Pay Period';

  @override
  String get hourlyRates => 'Hourly Rates';

  @override
  String get normalRateR => 'Normal Rate (R)';

  @override
  String get overtimeRateR => 'Overtime Rate (R)';

  @override
  String get doubleRateR => 'Double Rate (R)';

  @override
  String get normalHoursLabel => 'Normal Hours';

  @override
  String get overtimeHoursLabel => 'Overtime Hours';

  @override
  String get doubleTimeHoursLabel => 'Double Time Hours';

  @override
  String get publicHolidayHoursLabel => 'Public Holiday Hours';

  @override
  String get earningsSummary => 'Earnings Summary';

  @override
  String get normalPayLabel => 'Normal Pay';

  @override
  String get overtimePayLabel => 'Overtime Pay';

  @override
  String get doubleTimePayLabel => 'Double Time Pay';

  @override
  String get publicHolidayPayLabel => 'Public Holiday Pay';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String get deductionsTitle => 'Deductions';

  @override
  String get uifOnePercent => 'UIF (1% of earnings)';

  @override
  String get compulsory => 'Compulsory';

  @override
  String get totalDeductions => 'Total Deductions';

  @override
  String get saveDraft => 'Save Draft';

  @override
  String get selectAnEmployee => 'Select an employee';

  @override
  String get noEmployeesAddFirst => 'No employees – add one first';

  @override
  String get selectEmployee => 'Select employee';

  @override
  String get required => 'Required';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get payslipFinalisedNoEdit =>
      'This payslip has been finalised and cannot be edited.';

  @override
  String get bulkEnterHours => 'Enter hours for at least one employee.';

  @override
  String bulkGeneratedOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payslips generated',
      one: '1 payslip generated',
    );
    return '$_temp0';
  }

  @override
  String bulkGeneratedSome(int ok, int failed) {
    return '$ok generated, $failed failed';
  }

  @override
  String get bulkTitle => 'Bulk Payslip Generator';

  @override
  String get generateAll => 'Generate All';

  @override
  String get addEmployeesFirst => 'Add employees in the Payslip Manager first.';

  @override
  String get backToManager => 'Back to Manager';

  @override
  String get colRateRHr => 'Rate (R/hr)';

  @override
  String get colNormalHrs => 'Normal\nhrs';

  @override
  String get colOvertimeHrs => 'Overtime\nhrs';

  @override
  String get colDoubleTime => 'Double\nTime';

  @override
  String get colPublicHol => 'Public\nHol';

  @override
  String get colEstNetPay => 'Est. Net Pay';

  @override
  String get shortfallTitle => 'Not enough leave left';

  @override
  String get shortfallOne =>
      'This employee doesn’t have enough leave left for what was entered. Choose what to do:';

  @override
  String get shortfallMany =>
      'These employees don’t have enough leave left for what was entered. Choose what to do for each:';

  @override
  String get applyToAll => 'Apply to all:';

  @override
  String get payAvailable => 'Pay available';

  @override
  String get takeOff => 'Take off';

  @override
  String get overridePay => 'Override & pay';

  @override
  String chooseForMore(int count) {
    return 'Choose an option for $count more';
  }

  @override
  String get backToEdit => 'Back to edit';

  @override
  String get applyAndSave => 'Apply & save';

  @override
  String shortfallLine(String requested, String type, String available) {
    return ' — $requested h $type entered, only $available h left';
  }

  @override
  String shortfallPayAvailableTitle(String hours) {
    return 'Pay only the $hours h available';
  }

  @override
  String shortfallPayAvailableSub(String hours) {
    return 'The other $hours h is left off the payslip (unpaid).';
  }

  @override
  String get shortfallTakeOffTitle => 'Take the leave off';

  @override
  String shortfallTakeOffSub(String code, String hours) {
    return 'No $code on this payslip — the $hours h is unpaid.';
  }

  @override
  String shortfallOverrideTitle(String hours) {
    return 'Override & pay all $hours h';
  }

  @override
  String shortfallOverrideSub(String code, String hours) {
    return 'Pays the full amount as $code; their $code balance goes $hours h below zero.';
  }

  @override
  String get bulkPaymentFile => 'Bulk Payment File';

  @override
  String get noPaymentsYet => 'No payments yet';

  @override
  String paymentsTotal(int count, Object total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments · total $total',
      one: '1 payment · total $total',
    );
    return '$_temp0';
  }

  @override
  String get bankUploadHelp =>
      'Upload the file to your online banking as a bulk payment, check the total, then approve once.';

  @override
  String get reference => 'Reference';

  @override
  String get refFirstNameAdded => 'Each employee’s first name is added';

  @override
  String refFirstNameExample(String sample) {
    return 'Each employee’s first name is added — e.g. “$sample”';
  }

  @override
  String combinedPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count employees have more than one payslip selected — their net pay is combined into one payment.',
      one:
          '1 employee has more than one payslip selected — their net pay is combined into one payment.',
    );
    return '$_temp0';
  }

  @override
  String get downloadFile => 'Download file';

  @override
  String get chooseYourBank => 'Choose your bank';

  @override
  String get bankFarmPaysFrom => 'Bank the farm pays from';

  @override
  String get nobodyPayable => 'Nobody can be paid yet — let’s fix that';

  @override
  String get eachFixSaves =>
      'Each fix saves straight away and this list updates as you go.';

  @override
  String addBankingForCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add banking details for $count employees',
      one: 'Add banking details for 1 employee',
    );
    return '$_temp0';
  }

  @override
  String fixUnlinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fix $count unlinked payslips',
      one: 'Fix 1 unlinked payslip',
    );
    return '$_temp0';
  }

  @override
  String reviewZeroCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review $count R 0 payslips',
      one: 'Review 1 R 0 payslip',
    );
    return '$_temp0';
  }

  @override
  String notIncludedCount(int count) {
    return 'Not included ($count)';
  }

  @override
  String addBankingForAll(int count) {
    return 'Add banking details for all $count';
  }

  @override
  String get addBankingDetails => 'Add banking details';

  @override
  String get fixBankingDetails => 'Fix banking details';

  @override
  String get linkToEmployee => 'Link to employee';

  @override
  String get editPayslip => 'Edit payslip';

  @override
  String relinkedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count payslips were linked to a removed employee record — matched to the current employee by ID number or name.',
      one:
          '1 payslip was linked to a removed employee record — matched to the current employee by ID number or name.',
    );
    return '$_temp0';
  }

  @override
  String get saveLinks => 'Save links';

  @override
  String draftsUndecided(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count selected payslips are still Draft — amounts may still change:',
      one: '1 selected payslip is still Draft — amounts may still change:',
    );
    return '$_temp0';
  }

  @override
  String draftsRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count draft payslips removed from this export:',
      one: '1 draft payslip removed from this export:',
    );
    return '$_temp0';
  }

  @override
  String draftsIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count draft payslips included as they are now:',
      one: '1 draft payslip included as it is now:',
    );
    return '$_temp0';
  }

  @override
  String removeDrafts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove drafts',
      one: 'Remove draft',
    );
    return '$_temp0';
  }

  @override
  String get includeAnyway => 'Include anyway';

  @override
  String get undo => 'Undo';

  @override
  String bankingDetailsFor(String name) {
    return 'Banking details — $name';
  }

  @override
  String get orphanPayslipBody =>
      'This payslip is linked to an employee record that no longer exists (the employee was probably removed). Link it to a current employee, or re-create the employee from the payslip.';

  @override
  String get skip => 'Skip';

  @override
  String get recreateEmployee => 'Re-create employee';

  @override
  String linkNameTo(String name) {
    return 'Link “$name” to…';
  }

  @override
  String get noIdNumber => 'No ID number';

  @override
  String get notListedRecreate => 'Not listed? Re-create the employee instead';

  @override
  String couldNotLink(String reason) {
    return 'Could not link: $reason';
  }

  @override
  String get employeeSavedLinkFailed =>
      'Employee saved, but linking payslips failed.';

  @override
  String get payslipLinksSaved => 'Payslip links saved';

  @override
  String get someLinksFailed => 'Some links could not be saved';

  @override
  String get completeHighlighted => 'Please complete the highlighted fields.';

  @override
  String get editEmployee => 'Edit Employee';

  @override
  String get employeeDetails => 'Employee details';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'e.g. John Smith';

  @override
  String get normalHourlyRateR => 'Normal Hourly Rate (R)';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get jobDescription => 'Job Description';

  @override
  String get jobDescriptionHint => 'e.g. Farm Worker, Tractor Driver';

  @override
  String get employmentStartOptional => 'Employment Start Date (optional)';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get employmentType => 'Employment Type';

  @override
  String get bankingDetails => 'Banking Details';

  @override
  String get bankingOnlyIfCsv =>
      'Only needed if you pay staff with the Bank CSV bulk-payment file. Leave blank otherwise.';

  @override
  String get bank => 'Bank';

  @override
  String get otherBank => 'Other bank…';

  @override
  String get bankName => 'Bank name';

  @override
  String get bankNameHint => 'e.g. Bidvest Bank';

  @override
  String get accountHolderLabel => 'Account holder (if not the employee)';

  @override
  String get accountHolderHint => 'Leave blank to use the employee’s name';

  @override
  String get accountNumber => 'Account Number';

  @override
  String get accountDigits => 'Digits only, 6–16 long';

  @override
  String get branchCode => 'Branch Code';

  @override
  String get branchCodeHint => 'Filled in automatically for major banks';

  @override
  String get accountType => 'Account Type';

  @override
  String leaveEligibility(int months) {
    return 'Leave eligibility ($months months employed):';
  }

  @override
  String get familyLeave3Days => 'Family Resp. Leave (3 days/yr)';

  @override
  String get months4Required => '4 months required';

  @override
  String get sickLeave30Days => 'Sick Leave (30 days/3 yr)';

  @override
  String get months6Required => '6 months required';

  @override
  String rateHelper(String overtime, String double) {
    return 'Overtime: R $overtime/hr  ·  Double: R $double/hr';
  }

  @override
  String get employmentPermanent => 'Permanent';

  @override
  String get employmentSeasonal => 'Seasonal';

  @override
  String get accountCurrent => 'Current / Cheque';

  @override
  String get accountSavings => 'Savings';

  @override
  String get accountTransmission => 'Transmission';

  @override
  String get bankIssueNone => 'no banking details';

  @override
  String get bankIssueNoAccount => 'no account number';

  @override
  String get bankIssueAccountDigits => 'account number must be 6–16 digits';

  @override
  String get bankIssueNoBranch => 'no branch code';

  @override
  String get bankIssueBranchDigits => 'branch code must be 6 digits';

  @override
  String get formUntitledField => 'Untitled Field';

  @override
  String formEnterField(String label) {
    return 'Enter $label';
  }

  @override
  String get formNoOptions => 'No options provided';

  @override
  String get formInvalidConfig => 'Invalid form configuration: missing fields';

  @override
  String formBuildError(String error) {
    return 'Error building form: $error';
  }

  @override
  String get formContractName => 'Contract Name';

  @override
  String get formContractNameHint => 'Enter the name of the contract';

  @override
  String get formContractNumber => 'Contract Number';

  @override
  String get formContractNumberHint => 'Enter the contract reference number';

  @override
  String get formCounterparty => 'Counterparty';

  @override
  String get formCounterpartyHint => 'Enter the name of the other party';

  @override
  String get formEffectiveDate => 'Effective Date';

  @override
  String get formContractStatus => 'Contract Status';

  @override
  String get formOptActive => 'Active';

  @override
  String get formOptPending => 'Pending';

  @override
  String get formOptTerminated => 'Terminated';

  @override
  String get formOptExpired => 'Expired';

  @override
  String get formContractDescHint => 'Enter a description of the contract';

  @override
  String get formCertName => 'Certification Name';

  @override
  String get formCertNameHint => 'Enter the name of the certification';

  @override
  String get formCertNumber => 'Certification Number';

  @override
  String get formCertNumberHint => 'Enter the certification reference number';

  @override
  String get formIssuingAuthority => 'Issuing Authority';

  @override
  String get formIssuingAuthorityHint =>
      'Enter the name of the issuing authority';

  @override
  String get formIssueDate => 'Issue Date';

  @override
  String get formHasRestrictions => 'Has Restrictions';

  @override
  String get formNotes => 'Notes';

  @override
  String get formNotesHint => 'Enter any additional notes';

  @override
  String get formInspectionLocation => 'Inspection Location';

  @override
  String get formInspectionLocationHint =>
      'Enter the location that was inspected';

  @override
  String get formInspectionDate => 'Inspection Date';

  @override
  String get formInspector => 'Inspector';

  @override
  String get formInspectorHint => 'Enter the name of the inspector';

  @override
  String get formInspectionResult => 'Inspection Result';

  @override
  String get formOptPass => 'Pass';

  @override
  String get formOptPassConditions => 'Pass with Conditions';

  @override
  String get formOptFail => 'Fail';

  @override
  String get formOptIncomplete => 'Incomplete';

  @override
  String get formFindings => 'Findings';

  @override
  String get formFindingsHint => 'Enter inspection findings';

  @override
  String get formRecommendations => 'Recommendations';

  @override
  String get formRecommendationsHint => 'Enter recommendations';

  @override
  String get formAssessmentTitle => 'Assessment Title';

  @override
  String get formAssessmentTitleHint =>
      'Enter the title of this risk assessment';

  @override
  String get formAssessmentDate => 'Assessment Date';

  @override
  String get formAssessor => 'Assessor';

  @override
  String get formAssessorHint => 'Enter the name of the assessor';

  @override
  String get formOverallRisk => 'Overall Risk Level';

  @override
  String get formOptLow => 'Low';

  @override
  String get formOptMedium => 'Medium';

  @override
  String get formOptHigh => 'High';

  @override
  String get formOptCritical => 'Critical';

  @override
  String get formHazards => 'Identified Hazards';

  @override
  String get formHazardsHint => 'List the identified hazards';

  @override
  String get formControlMeasures => 'Control Measures';

  @override
  String get formControlMeasuresHint => 'List the control measures';

  @override
  String get formRequiresFollowUp => 'Requires Follow-up';

  @override
  String get formTitle => 'Title';

  @override
  String get formTitleHint => 'Enter a title';

  @override
  String get formReferenceHint => 'Enter a reference number';

  @override
  String get formDocumentDate => 'Document Date';

  @override
  String get formSelectDate => 'Select a date';

  @override
  String get fmNoFarmLinked => 'No Farmable farm is linked to this company.';

  @override
  String get fmMapLoadFailed => 'Could not load farm map';

  @override
  String get fmCrop => 'Crop';

  @override
  String get fmVariety => 'Variety';

  @override
  String get fmFieldType => 'Field type';

  @override
  String get fmArea => 'Area';

  @override
  String fmHectares(String value) {
    return '$value ha';
  }

  @override
  String get fmSkyView => 'Farm Sky View';

  @override
  String fmCropsBlocks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Crops · $count blocks',
      one: 'Crops · 1 block',
    );
    return '$_temp0';
  }

  @override
  String get fmDataLoadFailed => 'Could not load farm data';

  @override
  String get fmFarmableLoadFailed => 'Could not load Farmable data';

  @override
  String get fmFarmData => 'Farm Data';

  @override
  String get fmFieldsCrops => 'Fields & Crops';

  @override
  String get fmRecentSales => 'Recent Harvests / Sales';

  @override
  String get fmNoSales => 'No sales records found.';

  @override
  String get fmViewRegister => 'View full farm register';

  @override
  String get fmNoCrops => 'No crops';

  @override
  String fmCropArea(String crops, String area) {
    return '$crops · $area ha';
  }

  @override
  String get fmUnassigned => 'Unassigned';

  @override
  String get fmNoMappedFields => 'No mapped fields';

  @override
  String get fmTotalArea => 'Total Cultivated Area';

  @override
  String get fmFields => 'Fields';

  @override
  String get fmCropTypes => 'Crop Types';

  @override
  String get fmPeople => 'People';

  @override
  String get unitBlocks => 'blocks';

  @override
  String get unitTypes => 'types';

  @override
  String get unitMembers => 'members';

  @override
  String get fmEquipmentInspection => 'Equipment Inspection';

  @override
  String get fmNoEquipment => 'No equipment';

  @override
  String get fmAllInspected => 'All inspected';

  @override
  String fmNeedInspection(int count) {
    return '$count need inspection';
  }

  @override
  String fmBlocksArea(int count, Object area) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocks · $area ha',
      one: '1 block · $area ha',
    );
    return '$_temp0';
  }

  @override
  String get fmCropDistribution => 'Crop Distribution';

  @override
  String get fmNoCropData => 'No crop data.';

  @override
  String get fmEquipment => 'Equipment';

  @override
  String fmToInspect(int count) {
    return '$count to inspect';
  }

  @override
  String get fmAllGood => 'All good';

  @override
  String get fmNoEquipmentRecord => 'No equipment on record.';

  @override
  String fmInspectedOn(String date) {
    return 'Inspected $date';
  }

  @override
  String get fmDue => 'Due';

  @override
  String get fmPeopleRoles => 'People & Roles';

  @override
  String get fmNoPeople => 'No people on record.';

  @override
  String get srTitle => 'Spray & Fertilizer Records';

  @override
  String get srAddRecord => 'Add Record';

  @override
  String srRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String srSyncedFarmable(String job) {
    return 'Synced to Farmable (Job #$job)';
  }

  @override
  String get srNoFields => 'No fields';

  @override
  String srPhiDays(int days) {
    return 'PHI: ${days}d';
  }

  @override
  String get srNoRecordsSpray => 'No spray application records yet';

  @override
  String get srNoRecordsFert => 'No fertilizer application records yet';

  @override
  String get srEmptyHint => 'Tap + Add Record to log your first application';

  @override
  String get srAdded => 'Record added';

  @override
  String get srUpdated => 'Record updated';

  @override
  String get srDeleted => 'Record deleted';

  @override
  String get srLogTitle => 'Log Application Record';

  @override
  String get srEditTitle => 'Edit Application Record';

  @override
  String get srDeleteTooltip => 'Delete record';

  @override
  String get srDeleteTitle => 'Delete Record';

  @override
  String get srDeleteBody => 'This will permanently delete this record.';

  @override
  String get srSpray => 'Spray';

  @override
  String get srFertilizer => 'Fertilizer';

  @override
  String get srAppDate => 'Application Date *';

  @override
  String get srProduct => 'Product Name *';

  @override
  String get srProductHint => 'e.g. Karate 5 EC';

  @override
  String get srActiveIngredient => 'Active Ingredient';

  @override
  String get srActiveIngredientHint => 'e.g. Lambda-cyhalothrin';

  @override
  String get srRegNumber => 'Registration Number';

  @override
  String get srTargetPest => 'Target Pest / Disease *';

  @override
  String get srTargetCrop => 'Target Crop / Nutrient *';

  @override
  String get srTargetPestHint => 'e.g. False codling moth';

  @override
  String get srTargetCropHint => 'e.g. Nitrogen top-dressing';

  @override
  String get srRate => 'Application Rate *';

  @override
  String get enterANumber => 'Enter a number';

  @override
  String get srUnit => 'Unit';

  @override
  String get srTotalUsed => 'Total Used';

  @override
  String get srFieldsTreated => 'Fields Treated';

  @override
  String get srOperator => 'Operator Name *';

  @override
  String get srEquipment => 'Equipment';

  @override
  String get srEquipmentHint => 'e.g. Tractor boom sprayer';

  @override
  String get srPhi => 'PHI (days)';

  @override
  String get srPhiHint => 'Pre-Harvest Interval';

  @override
  String get srRei => 'REI (days)';

  @override
  String get srReiHint => 'Re-Entry Interval';

  @override
  String get srWeather => 'Weather Conditions';

  @override
  String get srWeatherHint => 'e.g. Clear, 22°C, wind < 5 km/h';

  @override
  String get srNotesHint => 'Any additional notes';

  @override
  String get srSave => 'Save Record';

  @override
  String get actionUpdate => 'Update';

  @override
  String get srTypeSpray => 'Spray Application';

  @override
  String get srTypeFertilizer => 'Fertilizer Application';

  @override
  String unitBoxes(String value) {
    return '$value boxes';
  }

  @override
  String unitPieces(int count) {
    return '$count pcs';
  }

  @override
  String get errNoAuthUser => 'No authenticated user';

  @override
  String errInitData(String error) {
    return 'Failed to initialize data: $error';
  }

  @override
  String errUpdateFiles(String error) {
    return 'Failed to update document files: $error';
  }

  @override
  String errDeleteDoc(String error) {
    return 'Failed to delete document: $error';
  }

  @override
  String errFetchData(String error) {
    return 'Failed to fetch data: $error';
  }

  @override
  String errFetchCatsTypes(String error) {
    return 'Failed to fetch categories and document types: $error';
  }

  @override
  String errFetchCats(String error) {
    return 'Failed to fetch categories: $error';
  }

  @override
  String errFetchTypes(String error) {
    return 'Failed to fetch document types: $error';
  }

  @override
  String errFetchDocs(String error) {
    return 'Failed to fetch documents: $error';
  }

  @override
  String errGetDoc(String error) {
    return 'Failed to get document: $error';
  }

  @override
  String errCreateDoc(String error) {
    return 'Failed to create document: $error';
  }

  @override
  String get errNoEffectiveUser => 'No effective user found';

  @override
  String errUpdateStatus(String error) {
    return 'Failed to update document status: $error';
  }

  @override
  String errSupersede(String error) {
    return 'Failed to supersede document: $error';
  }

  @override
  String errAddSignature(String error) {
    return 'Failed to add signature: $error';
  }

  @override
  String errAddComment(String error) {
    return 'Failed to add comment: $error';
  }

  @override
  String errCompliancePct(String error) {
    return 'Failed to calculate compliance percentage: $error';
  }

  @override
  String cmtCreatedByAdmin(String admin, String user) {
    return 'Document created by admin $admin for user $user';
  }

  @override
  String get cmtSpecUpdated => 'specification updated';

  @override
  String cmtExpiryUpdated(String date) {
    return 'expiry date updated to $date';
  }

  @override
  String get cmtExpiryRemoved => 'expiry date removed';

  @override
  String cmtStatusByAdmin(String name) {
    return 'Status updated by admin $name';
  }

  @override
  String viaAdmin(String user, String admin) {
    return '$user (via admin $admin)';
  }

  @override
  String get cmtResubmitted => 'Document resubmitted with updated files.';

  @override
  String cmtResubmittedByAdmin(String admin, String user) {
    return 'Document resubmitted with updated files by admin $admin for user $user.';
  }

  @override
  String get noReasonProvided => 'No reason provided';

  @override
  String errInitCats(String error) {
    return 'Failed to initialize categories: $error';
  }

  @override
  String errComplianceStats(String error) {
    return 'Failed to calculate compliance statistics: $error';
  }

  @override
  String errAuditDocs(String error) {
    return 'Failed to get documents for audit: $error';
  }

  @override
  String get pushChannelName => 'Compliance Alerts';

  @override
  String get pushChannelDesc =>
      'Document rejections, expiries and audit reminders';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusFinal => 'Final';

  @override
  String routeNotFound(String name) {
    return 'No route defined for $name';
  }

  @override
  String get fmInvalidKey => 'Invalid API key.';

  @override
  String get fmForbidden => 'Access forbidden.';

  @override
  String get fmNotFound => 'Not found.';

  @override
  String get fmRateLimit => 'Rate limit reached. Try again shortly.';

  @override
  String fmApiError(int code) {
    return 'API error ($code)';
  }

  @override
  String get bankRefDefault => 'Salaries';

  @override
  String get bankNoteGeneric =>
      'Generic layout with column headings — map the columns in your bank’s import screen and test a small upload first.';

  @override
  String bankNoteUnverified(String bank) {
    return 'Template not yet confirmed with $bank — test a small upload first.';
  }

  @override
  String get bankIssueNetZero => 'net pay is R 0.00 or less';

  @override
  String bankFileName(String company, String bank, String period, String ext) {
    return '$company Bank Payments $bank $period.$ext';
  }

  @override
  String bankFileNameGeneric(String company, String period, String ext) {
    return '$company Bank Payments $period.$ext';
  }

  @override
  String get bankGenericName => 'Other bank (generic CSV)';

  @override
  String get unnamedEmployee => 'Unnamed employee';

  @override
  String get skipEmployeeGone => 'employee record no longer exists';

  @override
  String get bankNoneSelected => 'No payslips selected.';

  @override
  String get bankChooseBank => 'Choose the bank the farm pays from.';

  @override
  String bankDraftsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count draft payslips selected — remove them or include them anyway.',
      one: '1 draft payslip selected — remove it or include it anyway.',
    );
    return '$_temp0';
  }

  @override
  String get bankAllDrafts =>
      'All selected payslips are drafts — include them anyway or select finalised payslips.';

  @override
  String get bankNobodyBanking =>
      'Nobody has banking details yet — add them to continue.';

  @override
  String get bankNotLinked =>
      'These payslips aren’t linked to an employee — fix them to continue.';

  @override
  String get bankNobodyPayableFix =>
      'Nobody can be paid yet — fix the employees listed below.';

  @override
  String pdfPayslipFile(String name, String period) {
    return '$name $period Payslip.pdf';
  }

  @override
  String pdfUifFile(String company, String period) {
    return '$company UIF Summary $period.pdf';
  }

  @override
  String pdfLeaveFile(String company, String stamp) {
    return '$company Leave Records $stamp.pdf';
  }

  @override
  String get psEmployeeType => 'Employee Type';

  @override
  String get payslipFinalisedDot => 'This payslip has been finalised.';

  @override
  String get payslipDraftBanner =>
      'DRAFT – This payslip has not been finalised.';

  @override
  String get uifSummaryTitle => 'UIF & DEDUCTIONS SUMMARY';

  @override
  String uifPeriodRange(String start, String end) {
    return 'Period: $start – $end';
  }

  @override
  String uifRegNrValue(String value) {
    return 'UIF Reg No: $value';
  }

  @override
  String uifEmployeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count employees',
      one: '1 employee',
    );
    return '$_temp0';
  }

  @override
  String get uifColIncome => 'Income';

  @override
  String get uifColEmployeeUif => 'UIF Empl. (1%)';

  @override
  String get uifColEmployerUif => 'UIF Emplr. (1%)';

  @override
  String get uifColOtherDed => 'Other Ded.';

  @override
  String get uifColEmployeeDed => 'Empl. Ded.';

  @override
  String get uifSummaryHeading => 'Summary';

  @override
  String get uifPayeTaxColon => 'PAYE Tax:';

  @override
  String get uifEmployeeContribution => 'Employee UIF contribution (1%):';

  @override
  String get uifOtherDeductions => 'Other deductions:';

  @override
  String get uifTotalEmployeeDed => 'TOTAL EMPLOYEE DEDUCTIONS:';

  @override
  String get uifEmployerContribution => 'Employer UIF contribution (1%):';

  @override
  String get uifTotalPayable => 'TOTAL UIF PAYABLE (Empl. + Emplr.):';

  @override
  String get leavePdfTitle => 'LEAVE RECORDS';

  @override
  String leavePdfGenerated(String date) {
    return 'Generated: $date';
  }

  @override
  String get leavePdfHoursNote => 'Values in hours (days = hours ÷ 8)';

  @override
  String get leavePdfNoEmployees => 'No employees.';

  @override
  String get leavePdfColType => 'Leave Type';

  @override
  String get leavePdfOpening => 'Opening';

  @override
  String get leavePdfHoliday => 'Holiday (HL)';

  @override
  String get leavePdfSick => 'Sick (SL)';

  @override
  String get leavePdfFamily => 'Family (FL)';

  @override
  String get leavePdfFormula =>
      'Balance = Opening (pre-system) + Accrued (in-system) − Taken.';

  @override
  String get xlsSheet => 'Payslips';

  @override
  String get xlsType => 'Type';

  @override
  String get xlsJob => 'Job';

  @override
  String get xlsSickHrs => 'Sick hrs';

  @override
  String get xlsHolidayHrs => 'Holiday hrs';

  @override
  String get xlsFamilyHrs => 'Family hrs';

  @override
  String get xlsGross => 'Gross (R)';

  @override
  String get xlsPaye => 'PAYE (R)';

  @override
  String get xlsUif => 'UIF 1% (R)';

  @override
  String get xlsOtherDed => 'Other deductions (R)';

  @override
  String get xlsTotalDed => 'Total deductions (R)';

  @override
  String get xlsNet => 'Net (R)';

  @override
  String xlsTotalRow(int count) {
    return 'TOTAL ($count)';
  }

  @override
  String xlsFileName(String company, String period) {
    return '$company Payslips $period.xlsx';
  }

  @override
  String zipFileName(String company) {
    return '$company Payslips.zip';
  }

  @override
  String frFileName(String company, String stamp) {
    return '$company Farm Register $stamp.pdf';
  }

  @override
  String get frTitle => 'FARM REGISTER';

  @override
  String frFarm(String name) {
    return 'Farm: $name';
  }

  @override
  String frCountry(String name) {
    return 'Country: $name';
  }

  @override
  String frLocation(String lat, String lng) {
    return 'Location: $lat, $lng';
  }

  @override
  String frGenerated(String date) {
    return 'Generated: $date';
  }

  @override
  String frCounts(int fields, String area, int equipment, int people) {
    return '$fields fields · $area ha · $equipment equipment · $people people';
  }

  @override
  String get frFieldsSection => 'FIELDS / BLOCKS';

  @override
  String get frBlockField => 'Block / Field';

  @override
  String get frAreaHa => 'Area (ha)';

  @override
  String get frEquipmentSection => 'EQUIPMENT REGISTER';

  @override
  String get frCapacity => 'Capacity';

  @override
  String get frRate => 'Rate';

  @override
  String get frRegNo => 'Reg. No.';

  @override
  String get frInspection => 'Inspection';

  @override
  String get frPeopleSection => 'PEOPLE / ROLES';

  @override
  String get frName => 'Name';

  @override
  String get frEmail => 'Email';

  @override
  String get frRole => 'Role';

  @override
  String get frSource =>
      'Source: Farmable Partner API v2.0. Generated by Crop Compliance for audit evidence.';

  @override
  String get leaveCodePH => 'PH';

  @override
  String get leaveCodeA => 'A';

  @override
  String get tsLeaveCodesTitle => 'Leave codes';

  @override
  String get tsLeaveHintPick =>
      'Click a day in the grid, then a code — or type the code straight into the day.';

  @override
  String tsLeaveHintTarget(String name, String day) {
    return 'Filling $name · $day — moves to the next day after each code.';
  }

  @override
  String get tsLeavePickDayFirst =>
      'Click the day in the grid first, then the leave code.';

  @override
  String get tsCodeSL => 'Sick leave';

  @override
  String get tsCodeHL => 'Holiday leave';

  @override
  String get tsCodeFL => 'Family responsibility';

  @override
  String get tsCodePH => 'Public holiday';

  @override
  String get tsCodeA => 'Absent (unpaid)';

  @override
  String get tsCodeClear => 'Clear day';

  @override
  String tsCodeTipSL(String hours) {
    return 'Paid as one ordinary day ($hours h) and taken off the employee’s sick-leave balance.';
  }

  @override
  String tsCodeTipHL(String hours) {
    return 'Paid as one ordinary day ($hours h) and taken off the employee’s holiday-leave balance.';
  }

  @override
  String tsCodeTipFL(String hours) {
    return 'Paid as one ordinary day ($hours h) and taken off the employee’s family-responsibility leave balance.';
  }

  @override
  String tsCodeTipPH(String hours) {
    return 'Public holiday not worked: paid as one ordinary day ($hours h). If they worked it, type their hours instead.';
  }

  @override
  String get tsCodeTipA => 'Absent — this day is not paid.';

  @override
  String get tsCodeTipClear => 'Empty the selected day.';

  @override
  String get farmChooseToContinue => 'Choose a farm';

  @override
  String get pdfDownloadBtn => 'Download PDF';

  @override
  String get pdfOpenPrint => 'Open / print';

  @override
  String get psPayeBelowThreshold =>
      'Below the tax threshold — no PAYE due this period';

  @override
  String get psEarningsCaps => 'EARNINGS';

  @override
  String get psDeductionsCaps => 'DEDUCTIONS';

  @override
  String tsPdfFile(String company, String start) {
    return 'Timesheet $company $start.pdf';
  }

  @override
  String tsPdfHeading(String sheet) {
    return 'Timesheet · $sheet';
  }

  @override
  String get tsPdfDraft => 'Draft — not finalised';

  @override
  String tsPdfPrinted(String date) {
    return 'Printed $date';
  }

  @override
  String get tsPdfChecked =>
      'Checked by: ______________________________      Signature: ______________________________      Date: ____________________';

  @override
  String tsPdfPieceLegend(String unit) {
    return 'Each day: hours worked (h) and $unit picked.';
  }

  @override
  String get tsPdfDownloading => 'Making the timesheet PDF…';

  @override
  String tsLeaveUnpaidTip(String leave) {
    return 'Unpaid — not enough $leave left (chosen when saving). Type the code again to have it checked again.';
  }

  @override
  String tsLeavePartTip(String hours, String leave) {
    return '$hours h paid, the rest unpaid — not enough $leave left (chosen when saving). Type the code again to have it checked again.';
  }

  @override
  String tsLeaveOverrideTip(String leave) {
    return 'Paid in full although the $leave balance was short (chosen when saving). Type the code again to have it checked again.';
  }

  @override
  String tsUnpaidBadge(String hours) {
    return '$hours h unpaid';
  }

  @override
  String get tsLeaveUnpaidLegend =>
      '= unpaid or partly paid — not enough leave left, as chosen when saving. Type the code again to have the day checked again.';

  @override
  String get tsPdfUnpaidLegend =>
      'A number under a leave code = hours paid for that day (not enough leave left).';

  @override
  String get tsLeaveSettledToast =>
      'Your choices are on the timesheet: crossed-out days are unpaid.';
}
