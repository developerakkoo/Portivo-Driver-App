class AppLocalizationsMr {
  // Login Screen
  String get welcomeToPorttivoDriver => 'पोर्टिवो ड्रायव्हरमध्ये आपले स्वागत आहे';
  String get pleaseEnterMobileNumber => 'कृपया सुरू ठेवण्यासाठी आपला मोबाइल नंबर प्रविष्ट करा';
  String get mobileNumber => 'मोबाइल नंबर';
  String get enterMobileNumber => 'आपला मोबाइल नंबर प्रविष्ट करा';
  String get pleaseEnterMobileNumberValidation => 'कृपया आपला मोबाइल नंबर प्रविष्ट करा';
  String get validMobileNumberValidation => 'कृपया वैध 10-अंकी मोबाइल नंबर प्रविष्ट करा';
  String get signIn => 'साइन इन करा';
  String get signingIn => 'साइन इन होत आहे...';

  // Home Tab
  String get home => 'होम';
  String get welcomeBack => 'पुन्हा स्वागत आहे, {name}!';
  String welcomeBackWithName(String name) => welcomeBack.replaceAll('{name}', name);
  String get readyToStartYourDay => 'आपला दिवस सुरू करण्यासाठी तयार आहात?';
  String get activeTrip => 'सक्रिय प्रवास';
  String get tapToViewDetails => 'तपशील पाहण्यासाठी टॅप करा';
  String get queuedTrips => 'रांगेत असलेले प्रवास';
  String get activeTrips => 'सक्रिय प्रवास';
  String get completed => 'पूर्ण';
  String get wallet => 'वॉलेट';

  // Trips Tab
  String get active => 'सक्रिय';
  String get queued => 'रांगेत';
  String get history => 'इतिहास';
  String get noActiveTrip => 'सक्रिय प्रवास नाही';
  String get activeTripsWillAppearHere => 'आपले सक्रिय प्रवास येथे दिसतील';
  String get noQueuedTrips => 'रांगेत असलेले प्रवास नाहीत';
  String get queuedTripsWillAppearHere => 'आपले रांगेत असलेले प्रवास येथे दिसतील';
  String get noTripHistory => 'प्रवास इतिहास नाही';
  String get completedTripsWillAppearHere => 'आपले पूर्ण झालेले प्रवास येथे दिसतील';

  // Menu Tab
  String get menu => 'मेनू';
  String get fuelCards => 'इंधन कार्ड';
  String get trips => 'प्रवास';
  String get profile => 'प्रोफाइल';
  String get logout => 'लॉगआउट';
  String get logoutConfirmation => 'आपण खरोखर लॉगआउट करू इच्छिता?';
  String get cancel => 'रद्द करा';

  // Profile Screen
  String get profileTitle => 'प्रोफाइल';
  String get personalInformation => 'वैयक्तिक माहिती';
  String get name => 'नाव';
  String get enterName => 'आपले नाव प्रविष्ट करा';
  String get languagePreference => 'भाषा प्राधान्य';
  String get english => 'English';
  String get hindi => 'हिंदी (Hindi)';
  String get marathi => 'मराठी (Marathi)';
  String get languagePreferenceUpdated => 'भाषा प्राधान्य अद्यतनित केले';
  String get failedToUpdateLanguage => 'भाषा अद्यतनित करण्यात अयशस्वी';
  String get save => 'जतन करा';
  String get saving => 'जतन होत आहे...';
  String get profileUpdated => 'प्रोफाइल यशस्वीरित्या अद्यतनित केले';
  String get failedToUpdateProfile => 'प्रोफाइल अद्यतनित करण्यात अयशस्वी';

  // Active Trip Screen
  String get activeTripTitle => 'सक्रिय प्रवास';
  String get tripDetails => 'प्रवास तपशील';
  String get tripId => 'प्रवास आयडी';
  String get container => 'कंटेनर';
  String get reference => 'संदर्भ';
  String get type => 'प्रकार';
  String get status => 'स्थिती';
  String get milestoneProgress => 'माइलस्टोन प्रगती';
  String get milestonesCompleted => '5 पैकी {count} माइलस्टोन पूर्ण';
  String milestonesCompletedWithCount(int count) => milestonesCompleted.replaceAll('{count}', count.toString());
  String get nextMilestone => 'पुढील: माइलस्टोन {number}';
  String nextMilestoneWithNumber(int number) => nextMilestone.replaceAll('{number}', number.toString());
  String get locations => 'स्थाने';
  String get pickup => 'पिकअप';
  String get drop => 'ड्रॉप';
  String get updateMilestone => 'माइलस्टोन {number} अद्यतनित करा';
  String updateMilestoneWithNumber(int number) => updateMilestone.replaceAll('{number}', number.toString());
  String get uploadPOD => 'POD अपलोड करा';
  String get completeTrip => 'प्रवास पूर्ण करा';
  String get tripCompletedSuccessfully => 'प्रवास यशस्वीरित्या पूर्ण झाला!';
  String get failedToCompleteTrip => 'प्रवास पूर्ण करण्यात अयशस्वी';
  String get tripNotFound => 'प्रवास सापडला नाही';
  String get pullDownToRefresh => 'रिफ्रेश करण्यासाठी खाली खेचा';

  // Milestone Update Screen
  String get updateMilestoneTitle => 'माइलस्टोन अद्यतनित करा';
  String get containerPicked => 'कंटेनर उचलले';
  String get reachedLocation => 'स्थानावर पोहोचले';
  String get loadingUnloading => 'लोडिंग/अनलोडिंग';
  String get reachedDestination => 'गंतव्यस्थानावर पोहोचले';
  String get tripCompleted => 'प्रवास पूर्ण';
  String get capturePhoto => 'फोटो कॅप्चर करा';
  String get address => 'पत्ता';
  String get enterAddress => 'पत्ता प्रविष्ट करा (पर्यायी)';
  String get update => 'अद्यतनित करा';
  String get updating => 'अद्यतनित होत आहे...';
  String get milestoneUpdatedSuccessfully => 'माइलस्टोन यशस्वीरित्या अद्यतनित केले!';
  String get failedToUpdateMilestone => 'माइलस्टोन अद्यतनित करण्यात अयशस्वी';
  String get photoRequired => 'कृपया एक फोटो कॅप्चर करा';
  String get locationRequired => 'स्थान आवश्यक आहे';

  // POD Upload Screen
  String get uploadPODTitle => 'POD अपलोड करा';
  String get podUploadedSuccessfully => 'POD यशस्वीरित्या अपलोड केले! मंजुरीची प्रतीक्षा करत आहे.';
  String get failedToUploadPOD => 'POD अपलोड करण्यात अयशस्वी';
  String get pleaseCapturePhotoFirst => 'कृपया प्रथम एक फोटो कॅप्चर करा';
  String get uploading => 'अपलोड होत आहे...';

  // Wallet Screen
  String get walletTitle => 'वॉलेट';
  String get walletBalance => 'वॉलेट शिल्लक';
  String get transactions => 'व्यवहार';
  String get noTransactions => 'अद्याप कोणतेही व्यवहार नाहीत';
  String get transactionsWillAppearHere => 'आपले व्यवहार येथे दिसतील';

  // Access Pending Screen
  String get accessPending => 'प्रवेश लंबित';
  String get accessPendingMessage => 'आपला प्रवेश ट्रान्सपोर्टरकडून मंजुरीची प्रतीक्षा करत आहे. कृपया मंजुरीची प्रतीक्षा करा किंवा अधिक माहितीसाठी आपल्या ट्रान्सपोर्टरशी संपर्क साधा.';
  String get contactTransporter => 'ट्रान्सपोर्टरशी संपर्क साधा';

  // Common
  String get loading => 'लोड होत आहे...';
  String get error => 'त्रुटी';
  String get success => 'यश';
  String get retry => 'पुन्हा प्रयत्न करा';
  String get continue_ => 'सुरू ठेवा';
  String get back => 'मागे';
  String get done => 'पूर्ण';
  String get ok => 'ठीक आहे';
  String get yes => 'होय';
  String get no => 'नाही';
}
