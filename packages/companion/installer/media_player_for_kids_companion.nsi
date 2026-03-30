; Media Player For Kids Companion Installer
; Tested with NSIS 3.x

Unicode true

;--------------------------------
; Include Modern UI

  !include "MUI2.nsh"

;--------------------------------
; General

!ifndef VERSION
  !define VERSION "1.0.0"
!endif
!define PRODUCTNAME "media_player_for_kids_companion"
!define DISPLAYNAME "Media Player For Kids Companion"
!define PUBLISHER "Stonesoft"

SetCompress auto
SetCompressor /SOLID lzma

!define SOURCEPATH "..\build\windows\x64\runner\Release"

  ; Name and output file
  Name "${DISPLAYNAME}"
  OutFile ".\${PRODUCTNAME}_${VERSION}.exe"

  ; Default installation folder
  InstallDir "$LOCALAPPDATA\${PUBLISHER}\${PRODUCTNAME}"

  ; Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\${PUBLISHER}\${PRODUCTNAME}" "InstallDir"

  RequestExecutionLevel user

;--------------------------------
; Interface Settings

  !define MUI_ABORTWARNING

  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_TEXT "Start ${DISPLAYNAME}"
  !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchApp"

;--------------------------------
; Pages

  !insertmacro MUI_PAGE_LICENSE "../LICENSE"
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
; Languages

  !insertmacro MUI_LANGUAGE "English"

;--------------------------------

Function LaunchApp
  Exec "$INSTDIR\${PRODUCTNAME}.exe"
FunctionEnd

;--------------------------------
; Check for existing installation before installing

Function .onInit

  ReadRegStr $R0 HKCU \
  "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" \
  "UninstallString"
  StrCmp $R0 "" done

  MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
  "${DISPLAYNAME} is already installed.$\n$\nClick OK to remove the \
previous version or Cancel to cancel this upgrade." \
  IDOK uninst
  Abort

; Run the uninstaller
uninst:
  ClearErrors
  ExecWait '$R0 _?=$INSTDIR'

  IfErrors no_remove_uninstaller done
    Delete "$INSTDIR\Uninstall.exe"
  no_remove_uninstaller:

done:

FunctionEnd

;--------------------------------
; Installer Section

Section "${DISPLAYNAME}" SecProgram

  SetOutPath "$INSTDIR"
  File /r "${SOURCEPATH}\*"

  ; Store installation folder in registry
  WriteRegStr HKCU "Software\${PUBLISHER}\${PRODUCTNAME}" "InstallDir" $INSTDIR

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Add to Add/Remove Programs
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" \
                   "DisplayName" "${DISPLAYNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" \
                   "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" \
                   "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}" \
                   "DisplayVersion" "${VERSION}"

  ; Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\${DISPLAYNAME}"
  CreateShortCut "$SMPROGRAMS\${DISPLAYNAME}\${DISPLAYNAME}.lnk" "$INSTDIR\${PRODUCTNAME}.exe"
  CreateShortCut "$SMPROGRAMS\${DISPLAYNAME}\Uninstall ${DISPLAYNAME}.lnk" "$INSTDIR\Uninstall.exe"

  ; Desktop shortcut
  CreateShortCut "$DESKTOP\${DISPLAYNAME}.lnk" "$INSTDIR\${PRODUCTNAME}.exe"

SectionEnd

;--------------------------------
; Uninstaller Section

Section "Uninstall"

  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r /REBOOTOK "$INSTDIR"

  ; Remove Start Menu shortcuts
  RMDir /r /REBOOTOK "$SMPROGRAMS\${DISPLAYNAME}"

  ; Remove Desktop shortcut
  Delete "$DESKTOP\${DISPLAYNAME}.lnk"

  ; Remove registry entries
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCTNAME}"
  DeleteRegKey HKCU "Software\${PUBLISHER}\${PRODUCTNAME}"

SectionEnd
