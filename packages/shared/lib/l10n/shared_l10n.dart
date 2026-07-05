import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'shared_l10n_de.dart';
import 'shared_l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SharedL10n
/// returned by `SharedL10n.of(context)`.
///
/// Applications need to include `SharedL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/shared_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SharedL10n.localizationsDelegates,
///   supportedLocales: SharedL10n.supportedLocales,
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
/// be consistent with the languages listed in the SharedL10n.supportedLocales
/// property.
abstract class SharedL10n {
  SharedL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SharedL10n of(BuildContext context) {
    return Localizations.of<SharedL10n>(context, SharedL10n)!;
  }

  static const LocalizationsDelegate<SharedL10n> delegate =
      _SharedL10nDelegate();

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
    Locale('de'),
    Locale('en'),
  ];

  /// Separator used when joining AND-combined constraint descriptions.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get constraintAnd;

  /// Separator used when joining OR-combined constraint descriptions.
  ///
  /// In en, this message translates to:
  /// **' or '**
  String get constraintOr;

  /// Prefix for NOT-inverted constraint descriptions.
  ///
  /// In en, this message translates to:
  /// **'Not: {desc}'**
  String constraintNotPrefix(String desc);

  /// PlayCountConstraint with maxCount == 1, e.g. 'Once per day'.
  ///
  /// In en, this message translates to:
  /// **'Once {window}'**
  String constraintPlayCountOnce(String window);

  /// PlayCountConstraint with maxCount > 1.
  ///
  /// In en, this message translates to:
  /// **'At most {count}× {window}'**
  String constraintPlayCountTimes(int count, String window);

  /// PlayDurationConstraint description.
  ///
  /// In en, this message translates to:
  /// **'Max. {minutes} min {window}'**
  String constraintPlayDuration(int minutes, String window);

  /// FolderItemCountConstraint description.
  ///
  /// In en, this message translates to:
  /// **'Max. {count} different entries {window}'**
  String constraintFolderItemCount(int count, String window);

  /// TimeOfDayConstraint description, e.g. 'Only 08:00–20:00'.
  ///
  /// In en, this message translates to:
  /// **'Only {from}–{to}'**
  String constraintTimeOfDayOnly(String from, String to);

  /// Shorthand DayOfWeek when all five weekdays are allowed.
  ///
  /// In en, this message translates to:
  /// **'Only Mon–Fri'**
  String get constraintDayOfWeekWeekdaysOnly;

  /// Shorthand DayOfWeek when only Sat+Sun are allowed.
  ///
  /// In en, this message translates to:
  /// **'Only on the weekend'**
  String get constraintDayOfWeekWeekendOnly;

  /// DayOfWeek with arbitrary list, e.g. 'Only Mon, Wed, Fri'.
  ///
  /// In en, this message translates to:
  /// **'Only {days}'**
  String constraintDayOfWeekList(String days);

  /// No description provided for @dayAbbrMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayAbbrMon;

  /// No description provided for @dayAbbrTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayAbbrTue;

  /// No description provided for @dayAbbrWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayAbbrWed;

  /// No description provided for @dayAbbrThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayAbbrThu;

  /// No description provided for @dayAbbrFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayAbbrFri;

  /// No description provided for @dayAbbrSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get dayAbbrSat;

  /// No description provided for @dayAbbrSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get dayAbbrSun;

  /// DateRange with both endpoints.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String constraintDateRangeFromTo(String from, String to);

  /// No description provided for @constraintDateRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String constraintDateRangeFrom(String date);

  /// No description provided for @constraintDateRangeTo.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String constraintDateRangeTo(String date);

  /// No description provided for @constraintUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown restriction'**
  String get constraintUnknown;

  /// No description provided for @windowPerDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get windowPerDay;

  /// No description provided for @windowPerWeek.
  ///
  /// In en, this message translates to:
  /// **'per week'**
  String get windowPerWeek;

  /// No description provided for @windowPerMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get windowPerMonth;

  /// No description provided for @windowSinceDate.
  ///
  /// In en, this message translates to:
  /// **'since {date}'**
  String windowSinceDate(String date);

  /// No description provided for @windowRollingHours.
  ///
  /// In en, this message translates to:
  /// **'every {hours} hours'**
  String windowRollingHours(int hours);

  /// No description provided for @reasonNoAccess.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get reasonNoAccess;

  /// No description provided for @reasonLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get reasonLocked;

  /// No description provided for @reasonMaxPlaysReached.
  ///
  /// In en, this message translates to:
  /// **'Reached max {count}× {window}'**
  String reasonMaxPlaysReached(int count, String window);

  /// No description provided for @reasonOnePlayLeft.
  ///
  /// In en, this message translates to:
  /// **'1 play left'**
  String get reasonOnePlayLeft;

  /// No description provided for @reasonTimeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Time limit reached (max {minutes} min {window})'**
  String reasonTimeLimitReached(int minutes, String window);

  /// No description provided for @reasonAlmostAtTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Almost at time limit'**
  String get reasonAlmostAtTimeLimit;

  /// No description provided for @reasonMaxItemsStarted.
  ///
  /// In en, this message translates to:
  /// **'Max {count} entries {window} started'**
  String reasonMaxItemsStarted(int count, String window);

  /// No description provided for @reasonOneItemLeft.
  ///
  /// In en, this message translates to:
  /// **'1 entry left'**
  String get reasonOneItemLeft;

  /// No description provided for @reasonOnlyAvailableHours.
  ///
  /// In en, this message translates to:
  /// **'Only available {from}–{to}'**
  String reasonOnlyAvailableHours(String from, String to);

  /// No description provided for @reasonNotAvailableToday.
  ///
  /// In en, this message translates to:
  /// **'Not available today'**
  String get reasonNotAvailableToday;

  /// No description provided for @reasonAvailableFrom.
  ///
  /// In en, this message translates to:
  /// **'Available from {date}'**
  String reasonAvailableFrom(String date);

  /// No description provided for @reasonNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get reasonNoLongerAvailable;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get commonHidden;

  /// Title of the password prompt that gates admin actions.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get adminAccessRequired;

  /// Text field label in the admin password prompt.
  ///
  /// In en, this message translates to:
  /// **'Admin password'**
  String get adminPassword;

  /// No description provided for @adminPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get adminPasswordIncorrect;

  /// No description provided for @adminPasswordIncorrectCurrent.
  ///
  /// In en, this message translates to:
  /// **'Incorrect current password'**
  String get adminPasswordIncorrectCurrent;

  /// No description provided for @adminPasswordVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get adminPasswordVerify;

  /// No description provided for @adminPasswordChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change admin password'**
  String get adminPasswordChangeTitle;

  /// No description provided for @adminPasswordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get adminPasswordCurrent;

  /// No description provided for @adminPasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get adminPasswordNew;

  /// No description provided for @adminPasswordConfirmNew.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get adminPasswordConfirmNew;

  /// No description provided for @adminPasswordPleaseEnterNew.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get adminPasswordPleaseEnterNew;

  /// No description provided for @adminPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 4 characters'**
  String get adminPasswordTooShort;

  /// No description provided for @adminPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get adminPasswordsDoNotMatch;

  /// No description provided for @adminPasswordChange.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get adminPasswordChange;

  /// No description provided for @adminPasswordChangedSnack.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get adminPasswordChangedSnack;

  /// No description provided for @adminPasswordSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set admin password'**
  String get adminPasswordSetTitle;

  /// No description provided for @adminPasswordSetExplanation.
  ///
  /// In en, this message translates to:
  /// **'Please set an admin password for first-time setup.'**
  String get adminPasswordSetExplanation;

  /// No description provided for @adminPasswordPlain.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get adminPasswordPlain;

  /// No description provided for @adminPasswordPleaseEnter.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get adminPasswordPleaseEnter;

  /// No description provided for @adminPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get adminPasswordConfirm;

  /// No description provided for @adminPasswordSet.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get adminPasswordSet;

  /// No description provided for @adminSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin settings'**
  String get adminSettingsTitle;

  /// No description provided for @adminAudioOutputDevices.
  ///
  /// In en, this message translates to:
  /// **'Audio output devices'**
  String get adminAudioOutputDevices;

  /// No description provided for @adminAudioOutputDevicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set volume limits per output device'**
  String get adminAudioOutputDevicesSubtitle;

  /// No description provided for @adminGridColumnsPortrait.
  ///
  /// In en, this message translates to:
  /// **'Grid columns (portrait): {count}'**
  String adminGridColumnsPortrait(int count);

  /// No description provided for @adminGridColumnsLandscape.
  ///
  /// In en, this message translates to:
  /// **'Grid columns (landscape): {count}'**
  String adminGridColumnsLandscape(int count);

  /// Section header above the min-play / grace-period sliders on the admin settings page.
  ///
  /// In en, this message translates to:
  /// **'Hearing rules'**
  String get adminHearingRulesSection;

  /// No description provided for @adminMinPlayDurationDescription.
  ///
  /// In en, this message translates to:
  /// **'Minimum duration before a play session is counted and an audiobook position is saved. Tracks shorter than this duration always count.'**
  String get adminMinPlayDurationDescription;

  /// No description provided for @adminMinPlayDurationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Minimum duration: disabled'**
  String get adminMinPlayDurationDisabled;

  /// No description provided for @adminMinPlayDuration.
  ///
  /// In en, this message translates to:
  /// **'Minimum duration: {seconds} s'**
  String adminMinPlayDuration(int seconds);

  /// No description provided for @adminMinPlaySliderLabelOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get adminMinPlaySliderLabelOff;

  /// No description provided for @adminMinPlaySliderLabel.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String adminMinPlaySliderLabel(int seconds);

  /// No description provided for @adminGracePeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'When listening time runs out and the track has less than this much left, the child may finish listening.'**
  String get adminGracePeriodDescription;

  /// No description provided for @adminGracePeriod.
  ///
  /// In en, this message translates to:
  /// **'Grace period: {minutes} min'**
  String adminGracePeriod(int minutes);

  /// No description provided for @adminGraceSliderLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String adminGraceSliderLabel(int minutes);

  /// No description provided for @adminVersionLoading.
  ///
  /// In en, this message translates to:
  /// **'Version …'**
  String get adminVersionLoading;

  /// No description provided for @adminVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (Build {build})'**
  String adminVersion(String version, String build);

  /// No description provided for @kidNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Who\'s using this device?'**
  String get kidNameTitle;

  /// No description provided for @kidNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get kidNameLabel;

  /// No description provided for @kidNamePleaseEnter.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get kidNamePleaseEnter;

  /// No description provided for @kidNameDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get kidNameDone;

  /// No description provided for @playerAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Media Player for Kids'**
  String get playerAppTitle;

  /// No description provided for @playerMenuShowAdmin.
  ///
  /// In en, this message translates to:
  /// **'Show admin options'**
  String get playerMenuShowAdmin;

  /// No description provided for @directoryHearingRulesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Hearing rules disabled'**
  String get directoryHearingRulesDisabled;

  /// No description provided for @directoryDateLocksDisabled.
  ///
  /// In en, this message translates to:
  /// **'Date locks disabled'**
  String get directoryDateLocksDisabled;

  /// No description provided for @directoryNoMediaItems.
  ///
  /// In en, this message translates to:
  /// **'No media items found'**
  String get directoryNoMediaItems;

  /// No description provided for @directoryItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available right now'**
  String get directoryItemUnavailable;

  /// No description provided for @playerListeningTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Listening time is up'**
  String get playerListeningTimeUp;

  /// No description provided for @audioDeviceNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No audio devices found.'**
  String get audioDeviceNoneFound;

  /// No description provided for @audioDeviceEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency overrides'**
  String get audioDeviceEmergencyTitle;

  /// No description provided for @audioDeviceEmergencyHelper.
  ///
  /// In en, this message translates to:
  /// **'Only enable in an emergency. Please disable again after travel.'**
  String get audioDeviceEmergencyHelper;

  /// No description provided for @audioDeviceIgnoreConstraints.
  ///
  /// In en, this message translates to:
  /// **'Ignore hearing rules'**
  String get audioDeviceIgnoreConstraints;

  /// No description provided for @audioDeviceIgnoreConstraintsSub.
  ///
  /// In en, this message translates to:
  /// **'All hearing restrictions are disabled'**
  String get audioDeviceIgnoreConstraintsSub;

  /// No description provided for @audioDeviceIgnoreDates.
  ///
  /// In en, this message translates to:
  /// **'Ignore date locks'**
  String get audioDeviceIgnoreDates;

  /// No description provided for @audioDeviceIgnoreDatesSub.
  ///
  /// In en, this message translates to:
  /// **'Content with date windows (from/to) is visible'**
  String get audioDeviceIgnoreDatesSub;

  /// No description provided for @audioDeviceBluetoothBannerText.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth access to list all paired devices, even when they are turned off.'**
  String get audioDeviceBluetoothBannerText;

  /// No description provided for @audioDeviceBluetoothBannerAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get audioDeviceBluetoothBannerAllow;

  /// No description provided for @audioDeviceStatusActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get audioDeviceStatusActive;

  /// No description provided for @audioDeviceStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'available now'**
  String get audioDeviceStatusAvailable;

  /// No description provided for @audioDeviceStatusPairedUnavailable.
  ///
  /// In en, this message translates to:
  /// **'paired, currently unavailable'**
  String get audioDeviceStatusPairedUnavailable;

  /// No description provided for @audioDeviceStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'currently unavailable'**
  String get audioDeviceStatusUnavailable;

  /// No description provided for @audioDeviceVolumeLimit.
  ///
  /// In en, this message translates to:
  /// **'Volume limit'**
  String get audioDeviceVolumeLimit;

  /// No description provided for @audioDeviceNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get audioDeviceNoLimit;

  /// No description provided for @audioDeviceLimitedTo.
  ///
  /// In en, this message translates to:
  /// **'Audio limited to {db} dB below maximum'**
  String audioDeviceLimitedTo(String db);

  /// No description provided for @audioDeviceUnavailablePairedHelper.
  ///
  /// In en, this message translates to:
  /// **'This output is known to Android but is not currently routeable. Volume limit will apply when it becomes available.'**
  String get audioDeviceUnavailablePairedHelper;

  /// No description provided for @audioDeviceUnavailableTypeHelper.
  ///
  /// In en, this message translates to:
  /// **'This output type is not currently routeable, but its settings are still saved.'**
  String get audioDeviceUnavailableTypeHelper;

  /// No description provided for @audioDevicePairedBluetoothTitle.
  ///
  /// In en, this message translates to:
  /// **'Paired Bluetooth devices'**
  String get audioDevicePairedBluetoothTitle;

  /// No description provided for @audioDevicePairedBluetoothHelper.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth access to show headphones and speakers that are paired with Android, even when they are currently off.'**
  String get audioDevicePairedBluetoothHelper;

  /// No description provided for @audioDevicePairedBluetoothAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth Access'**
  String get audioDevicePairedBluetoothAllow;

  /// No description provided for @audioDeviceBluetoothTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth device'**
  String get audioDeviceBluetoothTitle;

  /// No description provided for @audioDeviceBluetoothNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No specific paired Bluetooth device is known yet. Once Android reports a paired headset, it will get its own entry here.'**
  String get audioDeviceBluetoothNoneYet;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get commonDuplicate;

  /// No description provided for @commonLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get commonLogin;

  /// No description provided for @commonImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commonImport;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonItem.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get commonItem;

  /// No description provided for @commonItemCapitalized.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get commonItemCapitalized;

  /// No description provided for @commonFolder.
  ///
  /// In en, this message translates to:
  /// **'folder'**
  String get commonFolder;

  /// No description provided for @commonFolderCapitalized.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get commonFolderCapitalized;

  /// No description provided for @commonMediaItem.
  ///
  /// In en, this message translates to:
  /// **'Media item'**
  String get commonMediaItem;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @commonFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get commonFrom;

  /// No description provided for @commonUntil.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get commonUntil;

  /// No description provided for @commonHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get commonHours;

  /// No description provided for @companionAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Media Player for Kids Companion'**
  String get companionAppTitle;

  /// No description provided for @companionGlobalConstraintsMenu.
  ///
  /// In en, this message translates to:
  /// **'Global restrictions'**
  String get companionGlobalConstraintsMenu;

  /// No description provided for @companionLogoutMenu.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get companionLogoutMenu;

  /// No description provided for @companionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get companionDeleteTitle;

  /// No description provided for @companionDeleteOneConfirm.
  ///
  /// In en, this message translates to:
  /// **'Really delete {kind} \"{name}\"?'**
  String companionDeleteOneConfirm(String kind, String name);

  /// No description provided for @companionDeleteManyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Really delete {kind} \"{name}\" and its {count} child(ren)?'**
  String companionDeleteManyConfirm(String kind, String name, int count);

  /// No description provided for @companionCreateNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get companionCreateNewTitle;

  /// No description provided for @globalConstraintsHeading.
  ///
  /// In en, this message translates to:
  /// **'Global hearing rules'**
  String get globalConstraintsHeading;

  /// No description provided for @globalConstraintsDescription.
  ///
  /// In en, this message translates to:
  /// **'Limits total daily/weekly listening time across all content. Evaluated in combination with per-item restrictions — the stricter rule wins.'**
  String get globalConstraintsDescription;

  /// No description provided for @globalConstraintsRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove restriction'**
  String get globalConstraintsRemoveTooltip;

  /// No description provided for @globalConstraintsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create global restriction'**
  String get globalConstraintsCreate;

  /// No description provided for @editorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit hearing rules'**
  String get editorTitle;

  /// No description provided for @editorReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get editorReset;

  /// No description provided for @editorApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get editorApply;

  /// No description provided for @editorInheritedBanner.
  ///
  /// In en, this message translates to:
  /// **'This item inherits hearing rules from \"{from}\". You can take them over as its own rules and adjust them.'**
  String editorInheritedBanner(String from);

  /// No description provided for @editorAdoptRules.
  ///
  /// In en, this message translates to:
  /// **'Adopt rules'**
  String get editorAdoptRules;

  /// No description provided for @editorPaneTitle.
  ///
  /// In en, this message translates to:
  /// **'Rule editor'**
  String get editorPaneTitle;

  /// No description provided for @editorCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get editorCollapseAll;

  /// No description provided for @editorExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get editorExpandAll;

  /// No description provided for @editorNoConstraint.
  ///
  /// In en, this message translates to:
  /// **'No restriction — freely playable.'**
  String get editorNoConstraint;

  /// No description provided for @editorCombineLabel.
  ///
  /// In en, this message translates to:
  /// **'Combine:'**
  String get editorCombineLabel;

  /// No description provided for @editorCombineAnd.
  ///
  /// In en, this message translates to:
  /// **'AND (all apply)'**
  String get editorCombineAnd;

  /// No description provided for @editorCombineOr.
  ///
  /// In en, this message translates to:
  /// **'OR (any applies)'**
  String get editorCombineOr;

  /// No description provided for @editorPresetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Building blocks'**
  String get editorPresetsTitle;

  /// No description provided for @editorPresetsHint.
  ///
  /// In en, this message translates to:
  /// **'Drag & drop into the editor'**
  String get editorPresetsHint;

  /// No description provided for @editorTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get editorTypeLabel;

  /// No description provided for @editorAddCondition.
  ///
  /// In en, this message translates to:
  /// **'Add condition'**
  String get editorAddCondition;

  /// No description provided for @editorAddConditionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add a condition or drag here'**
  String get editorAddConditionTooltip;

  /// No description provided for @editorTimeWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get editorTimeWindowLabel;

  /// No description provided for @editorWindowPerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get editorWindowPerDay;

  /// No description provided for @editorWindowPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get editorWindowPerWeek;

  /// No description provided for @editorWindowPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get editorWindowPerMonth;

  /// No description provided for @editorWindowSinceDate.
  ///
  /// In en, this message translates to:
  /// **'Since date'**
  String get editorWindowSinceDate;

  /// No description provided for @editorWindowRollingHours.
  ///
  /// In en, this message translates to:
  /// **'Last N hours'**
  String get editorWindowRollingHours;

  /// No description provided for @editorLeafMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get editorLeafMaximum;

  /// No description provided for @editorLeafMaxMinutes.
  ///
  /// In en, this message translates to:
  /// **'Max. minutes'**
  String get editorLeafMaxMinutes;

  /// No description provided for @editorLeafMaxItems.
  ///
  /// In en, this message translates to:
  /// **'Max. entries'**
  String get editorLeafMaxItems;

  /// No description provided for @editorTypeAnd.
  ///
  /// In en, this message translates to:
  /// **'AND (all must apply)'**
  String get editorTypeAnd;

  /// No description provided for @editorTypeOr.
  ///
  /// In en, this message translates to:
  /// **'OR (at least one)'**
  String get editorTypeOr;

  /// No description provided for @editorTypeNot.
  ///
  /// In en, this message translates to:
  /// **'NOT (inversion)'**
  String get editorTypeNot;

  /// No description provided for @editorTypePlayCount.
  ///
  /// In en, this message translates to:
  /// **'Play count'**
  String get editorTypePlayCount;

  /// No description provided for @editorTypePlayDuration.
  ///
  /// In en, this message translates to:
  /// **'Listening time'**
  String get editorTypePlayDuration;

  /// No description provided for @editorTypeFolderItemCount.
  ///
  /// In en, this message translates to:
  /// **'Different folder entries'**
  String get editorTypeFolderItemCount;

  /// No description provided for @editorTypeTimeOfDay.
  ///
  /// In en, this message translates to:
  /// **'Time of day'**
  String get editorTypeTimeOfDay;

  /// No description provided for @editorTypeDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of week'**
  String get editorTypeDayOfWeek;

  /// No description provided for @editorTypeDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get editorTypeDateRange;

  /// No description provided for @editorPickDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get editorPickDateTooltip;

  /// No description provided for @presetThreeTimesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Three times a day'**
  String get presetThreeTimesPerDay;

  /// No description provided for @presetOnceAWeek.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get presetOnceAWeek;

  /// No description provided for @presetDaytimeOnly.
  ///
  /// In en, this message translates to:
  /// **'Daytime only (8 am – 8 pm)'**
  String get presetDaytimeOnly;

  /// No description provided for @presetWeekdaysOnly.
  ///
  /// In en, this message translates to:
  /// **'Weekdays only'**
  String get presetWeekdaysOnly;

  /// No description provided for @presetWeekdaysAndDaytime.
  ///
  /// In en, this message translates to:
  /// **'Weekdays & daytime'**
  String get presetWeekdaysAndDaytime;

  /// No description provided for @presetWeekendOnly.
  ///
  /// In en, this message translates to:
  /// **'Weekends only'**
  String get presetWeekendOnly;

  /// No description provided for @presetMax30MinPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Max. 30 min per week'**
  String get presetMax30MinPerWeek;

  /// No description provided for @preset2xMonFri3xSatSun.
  ///
  /// In en, this message translates to:
  /// **'2× Mon–Fri, 3× Sat+Sun'**
  String get preset2xMonFri3xSatSun;

  /// No description provided for @preset2hMonFri3hSatSun.
  ///
  /// In en, this message translates to:
  /// **'2h Mon–Fri, 3h Sat+Sun'**
  String get preset2hMonFri3hSatSun;

  /// No description provided for @presetMax2DifferentItems.
  ///
  /// In en, this message translates to:
  /// **'Max. 2 different items'**
  String get presetMax2DifferentItems;

  /// No description provided for @headerVisibleDateRange.
  ///
  /// In en, this message translates to:
  /// **'Visible date range:'**
  String get headerVisibleDateRange;

  /// No description provided for @headerFromDate.
  ///
  /// In en, this message translates to:
  /// **'From date:'**
  String get headerFromDate;

  /// No description provided for @headerToDate.
  ///
  /// In en, this message translates to:
  /// **'To date:'**
  String get headerToDate;

  /// No description provided for @headerHearingRules.
  ///
  /// In en, this message translates to:
  /// **'Hearing rules'**
  String get headerHearingRules;

  /// No description provided for @headerInheritedFrom.
  ///
  /// In en, this message translates to:
  /// **'inherited from \"{name}\"'**
  String headerInheritedFrom(String name);

  /// No description provided for @headerRemoveRulesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove hearing rules'**
  String get headerRemoveRulesTooltip;

  /// No description provided for @headerHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get headerHiddenLabel;

  /// No description provided for @headerRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get headerRemoveImage;

  /// No description provided for @headerPasteImage.
  ///
  /// In en, this message translates to:
  /// **'Paste image from clipboard'**
  String get headerPasteImage;

  /// No description provided for @headerClipboardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Clipboard not available'**
  String get headerClipboardUnavailable;

  /// No description provided for @headerClipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data in clipboard'**
  String get headerClipboardEmpty;

  /// No description provided for @headerClipboardUnsupported.
  ///
  /// In en, this message translates to:
  /// **'No supported image format in clipboard'**
  String get headerClipboardUnsupported;

  /// No description provided for @headerClipboardError.
  ///
  /// In en, this message translates to:
  /// **'Error reading clipboard: {error}'**
  String headerClipboardError(String error);

  /// No description provided for @headerChildrenCount.
  ///
  /// In en, this message translates to:
  /// **'{count} children'**
  String headerChildrenCount(int count);

  /// No description provided for @headerNotSetPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'*Not set*'**
  String get headerNotSetPlaceholder;

  /// No description provided for @headerNoRules.
  ///
  /// In en, this message translates to:
  /// **'No restrictions'**
  String get headerNoRules;

  /// No description provided for @folderDetailAudioBook.
  ///
  /// In en, this message translates to:
  /// **'Audio book'**
  String get folderDetailAudioBook;

  /// No description provided for @folderDetailIsNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get folderDetailIsNew;

  /// No description provided for @folderDetailHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get folderDetailHidden;

  /// No description provided for @folderDetailShowChildNumbering.
  ///
  /// In en, this message translates to:
  /// **'Show child numbering in player directory view'**
  String get folderDetailShowChildNumbering;

  /// No description provided for @folderDetailFilterAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get folderDetailFilterAll;

  /// No description provided for @folderDetailFilterOnlyVisible.
  ///
  /// In en, this message translates to:
  /// **'Only visible'**
  String get folderDetailFilterOnlyVisible;

  /// No description provided for @folderDetailFilterOnlyHidden.
  ///
  /// In en, this message translates to:
  /// **'Only hidden'**
  String get folderDetailFilterOnlyHidden;

  /// No description provided for @folderDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get folderDialogCreateTitle;

  /// No description provided for @folderDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit folder'**
  String get folderDialogEditTitle;

  /// No description provided for @folderDialogNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderDialogNameLabel;

  /// No description provided for @itemDialogNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemDialogNameLabel;

  /// No description provided for @itemDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create media item'**
  String get itemDialogCreateTitle;

  /// No description provided for @itemDialogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit media item'**
  String get itemDialogEditTitle;

  /// No description provided for @itemDetailDeleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete media file?'**
  String get itemDetailDeleteFileTitle;

  /// No description provided for @itemDetailDeleteFileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this item?'**
  String itemDetailDeleteFileConfirm(String name);

  /// No description provided for @itemDetailNoFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No audio files found in folder'**
  String get itemDetailNoFilesFound;

  /// No description provided for @itemDetailImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import audio files?'**
  String get itemDetailImportTitle;

  /// No description provided for @itemDetailImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import all {count} audio files from \"{folder}\"?'**
  String itemDetailImportConfirm(int count, String folder);

  /// No description provided for @itemDetailFoldersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} folders'**
  String itemDetailFoldersCount(int count);

  /// No description provided for @itemDetailAddedSnack.
  ///
  /// In en, this message translates to:
  /// **'Successfully added {count} file(s)'**
  String itemDetailAddedSnack(int count);

  /// No description provided for @itemDetailNoFilesAdded.
  ///
  /// In en, this message translates to:
  /// **'No files were added'**
  String get itemDetailNoFilesAdded;

  /// No description provided for @itemDetailErrorPlaying.
  ///
  /// In en, this message translates to:
  /// **'Error playing audio: {error}'**
  String itemDetailErrorPlaying(String error);

  /// No description provided for @itemDetailErrorTrackNotFound.
  ///
  /// In en, this message translates to:
  /// **'Error: track document not found'**
  String get itemDetailErrorTrackNotFound;

  /// No description provided for @itemDetailFileRemoved.
  ///
  /// In en, this message translates to:
  /// **'Media file removed'**
  String get itemDetailFileRemoved;

  /// No description provided for @itemDetailErrorRemovingFile.
  ///
  /// In en, this message translates to:
  /// **'Error removing file: {error}'**
  String itemDetailErrorRemovingFile(String error);

  /// No description provided for @itemDetailShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get itemDetailShuffle;

  /// No description provided for @itemDetailRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get itemDetailRepeat;

  /// No description provided for @itemDetailNewFlag.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get itemDetailNewFlag;

  /// No description provided for @itemDetailUseTrackCovers.
  ///
  /// In en, this message translates to:
  /// **'Use track covers in player rather than item cover'**
  String get itemDetailUseTrackCovers;

  /// No description provided for @folderDetailNameForNewItem.
  ///
  /// In en, this message translates to:
  /// **'Name for new media item'**
  String get folderDetailNameForNewItem;

  /// No description provided for @folderDetailEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get folderDetailEditName;

  /// No description provided for @folderDetailDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String folderDetailDeletedSnack(String name);

  /// No description provided for @folderDetailDeleteErrorSnack.
  ///
  /// In en, this message translates to:
  /// **'Error deleting: {error}'**
  String folderDetailDeleteErrorSnack(String error);

  /// No description provided for @folderDetailNoAudioFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No audio files found'**
  String get folderDetailNoAudioFilesFound;

  /// No description provided for @folderDetailErrorCreatingItem.
  ///
  /// In en, this message translates to:
  /// **'Error creating media item'**
  String get folderDetailErrorCreatingItem;

  /// No description provided for @folderDetailDeleteWithContents.
  ///
  /// In en, this message translates to:
  /// **'This will also delete all its contents.'**
  String get folderDetailDeleteWithContents;

  /// No description provided for @folderDetailNoValidAudioImported.
  ///
  /// In en, this message translates to:
  /// **'No valid audio files were imported'**
  String get folderDetailNoValidAudioImported;

  /// No description provided for @folderDetailImportedItems.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} item(s)'**
  String folderDetailImportedItems(int count);

  /// No description provided for @folderDetailImportedFolders.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} folder(s) as media items'**
  String folderDetailImportedFolders(int count);

  /// No description provided for @importDialogTitleFiles.
  ///
  /// In en, this message translates to:
  /// **'Import {count} audio files'**
  String importDialogTitleFiles(int count);

  /// No description provided for @importDialogSingleItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Import all into a single media item'**
  String get importDialogSingleItemTitle;

  /// No description provided for @importDialogSingleItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All files go into one item'**
  String get importDialogSingleItemSubtitle;

  /// No description provided for @importDialogPerFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Each file as a separate media item'**
  String get importDialogPerFileTitle;

  /// No description provided for @importDialogPerFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One item per file'**
  String get importDialogPerFileSubtitle;

  /// No description provided for @importDialogSingleFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Import audio file'**
  String get importDialogSingleFileTitle;

  /// No description provided for @importDialogSingleFileAsItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Import as a media item'**
  String get importDialogSingleFileAsItemTitle;

  /// No description provided for @importDialogFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Import {folders} folders ({files} audio files)'**
  String importDialogFoldersTitle(int folders, int files);

  /// No description provided for @importDialogPerFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Each folder as a separate media item'**
  String get importDialogPerFolderTitle;

  /// No description provided for @importDialogPerFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One item per folder, containing all its files'**
  String get importDialogPerFolderSubtitle;

  /// No description provided for @importDialogAllOneItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All files go into one item'**
  String get importDialogAllOneItemSubtitle;

  /// No description provided for @importDialogEachFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Each file as a separate media item'**
  String get importDialogEachFileTitle;

  /// No description provided for @importDialogEachFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One item per audio file'**
  String get importDialogEachFileSubtitle;

  /// No description provided for @audioImportCompressTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress audio files?'**
  String get audioImportCompressTitle;

  /// No description provided for @audioImportKeepOriginals.
  ///
  /// In en, this message translates to:
  /// **'No, keep originals'**
  String get audioImportKeepOriginals;

  /// No description provided for @audioImportCompress.
  ///
  /// In en, this message translates to:
  /// **'Yes, compress'**
  String get audioImportCompress;

  /// No description provided for @audioImportInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing files'**
  String get audioImportInProgressTitle;

  /// No description provided for @audioImportProgressLine.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} file(s)'**
  String audioImportProgressLine(int count);

  /// No description provided for @audioImportUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type: {filename}'**
  String audioImportUnsupported(String filename);

  /// No description provided for @audioImportErrorAdding.
  ///
  /// In en, this message translates to:
  /// **'Error adding file: {error}'**
  String audioImportErrorAdding(String error);

  /// No description provided for @loginEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get loginEditTooltip;

  /// No description provided for @loginDuplicateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get loginDuplicateTooltip;

  /// No description provided for @loginDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get loginDeleteTooltip;

  /// No description provided for @loginLoginTooltip.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLoginTooltip;

  /// No description provided for @loginServerUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get loginServerUrlLabel;

  /// No description provided for @loginServerUrlHint.
  ///
  /// In en, this message translates to:
  /// **'example.com'**
  String get loginServerUrlHint;

  /// No description provided for @loginUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsernameLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginEditProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get loginEditProfileTitle;

  /// No description provided for @loginNewProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get loginNewProfileTitle;

  /// No description provided for @loginPleaseEnterServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a server URL'**
  String get loginPleaseEnterServerUrl;

  /// No description provided for @loginPleaseEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get loginPleaseEnterUsername;

  /// No description provided for @loginPleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get loginPleaseEnterPassword;

  /// No description provided for @audioImportTotalProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String audioImportTotalProgress(int percent);

  /// No description provided for @audioImportFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String audioImportFileCount(int count);

  /// No description provided for @audioImportCompressBody.
  ///
  /// In en, this message translates to:
  /// **'{fileText} not highly compressed. Compress to AAC (160 kbps stereo / 80 kbps mono)? Quality will be indistinguishable from CD. Original files will not be modified.'**
  String audioImportCompressBody(String fileText);

  /// No description provided for @audioImportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing import…'**
  String get audioImportPreparing;

  /// No description provided for @audioImportProcessedLine.
  ///
  /// In en, this message translates to:
  /// **'Processed {done}/{total} files'**
  String audioImportProcessedLine(int done, int total);

  /// No description provided for @audioImportImportingFile.
  ///
  /// In en, this message translates to:
  /// **'Importing file\n{filename}'**
  String audioImportImportingFile(String filename);

  /// No description provided for @audioImportSkippedFile.
  ///
  /// In en, this message translates to:
  /// **'Skipped unsupported file\n{filename}'**
  String audioImportSkippedFile(String filename);

  /// No description provided for @audioImportCompressingFile.
  ///
  /// In en, this message translates to:
  /// **'Compressing file\n{filename}'**
  String audioImportCompressingFile(String filename);

  /// No description provided for @audioImportFinishedFile.
  ///
  /// In en, this message translates to:
  /// **'Finished file\n{filename}'**
  String audioImportFinishedFile(String filename);

  /// No description provided for @hearingStatsAllKids.
  ///
  /// In en, this message translates to:
  /// **'All Kids'**
  String get hearingStatsAllKids;

  /// No description provided for @hearingStatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Stats:'**
  String get hearingStatsLabel;

  /// No description provided for @commonMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get commonMove;

  /// No description provided for @moveDialogTitleOne.
  ///
  /// In en, this message translates to:
  /// **'Move \"{name}\" to:'**
  String moveDialogTitleOne(String name);

  /// No description provided for @moveDialogTitleMany.
  ///
  /// In en, this message translates to:
  /// **'Move {count} entries to:'**
  String moveDialogTitleMany(int count);

  /// No description provided for @moveDialogRootLevel.
  ///
  /// In en, this message translates to:
  /// **'Top level'**
  String get moveDialogRootLevel;

  /// No description provided for @moveDoneSnack.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Moved 1 entry} other{Moved {count} entries}}'**
  String moveDoneSnack(int count);

  /// No description provided for @moveToNewSubfolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to new subfolder'**
  String get moveToNewSubfolderTitle;

  /// No description provided for @moveToNewSubfolderLabel.
  ///
  /// In en, this message translates to:
  /// **'New subfolder name'**
  String get moveToNewSubfolderLabel;

  /// No description provided for @selectionSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionSelectedCount(int count);

  /// No description provided for @selectionClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get selectionClearTooltip;

  /// No description provided for @selectionMoveToNewSubfolder.
  ///
  /// In en, this message translates to:
  /// **'To new subfolder'**
  String get selectionMoveToNewSubfolder;
}

class _SharedL10nDelegate extends LocalizationsDelegate<SharedL10n> {
  const _SharedL10nDelegate();

  @override
  Future<SharedL10n> load(Locale locale) {
    return SynchronousFuture<SharedL10n>(lookupSharedL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SharedL10nDelegate old) => false;
}

SharedL10n lookupSharedL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return SharedL10nDe();
    case 'en':
      return SharedL10nEn();
  }

  throw FlutterError(
    'SharedL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
