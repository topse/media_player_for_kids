// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'shared_l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class SharedL10nDe extends SharedL10n {
  SharedL10nDe([String locale = 'de']) : super(locale);

  @override
  String get constraintAnd => ' und ';

  @override
  String get constraintOr => ' oder ';

  @override
  String constraintNotPrefix(String desc) {
    return 'Nicht: $desc';
  }

  @override
  String constraintPlayCountOnce(String window) {
    return 'Einmal $window';
  }

  @override
  String constraintPlayCountTimes(int count, String window) {
    return 'Maximal $count× $window';
  }

  @override
  String constraintPlayDuration(int minutes, String window) {
    return 'Max. $minutes Min. $window';
  }

  @override
  String constraintFolderItemCount(int count, String window) {
    return 'Max. $count verschiedene Einträge $window';
  }

  @override
  String constraintTimeOfDayOnly(String from, String to) {
    return 'Nur $from–$to Uhr';
  }

  @override
  String get constraintDayOfWeekWeekdaysOnly => 'Nur Mo–Fr';

  @override
  String get constraintDayOfWeekWeekendOnly => 'Nur am Wochenende';

  @override
  String constraintDayOfWeekList(String days) {
    return 'Nur $days';
  }

  @override
  String get dayAbbrMon => 'Mo';

  @override
  String get dayAbbrTue => 'Di';

  @override
  String get dayAbbrWed => 'Mi';

  @override
  String get dayAbbrThu => 'Do';

  @override
  String get dayAbbrFri => 'Fr';

  @override
  String get dayAbbrSat => 'Sa';

  @override
  String get dayAbbrSun => 'So';

  @override
  String constraintDateRangeFromTo(String from, String to) {
    return '$from – $to';
  }

  @override
  String constraintDateRangeFrom(String date) {
    return 'Ab $date';
  }

  @override
  String constraintDateRangeTo(String date) {
    return 'Bis $date';
  }

  @override
  String get constraintUnknown => 'Unbekannte Einschränkung';

  @override
  String get windowPerDay => 'pro Tag';

  @override
  String get windowPerWeek => 'pro Woche';

  @override
  String get windowPerMonth => 'pro Monat';

  @override
  String windowSinceDate(String date) {
    return 'seit $date';
  }

  @override
  String windowRollingHours(int hours) {
    return 'je $hours Stunden';
  }

  @override
  String get reasonNoAccess => 'Kein Zugang';

  @override
  String get reasonLocked => 'Gesperrt';

  @override
  String reasonMaxPlaysReached(int count, String window) {
    return 'Maximal $count× $window erreicht';
  }

  @override
  String get reasonOnePlayLeft => 'Noch 1× verfügbar';

  @override
  String reasonTimeLimitReached(int minutes, String window) {
    return 'Zeitlimit erreicht (max. $minutes Min. $window)';
  }

  @override
  String get reasonAlmostAtTimeLimit => 'Fast am Zeitlimit';

  @override
  String reasonMaxItemsStarted(int count, String window) {
    return 'Max. $count Einträge $window gestartet';
  }

  @override
  String get reasonOneItemLeft => 'Noch 1 Eintrag verfügbar';

  @override
  String reasonOnlyAvailableHours(String from, String to) {
    return 'Nur $from–$to Uhr verfügbar';
  }

  @override
  String get reasonNotAvailableToday => 'Heute nicht verfügbar';

  @override
  String reasonAvailableFrom(String date) {
    return 'Verfügbar ab $date';
  }

  @override
  String get reasonNoLongerAvailable => 'Nicht mehr verfügbar';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nein';

  @override
  String get commonHidden => 'Versteckt';

  @override
  String get adminAccessRequired => 'Admin-Zugang erforderlich';

  @override
  String get adminPassword => 'Admin-Passwort';

  @override
  String get adminPasswordIncorrect => 'Falsches Passwort';

  @override
  String get adminPasswordIncorrectCurrent => 'Aktuelles Passwort ist falsch';

  @override
  String get adminPasswordVerify => 'Bestätigen';

  @override
  String get adminPasswordChangeTitle => 'Admin-Passwort ändern';

  @override
  String get adminPasswordCurrent => 'Aktuelles Passwort';

  @override
  String get adminPasswordNew => 'Neues Passwort';

  @override
  String get adminPasswordConfirmNew => 'Neues Passwort bestätigen';

  @override
  String get adminPasswordPleaseEnterNew => 'Bitte ein neues Passwort eingeben';

  @override
  String get adminPasswordTooShort =>
      'Passwort muss mindestens 4 Zeichen lang sein';

  @override
  String get adminPasswordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get adminPasswordChange => 'Passwort ändern';

  @override
  String get adminPasswordChangedSnack => 'Passwort erfolgreich geändert';

  @override
  String get adminPasswordSetTitle => 'Admin-Passwort festlegen';

  @override
  String get adminPasswordSetExplanation =>
      'Bitte ein Admin-Passwort für die Ersteinrichtung festlegen.';

  @override
  String get adminPasswordPlain => 'Passwort';

  @override
  String get adminPasswordPleaseEnter => 'Bitte ein Passwort eingeben';

  @override
  String get adminPasswordConfirm => 'Passwort bestätigen';

  @override
  String get adminPasswordSet => 'Passwort festlegen';

  @override
  String get adminSettingsTitle => 'Admin-Einstellungen';

  @override
  String get adminAudioOutputDevices => 'Audio-Ausgabegeräte';

  @override
  String get adminAudioOutputDevicesSubtitle =>
      'Lautstärke pro Ausgabegerät begrenzen';

  @override
  String adminGridColumnsPortrait(int count) {
    return 'Spalten im Hochformat: $count';
  }

  @override
  String adminGridColumnsLandscape(int count) {
    return 'Spalten im Querformat: $count';
  }

  @override
  String get adminHearingRulesSection => 'Hörregeln';

  @override
  String get adminMinPlayDurationDescription =>
      'Mindestdauer, ab der ein Abspielvorgang gezählt wird und der Abspielfortschritt eines Hörbuchs gespeichert wird. Titel die kürzer sind als dieser Wert zählen immer.';

  @override
  String get adminMinPlayDurationDisabled => 'Mindestdauer: deaktiviert';

  @override
  String adminMinPlayDuration(int seconds) {
    return 'Mindestdauer: $seconds s';
  }

  @override
  String get adminMinPlaySliderLabelOff => 'aus';

  @override
  String adminMinPlaySliderLabel(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminGracePeriodDescription =>
      'Wenn die Hörzeit abläuft und der Titel hat noch weniger als diese Zeit übrig, darf das Kind fertig hören.';

  @override
  String adminGracePeriod(int minutes) {
    return 'Kulanzzeit: $minutes min';
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
  String get kidNameTitle => 'Wer benutzt dieses Gerät?';

  @override
  String get kidNameLabel => 'Dein Name';

  @override
  String get kidNamePleaseEnter => 'Bitte gib deinen Namen ein';

  @override
  String get kidNameDone => 'Fertig';

  @override
  String get playerAppTitle => 'Media Player für Kinder';

  @override
  String get playerMenuShowAdmin => 'Admin-Optionen anzeigen';

  @override
  String get directoryHearingRulesDisabled => 'Hörregeln deaktiviert';

  @override
  String get directoryDateLocksDisabled => 'Datumssperren deaktiviert';

  @override
  String get directoryNoMediaItems => 'Keine Medien gefunden';

  @override
  String get directoryItemUnavailable => 'Jetzt nicht verfügbar';

  @override
  String get playerListeningTimeUp => 'Hörzeit aufgebraucht';

  @override
  String get audioDeviceNoneFound => 'Keine Audio-Ausgabegeräte gefunden.';

  @override
  String get audioDeviceEmergencyTitle => 'Notfall-Ausnahmen';

  @override
  String get audioDeviceEmergencyHelper =>
      'Nur für den Notfall aktivieren. Bitte nach der Reise wieder deaktivieren.';

  @override
  String get audioDeviceIgnoreConstraints => 'Hörregeln ignorieren';

  @override
  String get audioDeviceIgnoreConstraintsSub =>
      'Alle Hör-Einschränkungen sind deaktiviert';

  @override
  String get audioDeviceIgnoreDates => 'Datumssperren ignorieren';

  @override
  String get audioDeviceIgnoreDatesSub =>
      'Inhalte mit Zeitfenstern (von/bis) sind sichtbar';

  @override
  String get audioDeviceBluetoothBannerText =>
      'Bluetooth-Zugriff erlauben, um alle gekoppelten Geräte anzuzeigen, auch wenn sie ausgeschaltet sind.';

  @override
  String get audioDeviceBluetoothBannerAllow => 'Erlauben';

  @override
  String get audioDeviceStatusActive => 'aktiv';

  @override
  String get audioDeviceStatusAvailable => 'jetzt verfügbar';

  @override
  String get audioDeviceStatusPairedUnavailable =>
      'gekoppelt, derzeit nicht verfügbar';

  @override
  String get audioDeviceStatusUnavailable => 'derzeit nicht verfügbar';

  @override
  String get audioDeviceVolumeLimit => 'Lautstärkebegrenzung';

  @override
  String get audioDeviceNoLimit => 'Keine Begrenzung';

  @override
  String audioDeviceLimitedTo(String db) {
    return 'Audio um $db dB unter Maximum begrenzt';
  }

  @override
  String get audioDeviceUnavailablePairedHelper =>
      'Dieses Gerät ist Android bekannt, ist aber derzeit nicht ansteuerbar. Die Lautstärkebegrenzung wird übernommen, sobald es verfügbar wird.';

  @override
  String get audioDeviceUnavailableTypeHelper =>
      'Dieser Gerätetyp ist derzeit nicht ansteuerbar, die Einstellungen bleiben aber gespeichert.';

  @override
  String get audioDevicePairedBluetoothTitle => 'Gekoppelte Bluetooth-Geräte';

  @override
  String get audioDevicePairedBluetoothHelper =>
      'Bluetooth-Zugriff erlauben, um mit Android gekoppelte Kopfhörer und Lautsprecher anzuzeigen, auch wenn sie gerade ausgeschaltet sind.';

  @override
  String get audioDevicePairedBluetoothAllow => 'Bluetooth-Zugriff erlauben';

  @override
  String get audioDeviceBluetoothTitle => 'Bluetooth-Gerät';

  @override
  String get audioDeviceBluetoothNoneYet =>
      'Es ist noch kein konkret gekoppeltes Bluetooth-Gerät bekannt. Sobald Android einen gekoppelten Kopfhörer meldet, erscheint er hier mit eigenem Eintrag.';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonDuplicate => 'Duplizieren';

  @override
  String get commonLogin => 'Anmelden';

  @override
  String get commonImport => 'Importieren';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get commonItem => 'Eintrag';

  @override
  String get commonItemCapitalized => 'Eintrag';

  @override
  String get commonFolder => 'Ordner';

  @override
  String get commonFolderCapitalized => 'Ordner';

  @override
  String get commonMediaItem => 'Medien-Eintrag';

  @override
  String get commonNotSet => 'Nicht gesetzt';

  @override
  String get commonFrom => 'Von';

  @override
  String get commonUntil => 'Bis';

  @override
  String get commonHours => 'Stunden';

  @override
  String get companionAppTitle => 'Media Player für Kinder Companion';

  @override
  String get companionGlobalConstraintsMenu => 'Globale Einschränkungen';

  @override
  String get companionLogoutMenu => 'Abmelden';

  @override
  String get companionDeleteTitle => 'Löschen?';

  @override
  String companionDeleteOneConfirm(String kind, String name) {
    return '$kind „$name\" wirklich löschen?';
  }

  @override
  String companionDeleteManyConfirm(String kind, String name, int count) {
    return '$kind „$name\" und die $count Untereinträge wirklich löschen?';
  }

  @override
  String get companionCreateNewTitle => 'Neu erstellen';

  @override
  String get globalConstraintsHeading => 'Globale Hörregeln';

  @override
  String get globalConstraintsDescription =>
      'Beschränkt die gesamte tägliche/wöchentliche Hörzeit über alle Inhalte hinweg. Wird zusätzlich zu den Einschränkungen einzelner Einträge ausgewertet (die strengere Regel gewinnt).';

  @override
  String get globalConstraintsRemoveTooltip => 'Einschränkung entfernen';

  @override
  String get globalConstraintsCreate => 'Globale Einschränkung erstellen';

  @override
  String get editorTitle => 'Hörregeln bearbeiten';

  @override
  String get editorReset => 'Zurücksetzen';

  @override
  String get editorApply => 'Übernehmen';

  @override
  String editorInheritedBanner(String from) {
    return 'Dieses Element erbt Hörregeln von „$from\". Du kannst sie als eigene Regeln übernehmen und anpassen.';
  }

  @override
  String get editorAdoptRules => 'Regeln übernehmen';

  @override
  String get editorPaneTitle => 'Regel-Editor';

  @override
  String get editorCollapseAll => 'Alle einklappen';

  @override
  String get editorExpandAll => 'Alle ausklappen';

  @override
  String get editorNoConstraint => 'Keine Einschränkung — frei abspielbar.';

  @override
  String get editorCombineLabel => 'Verknüpfung:';

  @override
  String get editorCombineAnd => 'UND (alle gelten)';

  @override
  String get editorCombineOr => 'ODER (eins genügt)';

  @override
  String get editorPresetsTitle => 'Bausteine';

  @override
  String get editorPresetsHint => 'Per Drag & Drop in den Editor ziehen';

  @override
  String get editorTypeLabel => 'Typ';

  @override
  String get editorAddCondition => 'Bedingung hinzufügen';

  @override
  String get editorAddConditionTooltip =>
      'Bedingung hinzufügen oder hierher ziehen';

  @override
  String get editorTimeWindowLabel => 'Zeitfenster';

  @override
  String get editorWindowPerDay => 'Pro Tag';

  @override
  String get editorWindowPerWeek => 'Pro Woche';

  @override
  String get editorWindowPerMonth => 'Pro Monat';

  @override
  String get editorWindowSinceDate => 'Seit Datum';

  @override
  String get editorWindowRollingHours => 'Letzte N Stunden';

  @override
  String get editorLeafMaximum => 'Maximal';

  @override
  String get editorLeafMaxMinutes => 'Max. Minuten';

  @override
  String get editorLeafMaxItems => 'Max. Einträge';

  @override
  String get editorTypeAnd => 'UND (alle müssen gelten)';

  @override
  String get editorTypeOr => 'ODER (mindestens eins)';

  @override
  String get editorTypeNot => 'NICHT (Umkehrung)';

  @override
  String get editorTypePlayCount => 'Abspielhäufigkeit';

  @override
  String get editorTypePlayDuration => 'Hördauer';

  @override
  String get editorTypeFolderItemCount => 'Verschiedene Einträge im Ordner';

  @override
  String get editorTypeTimeOfDay => 'Tageszeit';

  @override
  String get editorTypeDayOfWeek => 'Wochentag';

  @override
  String get editorTypeDateRange => 'Zeitraum';

  @override
  String get editorPickDateTooltip => 'Datum wählen';

  @override
  String get presetThreeTimesPerDay => 'Dreimal am Tag';

  @override
  String get presetOnceAWeek => 'Einmal die Woche';

  @override
  String get presetDaytimeOnly => 'Nur tagsüber (8–20 Uhr)';

  @override
  String get presetWeekdaysOnly => 'Nur Wochentage';

  @override
  String get presetWeekdaysAndDaytime => 'Wochentage & tagsüber';

  @override
  String get presetWeekendOnly => 'Nur am Wochenende';

  @override
  String get presetMax30MinPerWeek => 'Max. 30 Min. pro Woche';

  @override
  String get preset2xMonFri3xSatSun => '2× Mo–Fr, 3× Sa+So';

  @override
  String get preset2hMonFri3hSatSun => '2h Mo–Fr, 3h Sa+So';

  @override
  String get presetMax2DifferentItems => 'Max. 2 verschiedene Einträge';

  @override
  String get headerVisibleDateRange => 'Sichtbarer Zeitraum:';

  @override
  String get headerFromDate => 'Von:';

  @override
  String get headerToDate => 'Bis:';

  @override
  String get headerHearingRules => 'Hörregeln';

  @override
  String headerInheritedFrom(String name) {
    return 'geerbt von „$name\"';
  }

  @override
  String get headerRemoveRulesTooltip => 'Hörregeln entfernen';

  @override
  String get headerHiddenLabel => 'Versteckt';

  @override
  String get headerRemoveImage => 'Bild entfernen';

  @override
  String get headerPasteImage => 'Bild aus Zwischenablage einfügen';

  @override
  String get headerClipboardUnavailable => 'Zwischenablage nicht verfügbar';

  @override
  String get headerClipboardEmpty => 'Keine Daten in der Zwischenablage';

  @override
  String get headerClipboardUnsupported =>
      'Kein unterstütztes Bildformat in der Zwischenablage';

  @override
  String headerClipboardError(String error) {
    return 'Fehler beim Lesen der Zwischenablage: $error';
  }

  @override
  String headerChildrenCount(int count) {
    return '$count Einträge';
  }

  @override
  String get headerNotSetPlaceholder => '*Nicht gesetzt*';

  @override
  String get headerNoRules => 'Keine Einschränkungen';

  @override
  String get folderDetailAudioBook => 'Hörbuch';

  @override
  String get folderDetailIsNew => 'Neu';

  @override
  String get folderDetailHidden => 'Versteckt';

  @override
  String get folderDetailShowChildNumbering =>
      'Nummerierung im Player anzeigen';

  @override
  String get folderDialogCreateTitle => 'Ordner erstellen';

  @override
  String get folderDialogEditTitle => 'Ordner bearbeiten';

  @override
  String get folderDialogNameLabel => 'Ordnername';

  @override
  String get itemDialogNameLabel => 'Eintragsname';

  @override
  String get itemDialogCreateTitle => 'Medien-Eintrag erstellen';

  @override
  String get itemDialogEditTitle => 'Medien-Eintrag bearbeiten';

  @override
  String get itemDetailDeleteFileTitle => 'Mediendatei löschen?';

  @override
  String itemDetailDeleteFileConfirm(String name) {
    return '$name aus diesem Eintrag entfernen?';
  }

  @override
  String get itemDetailNoFilesFound => 'Keine Audiodateien im Ordner gefunden';

  @override
  String get itemDetailImportTitle => 'Audiodateien importieren?';

  @override
  String itemDetailImportConfirm(int count, String folder) {
    return 'Alle $count Audiodateien aus „$folder\" importieren?';
  }

  @override
  String itemDetailFoldersCount(int count) {
    return '$count Ordner';
  }

  @override
  String itemDetailAddedSnack(int count) {
    return '$count Dateien erfolgreich hinzugefügt';
  }

  @override
  String get itemDetailNoFilesAdded => 'Es wurden keine Dateien hinzugefügt';

  @override
  String itemDetailErrorPlaying(String error) {
    return 'Fehler beim Abspielen: $error';
  }

  @override
  String get itemDetailErrorTrackNotFound =>
      'Fehler: Track-Dokument nicht gefunden';

  @override
  String get itemDetailFileRemoved => 'Mediendatei entfernt';

  @override
  String itemDetailErrorRemovingFile(String error) {
    return 'Fehler beim Entfernen der Datei: $error';
  }

  @override
  String get itemDetailShuffle => 'Zufällige Reihenfolge';

  @override
  String get itemDetailRepeat => 'Wiederholen';

  @override
  String get itemDetailNewFlag => 'Neu';

  @override
  String get itemDetailUseTrackCovers =>
      'Im Player Track-Cover statt Eintrags-Cover anzeigen';

  @override
  String get folderDetailNameForNewItem => 'Name für neuen Medien-Eintrag';

  @override
  String get folderDetailEditName => 'Name bearbeiten';

  @override
  String folderDetailDeletedSnack(String name) {
    return '„$name\" gelöscht';
  }

  @override
  String folderDetailDeleteErrorSnack(String error) {
    return 'Fehler beim Löschen: $error';
  }

  @override
  String get folderDetailNoAudioFilesFound => 'Keine Audiodateien gefunden';

  @override
  String get folderDetailErrorCreatingItem =>
      'Fehler beim Erstellen des Medien-Eintrags';

  @override
  String get folderDetailDeleteWithContents =>
      'Dabei werden auch alle Inhalte gelöscht.';

  @override
  String get folderDetailNoValidAudioImported =>
      'Keine gültigen Audiodateien importiert';

  @override
  String folderDetailImportedItems(int count) {
    return '$count Einträge importiert';
  }

  @override
  String folderDetailImportedFolders(int count) {
    return '$count Ordner als Medien-Einträge importiert';
  }

  @override
  String importDialogTitleFiles(int count) {
    return '$count Audiodateien importieren';
  }

  @override
  String get importDialogSingleItemTitle =>
      'Alle in einen Medien-Eintrag importieren';

  @override
  String get importDialogSingleItemSubtitle =>
      'Alle Dateien landen in einem Eintrag';

  @override
  String get importDialogPerFileTitle =>
      'Jede Datei als eigenen Medien-Eintrag';

  @override
  String get importDialogPerFileSubtitle => 'Ein Eintrag pro Datei';

  @override
  String get importDialogSingleFileTitle => 'Audiodatei importieren';

  @override
  String get importDialogSingleFileAsItemTitle =>
      'Als Medien-Eintrag importieren';

  @override
  String importDialogFoldersTitle(int folders, int files) {
    return '$folders Ordner ($files Audiodateien) importieren';
  }

  @override
  String get importDialogPerFolderTitle =>
      'Jeden Ordner als eigenen Medien-Eintrag';

  @override
  String get importDialogPerFolderSubtitle =>
      'Ein Eintrag pro Ordner mit allen enthaltenen Dateien';

  @override
  String get importDialogAllOneItemSubtitle =>
      'Alle Dateien landen in einem Eintrag';

  @override
  String get importDialogEachFileTitle =>
      'Jede Datei als eigenen Medien-Eintrag';

  @override
  String get importDialogEachFileSubtitle => 'Ein Eintrag pro Audiodatei';

  @override
  String get audioImportCompressTitle => 'Audiodateien komprimieren?';

  @override
  String get audioImportKeepOriginals => 'Nein, Originale behalten';

  @override
  String get audioImportCompress => 'Ja, komprimieren';

  @override
  String get audioImportInProgressTitle => 'Importiere Dateien';

  @override
  String audioImportProgressLine(int count) {
    return '$count Dateien importiert';
  }

  @override
  String audioImportUnsupported(String filename) {
    return 'Nicht unterstützter Dateityp: $filename';
  }

  @override
  String audioImportErrorAdding(String error) {
    return 'Fehler beim Hinzufügen der Datei: $error';
  }

  @override
  String get loginEditTooltip => 'Bearbeiten';

  @override
  String get loginDuplicateTooltip => 'Duplizieren';

  @override
  String get loginDeleteTooltip => 'Löschen';

  @override
  String get loginLoginTooltip => 'Anmelden';

  @override
  String get loginServerUrlLabel => 'Server-URL';

  @override
  String get loginServerUrlHint => 'example.com';

  @override
  String get loginUsernameLabel => 'Benutzername';

  @override
  String get loginPasswordLabel => 'Passwort';

  @override
  String get loginEditProfileTitle => 'Profil bearbeiten';

  @override
  String get loginNewProfileTitle => 'Neues Profil';

  @override
  String get loginPleaseEnterServerUrl => 'Bitte Server-URL eingeben';

  @override
  String get loginPleaseEnterUsername => 'Bitte Benutzernamen eingeben';

  @override
  String get loginPleaseEnterPassword => 'Bitte Passwort eingeben';

  @override
  String audioImportTotalProgress(int percent) {
    return '$percent %';
  }

  @override
  String audioImportFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String audioImportCompressBody(String fileText) {
    return '$fileText sind nicht stark komprimiert. Nach AAC umwandeln (160 kbps Stereo / 80 kbps Mono)? Die Qualität ist von CD nicht zu unterscheiden. Die Originaldateien werden nicht verändert.';
  }

  @override
  String get audioImportPreparing => 'Import wird vorbereitet…';

  @override
  String audioImportProcessedLine(int done, int total) {
    return '$done/$total Dateien verarbeitet';
  }

  @override
  String audioImportImportingFile(String filename) {
    return 'Importiere Datei\n$filename';
  }

  @override
  String audioImportSkippedFile(String filename) {
    return 'Nicht unterstützte Datei übersprungen\n$filename';
  }

  @override
  String audioImportCompressingFile(String filename) {
    return 'Komprimiere Datei\n$filename';
  }

  @override
  String audioImportFinishedFile(String filename) {
    return 'Datei fertig\n$filename';
  }
}
