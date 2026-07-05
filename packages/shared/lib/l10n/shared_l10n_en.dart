// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'shared_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SharedL10nEn extends SharedL10n {
  SharedL10nEn([String locale = 'en']) : super(locale);

  @override
  String get constraintAnd => ' and ';

  @override
  String get constraintOr => ' or ';

  @override
  String constraintNotPrefix(String desc) {
    return 'Not: $desc';
  }

  @override
  String constraintPlayCountOnce(String window) {
    return 'Once $window';
  }

  @override
  String constraintPlayCountTimes(int count, String window) {
    return 'At most $count× $window';
  }

  @override
  String constraintPlayDuration(int minutes, String window) {
    return 'Max. $minutes min $window';
  }

  @override
  String constraintFolderItemCount(int count, String window) {
    return 'Max. $count different entries $window';
  }

  @override
  String constraintTimeOfDayOnly(String from, String to) {
    return 'Only $from–$to';
  }

  @override
  String get constraintDayOfWeekWeekdaysOnly => 'Only Mon–Fri';

  @override
  String get constraintDayOfWeekWeekendOnly => 'Only on the weekend';

  @override
  String constraintDayOfWeekList(String days) {
    return 'Only $days';
  }

  @override
  String get dayAbbrMon => 'Mon';

  @override
  String get dayAbbrTue => 'Tue';

  @override
  String get dayAbbrWed => 'Wed';

  @override
  String get dayAbbrThu => 'Thu';

  @override
  String get dayAbbrFri => 'Fri';

  @override
  String get dayAbbrSat => 'Sat';

  @override
  String get dayAbbrSun => 'Sun';

  @override
  String constraintDateRangeFromTo(String from, String to) {
    return '$from – $to';
  }

  @override
  String constraintDateRangeFrom(String date) {
    return 'From $date';
  }

  @override
  String constraintDateRangeTo(String date) {
    return 'Until $date';
  }

  @override
  String get constraintUnknown => 'Unknown restriction';

  @override
  String get windowPerDay => 'per day';

  @override
  String get windowPerWeek => 'per week';

  @override
  String get windowPerMonth => 'per month';

  @override
  String windowSinceDate(String date) {
    return 'since $date';
  }

  @override
  String windowRollingHours(int hours) {
    return 'every $hours hours';
  }

  @override
  String get reasonNoAccess => 'No access';

  @override
  String get reasonLocked => 'Locked';

  @override
  String reasonMaxPlaysReached(int count, String window) {
    return 'Reached max $count× $window';
  }

  @override
  String get reasonOnePlayLeft => '1 play left';

  @override
  String reasonTimeLimitReached(int minutes, String window) {
    return 'Time limit reached (max $minutes min $window)';
  }

  @override
  String get reasonAlmostAtTimeLimit => 'Almost at time limit';

  @override
  String reasonMaxItemsStarted(int count, String window) {
    return 'Max $count entries $window started';
  }

  @override
  String get reasonOneItemLeft => '1 entry left';

  @override
  String reasonOnlyAvailableHours(String from, String to) {
    return 'Only available $from–$to';
  }

  @override
  String get reasonNotAvailableToday => 'Not available today';

  @override
  String reasonAvailableFrom(String date) {
    return 'Available from $date';
  }

  @override
  String get reasonNoLongerAvailable => 'No longer available';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonHidden => 'Hidden';

  @override
  String get adminAccessRequired => 'Admin access required';

  @override
  String get adminPassword => 'Admin password';

  @override
  String get adminPasswordIncorrect => 'Incorrect password';

  @override
  String get adminPasswordIncorrectCurrent => 'Incorrect current password';

  @override
  String get adminPasswordVerify => 'Verify';

  @override
  String get adminPasswordChangeTitle => 'Change admin password';

  @override
  String get adminPasswordCurrent => 'Current password';

  @override
  String get adminPasswordNew => 'New password';

  @override
  String get adminPasswordConfirmNew => 'Confirm new password';

  @override
  String get adminPasswordPleaseEnterNew => 'Please enter a new password';

  @override
  String get adminPasswordTooShort => 'Password must be at least 4 characters';

  @override
  String get adminPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get adminPasswordChange => 'Change password';

  @override
  String get adminPasswordChangedSnack => 'Password changed successfully';

  @override
  String get adminPasswordSetTitle => 'Set admin password';

  @override
  String get adminPasswordSetExplanation =>
      'Please set an admin password for first-time setup.';

  @override
  String get adminPasswordPlain => 'Password';

  @override
  String get adminPasswordPleaseEnter => 'Please enter a password';

  @override
  String get adminPasswordConfirm => 'Confirm password';

  @override
  String get adminPasswordSet => 'Set password';

  @override
  String get adminSettingsTitle => 'Admin settings';

  @override
  String get adminAudioOutputDevices => 'Audio output devices';

  @override
  String get adminAudioOutputDevicesSubtitle =>
      'Set volume limits per output device';

  @override
  String adminGridColumnsPortrait(int count) {
    return 'Grid columns (portrait): $count';
  }

  @override
  String adminGridColumnsLandscape(int count) {
    return 'Grid columns (landscape): $count';
  }

  @override
  String get adminHearingRulesSection => 'Hearing rules';

  @override
  String get adminMinPlayDurationDescription =>
      'Minimum duration before a play session is counted and an audiobook position is saved. Tracks shorter than this duration always count.';

  @override
  String get adminMinPlayDurationDisabled => 'Minimum duration: disabled';

  @override
  String adminMinPlayDuration(int seconds) {
    return 'Minimum duration: $seconds s';
  }

  @override
  String get adminMinPlaySliderLabelOff => 'off';

  @override
  String adminMinPlaySliderLabel(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminGracePeriodDescription =>
      'When listening time runs out and the track has less than this much left, the child may finish listening.';

  @override
  String adminGracePeriod(int minutes) {
    return 'Grace period: $minutes min';
  }

  @override
  String adminGraceSliderLabel(int minutes) {
    return '$minutes min';
  }

  @override
  String get adminVersionLoading => 'Version …';

  @override
  String adminVersion(String version, String build) {
    return 'Version $version (Build $build)';
  }

  @override
  String get kidNameTitle => 'Who\'s using this device?';

  @override
  String get kidNameLabel => 'Your name';

  @override
  String get kidNamePleaseEnter => 'Please enter your name';

  @override
  String get kidNameDone => 'Done';

  @override
  String get playerAppTitle => 'Media Player for Kids';

  @override
  String get playerMenuShowAdmin => 'Show admin options';

  @override
  String get directoryHearingRulesDisabled => 'Hearing rules disabled';

  @override
  String get directoryDateLocksDisabled => 'Date locks disabled';

  @override
  String get directoryNoMediaItems => 'No media items found';

  @override
  String get directoryItemUnavailable => 'Not available right now';

  @override
  String get playerListeningTimeUp => 'Listening time is up';

  @override
  String get audioDeviceNoneFound => 'No audio devices found.';

  @override
  String get audioDeviceEmergencyTitle => 'Emergency overrides';

  @override
  String get audioDeviceEmergencyHelper =>
      'Only enable in an emergency. Please disable again after travel.';

  @override
  String get audioDeviceIgnoreConstraints => 'Ignore hearing rules';

  @override
  String get audioDeviceIgnoreConstraintsSub =>
      'All hearing restrictions are disabled';

  @override
  String get audioDeviceIgnoreDates => 'Ignore date locks';

  @override
  String get audioDeviceIgnoreDatesSub =>
      'Content with date windows (from/to) is visible';

  @override
  String get audioDeviceBluetoothBannerText =>
      'Allow Bluetooth access to list all paired devices, even when they are turned off.';

  @override
  String get audioDeviceBluetoothBannerAllow => 'Allow';

  @override
  String get audioDeviceStatusActive => 'active';

  @override
  String get audioDeviceStatusAvailable => 'available now';

  @override
  String get audioDeviceStatusPairedUnavailable =>
      'paired, currently unavailable';

  @override
  String get audioDeviceStatusUnavailable => 'currently unavailable';

  @override
  String get audioDeviceVolumeLimit => 'Volume limit';

  @override
  String get audioDeviceNoLimit => 'No limit';

  @override
  String audioDeviceLimitedTo(String db) {
    return 'Audio limited to $db dB below maximum';
  }

  @override
  String get audioDeviceUnavailablePairedHelper =>
      'This output is known to Android but is not currently routeable. Volume limit will apply when it becomes available.';

  @override
  String get audioDeviceUnavailableTypeHelper =>
      'This output type is not currently routeable, but its settings are still saved.';

  @override
  String get audioDevicePairedBluetoothTitle => 'Paired Bluetooth devices';

  @override
  String get audioDevicePairedBluetoothHelper =>
      'Allow Bluetooth access to show headphones and speakers that are paired with Android, even when they are currently off.';

  @override
  String get audioDevicePairedBluetoothAllow => 'Allow Bluetooth Access';

  @override
  String get audioDeviceBluetoothTitle => 'Bluetooth device';

  @override
  String get audioDeviceBluetoothNoneYet =>
      'No specific paired Bluetooth device is known yet. Once Android reports a paired headset, it will get its own entry here.';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDuplicate => 'Duplicate';

  @override
  String get commonLogin => 'Login';

  @override
  String get commonImport => 'Import';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonItem => 'item';

  @override
  String get commonItemCapitalized => 'Item';

  @override
  String get commonFolder => 'folder';

  @override
  String get commonFolderCapitalized => 'Folder';

  @override
  String get commonMediaItem => 'Media item';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get commonFrom => 'From';

  @override
  String get commonUntil => 'Until';

  @override
  String get commonHours => 'Hours';

  @override
  String get companionAppTitle => 'Media Player for Kids Companion';

  @override
  String get companionGlobalConstraintsMenu => 'Global restrictions';

  @override
  String get companionLogoutMenu => 'Log out';

  @override
  String get companionDeleteTitle => 'Delete?';

  @override
  String companionDeleteOneConfirm(String kind, String name) {
    return 'Really delete $kind \"$name\"?';
  }

  @override
  String companionDeleteManyConfirm(String kind, String name, int count) {
    return 'Really delete $kind \"$name\" and its $count child(ren)?';
  }

  @override
  String get companionCreateNewTitle => 'Create new';

  @override
  String get globalConstraintsHeading => 'Global hearing rules';

  @override
  String get globalConstraintsDescription =>
      'Limits total daily/weekly listening time across all content. Evaluated in combination with per-item restrictions — the stricter rule wins.';

  @override
  String get globalConstraintsRemoveTooltip => 'Remove restriction';

  @override
  String get globalConstraintsCreate => 'Create global restriction';

  @override
  String get editorTitle => 'Edit hearing rules';

  @override
  String get editorReset => 'Reset';

  @override
  String get editorApply => 'Apply';

  @override
  String editorInheritedBanner(String from) {
    return 'This item inherits hearing rules from \"$from\". You can take them over as its own rules and adjust them.';
  }

  @override
  String get editorAdoptRules => 'Adopt rules';

  @override
  String get editorPaneTitle => 'Rule editor';

  @override
  String get editorCollapseAll => 'Collapse all';

  @override
  String get editorExpandAll => 'Expand all';

  @override
  String get editorNoConstraint => 'No restriction — freely playable.';

  @override
  String get editorCombineLabel => 'Combine:';

  @override
  String get editorCombineAnd => 'AND (all apply)';

  @override
  String get editorCombineOr => 'OR (any applies)';

  @override
  String get editorPresetsTitle => 'Building blocks';

  @override
  String get editorPresetsHint => 'Drag & drop into the editor';

  @override
  String get editorTypeLabel => 'Type';

  @override
  String get editorAddCondition => 'Add condition';

  @override
  String get editorAddConditionTooltip => 'Add a condition or drag here';

  @override
  String get editorTimeWindowLabel => 'Time window';

  @override
  String get editorWindowPerDay => 'Per day';

  @override
  String get editorWindowPerWeek => 'Per week';

  @override
  String get editorWindowPerMonth => 'Per month';

  @override
  String get editorWindowSinceDate => 'Since date';

  @override
  String get editorWindowRollingHours => 'Last N hours';

  @override
  String get editorLeafMaximum => 'Maximum';

  @override
  String get editorLeafMaxMinutes => 'Max. minutes';

  @override
  String get editorLeafMaxItems => 'Max. entries';

  @override
  String get editorTypeAnd => 'AND (all must apply)';

  @override
  String get editorTypeOr => 'OR (at least one)';

  @override
  String get editorTypeNot => 'NOT (inversion)';

  @override
  String get editorTypePlayCount => 'Play count';

  @override
  String get editorTypePlayDuration => 'Listening time';

  @override
  String get editorTypeFolderItemCount => 'Different folder entries';

  @override
  String get editorTypeTimeOfDay => 'Time of day';

  @override
  String get editorTypeDayOfWeek => 'Day of week';

  @override
  String get editorTypeDateRange => 'Date range';

  @override
  String get editorPickDateTooltip => 'Pick date';

  @override
  String get presetThreeTimesPerDay => 'Three times a day';

  @override
  String get presetOnceAWeek => 'Once a week';

  @override
  String get presetDaytimeOnly => 'Daytime only (8 am – 8 pm)';

  @override
  String get presetWeekdaysOnly => 'Weekdays only';

  @override
  String get presetWeekdaysAndDaytime => 'Weekdays & daytime';

  @override
  String get presetWeekendOnly => 'Weekends only';

  @override
  String get presetMax30MinPerWeek => 'Max. 30 min per week';

  @override
  String get preset2xMonFri3xSatSun => '2× Mon–Fri, 3× Sat+Sun';

  @override
  String get preset2hMonFri3hSatSun => '2h Mon–Fri, 3h Sat+Sun';

  @override
  String get presetMax2DifferentItems => 'Max. 2 different items';

  @override
  String get headerVisibleDateRange => 'Visible date range:';

  @override
  String get headerFromDate => 'From date:';

  @override
  String get headerToDate => 'To date:';

  @override
  String get headerHearingRules => 'Hearing rules';

  @override
  String headerInheritedFrom(String name) {
    return 'inherited from \"$name\"';
  }

  @override
  String get headerRemoveRulesTooltip => 'Remove hearing rules';

  @override
  String get headerHiddenLabel => 'Hidden';

  @override
  String get headerRemoveImage => 'Remove image';

  @override
  String get headerPasteImage => 'Paste image from clipboard';

  @override
  String get headerClipboardUnavailable => 'Clipboard not available';

  @override
  String get headerClipboardEmpty => 'No data in clipboard';

  @override
  String get headerClipboardUnsupported =>
      'No supported image format in clipboard';

  @override
  String headerClipboardError(String error) {
    return 'Error reading clipboard: $error';
  }

  @override
  String headerChildrenCount(int count) {
    return '$count children';
  }

  @override
  String get headerNotSetPlaceholder => '*Not set*';

  @override
  String get headerNoRules => 'No restrictions';

  @override
  String get folderDetailAudioBook => 'Audio book';

  @override
  String get folderDetailIsNew => 'New';

  @override
  String get folderDetailHidden => 'Hidden';

  @override
  String get folderDetailShowChildNumbering =>
      'Show child numbering in player directory view';

  @override
  String get folderDetailFilterAll => 'Show all';

  @override
  String get folderDetailFilterOnlyVisible => 'Only visible';

  @override
  String get folderDetailFilterOnlyHidden => 'Only hidden';

  @override
  String get folderDialogCreateTitle => 'Create folder';

  @override
  String get folderDialogEditTitle => 'Edit folder';

  @override
  String get folderDialogNameLabel => 'Folder name';

  @override
  String get itemDialogNameLabel => 'Item name';

  @override
  String get itemDialogCreateTitle => 'Create media item';

  @override
  String get itemDialogEditTitle => 'Edit media item';

  @override
  String get itemDetailDeleteFileTitle => 'Delete media file?';

  @override
  String itemDetailDeleteFileConfirm(String name) {
    return 'Remove $name from this item?';
  }

  @override
  String get itemDetailNoFilesFound => 'No audio files found in folder';

  @override
  String get itemDetailImportTitle => 'Import audio files?';

  @override
  String itemDetailImportConfirm(int count, String folder) {
    return 'Import all $count audio files from \"$folder\"?';
  }

  @override
  String itemDetailFoldersCount(int count) {
    return '$count folders';
  }

  @override
  String itemDetailAddedSnack(int count) {
    return 'Successfully added $count file(s)';
  }

  @override
  String get itemDetailNoFilesAdded => 'No files were added';

  @override
  String itemDetailErrorPlaying(String error) {
    return 'Error playing audio: $error';
  }

  @override
  String get itemDetailErrorTrackNotFound => 'Error: track document not found';

  @override
  String get itemDetailFileRemoved => 'Media file removed';

  @override
  String itemDetailErrorRemovingFile(String error) {
    return 'Error removing file: $error';
  }

  @override
  String get itemDetailShuffle => 'Shuffle';

  @override
  String get itemDetailRepeat => 'Repeat';

  @override
  String get itemDetailNewFlag => 'New';

  @override
  String get itemDetailUseTrackCovers =>
      'Use track covers in player rather than item cover';

  @override
  String get folderDetailNameForNewItem => 'Name for new media item';

  @override
  String get folderDetailEditName => 'Edit name';

  @override
  String folderDetailDeletedSnack(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String folderDetailDeleteErrorSnack(String error) {
    return 'Error deleting: $error';
  }

  @override
  String get folderDetailNoAudioFilesFound => 'No audio files found';

  @override
  String get folderDetailErrorCreatingItem => 'Error creating media item';

  @override
  String get folderDetailDeleteWithContents =>
      'This will also delete all its contents.';

  @override
  String get folderDetailNoValidAudioImported =>
      'No valid audio files were imported';

  @override
  String folderDetailImportedItems(int count) {
    return 'Imported $count item(s)';
  }

  @override
  String folderDetailImportedFolders(int count) {
    return 'Imported $count folder(s) as media items';
  }

  @override
  String importDialogTitleFiles(int count) {
    return 'Import $count audio files';
  }

  @override
  String get importDialogSingleItemTitle =>
      'Import all into a single media item';

  @override
  String get importDialogSingleItemSubtitle => 'All files go into one item';

  @override
  String get importDialogPerFileTitle => 'Each file as a separate media item';

  @override
  String get importDialogPerFileSubtitle => 'One item per file';

  @override
  String get importDialogSingleFileTitle => 'Import audio file';

  @override
  String get importDialogSingleFileAsItemTitle => 'Import as a media item';

  @override
  String importDialogFoldersTitle(int folders, int files) {
    return 'Import $folders folders ($files audio files)';
  }

  @override
  String get importDialogPerFolderTitle =>
      'Each folder as a separate media item';

  @override
  String get importDialogPerFolderSubtitle =>
      'One item per folder, containing all its files';

  @override
  String get importDialogAllOneItemSubtitle => 'All files go into one item';

  @override
  String get importDialogEachFileTitle => 'Each file as a separate media item';

  @override
  String get importDialogEachFileSubtitle => 'One item per audio file';

  @override
  String get audioImportCompressTitle => 'Compress audio files?';

  @override
  String get audioImportKeepOriginals => 'No, keep originals';

  @override
  String get audioImportCompress => 'Yes, compress';

  @override
  String get audioImportInProgressTitle => 'Importing files';

  @override
  String audioImportProgressLine(int count) {
    return 'Imported $count file(s)';
  }

  @override
  String audioImportUnsupported(String filename) {
    return 'Unsupported file type: $filename';
  }

  @override
  String audioImportErrorAdding(String error) {
    return 'Error adding file: $error';
  }

  @override
  String get loginEditTooltip => 'Edit';

  @override
  String get loginDuplicateTooltip => 'Duplicate';

  @override
  String get loginDeleteTooltip => 'Delete';

  @override
  String get loginLoginTooltip => 'Login';

  @override
  String get loginServerUrlLabel => 'Server URL';

  @override
  String get loginServerUrlHint => 'example.com';

  @override
  String get loginUsernameLabel => 'Username';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginEditProfileTitle => 'Edit profile';

  @override
  String get loginNewProfileTitle => 'New profile';

  @override
  String get loginPleaseEnterServerUrl => 'Please enter a server URL';

  @override
  String get loginPleaseEnterUsername => 'Please enter a username';

  @override
  String get loginPleaseEnterPassword => 'Please enter a password';

  @override
  String audioImportTotalProgress(int percent) {
    return '$percent%';
  }

  @override
  String audioImportFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String audioImportCompressBody(String fileText) {
    return '$fileText not highly compressed. Compress to AAC (160 kbps stereo / 80 kbps mono)? Quality will be indistinguishable from CD. Original files will not be modified.';
  }

  @override
  String get audioImportPreparing => 'Preparing import…';

  @override
  String audioImportProcessedLine(int done, int total) {
    return 'Processed $done/$total files';
  }

  @override
  String audioImportImportingFile(String filename) {
    return 'Importing file\n$filename';
  }

  @override
  String audioImportSkippedFile(String filename) {
    return 'Skipped unsupported file\n$filename';
  }

  @override
  String audioImportCompressingFile(String filename) {
    return 'Compressing file\n$filename';
  }

  @override
  String audioImportFinishedFile(String filename) {
    return 'Finished file\n$filename';
  }

  @override
  String get hearingStatsAllKids => 'All Kids';

  @override
  String get hearingStatsLabel => 'Stats:';

  @override
  String get commonMove => 'Move';

  @override
  String moveDialogTitleOne(String name) {
    return 'Move \"$name\" to:';
  }

  @override
  String moveDialogTitleMany(int count) {
    return 'Move $count entries to:';
  }

  @override
  String get moveDialogRootLevel => 'Top level';

  @override
  String moveDoneSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Moved $count entries',
      one: 'Moved 1 entry',
    );
    return '$_temp0';
  }

  @override
  String get moveToNewSubfolderTitle => 'Move to new subfolder';

  @override
  String get moveToNewSubfolderLabel => 'New subfolder name';

  @override
  String selectionSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectionClearTooltip => 'Clear selection';

  @override
  String get selectionMoveToNewSubfolder => 'To new subfolder';
}
