class AppLocalizationsEn {
  // Login Screen
  String get welcomeToPorttivoDriver => 'Welcome to Porttivo Driver';
  String get pleaseEnterMobileNumber => 'Please enter your mobile number to continue';
  String get mobileNumber => 'Mobile Number';
  String get enterMobileNumber => 'Enter your mobile number';
  String get pleaseEnterMobileNumberValidation => 'Please enter your mobile number';
  String get validMobileNumberValidation => 'Please enter a valid 10-digit mobile number';
  String get signIn => 'Sign In';
  String get signingIn => 'Signing in...';

  // Home Tab
  String get home => 'Home';
  String get welcomeBack => 'Welcome back, {name}!';
  String welcomeBackWithName(String name) => welcomeBack.replaceAll('{name}', name);
  String get readyToStartYourDay => 'Ready to start your day?';
  String get activeTrip => 'Active Trip';
  String get tapToViewDetails => 'Tap to view details';
  String get queuedTrips => 'Queued Trips';
  String get activeTrips => 'Active Trips';
  String get completed => 'Completed';
  String get wallet => 'Wallet';

  // Trips Tab
  String get active => 'Active';
  String get queued => 'Queued';
  String get history => 'History';
  String get noActiveTrip => 'No active trip';
  String get activeTripsWillAppearHere => 'Your active trips will appear here';
  String get noQueuedTrips => 'No queued trips';
  String get queuedTripsWillAppearHere => 'Your queued trips will appear here';
  String get noTripHistory => 'No trip history';
  String get completedTripsWillAppearHere => 'Your completed trips will appear here';

  // Menu Tab
  String get menu => 'Menu';
  String get fuelCards => 'Fuel Cards';
  String get trips => 'Trips';
  String get profile => 'Profile';
  String get logout => 'Logout';
  String get logoutConfirmation => 'Are you sure you want to logout?';
  String get cancel => 'Cancel';

  // Profile Screen
  String get profileTitle => 'Profile';
  String get personalInformation => 'Personal Information';
  String get name => 'Name';
  String get enterName => 'Enter your name';
  String get languagePreference => 'Language Preference';
  String get english => 'English';
  String get hindi => 'हिंदी (Hindi)';
  String get marathi => 'मराठी (Marathi)';
  String get languagePreferenceUpdated => 'Language preference updated';
  String get failedToUpdateLanguage => 'Failed to update language';
  String get save => 'Save';
  String get saving => 'Saving...';
  String get profileUpdated => 'Profile updated successfully';
  String get failedToUpdateProfile => 'Failed to update profile';

  // Active Trip Screen
  String get activeTripTitle => 'Active Trip';
  String get tripDetails => 'Trip Details';
  String get tripId => 'Trip ID';
  String get container => 'Container';
  String get reference => 'Reference';
  String get type => 'Type';
  String get status => 'Status';
  String get milestoneProgress => 'Milestone Progress';
  String get milestonesCompleted => '{count} of 5 milestones completed';
  String milestonesCompletedWithCount(int count) => milestonesCompleted.replaceAll('{count}', count.toString());
  String get nextMilestone => 'Next: Milestone {number}';
  String nextMilestoneWithNumber(int number) => nextMilestone.replaceAll('{number}', number.toString());
  String get locations => 'Locations';
  String get pickup => 'Pickup';
  String get drop => 'Drop';
  String get updateMilestone => 'Update Milestone {number}';
  String updateMilestoneWithNumber(int number) => updateMilestone.replaceAll('{number}', number.toString());
  String get uploadPOD => 'Upload POD';
  String get completeTrip => 'Complete Trip';
  String get tripCompletedSuccessfully => 'Trip completed successfully!';
  String get failedToCompleteTrip => 'Failed to complete trip';
  String get tripNotFound => 'Trip not found';
  String get pullDownToRefresh => 'Pull down to refresh';

  // Milestone Update Screen
  String get updateMilestoneTitle => 'Update Milestone';
  String get containerPicked => 'Container Picked';
  String get reachedLocation => 'Reached Location';
  String get loadingUnloading => 'Loading/Unloading';
  String get reachedDestination => 'Reached Destination';
  String get tripCompleted => 'Trip Completed';
  String get capturePhoto => 'Capture Photo';
  String get address => 'Address';
  String get enterAddress => 'Enter address (optional)';
  String get update => 'Update';
  String get updating => 'Updating...';
  String get milestoneUpdatedSuccessfully => 'Milestone updated successfully!';
  String get failedToUpdateMilestone => 'Failed to update milestone';
  String get photoRequired => 'Please capture a photo';
  String get locationRequired => 'Location is required';

  // POD Upload Screen
  String get uploadPODTitle => 'Upload POD';
  String get podUploadedSuccessfully => 'POD uploaded successfully! Waiting for approval.';
  String get failedToUploadPOD => 'Failed to upload POD';
  String get pleaseCapturePhotoFirst => 'Please capture a photo first';
  String get uploading => 'Uploading...';

  // Wallet Screen
  String get walletTitle => 'Wallet';
  String get walletBalance => 'Wallet Balance';
  String get transactions => 'Transactions';
  String get noTransactions => 'No transactions yet';
  String get transactionsWillAppearHere => 'Your transactions will appear here';

  // Access Pending Screen
  String get accessPending => 'Access Pending';
  String get accessPendingMessage => 'Your access is pending approval from the transporter. Please wait for approval or contact your transporter for more information.';
  String get contactTransporter => 'Contact Transporter';

  // Common
  String get loading => 'Loading...';
  String get error => 'Error';
  String get success => 'Success';
  String get retry => 'Retry';
  String get continue_ => 'Continue';
  String get back => 'Back';
  String get done => 'Done';
  String get ok => 'OK';
  String get yes => 'Yes';
  String get no => 'No';
}
