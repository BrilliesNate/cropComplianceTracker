import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_af.dart';
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
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('af'),
    Locale('en')
  ];

  /// Name of this language, shown in the language picker
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageAfrikaans.
  ///
  /// In en, this message translates to:
  /// **'Afrikaans'**
  String get languageAfrikaans;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Compliance'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get commonSwitch;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAuditChecklist.
  ///
  /// In en, this message translates to:
  /// **'Audit checklist'**
  String get navAuditChecklist;

  /// No description provided for @navPayslips.
  ///
  /// In en, this message translates to:
  /// **'Payslips'**
  String get navPayslips;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farm;

  /// No description provided for @farmOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm open'**
  String get farmOpenLabel;

  /// No description provided for @farmNoneViewingAll.
  ///
  /// In en, this message translates to:
  /// **'None — viewing all farms'**
  String get farmNoneViewingAll;

  /// No description provided for @farmOpenAFarm.
  ///
  /// In en, this message translates to:
  /// **'Open a farm'**
  String get farmOpenAFarm;

  /// No description provided for @farmSwitchFarm.
  ///
  /// In en, this message translates to:
  /// **'Switch farm'**
  String get farmSwitchFarm;

  /// No description provided for @farmChooseAFarm.
  ///
  /// In en, this message translates to:
  /// **'Choose a farm'**
  String get farmChooseAFarm;

  /// No description provided for @farmBackToAll.
  ///
  /// In en, this message translates to:
  /// **'Back to all farms'**
  String get farmBackToAll;

  /// No description provided for @farmViewing.
  ///
  /// In en, this message translates to:
  /// **'Viewing farm {name}'**
  String farmViewing(String name);

  /// No description provided for @unreadCountNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String unreadCountNew(int count);

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline — your work is saved on this phone'**
  String get syncOffline;

  /// No description provided for @syncFilesWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file waiting to upload} other{{count} files waiting to upload}}'**
  String syncFilesWaiting(int count);

  /// No description provided for @syncAllSynced.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced'**
  String get syncAllSynced;

  /// No description provided for @syncUploadNow.
  ///
  /// In en, this message translates to:
  /// **'Upload now'**
  String get syncUploadNow;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutPendingFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file is still waiting to upload.} other{{count} files are still waiting to upload.}} They stay on this phone and upload next time someone signs in here with signal.'**
  String signOutPendingFiles(int count);

  /// No description provided for @signOutCanSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'You can sign in again any time.'**
  String get signOutCanSignInAgain;

  /// No description provided for @languageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the language for the app, your notifications and downloads.'**
  String get languageHint;

  /// No description provided for @farmWhichFarm.
  ///
  /// In en, this message translates to:
  /// **'Which farm?'**
  String get farmWhichFarm;

  /// No description provided for @farmPickForChecklist.
  ///
  /// In en, this message translates to:
  /// **'Pick the farm whose audit checklist you want to see.'**
  String get farmPickForChecklist;

  /// No description provided for @farmPickForPayslips.
  ///
  /// In en, this message translates to:
  /// **'Pick the farm whose payslips you want to manage.'**
  String get farmPickForPayslips;

  /// No description provided for @farmSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search farms…'**
  String get farmSearchHint;

  /// No description provided for @farmLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the farms. Check your signal and try again.'**
  String get farmLoadFailed;

  /// No description provided for @farmNoSearchMatch.
  ///
  /// In en, this message translates to:
  /// **'No farms match your search.'**
  String get farmNoSearchMatch;

  /// No description provided for @offlineWithFiles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You’re offline — your work is saved on this phone. 1 file will upload when you’re back online.} other{You’re offline — your work is saved on this phone. {count} files will upload when you’re back online.}}'**
  String offlineWithFiles(int count);

  /// No description provided for @offlineNoFiles.
  ///
  /// In en, this message translates to:
  /// **'You’re offline — your work is saved on this phone and will sync when you’re back online.'**
  String get offlineNoFiles;

  /// No description provided for @offlineUploading.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Back online — uploading 1 file…} other{Back online — uploading {count} files…}}'**
  String offlineUploading(int count);

  /// No description provided for @offlineRetrying.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file waiting to upload — retrying shortly.} other{{count} files waiting to upload — retrying shortly.}}'**
  String offlineRetrying(int count);

  /// No description provided for @offlineRetryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get offlineRetryNow;

  /// No description provided for @pendingSavedOfflineTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saved offline — 1 file will upload automatically when the phone is back online.} other{Saved offline — {count} files will upload automatically when the phone is back online.}}'**
  String pendingSavedOfflineTooltip(int count);

  /// No description provided for @pendingWaitingToUpload.
  ///
  /// In en, this message translates to:
  /// **'Waiting to upload'**
  String get pendingWaitingToUpload;

  /// No description provided for @pendingSavedOnThisPhone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file saved on this phone — uploading automatically when you’re online.} other{{count} files saved on this phone — uploading automatically when you’re online.}}'**
  String pendingSavedOnThisPhone(int count);

  /// No description provided for @pendingUploadingFromOtherPhone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file still uploading from the phone it was saved on.} other{{count} files still uploading from the phone they were saved on.}}'**
  String pendingUploadingFromOtherPhone(int count);

  /// No description provided for @adminSortMostPending.
  ///
  /// In en, this message translates to:
  /// **'Most pending first'**
  String get adminSortMostPending;

  /// No description provided for @adminSortName.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get adminSortName;

  /// No description provided for @adminSortLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest progress first'**
  String get adminSortLowest;

  /// No description provided for @adminSortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest progress first'**
  String get adminSortHighest;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @adminTools.
  ///
  /// In en, this message translates to:
  /// **'Admin tools'**
  String get adminTools;

  /// No description provided for @commonSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get commonSearchHint;

  /// No description provided for @adminShowTwoPerRow.
  ///
  /// In en, this message translates to:
  /// **'Show two farms per row'**
  String get adminShowTwoPerRow;

  /// No description provided for @adminShowOnePerRow.
  ///
  /// In en, this message translates to:
  /// **'Show one farm per row'**
  String get adminShowOnePerRow;

  /// No description provided for @adminSortAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort and filter'**
  String get adminSortAndFilter;

  /// No description provided for @adminLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the farms. If you are offline, connect and try again.'**
  String get adminLoadFailed;

  /// No description provided for @adminNoFarmsYet.
  ///
  /// In en, this message translates to:
  /// **'There are no farms yet.'**
  String get adminNoFarmsYet;

  /// No description provided for @adminNoFarmsMatch.
  ///
  /// In en, this message translates to:
  /// **'No farms match your search or filters.'**
  String get adminNoFarmsMatch;

  /// No description provided for @adminAddFarm.
  ///
  /// In en, this message translates to:
  /// **'Add a farm'**
  String get adminAddFarm;

  /// No description provided for @adminClearSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear search and filters'**
  String get adminClearSearchFilters;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @adminSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get adminSortBy;

  /// No description provided for @adminStandards.
  ///
  /// In en, this message translates to:
  /// **'Standards'**
  String get adminStandards;

  /// No description provided for @adminOnlyPending.
  ///
  /// In en, this message translates to:
  /// **'Only farms with pending documents'**
  String get adminOnlyPending;

  /// No description provided for @adminShowFarms.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 farm} other{Show {count} farms}}'**
  String adminShowFarms(int count);

  /// No description provided for @menuCompanyManagement.
  ///
  /// In en, this message translates to:
  /// **'Company Management'**
  String get menuCompanyManagement;

  /// No description provided for @menuUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get menuUserManagement;

  /// No description provided for @menuCategoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get menuCategoryManagement;

  /// No description provided for @menuDocumentSettings.
  ///
  /// In en, this message translates to:
  /// **'Document Settings'**
  String get menuDocumentSettings;

  /// No description provided for @menuDataFixUtility.
  ///
  /// In en, this message translates to:
  /// **'Data Fix Utility'**
  String get menuDataFixUtility;

  /// No description provided for @menuFarmableConsole.
  ///
  /// In en, this message translates to:
  /// **'Farmable API Console'**
  String get menuFarmableConsole;

  /// No description provided for @adminFarmCardSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {pending} pending documents, {percent} percent complete'**
  String adminFarmCardSemantics(String name, int pending, int percent);

  /// No description provided for @farmNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No address yet'**
  String get farmNoAddress;

  /// No description provided for @pendingDocumentsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Pending Document} other{Pending Documents}}'**
  String pendingDocumentsLabel(int count);

  /// No description provided for @employeeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Employee} other{{count} Employees}}'**
  String employeeCount(int count);

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get statusInReview;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get statusNotApplicable;

  /// No description provided for @statusToUpload.
  ///
  /// In en, this message translates to:
  /// **'To upload'**
  String get statusToUpload;

  /// No description provided for @trackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Compliance Tracker'**
  String get trackerTitle;

  /// No description provided for @trackerNoStandards.
  ///
  /// In en, this message translates to:
  /// **'No audit standards are switched on for this farm yet.'**
  String get trackerNoStandards;

  /// No description provided for @trackerAskAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ask your Crop Compliance administrator to turn on SIZA/WIETA, GlobalG.A.P., IPW, Fairtrade or SIZA Environmental for your farm.'**
  String get trackerAskAdmin;

  /// No description provided for @trackerOpenChecklist.
  ///
  /// In en, this message translates to:
  /// **'Open audit checklist'**
  String get trackerOpenChecklist;

  /// No description provided for @trackerOverallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall progress'**
  String get trackerOverallProgress;

  /// No description provided for @trackerYouAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get trackerYouAreHere;

  /// No description provided for @trackerBehindYou.
  ///
  /// In en, this message translates to:
  /// **'Behind you'**
  String get trackerBehindYou;

  /// No description provided for @trackerDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String trackerDoneCount(int count);

  /// No description provided for @trackerFirstUploadHere.
  ///
  /// In en, this message translates to:
  /// **'Your first upload will show here'**
  String get trackerFirstUploadHere;

  /// No description provided for @trackerAndMore.
  ///
  /// In en, this message translates to:
  /// **'…and {count} more'**
  String trackerAndMore(int count);

  /// No description provided for @trackerAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up — every requirement has been submitted.'**
  String get trackerAllCaughtUp;

  /// No description provided for @statusRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get statusRequired;

  /// No description provided for @trackerHintRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'It was rejected: {reason}. Upload a corrected version.'**
  String trackerHintRejectedReason(String reason);

  /// No description provided for @trackerHintRejected.
  ///
  /// In en, this message translates to:
  /// **'It was rejected. Upload a corrected version.'**
  String get trackerHintRejected;

  /// No description provided for @trackerHintExpired.
  ///
  /// In en, this message translates to:
  /// **'It has expired. Upload the renewed document.'**
  String get trackerHintExpired;

  /// No description provided for @trackerHintUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload the {type} for {category}.'**
  String trackerHintUpload(String type, String category);

  /// No description provided for @trackerRightNow.
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get trackerRightNow;

  /// No description provided for @trackerInFront.
  ///
  /// In en, this message translates to:
  /// **'In front of you'**
  String get trackerInFront;

  /// No description provided for @trackerToGo.
  ///
  /// In en, this message translates to:
  /// **'{count} to go'**
  String trackerToGo(int count);

  /// No description provided for @trackerNothingLeft.
  ///
  /// In en, this message translates to:
  /// **'Nothing left'**
  String get trackerNothingLeft;

  /// No description provided for @trackerLastOne.
  ///
  /// In en, this message translates to:
  /// **'This is the last one'**
  String get trackerLastOne;

  /// No description provided for @actionResubmitType.
  ///
  /// In en, this message translates to:
  /// **'Resubmit {type}'**
  String actionResubmitType(String type);

  /// No description provided for @actionRenewType.
  ///
  /// In en, this message translates to:
  /// **'Renew {type}'**
  String actionRenewType(String type);

  /// No description provided for @actionUploadType.
  ///
  /// In en, this message translates to:
  /// **'Upload {type}'**
  String actionUploadType(String type);

  /// No description provided for @checklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Checklist'**
  String get checklistTitle;

  /// No description provided for @checklistAskAdmin.
  ///
  /// In en, this message translates to:
  /// **'Ask your Crop Compliance administrator to turn one on for your farm.'**
  String get checklistAskAdmin;

  /// No description provided for @checklistNothingInCategory.
  ///
  /// In en, this message translates to:
  /// **'Nothing to upload in this category.'**
  String get checklistNothingInCategory;

  /// No description provided for @checklistSeeAllUploaded.
  ///
  /// In en, this message translates to:
  /// **'See all uploaded documents'**
  String get checklistSeeAllUploaded;

  /// No description provided for @ruleMultipleAllowed.
  ///
  /// In en, this message translates to:
  /// **'Multiple documents allowed'**
  String get ruleMultipleAllowed;

  /// No description provided for @ruleHasExpiry.
  ///
  /// In en, this message translates to:
  /// **'Has an expiry date'**
  String get ruleHasExpiry;

  /// No description provided for @ruleFilledInApp.
  ///
  /// In en, this message translates to:
  /// **'Filled in on the app'**
  String get ruleFilledInApp;

  /// No description provided for @actionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get actionUpload;

  /// No description provided for @actionFillIn.
  ///
  /// In en, this message translates to:
  /// **'Fill in'**
  String get actionFillIn;

  /// No description provided for @actionFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get actionFix;

  /// No description provided for @actionRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get actionRenew;

  /// No description provided for @uploadTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get uploadTakePhoto;

  /// No description provided for @uploadChooseFileTypes.
  ///
  /// In en, this message translates to:
  /// **'Choose a file (PDF, Word, photo)'**
  String get uploadChooseFileTypes;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @uploadNeedFileFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a file or take a photo first.'**
  String get uploadNeedFileFirst;

  /// No description provided for @uploadNeedExpiry.
  ///
  /// In en, this message translates to:
  /// **'Tap the expiry date on the calendar.'**
  String get uploadNeedExpiry;

  /// No description provided for @uploadNeedReviewed.
  ///
  /// In en, this message translates to:
  /// **'Choose the date it was last reviewed.'**
  String get uploadNeedReviewed;

  /// No description provided for @uploadNeedSpec.
  ///
  /// In en, this message translates to:
  /// **'Add a specification — what does this upload cover?'**
  String get uploadNeedSpec;

  /// No description provided for @uploadNoFarm.
  ///
  /// In en, this message translates to:
  /// **'No farm selected — open the dashboard and try again.'**
  String get uploadNoFarm;

  /// No description provided for @errorSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String errorSomethingWrong(String error);

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The upload didn’t go through — please try again.'**
  String get uploadFailed;

  /// No description provided for @uploadSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on your phone — it will upload automatically when you’re online.'**
  String get uploadSavedOffline;

  /// No description provided for @uploadDoneWaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Uploaded — it’s now waiting for review.'**
  String get uploadDoneWaitingReview;

  /// No description provided for @uploadTapExpiry.
  ///
  /// In en, this message translates to:
  /// **'Tap the expiry date'**
  String get uploadTapExpiry;

  /// No description provided for @uploadSubtitleWithExpiry.
  ///
  /// In en, this message translates to:
  /// **'Upload the document and set its expiry date'**
  String get uploadSubtitleWithExpiry;

  /// No description provided for @uploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload the document'**
  String get uploadSubtitle;

  /// No description provided for @uploadSpecRequired.
  ///
  /// In en, this message translates to:
  /// **'Specification (required)'**
  String get uploadSpecRequired;

  /// No description provided for @uploadSpecOptional.
  ///
  /// In en, this message translates to:
  /// **'Specification (optional)'**
  String get uploadSpecOptional;

  /// No description provided for @uploadSpecHint.
  ///
  /// In en, this message translates to:
  /// **'What does it cover? e.g. site, period'**
  String get uploadSpecHint;

  /// No description provided for @uploadChooseFileOrPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a file or photo'**
  String get uploadChooseFileOrPhoto;

  /// No description provided for @uploadTypeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'This document type couldn’t be loaded.'**
  String get uploadTypeLoadFailed;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get expiryDate;

  /// No description provided for @uploadNoFileYet.
  ///
  /// In en, this message translates to:
  /// **'No file chosen yet'**
  String get uploadNoFileYet;

  /// No description provided for @uploadFileAndMore.
  ///
  /// In en, this message translates to:
  /// **'{name} + {count} more'**
  String uploadFileAndMore(String name, int count);

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

  /// No description provided for @uploadExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry date: '**
  String get uploadExpiryLabel;

  /// No description provided for @uploadNotSet.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get uploadNotSet;

  /// No description provided for @uploadSelectedDocs.
  ///
  /// In en, this message translates to:
  /// **'Selected documents ({count})'**
  String uploadSelectedDocs(int count);

  /// No description provided for @actionPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get actionPreview;

  /// No description provided for @dateLastReviewed.
  ///
  /// In en, this message translates to:
  /// **'Date last reviewed'**
  String get dateLastReviewed;

  /// No description provided for @dateLastReviewedRequired.
  ///
  /// In en, this message translates to:
  /// **'Date last reviewed (required)'**
  String get dateLastReviewedRequired;

  /// No description provided for @lastReviewedOn.
  ///
  /// In en, this message translates to:
  /// **'Last reviewed: {date}'**
  String lastReviewedOn(String date);

  /// No description provided for @hoursTabRate.
  ///
  /// In en, this message translates to:
  /// **'Rate\n(R/hr)'**
  String get hoursTabRate;

  /// No description provided for @hoursTabNormal.
  ///
  /// In en, this message translates to:
  /// **'Norm\nhrs'**
  String get hoursTabNormal;

  /// No description provided for @hoursTabOvertime.
  ///
  /// In en, this message translates to:
  /// **'OT\nhrs'**
  String get hoursTabOvertime;

  /// No description provided for @hoursTabDouble.
  ///
  /// In en, this message translates to:
  /// **'DT\nhrs'**
  String get hoursTabDouble;

  /// No description provided for @hoursTabPublicHoliday.
  ///
  /// In en, this message translates to:
  /// **'PH\nhrs'**
  String get hoursTabPublicHoliday;

  /// No description provided for @hoursTabSick.
  ///
  /// In en, this message translates to:
  /// **'SL\nhrs'**
  String get hoursTabSick;

  /// No description provided for @hoursTabHoliday.
  ///
  /// In en, this message translates to:
  /// **'HL\nhrs'**
  String get hoursTabHoliday;

  /// No description provided for @hoursTabFamily.
  ///
  /// In en, this message translates to:
  /// **'FL\nhrs'**
  String get hoursTabFamily;

  /// No description provided for @hoursTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Type a number, e.g. 8 or 7.5'**
  String get hoursTypeNumber;

  /// No description provided for @hoursSetRateFirst.
  ///
  /// In en, this message translates to:
  /// **'Set {name}’s hourly rate first.'**
  String hoursSetRateFirst(String name);

  /// No description provided for @hoursEnterFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter the hours worked first.'**
  String get hoursEnterFirst;

  /// No description provided for @payslipReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace this payslip?'**
  String get payslipReplaceTitle;

  /// No description provided for @payslipReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'{name} already has a payslip for {start} – {end}. Replace it with these hours?'**
  String payslipReplaceBody(String name, String start, String end);

  /// No description provided for @actionReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get actionReplace;

  /// No description provided for @payslipSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The payslip couldn’t be saved — please try again.'**
  String get payslipSaveFailed;

  /// No description provided for @payslipSavedFor.
  ///
  /// In en, this message translates to:
  /// **'Payslip saved for {name} — net {amount}'**
  String payslipSavedFor(String name, String amount);

  /// No description provided for @periodStart.
  ///
  /// In en, this message translates to:
  /// **'Period start'**
  String get periodStart;

  /// No description provided for @periodEnd.
  ///
  /// In en, this message translates to:
  /// **'Period end'**
  String get periodEnd;

  /// No description provided for @payslipsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'{farm} – Payslips'**
  String payslipsHeaderTitle(String farm);

  /// No description provided for @employeesLabel.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeesLabel;

  /// No description provided for @chooseFarmFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a farm first.'**
  String get chooseFarmFirst;

  /// No description provided for @employeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employeeLabel;

  /// No description provided for @actionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get actionViewAll;

  /// No description provided for @hoursWorked.
  ///
  /// In en, this message translates to:
  /// **'Hours Worked'**
  String get hoursWorked;

  /// No description provided for @payslipNoneYetFor.
  ///
  /// In en, this message translates to:
  /// **'No payslip yet for {name}. Enter the hours below and save.'**
  String payslipNoneYetFor(String name);

  /// No description provided for @payslipNormalPayHours.
  ///
  /// In en, this message translates to:
  /// **'Normal Pay ({hours} h)'**
  String payslipNormalPayHours(String hours);

  /// No description provided for @payslipOvertimePayHours.
  ///
  /// In en, this message translates to:
  /// **'Overtime Pay ({hours} h)'**
  String payslipOvertimePayHours(String hours);

  /// No description provided for @payslipDoubleTimeHours.
  ///
  /// In en, this message translates to:
  /// **'Double Time ({hours} h)'**
  String payslipDoubleTimeHours(String hours);

  /// No description provided for @payslipPublicHolidayHours.
  ///
  /// In en, this message translates to:
  /// **'Public Holiday ({hours} h)'**
  String payslipPublicHolidayHours(String hours);

  /// No description provided for @payslipSickLeaveHours.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave ({hours} h)'**
  String payslipSickLeaveHours(String hours);

  /// No description provided for @payslipAnnualLeaveHours.
  ///
  /// In en, this message translates to:
  /// **'Annual Leave ({hours} h)'**
  String payslipAnnualLeaveHours(String hours);

  /// No description provided for @payslipFamilyLeaveHours.
  ///
  /// In en, this message translates to:
  /// **'Family Responsibility Leave ({hours} h)'**
  String payslipFamilyLeaveHours(String hours);

  /// No description provided for @payslipTitle.
  ///
  /// In en, this message translates to:
  /// **'PAYSLIP'**
  String get payslipTitle;

  /// No description provided for @payslipName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get payslipName;

  /// No description provided for @payslipIdNumber.
  ///
  /// In en, this message translates to:
  /// **'ID Number'**
  String get payslipIdNumber;

  /// No description provided for @payslipPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get payslipPeriod;

  /// No description provided for @payslipPayDate.
  ///
  /// In en, this message translates to:
  /// **'Pay Date'**
  String get payslipPayDate;

  /// No description provided for @payslipEarnings.
  ///
  /// In en, this message translates to:
  /// **'EARNINGS'**
  String get payslipEarnings;

  /// No description provided for @payslipTotalEarnings.
  ///
  /// In en, this message translates to:
  /// **'TOTAL EARNINGS'**
  String get payslipTotalEarnings;

  /// No description provided for @payslipDeductions.
  ///
  /// In en, this message translates to:
  /// **'DEDUCTIONS'**
  String get payslipDeductions;

  /// No description provided for @payslipUifEmployee.
  ///
  /// In en, this message translates to:
  /// **'UIF Employee (1%)'**
  String get payslipUifEmployee;

  /// No description provided for @payslipPayeTax.
  ///
  /// In en, this message translates to:
  /// **'PAYE Tax'**
  String get payslipPayeTax;

  /// No description provided for @payslipTotalDeductions.
  ///
  /// In en, this message translates to:
  /// **'TOTAL DEDUCTIONS'**
  String get payslipTotalDeductions;

  /// No description provided for @payslipNetSalary.
  ///
  /// In en, this message translates to:
  /// **'Net Salary'**
  String get payslipNetSalary;

  /// No description provided for @actionDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get actionDownloadPdf;

  /// No description provided for @pdfOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the PDF: {error}'**
  String pdfOpenFailed(String error);

  /// No description provided for @employeesNoneYetTapAdd.
  ///
  /// In en, this message translates to:
  /// **'No employees yet — tap to add your first one.'**
  String get employeesNoneYetTapAdd;

  /// No description provided for @employeeNoId.
  ///
  /// In en, this message translates to:
  /// **'No ID'**
  String get employeeNoId;

  /// No description provided for @employeeIdShort.
  ///
  /// In en, this message translates to:
  /// **'ID {id}'**
  String employeeIdShort(String id);

  /// No description provided for @employeeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or ID'**
  String get employeeSearchHint;

  /// No description provided for @employeeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get employeeAdd;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @saveFailedReason.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {reason}'**
  String saveFailedReason(String reason);

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get errorUnknown;

  /// No description provided for @hoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{hours} h left'**
  String hoursLeft(String hours);

  /// No description provided for @hoursHelpRate.
  ///
  /// In en, this message translates to:
  /// **'Employee’s base hourly wage in Rand, used to calculate all earnings'**
  String get hoursHelpRate;

  /// No description provided for @hoursHelpNormal.
  ///
  /// In en, this message translates to:
  /// **'Ordinary hours worked in this period'**
  String get hoursHelpNormal;

  /// No description provided for @hoursHelpOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime hours — paid at 1.5 × the rate'**
  String get hoursHelpOvertime;

  /// No description provided for @hoursHelpDouble.
  ///
  /// In en, this message translates to:
  /// **'Double-time hours (e.g. Sundays) — paid at 2 × the rate'**
  String get hoursHelpDouble;

  /// No description provided for @hoursHelpPublicHoliday.
  ///
  /// In en, this message translates to:
  /// **'Paid public-holiday hours'**
  String get hoursHelpPublicHoliday;

  /// No description provided for @hoursHelpSick.
  ///
  /// In en, this message translates to:
  /// **'Sick leave taken · {balance}'**
  String hoursHelpSick(String balance);

  /// No description provided for @hoursHelpHoliday.
  ///
  /// In en, this message translates to:
  /// **'Annual leave taken · {balance}'**
  String hoursHelpHoliday(String balance);

  /// No description provided for @hoursHelpFamily.
  ///
  /// In en, this message translates to:
  /// **'Family responsibility leave · {balance}'**
  String hoursHelpFamily(String balance);

  /// No description provided for @employeeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String employeeIdLabel(String id);

  /// No description provided for @dateStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get dateStart;

  /// No description provided for @dateEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get dateEnd;

  /// No description provided for @actionSetDone.
  ///
  /// In en, this message translates to:
  /// **'Set ✓'**
  String get actionSetDone;

  /// No description provided for @actionSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get actionSet;

  /// No description provided for @hoursEntered.
  ///
  /// In en, this message translates to:
  /// **'Entered: {list}'**
  String hoursEntered(String list);

  /// No description provided for @payslipSaveFor.
  ///
  /// In en, this message translates to:
  /// **'Save payslip for {name}'**
  String payslipSaveFor(String name);

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @kpiCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get kpiCompletionRate;

  /// No description provided for @kpiApprovalRate.
  ///
  /// In en, this message translates to:
  /// **'Approval Rate'**
  String get kpiApprovalRate;

  /// No description provided for @kpiPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get kpiPendingReview;

  /// No description provided for @docsNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No documents yet.'**
  String get docsNoneYet;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @documentLabel.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentLabel;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @dashboardDocumentComments.
  ///
  /// In en, this message translates to:
  /// **'Document Comments'**
  String get dashboardDocumentComments;

  /// No description provided for @dashboardAllGood.
  ///
  /// In en, this message translates to:
  /// **'All documents in good standing'**
  String get dashboardAllGood;

  /// No description provided for @rejectedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Rejected - {date}'**
  String rejectedOnDate(String date);

  /// No description provided for @actionResubmit.
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get actionResubmit;

  /// No description provided for @farmPickForPage.
  ///
  /// In en, this message translates to:
  /// **'This page shows one farm. Pick the farm you want to work on.'**
  String get farmPickForPage;

  /// No description provided for @menuComplianceReport.
  ///
  /// In en, this message translates to:
  /// **'Compliance Report'**
  String get menuComplianceReport;

  /// No description provided for @menuAuditIndex.
  ///
  /// In en, this message translates to:
  /// **'Audit Index'**
  String get menuAuditIndex;

  /// No description provided for @menuPayslipManager.
  ///
  /// In en, this message translates to:
  /// **'Payslip Manager'**
  String get menuPayslipManager;

  /// No description provided for @menuMyFarms.
  ///
  /// In en, this message translates to:
  /// **'My Farms'**
  String get menuMyFarms;

  /// No description provided for @menuFarmRegister.
  ///
  /// In en, this message translates to:
  /// **'Farm Register'**
  String get menuFarmRegister;

  /// No description provided for @menuSprayRecords.
  ///
  /// In en, this message translates to:
  /// **'Spray Records'**
  String get menuSprayRecords;

  /// No description provided for @menuFarmableSection.
  ///
  /// In en, this message translates to:
  /// **'FARMABLE'**
  String get menuFarmableSection;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @menuCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get menuCollapse;

  /// No description provided for @farmSelect.
  ///
  /// In en, this message translates to:
  /// **'Select farm'**
  String get farmSelect;

  /// No description provided for @farmSwitchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch farm — {name}'**
  String farmSwitchTooltip(String name);

  /// No description provided for @farmSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not switch farm. Please try again.'**
  String get farmSwitchFailed;

  /// No description provided for @adminModeManagingFor.
  ///
  /// In en, this message translates to:
  /// **'ADMIN MODE: Managing documents for '**
  String get adminModeManagingFor;

  /// No description provided for @adminModeOwnDocs.
  ///
  /// In en, this message translates to:
  /// **'Admin Mode: Managing your own documents'**
  String get adminModeOwnDocs;

  /// No description provided for @actionSwitchBack.
  ///
  /// In en, this message translates to:
  /// **'Switch Back'**
  String get actionSwitchBack;

  /// No description provided for @selectUserToManage.
  ///
  /// In en, this message translates to:
  /// **'Select User to Manage'**
  String get selectUserToManage;

  /// No description provided for @selectUserToManageHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a user to manage their documents and compliance status.'**
  String get selectUserToManageHint;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @manageOwnDocs.
  ///
  /// In en, this message translates to:
  /// **'Manage your own documents'**
  String get manageOwnDocs;

  /// No description provided for @farmTapToSwitch.
  ///
  /// In en, this message translates to:
  /// **'Tap to switch farm'**
  String get farmTapToSwitch;

  /// No description provided for @farmAccessCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have access to 1 farm.} other{You have access to {count} farms.}}'**
  String farmAccessCount(int count);

  /// No description provided for @farmNoMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'No farms match “{query}”'**
  String farmNoMatchQuery(String query);

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @statusExpiresSoon.
  ///
  /// In en, this message translates to:
  /// **'Expires Soon'**
  String get statusExpiresSoon;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleAuditor.
  ///
  /// In en, this message translates to:
  /// **'Auditor'**
  String get roleAuditor;

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get roleUser;

  /// No description provided for @loginTagline1.
  ///
  /// In en, this message translates to:
  /// **'Simplified Compliance,'**
  String get loginTagline1;

  /// No description provided for @loginTagline2.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Success'**
  String get loginTagline2;

  /// No description provided for @loginFeature1.
  ///
  /// In en, this message translates to:
  /// **'Streamlined document management'**
  String get loginFeature1;

  /// No description provided for @loginFeature2.
  ///
  /// In en, this message translates to:
  /// **'Real-time compliance tracking'**
  String get loginFeature2;

  /// No description provided for @loginFeature3.
  ///
  /// In en, this message translates to:
  /// **'Effortless audit preparation'**
  String get loginFeature3;

  /// No description provided for @loginFeature4.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive compliance reports'**
  String get loginFeature4;

  /// No description provided for @loginCopyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} Crop Compliance. All rights reserved.'**
  String loginCopyright(String year);

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get loginWelcomeBack;

  /// No description provided for @loginEnterCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access your account'**
  String get loginEnterCredentials;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get fieldEmailHint;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validationEmailInvalid;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get fieldPasswordHint;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get validationPasswordRequired;

  /// No description provided for @loginRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get loginRememberMe;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get loginContactSupport;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email. We’ll send a reset link if an account exists.'**
  String get resetPasswordBody;

  /// No description provided for @resetPasswordSpamHint.
  ///
  /// In en, this message translates to:
  /// **'If it doesn’t arrive within a few minutes, check your spam folder — or contact your admin, who can set a new password for you directly.'**
  String get resetPasswordSpamHint;

  /// No description provided for @validationEmailValidAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailValidAddress;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a reset email is on its way. Check spam if it doesn’t arrive soon.'**
  String resetPasswordSent(String email);

  /// No description provided for @resetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please contact your admin for help resetting your password.'**
  String get resetPasswordFailed;

  /// No description provided for @resetPasswordSend.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get resetPasswordSend;

  /// No description provided for @authSignedOut.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out. Please sign in again.'**
  String get authSignedOut;

  /// No description provided for @authOtherAccount.
  ///
  /// In en, this message translates to:
  /// **'This browser is now signed in as a different account. Please sign in again.'**
  String get authOtherAccount;

  /// No description provided for @authInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize user: {error}'**
  String authInitFailed(String error);

  /// No description provided for @authLoadUsersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users: {error}'**
  String authLoadUsersFailed(String error);

  /// No description provided for @authAdminView.
  ///
  /// In en, this message translates to:
  /// **'{name} (Admin View)'**
  String authAdminView(String name);

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @authManaging.
  ///
  /// In en, this message translates to:
  /// **'Managing {name}'**
  String authManaging(String name);

  /// No description provided for @authPersonalAccount.
  ///
  /// In en, this message translates to:
  /// **'Personal account'**
  String get authPersonalAccount;

  /// No description provided for @authInvalidLogin.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get authInvalidLogin;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String authLoginFailed(String error);

  /// No description provided for @authRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get authRegisterFailed;

  /// No description provided for @authRegisterFailedReason.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {error}'**
  String authRegisterFailedReason(String error);

  /// No description provided for @authLogoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed: {error}'**
  String authLogoutFailed(String error);

  /// No description provided for @authResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Password reset failed: {error}'**
  String authResetFailed(String error);

  /// No description provided for @authDeactivated.
  ///
  /// In en, this message translates to:
  /// **'This account has been deactivated. Please contact your administrator.'**
  String get authDeactivated;

  /// No description provided for @pleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get pleaseLogIn;

  /// No description provided for @dashboardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard data...'**
  String get dashboardLoading;

  /// No description provided for @adminModeManagingCompany.
  ///
  /// In en, this message translates to:
  /// **'ADMIN MODE: Managing Company'**
  String get adminModeManagingCompany;

  /// No description provided for @adminModeManagingUser.
  ///
  /// In en, this message translates to:
  /// **'ADMIN MODE: Managing User'**
  String get adminModeManagingUser;

  /// No description provided for @viaUser.
  ///
  /// In en, this message translates to:
  /// **'via {name}'**
  String viaUser(String name);

  /// No description provided for @switchBackOwnAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch back to your own account'**
  String get switchBackOwnAccount;

  /// No description provided for @userFallbackName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallbackName;

  /// No description provided for @dashboardManagingName.
  ///
  /// In en, this message translates to:
  /// **'Managing: {name}'**
  String dashboardManagingName(String name);

  /// No description provided for @dashboardHiName.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String dashboardHiName(String name);

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Document compliance overview'**
  String get dashboardOverview;

  /// No description provided for @dashboardWelcomeBackShort.
  ///
  /// In en, this message translates to:
  /// **'Welcome back.'**
  String get dashboardWelcomeBackShort;

  /// No description provided for @kpiActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action Needed'**
  String get kpiActionNeeded;

  /// No description provided for @kpiRejectedItem.
  ///
  /// In en, this message translates to:
  /// **'Rejected Item'**
  String get kpiRejectedItem;

  /// No description provided for @kpiNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get kpiNeedsAttention;

  /// No description provided for @teamAllUsersManaging.
  ///
  /// In en, this message translates to:
  /// **'All Users (Managing: {name})'**
  String teamAllUsersManaging(String name);

  /// No description provided for @teamAllUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get teamAllUsers;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team Members'**
  String get teamMembers;

  /// No description provided for @teamAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get teamAddUser;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageOf(int page, int total);

  /// No description provided for @teamNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get teamNoUsers;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @teamLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading team'**
  String get teamLoadError;

  /// No description provided for @teamNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No team members'**
  String get teamNoMembers;

  /// No description provided for @teamLoadingDocsFor.
  ///
  /// In en, this message translates to:
  /// **'Loading {name}’s documents...'**
  String teamLoadingDocsFor(String name);

  /// No description provided for @teamNowManaging.
  ///
  /// In en, this message translates to:
  /// **'Now managing: {name}'**
  String teamNowManaging(String name);

  /// No description provided for @errorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetail(String error);

  /// No description provided for @docsTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String docsTotalCount(int count);

  /// No description provided for @colDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get colDocumentType;

  /// No description provided for @colStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get colStatus;

  /// No description provided for @colUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get colUpdated;

  /// No description provided for @colExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get colExpires;

  /// No description provided for @docsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get docsNoneFound;

  /// No description provided for @commentsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Comment'**
  String get commentsCardTitle;

  /// No description provided for @commentsNoRejected.
  ///
  /// In en, this message translates to:
  /// **'No rejected documents with comments'**
  String get commentsNoRejected;

  /// No description provided for @commentsAllGood.
  ///
  /// In en, this message translates to:
  /// **'All documents are in good standing'**
  String get commentsAllGood;

  /// No description provided for @unknownDocument.
  ///
  /// In en, this message translates to:
  /// **'Unknown Document'**
  String get unknownDocument;

  /// No description provided for @commentsActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action required: Update and resubmit'**
  String get commentsActionRequired;

  /// No description provided for @actionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get actionDetails;

  /// No description provided for @adminDashLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the dashboard.'**
  String get adminDashLoadFailed;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @kpiCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get kpiCompanies;

  /// No description provided for @kpiUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get kpiUsers;

  /// No description provided for @adminSearchCompanies.
  ///
  /// In en, this message translates to:
  /// **'Search companies...'**
  String get adminSearchCompanies;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @adminNoCompanies.
  ///
  /// In en, this message translates to:
  /// **'No companies found'**
  String get adminNoCompanies;

  /// No description provided for @categoriesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get categoriesLoading;

  /// No description provided for @categoriesNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get categoriesNoneFound;

  /// No description provided for @docCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 doc} other{{count} docs}}'**
  String docCountShort(int count);

  /// No description provided for @deleteSelectedEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected...'**
  String get deleteSelectedEllipsis;

  /// No description provided for @deleteAllCount.
  ///
  /// In en, this message translates to:
  /// **'Delete All ({count})'**
  String deleteAllCount(int count);

  /// No description provided for @deleteAllDocsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Documents?'**
  String get deleteAllDocsTitle;

  /// No description provided for @deleteAllDocsIn.
  ///
  /// In en, this message translates to:
  /// **'You are about to delete ALL {count} documents in:'**
  String deleteAllDocsIn(int count);

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This action CANNOT be undone!'**
  String get cannotBeUndone;

  /// No description provided for @deleteAllCaps.
  ///
  /// In en, this message translates to:
  /// **'DELETE ALL ({count})'**
  String deleteAllCaps(int count);

  /// No description provided for @selectDocsToDelete.
  ///
  /// In en, this message translates to:
  /// **'Select Documents to Delete'**
  String get selectDocsToDelete;

  /// No description provided for @selectedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String selectedOfTotal(int selected, int total);

  /// No description provided for @actionSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get actionSelectAll;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @unknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown Type'**
  String get unknownType;

  /// No description provided for @docDeleteLine.
  ///
  /// In en, this message translates to:
  /// **'Status: {status} | Files: {files}\nCreated: {date}'**
  String docDeleteLine(String status, int files, String date);

  /// No description provided for @deleteCaps.
  ///
  /// In en, this message translates to:
  /// **'DELETE ({count})'**
  String deleteCaps(int count);

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteDocs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Are you sure you want to delete 1 document?} other{Are you sure you want to delete {count} documents?}}'**
  String confirmDeleteDocs(int count);

  /// No description provided for @deletingDocs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Deleting 1 document...} other{Deleting {count} documents...}}'**
  String deletingDocs(int count);

  /// No description provided for @deletedDocsOk.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{✓ Deleted 1 document} other{✓ Deleted {count} documents}}'**
  String deletedDocsOk(int count);

  /// No description provided for @deletedSomeFailed.
  ///
  /// In en, this message translates to:
  /// **'Deleted {ok}, failed {failed}'**
  String deletedSomeFailed(int ok, int failed);

  /// No description provided for @docsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading documents...'**
  String get docsLoading;

  /// No description provided for @filterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterLabel;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @docsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get docsSearchHint;

  /// No description provided for @docsTryAdjusting.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search criteria'**
  String get docsTryAdjusting;

  /// No description provided for @documentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document} other{{count} documents}}'**
  String documentCount(int count);

  /// No description provided for @unknownDocumentType.
  ///
  /// In en, this message translates to:
  /// **'Unknown Document Type'**
  String get unknownDocumentType;

  /// No description provided for @specification.
  ///
  /// In en, this message translates to:
  /// **'Specification'**
  String get specification;

  /// No description provided for @specNone.
  ///
  /// In en, this message translates to:
  /// **'No specification provided'**
  String get specNone;

  /// No description provided for @lastReviewedShort.
  ///
  /// In en, this message translates to:
  /// **'Last reviewed {date}'**
  String lastReviewedShort(String date);

  /// No description provided for @reviewedSuffix.
  ///
  /// In en, this message translates to:
  /// **' · reviewed {date}'**
  String reviewedSuffix(String date);

  /// No description provided for @uploadedBy.
  ///
  /// In en, this message translates to:
  /// **'Uploaded By'**
  String get uploadedBy;

  /// No description provided for @uploadDate.
  ///
  /// In en, this message translates to:
  /// **'Upload Date'**
  String get uploadDate;

  /// No description provided for @expiryDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDateTitle;

  /// No description provided for @expiryNone.
  ///
  /// In en, this message translates to:
  /// **'No expiry date'**
  String get expiryNone;

  /// No description provided for @statusLabelColon.
  ///
  /// In en, this message translates to:
  /// **'Status: '**
  String get statusLabelColon;

  /// No description provided for @actionViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get actionViewDetails;

  /// No description provided for @filterDocsTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Documents'**
  String get filterDocsTitle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not Applicable'**
  String get notApplicable;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @searchByDocType.
  ///
  /// In en, this message translates to:
  /// **'Search by document type'**
  String get searchByDocType;

  /// No description provided for @unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown Category'**
  String get unknownCategory;

  /// No description provided for @categoryWithName.
  ///
  /// In en, this message translates to:
  /// **'Category: {name}'**
  String categoryWithName(String name);

  /// No description provided for @previousVersion.
  ///
  /// In en, this message translates to:
  /// **'Previous version'**
  String get previousVersion;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @signatures.
  ///
  /// In en, this message translates to:
  /// **'Signatures'**
  String get signatures;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @rejectionComment.
  ///
  /// In en, this message translates to:
  /// **'Rejection Comment:'**
  String get rejectionComment;

  /// No description provided for @photoDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoDefaultName;

  /// No description provided for @trackerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading audit data...'**
  String get trackerLoading;

  /// No description provided for @kpiApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get kpiApproval;

  /// No description provided for @kpiAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get kpiAllClear;

  /// No description provided for @kpiFixRequired.
  ///
  /// In en, this message translates to:
  /// **'Fix required'**
  String get kpiFixRequired;

  /// No description provided for @kpiRejectedItems.
  ///
  /// In en, this message translates to:
  /// **'Rejected Items'**
  String get kpiRejectedItems;

  /// No description provided for @trackerNoApproved.
  ///
  /// In en, this message translates to:
  /// **'No approved documents'**
  String get trackerNoApproved;

  /// No description provided for @trackerNoActionItems.
  ///
  /// In en, this message translates to:
  /// **'No action items found'**
  String get trackerNoActionItems;

  /// No description provided for @filterColon.
  ///
  /// In en, this message translates to:
  /// **'Filter: '**
  String get filterColon;

  /// No description provided for @trackerActionItems.
  ///
  /// In en, this message translates to:
  /// **'Action Items'**
  String get trackerActionItems;

  /// No description provided for @trackerApprovedCurrent.
  ///
  /// In en, this message translates to:
  /// **'Approved & Current'**
  String get trackerApprovedCurrent;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @percentOverall.
  ///
  /// In en, this message translates to:
  /// **'{percent}% overall'**
  String percentOverall(String percent);

  /// No description provided for @trackerNoApprovedCurrent.
  ///
  /// In en, this message translates to:
  /// **'No approved documents that are current and not expiring soon'**
  String get trackerNoApprovedCurrent;

  /// No description provided for @expiredCaps.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get expiredCaps;

  /// No description provided for @expiresSoonCaps.
  ///
  /// In en, this message translates to:
  /// **'EXPIRES SOON'**
  String get expiresSoonCaps;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String daysLeft(int count);

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiresToday;

  /// No description provided for @docExpiredRenew.
  ///
  /// In en, this message translates to:
  /// **'This document has expired and needs to be renewed'**
  String get docExpiredRenew;

  /// No description provided for @docExpiresSoonRenew.
  ///
  /// In en, this message translates to:
  /// **'This document expires soon and may need renewal'**
  String get docExpiresSoonRenew;

  /// No description provided for @commentsColon.
  ///
  /// In en, this message translates to:
  /// **'Comments:'**
  String get commentsColon;

  /// No description provided for @uploadNewVersion.
  ///
  /// In en, this message translates to:
  /// **'Upload New Version'**
  String get uploadNewVersion;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @deleteDocTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Document'**
  String get deleteDocTitle;

  /// No description provided for @deleteDocConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this document?'**
  String get deleteDocConfirm;

  /// No description provided for @deleteDocWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The document and all its files will be permanently deleted.'**
  String get deleteDocWarning;

  /// No description provided for @deletingDoc.
  ///
  /// In en, this message translates to:
  /// **'Deleting document...'**
  String get deletingDoc;

  /// No description provided for @docDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted successfully'**
  String get docDeleted;

  /// No description provided for @docDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete document'**
  String get docDeleteFailed;

  /// No description provided for @docDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting document: {error}'**
  String docDeleteError(String error);

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expiresOn(String date);

  /// No description provided for @noExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'No Expiry Date'**
  String get noExpiryDate;

  /// No description provided for @docTypesNoneInCategory.
  ///
  /// In en, this message translates to:
  /// **'No document types found for this category'**
  String get docTypesNoneInCategory;

  /// No description provided for @docsUploadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 document uploaded} other{{count} documents uploaded}}'**
  String docsUploadedCount(int count);

  /// No description provided for @viewDocuments.
  ///
  /// In en, this message translates to:
  /// **'View Documents'**
  String get viewDocuments;

  /// No description provided for @specNoneShort.
  ///
  /// In en, this message translates to:
  /// **'No specification'**
  String get specNoneShort;

  /// No description provided for @uploadedOn.
  ///
  /// In en, this message translates to:
  /// **'Uploaded: {date}'**
  String uploadedOn(String date);

  /// No description provided for @addAnotherDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Another Document'**
  String get addAnotherDocument;

  /// No description provided for @addAnotherForm.
  ///
  /// In en, this message translates to:
  /// **'Add Another Form'**
  String get addAnotherForm;

  /// No description provided for @actionFillForm.
  ///
  /// In en, this message translates to:
  /// **'Fill Form'**
  String get actionFillForm;

  /// No description provided for @actionAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get actionAddMore;

  /// No description provided for @actionAddForm.
  ///
  /// In en, this message translates to:
  /// **'Add Form'**
  String get actionAddForm;

  /// No description provided for @actionUpdateForm.
  ///
  /// In en, this message translates to:
  /// **'Update Form'**
  String get actionUpdateForm;

  /// No description provided for @statusNotUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not Uploaded'**
  String get statusNotUploaded;

  /// No description provided for @ruleRequiresExpiry.
  ///
  /// In en, this message translates to:
  /// **'Requires expiry date'**
  String get ruleRequiresExpiry;

  /// No description provided for @ruleRequiresSignature.
  ///
  /// In en, this message translates to:
  /// **'Requires signature'**
  String get ruleRequiresSignature;

  /// No description provided for @ruleCanBeNa.
  ///
  /// In en, this message translates to:
  /// **'Can be marked N/A'**
  String get ruleCanBeNa;

  /// No description provided for @catNoDocsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No documents available'**
  String get catNoDocsAvailable;

  /// No description provided for @catCompletedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed: {done} / {total} ({percent}%)'**
  String catCompletedStatus(int done, int total, String percent);

  /// No description provided for @catProgress.
  ///
  /// In en, this message translates to:
  /// **'Category Progress'**
  String get catProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @viewDocument.
  ///
  /// In en, this message translates to:
  /// **'View Document'**
  String get viewDocument;

  /// No description provided for @markNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Mark as Not Applicable'**
  String get markNotApplicable;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason:'**
  String get rejectionReason;

  /// No description provided for @ruleRequiresSignatures.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Requires 1 signature} other{Requires {count} signatures}}'**
  String ruleRequiresSignatures(int count);

  /// No description provided for @reviewedPolicyHelp.
  ///
  /// In en, this message translates to:
  /// **'Date this policy was last reviewed'**
  String get reviewedPolicyHelp;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @uploadSelectFilesError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting files: {error}'**
  String uploadSelectFilesError(String error);

  /// No description provided for @uploadSelectFilesFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select files to upload'**
  String get uploadSelectFilesFirst;

  /// No description provided for @uploadSelectExpiryAll.
  ///
  /// In en, this message translates to:
  /// **'Please select an expiry date for all documents'**
  String get uploadSelectExpiryAll;

  /// No description provided for @uploadNeedSpecPlease.
  ///
  /// In en, this message translates to:
  /// **'Please add a specification — what does this upload cover?'**
  String get uploadNeedSpecPlease;

  /// No description provided for @uploadNeedReviewedPlease.
  ///
  /// In en, this message translates to:
  /// **'Please enter the date this was last reviewed'**
  String get uploadNeedReviewedPlease;

  /// No description provided for @uploadNoContext.
  ///
  /// In en, this message translates to:
  /// **'Error: No user or company context'**
  String get uploadNoContext;

  /// No description provided for @uploadedFileOk.
  ///
  /// In en, this message translates to:
  /// **'Successfully uploaded: {name}'**
  String uploadedFileOk(String name);

  /// No description provided for @uploadedFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload: {name}'**
  String uploadedFileFailed(String name);

  /// No description provided for @uploadedFileError.
  ///
  /// In en, this message translates to:
  /// **'Error uploading: {name}'**
  String uploadedFileError(String name);

  /// No description provided for @uploadAllOk.
  ///
  /// In en, this message translates to:
  /// **'All documents uploaded successfully!'**
  String get uploadAllOk;

  /// No description provided for @uploadSomeFailed.
  ///
  /// In en, this message translates to:
  /// **'{ok} uploaded, {failed} failed'**
  String uploadSomeFailed(int ok, int failed);

  /// No description provided for @uploadAllFailed.
  ///
  /// In en, this message translates to:
  /// **'All uploads failed'**
  String get uploadAllFailed;

  /// No description provided for @uploadDocsError.
  ///
  /// In en, this message translates to:
  /// **'Error uploading documents: {error}'**
  String uploadDocsError(String error);

  /// No description provided for @uploadCardSubtitleExpiry.
  ///
  /// In en, this message translates to:
  /// **'Upload documents and set expiry dates for each'**
  String get uploadCardSubtitleExpiry;

  /// No description provided for @uploadCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload documents for this category'**
  String get uploadCardSubtitle;

  /// No description provided for @uploadSpecHintLong.
  ///
  /// In en, this message translates to:
  /// **'What does this cover? e.g. site, period, worker group'**
  String get uploadSpecHintLong;

  /// No description provided for @uploadSpecHintOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter document specification (optional)'**
  String get uploadSpecHintOptional;

  /// No description provided for @uploadChooseReviewDate.
  ///
  /// In en, this message translates to:
  /// **'Choose the review date'**
  String get uploadChooseReviewDate;

  /// No description provided for @uploadTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select files'**
  String get uploadTapToSelect;

  /// No description provided for @uploadSupportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: PDF, JPG, JPEG, PNG, DOC, DOCX'**
  String get uploadSupportedFormats;

  /// No description provided for @uploadSelectedDocsTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected Documents ({count})'**
  String uploadSelectedDocsTitle(int count);

  /// No description provided for @actionSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set Date'**
  String get actionSetDate;

  /// No description provided for @uploadingDocs.
  ///
  /// In en, this message translates to:
  /// **'Uploading Documents...'**
  String get uploadingDocs;

  /// No description provided for @uploadingDoc.
  ///
  /// In en, this message translates to:
  /// **'Uploading Document...'**
  String get uploadingDoc;

  /// No description provided for @uploadNDocs.
  ///
  /// In en, this message translates to:
  /// **'Upload {count} Documents'**
  String uploadNDocs(int count);

  /// No description provided for @uploadOneDoc.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadOneDoc;

  /// No description provided for @uploadSelectAndUpload.
  ///
  /// In en, this message translates to:
  /// **'Select and Upload Documents'**
  String get uploadSelectAndUpload;

  /// No description provided for @docDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Details'**
  String get docDetailsTitle;

  /// No description provided for @docLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading document...'**
  String get docLoading;

  /// No description provided for @docLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading document: {error}'**
  String docLoadError(String error);

  /// No description provided for @docNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This document is not available.'**
  String get docNotAvailable;

  /// No description provided for @docNotFound.
  ///
  /// In en, this message translates to:
  /// **'Document not found'**
  String get docNotFound;

  /// No description provided for @bannerExpired.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT EXPIRED'**
  String get bannerExpired;

  /// No description provided for @bannerExpiredSub.
  ///
  /// In en, this message translates to:
  /// **'This document has expired and needs to be updated'**
  String get bannerExpiredSub;

  /// No description provided for @bannerRejected.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENT REJECTED'**
  String get bannerRejected;

  /// No description provided for @bannerRejectedSub.
  ///
  /// In en, this message translates to:
  /// **'Please review the feedback and resubmit'**
  String get bannerRejectedSub;

  /// No description provided for @bannerPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING REVIEW'**
  String get bannerPending;

  /// No description provided for @bannerAwaitingYou.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your review'**
  String get bannerAwaitingYou;

  /// No description provided for @bannerAwaitingAdmin.
  ///
  /// In en, this message translates to:
  /// **'Awaiting admin review'**
  String get bannerAwaitingAdmin;

  /// No description provided for @bannerValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String bannerValidUntil(String date);

  /// No description provided for @bannerApproved.
  ///
  /// In en, this message translates to:
  /// **'Document is approved'**
  String get bannerApproved;

  /// No description provided for @bannerApprovedCaps.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get bannerApprovedCaps;

  /// No description provided for @bannerUnknown.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN STATUS'**
  String get bannerUnknown;

  /// No description provided for @docInformation.
  ///
  /// In en, this message translates to:
  /// **'Document Information'**
  String get docInformation;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @resubmitDocCaps.
  ///
  /// In en, this message translates to:
  /// **'RESUBMIT DOCUMENT'**
  String get resubmitDocCaps;

  /// No description provided for @uploadNewVersionCaps.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD NEW VERSION'**
  String get uploadNewVersionCaps;

  /// No description provided for @addSignatureCaps.
  ///
  /// In en, this message translates to:
  /// **'ADD SIGNATURE ({done}/{total})'**
  String addSignatureCaps(int done, int total);

  /// No description provided for @docFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Document Files ({count})'**
  String docFilesCount(int count);

  /// No description provided for @noFilesUploaded.
  ///
  /// In en, this message translates to:
  /// **'No files uploaded'**
  String get noFilesUploaded;

  /// No description provided for @commentsHistoryCount.
  ///
  /// In en, this message translates to:
  /// **'Comments & History ({count})'**
  String commentsHistoryCount(int count);

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @adminReview.
  ///
  /// In en, this message translates to:
  /// **'Admin Review'**
  String get adminReview;

  /// No description provided for @editSpecHint.
  ///
  /// In en, this message translates to:
  /// **'Edit document specification (optional)...'**
  String get editSpecHint;

  /// No description provided for @strayExpiryNote.
  ///
  /// In en, this message translates to:
  /// **'This document type does not use an expiry date. Clear it so the document never shows as expired.'**
  String get strayExpiryNote;

  /// No description provided for @selectExpiryOptional.
  ///
  /// In en, this message translates to:
  /// **'Select expiry date (optional)'**
  String get selectExpiryOptional;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @commentHintReject.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (required for rejection)...'**
  String get commentHintReject;

  /// No description provided for @reviewSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Changes to specification and expiry date will be saved when you approve or reject.'**
  String get reviewSaveNote;

  /// No description provided for @selectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select Expiry Date'**
  String get selectExpiryDate;

  /// No description provided for @actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// No description provided for @addYourSignature.
  ///
  /// In en, this message translates to:
  /// **'Add Your Signature'**
  String get addYourSignature;

  /// No description provided for @signatureAdded.
  ///
  /// In en, this message translates to:
  /// **'Signature added successfully'**
  String get signatureAdded;

  /// No description provided for @rejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejection'**
  String get rejectReasonRequired;

  /// No description provided for @docApprovedOk.
  ///
  /// In en, this message translates to:
  /// **'Document approved'**
  String get docApprovedOk;

  /// No description provided for @docRejectedOk.
  ///
  /// In en, this message translates to:
  /// **'Document rejected'**
  String get docRejectedOk;

  /// No description provided for @docTypeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading document type...'**
  String get docTypeLoading;

  /// No description provided for @docTypeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Document type not found'**
  String get docTypeNotFound;

  /// No description provided for @selectExpiryPlease.
  ///
  /// In en, this message translates to:
  /// **'Please select an expiry date'**
  String get selectExpiryPlease;

  /// No description provided for @docCreated.
  ///
  /// In en, this message translates to:
  /// **'Document created successfully'**
  String get docCreated;

  /// No description provided for @formSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Error submitting form: {error}'**
  String formSubmitError(String error);

  /// No description provided for @fillDocForm.
  ///
  /// In en, this message translates to:
  /// **'Fill Document Form'**
  String get fillDocForm;

  /// No description provided for @fillTypeName.
  ///
  /// In en, this message translates to:
  /// **'Fill {type}'**
  String fillTypeName(String type);

  /// No description provided for @selectExpiryDateLower.
  ///
  /// In en, this message translates to:
  /// **'Select expiry date'**
  String get selectExpiryDateLower;

  /// No description provided for @submitForm.
  ///
  /// In en, this message translates to:
  /// **'Submit Form'**
  String get submitForm;

  /// No description provided for @reportLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading compliance data...'**
  String get reportLoading;

  /// No description provided for @reportComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get reportComplete;

  /// No description provided for @updatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated: {date}'**
  String updatedOn(String date);

  /// No description provided for @notifUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notifUnreadCount(int count);

  /// No description provided for @notifAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notifAllCaughtUp;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notifMarkAllRead;

  /// No description provided for @notifNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifNoneYet;

  /// No description provided for @notifEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'You’ll be notified about rejections and expiring documents.'**
  String get notifEmptyHint;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @farmsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your farms.'**
  String get farmsLoadFailed;

  /// No description provided for @farmOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open this farm. Please try again.'**
  String get farmOpenFailed;

  /// No description provided for @farmsAuditorCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You can review approved documents for 1 farm.} other{You can review approved documents for {count} farms.}}'**
  String farmsAuditorCount(int count);

  /// No description provided for @farmsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search farms...'**
  String get farmsSearchHint;

  /// No description provided for @farmsNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No farms found'**
  String get farmsNoneFound;

  /// No description provided for @farmCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get farmCurrent;

  /// No description provided for @docFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Files'**
  String get docFilesTitle;

  /// No description provided for @imagePreview.
  ///
  /// In en, this message translates to:
  /// **'Image Preview'**
  String get imagePreview;

  /// No description provided for @openingInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opening in browser...'**
  String get openingInBrowser;

  /// No description provided for @fileViewError.
  ///
  /// In en, this message translates to:
  /// **'Error viewing file: {error}'**
  String fileViewError(String error);

  /// No description provided for @urlOpenError.
  ///
  /// In en, this message translates to:
  /// **'Error opening URL: {error}'**
  String urlOpenError(String error);

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @signFirst.
  ///
  /// In en, this message translates to:
  /// **'Please sign before saving'**
  String get signFirst;

  /// No description provided for @signatureSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving signature: {error}'**
  String signatureSaveError(String error);

  /// No description provided for @psEnterHoursFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter hours for at least one employee first.'**
  String get psEnterHoursFirst;

  /// No description provided for @psSaveFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get psSaveFailedShort;

  /// No description provided for @psSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payslip saved} other{{count} payslips saved}}'**
  String psSavedCount(int count);

  /// No description provided for @psSavedSomeFailed.
  ///
  /// In en, this message translates to:
  /// **'{ok} saved, {failed} failed'**
  String psSavedSomeFailed(int ok, int failed);

  /// No description provided for @psFamilyLeaveNeedsStart.
  ///
  /// In en, this message translates to:
  /// **'Family leave starts once an employment start date is set — add it via Edit employee if it should apply.'**
  String get psFamilyLeaveNeedsStart;

  /// No description provided for @psDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Payslip'**
  String get psDeleteTitle;

  /// No description provided for @psNetAmount.
  ///
  /// In en, this message translates to:
  /// **'Net: {amount}'**
  String psNetAmount(String amount);

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @employeeAdded.
  ///
  /// In en, this message translates to:
  /// **'Employee added'**
  String get employeeAdded;

  /// No description provided for @employeeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Employee updated'**
  String get employeeUpdated;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save'**
  String get couldNotSave;

  /// No description provided for @employeeRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Employee'**
  String get employeeRemoveTitle;

  /// No description provided for @employeeRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}? Their payslips are kept. If you add them again later, use the same ID number so old payslips link back to them (e.g. for bank payments).'**
  String employeeRemoveBody(String name);

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @companyFallback.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyFallback;

  /// No description provided for @psAllPdfName.
  ///
  /// In en, this message translates to:
  /// **'{company} Payslips.pdf'**
  String psAllPdfName(String company);

  /// No description provided for @payeTax.
  ///
  /// In en, this message translates to:
  /// **'PAYE (Tax)'**
  String get payeTax;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'weekly'**
  String get freqWeekly;

  /// No description provided for @freqFortnightly.
  ///
  /// In en, this message translates to:
  /// **'fortnightly'**
  String get freqFortnightly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get freqMonthly;

  /// No description provided for @payeAutoAmount.
  ///
  /// In en, this message translates to:
  /// **'Auto ({freq}): {amount}'**
  String payeAutoAmount(String freq, String amount);

  /// No description provided for @payeAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYE amount (R)'**
  String get payeAmountLabel;

  /// No description provided for @payeBlankAuto.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use auto'**
  String get payeBlankAuto;

  /// No description provided for @payeUseAuto.
  ///
  /// In en, this message translates to:
  /// **'Use auto'**
  String get payeUseAuto;

  /// No description provided for @payeManualNote.
  ///
  /// In en, this message translates to:
  /// **'Manual PAYE — this exact amount will be used.'**
  String get payeManualNote;

  /// No description provided for @payeAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Auto PAYE is calculated on the taxable gross for this {freq} period.'**
  String payeAutoNote(String freq);

  /// No description provided for @additionalDeductions.
  ///
  /// In en, this message translates to:
  /// **'Additional Deductions'**
  String get additionalDeductions;

  /// No description provided for @noDeductionsYet.
  ///
  /// In en, this message translates to:
  /// **'No deductions yet'**
  String get noDeductionsYet;

  /// No description provided for @fieldReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get fieldReason;

  /// No description provided for @fieldAmountR.
  ///
  /// In en, this message translates to:
  /// **'Amount (R)'**
  String get fieldAmountR;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String totalAmount(String amount);

  /// No description provided for @addDeduction.
  ///
  /// In en, this message translates to:
  /// **'Add Deduction'**
  String get addDeduction;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @additionalIncome.
  ///
  /// In en, this message translates to:
  /// **'Additional Income'**
  String get additionalIncome;

  /// No description provided for @noAdditionsYet.
  ///
  /// In en, this message translates to:
  /// **'No additions yet'**
  String get noAdditionsYet;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get addIncome;

  /// No description provided for @uifSummary.
  ///
  /// In en, this message translates to:
  /// **'UIF Summary'**
  String get uifSummary;

  /// No description provided for @noPayslipsForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No payslips for this period.'**
  String get noPayslipsForPeriod;

  /// No description provided for @pdfError.
  ///
  /// In en, this message translates to:
  /// **'PDF error: {error}'**
  String pdfError(String error);

  /// No description provided for @downloadUifPdf.
  ///
  /// In en, this message translates to:
  /// **'Download UIF Summary PDF'**
  String get downloadUifPdf;

  /// No description provided for @colEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get colEmployee;

  /// No description provided for @colEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get colEarnings;

  /// No description provided for @colTotalDed.
  ///
  /// In en, this message translates to:
  /// **'Total Ded'**
  String get colTotalDed;

  /// No description provided for @companyColon.
  ///
  /// In en, this message translates to:
  /// **'Company:'**
  String get companyColon;

  /// No description provided for @selectCompany.
  ///
  /// In en, this message translates to:
  /// **'Select a company'**
  String get selectCompany;

  /// No description provided for @defaultStart.
  ///
  /// In en, this message translates to:
  /// **'Default Start'**
  String get defaultStart;

  /// No description provided for @defaultEnd.
  ///
  /// In en, this message translates to:
  /// **'Default End'**
  String get defaultEnd;

  /// No description provided for @fillsAllRows.
  ///
  /// In en, this message translates to:
  /// **'fills all rows'**
  String get fillsAllRows;

  /// No description provided for @payDate.
  ///
  /// In en, this message translates to:
  /// **'Pay Date'**
  String get payDate;

  /// No description provided for @companyAddressOnPayslip.
  ///
  /// In en, this message translates to:
  /// **'Company Address (on payslip)'**
  String get companyAddressOnPayslip;

  /// No description provided for @companyAddress.
  ///
  /// In en, this message translates to:
  /// **'Company Address'**
  String get companyAddress;

  /// No description provided for @tapToSet.
  ///
  /// In en, this message translates to:
  /// **'Tap to set'**
  String get tapToSet;

  /// No description provided for @employerUifRegNr.
  ///
  /// In en, this message translates to:
  /// **'Employer UIF Reg Nr'**
  String get employerUifRegNr;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveChangesCount.
  ///
  /// In en, this message translates to:
  /// **'Save Changes ({count})'**
  String saveChangesCount(int count);

  /// No description provided for @saveAllCount.
  ///
  /// In en, this message translates to:
  /// **'Save All ({count})'**
  String saveAllCount(int count);

  /// No description provided for @savePayslipsCount.
  ///
  /// In en, this message translates to:
  /// **'Save Payslips ({count})'**
  String savePayslipsCount(int count);

  /// No description provided for @savePayslips.
  ///
  /// In en, this message translates to:
  /// **'Save Payslips'**
  String get savePayslips;

  /// No description provided for @timesheet.
  ///
  /// In en, this message translates to:
  /// **'Timesheet'**
  String get timesheet;

  /// No description provided for @leaveRecords.
  ///
  /// In en, this message translates to:
  /// **'Leave Records'**
  String get leaveRecords;

  /// No description provided for @payslipRecords.
  ///
  /// In en, this message translates to:
  /// **'Payslip Records'**
  String get payslipRecords;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @noEmployeesFound.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get noEmployeesFound;

  /// No description provided for @colIdNumber.
  ///
  /// In en, this message translates to:
  /// **'ID Number'**
  String get colIdNumber;

  /// No description provided for @colNetPay.
  ///
  /// In en, this message translates to:
  /// **'Net Pay'**
  String get colNetPay;

  /// No description provided for @colPayslipPeriod.
  ///
  /// In en, this message translates to:
  /// **'Payslip Period'**
  String get colPayslipPeriod;

  /// No description provided for @employeePermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent employee'**
  String get employeePermanent;

  /// No description provided for @employeeSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal worker'**
  String get employeeSeasonal;

  /// No description provided for @bankingOnFile.
  ///
  /// In en, this message translates to:
  /// **'Banking details on file — included in Bank CSV'**
  String get bankingOnFile;

  /// No description provided for @bankingIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Banking details incomplete ({issues}) — not included in Bank CSV'**
  String bankingIncomplete(String issues);

  /// No description provided for @editEmployeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit employee details'**
  String get editEmployeeDetails;

  /// No description provided for @removeEmployee.
  ///
  /// In en, this message translates to:
  /// **'Remove employee'**
  String get removeEmployee;

  /// No description provided for @editThisPayslip.
  ///
  /// In en, this message translates to:
  /// **'Edit this payslip'**
  String get editThisPayslip;

  /// No description provided for @cancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel edit'**
  String get cancelEdit;

  /// No description provided for @addIncomeLower.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncomeLower;

  /// No description provided for @additionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 addition} other{{count} additions}}'**
  String additionsCount(int count);

  /// No description provided for @noAdditionsEditToAdd.
  ///
  /// In en, this message translates to:
  /// **'No additions (edit to add)'**
  String get noAdditionsEditToAdd;

  /// No description provided for @additionsEditToChange.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 addition (edit to change)} other{{count} additions (edit to change)}}'**
  String additionsEditToChange(int count);

  /// No description provided for @addDeductionsLower.
  ///
  /// In en, this message translates to:
  /// **'Add deductions'**
  String get addDeductionsLower;

  /// No description provided for @deductionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 deduction} other{{count} deductions}}'**
  String deductionsCount(int count);

  /// No description provided for @noDeductionsEditToAdd.
  ///
  /// In en, this message translates to:
  /// **'No deductions (edit to add)'**
  String get noDeductionsEditToAdd;

  /// No description provided for @deductionsEditToChange.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 deduction (edit to change)} other{{count} deductions (edit to change)}}'**
  String deductionsEditToChange(int count);

  /// No description provided for @deletePayslip.
  ///
  /// In en, this message translates to:
  /// **'Delete payslip'**
  String get deletePayslip;

  /// No description provided for @finishEditingFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish editing first'**
  String get finishEditingFirst;

  /// No description provided for @newPayslip.
  ///
  /// In en, this message translates to:
  /// **'New Payslip'**
  String get newPayslip;

  /// No description provided for @searchEmployees.
  ///
  /// In en, this message translates to:
  /// **'Search employees…'**
  String get searchEmployees;

  /// No description provided for @showingRange.
  ///
  /// In en, this message translates to:
  /// **'Showing {from}–{to} of {total}'**
  String showingRange(int from, int to, int total);

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// No description provided for @selectCompanyForPayslips.
  ///
  /// In en, this message translates to:
  /// **'Select a company to manage payslips'**
  String get selectCompanyForPayslips;

  /// No description provided for @addFirstEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add First Employee'**
  String get addFirstEmployee;

  /// No description provided for @tsLinePhWorkedNormal.
  ///
  /// In en, this message translates to:
  /// **'Public holiday worked ({date}, {hours} h): greater of 2 × daily wage or daily wage {daily} + {hours} h × {rate}'**
  String tsLinePhWorkedNormal(
      String date, String hours, String daily, String rate);

  /// No description provided for @tsLinePhWorkedOff.
  ///
  /// In en, this message translates to:
  /// **'Public holiday worked ({date}, {hours} h): daily wage {daily} + {hours} h × {rate}'**
  String tsLinePhWorkedOff(
      String date, String hours, String daily, String rate);

  /// No description provided for @tsLineSundayMin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sunday minimum pay (1 day: at least the daily wage {daily})} other{Sunday minimum pay ({count} days: at least the daily wage {daily})}}'**
  String tsLineSundayMin(int count, Object daily);

  /// No description provided for @tsLineNight.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Night-shift allowance (1 day × {perDay})} other{Night-shift allowance ({count} days × {perDay})}}'**
  String tsLineNight(int count, Object perDay);

  /// No description provided for @tsLinePiece.
  ///
  /// In en, this message translates to:
  /// **'Piecework: {units} {unit} × {rate} ({task})'**
  String tsLinePiece(String units, String unit, String rate, String task);

  /// No description provided for @tsLineTopUpDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Minimum wage top-up (1 day below {wage}/h)} other{Minimum wage top-up ({count} days below {wage}/h)}}'**
  String tsLineTopUpDays(int count, Object wage);

  /// No description provided for @tsLineTopUpWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Minimum wage top-up (1 week below {wage}/h)} other{Minimum wage top-up ({count} weeks below {wage}/h)}}'**
  String tsLineTopUpWeeks(int count, Object wage);

  /// No description provided for @tsWarnDay.
  ///
  /// In en, this message translates to:
  /// **'{hours} h on {date} (over {limit} h a day)'**
  String tsWarnDay(String hours, String date, String limit);

  /// No description provided for @tsWarnWeek.
  ///
  /// In en, this message translates to:
  /// **'{hours} h overtime in week of {week} (over {limit} h)'**
  String tsWarnWeek(String hours, String week, String limit);

  /// No description provided for @periodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get periodWeekly;

  /// No description provided for @periodFortnightly.
  ///
  /// In en, this message translates to:
  /// **'Fortnightly'**
  String get periodFortnightly;

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @leaveSick.
  ///
  /// In en, this message translates to:
  /// **'sick leave'**
  String get leaveSick;

  /// No description provided for @leaveAnnual.
  ///
  /// In en, this message translates to:
  /// **'annual (holiday) leave'**
  String get leaveAnnual;

  /// No description provided for @leaveFamily.
  ///
  /// In en, this message translates to:
  /// **'family responsibility leave'**
  String get leaveFamily;

  /// No description provided for @tsLoadPeriodFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load that period: {error}'**
  String tsLoadPeriodFailed(String error);

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @tsUnsavedBody.
  ///
  /// In en, this message translates to:
  /// **'You have changes on this timesheet that are not saved yet.'**
  String get tsUnsavedBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChanges;

  /// No description provided for @tsFixRedCells.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Fix the red cell first (hours like 9 or 7.5, codes SL / AL / PH / A, finish times like 21:30).} other{Fix the {count} red cells first (hours like 9 or 7.5, codes SL / AL / PH / A, finish times like 21:30).}}'**
  String tsFixRedCells(int count);

  /// No description provided for @tsSavedUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saved · 1 payslip updated} other{Saved · {count} payslips updated}}'**
  String tsSavedUpdated(int count);

  /// No description provided for @tsSavedSkipped.
  ///
  /// In en, this message translates to:
  /// **'{skipped} waiting for rates (see the banner)'**
  String tsSavedSkipped(int skipped);

  /// No description provided for @saveFailedError.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailedError(String error);

  /// No description provided for @tsFinaliseTitle.
  ///
  /// In en, this message translates to:
  /// **'Finalise period?'**
  String get tsFinaliseTitle;

  /// No description provided for @tsFinaliseBody.
  ///
  /// In en, this message translates to:
  /// **'This saves the timesheet, locks all three sheets for {start} – {end} and finalises the payslips. You can unlock it again if something needs fixing.'**
  String tsFinaliseBody(String start, String end);

  /// No description provided for @tsFinalisePeriod.
  ///
  /// In en, this message translates to:
  /// **'Finalise period'**
  String get tsFinalisePeriod;

  /// No description provided for @tsUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock this period?'**
  String get tsUnlockTitle;

  /// No description provided for @tsUnlockBody.
  ///
  /// In en, this message translates to:
  /// **'The sheets become editable again and the payslips go back to Draft until you finalise again. This is recorded in the audit log.'**
  String get tsUnlockBody;

  /// No description provided for @actionUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get actionUnlock;

  /// No description provided for @tsFinalisedToast.
  ///
  /// In en, this message translates to:
  /// **'Period finalised — sheets locked, payslips finalised'**
  String get tsFinalisedToast;

  /// No description provided for @tsUnlockedToast.
  ///
  /// In en, this message translates to:
  /// **'Period unlocked — payslips are Draft again'**
  String get tsUnlockedToast;

  /// No description provided for @tsPeriodUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the period: {error}'**
  String tsPeriodUpdateFailed(String error);

  /// No description provided for @tsNeedRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Some payslips need rates first'**
  String get tsNeedRatesTitle;

  /// No description provided for @tsNeedRatesBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payslip ({names}) can’t be calculated until these are set: {missing}.} other{{count} payslips ({names}) can’t be calculated until these are set: {missing}.}}'**
  String tsNeedRatesBody(int count, Object missing, Object names);

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @setThemNow.
  ///
  /// In en, this message translates to:
  /// **'Set them now'**
  String get setThemNow;

  /// No description provided for @tsRatesSaved.
  ///
  /// In en, this message translates to:
  /// **'Rates saved — press Save to update the payslips'**
  String get tsRatesSaved;

  /// No description provided for @tsRatesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save rates: {error}'**
  String tsRatesSaveFailed(String error);

  /// No description provided for @tsPieceRateAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add the piece rate: {error}'**
  String tsPieceRateAddFailed(String error);

  /// No description provided for @tsPayPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} pay period'**
  String tsPayPeriodTitle(String type);

  /// No description provided for @tsChooseStartDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a start date…'**
  String get tsChooseStartDate;

  /// No description provided for @tsFirstDayHelp.
  ///
  /// In en, this message translates to:
  /// **'First day of the pay period'**
  String get tsFirstDayHelp;

  /// No description provided for @tsTitle.
  ///
  /// In en, this message translates to:
  /// **'Timesheet – {company}'**
  String tsTitle(String company);

  /// No description provided for @tsRates.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get tsRates;

  /// No description provided for @tsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The timesheet could not be loaded.'**
  String get tsLoadFailed;

  /// No description provided for @tsNormalHours.
  ///
  /// In en, this message translates to:
  /// **'Normal hours'**
  String get tsNormalHours;

  /// No description provided for @tsOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get tsOvertime;

  /// No description provided for @tsPiecework.
  ///
  /// In en, this message translates to:
  /// **'Piecework'**
  String get tsPiecework;

  /// No description provided for @tsPayPeriod.
  ///
  /// In en, this message translates to:
  /// **'Pay period'**
  String get tsPayPeriod;

  /// No description provided for @tsDaysWorkers.
  ///
  /// In en, this message translates to:
  /// **'{days} days · {count, plural, =1{1 worker} other{{count} workers}}'**
  String tsDaysWorkers(int days, int count);

  /// No description provided for @tsNsLegend.
  ///
  /// In en, this message translates to:
  /// **'NS = night work (finish after 20:00, before 04:00)'**
  String get tsNsLegend;

  /// No description provided for @tsFinalised.
  ///
  /// In en, this message translates to:
  /// **'Finalised'**
  String get tsFinalised;

  /// No description provided for @tsFinalisedBy.
  ///
  /// In en, this message translates to:
  /// **'Finalised by {name}'**
  String tsFinalisedBy(String name);

  /// No description provided for @tsPieceRate.
  ///
  /// In en, this message translates to:
  /// **'Piece rate'**
  String get tsPieceRate;

  /// No description provided for @chooseEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Choose…'**
  String get chooseEllipsis;

  /// No description provided for @tsAddPieceRateMenu.
  ///
  /// In en, this message translates to:
  /// **'+ Add piece rate…'**
  String get tsAddPieceRateMenu;

  /// No description provided for @tsNotUpdatedBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payslip not updated yet — set: {missing}.} other{{count} payslips not updated yet — set: {missing}.}}'**
  String tsNotUpdatedBanner(int count, Object missing);

  /// No description provided for @colHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get colHours;

  /// No description provided for @colLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get colLeave;

  /// No description provided for @colComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get colComment;

  /// No description provided for @colOtHours.
  ///
  /// In en, this message translates to:
  /// **'OT hours'**
  String get colOtHours;

  /// No description provided for @colNsDays.
  ///
  /// In en, this message translates to:
  /// **'NS days'**
  String get colNsDays;

  /// No description provided for @colUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get colUnits;

  /// No description provided for @colPiecePay.
  ///
  /// In en, this message translates to:
  /// **'Piece pay'**
  String get colPiecePay;

  /// No description provided for @colTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top-up'**
  String get colTopUp;

  /// No description provided for @tsNoEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees yet.'**
  String get tsNoEmployees;

  /// No description provided for @tsAddEmployeesHint.
  ///
  /// In en, this message translates to:
  /// **'Add employees in the Payslip Manager'**
  String get tsAddEmployeesHint;

  /// No description provided for @colWorker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get colWorker;

  /// No description provided for @tsPhTooltip.
  ///
  /// In en, this message translates to:
  /// **'Public holiday. Not worked: type PH (paid one daily wage). Worked: type the hours — paid per SD13 (greater of 2 × daily wage or daily wage + hours, on a normal work day).'**
  String get tsPhTooltip;

  /// No description provided for @tsSundayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sunday: hours worked are paid at double the ordinary wage, and at least the daily wage (SD13).'**
  String get tsSundayTooltip;

  /// No description provided for @tsBelowMinTooltip.
  ///
  /// In en, this message translates to:
  /// **'Piece pay is below the minimum wage — a top-up is added to the payslip.'**
  String get tsBelowMinTooltip;

  /// No description provided for @tsOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get tsOk;

  /// No description provided for @viewPayslip.
  ///
  /// In en, this message translates to:
  /// **'View payslip'**
  String get viewPayslip;

  /// No description provided for @viewDraft.
  ///
  /// In en, this message translates to:
  /// **'View draft'**
  String get viewDraft;

  /// No description provided for @tsSummaryNormal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Normal hours · All workers · Hours {hours} · Leave / absent 1 day} other{Normal hours · All workers · Hours {hours} · Leave / absent {count} days}}'**
  String tsSummaryNormal(int count, Object hours);

  /// No description provided for @tsSummaryOvertime.
  ///
  /// In en, this message translates to:
  /// **'Overtime · All workers · OT hours {hours} · Night-shift days {ns}'**
  String tsSummaryOvertime(String hours, int ns);

  /// No description provided for @tsSummaryPiece.
  ///
  /// In en, this message translates to:
  /// **'Piecework · All workers · Units {units}'**
  String tsSummaryPiece(String units);

  /// No description provided for @tsChoosePieceRateSuffix.
  ///
  /// In en, this message translates to:
  /// **' · choose a piece rate'**
  String get tsChoosePieceRateSuffix;

  /// No description provided for @tsHelpNormal.
  ///
  /// In en, this message translates to:
  /// **'Type the hours worked (9, 7.5…) in each day. Leave goes in with the leave codes above the grid. Overtime and piecework go on their own sheets.'**
  String get tsHelpNormal;

  /// No description provided for @tsHelpOvertime.
  ///
  /// In en, this message translates to:
  /// **'Each day: overtime hours + finish time. NS is marked automatically when the finish time is after 20:00 or before 04:00 (SD13 cl 17) and adds a night-shift allowance line to the payslip.'**
  String get tsHelpOvertime;

  /// No description provided for @tsHelpPiece.
  ///
  /// In en, this message translates to:
  /// **'Each day: hours worked + units. Piece pay = units × the piece rate. Top-up is flagged when piece pay is below the minimum wage for the hours worked.'**
  String get tsHelpPiece;

  /// No description provided for @tsRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Timesheet rates'**
  String get tsRatesTitle;

  /// No description provided for @tsRatesConfirmedNote.
  ///
  /// In en, this message translates to:
  /// **'Confirmed figures: overtime 1.5×, night-shift 10% of the daily wage per night-shift day, minimum wage R30.23 (check each March). Sundays and public holidays are paid per SD13 automatically. Leave a field blank and the payslips that need it show “R —” until it’s set.'**
  String get tsRatesConfirmedNote;

  /// No description provided for @tsFillConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Fill in the confirmed figures'**
  String get tsFillConfirmed;

  /// No description provided for @tsOtMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Overtime multiplier'**
  String get tsOtMultiplier;

  /// No description provided for @tsOtMultiplierHelp.
  ///
  /// In en, this message translates to:
  /// **'SD13 cl 14: at least 1.5 × the wage.'**
  String get tsOtMultiplierHelp;

  /// No description provided for @tsNightAllowance.
  ///
  /// In en, this message translates to:
  /// **'Night-shift allowance (% of ordinary daily wage)'**
  String get tsNightAllowance;

  /// No description provided for @tsNightAllowanceHelp.
  ///
  /// In en, this message translates to:
  /// **'SD13 cl 17: at least 10%, per day with night work.'**
  String get tsNightAllowanceHelp;

  /// No description provided for @tsMinWage.
  ///
  /// In en, this message translates to:
  /// **'Minimum wage per ordinary hour (R)'**
  String get tsMinWage;

  /// No description provided for @tsMinWageHelp.
  ///
  /// In en, this message translates to:
  /// **'Farm-worker NMW from 1 March 2026: R30.23 — check the current gazette.'**
  String get tsMinWageHelp;

  /// No description provided for @tsDayHours.
  ///
  /// In en, this message translates to:
  /// **'Ordinary hours per day'**
  String get tsDayHours;

  /// No description provided for @tsDayHoursHelp.
  ///
  /// In en, this message translates to:
  /// **'Used for leave days (SL / AL / PH) and the daily wage.'**
  String get tsDayHoursHelp;

  /// No description provided for @tsWarnWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Warn above overtime hours per week'**
  String get tsWarnWeekLabel;

  /// No description provided for @tsWarnWeekHelp.
  ///
  /// In en, this message translates to:
  /// **'SD13 cl 13: max 15 h overtime a week (warning only).'**
  String get tsWarnWeekHelp;

  /// No description provided for @tsWarnDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Warn above total hours per day'**
  String get tsWarnDayLabel;

  /// No description provided for @tsWarnDayHelp.
  ///
  /// In en, this message translates to:
  /// **'SD13 cl 13: max 12 h a day including overtime (warning only).'**
  String get tsWarnDayHelp;

  /// No description provided for @tsTopUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum-wage top-up for piecework'**
  String get tsTopUpTitle;

  /// No description provided for @tsTopUpHelp.
  ///
  /// In en, this message translates to:
  /// **'Checked per day or per week, depending on this farm. Workers below the minimum are shown in red.'**
  String get tsTopUpHelp;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get perDay;

  /// No description provided for @perWeek.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get perWeek;

  /// No description provided for @tsWorkDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Normal work days'**
  String get tsWorkDaysTitle;

  /// No description provided for @tsWorkDaysHelp.
  ///
  /// In en, this message translates to:
  /// **'Decides how a worked public holiday is paid: on a normal work day the greater of 2 × daily wage or daily wage + hours; otherwise daily wage + hours.'**
  String get tsWorkDaysHelp;

  /// No description provided for @tsSaveRates.
  ///
  /// In en, this message translates to:
  /// **'Save rates'**
  String get tsSaveRates;

  /// No description provided for @tsAddPieceRate.
  ///
  /// In en, this message translates to:
  /// **'Add piece rate'**
  String get tsAddPieceRate;

  /// No description provided for @tsTaskOrCrop.
  ///
  /// In en, this message translates to:
  /// **'Task or crop'**
  String get tsTaskOrCrop;

  /// No description provided for @tsTaskHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Harvest'**
  String get tsTaskHint;

  /// No description provided for @tsTaskRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the task or crop'**
  String get tsTaskRequired;

  /// No description provided for @tsUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get tsUnit;

  /// No description provided for @tsUnitHint.
  ///
  /// In en, this message translates to:
  /// **'bins, crates, …'**
  String get tsUnitHint;

  /// No description provided for @tsUnitDefault.
  ///
  /// In en, this message translates to:
  /// **'bins'**
  String get tsUnitDefault;

  /// No description provided for @tsUnitRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the unit'**
  String get tsUnitRequired;

  /// No description provided for @tsRatePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Rate per unit (R)'**
  String get tsRatePerUnit;

  /// No description provided for @tsRatePerUnitHelp.
  ///
  /// In en, this message translates to:
  /// **'From your configured tariff — not an example figure.'**
  String get tsRatePerUnitHelp;

  /// No description provided for @tsRateRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the rate per unit'**
  String get tsRateRequired;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @missOvertime.
  ///
  /// In en, this message translates to:
  /// **'overtime multiplier'**
  String get missOvertime;

  /// No description provided for @missNight.
  ///
  /// In en, this message translates to:
  /// **'night-shift allowance %'**
  String get missNight;

  /// No description provided for @missPieceRate.
  ///
  /// In en, this message translates to:
  /// **'piece rate'**
  String get missPieceRate;

  /// No description provided for @missMinWage.
  ///
  /// In en, this message translates to:
  /// **'minimum hourly wage'**
  String get missMinWage;

  /// No description provided for @missTopUp.
  ///
  /// In en, this message translates to:
  /// **'top-up per day or per week'**
  String get missTopUp;

  /// No description provided for @missWorkDays.
  ///
  /// In en, this message translates to:
  /// **'normal work days'**
  String get missWorkDays;

  /// No description provided for @leaveRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Records – {company}'**
  String leaveRecordsTitle(String company);

  /// No description provided for @noEmployeesFoundDot.
  ///
  /// In en, this message translates to:
  /// **'No employees found.'**
  String get noEmployeesFoundDot;

  /// No description provided for @leaveCodeHL.
  ///
  /// In en, this message translates to:
  /// **'HL'**
  String get leaveCodeHL;

  /// No description provided for @leaveCodeSL.
  ///
  /// In en, this message translates to:
  /// **'SL'**
  String get leaveCodeSL;

  /// No description provided for @leaveCodeFL.
  ///
  /// In en, this message translates to:
  /// **'FL'**
  String get leaveCodeFL;

  /// No description provided for @leaveHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday Leave'**
  String get leaveHoliday;

  /// No description provided for @leaveHolidayRule.
  ///
  /// In en, this message translates to:
  /// **'1 hr per 17 hrs worked'**
  String get leaveHolidayRule;

  /// No description provided for @leaveSickTitle.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave'**
  String get leaveSickTitle;

  /// No description provided for @leaveSickRule.
  ///
  /// In en, this message translates to:
  /// **'1 hr per 26 hrs (pre-6mo) / 30 days per 3 yrs'**
  String get leaveSickRule;

  /// No description provided for @leaveFamilyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Resp. Leave'**
  String get leaveFamilyTitle;

  /// No description provided for @leaveFamilyRule.
  ///
  /// In en, this message translates to:
  /// **'3 days/yr after 4 months (needs start date)'**
  String get leaveFamilyRule;

  /// No description provided for @leaveReportPdf.
  ///
  /// In en, this message translates to:
  /// **'Leave Report (PDF)'**
  String get leaveReportPdf;

  /// No description provided for @employedSince.
  ///
  /// In en, this message translates to:
  /// **'Employed {date}'**
  String employedSince(String date);

  /// No description provided for @setOpeningLeave.
  ///
  /// In en, this message translates to:
  /// **'Set opening leave'**
  String get setOpeningLeave;

  /// No description provided for @hoursWorkedInSystem.
  ///
  /// In en, this message translates to:
  /// **'Hours worked in system: '**
  String get hoursWorkedInSystem;

  /// No description provided for @hoursAmount.
  ///
  /// In en, this message translates to:
  /// **'{hours} hrs'**
  String hoursAmount(String hours);

  /// No description provided for @accrualNote.
  ///
  /// In en, this message translates to:
  /// **'(drives new accrual; opening balances set separately)'**
  String get accrualNote;

  /// No description provided for @allocated30Day.
  ///
  /// In en, this message translates to:
  /// **'Allocated (30-day batches)'**
  String get allocated30Day;

  /// No description provided for @accrued126.
  ///
  /// In en, this message translates to:
  /// **'Accrued (1/26 hrs)'**
  String get accrued126;

  /// No description provided for @entitlement3Days.
  ///
  /// In en, this message translates to:
  /// **'Entitlement (3 days/yr)'**
  String get entitlement3Days;

  /// No description provided for @setStartDateToEnable.
  ///
  /// In en, this message translates to:
  /// **'Set employment start date to enable'**
  String get setStartDateToEnable;

  /// No description provided for @eligibleAfter4Months.
  ///
  /// In en, this message translates to:
  /// **'Eligible after 4 months employment'**
  String get eligibleAfter4Months;

  /// No description provided for @openingPreSystem.
  ///
  /// In en, this message translates to:
  /// **'Opening (pre-system)'**
  String get openingPreSystem;

  /// No description provided for @accrued.
  ///
  /// In en, this message translates to:
  /// **'Accrued'**
  String get accrued;

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @balanceHoursHelp.
  ///
  /// In en, this message translates to:
  /// **'Balance in hours (8 hrs = 1 day)'**
  String get balanceHoursHelp;

  /// No description provided for @openingLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Accumulated Before Using the System'**
  String get openingLeaveTitle;

  /// No description provided for @openingLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'For {name} — enter the leave this employee had already banked BEFORE you started using the app. This is the opening balance; the system adds new accrual on top and subtracts leave taken. Enter each type separately — holiday and sick leave are not the same.'**
  String openingLeaveBody(String name);

  /// No description provided for @openingHL.
  ///
  /// In en, this message translates to:
  /// **'Holiday Leave (HL) opening'**
  String get openingHL;

  /// No description provided for @openingSL.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave (SL) opening'**
  String get openingSL;

  /// No description provided for @openingFL.
  ///
  /// In en, this message translates to:
  /// **'Family Resp. Leave (FL) opening'**
  String get openingFL;

  /// No description provided for @sickAllocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave Allocation – {name}'**
  String sickAllocationTitle(String name);

  /// No description provided for @sickPost6Months.
  ///
  /// In en, this message translates to:
  /// **'Employee has passed 6 months — grant 30-day batches'**
  String get sickPost6Months;

  /// No description provided for @sickPre6Months.
  ///
  /// In en, this message translates to:
  /// **'Pre-6 months: auto-accrues 1 hr per 26 hrs worked'**
  String get sickPre6Months;

  /// No description provided for @previousAllocations.
  ///
  /// In en, this message translates to:
  /// **'Previous allocations'**
  String get previousAllocations;

  /// No description provided for @hoursOnDate.
  ///
  /// In en, this message translates to:
  /// **'{hours} hrs on {date}'**
  String hoursOnDate(String hours, String date);

  /// No description provided for @sickAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Sick leave is auto-calculated at 1 hour per 26 hours worked. No manual allocation needed until 6 months of employment.'**
  String get sickAutoNote;

  /// No description provided for @grantSickBatch.
  ///
  /// In en, this message translates to:
  /// **'Grant new 30-day sick leave batch'**
  String get grantSickBatch;

  /// No description provided for @hours240Hint.
  ///
  /// In en, this message translates to:
  /// **'240 (= 30 days × 8 hrs)'**
  String get hours240Hint;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @grantSickLeave.
  ///
  /// In en, this message translates to:
  /// **'Grant Sick Leave'**
  String get grantSickLeave;

  /// No description provided for @familyAllocateBody.
  ///
  /// In en, this message translates to:
  /// **'{name} — allocate annual family responsibility leave. SA law provides 3 days per year for employees employed > 4 months.'**
  String familyAllocateBody(String name);

  /// No description provided for @hoursAllocated.
  ///
  /// In en, this message translates to:
  /// **'Hours allocated'**
  String get hoursAllocated;

  /// No description provided for @hours24Hint.
  ///
  /// In en, this message translates to:
  /// **'24 (= 3 days × 8 hrs)'**
  String get hours24Hint;

  /// No description provided for @hours24Help.
  ///
  /// In en, this message translates to:
  /// **'Typically 24 hrs (3 working days at 8 hrs/day)'**
  String get hours24Help;

  /// No description provided for @actionAllocate.
  ///
  /// In en, this message translates to:
  /// **'Allocate'**
  String get actionAllocate;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'{action} failed: {error}'**
  String actionFailed(String action, String error);

  /// No description provided for @deletePayslipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Payslips'**
  String get deletePayslipsTitle;

  /// No description provided for @deletePayslipsBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Permanently delete 1 payslip? This cannot be undone.} other{Permanently delete {count} payslips? This cannot be undone.}}'**
  String deletePayslipsBody(int count);

  /// No description provided for @deleteCount.
  ///
  /// In en, this message translates to:
  /// **'Delete {count}'**
  String deleteCount(int count);

  /// No description provided for @payslipsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payslip deleted} other{{count} payslips deleted}}'**
  String payslipsDeleted(int count);

  /// No description provided for @bankFile.
  ///
  /// In en, this message translates to:
  /// **'Bank file'**
  String get bankFile;

  /// No description provided for @payslipRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payslip Records – {company}'**
  String payslipRecordsTitle(String company);

  /// No description provided for @presetThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get presetThisWeek;

  /// No description provided for @presetLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get presetLastWeek;

  /// No description provided for @presetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get presetThisMonth;

  /// No description provided for @presetLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get presetLastMonth;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dateFrom;

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dateTo;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @payslipsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payslip} other{{count} payslips}}'**
  String payslipsCount(int count);

  /// No description provided for @bankCsv.
  ///
  /// In en, this message translates to:
  /// **'Bank CSV'**
  String get bankCsv;

  /// No description provided for @noPayslipsInRange.
  ///
  /// In en, this message translates to:
  /// **'No payslips in this date range.'**
  String get noPayslipsInRange;

  /// No description provided for @payslipWord.
  ///
  /// In en, this message translates to:
  /// **'Payslip'**
  String get payslipWord;

  /// No description provided for @payslipNotFound.
  ///
  /// In en, this message translates to:
  /// **'Payslip not found'**
  String get payslipNotFound;

  /// No description provided for @printSavePdf.
  ///
  /// In en, this message translates to:
  /// **'Print / Save PDF'**
  String get printSavePdf;

  /// No description provided for @deletePayslipFor.
  ///
  /// In en, this message translates to:
  /// **'Delete this payslip for {name}?'**
  String deletePayslipFor(String name);

  /// No description provided for @psPersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL DETAILS'**
  String get psPersonalDetails;

  /// No description provided for @psPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Period Start'**
  String get psPeriodStart;

  /// No description provided for @psPeriodEnd.
  ///
  /// In en, this message translates to:
  /// **'Period End'**
  String get psPeriodEnd;

  /// No description provided for @psHourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get psHourlyRate;

  /// No description provided for @psOvertimeRate.
  ///
  /// In en, this message translates to:
  /// **'Overtime Rate'**
  String get psOvertimeRate;

  /// No description provided for @psDoubleTimeRate.
  ///
  /// In en, this message translates to:
  /// **'Double Time Rate'**
  String get psDoubleTimeRate;

  /// No description provided for @psNormalPay.
  ///
  /// In en, this message translates to:
  /// **'Normal Pay'**
  String get psNormalPay;

  /// No description provided for @psOvertimePay.
  ///
  /// In en, this message translates to:
  /// **'Overtime Pay'**
  String get psOvertimePay;

  /// No description provided for @psDoubleTime.
  ///
  /// In en, this message translates to:
  /// **'Double Time'**
  String get psDoubleTime;

  /// No description provided for @psPublicHoliday.
  ///
  /// In en, this message translates to:
  /// **'Public Holiday'**
  String get psPublicHoliday;

  /// No description provided for @psSickLeaveCoded.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave (SL)'**
  String get psSickLeaveCoded;

  /// No description provided for @psHolidayLeaveCoded.
  ///
  /// In en, this message translates to:
  /// **'Annual Leave (HL)'**
  String get psHolidayLeaveCoded;

  /// No description provided for @psFamilyLeaveCoded.
  ///
  /// In en, this message translates to:
  /// **'Family Leave (FL)'**
  String get psFamilyLeaveCoded;

  /// No description provided for @psOtherDetails.
  ///
  /// In en, this message translates to:
  /// **'OTHER DETAILS'**
  String get psOtherDetails;

  /// No description provided for @psUifRegNr.
  ///
  /// In en, this message translates to:
  /// **'UIF Reg No'**
  String get psUifRegNr;

  /// No description provided for @psNetSalaryCaps.
  ///
  /// In en, this message translates to:
  /// **'NET SALARY'**
  String get psNetSalaryCaps;

  /// No description provided for @pdfGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate PDF: {error}'**
  String pdfGenerateFailed(String error);

  /// No description provided for @payslipFinalised.
  ///
  /// In en, this message translates to:
  /// **'This payslip has been finalised'**
  String get payslipFinalised;

  /// No description provided for @payslipIsDraft.
  ///
  /// In en, this message translates to:
  /// **'This payslip is a draft'**
  String get payslipIsDraft;

  /// No description provided for @selectEmployeePlease.
  ///
  /// In en, this message translates to:
  /// **'Please select an employee'**
  String get selectEmployeePlease;

  /// No description provided for @finalisePayslipTitle.
  ///
  /// In en, this message translates to:
  /// **'Finalise Payslip'**
  String get finalisePayslipTitle;

  /// No description provided for @finalisePayslipBody.
  ///
  /// In en, this message translates to:
  /// **'Once finalised this payslip cannot be edited. Continue?'**
  String get finalisePayslipBody;

  /// No description provided for @actionFinalise.
  ///
  /// In en, this message translates to:
  /// **'Finalise'**
  String get actionFinalise;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// No description provided for @viewPayslipTitle.
  ///
  /// In en, this message translates to:
  /// **'View Payslip'**
  String get viewPayslipTitle;

  /// No description provided for @editPayslipTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Payslip'**
  String get editPayslipTitle;

  /// No description provided for @employeePayPeriod.
  ///
  /// In en, this message translates to:
  /// **'Employee & Pay Period'**
  String get employeePayPeriod;

  /// No description provided for @hourlyRates.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rates'**
  String get hourlyRates;

  /// No description provided for @normalRateR.
  ///
  /// In en, this message translates to:
  /// **'Normal Rate (R)'**
  String get normalRateR;

  /// No description provided for @overtimeRateR.
  ///
  /// In en, this message translates to:
  /// **'Overtime Rate (R)'**
  String get overtimeRateR;

  /// No description provided for @doubleRateR.
  ///
  /// In en, this message translates to:
  /// **'Double Rate (R)'**
  String get doubleRateR;

  /// No description provided for @normalHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Normal Hours'**
  String get normalHoursLabel;

  /// No description provided for @overtimeHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Overtime Hours'**
  String get overtimeHoursLabel;

  /// No description provided for @doubleTimeHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Double Time Hours'**
  String get doubleTimeHoursLabel;

  /// No description provided for @publicHolidayHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Public Holiday Hours'**
  String get publicHolidayHoursLabel;

  /// No description provided for @earningsSummary.
  ///
  /// In en, this message translates to:
  /// **'Earnings Summary'**
  String get earningsSummary;

  /// No description provided for @normalPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Normal Pay'**
  String get normalPayLabel;

  /// No description provided for @overtimePayLabel.
  ///
  /// In en, this message translates to:
  /// **'Overtime Pay'**
  String get overtimePayLabel;

  /// No description provided for @doubleTimePayLabel.
  ///
  /// In en, this message translates to:
  /// **'Double Time Pay'**
  String get doubleTimePayLabel;

  /// No description provided for @publicHolidayPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Public Holiday Pay'**
  String get publicHolidayPayLabel;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @deductionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductionsTitle;

  /// No description provided for @uifOnePercent.
  ///
  /// In en, this message translates to:
  /// **'UIF (1% of earnings)'**
  String get uifOnePercent;

  /// No description provided for @compulsory.
  ///
  /// In en, this message translates to:
  /// **'Compulsory'**
  String get compulsory;

  /// No description provided for @totalDeductions.
  ///
  /// In en, this message translates to:
  /// **'Total Deductions'**
  String get totalDeductions;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @selectAnEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select an employee'**
  String get selectAnEmployee;

  /// No description provided for @noEmployeesAddFirst.
  ///
  /// In en, this message translates to:
  /// **'No employees – add one first'**
  String get noEmployeesAddFirst;

  /// No description provided for @selectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select employee'**
  String get selectEmployee;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @payslipFinalisedNoEdit.
  ///
  /// In en, this message translates to:
  /// **'This payslip has been finalised and cannot be edited.'**
  String get payslipFinalisedNoEdit;

  /// No description provided for @bulkEnterHours.
  ///
  /// In en, this message translates to:
  /// **'Enter hours for at least one employee.'**
  String get bulkEnterHours;

  /// No description provided for @bulkGeneratedOk.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payslip generated} other{{count} payslips generated}}'**
  String bulkGeneratedOk(int count);

  /// No description provided for @bulkGeneratedSome.
  ///
  /// In en, this message translates to:
  /// **'{ok} generated, {failed} failed'**
  String bulkGeneratedSome(int ok, int failed);

  /// No description provided for @bulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Payslip Generator'**
  String get bulkTitle;

  /// No description provided for @generateAll.
  ///
  /// In en, this message translates to:
  /// **'Generate All'**
  String get generateAll;

  /// No description provided for @addEmployeesFirst.
  ///
  /// In en, this message translates to:
  /// **'Add employees in the Payslip Manager first.'**
  String get addEmployeesFirst;

  /// No description provided for @backToManager.
  ///
  /// In en, this message translates to:
  /// **'Back to Manager'**
  String get backToManager;

  /// No description provided for @colRateRHr.
  ///
  /// In en, this message translates to:
  /// **'Rate (R/hr)'**
  String get colRateRHr;

  /// No description provided for @colNormalHrs.
  ///
  /// In en, this message translates to:
  /// **'Normal\nhrs'**
  String get colNormalHrs;

  /// No description provided for @colOvertimeHrs.
  ///
  /// In en, this message translates to:
  /// **'Overtime\nhrs'**
  String get colOvertimeHrs;

  /// No description provided for @colDoubleTime.
  ///
  /// In en, this message translates to:
  /// **'Double\nTime'**
  String get colDoubleTime;

  /// No description provided for @colPublicHol.
  ///
  /// In en, this message translates to:
  /// **'Public\nHol'**
  String get colPublicHol;

  /// No description provided for @colEstNetPay.
  ///
  /// In en, this message translates to:
  /// **'Est. Net Pay'**
  String get colEstNetPay;

  /// No description provided for @shortfallTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough leave left'**
  String get shortfallTitle;

  /// No description provided for @shortfallOne.
  ///
  /// In en, this message translates to:
  /// **'This employee doesn’t have enough leave left for what was entered. Choose what to do:'**
  String get shortfallOne;

  /// No description provided for @shortfallMany.
  ///
  /// In en, this message translates to:
  /// **'These employees don’t have enough leave left for what was entered. Choose what to do for each:'**
  String get shortfallMany;

  /// No description provided for @applyToAll.
  ///
  /// In en, this message translates to:
  /// **'Apply to all:'**
  String get applyToAll;

  /// No description provided for @payAvailable.
  ///
  /// In en, this message translates to:
  /// **'Pay available'**
  String get payAvailable;

  /// No description provided for @takeOff.
  ///
  /// In en, this message translates to:
  /// **'Take off'**
  String get takeOff;

  /// No description provided for @overridePay.
  ///
  /// In en, this message translates to:
  /// **'Override & pay'**
  String get overridePay;

  /// No description provided for @chooseForMore.
  ///
  /// In en, this message translates to:
  /// **'Choose an option for {count} more'**
  String chooseForMore(int count);

  /// No description provided for @backToEdit.
  ///
  /// In en, this message translates to:
  /// **'Back to edit'**
  String get backToEdit;

  /// No description provided for @applyAndSave.
  ///
  /// In en, this message translates to:
  /// **'Apply & save'**
  String get applyAndSave;

  /// No description provided for @shortfallLine.
  ///
  /// In en, this message translates to:
  /// **' — {requested} h {type} entered, only {available} h left'**
  String shortfallLine(String requested, String type, String available);

  /// No description provided for @shortfallPayAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay only the {hours} h available'**
  String shortfallPayAvailableTitle(String hours);

  /// No description provided for @shortfallPayAvailableSub.
  ///
  /// In en, this message translates to:
  /// **'The other {hours} h is left off the payslip (unpaid).'**
  String shortfallPayAvailableSub(String hours);

  /// No description provided for @shortfallTakeOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Take the leave off'**
  String get shortfallTakeOffTitle;

  /// No description provided for @shortfallTakeOffSub.
  ///
  /// In en, this message translates to:
  /// **'No {code} on this payslip — the {hours} h is unpaid.'**
  String shortfallTakeOffSub(String code, String hours);

  /// No description provided for @shortfallOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Override & pay all {hours} h'**
  String shortfallOverrideTitle(String hours);

  /// No description provided for @shortfallOverrideSub.
  ///
  /// In en, this message translates to:
  /// **'Pays the full amount as {code}; their {code} balance goes {hours} h below zero.'**
  String shortfallOverrideSub(String code, String hours);

  /// No description provided for @bulkPaymentFile.
  ///
  /// In en, this message translates to:
  /// **'Bulk Payment File'**
  String get bulkPaymentFile;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get noPaymentsYet;

  /// No description provided for @paymentsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment · total {total}} other{{count} payments · total {total}}}'**
  String paymentsTotal(int count, Object total);

  /// No description provided for @bankUploadHelp.
  ///
  /// In en, this message translates to:
  /// **'Upload the file to your online banking as a bulk payment, check the total, then approve once.'**
  String get bankUploadHelp;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @refFirstNameAdded.
  ///
  /// In en, this message translates to:
  /// **'Each employee’s first name is added'**
  String get refFirstNameAdded;

  /// No description provided for @refFirstNameExample.
  ///
  /// In en, this message translates to:
  /// **'Each employee’s first name is added — e.g. “{sample}”'**
  String refFirstNameExample(String sample);

  /// No description provided for @combinedPayments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 employee has more than one payslip selected — their net pay is combined into one payment.} other{{count} employees have more than one payslip selected — their net pay is combined into one payment.}}'**
  String combinedPayments(int count);

  /// No description provided for @downloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download file'**
  String get downloadFile;

  /// No description provided for @chooseYourBank.
  ///
  /// In en, this message translates to:
  /// **'Choose your bank'**
  String get chooseYourBank;

  /// No description provided for @bankFarmPaysFrom.
  ///
  /// In en, this message translates to:
  /// **'Bank the farm pays from'**
  String get bankFarmPaysFrom;

  /// No description provided for @nobodyPayable.
  ///
  /// In en, this message translates to:
  /// **'Nobody can be paid yet — let’s fix that'**
  String get nobodyPayable;

  /// No description provided for @eachFixSaves.
  ///
  /// In en, this message translates to:
  /// **'Each fix saves straight away and this list updates as you go.'**
  String get eachFixSaves;

  /// No description provided for @addBankingForCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add banking details for 1 employee} other{Add banking details for {count} employees}}'**
  String addBankingForCount(int count);

  /// No description provided for @fixUnlinkedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Fix 1 unlinked payslip} other{Fix {count} unlinked payslips}}'**
  String fixUnlinkedCount(int count);

  /// No description provided for @reviewZeroCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Review 1 R 0 payslip} other{Review {count} R 0 payslips}}'**
  String reviewZeroCount(int count);

  /// No description provided for @notIncludedCount.
  ///
  /// In en, this message translates to:
  /// **'Not included ({count})'**
  String notIncludedCount(int count);

  /// No description provided for @addBankingForAll.
  ///
  /// In en, this message translates to:
  /// **'Add banking details for all {count}'**
  String addBankingForAll(int count);

  /// No description provided for @addBankingDetails.
  ///
  /// In en, this message translates to:
  /// **'Add banking details'**
  String get addBankingDetails;

  /// No description provided for @fixBankingDetails.
  ///
  /// In en, this message translates to:
  /// **'Fix banking details'**
  String get fixBankingDetails;

  /// No description provided for @linkToEmployee.
  ///
  /// In en, this message translates to:
  /// **'Link to employee'**
  String get linkToEmployee;

  /// No description provided for @editPayslip.
  ///
  /// In en, this message translates to:
  /// **'Edit payslip'**
  String get editPayslip;

  /// No description provided for @relinkedNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payslip was linked to a removed employee record — matched to the current employee by ID number or name.} other{{count} payslips were linked to a removed employee record — matched to the current employee by ID number or name.}}'**
  String relinkedNote(int count);

  /// No description provided for @saveLinks.
  ///
  /// In en, this message translates to:
  /// **'Save links'**
  String get saveLinks;

  /// No description provided for @draftsUndecided.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected payslip is still Draft — amounts may still change:} other{{count} selected payslips are still Draft — amounts may still change:}}'**
  String draftsUndecided(int count);

  /// No description provided for @draftsRemoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 draft payslip removed from this export:} other{{count} draft payslips removed from this export:}}'**
  String draftsRemoved(int count);

  /// No description provided for @draftsIncluded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 draft payslip included as it is now:} other{{count} draft payslips included as they are now:}}'**
  String draftsIncluded(int count);

  /// No description provided for @removeDrafts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Remove draft} other{Remove drafts}}'**
  String removeDrafts(int count);

  /// No description provided for @includeAnyway.
  ///
  /// In en, this message translates to:
  /// **'Include anyway'**
  String get includeAnyway;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @bankingDetailsFor.
  ///
  /// In en, this message translates to:
  /// **'Banking details — {name}'**
  String bankingDetailsFor(String name);

  /// No description provided for @orphanPayslipBody.
  ///
  /// In en, this message translates to:
  /// **'This payslip is linked to an employee record that no longer exists (the employee was probably removed). Link it to a current employee, or re-create the employee from the payslip.'**
  String get orphanPayslipBody;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @recreateEmployee.
  ///
  /// In en, this message translates to:
  /// **'Re-create employee'**
  String get recreateEmployee;

  /// No description provided for @linkNameTo.
  ///
  /// In en, this message translates to:
  /// **'Link “{name}” to…'**
  String linkNameTo(String name);

  /// No description provided for @noIdNumber.
  ///
  /// In en, this message translates to:
  /// **'No ID number'**
  String get noIdNumber;

  /// No description provided for @notListedRecreate.
  ///
  /// In en, this message translates to:
  /// **'Not listed? Re-create the employee instead'**
  String get notListedRecreate;

  /// No description provided for @couldNotLink.
  ///
  /// In en, this message translates to:
  /// **'Could not link: {reason}'**
  String couldNotLink(String reason);

  /// No description provided for @employeeSavedLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Employee saved, but linking payslips failed.'**
  String get employeeSavedLinkFailed;

  /// No description provided for @payslipLinksSaved.
  ///
  /// In en, this message translates to:
  /// **'Payslip links saved'**
  String get payslipLinksSaved;

  /// No description provided for @someLinksFailed.
  ///
  /// In en, this message translates to:
  /// **'Some links could not be saved'**
  String get someLinksFailed;

  /// No description provided for @completeHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Please complete the highlighted fields.'**
  String get completeHighlighted;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @employeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Employee details'**
  String get employeeDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. John Smith'**
  String get fullNameHint;

  /// No description provided for @normalHourlyRateR.
  ///
  /// In en, this message translates to:
  /// **'Normal Hourly Rate (R)'**
  String get normalHourlyRateR;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDescription;

  /// No description provided for @jobDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Farm Worker, Tractor Driver'**
  String get jobDescriptionHint;

  /// No description provided for @employmentStartOptional.
  ///
  /// In en, this message translates to:
  /// **'Employment Start Date (optional)'**
  String get employmentStartOptional;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @employmentType.
  ///
  /// In en, this message translates to:
  /// **'Employment Type'**
  String get employmentType;

  /// No description provided for @bankingDetails.
  ///
  /// In en, this message translates to:
  /// **'Banking Details'**
  String get bankingDetails;

  /// No description provided for @bankingOnlyIfCsv.
  ///
  /// In en, this message translates to:
  /// **'Only needed if you pay staff with the Bank CSV bulk-payment file. Leave blank otherwise.'**
  String get bankingOnlyIfCsv;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @otherBank.
  ///
  /// In en, this message translates to:
  /// **'Other bank…'**
  String get otherBank;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank name'**
  String get bankName;

  /// No description provided for @bankNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bidvest Bank'**
  String get bankNameHint;

  /// No description provided for @accountHolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Account holder (if not the employee)'**
  String get accountHolderLabel;

  /// No description provided for @accountHolderHint.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to use the employee’s name'**
  String get accountHolderHint;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @accountDigits.
  ///
  /// In en, this message translates to:
  /// **'Digits only, 6–16 long'**
  String get accountDigits;

  /// No description provided for @branchCode.
  ///
  /// In en, this message translates to:
  /// **'Branch Code'**
  String get branchCode;

  /// No description provided for @branchCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Filled in automatically for major banks'**
  String get branchCodeHint;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @leaveEligibility.
  ///
  /// In en, this message translates to:
  /// **'Leave eligibility ({months} months employed):'**
  String leaveEligibility(int months);

  /// No description provided for @familyLeave3Days.
  ///
  /// In en, this message translates to:
  /// **'Family Resp. Leave (3 days/yr)'**
  String get familyLeave3Days;

  /// No description provided for @months4Required.
  ///
  /// In en, this message translates to:
  /// **'4 months required'**
  String get months4Required;

  /// No description provided for @sickLeave30Days.
  ///
  /// In en, this message translates to:
  /// **'Sick Leave (30 days/3 yr)'**
  String get sickLeave30Days;

  /// No description provided for @months6Required.
  ///
  /// In en, this message translates to:
  /// **'6 months required'**
  String get months6Required;

  /// No description provided for @rateHelper.
  ///
  /// In en, this message translates to:
  /// **'Overtime: R {overtime}/hr  ·  Double: R {double}/hr'**
  String rateHelper(String overtime, String double);

  /// No description provided for @employmentPermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get employmentPermanent;

  /// No description provided for @employmentSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get employmentSeasonal;

  /// No description provided for @accountCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current / Cheque'**
  String get accountCurrent;

  /// No description provided for @accountSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get accountSavings;

  /// No description provided for @accountTransmission.
  ///
  /// In en, this message translates to:
  /// **'Transmission'**
  String get accountTransmission;

  /// No description provided for @bankIssueNone.
  ///
  /// In en, this message translates to:
  /// **'no banking details'**
  String get bankIssueNone;

  /// No description provided for @bankIssueNoAccount.
  ///
  /// In en, this message translates to:
  /// **'no account number'**
  String get bankIssueNoAccount;

  /// No description provided for @bankIssueAccountDigits.
  ///
  /// In en, this message translates to:
  /// **'account number must be 6–16 digits'**
  String get bankIssueAccountDigits;

  /// No description provided for @bankIssueNoBranch.
  ///
  /// In en, this message translates to:
  /// **'no branch code'**
  String get bankIssueNoBranch;

  /// No description provided for @bankIssueBranchDigits.
  ///
  /// In en, this message translates to:
  /// **'branch code must be 6 digits'**
  String get bankIssueBranchDigits;

  /// No description provided for @formUntitledField.
  ///
  /// In en, this message translates to:
  /// **'Untitled Field'**
  String get formUntitledField;

  /// No description provided for @formEnterField.
  ///
  /// In en, this message translates to:
  /// **'Enter {label}'**
  String formEnterField(String label);

  /// No description provided for @formNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No options provided'**
  String get formNoOptions;

  /// No description provided for @formInvalidConfig.
  ///
  /// In en, this message translates to:
  /// **'Invalid form configuration: missing fields'**
  String get formInvalidConfig;

  /// No description provided for @formBuildError.
  ///
  /// In en, this message translates to:
  /// **'Error building form: {error}'**
  String formBuildError(String error);

  /// No description provided for @formContractName.
  ///
  /// In en, this message translates to:
  /// **'Contract Name'**
  String get formContractName;

  /// No description provided for @formContractNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the contract'**
  String get formContractNameHint;

  /// No description provided for @formContractNumber.
  ///
  /// In en, this message translates to:
  /// **'Contract Number'**
  String get formContractNumber;

  /// No description provided for @formContractNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the contract reference number'**
  String get formContractNumberHint;

  /// No description provided for @formCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Counterparty'**
  String get formCounterparty;

  /// No description provided for @formCounterpartyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the other party'**
  String get formCounterpartyHint;

  /// No description provided for @formEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective Date'**
  String get formEffectiveDate;

  /// No description provided for @formContractStatus.
  ///
  /// In en, this message translates to:
  /// **'Contract Status'**
  String get formContractStatus;

  /// No description provided for @formOptActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get formOptActive;

  /// No description provided for @formOptPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get formOptPending;

  /// No description provided for @formOptTerminated.
  ///
  /// In en, this message translates to:
  /// **'Terminated'**
  String get formOptTerminated;

  /// No description provided for @formOptExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get formOptExpired;

  /// No description provided for @formContractDescHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a description of the contract'**
  String get formContractDescHint;

  /// No description provided for @formCertName.
  ///
  /// In en, this message translates to:
  /// **'Certification Name'**
  String get formCertName;

  /// No description provided for @formCertNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the certification'**
  String get formCertNameHint;

  /// No description provided for @formCertNumber.
  ///
  /// In en, this message translates to:
  /// **'Certification Number'**
  String get formCertNumber;

  /// No description provided for @formCertNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the certification reference number'**
  String get formCertNumberHint;

  /// No description provided for @formIssuingAuthority.
  ///
  /// In en, this message translates to:
  /// **'Issuing Authority'**
  String get formIssuingAuthority;

  /// No description provided for @formIssuingAuthorityHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the issuing authority'**
  String get formIssuingAuthorityHint;

  /// No description provided for @formIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get formIssueDate;

  /// No description provided for @formHasRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Has Restrictions'**
  String get formHasRestrictions;

  /// No description provided for @formNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get formNotes;

  /// No description provided for @formNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Enter any additional notes'**
  String get formNotesHint;

  /// No description provided for @formInspectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Inspection Location'**
  String get formInspectionLocation;

  /// No description provided for @formInspectionLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the location that was inspected'**
  String get formInspectionLocationHint;

  /// No description provided for @formInspectionDate.
  ///
  /// In en, this message translates to:
  /// **'Inspection Date'**
  String get formInspectionDate;

  /// No description provided for @formInspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get formInspector;

  /// No description provided for @formInspectorHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the inspector'**
  String get formInspectorHint;

  /// No description provided for @formInspectionResult.
  ///
  /// In en, this message translates to:
  /// **'Inspection Result'**
  String get formInspectionResult;

  /// No description provided for @formOptPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get formOptPass;

  /// No description provided for @formOptPassConditions.
  ///
  /// In en, this message translates to:
  /// **'Pass with Conditions'**
  String get formOptPassConditions;

  /// No description provided for @formOptFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get formOptFail;

  /// No description provided for @formOptIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get formOptIncomplete;

  /// No description provided for @formFindings.
  ///
  /// In en, this message translates to:
  /// **'Findings'**
  String get formFindings;

  /// No description provided for @formFindingsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter inspection findings'**
  String get formFindingsHint;

  /// No description provided for @formRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get formRecommendations;

  /// No description provided for @formRecommendationsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter recommendations'**
  String get formRecommendationsHint;

  /// No description provided for @formAssessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Assessment Title'**
  String get formAssessmentTitle;

  /// No description provided for @formAssessmentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the title of this risk assessment'**
  String get formAssessmentTitleHint;

  /// No description provided for @formAssessmentDate.
  ///
  /// In en, this message translates to:
  /// **'Assessment Date'**
  String get formAssessmentDate;

  /// No description provided for @formAssessor.
  ///
  /// In en, this message translates to:
  /// **'Assessor'**
  String get formAssessor;

  /// No description provided for @formAssessorHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the name of the assessor'**
  String get formAssessorHint;

  /// No description provided for @formOverallRisk.
  ///
  /// In en, this message translates to:
  /// **'Overall Risk Level'**
  String get formOverallRisk;

  /// No description provided for @formOptLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get formOptLow;

  /// No description provided for @formOptMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get formOptMedium;

  /// No description provided for @formOptHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get formOptHigh;

  /// No description provided for @formOptCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get formOptCritical;

  /// No description provided for @formHazards.
  ///
  /// In en, this message translates to:
  /// **'Identified Hazards'**
  String get formHazards;

  /// No description provided for @formHazardsHint.
  ///
  /// In en, this message translates to:
  /// **'List the identified hazards'**
  String get formHazardsHint;

  /// No description provided for @formControlMeasures.
  ///
  /// In en, this message translates to:
  /// **'Control Measures'**
  String get formControlMeasures;

  /// No description provided for @formControlMeasuresHint.
  ///
  /// In en, this message translates to:
  /// **'List the control measures'**
  String get formControlMeasuresHint;

  /// No description provided for @formRequiresFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Requires Follow-up'**
  String get formRequiresFollowUp;

  /// No description provided for @formTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get formTitle;

  /// No description provided for @formTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get formTitleHint;

  /// No description provided for @formReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a reference number'**
  String get formReferenceHint;

  /// No description provided for @formDocumentDate.
  ///
  /// In en, this message translates to:
  /// **'Document Date'**
  String get formDocumentDate;

  /// No description provided for @formSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get formSelectDate;

  /// No description provided for @fmNoFarmLinked.
  ///
  /// In en, this message translates to:
  /// **'No Farmable farm is linked to this company.'**
  String get fmNoFarmLinked;

  /// No description provided for @fmMapLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load farm map'**
  String get fmMapLoadFailed;

  /// No description provided for @fmCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get fmCrop;

  /// No description provided for @fmVariety.
  ///
  /// In en, this message translates to:
  /// **'Variety'**
  String get fmVariety;

  /// No description provided for @fmFieldType.
  ///
  /// In en, this message translates to:
  /// **'Field type'**
  String get fmFieldType;

  /// No description provided for @fmArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get fmArea;

  /// No description provided for @fmHectares.
  ///
  /// In en, this message translates to:
  /// **'{value} ha'**
  String fmHectares(String value);

  /// No description provided for @fmSkyView.
  ///
  /// In en, this message translates to:
  /// **'Farm Sky View'**
  String get fmSkyView;

  /// No description provided for @fmCropsBlocks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Crops · 1 block} other{Crops · {count} blocks}}'**
  String fmCropsBlocks(int count);

  /// No description provided for @fmDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load farm data'**
  String get fmDataLoadFailed;

  /// No description provided for @fmFarmableLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load Farmable data'**
  String get fmFarmableLoadFailed;

  /// No description provided for @fmFarmData.
  ///
  /// In en, this message translates to:
  /// **'Farm Data'**
  String get fmFarmData;

  /// No description provided for @fmFieldsCrops.
  ///
  /// In en, this message translates to:
  /// **'Fields & Crops'**
  String get fmFieldsCrops;

  /// No description provided for @fmRecentSales.
  ///
  /// In en, this message translates to:
  /// **'Recent Harvests / Sales'**
  String get fmRecentSales;

  /// No description provided for @fmNoSales.
  ///
  /// In en, this message translates to:
  /// **'No sales records found.'**
  String get fmNoSales;

  /// No description provided for @fmViewRegister.
  ///
  /// In en, this message translates to:
  /// **'View full farm register'**
  String get fmViewRegister;

  /// No description provided for @fmNoCrops.
  ///
  /// In en, this message translates to:
  /// **'No crops'**
  String get fmNoCrops;

  /// No description provided for @fmCropArea.
  ///
  /// In en, this message translates to:
  /// **'{crops} · {area} ha'**
  String fmCropArea(String crops, String area);

  /// No description provided for @fmUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get fmUnassigned;

  /// No description provided for @fmNoMappedFields.
  ///
  /// In en, this message translates to:
  /// **'No mapped fields'**
  String get fmNoMappedFields;

  /// No description provided for @fmTotalArea.
  ///
  /// In en, this message translates to:
  /// **'Total Cultivated Area'**
  String get fmTotalArea;

  /// No description provided for @fmFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fmFields;

  /// No description provided for @fmCropTypes.
  ///
  /// In en, this message translates to:
  /// **'Crop Types'**
  String get fmCropTypes;

  /// No description provided for @fmPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get fmPeople;

  /// No description provided for @unitBlocks.
  ///
  /// In en, this message translates to:
  /// **'blocks'**
  String get unitBlocks;

  /// No description provided for @unitTypes.
  ///
  /// In en, this message translates to:
  /// **'types'**
  String get unitTypes;

  /// No description provided for @unitMembers.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get unitMembers;

  /// No description provided for @fmEquipmentInspection.
  ///
  /// In en, this message translates to:
  /// **'Equipment Inspection'**
  String get fmEquipmentInspection;

  /// No description provided for @fmNoEquipment.
  ///
  /// In en, this message translates to:
  /// **'No equipment'**
  String get fmNoEquipment;

  /// No description provided for @fmAllInspected.
  ///
  /// In en, this message translates to:
  /// **'All inspected'**
  String get fmAllInspected;

  /// No description provided for @fmNeedInspection.
  ///
  /// In en, this message translates to:
  /// **'{count} need inspection'**
  String fmNeedInspection(int count);

  /// No description provided for @fmBlocksArea.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 block · {area} ha} other{{count} blocks · {area} ha}}'**
  String fmBlocksArea(int count, Object area);

  /// No description provided for @fmCropDistribution.
  ///
  /// In en, this message translates to:
  /// **'Crop Distribution'**
  String get fmCropDistribution;

  /// No description provided for @fmNoCropData.
  ///
  /// In en, this message translates to:
  /// **'No crop data.'**
  String get fmNoCropData;

  /// No description provided for @fmEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get fmEquipment;

  /// No description provided for @fmToInspect.
  ///
  /// In en, this message translates to:
  /// **'{count} to inspect'**
  String fmToInspect(int count);

  /// No description provided for @fmAllGood.
  ///
  /// In en, this message translates to:
  /// **'All good'**
  String get fmAllGood;

  /// No description provided for @fmNoEquipmentRecord.
  ///
  /// In en, this message translates to:
  /// **'No equipment on record.'**
  String get fmNoEquipmentRecord;

  /// No description provided for @fmInspectedOn.
  ///
  /// In en, this message translates to:
  /// **'Inspected {date}'**
  String fmInspectedOn(String date);

  /// No description provided for @fmDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get fmDue;

  /// No description provided for @fmPeopleRoles.
  ///
  /// In en, this message translates to:
  /// **'People & Roles'**
  String get fmPeopleRoles;

  /// No description provided for @fmNoPeople.
  ///
  /// In en, this message translates to:
  /// **'No people on record.'**
  String get fmNoPeople;

  /// No description provided for @srTitle.
  ///
  /// In en, this message translates to:
  /// **'Spray & Fertilizer Records'**
  String get srTitle;

  /// No description provided for @srAddRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get srAddRecord;

  /// No description provided for @srRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 record} other{{count} records}}'**
  String srRecordCount(int count);

  /// No description provided for @srSyncedFarmable.
  ///
  /// In en, this message translates to:
  /// **'Synced to Farmable (Job #{job})'**
  String srSyncedFarmable(String job);

  /// No description provided for @srNoFields.
  ///
  /// In en, this message translates to:
  /// **'No fields'**
  String get srNoFields;

  /// No description provided for @srPhiDays.
  ///
  /// In en, this message translates to:
  /// **'PHI: {days}d'**
  String srPhiDays(int days);

  /// No description provided for @srNoRecordsSpray.
  ///
  /// In en, this message translates to:
  /// **'No spray application records yet'**
  String get srNoRecordsSpray;

  /// No description provided for @srNoRecordsFert.
  ///
  /// In en, this message translates to:
  /// **'No fertilizer application records yet'**
  String get srNoRecordsFert;

  /// No description provided for @srEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + Add Record to log your first application'**
  String get srEmptyHint;

  /// No description provided for @srAdded.
  ///
  /// In en, this message translates to:
  /// **'Record added'**
  String get srAdded;

  /// No description provided for @srUpdated.
  ///
  /// In en, this message translates to:
  /// **'Record updated'**
  String get srUpdated;

  /// No description provided for @srDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get srDeleted;

  /// No description provided for @srLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Application Record'**
  String get srLogTitle;

  /// No description provided for @srEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Application Record'**
  String get srEditTitle;

  /// No description provided for @srDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get srDeleteTooltip;

  /// No description provided for @srDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get srDeleteTitle;

  /// No description provided for @srDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this record.'**
  String get srDeleteBody;

  /// No description provided for @srSpray.
  ///
  /// In en, this message translates to:
  /// **'Spray'**
  String get srSpray;

  /// No description provided for @srFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer'**
  String get srFertilizer;

  /// No description provided for @srAppDate.
  ///
  /// In en, this message translates to:
  /// **'Application Date *'**
  String get srAppDate;

  /// No description provided for @srProduct.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get srProduct;

  /// No description provided for @srProductHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Karate 5 EC'**
  String get srProductHint;

  /// No description provided for @srActiveIngredient.
  ///
  /// In en, this message translates to:
  /// **'Active Ingredient'**
  String get srActiveIngredient;

  /// No description provided for @srActiveIngredientHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lambda-cyhalothrin'**
  String get srActiveIngredientHint;

  /// No description provided for @srRegNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration Number'**
  String get srRegNumber;

  /// No description provided for @srTargetPest.
  ///
  /// In en, this message translates to:
  /// **'Target Pest / Disease *'**
  String get srTargetPest;

  /// No description provided for @srTargetCrop.
  ///
  /// In en, this message translates to:
  /// **'Target Crop / Nutrient *'**
  String get srTargetCrop;

  /// No description provided for @srTargetPestHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. False codling moth'**
  String get srTargetPestHint;

  /// No description provided for @srTargetCropHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Nitrogen top-dressing'**
  String get srTargetCropHint;

  /// No description provided for @srRate.
  ///
  /// In en, this message translates to:
  /// **'Application Rate *'**
  String get srRate;

  /// No description provided for @enterANumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get enterANumber;

  /// No description provided for @srUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get srUnit;

  /// No description provided for @srTotalUsed.
  ///
  /// In en, this message translates to:
  /// **'Total Used'**
  String get srTotalUsed;

  /// No description provided for @srFieldsTreated.
  ///
  /// In en, this message translates to:
  /// **'Fields Treated'**
  String get srFieldsTreated;

  /// No description provided for @srOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator Name *'**
  String get srOperator;

  /// No description provided for @srEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get srEquipment;

  /// No description provided for @srEquipmentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tractor boom sprayer'**
  String get srEquipmentHint;

  /// No description provided for @srPhi.
  ///
  /// In en, this message translates to:
  /// **'PHI (days)'**
  String get srPhi;

  /// No description provided for @srPhiHint.
  ///
  /// In en, this message translates to:
  /// **'Pre-Harvest Interval'**
  String get srPhiHint;

  /// No description provided for @srRei.
  ///
  /// In en, this message translates to:
  /// **'REI (days)'**
  String get srRei;

  /// No description provided for @srReiHint.
  ///
  /// In en, this message translates to:
  /// **'Re-Entry Interval'**
  String get srReiHint;

  /// No description provided for @srWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather Conditions'**
  String get srWeather;

  /// No description provided for @srWeatherHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Clear, 22°C, wind < 5 km/h'**
  String get srWeatherHint;

  /// No description provided for @srNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes'**
  String get srNotesHint;

  /// No description provided for @srSave.
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get srSave;

  /// No description provided for @actionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get actionUpdate;

  /// No description provided for @srTypeSpray.
  ///
  /// In en, this message translates to:
  /// **'Spray Application'**
  String get srTypeSpray;

  /// No description provided for @srTypeFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Application'**
  String get srTypeFertilizer;

  /// No description provided for @unitBoxes.
  ///
  /// In en, this message translates to:
  /// **'{value} boxes'**
  String unitBoxes(String value);

  /// No description provided for @unitPieces.
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String unitPieces(int count);

  /// No description provided for @errNoAuthUser.
  ///
  /// In en, this message translates to:
  /// **'No authenticated user'**
  String get errNoAuthUser;

  /// No description provided for @errInitData.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize data: {error}'**
  String errInitData(String error);

  /// No description provided for @errUpdateFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to update document files: {error}'**
  String errUpdateFiles(String error);

  /// No description provided for @errDeleteDoc.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete document: {error}'**
  String errDeleteDoc(String error);

  /// No description provided for @errFetchData.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch data: {error}'**
  String errFetchData(String error);

  /// No description provided for @errFetchCatsTypes.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch categories and document types: {error}'**
  String errFetchCatsTypes(String error);

  /// No description provided for @errFetchCats.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch categories: {error}'**
  String errFetchCats(String error);

  /// No description provided for @errFetchTypes.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch document types: {error}'**
  String errFetchTypes(String error);

  /// No description provided for @errFetchDocs.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch documents: {error}'**
  String errFetchDocs(String error);

  /// No description provided for @errGetDoc.
  ///
  /// In en, this message translates to:
  /// **'Failed to get document: {error}'**
  String errGetDoc(String error);

  /// No description provided for @errCreateDoc.
  ///
  /// In en, this message translates to:
  /// **'Failed to create document: {error}'**
  String errCreateDoc(String error);

  /// No description provided for @errNoEffectiveUser.
  ///
  /// In en, this message translates to:
  /// **'No effective user found'**
  String get errNoEffectiveUser;

  /// No description provided for @errUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update document status: {error}'**
  String errUpdateStatus(String error);

  /// No description provided for @errSupersede.
  ///
  /// In en, this message translates to:
  /// **'Failed to supersede document: {error}'**
  String errSupersede(String error);

  /// No description provided for @errAddSignature.
  ///
  /// In en, this message translates to:
  /// **'Failed to add signature: {error}'**
  String errAddSignature(String error);

  /// No description provided for @errAddComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to add comment: {error}'**
  String errAddComment(String error);

  /// No description provided for @errCompliancePct.
  ///
  /// In en, this message translates to:
  /// **'Failed to calculate compliance percentage: {error}'**
  String errCompliancePct(String error);

  /// No description provided for @cmtCreatedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Document created by admin {admin} for user {user}'**
  String cmtCreatedByAdmin(String admin, String user);

  /// No description provided for @cmtSpecUpdated.
  ///
  /// In en, this message translates to:
  /// **'specification updated'**
  String get cmtSpecUpdated;

  /// No description provided for @cmtExpiryUpdated.
  ///
  /// In en, this message translates to:
  /// **'expiry date updated to {date}'**
  String cmtExpiryUpdated(String date);

  /// No description provided for @cmtExpiryRemoved.
  ///
  /// In en, this message translates to:
  /// **'expiry date removed'**
  String get cmtExpiryRemoved;

  /// No description provided for @cmtStatusByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Status updated by admin {name}'**
  String cmtStatusByAdmin(String name);

  /// No description provided for @viaAdmin.
  ///
  /// In en, this message translates to:
  /// **'{user} (via admin {admin})'**
  String viaAdmin(String user, String admin);

  /// No description provided for @cmtResubmitted.
  ///
  /// In en, this message translates to:
  /// **'Document resubmitted with updated files.'**
  String get cmtResubmitted;

  /// No description provided for @cmtResubmittedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Document resubmitted with updated files by admin {admin} for user {user}.'**
  String cmtResubmittedByAdmin(String admin, String user);

  /// No description provided for @noReasonProvided.
  ///
  /// In en, this message translates to:
  /// **'No reason provided'**
  String get noReasonProvided;

  /// No description provided for @errInitCats.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize categories: {error}'**
  String errInitCats(String error);

  /// No description provided for @errComplianceStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to calculate compliance statistics: {error}'**
  String errComplianceStats(String error);

  /// No description provided for @errAuditDocs.
  ///
  /// In en, this message translates to:
  /// **'Failed to get documents for audit: {error}'**
  String errAuditDocs(String error);

  /// No description provided for @pushChannelName.
  ///
  /// In en, this message translates to:
  /// **'Compliance Alerts'**
  String get pushChannelName;

  /// No description provided for @pushChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Document rejections, expiries and audit reminders'**
  String get pushChannelDesc;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusFinal.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get statusFinal;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No route defined for {name}'**
  String routeNotFound(String name);

  /// No description provided for @fmInvalidKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid API key.'**
  String get fmInvalidKey;

  /// No description provided for @fmForbidden.
  ///
  /// In en, this message translates to:
  /// **'Access forbidden.'**
  String get fmForbidden;

  /// No description provided for @fmNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get fmNotFound;

  /// No description provided for @fmRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Rate limit reached. Try again shortly.'**
  String get fmRateLimit;

  /// No description provided for @fmApiError.
  ///
  /// In en, this message translates to:
  /// **'API error ({code})'**
  String fmApiError(int code);

  /// No description provided for @bankRefDefault.
  ///
  /// In en, this message translates to:
  /// **'Salaries'**
  String get bankRefDefault;

  /// No description provided for @bankNoteGeneric.
  ///
  /// In en, this message translates to:
  /// **'Generic layout with column headings — map the columns in your bank’s import screen and test a small upload first.'**
  String get bankNoteGeneric;

  /// No description provided for @bankNoteUnverified.
  ///
  /// In en, this message translates to:
  /// **'Template not yet confirmed with {bank} — test a small upload first.'**
  String bankNoteUnverified(String bank);

  /// No description provided for @bankIssueNetZero.
  ///
  /// In en, this message translates to:
  /// **'net pay is R 0.00 or less'**
  String get bankIssueNetZero;

  /// No description provided for @bankFileName.
  ///
  /// In en, this message translates to:
  /// **'{company} Bank Payments {bank} {period}.{ext}'**
  String bankFileName(String company, String bank, String period, String ext);

  /// No description provided for @bankFileNameGeneric.
  ///
  /// In en, this message translates to:
  /// **'{company} Bank Payments {period}.{ext}'**
  String bankFileNameGeneric(String company, String period, String ext);

  /// No description provided for @bankGenericName.
  ///
  /// In en, this message translates to:
  /// **'Other bank (generic CSV)'**
  String get bankGenericName;

  /// No description provided for @unnamedEmployee.
  ///
  /// In en, this message translates to:
  /// **'Unnamed employee'**
  String get unnamedEmployee;

  /// No description provided for @skipEmployeeGone.
  ///
  /// In en, this message translates to:
  /// **'employee record no longer exists'**
  String get skipEmployeeGone;

  /// No description provided for @bankNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'No payslips selected.'**
  String get bankNoneSelected;

  /// No description provided for @bankChooseBank.
  ///
  /// In en, this message translates to:
  /// **'Choose the bank the farm pays from.'**
  String get bankChooseBank;

  /// No description provided for @bankDraftsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 draft payslip selected — remove it or include it anyway.} other{{count} draft payslips selected — remove them or include them anyway.}}'**
  String bankDraftsSelected(int count);

  /// No description provided for @bankAllDrafts.
  ///
  /// In en, this message translates to:
  /// **'All selected payslips are drafts — include them anyway or select finalised payslips.'**
  String get bankAllDrafts;

  /// No description provided for @bankNobodyBanking.
  ///
  /// In en, this message translates to:
  /// **'Nobody has banking details yet — add them to continue.'**
  String get bankNobodyBanking;

  /// No description provided for @bankNotLinked.
  ///
  /// In en, this message translates to:
  /// **'These payslips aren’t linked to an employee — fix them to continue.'**
  String get bankNotLinked;

  /// No description provided for @bankNobodyPayableFix.
  ///
  /// In en, this message translates to:
  /// **'Nobody can be paid yet — fix the employees listed below.'**
  String get bankNobodyPayableFix;

  /// No description provided for @pdfPayslipFile.
  ///
  /// In en, this message translates to:
  /// **'{name} {period} Payslip.pdf'**
  String pdfPayslipFile(String name, String period);

  /// No description provided for @pdfUifFile.
  ///
  /// In en, this message translates to:
  /// **'{company} UIF Summary {period}.pdf'**
  String pdfUifFile(String company, String period);

  /// No description provided for @pdfLeaveFile.
  ///
  /// In en, this message translates to:
  /// **'{company} Leave Records {stamp}.pdf'**
  String pdfLeaveFile(String company, String stamp);

  /// No description provided for @psEmployeeType.
  ///
  /// In en, this message translates to:
  /// **'Employee Type'**
  String get psEmployeeType;

  /// No description provided for @payslipFinalisedDot.
  ///
  /// In en, this message translates to:
  /// **'This payslip has been finalised.'**
  String get payslipFinalisedDot;

  /// No description provided for @payslipDraftBanner.
  ///
  /// In en, this message translates to:
  /// **'DRAFT – This payslip has not been finalised.'**
  String get payslipDraftBanner;

  /// No description provided for @uifSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'UIF & DEDUCTIONS SUMMARY'**
  String get uifSummaryTitle;

  /// No description provided for @uifPeriodRange.
  ///
  /// In en, this message translates to:
  /// **'Period: {start} – {end}'**
  String uifPeriodRange(String start, String end);

  /// No description provided for @uifRegNrValue.
  ///
  /// In en, this message translates to:
  /// **'UIF Reg No: {value}'**
  String uifRegNrValue(String value);

  /// No description provided for @uifEmployeeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 employee} other{{count} employees}}'**
  String uifEmployeeCount(int count);

  /// No description provided for @uifColIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get uifColIncome;

  /// No description provided for @uifColEmployeeUif.
  ///
  /// In en, this message translates to:
  /// **'UIF Empl. (1%)'**
  String get uifColEmployeeUif;

  /// No description provided for @uifColEmployerUif.
  ///
  /// In en, this message translates to:
  /// **'UIF Emplr. (1%)'**
  String get uifColEmployerUif;

  /// No description provided for @uifColOtherDed.
  ///
  /// In en, this message translates to:
  /// **'Other Ded.'**
  String get uifColOtherDed;

  /// No description provided for @uifColEmployeeDed.
  ///
  /// In en, this message translates to:
  /// **'Empl. Ded.'**
  String get uifColEmployeeDed;

  /// No description provided for @uifSummaryHeading.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get uifSummaryHeading;

  /// No description provided for @uifPayeTaxColon.
  ///
  /// In en, this message translates to:
  /// **'PAYE Tax:'**
  String get uifPayeTaxColon;

  /// No description provided for @uifEmployeeContribution.
  ///
  /// In en, this message translates to:
  /// **'Employee UIF contribution (1%):'**
  String get uifEmployeeContribution;

  /// No description provided for @uifOtherDeductions.
  ///
  /// In en, this message translates to:
  /// **'Other deductions:'**
  String get uifOtherDeductions;

  /// No description provided for @uifTotalEmployeeDed.
  ///
  /// In en, this message translates to:
  /// **'TOTAL EMPLOYEE DEDUCTIONS:'**
  String get uifTotalEmployeeDed;

  /// No description provided for @uifEmployerContribution.
  ///
  /// In en, this message translates to:
  /// **'Employer UIF contribution (1%):'**
  String get uifEmployerContribution;

  /// No description provided for @uifTotalPayable.
  ///
  /// In en, this message translates to:
  /// **'TOTAL UIF PAYABLE (Empl. + Emplr.):'**
  String get uifTotalPayable;

  /// No description provided for @leavePdfTitle.
  ///
  /// In en, this message translates to:
  /// **'LEAVE RECORDS'**
  String get leavePdfTitle;

  /// No description provided for @leavePdfGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {date}'**
  String leavePdfGenerated(String date);

  /// No description provided for @leavePdfHoursNote.
  ///
  /// In en, this message translates to:
  /// **'Values in hours (days = hours ÷ 8)'**
  String get leavePdfHoursNote;

  /// No description provided for @leavePdfNoEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees.'**
  String get leavePdfNoEmployees;

  /// No description provided for @leavePdfColType.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leavePdfColType;

  /// No description provided for @leavePdfOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get leavePdfOpening;

  /// No description provided for @leavePdfHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday (HL)'**
  String get leavePdfHoliday;

  /// No description provided for @leavePdfSick.
  ///
  /// In en, this message translates to:
  /// **'Sick (SL)'**
  String get leavePdfSick;

  /// No description provided for @leavePdfFamily.
  ///
  /// In en, this message translates to:
  /// **'Family (FL)'**
  String get leavePdfFamily;

  /// No description provided for @leavePdfFormula.
  ///
  /// In en, this message translates to:
  /// **'Balance = Opening (pre-system) + Accrued (in-system) − Taken.'**
  String get leavePdfFormula;

  /// No description provided for @xlsSheet.
  ///
  /// In en, this message translates to:
  /// **'Payslips'**
  String get xlsSheet;

  /// No description provided for @xlsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get xlsType;

  /// No description provided for @xlsJob.
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get xlsJob;

  /// No description provided for @xlsSickHrs.
  ///
  /// In en, this message translates to:
  /// **'Sick hrs'**
  String get xlsSickHrs;

  /// No description provided for @xlsHolidayHrs.
  ///
  /// In en, this message translates to:
  /// **'Holiday hrs'**
  String get xlsHolidayHrs;

  /// No description provided for @xlsFamilyHrs.
  ///
  /// In en, this message translates to:
  /// **'Family hrs'**
  String get xlsFamilyHrs;

  /// No description provided for @xlsGross.
  ///
  /// In en, this message translates to:
  /// **'Gross (R)'**
  String get xlsGross;

  /// No description provided for @xlsPaye.
  ///
  /// In en, this message translates to:
  /// **'PAYE (R)'**
  String get xlsPaye;

  /// No description provided for @xlsUif.
  ///
  /// In en, this message translates to:
  /// **'UIF 1% (R)'**
  String get xlsUif;

  /// No description provided for @xlsOtherDed.
  ///
  /// In en, this message translates to:
  /// **'Other deductions (R)'**
  String get xlsOtherDed;

  /// No description provided for @xlsTotalDed.
  ///
  /// In en, this message translates to:
  /// **'Total deductions (R)'**
  String get xlsTotalDed;

  /// No description provided for @xlsNet.
  ///
  /// In en, this message translates to:
  /// **'Net (R)'**
  String get xlsNet;

  /// No description provided for @xlsTotalRow.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ({count})'**
  String xlsTotalRow(int count);

  /// No description provided for @xlsFileName.
  ///
  /// In en, this message translates to:
  /// **'{company} Payslips {period}.xlsx'**
  String xlsFileName(String company, String period);

  /// No description provided for @zipFileName.
  ///
  /// In en, this message translates to:
  /// **'{company} Payslips.zip'**
  String zipFileName(String company);

  /// No description provided for @frFileName.
  ///
  /// In en, this message translates to:
  /// **'{company} Farm Register {stamp}.pdf'**
  String frFileName(String company, String stamp);

  /// No description provided for @frTitle.
  ///
  /// In en, this message translates to:
  /// **'FARM REGISTER'**
  String get frTitle;

  /// No description provided for @frFarm.
  ///
  /// In en, this message translates to:
  /// **'Farm: {name}'**
  String frFarm(String name);

  /// No description provided for @frCountry.
  ///
  /// In en, this message translates to:
  /// **'Country: {name}'**
  String frCountry(String name);

  /// No description provided for @frLocation.
  ///
  /// In en, this message translates to:
  /// **'Location: {lat}, {lng}'**
  String frLocation(String lat, String lng);

  /// No description provided for @frGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated: {date}'**
  String frGenerated(String date);

  /// No description provided for @frCounts.
  ///
  /// In en, this message translates to:
  /// **'{fields} fields · {area} ha · {equipment} equipment · {people} people'**
  String frCounts(int fields, String area, int equipment, int people);

  /// No description provided for @frFieldsSection.
  ///
  /// In en, this message translates to:
  /// **'FIELDS / BLOCKS'**
  String get frFieldsSection;

  /// No description provided for @frBlockField.
  ///
  /// In en, this message translates to:
  /// **'Block / Field'**
  String get frBlockField;

  /// No description provided for @frAreaHa.
  ///
  /// In en, this message translates to:
  /// **'Area (ha)'**
  String get frAreaHa;

  /// No description provided for @frEquipmentSection.
  ///
  /// In en, this message translates to:
  /// **'EQUIPMENT REGISTER'**
  String get frEquipmentSection;

  /// No description provided for @frCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get frCapacity;

  /// No description provided for @frRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get frRate;

  /// No description provided for @frRegNo.
  ///
  /// In en, this message translates to:
  /// **'Reg. No.'**
  String get frRegNo;

  /// No description provided for @frInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get frInspection;

  /// No description provided for @frPeopleSection.
  ///
  /// In en, this message translates to:
  /// **'PEOPLE / ROLES'**
  String get frPeopleSection;

  /// No description provided for @frName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get frName;

  /// No description provided for @frEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get frEmail;

  /// No description provided for @frRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get frRole;

  /// No description provided for @frSource.
  ///
  /// In en, this message translates to:
  /// **'Source: Farmable Partner API v2.0. Generated by Crop Compliance for audit evidence.'**
  String get frSource;

  /// No description provided for @leaveCodePH.
  ///
  /// In en, this message translates to:
  /// **'PH'**
  String get leaveCodePH;

  /// No description provided for @leaveCodeA.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get leaveCodeA;

  /// No description provided for @tsLeaveCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave codes'**
  String get tsLeaveCodesTitle;

  /// No description provided for @tsLeaveHintPick.
  ///
  /// In en, this message translates to:
  /// **'Click a day in the grid, then a code — or type the code straight into the day.'**
  String get tsLeaveHintPick;

  /// No description provided for @tsLeaveHintTarget.
  ///
  /// In en, this message translates to:
  /// **'Filling {name} · {day} — moves to the next day after each code.'**
  String tsLeaveHintTarget(String name, String day);

  /// No description provided for @tsLeavePickDayFirst.
  ///
  /// In en, this message translates to:
  /// **'Click the day in the grid first, then the leave code.'**
  String get tsLeavePickDayFirst;

  /// No description provided for @tsCodeSL.
  ///
  /// In en, this message translates to:
  /// **'Sick leave'**
  String get tsCodeSL;

  /// No description provided for @tsCodeHL.
  ///
  /// In en, this message translates to:
  /// **'Holiday leave'**
  String get tsCodeHL;

  /// No description provided for @tsCodeFL.
  ///
  /// In en, this message translates to:
  /// **'Family responsibility'**
  String get tsCodeFL;

  /// No description provided for @tsCodePH.
  ///
  /// In en, this message translates to:
  /// **'Public holiday'**
  String get tsCodePH;

  /// No description provided for @tsCodeA.
  ///
  /// In en, this message translates to:
  /// **'Absent (unpaid)'**
  String get tsCodeA;

  /// No description provided for @tsCodeClear.
  ///
  /// In en, this message translates to:
  /// **'Clear day'**
  String get tsCodeClear;

  /// No description provided for @tsCodeTipSL.
  ///
  /// In en, this message translates to:
  /// **'Paid as one ordinary day ({hours} h) and taken off the employee’s sick-leave balance.'**
  String tsCodeTipSL(String hours);

  /// No description provided for @tsCodeTipHL.
  ///
  /// In en, this message translates to:
  /// **'Paid as one ordinary day ({hours} h) and taken off the employee’s holiday-leave balance.'**
  String tsCodeTipHL(String hours);

  /// No description provided for @tsCodeTipFL.
  ///
  /// In en, this message translates to:
  /// **'Paid as one ordinary day ({hours} h) and taken off the employee’s family-responsibility leave balance.'**
  String tsCodeTipFL(String hours);

  /// No description provided for @tsCodeTipPH.
  ///
  /// In en, this message translates to:
  /// **'Public holiday not worked: paid as one ordinary day ({hours} h). If they worked it, type their hours instead.'**
  String tsCodeTipPH(String hours);

  /// No description provided for @tsCodeTipA.
  ///
  /// In en, this message translates to:
  /// **'Absent — this day is not paid.'**
  String get tsCodeTipA;

  /// No description provided for @tsCodeTipClear.
  ///
  /// In en, this message translates to:
  /// **'Empty the selected day.'**
  String get tsCodeTipClear;

  /// No description provided for @farmChooseToContinue.
  ///
  /// In en, this message translates to:
  /// **'Choose a farm'**
  String get farmChooseToContinue;

  /// No description provided for @pdfDownloadBtn.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get pdfDownloadBtn;

  /// No description provided for @pdfOpenPrint.
  ///
  /// In en, this message translates to:
  /// **'Open / print'**
  String get pdfOpenPrint;

  /// No description provided for @psPayeBelowThreshold.
  ///
  /// In en, this message translates to:
  /// **'Below the tax threshold — no PAYE due this period'**
  String get psPayeBelowThreshold;

  /// No description provided for @psEarningsCaps.
  ///
  /// In en, this message translates to:
  /// **'EARNINGS'**
  String get psEarningsCaps;

  /// No description provided for @psDeductionsCaps.
  ///
  /// In en, this message translates to:
  /// **'DEDUCTIONS'**
  String get psDeductionsCaps;

  /// No description provided for @tsPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Timesheet {company} {start}.pdf'**
  String tsPdfFile(String company, String start);

  /// No description provided for @tsPdfHeading.
  ///
  /// In en, this message translates to:
  /// **'Timesheet · {sheet}'**
  String tsPdfHeading(String sheet);

  /// No description provided for @tsPdfDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft — not finalised'**
  String get tsPdfDraft;

  /// No description provided for @tsPdfPrinted.
  ///
  /// In en, this message translates to:
  /// **'Printed {date}'**
  String tsPdfPrinted(String date);

  /// No description provided for @tsPdfChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked by: ______________________________      Signature: ______________________________      Date: ____________________'**
  String get tsPdfChecked;

  /// No description provided for @tsPdfPieceLegend.
  ///
  /// In en, this message translates to:
  /// **'Each day: hours worked (h) and {unit} picked.'**
  String tsPdfPieceLegend(String unit);

  /// No description provided for @tsPdfDownloading.
  ///
  /// In en, this message translates to:
  /// **'Making the timesheet PDF…'**
  String get tsPdfDownloading;

  /// No description provided for @tsLeaveUnpaidTip.
  ///
  /// In en, this message translates to:
  /// **'Unpaid — not enough {leave} left (chosen when saving). Type the code again to have it checked again.'**
  String tsLeaveUnpaidTip(String leave);

  /// No description provided for @tsLeavePartTip.
  ///
  /// In en, this message translates to:
  /// **'{hours} h paid, the rest unpaid — not enough {leave} left (chosen when saving). Type the code again to have it checked again.'**
  String tsLeavePartTip(String hours, String leave);

  /// No description provided for @tsLeaveOverrideTip.
  ///
  /// In en, this message translates to:
  /// **'Paid in full although the {leave} balance was short (chosen when saving). Type the code again to have it checked again.'**
  String tsLeaveOverrideTip(String leave);

  /// No description provided for @tsUnpaidBadge.
  ///
  /// In en, this message translates to:
  /// **'{hours} h unpaid'**
  String tsUnpaidBadge(String hours);

  /// No description provided for @tsLeaveUnpaidLegend.
  ///
  /// In en, this message translates to:
  /// **'= unpaid or partly paid — not enough leave left, as chosen when saving. Type the code again to have the day checked again.'**
  String get tsLeaveUnpaidLegend;

  /// No description provided for @tsPdfUnpaidLegend.
  ///
  /// In en, this message translates to:
  /// **'A number under a leave code = hours paid for that day (not enough leave left).'**
  String get tsPdfUnpaidLegend;

  /// No description provided for @tsLeaveSettledToast.
  ///
  /// In en, this message translates to:
  /// **'Your choices are on the timesheet: crossed-out days are unpaid.'**
  String get tsLeaveSettledToast;

  /// No description provided for @tsSavedNoPayslipsYet.
  ///
  /// In en, this message translates to:
  /// **'Timesheet saved — but no payslips were made yet. Choose what to do with the leave (blue banner → Make payslips).'**
  String get tsSavedNoPayslipsYet;

  /// No description provided for @tsPayslipsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Timesheet saved, but 1 payslip could not be saved: {error}} other{Timesheet saved, but {count} payslips could not be saved: {error}}}'**
  String tsPayslipsSaveFailed(int count, String error);

  /// No description provided for @tsNoPayslipBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 worker has hours on this timesheet but no payslip yet ({names}).} other{{count} workers have hours on this timesheet but no payslip yet ({names}).}}'**
  String tsNoPayslipBanner(int count, String names);

  /// No description provided for @tsMakePayslips.
  ///
  /// In en, this message translates to:
  /// **'Make payslips'**
  String get tsMakePayslips;
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
      <String>['af', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return AppLocalizationsAf();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
