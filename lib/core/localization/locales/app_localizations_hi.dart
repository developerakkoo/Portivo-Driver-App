class AppLocalizationsHi {
  // Login Screen
  String get welcomeToPorttivoDriver => 'पोर्टिवो ड्राइवर में आपका स्वागत है';
  String get pleaseEnterMobileNumber => 'कृपया जारी रखने के लिए अपना मोबाइल नंबर दर्ज करें';
  String get mobileNumber => 'मोबाइल नंबर';
  String get enterMobileNumber => 'अपना मोबाइल नंबर दर्ज करें';
  String get pleaseEnterMobileNumberValidation => 'कृपया अपना मोबाइल नंबर दर्ज करें';
  String get validMobileNumberValidation => 'कृपया एक वैध 10-अंकीय मोबाइल नंबर दर्ज करें';
  String get signIn => 'साइन इन करें';
  String get signingIn => 'साइन इन हो रहा है...';

  // Home Tab
  String get home => 'होम';
  String get welcomeBack => 'वापसी पर स्वागत है, {name}!';
  String welcomeBackWithName(String name) => welcomeBack.replaceAll('{name}', name);
  String get readyToStartYourDay => 'अपना दिन शुरू करने के लिए तैयार?';
  String get activeTrip => 'सक्रिय यात्रा';
  String get tapToViewDetails => 'विवरण देखने के लिए टैप करें';
  String get queuedTrips => 'कतारबद्ध यात्राएं';
  String get activeTrips => 'सक्रिय यात्राएं';
  String get completed => 'पूर्ण';
  String get wallet => 'वॉलेट';

  // Trips Tab
  String get active => 'सक्रिय';
  String get queued => 'कतारबद्ध';
  String get history => 'इतिहास';
  String get noActiveTrip => 'कोई सक्रिय यात्रा नहीं';
  String get activeTripsWillAppearHere => 'आपकी सक्रिय यात्राएं यहां दिखाई देंगी';
  String get noQueuedTrips => 'कोई कतारबद्ध यात्रा नहीं';
  String get queuedTripsWillAppearHere => 'आपकी कतारबद्ध यात्राएं यहां दिखाई देंगी';
  String get noTripHistory => 'कोई यात्रा इतिहास नहीं';
  String get completedTripsWillAppearHere => 'आपकी पूर्ण यात्राएं यहां दिखाई देंगी';

  // Menu Tab
  String get menu => 'मेनू';
  String get fuelCards => 'ईंधन कार्ड';
  String get trips => 'यात्राएं';
  String get profile => 'प्रोफ़ाइल';
  String get logout => 'लॉगआउट';
  String get logoutConfirmation => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';
  String get cancel => 'रद्द करें';

  // Profile Screen
  String get profileTitle => 'प्रोफ़ाइल';
  String get personalInformation => 'व्यक्तिगत जानकारी';
  String get name => 'नाम';
  String get enterName => 'अपना नाम दर्ज करें';
  String get languagePreference => 'भाषा वरीयता';
  String get english => 'English';
  String get hindi => 'हिंदी (Hindi)';
  String get marathi => 'मराठी (Marathi)';
  String get languagePreferenceUpdated => 'भाषा वरीयता अपडेट की गई';
  String get failedToUpdateLanguage => 'भाषा अपडेट करने में विफल';
  String get save => 'सहेजें';
  String get saving => 'सहेजा जा रहा है...';
  String get profileUpdated => 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई';
  String get failedToUpdateProfile => 'प्रोफ़ाइल अपडेट करने में विफल';

  // Active Trip Screen
  String get activeTripTitle => 'सक्रिय यात्रा';
  String get tripDetails => 'यात्रा विवरण';
  String get tripId => 'यात्रा आईडी';
  String get container => 'कंटेनर';
  String get reference => 'संदर्भ';
  String get type => 'प्रकार';
  String get status => 'स्थिति';
  String get milestoneProgress => 'माइलस्टोन प्रगति';
  String get milestonesCompleted => '5 में से {count} माइलस्टोन पूर्ण';
  String milestonesCompletedWithCount(int count) => milestonesCompleted.replaceAll('{count}', count.toString());
  String get nextMilestone => 'अगला: माइलस्टोन {number}';
  String nextMilestoneWithNumber(int number) => nextMilestone.replaceAll('{number}', number.toString());
  String get locations => 'स्थान';
  String get pickup => 'पिकअप';
  String get drop => 'ड्रॉप';
  String get updateMilestone => 'माइलस्टोन {number} अपडेट करें';
  String updateMilestoneWithNumber(int number) => updateMilestone.replaceAll('{number}', number.toString());
  String get uploadPOD => 'POD अपलोड करें';
  String get completeTrip => 'यात्रा पूर्ण करें';
  String get tripCompletedSuccessfully => 'यात्रा सफलतापूर्वक पूर्ण हुई!';
  String get failedToCompleteTrip => 'यात्रा पूर्ण करने में विफल';
  String get tripNotFound => 'यात्रा नहीं मिली';
  String get pullDownToRefresh => 'रिफ्रेश करने के लिए नीचे खींचें';

  // Milestone Update Screen
  String get updateMilestoneTitle => 'माइलस्टोन अपडेट करें';
  String get containerPicked => 'कंटेनर उठाया गया';
  String get reachedLocation => 'स्थान पर पहुंचे';
  String get loadingUnloading => 'लोडिंग/अनलोडिंग';
  String get reachedDestination => 'गंतव्य पर पहुंचे';
  String get tripCompleted => 'यात्रा पूर्ण';
  String get capturePhoto => 'फोटो कैप्चर करें';
  String get address => 'पता';
  String get enterAddress => 'पता दर्ज करें (वैकल्पिक)';
  String get update => 'अपडेट करें';
  String get updating => 'अपडेट हो रहा है...';
  String get milestoneUpdatedSuccessfully => 'माइलस्टोन सफलतापूर्वक अपडेट किया गया!';
  String get failedToUpdateMilestone => 'माइलस्टोन अपडेट करने में विफल';
  String get photoRequired => 'कृपया एक फोटो कैप्चर करें';
  String get locationRequired => 'स्थान आवश्यक है';

  // POD Upload Screen
  String get uploadPODTitle => 'POD अपलोड करें';
  String get podUploadedSuccessfully => 'POD सफलतापूर्वक अपलोड किया गया! अनुमोदन की प्रतीक्षा कर रहे हैं।';
  String get failedToUploadPOD => 'POD अपलोड करने में विफल';
  String get pleaseCapturePhotoFirst => 'कृपया पहले एक फोटो कैप्चर करें';
  String get uploading => 'अपलोड हो रहा है...';

  // Wallet Screen
  String get walletTitle => 'वॉलेट';
  String get walletBalance => 'वॉलेट बैलेंस';
  String get transactions => 'लेनदेन';
  String get noTransactions => 'अभी तक कोई लेनदेन नहीं';
  String get transactionsWillAppearHere => 'आपके लेनदेन यहां दिखाई देंगे';

  // Access Pending Screen
  String get accessPending => 'पहुंच लंबित';
  String get accessPendingMessage => 'आपकी पहुंच ट्रांसपोर्टर से अनुमोदन की प्रतीक्षा में है। कृपया अनुमोदन की प्रतीक्षा करें या अधिक जानकारी के लिए अपने ट्रांसपोर्टर से संपर्क करें।';
  String get contactTransporter => 'ट्रांसपोर्टर से संपर्क करें';

  // Common
  String get loading => 'लोड हो रहा है...';
  String get error => 'त्रुटि';
  String get success => 'सफलता';
  String get retry => 'पुनः प्रयास करें';
  String get continue_ => 'जारी रखें';
  String get back => 'वापस';
  String get done => 'पूर्ण';
  String get ok => 'ठीक है';
  String get yes => 'हाँ';
  String get no => 'नहीं';
}
