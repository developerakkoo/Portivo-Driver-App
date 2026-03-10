import 'package:flutter/material.dart';
import 'locales/app_localizations_en.dart';
import 'locales/app_localizations_hi.dart';
import 'locales/app_localizations_mr.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final List<Locale> supportedLocales = [
    const Locale('en'),
    const Locale('hi'),
    const Locale('mr'),
  ];

  // Get the appropriate localization class based on locale
  dynamic get _localizations {
    switch (locale.languageCode) {
      case 'hi':
        return AppLocalizationsHi();
      case 'mr':
        return AppLocalizationsMr();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  // Login Screen
  String get welcomeToPorttivoDriver => _localizations.welcomeToPorttivoDriver;
  String get pleaseEnterMobileNumber => _localizations.pleaseEnterMobileNumber;
  String get mobileNumber => _localizations.mobileNumber;
  String get enterMobileNumber => _localizations.enterMobileNumber;
  String get pleaseEnterMobileNumberValidation => _localizations.pleaseEnterMobileNumberValidation;
  String get validMobileNumberValidation => _localizations.validMobileNumberValidation;
  String get signIn => _localizations.signIn;
  String get signingIn => _localizations.signingIn;

  // Home Tab
  String get home => _localizations.home;
  String welcomeBackWithName(String name) => _localizations.welcomeBackWithName(name);
  String get readyToStartYourDay => _localizations.readyToStartYourDay;
  String get activeTrip => _localizations.activeTrip;
  String get tapToViewDetails => _localizations.tapToViewDetails;
  String get queuedTrips => _localizations.queuedTrips;
  String get activeTrips => _localizations.activeTrips;
  String get completed => _localizations.completed;
  String get wallet => _localizations.wallet;

  // Trips Tab
  String get active => _localizations.active;
  String get queued => _localizations.queued;
  String get history => _localizations.history;
  String get noActiveTrip => _localizations.noActiveTrip;
  String get activeTripsWillAppearHere => _localizations.activeTripsWillAppearHere;
  String get noQueuedTrips => _localizations.noQueuedTrips;
  String get queuedTripsWillAppearHere => _localizations.queuedTripsWillAppearHere;
  String get noTripHistory => _localizations.noTripHistory;
  String get completedTripsWillAppearHere => _localizations.completedTripsWillAppearHere;

  // Menu Tab
  String get menu => _localizations.menu;
  String get fuelCards => _localizations.fuelCards;
  String get trips => _localizations.trips;
  String get profile => _localizations.profile;
  String get logout => _localizations.logout;
  String get logoutConfirmation => _localizations.logoutConfirmation;
  String get cancel => _localizations.cancel;

  // Profile Screen
  String get profileTitle => _localizations.profileTitle;
  String get personalInformation => _localizations.personalInformation;
  String get name => _localizations.name;
  String get enterName => _localizations.enterName;
  String get languagePreference => _localizations.languagePreference;
  String get english => _localizations.english;
  String get hindi => _localizations.hindi;
  String get marathi => _localizations.marathi;
  String get languagePreferenceUpdated => _localizations.languagePreferenceUpdated;
  String get failedToUpdateLanguage => _localizations.failedToUpdateLanguage;
  String get save => _localizations.save;
  String get saving => _localizations.saving;
  String get profileUpdated => _localizations.profileUpdated;
  String get failedToUpdateProfile => _localizations.failedToUpdateProfile;

  // Active Trip Screen
  String get activeTripTitle => _localizations.activeTripTitle;
  String get tripDetails => _localizations.tripDetails;
  String get tripId => _localizations.tripId;
  String get container => _localizations.container;
  String get reference => _localizations.reference;
  String get type => _localizations.type;
  String get status => _localizations.status;
  String get milestoneProgress => _localizations.milestoneProgress;
  String milestonesCompletedWithCount(int count) => _localizations.milestonesCompletedWithCount(count);
  String nextMilestoneWithNumber(int number) => _localizations.nextMilestoneWithNumber(number);
  String get locations => _localizations.locations;
  String get pickup => _localizations.pickup;
  String get drop => _localizations.drop;
  String updateMilestoneWithNumber(int number) => _localizations.updateMilestoneWithNumber(number);
  String get uploadPOD => _localizations.uploadPOD;
  String get completeTrip => _localizations.completeTrip;
  String get tripCompletedSuccessfully => _localizations.tripCompletedSuccessfully;
  String get failedToCompleteTrip => _localizations.failedToCompleteTrip;
  String get tripNotFound => _localizations.tripNotFound;
  String get pullDownToRefresh => _localizations.pullDownToRefresh;

  // Milestone Update Screen
  String get updateMilestoneTitle => _localizations.updateMilestoneTitle;
  String get containerPicked => _localizations.containerPicked;
  String get reachedLocation => _localizations.reachedLocation;
  String get loadingUnloading => _localizations.loadingUnloading;
  String get reachedDestination => _localizations.reachedDestination;
  String get tripCompleted => _localizations.tripCompleted;
  String get capturePhoto => _localizations.capturePhoto;
  String get address => _localizations.address;
  String get enterAddress => _localizations.enterAddress;
  String get update => _localizations.update;
  String get updating => _localizations.updating;
  String get milestoneUpdatedSuccessfully => _localizations.milestoneUpdatedSuccessfully;
  String get failedToUpdateMilestone => _localizations.failedToUpdateMilestone;
  String get photoRequired => _localizations.photoRequired;
  String get locationRequired => _localizations.locationRequired;

  // POD Upload Screen
  String get uploadPODTitle => _localizations.uploadPODTitle;
  String get podUploadedSuccessfully => _localizations.podUploadedSuccessfully;
  String get failedToUploadPOD => _localizations.failedToUploadPOD;
  String get pleaseCapturePhotoFirst => _localizations.pleaseCapturePhotoFirst;
  String get uploading => _localizations.uploading;

  // Wallet Screen
  String get walletTitle => _localizations.walletTitle;
  String get walletBalance => _localizations.walletBalance;
  String get transactions => _localizations.transactions;
  String get noTransactions => _localizations.noTransactions;
  String get transactionsWillAppearHere => _localizations.transactionsWillAppearHere;

  // Access Pending Screen
  String get accessPending => _localizations.accessPending;
  String get accessPendingMessage => _localizations.accessPendingMessage;
  String get contactTransporter => _localizations.contactTransporter;

  // Common
  String get loading => _localizations.loading;
  String get error => _localizations.error;
  String get success => _localizations.success;
  String get retry => _localizations.retry;
  String get continue_ => _localizations.continue_;
  String get back => _localizations.back;
  String get done => _localizations.done;
  String get ok => _localizations.ok;
  String get yes => _localizations.yes;
  String get no => _localizations.no;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
