// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Afrikaans (`af`).
class AppLocalizationsAf extends AppLocalizations {
  AppLocalizationsAf([String locale = 'af']) : super(locale);

  @override
  String get languageName => 'Afrikaans';

  @override
  String get language => 'Taal';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAfrikaans => 'Afrikaans';

  @override
  String get appTitle => 'Crop Compliance';

  @override
  String get commonCancel => 'Kanselleer';

  @override
  String get commonClose => 'Maak toe';

  @override
  String get commonOpen => 'Maak oop';

  @override
  String get commonSwitch => 'Wissel';

  @override
  String get commonRetry => 'Probeer weer';

  @override
  String get navHome => 'Tuis';

  @override
  String get navAuditChecklist => 'Ouditkontrolelys';

  @override
  String get navPayslips => 'Salarisstrokies';

  @override
  String get navProfile => 'Profiel';

  @override
  String get notificationsTitle => 'Kennisgewings';

  @override
  String get signOut => 'Teken uit';

  @override
  String get farm => 'Plaas';

  @override
  String get farmOpenLabel => 'Plaas oop';

  @override
  String get farmNoneViewingAll => 'Geen — jy sien alle plase';

  @override
  String get farmOpenAFarm => 'Maak ’n plaas oop';

  @override
  String get farmSwitchFarm => 'Wissel plaas';

  @override
  String get farmChooseAFarm => 'Kies ’n plaas';

  @override
  String get farmBackToAll => 'Terug na alle plase';

  @override
  String farmViewing(String name) {
    return 'Besig met plaas $name';
  }

  @override
  String unreadCountNew(int count) {
    return '$count nuut';
  }

  @override
  String get syncOffline => 'Vanlyn — jou werk word op hierdie foon gestoor';

  @override
  String syncFilesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lêers wag om opgelaai te word',
      one: '1 lêer wag om opgelaai te word',
    );
    return '$_temp0';
  }

  @override
  String get syncAllSynced => 'Alles is gesinkroniseer';

  @override
  String get syncUploadNow => 'Laai nou op';

  @override
  String get signOutConfirmTitle => 'Teken uit?';

  @override
  String signOutPendingFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lêers wag nog om opgelaai te word.',
      one: '1 lêer wag nog om opgelaai te word.',
    );
    return '$_temp0 Hulle bly op hierdie foon en word opgelaai wanneer iemand weer hier aanteken en sein het.';
  }

  @override
  String get signOutCanSignInAgain => 'Jy kan enige tyd weer aanteken.';

  @override
  String get languageHint =>
      'Kies die taal vir die toep, jou kennisgewings en aflaaie.';

  @override
  String get farmWhichFarm => 'Watter plaas?';

  @override
  String get farmPickForChecklist =>
      'Kies die plaas wie se ouditkontrolelys jy wil sien.';

  @override
  String get farmPickForPayslips =>
      'Kies die plaas wie se salarisstrokies jy wil bestuur.';

  @override
  String get farmSearchHint => 'Soek plase…';

  @override
  String get farmLoadFailed =>
      'Kon nie die plase laai nie. Kontroleer jou sein en probeer weer.';

  @override
  String get farmNoSearchMatch => 'Geen plase pas by jou soektog nie.';

  @override
  String offlineWithFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Jy is vanlyn — jou werk word op hierdie foon gestoor. $count lêers sal opgelaai word wanneer jy weer aanlyn is.',
      one:
          'Jy is vanlyn — jou werk word op hierdie foon gestoor. 1 lêer sal opgelaai word wanneer jy weer aanlyn is.',
    );
    return '$_temp0';
  }

  @override
  String get offlineNoFiles =>
      'Jy is vanlyn — jou werk word op hierdie foon gestoor en sal sinkroniseer wanneer jy weer aanlyn is.';

  @override
  String offlineUploading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Weer aanlyn — laai $count lêers op…',
      one: 'Weer aanlyn — laai 1 lêer op…',
    );
    return '$_temp0';
  }

  @override
  String offlineRetrying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lêers wag om opgelaai te word — probeer binnekort weer.',
      one: '1 lêer wag om opgelaai te word — probeer binnekort weer.',
    );
    return '$_temp0';
  }

  @override
  String get offlineRetryNow => 'Probeer nou weer';

  @override
  String pendingSavedOfflineTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vanlyn gestoor — $count lêers sal outomaties opgelaai word wanneer die foon weer aanlyn is.',
      one:
          'Vanlyn gestoor — 1 lêer sal outomaties opgelaai word wanneer die foon weer aanlyn is.',
    );
    return '$_temp0';
  }

  @override
  String get pendingWaitingToUpload => 'Wag om op te laai';

  @override
  String pendingSavedOnThisPhone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lêers op hierdie foon gestoor — word outomaties opgelaai wanneer jy aanlyn is.',
      one:
          '1 lêer op hierdie foon gestoor — word outomaties opgelaai wanneer jy aanlyn is.',
    );
    return '$_temp0';
  }

  @override
  String pendingUploadingFromOtherPhone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lêers word nog opgelaai van die foon waarop hulle gestoor is.',
      one: '1 lêer word nog opgelaai van die foon waarop dit gestoor is.',
    );
    return '$_temp0';
  }

  @override
  String get adminSortMostPending => 'Meeste hangende eerste';

  @override
  String get adminSortName => 'Naam (A–Z)';

  @override
  String get adminSortLowest => 'Laagste vordering eerste';

  @override
  String get adminSortHighest => 'Hoogste vordering eerste';

  @override
  String get adminDashboardTitle => 'Admin-paneelbord';

  @override
  String get adminTools => 'Admin-gereedskap';

  @override
  String get commonSearchHint => 'Soek…';

  @override
  String get adminShowTwoPerRow => 'Wys twee plase per ry';

  @override
  String get adminShowOnePerRow => 'Wys een plaas per ry';

  @override
  String get adminSortAndFilter => 'Sorteer en filtreer';

  @override
  String get adminLoadFailed =>
      'Kon nie die plase laai nie. As jy vanlyn is, koppel en probeer weer.';

  @override
  String get adminNoFarmsYet => 'Daar is nog geen plase nie.';

  @override
  String get adminNoFarmsMatch =>
      'Geen plase pas by jou soektog of filters nie.';

  @override
  String get adminAddFarm => 'Voeg ’n plaas by';

  @override
  String get adminClearSearchFilters => 'Maak soektog en filters skoon';

  @override
  String get commonReset => 'Herstel';

  @override
  String get adminSortBy => 'Sorteer volgens';

  @override
  String get adminStandards => 'Standaarde';

  @override
  String get adminOnlyPending => 'Net plase met hangende dokumente';

  @override
  String adminShowFarms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wys $count plase',
      one: 'Wys 1 plaas',
    );
    return '$_temp0';
  }

  @override
  String get menuCompanyManagement => 'Maatskappybestuur';

  @override
  String get menuUserManagement => 'Gebruikerbestuur';

  @override
  String get menuCategoryManagement => 'Kategoriebestuur';

  @override
  String get menuDocumentSettings => 'Dokumentinstellings';

  @override
  String get menuDataFixUtility => 'Datahersteller';

  @override
  String get menuFarmableConsole => 'Farmable API-konsole';

  @override
  String adminFarmCardSemantics(String name, int pending, int percent) {
    return '$name, $pending hangende dokumente, $percent persent voltooi';
  }

  @override
  String get farmNoAddress => 'Nog geen adres nie';

  @override
  String pendingDocumentsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hangende dokumente',
      one: 'Hangende dokument',
    );
    return '$_temp0';
  }

  @override
  String employeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Werknemers',
      one: '1 Werknemer',
    );
    return '$_temp0';
  }

  @override
  String get statusApproved => 'Goedgekeur';

  @override
  String get statusInReview => 'Word nagegaan';

  @override
  String get statusRejected => 'Afgekeur';

  @override
  String get statusExpired => 'Verval';

  @override
  String get statusNotApplicable => 'N.v.t.';

  @override
  String get statusToUpload => 'Moet opgelaai word';

  @override
  String get trackerTitle => 'Nakomingsvolger';

  @override
  String get trackerNoStandards =>
      'Daar is nog geen ouditstandaarde vir hierdie plaas aangeskakel nie.';

  @override
  String get trackerAskAdmin =>
      'Vra jou Crop Compliance-administrateur om SIZA/WIETA, GlobalG.A.P., IPW, Fairtrade of SIZA Environmental vir jou plaas aan te skakel.';

  @override
  String get trackerOpenChecklist => 'Maak ouditkontrolelys oop';

  @override
  String get trackerOverallProgress => 'Algehele vordering';

  @override
  String get trackerYouAreHere => 'Jy is hier';

  @override
  String get trackerBehindYou => 'Agter jou';

  @override
  String trackerDoneCount(int count) {
    return '$count klaar';
  }

  @override
  String get trackerFirstUploadHere => 'Jou eerste oplaai sal hier wys';

  @override
  String trackerAndMore(int count) {
    return '…en nog $count';
  }

  @override
  String get trackerAllCaughtUp =>
      'Alles op datum — elke vereiste is ingedien.';

  @override
  String get statusRequired => 'Vereis';

  @override
  String trackerHintRejectedReason(String reason) {
    return 'Dit is afgekeur: $reason. Laai ’n verbeterde weergawe op.';
  }

  @override
  String get trackerHintRejected =>
      'Dit is afgekeur. Laai ’n verbeterde weergawe op.';

  @override
  String get trackerHintExpired =>
      'Dit het verval. Laai die hernude dokument op.';

  @override
  String trackerHintUpload(String type, String category) {
    return 'Laai die $type vir $category op.';
  }

  @override
  String get trackerRightNow => 'Nou';

  @override
  String get trackerInFront => 'Voor jou';

  @override
  String trackerToGo(int count) {
    return 'Nog $count';
  }

  @override
  String get trackerNothingLeft => 'Niks oor nie';

  @override
  String get trackerLastOne => 'Dit is die laaste een';

  @override
  String actionResubmitType(String type) {
    return 'Dien $type weer in';
  }

  @override
  String actionRenewType(String type) {
    return 'Hernu $type';
  }

  @override
  String actionUploadType(String type) {
    return 'Laai $type op';
  }

  @override
  String get checklistTitle => 'Ouditkontrolelys';

  @override
  String get checklistAskAdmin =>
      'Vra jou Crop Compliance-administrateur om een vir jou plaas aan te skakel.';

  @override
  String get checklistNothingInCategory =>
      'Niks om in hierdie kategorie op te laai nie.';

  @override
  String get checklistSeeAllUploaded => 'Sien alle opgelaaide dokumente';

  @override
  String get ruleMultipleAllowed => 'Meer as een dokument toegelaat';

  @override
  String get ruleHasExpiry => 'Het ’n vervaldatum';

  @override
  String get ruleFilledInApp => 'Word op die toep ingevul';

  @override
  String get actionUpload => 'Laai op';

  @override
  String get actionFillIn => 'Vul in';

  @override
  String get actionFix => 'Herstel';

  @override
  String get actionRenew => 'Hernu';

  @override
  String get uploadTakePhoto => 'Neem ’n foto';

  @override
  String get uploadChooseFileTypes => 'Kies ’n lêer (PDF, Word, foto)';

  @override
  String get commonLoading => 'Laai tans…';

  @override
  String get uploadNeedFileFirst => 'Kies eers ’n lêer of neem ’n foto.';

  @override
  String get uploadNeedExpiry => 'Tik die vervaldatum op die kalender.';

  @override
  String get uploadNeedReviewed => 'Kies die datum waarop dit laas hersien is.';

  @override
  String get uploadNeedSpec =>
      'Voeg ’n spesifikasie by — wat dek hierdie oplaai?';

  @override
  String get uploadNoFarm =>
      'Geen plaas gekies nie — maak die paneelbord oop en probeer weer.';

  @override
  String errorSomethingWrong(String error) {
    return 'Iets het skeefgeloop: $error';
  }

  @override
  String get uploadFailed =>
      'Die oplaai het nie deurgegaan nie — probeer asseblief weer.';

  @override
  String get uploadSavedOffline =>
      'Op jou foon gestoor — dit sal outomaties opgelaai word wanneer jy aanlyn is.';

  @override
  String get uploadDoneWaitingReview =>
      'Opgelaai — dit wag nou om nagegaan te word.';

  @override
  String get uploadTapExpiry => 'Tik die vervaldatum';

  @override
  String get uploadSubtitleWithExpiry =>
      'Laai die dokument op en stel sy vervaldatum';

  @override
  String get uploadSubtitle => 'Laai die dokument op';

  @override
  String get uploadSpecRequired => 'Spesifikasie (verpligtend)';

  @override
  String get uploadSpecOptional => 'Spesifikasie (opsioneel)';

  @override
  String get uploadSpecHint => 'Wat dek dit? bv. perseel, tydperk';

  @override
  String get uploadChooseFileOrPhoto => 'Kies ’n lêer of foto';

  @override
  String get uploadTypeLoadFailed =>
      'Hierdie dokumenttipe kon nie gelaai word nie.';

  @override
  String get expiryDate => 'Vervaldatum';

  @override
  String get uploadNoFileYet => 'Nog geen lêer gekies nie';

  @override
  String uploadFileAndMore(String name, int count) {
    return '$name + nog $count';
  }

  @override
  String get actionChange => 'Verander';

  @override
  String get uploadExpiryLabel => 'Vervaldatum: ';

  @override
  String get uploadNotSet => 'nie gestel nie';

  @override
  String uploadSelectedDocs(int count) {
    return 'Gekose dokumente ($count)';
  }

  @override
  String get actionPreview => 'Voorskou';

  @override
  String get dateLastReviewed => 'Datum laas hersien';

  @override
  String get dateLastReviewedRequired => 'Datum laas hersien (verpligtend)';

  @override
  String lastReviewedOn(String date) {
    return 'Laas hersien: $date';
  }

  @override
  String get hoursTabRate => 'Tarief\n(R/uur)';

  @override
  String get hoursTabNormal => 'Norm\nure';

  @override
  String get hoursTabOvertime => 'OT\nure';

  @override
  String get hoursTabDouble => 'DT\nure';

  @override
  String get hoursTabPublicHoliday => 'OV\nure';

  @override
  String get hoursTabSick => 'SV\nure';

  @override
  String get hoursTabHoliday => 'VV\nure';

  @override
  String get hoursTabFamily => 'GV\nure';

  @override
  String get hoursTypeNumber => 'Tik ’n getal, bv. 8 of 7.5';

  @override
  String hoursSetRateFirst(String name) {
    return 'Stel eers $name se uurtarief.';
  }

  @override
  String get hoursEnterFirst => 'Vul eers die ure gewerk in.';

  @override
  String get payslipReplaceTitle => 'Vervang hierdie salarisstrokie?';

  @override
  String payslipReplaceBody(String name, String start, String end) {
    return '$name het reeds ’n salarisstrokie vir $start – $end. Vervang dit met hierdie ure?';
  }

  @override
  String get actionReplace => 'Vervang';

  @override
  String get payslipSaveFailed =>
      'Die salarisstrokie kon nie gestoor word nie — probeer asseblief weer.';

  @override
  String payslipSavedFor(String name, String amount) {
    return 'Salarisstrokie vir $name gestoor — netto $amount';
  }

  @override
  String get periodStart => 'Begin van tydperk';

  @override
  String get periodEnd => 'Einde van tydperk';

  @override
  String payslipsHeaderTitle(String farm) {
    return '$farm – Salarisstrokies';
  }

  @override
  String get employeesLabel => 'Werknemers';

  @override
  String get chooseFarmFirst => 'Kies eers ’n plaas.';

  @override
  String get employeeLabel => 'Werknemer';

  @override
  String get actionViewAll => 'Sien alles';

  @override
  String get hoursWorked => 'Ure gewerk';

  @override
  String payslipNoneYetFor(String name) {
    return 'Nog geen salarisstrokie vir $name nie. Vul die ure hieronder in en stoor.';
  }

  @override
  String payslipNormalPayHours(String hours) {
    return 'Normale Loon ($hours h)';
  }

  @override
  String payslipOvertimePayHours(String hours) {
    return 'Oortyd Loon ($hours h)';
  }

  @override
  String payslipDoubleTimeHours(String hours) {
    return 'Dubbel Tyd ($hours h)';
  }

  @override
  String payslipPublicHolidayHours(String hours) {
    return 'Openbare Vakansie ($hours h)';
  }

  @override
  String payslipSickLeaveHours(String hours) {
    return 'Siekteverlof ($hours h)';
  }

  @override
  String payslipAnnualLeaveHours(String hours) {
    return 'Vakansieverlof ($hours h)';
  }

  @override
  String payslipFamilyLeaveHours(String hours) {
    return 'Gesinsverlof ($hours h)';
  }

  @override
  String get payslipTitle => 'SALARIS STROKIE';

  @override
  String get payslipName => 'Naam';

  @override
  String get payslipIdNumber => 'ID Nommer';

  @override
  String get payslipPeriod => 'Periode';

  @override
  String get payslipPayDate => 'Betaaldatum';

  @override
  String get payslipEarnings => 'VERDIENSTE';

  @override
  String get payslipTotalEarnings => 'TOTALE INKOMSTE';

  @override
  String get payslipDeductions => 'AFTREKKINGS';

  @override
  String get payslipUifEmployee => 'UIF Werknemer (1%)';

  @override
  String get payslipPayeTax => 'PAYE Belasting';

  @override
  String get payslipTotalDeductions => 'TOTALE AFTREKKINGS';

  @override
  String get payslipNetSalary => 'Netto Salaris';

  @override
  String get actionDownloadPdf => 'Laai PDF af';

  @override
  String pdfOpenFailed(String error) {
    return 'Kon nie die PDF oopmaak nie: $error';
  }

  @override
  String get employeesNoneYetTapAdd =>
      'Nog geen werknemers nie — tik om jou eerste een by te voeg.';

  @override
  String get employeeNoId => 'Geen ID';

  @override
  String employeeIdShort(String id) {
    return 'ID $id';
  }

  @override
  String get employeeSearchHint => 'Soek naam of ID';

  @override
  String get employeeAdd => 'Voeg werknemer by';

  @override
  String get actionEdit => 'Wysig';

  @override
  String saveFailedReason(String reason) {
    return 'Kon nie stoor nie: $reason';
  }

  @override
  String get errorUnknown => 'onbekende fout';

  @override
  String hoursLeft(String hours) {
    return '$hours h oor';
  }

  @override
  String get hoursHelpRate =>
      'Werknemer se basiese uurloon in Rand, wat gebruik word om alle verdienste te bereken';

  @override
  String get hoursHelpNormal => 'Gewone ure gewerk in hierdie tydperk';

  @override
  String get hoursHelpOvertime => 'Oortydure — betaal teen 1.5 × die tarief';

  @override
  String get hoursHelpDouble =>
      'Dubbeltydure (bv. Sondae) — betaal teen 2 × die tarief';

  @override
  String get hoursHelpPublicHoliday => 'Betaalde openbarevakansiedag-ure';

  @override
  String hoursHelpSick(String balance) {
    return 'Siekverlof geneem · $balance';
  }

  @override
  String hoursHelpHoliday(String balance) {
    return 'Jaarlikse verlof geneem · $balance';
  }

  @override
  String hoursHelpFamily(String balance) {
    return 'Gesinsverantwoordelikheidsverlof · $balance';
  }

  @override
  String employeeIdLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get dateStart => 'Begin';

  @override
  String get dateEnd => 'Einde';

  @override
  String get actionSetDone => 'Stel ✓';

  @override
  String get actionSet => 'Stel';

  @override
  String hoursEntered(String list) {
    return 'Ingevul: $list';
  }

  @override
  String payslipSaveFor(String name) {
    return 'Stoor salarisstrokie vir $name';
  }

  @override
  String get dashboardTitle => 'Paneelbord';

  @override
  String get kpiCompletionRate => 'Voltooiingskoers';

  @override
  String get kpiApprovalRate => 'Goedkeuringskoers';

  @override
  String get kpiPendingReview => 'Wag op nagaan';

  @override
  String get docsNoneYet => 'Nog geen dokumente nie.';

  @override
  String get documentsTitle => 'Dokumente';

  @override
  String get documentLabel => 'Dokument';

  @override
  String get statusPending => 'Hangend';

  @override
  String get dashboardDocumentComments => 'Dokumentkommentaar';

  @override
  String get dashboardAllGood => 'Alle dokumente is in orde';

  @override
  String rejectedOnDate(String date) {
    return 'Afgekeur - $date';
  }

  @override
  String get actionResubmit => 'Dien weer in';

  @override
  String get farmPickForPage =>
      'Hierdie bladsy wys een plaas. Kies die plaas waaraan jy wil werk.';

  @override
  String get menuComplianceReport => 'Nakomingsverslag';

  @override
  String get menuAuditIndex => 'Ouditindeks';

  @override
  String get menuPayslipManager => 'Salarisstrokiebestuurder';

  @override
  String get menuMyFarms => 'My plase';

  @override
  String get menuFarmRegister => 'Plaasregister';

  @override
  String get menuSprayRecords => 'Spuitrekords';

  @override
  String get menuFarmableSection => 'FARMABLE';

  @override
  String get logout => 'Teken uit';

  @override
  String get menuCollapse => 'Vou in';

  @override
  String get farmSelect => 'Kies plaas';

  @override
  String farmSwitchTooltip(String name) {
    return 'Wissel plaas — $name';
  }

  @override
  String get farmSwitchFailed =>
      'Kon nie plaas wissel nie. Probeer asseblief weer.';

  @override
  String get adminModeManagingFor => 'ADMIN-MODUS: Bestuur dokumente vir ';

  @override
  String get adminModeOwnDocs => 'Admin-modus: Bestuur jou eie dokumente';

  @override
  String get actionSwitchBack => 'Wissel terug';

  @override
  String get selectUserToManage => 'Kies gebruiker om te bestuur';

  @override
  String get selectUserToManageHint =>
      'Kies ’n gebruiker om hul dokumente en nakomingstatus te bestuur.';

  @override
  String get you => 'Jy';

  @override
  String get manageOwnDocs => 'Bestuur jou eie dokumente';

  @override
  String get farmTapToSwitch => 'Tik om plaas te wissel';

  @override
  String farmAccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jy het toegang tot $count plase.',
      one: 'Jy het toegang tot 1 plaas.',
    );
    return '$_temp0';
  }

  @override
  String farmNoMatchQuery(String query) {
    return 'Geen plase pas by “$query” nie';
  }

  @override
  String get errorTitle => 'Fout';

  @override
  String get actionRetry => 'Probeer weer';

  @override
  String get statusExpiresSoon => 'Verval binnekort';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleAuditor => 'Ouditeur';

  @override
  String get roleUser => 'Gebruiker';

  @override
  String get loginTagline1 => 'Vereenvoudigde nakoming,';

  @override
  String get loginTagline2 => 'Gewaarborgde sukses';

  @override
  String get loginFeature1 => 'Vaartbelynde dokumentbestuur';

  @override
  String get loginFeature2 => 'Intydse nakomingsopvolging';

  @override
  String get loginFeature3 => 'Moeitelose oudit-voorbereiding';

  @override
  String get loginFeature4 => 'Omvattende nakomingsverslae';

  @override
  String loginCopyright(String year) {
    return '© $year Crop Compliance. Alle regte voorbehou.';
  }

  @override
  String get loginWelcomeBack => 'Welkom terug!';

  @override
  String get loginEnterCredentials =>
      'Vul jou besonderhede in om by jou rekening in te gaan';

  @override
  String get fieldEmail => 'E-pos';

  @override
  String get fieldEmailHint => 'Vul jou e-pos in';

  @override
  String get validationEmailRequired => 'Vul asseblief jou e-pos in';

  @override
  String get validationEmailInvalid => 'Vul asseblief ’n geldige e-pos in';

  @override
  String get fieldPassword => 'Wagwoord';

  @override
  String get fieldPasswordHint => 'Vul jou wagwoord in';

  @override
  String get validationPasswordRequired => 'Vul asseblief jou wagwoord in';

  @override
  String get loginRememberMe => 'Onthou my';

  @override
  String get loginForgotPassword => 'Wagwoord vergeet?';

  @override
  String get signIn => 'Teken in';

  @override
  String get loginNoAccount => 'Het jy nie ’n rekening nie? ';

  @override
  String get loginContactSupport => 'Kontak ondersteuning';

  @override
  String get resetPasswordTitle => 'Stel wagwoord terug';

  @override
  String get resetPasswordBody =>
      'Vul jou rekening se e-pos in. Ons stuur ’n terugstel-skakel as daar ’n rekening is.';

  @override
  String get resetPasswordSpamHint =>
      'As dit nie binne ’n paar minute aankom nie, kyk in jou gemorspos — of kontak jou admin, wat direk ’n nuwe wagwoord vir jou kan stel.';

  @override
  String get validationEmailValidAddress => 'Vul ’n geldige e-posadres in';

  @override
  String resetPasswordSent(String email) {
    return 'As daar ’n rekening vir $email is, is ’n terugstel-e-pos op pad. Kyk in gemorspos as dit nie gou aankom nie.';
  }

  @override
  String get resetPasswordFailed =>
      'Iets het skeefgeloop. Kontak asseblief jou admin vir hulp om jou wagwoord terug te stel.';

  @override
  String get resetPasswordSend => 'Stuur terugstel-skakel';

  @override
  String get authSignedOut => 'Jy is uitgeteken. Teken asseblief weer in.';

  @override
  String get authOtherAccount =>
      'Hierdie blaaier is nou by ’n ander rekening aangeteken. Teken asseblief weer in.';

  @override
  String authInitFailed(String error) {
    return 'Kon nie die gebruiker laai nie: $error';
  }

  @override
  String authLoadUsersFailed(String error) {
    return 'Kon nie gebruikers laai nie: $error';
  }

  @override
  String authAdminView(String name) {
    return '$name (Admin-aansig)';
  }

  @override
  String get unknownUser => 'Onbekende gebruiker';

  @override
  String authManaging(String name) {
    return 'Bestuur $name';
  }

  @override
  String get authPersonalAccount => 'Persoonlike rekening';

  @override
  String get authInvalidLogin => 'Ongeldige e-pos of wagwoord';

  @override
  String authLoginFailed(String error) {
    return 'Aanteken het misluk: $error';
  }

  @override
  String get authRegisterFailed => 'Registrasie het misluk';

  @override
  String authRegisterFailedReason(String error) {
    return 'Registrasie het misluk: $error';
  }

  @override
  String authLogoutFailed(String error) {
    return 'Uitteken het misluk: $error';
  }

  @override
  String authResetFailed(String error) {
    return 'Wagwoord-terugstel het misluk: $error';
  }

  @override
  String get authDeactivated =>
      'Hierdie rekening is gedeaktiveer. Kontak asseblief jou administrateur.';

  @override
  String get pleaseLogIn => 'Teken asseblief in om voort te gaan';

  @override
  String get dashboardLoading => 'Laai paneelbord-data...';

  @override
  String get adminModeManagingCompany => 'ADMIN-MODUS: Bestuur maatskappy';

  @override
  String get adminModeManagingUser => 'ADMIN-MODUS: Bestuur gebruiker';

  @override
  String viaUser(String name) {
    return 'via $name';
  }

  @override
  String get switchBackOwnAccount => 'Wissel terug na jou eie rekening';

  @override
  String get userFallbackName => 'Gebruiker';

  @override
  String dashboardManagingName(String name) {
    return 'Bestuur: $name';
  }

  @override
  String dashboardHiName(String name) {
    return 'Hallo, $name';
  }

  @override
  String get dashboardOverview => 'Oorsig van dokumentnakoming';

  @override
  String get dashboardWelcomeBackShort => 'Welkom terug.';

  @override
  String get kpiActionNeeded => 'Aksie nodig';

  @override
  String get kpiRejectedItem => 'Afgekeurde item';

  @override
  String get kpiNeedsAttention => 'Vra aandag';

  @override
  String teamAllUsersManaging(String name) {
    return 'Alle gebruikers (bestuur: $name)';
  }

  @override
  String get teamAllUsers => 'Alle gebruikers';

  @override
  String get teamMembers => 'Spanlede';

  @override
  String get teamAddUser => 'Voeg gebruiker by';

  @override
  String pageOf(int page, int total) {
    return 'Bladsy $page van $total';
  }

  @override
  String get teamNoUsers => 'Geen gebruikers gevind nie';

  @override
  String get noMatches => 'Geen resultate nie';

  @override
  String get teamLoadError => 'Kon nie die span laai nie';

  @override
  String get teamNoMembers => 'Geen spanlede nie';

  @override
  String teamLoadingDocsFor(String name) {
    return 'Laai $name se dokumente...';
  }

  @override
  String teamNowManaging(String name) {
    return 'Bestuur nou: $name';
  }

  @override
  String errorWithDetail(String error) {
    return 'Fout: $error';
  }

  @override
  String docsTotalCount(int count) {
    return '$count altesaam';
  }

  @override
  String get colDocumentType => 'Dokumenttipe';

  @override
  String get colStatus => 'Status';

  @override
  String get colUpdated => 'Opgedateer';

  @override
  String get colExpires => 'Verval';

  @override
  String get docsNoneFound => 'Geen dokumente gevind nie';

  @override
  String get commentsCardTitle => 'Dokumentkommentaar';

  @override
  String get commentsNoRejected =>
      'Geen afgekeurde dokumente met kommentaar nie';

  @override
  String get commentsAllGood => 'Alle dokumente is in orde';

  @override
  String get unknownDocument => 'Onbekende dokument';

  @override
  String get commentsActionRequired => 'Aksie nodig: Werk by en dien weer in';

  @override
  String get actionDetails => 'Besonderhede';

  @override
  String get adminDashLoadFailed => 'Kon nie die paneelbord laai nie.';

  @override
  String get somethingWentWrong => 'Iets het skeefgeloop';

  @override
  String get kpiCompanies => 'Maatskappye';

  @override
  String get kpiUsers => 'Gebruikers';

  @override
  String get adminSearchCompanies => 'Soek maatskappye...';

  @override
  String get actionRefresh => 'Verfris';

  @override
  String get adminNoCompanies => 'Geen maatskappye gevind nie';

  @override
  String get categoriesLoading => 'Laai kategorieë...';

  @override
  String get categoriesNoneFound => 'Geen kategorieë gevind nie';

  @override
  String docCountShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dokke',
      one: '1 dok',
    );
    return '$_temp0';
  }

  @override
  String get deleteSelectedEllipsis => 'Skrap gekose...';

  @override
  String deleteAllCount(int count) {
    return 'Skrap alles ($count)';
  }

  @override
  String get deleteAllDocsTitle => 'Skrap alle dokumente?';

  @override
  String deleteAllDocsIn(int count) {
    return 'Jy is op die punt om AL $count dokumente te skrap in:';
  }

  @override
  String get cannotBeUndone => '⚠️ Hierdie aksie KAN NIE ontdoen word nie!';

  @override
  String deleteAllCaps(int count) {
    return 'SKRAP ALLES ($count)';
  }

  @override
  String get selectDocsToDelete => 'Kies dokumente om te skrap';

  @override
  String selectedOfTotal(int selected, int total) {
    return '$selected van $total gekies';
  }

  @override
  String get actionSelectAll => 'Kies alles';

  @override
  String get actionClear => 'Maak skoon';

  @override
  String get unknownType => 'Onbekende tipe';

  @override
  String docDeleteLine(String status, int files, String date) {
    return 'Status: $status | Lêers: $files\nGeskep: $date';
  }

  @override
  String deleteCaps(int count) {
    return 'SKRAP ($count)';
  }

  @override
  String get confirmDeleteTitle => 'Bevestig skrapping';

  @override
  String confirmDeleteDocs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Is jy seker jy wil $count dokumente skrap?',
      one: 'Is jy seker jy wil 1 dokument skrap?',
    );
    return '$_temp0';
  }

  @override
  String deletingDocs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skrap $count dokumente...',
      one: 'Skrap 1 dokument...',
    );
    return '$_temp0';
  }

  @override
  String deletedDocsOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '✓ $count dokumente geskrap',
      one: '✓ 1 dokument geskrap',
    );
    return '$_temp0';
  }

  @override
  String deletedSomeFailed(int ok, int failed) {
    return '$ok geskrap, $failed het misluk';
  }

  @override
  String get docsLoading => 'Laai dokumente...';

  @override
  String get filterLabel => 'Filter';

  @override
  String get filterAll => 'Alles';

  @override
  String get docsSearchHint => 'Soek dokumente...';

  @override
  String get docsTryAdjusting => 'Probeer jou filters of soekterme verander';

  @override
  String documentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dokumente',
      one: '1 dokument',
    );
    return '$_temp0';
  }

  @override
  String get unknownDocumentType => 'Onbekende dokumenttipe';

  @override
  String get specification => 'Spesifikasie';

  @override
  String get specNone => 'Geen spesifikasie verskaf nie';

  @override
  String lastReviewedShort(String date) {
    return 'Laas hersien $date';
  }

  @override
  String reviewedSuffix(String date) {
    return ' · hersien $date';
  }

  @override
  String get uploadedBy => 'Opgelaai deur';

  @override
  String get uploadDate => 'Oplaaidatum';

  @override
  String get expiryDateTitle => 'Vervaldatum';

  @override
  String get expiryNone => 'Geen vervaldatum nie';

  @override
  String get statusLabelColon => 'Status: ';

  @override
  String get actionViewDetails => 'Sien besonderhede';

  @override
  String get filterDocsTitle => 'Filtreer dokumente';

  @override
  String get category => 'Kategorie';

  @override
  String get allCategories => 'Alle kategorieë';

  @override
  String get allStatuses => 'Alle statusse';

  @override
  String get notApplicable => 'Nie van toepassing nie';

  @override
  String get searchLabel => 'Soek';

  @override
  String get searchByDocType => 'Soek volgens dokumenttipe';

  @override
  String get unknownCategory => 'Onbekende kategorie';

  @override
  String categoryWithName(String name) {
    return 'Kategorie: $name';
  }

  @override
  String get previousVersion => 'Vorige weergawe';

  @override
  String get lastUpdated => 'Laas opgedateer';

  @override
  String get files => 'Lêers';

  @override
  String get signatures => 'Handtekeninge';

  @override
  String get comments => 'Kommentaar';

  @override
  String get rejectionComment => 'Afkeuringskommentaar:';

  @override
  String get photoDefaultName => 'Foto';

  @override
  String get trackerLoading => 'Laai ouditdata...';

  @override
  String get kpiApproval => 'Goedkeuring';

  @override
  String get kpiAllClear => 'Alles in orde';

  @override
  String get kpiFixRequired => 'Moet herstel word';

  @override
  String get kpiRejectedItems => 'Afgekeurde items';

  @override
  String get trackerNoApproved => 'Geen goedgekeurde dokumente nie';

  @override
  String get trackerNoActionItems => 'Geen aksie-items nie';

  @override
  String get filterColon => 'Filter: ';

  @override
  String get trackerActionItems => 'Aksie-items';

  @override
  String get trackerApprovedCurrent => 'Goedgekeur & geldig';

  @override
  String get unknown => 'Onbekend';

  @override
  String percentOverall(String percent) {
    return '$percent% algeheel';
  }

  @override
  String get trackerNoApprovedCurrent =>
      'Geen goedgekeurde dokumente wat geldig is en nie binnekort verval nie';

  @override
  String get expiredCaps => 'VERVAL';

  @override
  String get expiresSoonCaps => 'VERVAL BINNEKORT';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dae oor',
      one: '1 dag oor',
    );
    return '$_temp0';
  }

  @override
  String get expiresToday => 'Verval vandag';

  @override
  String get docExpiredRenew =>
      'Hierdie dokument het verval en moet hernu word';

  @override
  String get docExpiresSoonRenew =>
      'Hierdie dokument verval binnekort en moet dalk hernu word';

  @override
  String get commentsColon => 'Kommentaar:';

  @override
  String get uploadNewVersion => 'Laai nuwe weergawe op';

  @override
  String get actionDelete => 'Skrap';

  @override
  String get deleteDocTitle => 'Skrap dokument';

  @override
  String get deleteDocConfirm => 'Is jy seker jy wil hierdie dokument skrap?';

  @override
  String get deleteDocWarning =>
      'Hierdie aksie kan nie ontdoen word nie. Die dokument en al sy lêers word permanent geskrap.';

  @override
  String get deletingDoc => 'Skrap dokument...';

  @override
  String get docDeleted => 'Dokument geskrap';

  @override
  String get docDeleteFailed => 'Kon nie die dokument skrap nie';

  @override
  String docDeleteError(String error) {
    return 'Fout met skrap van dokument: $error';
  }

  @override
  String expiresOn(String date) {
    return 'Verval: $date';
  }

  @override
  String get noExpiryDate => 'Geen vervaldatum nie';

  @override
  String get docTypesNoneInCategory =>
      'Geen dokumenttipes in hierdie kategorie nie';

  @override
  String docsUploadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dokumente opgelaai',
      one: '1 dokument opgelaai',
    );
    return '$_temp0';
  }

  @override
  String get viewDocuments => 'Sien dokumente';

  @override
  String get specNoneShort => 'Geen spesifikasie nie';

  @override
  String uploadedOn(String date) {
    return 'Opgelaai: $date';
  }

  @override
  String get addAnotherDocument => 'Voeg nog ’n dokument by';

  @override
  String get addAnotherForm => 'Voeg nog ’n vorm by';

  @override
  String get actionFillForm => 'Vul vorm in';

  @override
  String get actionAddMore => 'Voeg meer by';

  @override
  String get actionAddForm => 'Voeg vorm by';

  @override
  String get actionUpdateForm => 'Werk vorm by';

  @override
  String get statusNotUploaded => 'Nie opgelaai nie';

  @override
  String get ruleRequiresExpiry => 'Vereis vervaldatum';

  @override
  String get ruleRequiresSignature => 'Vereis handtekening';

  @override
  String get ruleCanBeNa => 'Kan as N.v.t. gemerk word';

  @override
  String get catNoDocsAvailable => 'Geen dokumente beskikbaar nie';

  @override
  String catCompletedStatus(int done, int total, String percent) {
    return 'Voltooi: $done / $total ($percent%)';
  }

  @override
  String get catProgress => 'Kategorievordering';

  @override
  String get statusCompleted => 'Voltooi';

  @override
  String get viewDocument => 'Sien dokument';

  @override
  String get markNotApplicable => 'Merk as nie van toepassing nie';

  @override
  String get rejectionReason => 'Rede vir afkeuring:';

  @override
  String ruleRequiresSignatures(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vereis $count handtekeninge',
      one: 'Vereis 1 handtekening',
    );
    return '$_temp0';
  }

  @override
  String get reviewedPolicyHelp =>
      'Datum waarop hierdie beleid laas hersien is';

  @override
  String get actionDismiss => 'Maak toe';

  @override
  String uploadSelectFilesError(String error) {
    return 'Fout met kies van lêers: $error';
  }

  @override
  String get uploadSelectFilesFirst => 'Kies asseblief lêers om op te laai';

  @override
  String get uploadSelectExpiryAll =>
      'Kies asseblief ’n vervaldatum vir alle dokumente';

  @override
  String get uploadNeedSpecPlease =>
      'Voeg asseblief ’n spesifikasie by — wat dek hierdie oplaai?';

  @override
  String get uploadNeedReviewedPlease =>
      'Vul asseblief die datum in waarop dit laas hersien is';

  @override
  String get uploadNoContext => 'Fout: Geen gebruiker of maatskappy nie';

  @override
  String uploadedFileOk(String name) {
    return 'Opgelaai: $name';
  }

  @override
  String uploadedFileFailed(String name) {
    return 'Kon nie oplaai nie: $name';
  }

  @override
  String uploadedFileError(String name) {
    return 'Fout met oplaai: $name';
  }

  @override
  String get uploadAllOk => 'Alle dokumente is opgelaai!';

  @override
  String uploadSomeFailed(int ok, int failed) {
    return '$ok opgelaai, $failed het misluk';
  }

  @override
  String get uploadAllFailed => 'Alle oplaaie het misluk';

  @override
  String uploadDocsError(String error) {
    return 'Fout met oplaai van dokumente: $error';
  }

  @override
  String get uploadCardSubtitleExpiry =>
      'Laai dokumente op en stel vir elkeen ’n vervaldatum';

  @override
  String get uploadCardSubtitle => 'Laai dokumente vir hierdie kategorie op';

  @override
  String get uploadSpecHintLong =>
      'Wat dek dit? bv. perseel, tydperk, werkersgroep';

  @override
  String get uploadSpecHintOptional =>
      'Vul dokumentspesifikasie in (opsioneel)';

  @override
  String get uploadChooseReviewDate => 'Kies die hersieningsdatum';

  @override
  String get uploadTapToSelect => 'Tik om lêers te kies';

  @override
  String get uploadSupportedFormats =>
      'Ondersteunde formate: PDF, JPG, JPEG, PNG, DOC, DOCX';

  @override
  String uploadSelectedDocsTitle(int count) {
    return 'Gekose dokumente ($count)';
  }

  @override
  String get actionSetDate => 'Stel datum';

  @override
  String get uploadingDocs => 'Laai dokumente op...';

  @override
  String get uploadingDoc => 'Laai dokument op...';

  @override
  String uploadNDocs(int count) {
    return 'Laai $count dokumente op';
  }

  @override
  String get uploadOneDoc => 'Laai dokument op';

  @override
  String get uploadSelectAndUpload => 'Kies en laai dokumente op';

  @override
  String get docDetailsTitle => 'Dokumentbesonderhede';

  @override
  String get docLoading => 'Laai dokument...';

  @override
  String docLoadError(String error) {
    return 'Fout met laai van dokument: $error';
  }

  @override
  String get docNotAvailable => 'Hierdie dokument is nie beskikbaar nie.';

  @override
  String get docNotFound => 'Dokument nie gevind nie';

  @override
  String get bannerExpired => 'DOKUMENT HET VERVAL';

  @override
  String get bannerExpiredSub =>
      'Hierdie dokument het verval en moet bygewerk word';

  @override
  String get bannerRejected => 'DOKUMENT AFGEKEUR';

  @override
  String get bannerRejectedSub =>
      'Lees asseblief die terugvoer en dien weer in';

  @override
  String get bannerPending => 'WAG OP NAGAAN';

  @override
  String get bannerAwaitingYou => 'Wag vir jou om na te gaan';

  @override
  String get bannerAwaitingAdmin => 'Wag vir admin om na te gaan';

  @override
  String bannerValidUntil(String date) {
    return 'Geldig tot $date';
  }

  @override
  String get bannerApproved => 'Dokument is goedgekeur';

  @override
  String get bannerApprovedCaps => 'GOEDGEKEUR';

  @override
  String get bannerUnknown => 'ONBEKENDE STATUS';

  @override
  String get docInformation => 'Dokumentinligting';

  @override
  String get created => 'Geskep';

  @override
  String get actions => 'Aksies';

  @override
  String get resubmitDocCaps => 'DIEN DOKUMENT WEER IN';

  @override
  String get uploadNewVersionCaps => 'LAAI NUWE WEERGAWE OP';

  @override
  String addSignatureCaps(int done, int total) {
    return 'VOEG HANDTEKENING BY ($done/$total)';
  }

  @override
  String docFilesCount(int count) {
    return 'Dokumentlêers ($count)';
  }

  @override
  String get noFilesUploaded => 'Geen lêers opgelaai nie';

  @override
  String commentsHistoryCount(int count) {
    return 'Kommentaar & geskiedenis ($count)';
  }

  @override
  String get noCommentsYet => 'Nog geen kommentaar nie';

  @override
  String get adminReview => 'Admin-nagaan';

  @override
  String get editSpecHint => 'Wysig dokumentspesifikasie (opsioneel)...';

  @override
  String get strayExpiryNote =>
      'Hierdie dokumenttipe gebruik nie ’n vervaldatum nie. Maak dit skoon sodat die dokument nooit as verval wys nie.';

  @override
  String get selectExpiryOptional => 'Kies vervaldatum (opsioneel)';

  @override
  String get comment => 'Kommentaar';

  @override
  String get commentHintReject =>
      'Voeg kommentaar by (verpligtend by afkeuring)...';

  @override
  String get reviewSaveNote =>
      'Veranderinge aan die spesifikasie en vervaldatum word gestoor wanneer jy goedkeur of afkeur.';

  @override
  String get selectExpiryDate => 'Kies vervaldatum';

  @override
  String get actionSelect => 'Kies';

  @override
  String get addYourSignature => 'Voeg jou handtekening by';

  @override
  String get signatureAdded => 'Handtekening bygevoeg';

  @override
  String get rejectReasonRequired => 'Gee asseblief ’n rede vir die afkeuring';

  @override
  String get docApprovedOk => 'Dokument goedgekeur';

  @override
  String get docRejectedOk => 'Dokument afgekeur';

  @override
  String get docTypeLoading => 'Laai dokumenttipe...';

  @override
  String get docTypeNotFound => 'Dokumenttipe nie gevind nie';

  @override
  String get selectExpiryPlease => 'Kies asseblief ’n vervaldatum';

  @override
  String get docCreated => 'Dokument geskep';

  @override
  String formSubmitError(String error) {
    return 'Fout met indien van vorm: $error';
  }

  @override
  String get fillDocForm => 'Vul dokumentvorm in';

  @override
  String fillTypeName(String type) {
    return 'Vul $type in';
  }

  @override
  String get selectExpiryDateLower => 'Kies vervaldatum';

  @override
  String get submitForm => 'Dien vorm in';

  @override
  String get reportLoading => 'Laai nakomingsdata...';

  @override
  String get reportComplete => 'Voltooi';

  @override
  String updatedOn(String date) {
    return 'Opgedateer: $date';
  }

  @override
  String notifUnreadCount(int count) {
    return '$count ongelees';
  }

  @override
  String get notifAllCaughtUp => 'Alles gelees';

  @override
  String get notifMarkAllRead => 'Merk alles as gelees';

  @override
  String get notifNoneYet => 'Nog geen kennisgewings nie';

  @override
  String get notifEmptyHint =>
      'Jy sal kennisgewings kry oor afkeurings en dokumente wat verval.';

  @override
  String get timeJustNow => 'Nou net';

  @override
  String timeMinutesAgo(int count) {
    return '$count min gelede';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count uur gelede';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dae gelede',
      one: '1 dag gelede',
    );
    return '$_temp0';
  }

  @override
  String get farmsLoadFailed => 'Kon nie jou plase laai nie.';

  @override
  String get farmOpenFailed =>
      'Kon nie hierdie plaas oopmaak nie. Probeer asseblief weer.';

  @override
  String farmsAuditorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jy kan goedgekeurde dokumente vir $count plase nagaan.',
      one: 'Jy kan goedgekeurde dokumente vir 1 plaas nagaan.',
    );
    return '$_temp0';
  }

  @override
  String get farmsSearchHint => 'Soek plase...';

  @override
  String get farmsNoneFound => 'Geen plase gevind nie';

  @override
  String get farmCurrent => 'Huidig';

  @override
  String get docFilesTitle => 'Dokumentlêers';

  @override
  String get imagePreview => 'Beeldvoorskou';

  @override
  String get openingInBrowser => 'Maak oop in blaaier...';

  @override
  String fileViewError(String error) {
    return 'Fout met wys van lêer: $error';
  }

  @override
  String urlOpenError(String error) {
    return 'Fout met oopmaak van skakel: $error';
  }

  @override
  String get actionSave => 'Stoor';

  @override
  String get signFirst => 'Teken asseblief voor jy stoor';

  @override
  String signatureSaveError(String error) {
    return 'Fout met stoor van handtekening: $error';
  }

  @override
  String get psEnterHoursFirst => 'Vul eers ure vir minstens een werknemer in.';

  @override
  String get psSaveFailedShort => 'Stoor het misluk';

  @override
  String psSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salarisstrokies gestoor',
      one: '1 salarisstrokie gestoor',
    );
    return '$_temp0';
  }

  @override
  String psSavedSomeFailed(int ok, int failed) {
    return '$ok gestoor, $failed het misluk';
  }

  @override
  String get psFamilyLeaveNeedsStart =>
      'Gesinsverlof begin sodra ’n diensaanvangsdatum gestel is — voeg dit by via Wysig werknemer as dit van toepassing is.';

  @override
  String get psDeleteTitle => 'Skrap salarisstrokie';

  @override
  String psNetAmount(String amount) {
    return 'Netto: $amount';
  }

  @override
  String get cannotUndo => 'Dit kan nie ontdoen word nie.';

  @override
  String get employeeAdded => 'Werknemer bygevoeg';

  @override
  String get employeeUpdated => 'Werknemer bygewerk';

  @override
  String get couldNotSave => 'Kon nie stoor nie';

  @override
  String get employeeRemoveTitle => 'Verwyder werknemer';

  @override
  String employeeRemoveBody(String name) {
    return 'Verwyder $name? Hul salarisstrokies word gehou. As jy hulle later weer byvoeg, gebruik dieselfde ID-nommer sodat ou salarisstrokies weer aan hulle gekoppel word (bv. vir bankbetalings).';
  }

  @override
  String get actionRemove => 'Verwyder';

  @override
  String get companyFallback => 'Maatskappy';

  @override
  String psAllPdfName(String company) {
    return '$company Salarisstrokies.pdf';
  }

  @override
  String get payeTax => 'PAYE (belasting)';

  @override
  String get freqWeekly => 'weekliks';

  @override
  String get freqFortnightly => 'tweeweekliks';

  @override
  String get freqMonthly => 'maandeliks';

  @override
  String payeAutoAmount(String freq, String amount) {
    return 'Outomaties ($freq): $amount';
  }

  @override
  String get payeAmountLabel => 'PAYE-bedrag (R)';

  @override
  String get payeBlankAuto => 'Laat leeg vir outomaties';

  @override
  String get payeUseAuto => 'Gebruik outomaties';

  @override
  String get payeManualNote =>
      'Handmatige PAYE — hierdie presiese bedrag sal gebruik word.';

  @override
  String payeAutoNote(String freq) {
    return 'Outomatiese PAYE word bereken op die belasbare bruto vir hierdie $freq tydperk.';
  }

  @override
  String get additionalDeductions => 'Bykomende aftrekkings';

  @override
  String get noDeductionsYet => 'Nog geen aftrekkings nie';

  @override
  String get fieldReason => 'Rede';

  @override
  String get fieldAmountR => 'Bedrag (R)';

  @override
  String totalAmount(String amount) {
    return 'Totaal: $amount';
  }

  @override
  String get addDeduction => 'Voeg aftrekking by';

  @override
  String get actionDone => 'Klaar';

  @override
  String get additionalIncome => 'Bykomende inkomste';

  @override
  String get noAdditionsYet => 'Nog geen byvoegings nie';

  @override
  String get fieldDescription => 'Beskrywing';

  @override
  String get addIncome => 'Voeg inkomste by';

  @override
  String get uifSummary => 'UIF-opsomming';

  @override
  String get noPayslipsForPeriod =>
      'Geen salarisstrokies vir hierdie tydperk nie.';

  @override
  String pdfError(String error) {
    return 'PDF-fout: $error';
  }

  @override
  String get downloadUifPdf => 'Laai UIF-opsomming PDF af';

  @override
  String get colEmployee => 'Werknemer';

  @override
  String get colEarnings => 'Verdienste';

  @override
  String get colTotalDed => 'Totale aftr.';

  @override
  String get companyColon => 'Maatskappy:';

  @override
  String get selectCompany => 'Kies ’n maatskappy';

  @override
  String get defaultStart => 'Verstek begin';

  @override
  String get defaultEnd => 'Verstek einde';

  @override
  String get fillsAllRows => 'vul alle rye';

  @override
  String get payDate => 'Betaaldatum';

  @override
  String get companyAddressOnPayslip => 'Maatskappyadres (op salarisstrokie)';

  @override
  String get companyAddress => 'Maatskappyadres';

  @override
  String get tapToSet => 'Tik om te stel';

  @override
  String get employerUifRegNr => 'Werkgewer UIF-regnr';

  @override
  String get saving => 'Stoor…';

  @override
  String saveChangesCount(int count) {
    return 'Stoor veranderinge ($count)';
  }

  @override
  String saveAllCount(int count) {
    return 'Stoor alles ($count)';
  }

  @override
  String savePayslipsCount(int count) {
    return 'Stoor salarisstrokies ($count)';
  }

  @override
  String get savePayslips => 'Stoor salarisstrokies';

  @override
  String get timesheet => 'Tydstaat';

  @override
  String get leaveRecords => 'Verlofrekords';

  @override
  String get payslipRecords => 'Salarisstrokierekords';

  @override
  String get actionDownload => 'Laai af';

  @override
  String get noEmployeesFound => 'Geen werknemers gevind nie';

  @override
  String get colIdNumber => 'ID-nommer';

  @override
  String get colNetPay => 'Netto betaal';

  @override
  String get colPayslipPeriod => 'Salarisstrokie-tydperk';

  @override
  String get employeePermanent => 'Permanente werknemer';

  @override
  String get employeeSeasonal => 'Seisoenwerker';

  @override
  String get bankingOnFile =>
      'Bankbesonderhede op lêer — ingesluit in Bank-CSV';

  @override
  String bankingIncomplete(String issues) {
    return 'Bankbesonderhede onvolledig ($issues) — nie ingesluit in Bank-CSV nie';
  }

  @override
  String get editEmployeeDetails => 'Wysig werknemerbesonderhede';

  @override
  String get removeEmployee => 'Verwyder werknemer';

  @override
  String get editThisPayslip => 'Wysig hierdie salarisstrokie';

  @override
  String get cancelEdit => 'Kanselleer wysiging';

  @override
  String get addIncomeLower => 'Voeg inkomste by';

  @override
  String additionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count byvoegings',
      one: '1 byvoeging',
    );
    return '$_temp0';
  }

  @override
  String get noAdditionsEditToAdd =>
      'Geen byvoegings nie (wysig om by te voeg)';

  @override
  String additionsEditToChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count byvoegings (wysig om te verander)',
      one: '1 byvoeging (wysig om te verander)',
    );
    return '$_temp0';
  }

  @override
  String get addDeductionsLower => 'Voeg aftrekkings by';

  @override
  String deductionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aftrekkings',
      one: '1 aftrekking',
    );
    return '$_temp0';
  }

  @override
  String get noDeductionsEditToAdd =>
      'Geen aftrekkings nie (wysig om by te voeg)';

  @override
  String deductionsEditToChange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aftrekkings (wysig om te verander)',
      one: '1 aftrekking (wysig om te verander)',
    );
    return '$_temp0';
  }

  @override
  String get deletePayslip => 'Skrap salarisstrokie';

  @override
  String get finishEditingFirst => 'Voltooi eers die wysiging';

  @override
  String get newPayslip => 'Nuwe salarisstrokie';

  @override
  String get searchEmployees => 'Soek werknemers…';

  @override
  String showingRange(int from, int to, int total) {
    return 'Wys $from–$to van $total';
  }

  @override
  String get failedToLoadData => 'Kon nie data laai nie';

  @override
  String get selectCompanyForPayslips =>
      'Kies ’n maatskappy om salarisstrokies te bestuur';

  @override
  String get addFirstEmployee => 'Voeg eerste werknemer by';

  @override
  String tsLinePhWorkedNormal(
      String date, String hours, String daily, String rate) {
    return 'Openbare vakansiedag gewerk ($date, $hours h): die grootste van 2 × daagloon of daagloon $daily + $hours h × $rate';
  }

  @override
  String tsLinePhWorkedOff(
      String date, String hours, String daily, String rate) {
    return 'Openbare vakansiedag gewerk ($date, $hours h): daagloon $daily + $hours h × $rate';
  }

  @override
  String tsLineSundayMin(int count, Object daily) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sondag-minimumbetaling ($count dae: ten minste die daagloon $daily)',
      one: 'Sondag-minimumbetaling (1 dag: ten minste die daagloon $daily)',
    );
    return '$_temp0';
  }

  @override
  String tsLineNight(int count, Object perDay) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nagskoftoelae ($count dae × $perDay)',
      one: 'Nagskoftoelae (1 dag × $perDay)',
    );
    return '$_temp0';
  }

  @override
  String tsLinePiece(String units, String unit, String rate, String task) {
    return 'Stukwerk: $units $unit × $rate ($task)';
  }

  @override
  String tsLineTopUpDays(int count, Object wage) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Minimumloon-aanvulling ($count dae onder $wage/h)',
      one: 'Minimumloon-aanvulling (1 dag onder $wage/h)',
    );
    return '$_temp0';
  }

  @override
  String tsLineTopUpWeeks(int count, Object wage) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Minimumloon-aanvulling ($count weke onder $wage/h)',
      one: 'Minimumloon-aanvulling (1 week onder $wage/h)',
    );
    return '$_temp0';
  }

  @override
  String tsWarnDay(String hours, String date, String limit) {
    return '$hours h op $date (meer as $limit h per dag)';
  }

  @override
  String tsWarnWeek(String hours, String week, String limit) {
    return '$hours h oortyd in week van $week (meer as $limit h)';
  }

  @override
  String get periodWeekly => 'Weekliks';

  @override
  String get periodFortnightly => 'Tweeweekliks';

  @override
  String get periodMonthly => 'Maandeliks';

  @override
  String get leaveSick => 'siekverlof';

  @override
  String get leaveAnnual => 'jaarlikse (vakansie)verlof';

  @override
  String get leaveFamily => 'gesinsverantwoordelikheidsverlof';

  @override
  String tsLoadPeriodFailed(String error) {
    return 'Kon nie daardie tydperk laai nie: $error';
  }

  @override
  String get unsavedChanges => 'Ongestoorde veranderinge';

  @override
  String get tsUnsavedBody =>
      'Jy het veranderinge aan hierdie tydstaat wat nog nie gestoor is nie.';

  @override
  String get keepEditing => 'Hou aan wysig';

  @override
  String get discardChanges => 'Gooi veranderinge weg';

  @override
  String tsFixRedCells(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Herstel eers die $count rooi selle (ure soos 9 of 7.5, kodes SL / AL / PH / A, eindtye soos 21:30).',
      one:
          'Herstel eers die rooi sel (ure soos 9 of 7.5, kodes SL / AL / PH / A, eindtye soos 21:30).',
    );
    return '$_temp0';
  }

  @override
  String tsSavedUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gestoor · $count salarisstrokies bygewerk',
      one: 'Gestoor · 1 salarisstrokie bygewerk',
    );
    return '$_temp0';
  }

  @override
  String tsSavedSkipped(int skipped) {
    return '$skipped wag vir tariewe (sien die banier)';
  }

  @override
  String saveFailedError(String error) {
    return 'Stoor het misluk: $error';
  }

  @override
  String get tsFinaliseTitle => 'Finaliseer tydperk?';

  @override
  String tsFinaliseBody(String start, String end) {
    return 'Dit stoor die tydstaat, sluit al drie blaaie vir $start – $end en finaliseer die salarisstrokies. Jy kan dit weer oopsluit as iets reggemaak moet word.';
  }

  @override
  String get tsFinalisePeriod => 'Finaliseer tydperk';

  @override
  String get tsUnlockTitle => 'Sluit hierdie tydperk oop?';

  @override
  String get tsUnlockBody =>
      'Die blaaie kan weer gewysig word en die salarisstrokies word weer konsepte totdat jy weer finaliseer. Dit word in die ouditlog aangeteken.';

  @override
  String get actionUnlock => 'Sluit oop';

  @override
  String get tsFinalisedToast =>
      'Tydperk gefinaliseer — blaaie gesluit, salarisstrokies gefinaliseer';

  @override
  String get tsUnlockedToast =>
      'Tydperk oopgesluit — salarisstrokies is weer konsepte';

  @override
  String tsPeriodUpdateFailed(String error) {
    return 'Kon nie die tydperk bywerk nie: $error';
  }

  @override
  String get tsNeedRatesTitle =>
      'Sommige salarisstrokies het eers tariewe nodig';

  @override
  String tsNeedRatesBody(int count, Object missing, Object names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count salarisstrokies ($names) kan nie bereken word voordat hierdie gestel is nie: $missing.',
      one:
          '1 salarisstrokie ($names) kan nie bereken word voordat hierdie gestel is nie: $missing.',
    );
    return '$_temp0';
  }

  @override
  String get later => 'Later';

  @override
  String get setThemNow => 'Stel hulle nou';

  @override
  String get tsRatesSaved =>
      'Tariewe gestoor — druk Stoor om die salarisstrokies by te werk';

  @override
  String tsRatesSaveFailed(String error) {
    return 'Kon nie tariewe stoor nie: $error';
  }

  @override
  String tsPieceRateAddFailed(String error) {
    return 'Kon nie die stukwerktarief byvoeg nie: $error';
  }

  @override
  String tsPayPeriodTitle(String type) {
    return '$type betaaltydperk';
  }

  @override
  String get tsChooseStartDate => 'Kies ’n begindatum…';

  @override
  String get tsFirstDayHelp => 'Eerste dag van die betaaltydperk';

  @override
  String tsTitle(String company) {
    return 'Tydstaat – $company';
  }

  @override
  String get tsRates => 'Tariewe';

  @override
  String get tsLoadFailed => 'Die tydstaat kon nie gelaai word nie.';

  @override
  String get tsNormalHours => 'Normale ure';

  @override
  String get tsOvertime => 'Oortyd';

  @override
  String get tsPiecework => 'Stukwerk';

  @override
  String get tsPayPeriod => 'Betaaltydperk';

  @override
  String tsDaysWorkers(int days, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werkers',
      one: '1 werker',
    );
    return '$days dae · $_temp0';
  }

  @override
  String get tsNsLegend => 'NS = nagwerk (klaar na 20:00, voor 04:00)';

  @override
  String get tsFinalised => 'Gefinaliseer';

  @override
  String tsFinalisedBy(String name) {
    return 'Gefinaliseer deur $name';
  }

  @override
  String get tsPieceRate => 'Stukwerktarief';

  @override
  String get chooseEllipsis => 'Kies…';

  @override
  String get tsAddPieceRateMenu => '+ Voeg stukwerktarief by…';

  @override
  String tsNotUpdatedBanner(int count, Object missing) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salarisstrokies nog nie bygewerk nie — stel: $missing.',
      one: '1 salarisstrokie nog nie bygewerk nie — stel: $missing.',
    );
    return '$_temp0';
  }

  @override
  String get colHours => 'Ure';

  @override
  String get colLeave => 'Verlof';

  @override
  String get colComment => 'Kommentaar';

  @override
  String get colOtHours => 'OT-ure';

  @override
  String get colNsDays => 'NS-dae';

  @override
  String get colUnits => 'Eenhede';

  @override
  String get colPiecePay => 'Stukloon';

  @override
  String get colTopUp => 'Aanvulling';

  @override
  String get tsNoEmployees => 'Nog geen werknemers nie.';

  @override
  String get tsAddEmployeesHint =>
      'Voeg werknemers by in die Salarisstrokiebestuurder';

  @override
  String get colWorker => 'Werker';

  @override
  String get tsPhTooltip =>
      'Openbare vakansiedag. Nie gewerk nie: tik PH (een daagloon betaal). Gewerk: tik die ure — betaal volgens SD13 (die grootste van 2 × daagloon of daagloon + ure, op ’n normale werksdag).';

  @override
  String get tsSundayTooltip =>
      'Sondag: ure gewerk word teen dubbel die gewone loon betaal, en ten minste die daagloon (SD13).';

  @override
  String get tsBelowMinTooltip =>
      'Stukloon is onder die minimumloon — ’n aanvulling word by die salarisstrokie gevoeg.';

  @override
  String get tsOk => 'In orde';

  @override
  String get viewPayslip => 'Sien salarisstrokie';

  @override
  String get viewDraft => 'Sien konsep';

  @override
  String tsSummaryNormal(int count, Object hours) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Normale ure · Alle werkers · Ure $hours · Verlof / afwesig $count dae',
      one: 'Normale ure · Alle werkers · Ure $hours · Verlof / afwesig 1 dag',
    );
    return '$_temp0';
  }

  @override
  String tsSummaryOvertime(String hours, int ns) {
    return 'Oortyd · Alle werkers · OT-ure $hours · Nagskofdae $ns';
  }

  @override
  String tsSummaryPiece(String units) {
    return 'Stukwerk · Alle werkers · Eenhede $units';
  }

  @override
  String get tsChoosePieceRateSuffix => ' · kies ’n stukwerktarief';

  @override
  String get tsHelpNormal =>
      'Tik die ure gewerk (9, 7.5…) in elke dag. Verlof gaan in met die verlofkodes bo die rooster. Oortyd en stukwerk gaan op hul eie blaaie.';

  @override
  String get tsHelpOvertime =>
      'Elke dag: oortydure + eindtyd. NS word outomaties gemerk wanneer die eindtyd na 20:00 of voor 04:00 is (SD13 kl 17) en voeg ’n nagskoftoelae by die salarisstrokie.';

  @override
  String get tsHelpPiece =>
      'Elke dag: ure gewerk + eenhede. Stukloon = eenhede × die stukwerktarief. ’n Aanvulling word aangedui wanneer stukloon onder die minimumloon vir die ure gewerk is.';

  @override
  String get tsRatesTitle => 'Tydstaattariewe';

  @override
  String get tsRatesConfirmedNote =>
      'Bevestigde syfers: oortyd 1.5×, nagskof 10% van die daagloon per nagskofdag, minimumloon R30.23 (kontroleer elke Maart). Sondae en openbare vakansiedae word outomaties volgens SD13 betaal. Laat ’n veld leeg en die salarisstrokies wat dit nodig het, wys “R —” totdat dit gestel is.';

  @override
  String get tsFillConfirmed => 'Vul die bevestigde syfers in';

  @override
  String get tsOtMultiplier => 'Oortydvermenigvuldiger';

  @override
  String get tsOtMultiplierHelp => 'SD13 kl 14: ten minste 1.5 × die loon.';

  @override
  String get tsNightAllowance => 'Nagskoftoelae (% van gewone daagloon)';

  @override
  String get tsNightAllowanceHelp =>
      'SD13 kl 17: ten minste 10%, per dag met nagwerk.';

  @override
  String get tsMinWage => 'Minimumloon per gewone uur (R)';

  @override
  String get tsMinWageHelp =>
      'Plaaswerker-NML vanaf 1 Maart 2026: R30.23 — kontroleer die huidige staatskoerant.';

  @override
  String get tsDayHours => 'Gewone ure per dag';

  @override
  String get tsDayHoursHelp =>
      'Gebruik vir verlofdae (SL / AL / PH) en die daagloon.';

  @override
  String get tsWarnWeekLabel => 'Waarsku bo oortydure per week';

  @override
  String get tsWarnWeekHelp =>
      'SD13 kl 13: maks 15 h oortyd per week (net ’n waarskuwing).';

  @override
  String get tsWarnDayLabel => 'Waarsku bo totale ure per dag';

  @override
  String get tsWarnDayHelp =>
      'SD13 kl 13: maks 12 h per dag insluitend oortyd (net ’n waarskuwing).';

  @override
  String get tsTopUpTitle => 'Minimumloon-aanvulling vir stukwerk';

  @override
  String get tsTopUpHelp =>
      'Per dag of per week nagegaan, afhangend van hierdie plaas. Werkers onder die minimum word in rooi gewys.';

  @override
  String get perDay => 'Per dag';

  @override
  String get perWeek => 'Per week';

  @override
  String get tsWorkDaysTitle => 'Normale werksdae';

  @override
  String get tsWorkDaysHelp =>
      'Bepaal hoe ’n gewerkte openbare vakansiedag betaal word: op ’n normale werksdag die grootste van 2 × daagloon of daagloon + ure; andersins daagloon + ure.';

  @override
  String get tsSaveRates => 'Stoor tariewe';

  @override
  String get tsAddPieceRate => 'Voeg stukwerktarief by';

  @override
  String get tsTaskOrCrop => 'Taak of gewas';

  @override
  String get tsTaskHint => 'bv. Oes';

  @override
  String get tsTaskRequired => 'Vul die taak of gewas in';

  @override
  String get tsUnit => 'Eenheid';

  @override
  String get tsUnitHint => 'bakke, kratte, …';

  @override
  String get tsUnitDefault => 'bakke';

  @override
  String get tsUnitRequired => 'Vul die eenheid in';

  @override
  String get tsRatePerUnit => 'Tarief per eenheid (R)';

  @override
  String get tsRatePerUnitHelp =>
      'Uit jou ingestelde tarief — nie ’n voorbeeldsyfer nie.';

  @override
  String get tsRateRequired => 'Vul die tarief per eenheid in';

  @override
  String get actionAdd => 'Voeg by';

  @override
  String get missOvertime => 'oortydvermenigvuldiger';

  @override
  String get missNight => 'nagskoftoelae %';

  @override
  String get missPieceRate => 'stukwerktarief';

  @override
  String get missMinWage => 'minimum-uurloon';

  @override
  String get missTopUp => 'aanvulling per dag of per week';

  @override
  String get missWorkDays => 'normale werksdae';

  @override
  String leaveRecordsTitle(String company) {
    return 'Verlofrekords – $company';
  }

  @override
  String get noEmployeesFoundDot => 'Geen werknemers gevind nie.';

  @override
  String get leaveCodeHL => 'VV';

  @override
  String get leaveCodeSL => 'SV';

  @override
  String get leaveCodeFL => 'GV';

  @override
  String get leaveHoliday => 'Vakansieverlof';

  @override
  String get leaveHolidayRule => '1 uur per 17 ure gewerk';

  @override
  String get leaveSickTitle => 'Siekverlof';

  @override
  String get leaveSickRule =>
      '1 uur per 26 ure (eerste 6 mnd) / 30 dae per 3 jaar';

  @override
  String get leaveFamilyTitle => 'Gesinsverantw.-verlof';

  @override
  String get leaveFamilyRule => '3 dae/jaar na 4 maande (aanvangsdatum nodig)';

  @override
  String get leaveReportPdf => 'Verlofverslag (PDF)';

  @override
  String employedSince(String date) {
    return 'In diens sedert $date';
  }

  @override
  String get setOpeningLeave => 'Stel openingsverlof';

  @override
  String get hoursWorkedInSystem => 'Ure gewerk in stelsel: ';

  @override
  String hoursAmount(String hours) {
    return '$hours ure';
  }

  @override
  String get accrualNote =>
      '(bepaal nuwe toevalling; openingsaldo’s word apart gestel)';

  @override
  String get allocated30Day => 'Toegeken (30-dag-bondels)';

  @override
  String get accrued126 => 'Toegeval (1/26 ure)';

  @override
  String get entitlement3Days => 'Aanspraak (3 dae/jaar)';

  @override
  String get setStartDateToEnable =>
      'Stel diensaanvangsdatum om dit aan te skakel';

  @override
  String get eligibleAfter4Months => 'Kwalifiseer na 4 maande diens';

  @override
  String get openingPreSystem => 'Opening (voor stelsel)';

  @override
  String get accrued => 'Toegeval';

  @override
  String get taken => 'Geneem';

  @override
  String get balance => 'Saldo';

  @override
  String get balanceHoursHelp => 'Saldo in ure (8 ure = 1 dag)';

  @override
  String get openingLeaveTitle =>
      'Verlof opgebou voordat die stelsel gebruik is';

  @override
  String openingLeaveBody(String name) {
    return 'Vir $name — vul die verlof in wat hierdie werknemer reeds opgebou het VOORDAT jy die toep begin gebruik het. Dit is die openingsaldo; die stelsel tel nuwe toevalling daarby en trek verlof geneem af. Vul elke tipe apart in — vakansie- en siekverlof is nie dieselfde nie.';
  }

  @override
  String get openingHL => 'Vakansieverlof (VV) opening';

  @override
  String get openingSL => 'Siekverlof (SV) opening';

  @override
  String get openingFL => 'Gesinsverantw.-verlof (GV) opening';

  @override
  String sickAllocationTitle(String name) {
    return 'Siekverloftoekenning – $name';
  }

  @override
  String get sickPost6Months =>
      'Werknemer is langer as 6 maande in diens — ken 30-dag-bondels toe';

  @override
  String get sickPre6Months =>
      'Eerste 6 maande: val outomaties toe teen 1 uur per 26 ure gewerk';

  @override
  String get previousAllocations => 'Vorige toekennings';

  @override
  String hoursOnDate(String hours, String date) {
    return '$hours ure op $date';
  }

  @override
  String get sickAutoNote =>
      'Siekverlof word outomaties bereken teen 1 uur per 26 ure gewerk. Geen handmatige toekenning nodig tot 6 maande diens nie.';

  @override
  String get grantSickBatch => 'Ken nuwe 30-dag-siekverlofbondel toe';

  @override
  String get hours240Hint => '240 (= 30 dae × 8 ure)';

  @override
  String get noteOptional => 'Nota (opsioneel)';

  @override
  String get grantSickLeave => 'Ken siekverlof toe';

  @override
  String familyAllocateBody(String name) {
    return '$name — ken jaarlikse gesinsverantwoordelikheidsverlof toe. Die SA wet bepaal 3 dae per jaar vir werknemers wat langer as 4 maande in diens is.';
  }

  @override
  String get hoursAllocated => 'Ure toegeken';

  @override
  String get hours24Hint => '24 (= 3 dae × 8 ure)';

  @override
  String get hours24Help => 'Gewoonlik 24 ure (3 werksdae teen 8 ure/dag)';

  @override
  String get actionAllocate => 'Ken toe';

  @override
  String actionFailed(String action, String error) {
    return '$action het misluk: $error';
  }

  @override
  String get deletePayslipsTitle => 'Skrap salarisstrokies';

  @override
  String deletePayslipsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Skrap $count salarisstrokies permanent? Dit kan nie ontdoen word nie.',
      one: 'Skrap 1 salarisstrokie permanent? Dit kan nie ontdoen word nie.',
    );
    return '$_temp0';
  }

  @override
  String deleteCount(int count) {
    return 'Skrap $count';
  }

  @override
  String payslipsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salarisstrokies geskrap',
      one: '1 salarisstrokie geskrap',
    );
    return '$_temp0';
  }

  @override
  String get bankFile => 'Banklêer';

  @override
  String payslipRecordsTitle(String company) {
    return 'Salarisstrokierekords – $company';
  }

  @override
  String get presetThisWeek => 'Hierdie week';

  @override
  String get presetLastWeek => 'Verlede week';

  @override
  String get presetThisMonth => 'Hierdie maand';

  @override
  String get presetLastMonth => 'Verlede maand';

  @override
  String get dateFrom => 'Van';

  @override
  String get dateTo => 'Tot';

  @override
  String get any => 'Enige';

  @override
  String selectedCount(int count) {
    return '$count gekies';
  }

  @override
  String payslipsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salarisstrokies',
      one: '1 salarisstrokie',
    );
    return '$_temp0';
  }

  @override
  String get bankCsv => 'Bank-CSV';

  @override
  String get noPayslipsInRange =>
      'Geen salarisstrokies in hierdie datumreeks nie.';

  @override
  String get payslipWord => 'Salarisstrokie';

  @override
  String get payslipNotFound => 'Salarisstrokie nie gevind nie';

  @override
  String get printSavePdf => 'Druk / stoor PDF';

  @override
  String deletePayslipFor(String name) {
    return 'Skrap hierdie salarisstrokie vir $name?';
  }

  @override
  String get psPersonalDetails => 'PERSOONLIKE BESONDERHEDE';

  @override
  String get psPeriodStart => 'Periode Begin';

  @override
  String get psPeriodEnd => 'Periode Einde';

  @override
  String get psHourlyRate => 'Uurlikse Loon';

  @override
  String get psOvertimeRate => 'Oortyd Loon';

  @override
  String get psDoubleTimeRate => 'Dubbel Tyd Loon';

  @override
  String get psNormalPay => 'Normale Loon';

  @override
  String get psOvertimePay => 'Oortyd Loon';

  @override
  String get psDoubleTime => 'Dubbel Tyd';

  @override
  String get psPublicHoliday => 'Openbare Vakansie';

  @override
  String get psSickLeaveCoded => 'Siekteverlof (SV)';

  @override
  String get psHolidayLeaveCoded => 'Vakansieverlof (VV)';

  @override
  String get psFamilyLeaveCoded => 'Gesinsverlof (GV)';

  @override
  String get psOtherDetails => 'ANDER BESONDERHEDE';

  @override
  String get psUifRegNr => 'UIF Reg Nr';

  @override
  String get psNetSalaryCaps => 'NETTO SALARIS';

  @override
  String pdfGenerateFailed(String error) {
    return 'Kon nie PDF maak nie: $error';
  }

  @override
  String get payslipFinalised => 'Hierdie salarisstrokie is gefinaliseer';

  @override
  String get payslipIsDraft => 'Hierdie salarisstrokie is ’n konsep';

  @override
  String get selectEmployeePlease => 'Kies asseblief ’n werknemer';

  @override
  String get finalisePayslipTitle => 'Finaliseer salarisstrokie';

  @override
  String get finalisePayslipBody =>
      'Sodra dit gefinaliseer is, kan hierdie salarisstrokie nie gewysig word nie. Gaan voort?';

  @override
  String get actionFinalise => 'Finaliseer';

  @override
  String get failedToSave => 'Kon nie stoor nie';

  @override
  String get viewPayslipTitle => 'Sien salarisstrokie';

  @override
  String get editPayslipTitle => 'Wysig salarisstrokie';

  @override
  String get employeePayPeriod => 'Werknemer & betaaltydperk';

  @override
  String get hourlyRates => 'Uurtariewe';

  @override
  String get normalRateR => 'Normale tarief (R)';

  @override
  String get overtimeRateR => 'Oortydtarief (R)';

  @override
  String get doubleRateR => 'Dubbeltarief (R)';

  @override
  String get normalHoursLabel => 'Normale ure';

  @override
  String get overtimeHoursLabel => 'Oortydure';

  @override
  String get doubleTimeHoursLabel => 'Dubbeltydure';

  @override
  String get publicHolidayHoursLabel => 'Openbare vakansiedag-ure';

  @override
  String get earningsSummary => 'Opsomming van verdienste';

  @override
  String get normalPayLabel => 'Normale loon';

  @override
  String get overtimePayLabel => 'Oortydloon';

  @override
  String get doubleTimePayLabel => 'Dubbeltydloon';

  @override
  String get publicHolidayPayLabel => 'Openbare vakansiedag-loon';

  @override
  String get totalEarnings => 'Totale verdienste';

  @override
  String get deductionsTitle => 'Aftrekkings';

  @override
  String get uifOnePercent => 'UIF (1% van verdienste)';

  @override
  String get compulsory => 'Verpligtend';

  @override
  String get totalDeductions => 'Totale aftrekkings';

  @override
  String get saveDraft => 'Stoor konsep';

  @override
  String get selectAnEmployee => 'Kies ’n werknemer';

  @override
  String get noEmployeesAddFirst => 'Geen werknemers – voeg eers een by';

  @override
  String get selectEmployee => 'Kies werknemer';

  @override
  String get required => 'Verpligtend';

  @override
  String get invalidNumber => 'Ongeldige getal';

  @override
  String get payslipFinalisedNoEdit =>
      'Hierdie salarisstrokie is gefinaliseer en kan nie gewysig word nie.';

  @override
  String get bulkEnterHours => 'Vul ure vir minstens een werknemer in.';

  @override
  String bulkGeneratedOk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count salarisstrokies gemaak',
      one: '1 salarisstrokie gemaak',
    );
    return '$_temp0';
  }

  @override
  String bulkGeneratedSome(int ok, int failed) {
    return '$ok gemaak, $failed het misluk';
  }

  @override
  String get bulkTitle => 'Massa-salarisstrokies';

  @override
  String get generateAll => 'Maak almal';

  @override
  String get addEmployeesFirst =>
      'Voeg eers werknemers by in die Salarisstrokiebestuurder.';

  @override
  String get backToManager => 'Terug na bestuurder';

  @override
  String get colRateRHr => 'Tarief (R/uur)';

  @override
  String get colNormalHrs => 'Normale\nure';

  @override
  String get colOvertimeHrs => 'Oortyd\nure';

  @override
  String get colDoubleTime => 'Dubbel\ntyd';

  @override
  String get colPublicHol => 'Openb.\nvak.';

  @override
  String get colEstNetPay => 'Geskatte netto';

  @override
  String get shortfallTitle => 'Nie genoeg verlof oor nie';

  @override
  String get shortfallOne =>
      'Hierdie werknemer het nie genoeg verlof oor vir wat ingevul is nie. Kies wat om te doen:';

  @override
  String get shortfallMany =>
      'Hierdie werknemers het nie genoeg verlof oor vir wat ingevul is nie. Kies wat om vir elkeen te doen:';

  @override
  String get applyToAll => 'Pas op almal toe:';

  @override
  String get payAvailable => 'Betaal beskikbare';

  @override
  String get takeOff => 'Haal af';

  @override
  String get overridePay => 'Ignoreer & betaal';

  @override
  String chooseForMore(int count) {
    return 'Kies ’n opsie vir nog $count';
  }

  @override
  String get backToEdit => 'Terug om te wysig';

  @override
  String get applyAndSave => 'Pas toe & stoor';

  @override
  String shortfallLine(String requested, String type, String available) {
    return ' — $requested h $type ingevul, net $available h oor';
  }

  @override
  String shortfallPayAvailableTitle(String hours) {
    return 'Betaal net die $hours h beskikbaar';
  }

  @override
  String shortfallPayAvailableSub(String hours) {
    return 'Die ander $hours h word van die salarisstrokie afgelaat (onbetaald).';
  }

  @override
  String get shortfallTakeOffTitle => 'Haal die verlof af';

  @override
  String shortfallTakeOffSub(String code, String hours) {
    return 'Geen $code op hierdie salarisstrokie nie — die $hours h is onbetaald.';
  }

  @override
  String shortfallOverrideTitle(String hours) {
    return 'Ignoreer & betaal al $hours h';
  }

  @override
  String shortfallOverrideSub(String code, String hours) {
    return 'Betaal die volle bedrag as $code; hul $code-saldo gaan $hours h onder nul.';
  }

  @override
  String get bulkPaymentFile => 'Massabetalingslêer';

  @override
  String get noPaymentsYet => 'Nog geen betalings nie';

  @override
  String paymentsTotal(int count, Object total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count betalings · totaal $total',
      one: '1 betaling · totaal $total',
    );
    return '$_temp0';
  }

  @override
  String get bankUploadHelp =>
      'Laai die lêer op na jou aanlyn bankdienste as ’n massabetaling, kontroleer die totaal en keur dit dan een keer goed.';

  @override
  String get reference => 'Verwysing';

  @override
  String get refFirstNameAdded => 'Elke werknemer se voornaam word bygevoeg';

  @override
  String refFirstNameExample(String sample) {
    return 'Elke werknemer se voornaam word bygevoeg — bv. “$sample”';
  }

  @override
  String combinedPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count werknemers het meer as een salarisstrokie gekies — hul netto loon word in een betaling saamgevoeg.',
      one:
          '1 werknemer het meer as een salarisstrokie gekies — hul netto loon word in een betaling saamgevoeg.',
    );
    return '$_temp0';
  }

  @override
  String get downloadFile => 'Laai lêer af';

  @override
  String get chooseYourBank => 'Kies jou bank';

  @override
  String get bankFarmPaysFrom => 'Bank waaruit die plaas betaal';

  @override
  String get nobodyPayable =>
      'Niemand kan nog betaal word nie — kom ons maak dit reg';

  @override
  String get eachFixSaves =>
      'Elke regstelling word dadelik gestoor en hierdie lys werk saam by.';

  @override
  String addBankingForCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Voeg bankbesonderhede vir $count werknemers by',
      one: 'Voeg bankbesonderhede vir 1 werknemer by',
    );
    return '$_temp0';
  }

  @override
  String fixUnlinkedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Herstel $count ongekoppelde salarisstrokies',
      one: 'Herstel 1 ongekoppelde salarisstrokie',
    );
    return '$_temp0';
  }

  @override
  String reviewZeroCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gaan $count R 0-salarisstrokies na',
      one: 'Gaan 1 R 0-salarisstrokie na',
    );
    return '$_temp0';
  }

  @override
  String notIncludedCount(int count) {
    return 'Nie ingesluit nie ($count)';
  }

  @override
  String addBankingForAll(int count) {
    return 'Voeg bankbesonderhede vir al $count by';
  }

  @override
  String get addBankingDetails => 'Voeg bankbesonderhede by';

  @override
  String get fixBankingDetails => 'Herstel bankbesonderhede';

  @override
  String get linkToEmployee => 'Koppel aan werknemer';

  @override
  String get editPayslip => 'Wysig salarisstrokie';

  @override
  String relinkedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count salarisstrokies was aan ’n verwyderde werknemerrekord gekoppel — aan die huidige werknemer gekoppel volgens ID-nommer of naam.',
      one:
          '1 salarisstrokie was aan ’n verwyderde werknemerrekord gekoppel — aan die huidige werknemer gekoppel volgens ID-nommer of naam.',
    );
    return '$_temp0';
  }

  @override
  String get saveLinks => 'Stoor koppelings';

  @override
  String draftsUndecided(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count gekose salarisstrokies is nog konsepte — bedrae kan nog verander:',
      one:
          '1 gekose salarisstrokie is nog ’n konsep — bedrae kan nog verander:',
    );
    return '$_temp0';
  }

  @override
  String draftsRemoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count konsep-salarisstrokies uit hierdie uitvoer verwyder:',
      one: '1 konsep-salarisstrokie uit hierdie uitvoer verwyder:',
    );
    return '$_temp0';
  }

  @override
  String draftsIncluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count konsep-salarisstrokies ingesluit soos hulle nou is:',
      one: '1 konsep-salarisstrokie ingesluit soos dit nou is:',
    );
    return '$_temp0';
  }

  @override
  String removeDrafts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verwyder konsepte',
      one: 'Verwyder konsep',
    );
    return '$_temp0';
  }

  @override
  String get includeAnyway => 'Sluit tog in';

  @override
  String get undo => 'Ontdoen';

  @override
  String bankingDetailsFor(String name) {
    return 'Bankbesonderhede — $name';
  }

  @override
  String get orphanPayslipBody =>
      'Hierdie salarisstrokie is gekoppel aan ’n werknemerrekord wat nie meer bestaan nie (die werknemer is waarskynlik verwyder). Koppel dit aan ’n huidige werknemer, of skep die werknemer weer uit die salarisstrokie.';

  @override
  String get skip => 'Slaan oor';

  @override
  String get recreateEmployee => 'Skep werknemer weer';

  @override
  String linkNameTo(String name) {
    return 'Koppel “$name” aan…';
  }

  @override
  String get noIdNumber => 'Geen ID-nommer nie';

  @override
  String get notListedRecreate =>
      'Nie gelys nie? Skep eerder die werknemer weer';

  @override
  String couldNotLink(String reason) {
    return 'Kon nie koppel nie: $reason';
  }

  @override
  String get employeeSavedLinkFailed =>
      'Werknemer gestoor, maar koppeling van salarisstrokies het misluk.';

  @override
  String get payslipLinksSaved => 'Salarisstrokie-koppelings gestoor';

  @override
  String get someLinksFailed => 'Sommige koppelings kon nie gestoor word nie';

  @override
  String get completeHighlighted => 'Voltooi asseblief die gemerkte velde.';

  @override
  String get editEmployee => 'Wysig werknemer';

  @override
  String get employeeDetails => 'Werknemerbesonderhede';

  @override
  String get fullName => 'Volle naam';

  @override
  String get fullNameHint => 'bv. Jan Smit';

  @override
  String get normalHourlyRateR => 'Normale uurtarief (R)';

  @override
  String get enterValidNumber => 'Vul ’n geldige getal in';

  @override
  String get jobDescription => 'Posbeskrywing';

  @override
  String get jobDescriptionHint => 'bv. Plaaswerker, Trekkerbestuurder';

  @override
  String get employmentStartOptional => 'Diensaanvangsdatum (opsioneel)';

  @override
  String get saveChanges => 'Stoor veranderinge';

  @override
  String get employmentType => 'Diens-tipe';

  @override
  String get bankingDetails => 'Bankbesonderhede';

  @override
  String get bankingOnlyIfCsv =>
      'Net nodig as jy personeel met die Bank-CSV-massabetalingslêer betaal. Laat andersins leeg.';

  @override
  String get bank => 'Bank';

  @override
  String get otherBank => 'Ander bank…';

  @override
  String get bankName => 'Banknaam';

  @override
  String get bankNameHint => 'bv. Bidvest Bank';

  @override
  String get accountHolderLabel =>
      'Rekeninghouer (as dit nie die werknemer is nie)';

  @override
  String get accountHolderHint =>
      'Laat leeg om die werknemer se naam te gebruik';

  @override
  String get accountNumber => 'Rekeningnommer';

  @override
  String get accountDigits => 'Net syfers, 6–16 lank';

  @override
  String get branchCode => 'Takkode';

  @override
  String get branchCodeHint => 'Word outomaties vir die groot banke ingevul';

  @override
  String get accountType => 'Rekeningtipe';

  @override
  String leaveEligibility(int months) {
    return 'Verlofkwalifikasie ($months maande in diens):';
  }

  @override
  String get familyLeave3Days => 'Gesinsverantw.-verlof (3 dae/jaar)';

  @override
  String get months4Required => '4 maande nodig';

  @override
  String get sickLeave30Days => 'Siekverlof (30 dae/3 jaar)';

  @override
  String get months6Required => '6 maande nodig';

  @override
  String rateHelper(String overtime, String double) {
    return 'Oortyd: R $overtime/uur  ·  Dubbel: R $double/uur';
  }

  @override
  String get employmentPermanent => 'Permanent';

  @override
  String get employmentSeasonal => 'Seisoen';

  @override
  String get accountCurrent => 'Tjek / Lopende';

  @override
  String get accountSavings => 'Spaar';

  @override
  String get accountTransmission => 'Transmissie';

  @override
  String get bankIssueNone => 'geen bankbesonderhede nie';

  @override
  String get bankIssueNoAccount => 'geen rekeningnommer nie';

  @override
  String get bankIssueAccountDigits => 'rekeningnommer moet 6–16 syfers wees';

  @override
  String get bankIssueNoBranch => 'geen takkode nie';

  @override
  String get bankIssueBranchDigits => 'takkode moet 6 syfers wees';

  @override
  String get formUntitledField => 'Naamlose veld';

  @override
  String formEnterField(String label) {
    return 'Vul $label in';
  }

  @override
  String get formNoOptions => 'Geen opsies verskaf nie';

  @override
  String get formInvalidConfig => 'Ongeldige vormopstelling: velde ontbreek';

  @override
  String formBuildError(String error) {
    return 'Fout met bou van vorm: $error';
  }

  @override
  String get formContractName => 'Kontraknaam';

  @override
  String get formContractNameHint => 'Vul die naam van die kontrak in';

  @override
  String get formContractNumber => 'Kontraknommer';

  @override
  String get formContractNumberHint => 'Vul die kontrak se verwysingsnommer in';

  @override
  String get formCounterparty => 'Teenparty';

  @override
  String get formCounterpartyHint => 'Vul die naam van die ander party in';

  @override
  String get formEffectiveDate => 'Datum van inwerkingtreding';

  @override
  String get formContractStatus => 'Kontrakstatus';

  @override
  String get formOptActive => 'Aktief';

  @override
  String get formOptPending => 'Hangend';

  @override
  String get formOptTerminated => 'Beëindig';

  @override
  String get formOptExpired => 'Verval';

  @override
  String get formContractDescHint => 'Vul ’n beskrywing van die kontrak in';

  @override
  String get formCertName => 'Sertifiseringsnaam';

  @override
  String get formCertNameHint => 'Vul die naam van die sertifisering in';

  @override
  String get formCertNumber => 'Sertifiseringsnommer';

  @override
  String get formCertNumberHint =>
      'Vul die sertifisering se verwysingsnommer in';

  @override
  String get formIssuingAuthority => 'Uitreikende owerheid';

  @override
  String get formIssuingAuthorityHint =>
      'Vul die naam van die uitreikende owerheid in';

  @override
  String get formIssueDate => 'Uitreikdatum';

  @override
  String get formHasRestrictions => 'Het beperkings';

  @override
  String get formNotes => 'Notas';

  @override
  String get formNotesHint => 'Vul enige bykomende notas in';

  @override
  String get formInspectionLocation => 'Inspeksieplek';

  @override
  String get formInspectionLocationHint =>
      'Vul die plek in wat geïnspekteer is';

  @override
  String get formInspectionDate => 'Inspeksiedatum';

  @override
  String get formInspector => 'Inspekteur';

  @override
  String get formInspectorHint => 'Vul die naam van die inspekteur in';

  @override
  String get formInspectionResult => 'Inspeksie-uitslag';

  @override
  String get formOptPass => 'Geslaag';

  @override
  String get formOptPassConditions => 'Geslaag met voorwaardes';

  @override
  String get formOptFail => 'Gedruip';

  @override
  String get formOptIncomplete => 'Onvolledig';

  @override
  String get formFindings => 'Bevindinge';

  @override
  String get formFindingsHint => 'Vul inspeksiebevindinge in';

  @override
  String get formRecommendations => 'Aanbevelings';

  @override
  String get formRecommendationsHint => 'Vul aanbevelings in';

  @override
  String get formAssessmentTitle => 'Titel van assessering';

  @override
  String get formAssessmentTitleHint =>
      'Vul die titel van hierdie risiko-assessering in';

  @override
  String get formAssessmentDate => 'Assesseringsdatum';

  @override
  String get formAssessor => 'Assessor';

  @override
  String get formAssessorHint => 'Vul die naam van die assessor in';

  @override
  String get formOverallRisk => 'Algehele risikovlak';

  @override
  String get formOptLow => 'Laag';

  @override
  String get formOptMedium => 'Medium';

  @override
  String get formOptHigh => 'Hoog';

  @override
  String get formOptCritical => 'Kritiek';

  @override
  String get formHazards => 'Geïdentifiseerde gevare';

  @override
  String get formHazardsHint => 'Lys die geïdentifiseerde gevare';

  @override
  String get formControlMeasures => 'Beheermaatreëls';

  @override
  String get formControlMeasuresHint => 'Lys die beheermaatreëls';

  @override
  String get formRequiresFollowUp => 'Vereis opvolg';

  @override
  String get formTitle => 'Titel';

  @override
  String get formTitleHint => 'Vul ’n titel in';

  @override
  String get formReferenceHint => 'Vul ’n verwysingsnommer in';

  @override
  String get formDocumentDate => 'Dokumentdatum';

  @override
  String get formSelectDate => 'Kies ’n datum';

  @override
  String get fmNoFarmLinked =>
      'Geen Farmable-plaas is aan hierdie maatskappy gekoppel nie.';

  @override
  String get fmMapLoadFailed => 'Kon nie die plaaskaart laai nie';

  @override
  String get fmCrop => 'Gewas';

  @override
  String get fmVariety => 'Kultivar';

  @override
  String get fmFieldType => 'Landtipe';

  @override
  String get fmArea => 'Oppervlakte';

  @override
  String fmHectares(String value) {
    return '$value ha';
  }

  @override
  String get fmSkyView => 'Plaas-lugaansig';

  @override
  String fmCropsBlocks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gewasse · $count blokke',
      one: 'Gewasse · 1 blok',
    );
    return '$_temp0';
  }

  @override
  String get fmDataLoadFailed => 'Kon nie plaasdata laai nie';

  @override
  String get fmFarmableLoadFailed => 'Kon nie Farmable-data laai nie';

  @override
  String get fmFarmData => 'Plaasdata';

  @override
  String get fmFieldsCrops => 'Lande & gewasse';

  @override
  String get fmRecentSales => 'Onlangse oeste / verkope';

  @override
  String get fmNoSales => 'Geen verkooprekords gevind nie.';

  @override
  String get fmViewRegister => 'Sien volledige plaasregister';

  @override
  String get fmNoCrops => 'Geen gewasse nie';

  @override
  String fmCropArea(String crops, String area) {
    return '$crops · $area ha';
  }

  @override
  String get fmUnassigned => 'Nie toegeken nie';

  @override
  String get fmNoMappedFields => 'Geen gekarteerde lande nie';

  @override
  String get fmTotalArea => 'Totale bewerkte oppervlakte';

  @override
  String get fmFields => 'Lande';

  @override
  String get fmCropTypes => 'Gewastipes';

  @override
  String get fmPeople => 'Mense';

  @override
  String get unitBlocks => 'blokke';

  @override
  String get unitTypes => 'tipes';

  @override
  String get unitMembers => 'lede';

  @override
  String get fmEquipmentInspection => 'Toerusting-inspeksie';

  @override
  String get fmNoEquipment => 'Geen toerusting nie';

  @override
  String get fmAllInspected => 'Alles geïnspekteer';

  @override
  String fmNeedInspection(int count) {
    return '$count moet geïnspekteer word';
  }

  @override
  String fmBlocksArea(int count, Object area) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blokke · $area ha',
      one: '1 blok · $area ha',
    );
    return '$_temp0';
  }

  @override
  String get fmCropDistribution => 'Gewasverspreiding';

  @override
  String get fmNoCropData => 'Geen gewasdata nie.';

  @override
  String get fmEquipment => 'Toerusting';

  @override
  String fmToInspect(int count) {
    return '$count om te inspekteer';
  }

  @override
  String get fmAllGood => 'Alles in orde';

  @override
  String get fmNoEquipmentRecord => 'Geen toerusting op rekord nie.';

  @override
  String fmInspectedOn(String date) {
    return 'Geïnspekteer $date';
  }

  @override
  String get fmDue => 'Agterstallig';

  @override
  String get fmPeopleRoles => 'Mense & rolle';

  @override
  String get fmNoPeople => 'Geen mense op rekord nie.';

  @override
  String get srTitle => 'Spuit- & kunsmisrekords';

  @override
  String get srAddRecord => 'Voeg rekord by';

  @override
  String srRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rekords',
      one: '1 rekord',
    );
    return '$_temp0';
  }

  @override
  String srSyncedFarmable(String job) {
    return 'Gesinkroniseer na Farmable (Taak #$job)';
  }

  @override
  String get srNoFields => 'Geen lande nie';

  @override
  String srPhiDays(int days) {
    return 'VOI: ${days}d';
  }

  @override
  String get srNoRecordsSpray => 'Nog geen spuittoedieningsrekords nie';

  @override
  String get srNoRecordsFert => 'Nog geen kunsmistoedieningsrekords nie';

  @override
  String get srEmptyHint =>
      'Tik + Voeg rekord by om jou eerste toediening aan te teken';

  @override
  String get srAdded => 'Rekord bygevoeg';

  @override
  String get srUpdated => 'Rekord bygewerk';

  @override
  String get srDeleted => 'Rekord geskrap';

  @override
  String get srLogTitle => 'Teken toediening aan';

  @override
  String get srEditTitle => 'Wysig toedieningsrekord';

  @override
  String get srDeleteTooltip => 'Skrap rekord';

  @override
  String get srDeleteTitle => 'Skrap rekord';

  @override
  String get srDeleteBody => 'Dit sal hierdie rekord permanent skrap.';

  @override
  String get srSpray => 'Spuit';

  @override
  String get srFertilizer => 'Kunsmis';

  @override
  String get srAppDate => 'Toedieningsdatum *';

  @override
  String get srProduct => 'Produknaam *';

  @override
  String get srProductHint => 'bv. Karate 5 EC';

  @override
  String get srActiveIngredient => 'Aktiewe bestanddeel';

  @override
  String get srActiveIngredientHint => 'bv. Lambda-sihalotrien';

  @override
  String get srRegNumber => 'Registrasienommer';

  @override
  String get srTargetPest => 'Teikenplaag / -siekte *';

  @override
  String get srTargetCrop => 'Teikengewas / -voedingstof *';

  @override
  String get srTargetPestHint => 'bv. Valskodlingmot';

  @override
  String get srTargetCropHint => 'bv. Stikstof-bobemesting';

  @override
  String get srRate => 'Toedieningskoers *';

  @override
  String get enterANumber => 'Vul ’n getal in';

  @override
  String get srUnit => 'Eenheid';

  @override
  String get srTotalUsed => 'Totaal gebruik';

  @override
  String get srFieldsTreated => 'Lande behandel';

  @override
  String get srOperator => 'Operateur se naam *';

  @override
  String get srEquipment => 'Toerusting';

  @override
  String get srEquipmentHint => 'bv. Trekker-spuitbalk';

  @override
  String get srPhi => 'VOI (dae)';

  @override
  String get srPhiHint => 'Voor-oes-interval';

  @override
  String get srRei => 'HTI (dae)';

  @override
  String get srReiHint => 'Hertoetrede-interval';

  @override
  String get srWeather => 'Weerstoestande';

  @override
  String get srWeatherHint => 'bv. Helder, 22°C, wind < 5 km/h';

  @override
  String get srNotesHint => 'Enige bykomende notas';

  @override
  String get srSave => 'Stoor rekord';

  @override
  String get actionUpdate => 'Werk by';

  @override
  String get srTypeSpray => 'Spuittoediening';

  @override
  String get srTypeFertilizer => 'Kunsmistoediening';

  @override
  String unitBoxes(String value) {
    return '$value bokse';
  }

  @override
  String unitPieces(int count) {
    return '$count stuks';
  }

  @override
  String get errNoAuthUser => 'Geen aangetekende gebruiker nie';

  @override
  String errInitData(String error) {
    return 'Kon nie data laai nie: $error';
  }

  @override
  String errUpdateFiles(String error) {
    return 'Kon nie dokumentlêers bywerk nie: $error';
  }

  @override
  String errDeleteDoc(String error) {
    return 'Kon nie dokument skrap nie: $error';
  }

  @override
  String errFetchData(String error) {
    return 'Kon nie data haal nie: $error';
  }

  @override
  String errFetchCatsTypes(String error) {
    return 'Kon nie kategorieë en dokumenttipes haal nie: $error';
  }

  @override
  String errFetchCats(String error) {
    return 'Kon nie kategorieë haal nie: $error';
  }

  @override
  String errFetchTypes(String error) {
    return 'Kon nie dokumenttipes haal nie: $error';
  }

  @override
  String errFetchDocs(String error) {
    return 'Kon nie dokumente haal nie: $error';
  }

  @override
  String errGetDoc(String error) {
    return 'Kon nie dokument kry nie: $error';
  }

  @override
  String errCreateDoc(String error) {
    return 'Kon nie dokument skep nie: $error';
  }

  @override
  String get errNoEffectiveUser => 'Geen gebruiker gevind nie';

  @override
  String errUpdateStatus(String error) {
    return 'Kon nie dokumentstatus bywerk nie: $error';
  }

  @override
  String errSupersede(String error) {
    return 'Kon nie dokument vervang nie: $error';
  }

  @override
  String errAddSignature(String error) {
    return 'Kon nie handtekening byvoeg nie: $error';
  }

  @override
  String errAddComment(String error) {
    return 'Kon nie kommentaar byvoeg nie: $error';
  }

  @override
  String errCompliancePct(String error) {
    return 'Kon nie nakomingspersentasie bereken nie: $error';
  }

  @override
  String cmtCreatedByAdmin(String admin, String user) {
    return 'Dokument geskep deur admin $admin vir gebruiker $user';
  }

  @override
  String get cmtSpecUpdated => 'spesifikasie bygewerk';

  @override
  String cmtExpiryUpdated(String date) {
    return 'vervaldatum bygewerk na $date';
  }

  @override
  String get cmtExpiryRemoved => 'vervaldatum verwyder';

  @override
  String cmtStatusByAdmin(String name) {
    return 'Status bygewerk deur admin $name';
  }

  @override
  String viaAdmin(String user, String admin) {
    return '$user (via admin $admin)';
  }

  @override
  String get cmtResubmitted => 'Dokument weer ingedien met bygewerkte lêers.';

  @override
  String cmtResubmittedByAdmin(String admin, String user) {
    return 'Dokument weer ingedien met bygewerkte lêers deur admin $admin vir gebruiker $user.';
  }

  @override
  String get noReasonProvided => 'Geen rede verskaf nie';

  @override
  String errInitCats(String error) {
    return 'Kon nie kategorieë laai nie: $error';
  }

  @override
  String errComplianceStats(String error) {
    return 'Kon nie nakomingstatistiek bereken nie: $error';
  }

  @override
  String errAuditDocs(String error) {
    return 'Kon nie dokumente vir oudit kry nie: $error';
  }

  @override
  String get pushChannelName => 'Nakomingswaarskuwings';

  @override
  String get pushChannelDesc =>
      'Dokumentafkeurings, vervaldatums en ouditherinnerings';

  @override
  String get statusDraft => 'Konsep';

  @override
  String get statusFinal => 'Finaal';

  @override
  String routeNotFound(String name) {
    return 'Geen bladsy vir $name nie';
  }

  @override
  String get fmInvalidKey => 'Ongeldige API-sleutel.';

  @override
  String get fmForbidden => 'Toegang geweier.';

  @override
  String get fmNotFound => 'Nie gevind nie.';

  @override
  String get fmRateLimit => 'Limiet bereik. Probeer binnekort weer.';

  @override
  String fmApiError(int code) {
    return 'API-fout ($code)';
  }

  @override
  String get bankRefDefault => 'Salaris';

  @override
  String get bankNoteGeneric =>
      'Algemene uitleg met kolomopskrifte — koppel die kolomme in jou bank se invoerskerm en toets eers ’n klein oplaai.';

  @override
  String bankNoteUnverified(String bank) {
    return 'Sjabloon nog nie met $bank bevestig nie — toets eers ’n klein oplaai.';
  }

  @override
  String get bankIssueNetZero => 'netto loon is R 0.00 of minder';

  @override
  String bankFileName(String company, String bank, String period, String ext) {
    return '$company Bankbetalings $bank $period.$ext';
  }

  @override
  String bankFileNameGeneric(String company, String period, String ext) {
    return '$company Bankbetalings $period.$ext';
  }

  @override
  String get bankGenericName => 'Ander bank (algemene CSV)';

  @override
  String get unnamedEmployee => 'Naamlose werknemer';

  @override
  String get skipEmployeeGone => 'werknemerrekord bestaan nie meer nie';

  @override
  String get bankNoneSelected => 'Geen salarisstrokies gekies nie.';

  @override
  String get bankChooseBank => 'Kies die bank waaruit die plaas betaal.';

  @override
  String bankDraftsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count konsep-salarisstrokies gekies — verwyder hulle of sluit hulle tog in.',
      one: '1 konsep-salarisstrokie gekies — verwyder dit of sluit dit tog in.',
    );
    return '$_temp0';
  }

  @override
  String get bankAllDrafts =>
      'Al die gekose salarisstrokies is konsepte — sluit hulle tog in of kies gefinaliseerde salarisstrokies.';

  @override
  String get bankNobodyBanking =>
      'Niemand het nog bankbesonderhede nie — voeg dit by om voort te gaan.';

  @override
  String get bankNotLinked =>
      'Hierdie salarisstrokies is nie aan ’n werknemer gekoppel nie — herstel hulle om voort te gaan.';

  @override
  String get bankNobodyPayableFix =>
      'Niemand kan nog betaal word nie — herstel die werknemers hieronder.';

  @override
  String pdfPayslipFile(String name, String period) {
    return '$name $period Salarisstrokie.pdf';
  }

  @override
  String pdfUifFile(String company, String period) {
    return '$company UIF-opsomming $period.pdf';
  }

  @override
  String pdfLeaveFile(String company, String stamp) {
    return '$company Verlofrekords $stamp.pdf';
  }

  @override
  String get psEmployeeType => 'Werknemer Tipe';

  @override
  String get payslipFinalisedDot => 'Hierdie salarisstrokie is gefinaliseer.';

  @override
  String get payslipDraftBanner =>
      'KONSEP – Hierdie salarisstrokie is nog nie gefinaliseer nie.';

  @override
  String get uifSummaryTitle => 'UIF & AFTREKKINGS OPSOMMING';

  @override
  String uifPeriodRange(String start, String end) {
    return 'Periode: $start – $end';
  }

  @override
  String uifRegNrValue(String value) {
    return 'UIF Reg Nr: $value';
  }

  @override
  String uifEmployeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werknemers',
      one: '1 werknemer',
    );
    return '$_temp0';
  }

  @override
  String get uifColIncome => 'Inkomste';

  @override
  String get uifColEmployeeUif => 'UIF Wrkn (1%)';

  @override
  String get uifColEmployerUif => 'UIF Wrkgr (1%)';

  @override
  String get uifColOtherDed => 'Ander Aftr.';

  @override
  String get uifColEmployeeDed => 'Werkn. Aftr.';

  @override
  String get uifSummaryHeading => 'Opsomming';

  @override
  String get uifPayeTaxColon => 'PAYE Belasting:';

  @override
  String get uifEmployeeContribution => 'Werknemers UIF bydrae (1%):';

  @override
  String get uifOtherDeductions => 'Ander aftrekkings:';

  @override
  String get uifTotalEmployeeDed => 'TOTALE WERKNEMER AFTREKKINGS:';

  @override
  String get uifEmployerContribution => 'Werkgewer UIF bydrae (1%):';

  @override
  String get uifTotalPayable => 'TOTALE UIF BETAALBAAR (Wrkn + Wrkgr):';

  @override
  String get leavePdfTitle => 'VERLOF REKORDS';

  @override
  String leavePdfGenerated(String date) {
    return 'Opgestel: $date';
  }

  @override
  String get leavePdfHoursNote => 'Waardes in ure (dae = ure ÷ 8)';

  @override
  String get leavePdfNoEmployees => 'Geen werknemers nie.';

  @override
  String get leavePdfColType => 'Verlof Tipe';

  @override
  String get leavePdfOpening => 'Opening';

  @override
  String get leavePdfHoliday => 'Vakansie (VV)';

  @override
  String get leavePdfSick => 'Siekte (SV)';

  @override
  String get leavePdfFamily => 'Gesin (GV)';

  @override
  String get leavePdfFormula =>
      'Saldo = Opening (voor die stelsel) + Toegeken (in stelsel) − Geneem.';

  @override
  String get xlsSheet => 'Salarisstrokies';

  @override
  String get xlsType => 'Tipe';

  @override
  String get xlsJob => 'Pos';

  @override
  String get xlsSickHrs => 'Siek ure';

  @override
  String get xlsHolidayHrs => 'Vakansie ure';

  @override
  String get xlsFamilyHrs => 'Gesin ure';

  @override
  String get xlsGross => 'Bruto (R)';

  @override
  String get xlsPaye => 'PAYE (R)';

  @override
  String get xlsUif => 'UIF 1% (R)';

  @override
  String get xlsOtherDed => 'Ander aftrekkings (R)';

  @override
  String get xlsTotalDed => 'Totale aftrekkings (R)';

  @override
  String get xlsNet => 'Netto (R)';

  @override
  String xlsTotalRow(int count) {
    return 'TOTAAL ($count)';
  }

  @override
  String xlsFileName(String company, String period) {
    return '$company Salarisstrokies $period.xlsx';
  }

  @override
  String zipFileName(String company) {
    return '$company Salarisstrokies.zip';
  }

  @override
  String frFileName(String company, String stamp) {
    return '$company Plaasregister $stamp.pdf';
  }

  @override
  String get frTitle => 'PLAASREGISTER';

  @override
  String frFarm(String name) {
    return 'Plaas: $name';
  }

  @override
  String frCountry(String name) {
    return 'Land: $name';
  }

  @override
  String frLocation(String lat, String lng) {
    return 'Ligging: $lat, $lng';
  }

  @override
  String frGenerated(String date) {
    return 'Opgestel: $date';
  }

  @override
  String frCounts(int fields, String area, int equipment, int people) {
    return '$fields lande · $area ha · $equipment toerusting · $people mense';
  }

  @override
  String get frFieldsSection => 'LANDE / BLOKKE';

  @override
  String get frBlockField => 'Blok / land';

  @override
  String get frAreaHa => 'Oppervlakte (ha)';

  @override
  String get frEquipmentSection => 'TOERUSTINGREGISTER';

  @override
  String get frCapacity => 'Kapasiteit';

  @override
  String get frRate => 'Koers';

  @override
  String get frRegNo => 'Reg.-nr.';

  @override
  String get frInspection => 'Inspeksie';

  @override
  String get frPeopleSection => 'MENSE / ROLLE';

  @override
  String get frName => 'Naam';

  @override
  String get frEmail => 'E-pos';

  @override
  String get frRole => 'Rol';

  @override
  String get frSource =>
      'Bron: Farmable Partner API v2.0. Deur Crop Compliance opgestel as ouditbewys.';

  @override
  String get leaveCodePH => 'OV';

  @override
  String get leaveCodeA => 'A';

  @override
  String get tsLeaveCodesTitle => 'Verlofkodes';

  @override
  String get tsLeaveHintPick =>
      'Klik op ’n dag in die rooster, dan op ’n kode — of tik die kode reg in die dag.';

  @override
  String tsLeaveHintTarget(String name, String day) {
    return 'Vul $name · $day in — skuif na die volgende dag ná elke kode.';
  }

  @override
  String get tsLeavePickDayFirst =>
      'Klik eers op die dag in die rooster, dan op die verlofkode.';

  @override
  String get tsCodeSL => 'Siekverlof';

  @override
  String get tsCodeHL => 'Vakansieverlof';

  @override
  String get tsCodeFL => 'Gesinsverantwoordelikheid';

  @override
  String get tsCodePH => 'Openbare vakansiedag';

  @override
  String get tsCodeA => 'Afwesig (onbetaald)';

  @override
  String get tsCodeClear => 'Maak dag skoon';

  @override
  String tsCodeTipSL(String hours) {
    return 'Betaal as een gewone dag ($hours h) en van die werknemer se siekverlofsaldo afgetrek.';
  }

  @override
  String tsCodeTipHL(String hours) {
    return 'Betaal as een gewone dag ($hours h) en van die werknemer se vakansieverlofsaldo afgetrek.';
  }

  @override
  String tsCodeTipFL(String hours) {
    return 'Betaal as een gewone dag ($hours h) en van die werknemer se gesinsverantwoordelikheidsverlof-saldo afgetrek.';
  }

  @override
  String tsCodeTipPH(String hours) {
    return 'Openbare vakansiedag nie gewerk nie: betaal as een gewone dag ($hours h). As hulle gewerk het, tik eerder hul ure.';
  }

  @override
  String get tsCodeTipA => 'Afwesig — hierdie dag word nie betaal nie.';

  @override
  String get tsCodeTipClear => 'Maak die gekose dag leeg.';

  @override
  String get farmChooseToContinue => 'Kies ’n plaas';

  @override
  String get pdfDownloadBtn => 'Laai PDF af';

  @override
  String get pdfOpenPrint => 'Maak oop / druk';

  @override
  String get psPayeBelowThreshold =>
      'Onder die belastingdrempel — geen PAYE vir hierdie tydperk nie';

  @override
  String get psEarningsCaps => 'VERDIENSTE';

  @override
  String get psDeductionsCaps => 'AFTREKKINGS';

  @override
  String tsPdfFile(String company, String start) {
    return 'Tydstaat $company $start.pdf';
  }

  @override
  String tsPdfHeading(String sheet) {
    return 'Tydstaat · $sheet';
  }

  @override
  String get tsPdfDraft => 'Konsep — nie gefinaliseer nie';

  @override
  String tsPdfPrinted(String date) {
    return 'Gedruk $date';
  }

  @override
  String get tsPdfChecked =>
      'Nagegaan deur: ______________________________      Handtekening: ______________________________      Datum: ____________________';

  @override
  String tsPdfPieceLegend(String unit) {
    return 'Elke dag: ure gewerk (h) en $unit gepluk.';
  }

  @override
  String get tsPdfDownloading => 'Maak die tydstaat-PDF…';

  @override
  String tsLeaveUnpaidTip(String leave) {
    return 'Onbetaal — nie genoeg $leave oor nie (gekies met stoor). Tik die kode weer om dit weer te laat nagaan.';
  }

  @override
  String tsLeavePartTip(String hours, String leave) {
    return '$hours h betaal, die res onbetaal — nie genoeg $leave oor nie (gekies met stoor). Tik die kode weer om dit weer te laat nagaan.';
  }

  @override
  String tsLeaveOverrideTip(String leave) {
    return 'Ten volle betaal al was die $leave-saldo te min (gekies met stoor). Tik die kode weer om dit weer te laat nagaan.';
  }

  @override
  String tsUnpaidBadge(String hours) {
    return '$hours h onbetaal';
  }

  @override
  String get tsLeaveUnpaidLegend =>
      '= onbetaal of deels betaal — nie genoeg verlof oor nie, soos gekies met stoor. Tik die kode weer om die dag weer te laat nagaan.';

  @override
  String get tsPdfUnpaidLegend =>
      '’n Getal onder ’n verlofkode = ure betaal vir daardie dag (nie genoeg verlof oor nie).';

  @override
  String get tsLeaveSettledToast =>
      'Jou keuses is op die tydstaat: deurgestreepte dae is onbetaal.';
}
