/*
 * Copyright 2016 OSVR and contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

/*
 * Starting with NSIS v3.0 we can choose to use unicode
 * support. We enable/disable the unicodeEnable variable
 * via /D when we call makensis within buildInstaller.bat.
 */
!ifdef unicodeEnable
Unicode true
!endif

; Modern interface settings
!include "MUI2.nsh"
!include "osvr_includes.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"
!include "WinVer.nsh"

;LoadLanguageFile "${NSISDIR}\Contrib\Language files\English.nlf"

;--------------------------------
;The nsProcess provides simple macros for handling process control
!include "nsProcess.nsh"

;--------------------------------
;The LogicLib provides some very simple macros that allow easy construction of complex logical structures, see LogicLib.nsh
!include "LogicLib.nsh"
  
; APP Installation directory Page
!define MUI_ICON "osvr_logo.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "splash.bmp"
; Window handle of the custom page
Var hwnd

!define PRODUCT_NAME "OSVR Runtime"
!define PRODUCT_FRIENDLY_NAME "OSVR Runtime"
!define APP_EXE "osvr_server.exe"
!define CORE_64_DIR "OSVR-Core-64"
!define CORE_32_DIR "OSVR-Core-32"
!define CORE_DIRX "OSVR-Core"

Var CORE_DIR

!define TRACKER_APP "OSVRTrackerView.exe"
!define TRACKER_DIR "OSVR-TrackerView"
!define CPI_DIR "OSVR-CPI"
!define CPI_APP "OSVR_CPI.exe"
!define STEAMVR_DIR "OSVR-SteamVR"
!define TRAY_APP "OSVR_TrayApp.exe"
!define TRAY_DIR "OSVR-TrayApp"
!define SAMPLESCENE_APP "OSVR_SampleScene.exe"
!define SAMPLESCENE_DIR "OSVR-SampleScene"
!define SERVICE_FILENAME "osvr_services.exe"
!define VIDEO_CALIBRATION_TOOL "VideoTrackerCalibrationUtility.exe"
!define OSVR_LOG_FILENAME "osvr_log.txt"
!define README_FILE "readme.txt"

!define RENDERMANAGER_DIR "OSVR-RenderManager"
!define DRIVER_PACKAGE_EXE "OSVR-HDK-Combined-Driver-Installer-1.2.6.exe"
!define DRIVER_PACKAGE_20_EXE "hdk2displaydrv_v1.00.01.exe"

; command line to either ask where to put the installation or default to Program Files (x86)
; "ask" or !"ask"
Var APP_INSTALL_DIR
Var UNINSTALL_DIR
!define LOCAL_UNINSTALLER_NAME 		"OSVRServicesUninstall.exe"
; command line parameter to indicate whether or not the opensource Control Panel Interface is installed
; "true" or !"true"
Var CPI_INSTALL
; Used to distinguish if we are going to install trackerviewer or not
Var TRACKER_INSTALL
; Used to distinguish if we are going to install trackerviewer or not
Var SAMPLESCENE_INSTALL
; Used to distinguish if we are installing the server as a service only the server
Var SERVER_ONLY_INSTALL
; Used to distinguish if we are installing the tray application
Var TRAY_INSTALL
; icon used for the shortcuts, installer, and uninstaller
icon "osvr_logo.ico"
UninstallIcon "osvr_logo.ico"

; helper variables
Var forwardPath

; Installer Version information
; must be a define...

!ifndef pVersion
!define pVersion "0.6.0.0"
!endif

!define productVersion ${pVersion}

; Version number needs to be changed when we install a new distribution. It is appended to the installer name just to allow for easy identification
!define REVISION                    XXXXX
!define VERSION                     2.5

!ifndef distroDirectory
	!define distroDirectory "..\Distro"
!endif

; NOTE: Assumption is that both the 32 and 64 bit versions are truly of the samve version
!define /file CCVERSION				"${distroDirectory}\${CORE_32_DIR}\osvr-ver.txt"
; required diskspace in KB
!define PAYLOAD_SIZE                "160000"

;VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "OSVR Services Setup"
;VIProductVersion ${productVersion}
;VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "OSVR"
;VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright OSVR"
;VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "Services and core binary installer"
;VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" ${CCVERSION}

; Splash screen. This may go away at some point.
Function .onInit
  ; ExtrAPP InstallOptions files
  ; $PLUGINSDIR will automatically be removed when the installer closes
  InitPluginsDir
  File /oname=$PLUGINSDIR\test.ini "osvr_finish.ini"

;  ${If} ${RunningX64}
;    # 64 bit code
;    Strcpy $CORE_DIR ${CORE_64_DIR}
;  ${Else}
    # 32 bit code
    Strcpy $CORE_DIR ${CORE_DIRX}
;  ${EndIf}
  SetShellVarContext all

  IfSilent +6
    SetOutPath $TEMP
    File /oname=spltmp.bmp "splash.bmp"
    advsplash::show 1000 600 400 -1 $TEMP/spltmp
    Pop $0 ; $0 has '1' if the user closed the splash screen early, '0' if everything closed normally, and '-1' if some error occurred.
    Delete $TEMP/spltmp.bmp
    
  SetPluginUnload alwaysoff
  ; set up the logging file
  LogEx::Init /NOUNLOAD ${OSVR_LOG_FILENAME}
  
  ; create a shortcut named "new shortcut" in the start menu programs directory
  CreateDirectory "$SMPROGRAMS\OSVR"
  Call GetCmdLineOptions
  Call OkayToInstall
FunctionEnd

;--------------------------------
;General

  ;Name and file
  Name "${PRODUCT_FRIENDLY_NAME}"
  OutFile "${distroDirectory}/${PRODUCT_NAME} Setup.${productVersion}.exe"

  ; Admin priviledge is required
  RequestExecutionLevel admin

  ShowInstDetails nevershow
  ShowUnInstDetails nevershow
  AutoCloseWindow true
  ;--------------------------------

Function GetCmdLineOptions
  ; default install directory to the program files (x86)
  Strcpy $INSTDIR "$PROGRAMFILES\OSVR"

  ; process command line options
  !InsertMacro CommandParameter "-SERVER_INSTALL_ONLY=" $SERVER_ONLY_INSTALL
  !InsertMacro CommandParameter "-CPI_INSTALL=" $CPI_INSTALL
  !InsertMacro CommandParameter "-TRACKER_INSTALL=" $TRACKER_INSTALL
  !InsertMacro CommandParameter "-TRAY_INSTALL=" $TRAY_INSTALL
  !InsertMacro CommandParameter "-SAMPLESCENE_INSTALL=" $SAMPLESCENE_INSTALL

  Strcpy $APP_INSTALL_DIR $INSTDIR
  ;MessageBox MB_OK "$APP_INSTALL_DIR"
  Strcpy $UNINSTALL_DIR $APP_INSTALL_DIR
FunctionEnd


Function OkayToInstall
;version Checking
  ${TimeStamp} $0
  LogEx::Write true true "$0:Version Check"

  ReadRegStr $0 HKLM "SOFTWARE\OSVR" "InstalledVersion"
  ${If} ${Errors}
      ;MessageBox MB_OK "Value not found"
	  Goto OkToInstallThis
  ${Else}
	  ;${If} ${CCVERSION} S>= $0
		 ;MessageBox MB_OK "Attempting to install version ${CCVERSION} over $0"
         ${TimeStamp} $0
         LogEx::Write true true "$0:Replacing $0 with ${CCVERSION}"
		 ;Goto InstallThis
	  ;${Else}
		;MessageBox MB_OK "Attempting to install version ${CCVERSION} over $0, which is not newer than already installed. Quitting installer."
       ;  ${TimeStamp} $0
        ;LogEx::Write true true "$0:Version Check: $0 is newer than ${CCVERSION}}"
		;Quit
	  ;${Endif}
  ${Endif}

  OkToInstallThis:
  ; should check for free space here
  ${TimeStamp} $0
  LogEx::Write true true "$0:Free space check"

  StrCpy $0 ${PAYLOAD_SIZE} ; kb u need
  StrCpy $1 '$PROGRAMFILES' ; check drive c: for space
  Call CheckSpaceFunc
  IntCmp $2 1 okay
  MessageBox MB_OK "Error: Not enough disk space. Please make sure you have at least ${PAYLOAD_SIZE} KB free. $2"
  Quit
  okay:
  
  ${TimeStamp} $0
  LogEx::Write true true "$0:InitialCleanup"

; Check if there is a process already running and kill it so we can install all necessary files.
  nsExec::ExecToStack /timeout=5000 '$APP_INSTALL_DIR\$CORE_DIR\bin\${SERVICE_FILENAME} -stop'
  !InsertMacro KillExe "${APP_EXE}"
  !InsertMacro KillExe "${TRACKER_APP}"
  !InsertMacro KillExe "${TRAY_APP}"
  !InsertMacro KillExe "${CPI_APP}"
  !InsertMacro KillExe "${SAMPLESCENE_APP}"
FunctionEnd

Function CheckAppInstallPre
  ; setup the application install path
  ; default
  Strcpy $INSTDIR "$PROGRAMFILES\OSVR"
  ${GetParameters} $R0
  ${GetOptions} $R0 "-APP_INSTALL_DIR_ASK=" $R1
  ; check if there istranges a command line option to install in a different location
  
  ${TimeStamp} $0
  LogEx::Write true true "$0:checkappinstallpre $R1"

  ${If} $R1 != "TRUE"
    Abort
  ${Endif}
FunctionEnd

Function ShowCustom
  InstallOptions::initDialog /NOUNLOAD "$PLUGINSDIR\test.ini"
  ; In this mode InstallOptions returns the window handle so we can use it
  Pop $hwnd

  !insertmacro MUI_HEADER_TEXT "Installation complete" "Where to go next"

  ; Now show the dialog and wait for it to finish
  InstallOptions::show
  ; Finally fetch the InstallOptions status value (we don't care what it is though)
  Pop $0
FunctionEnd

Function LeaveCustom

  ; At this point the user has either pressed Next or one of our custom buttons
  ; We find out which by reading from the INI file
  ReadINIStr $0 "$PLUGINSDIR\test.ini" "Settings" "State"
  StrCmp $0 3 readme  ; Next button?
  StrCmp $0 4 launchUtils ; Automatic install
  StrCmp $0 5 theLink  ; custom install
  StrCmp $0 0 nextButton ; finished
  Abort ; Return to the page

readme:
   Abort ; Return to the page

launchUtils:
   Abort ; Return to the page

theLink:
   Abort ; Return to the page

nextButton:
  ReadINIStr $0 "$PLUGINSDIR\test.ini" "Field 3" "State"
  StrCmp $0 1 openReadme skipReadme
openReadme:
  ExecShell "" "$APP_INSTALL_DIR\${README_FILE}"
      
skipReadme:
  ReadINIStr $0 "$PLUGINSDIR\test.ini" "Field 4" "State"
  StrCmp $0 1 openUtils done
   
openUtils:
   ExecShell "" "$APP_INSTALL_DIR\${CPI_DIR}\${CPI_APP}"
done:
FunctionEnd

; License page
!insertmacro MUI_PAGE_LICENSE "License.txt"

; Components Page
!define MUI_COMPONENTSPAGE_TEXT_TOP "Select the Components you want to install and uncheck the ones you you do not want to install. Click next to continue."
;!define MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_TITLE "OSVR Components"
;!define MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_INFO "Core: Runtime components - Tray: helper app - Utilies: Basic system management app - Tracker: Utility app RenderManager: Optional render tools - SteamVR: Steam drivers Drivers: MS Device drivers"
;!define MUI_COMPONENTSPAGE_TEXT_DESCRIPTION_INFO ""
!insertmacro MUI_PAGE_COMPONENTS
;Page components

; Install Files Page
!insertmacro MUI_PAGE_INSTFILES
;Page instfiles

; Our custom page
Page custom ShowCustom LeaveCustom

;!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
;!define MUI_FINISHPAGE_SHOWREADME "${README_FILE}"
;!define MUI_FINISHPAGE_LINK "Find more info at OSVR Org"
;!define MUI_FINISHPAGE_LINK_LOCATION "http://osvr.org"
;!insertmacro MUI_PAGE_FINISH

UninstPage uninstConfirm
UninstPage instfiles

;------------------------------------------------------------------------------------------
;Installer Sections
; Core
; Tray app
; Control panel interface
; TrackerViewer
; RenderManager
; SteamVR
; Drivers

Section "!OSVR Core" CoreSection
  ; make section manditory
  SectionIn RO
  ; We may want to check here first for existing earlier version before installing. We only do overwrite here and no deletion of existing items
  ; Copy files
  SetOverwrite on
;  Section "64-Bit Core"
;    ${TimeStamp} $0
;    LogEx::Write true true "$0:64-Bit CoreSection Install"
;    SetOutPath "$APP_INSTALL_DIR\${CORE_64_DIR}"
;    File /r /x . "${distroDirectory}\${CORE_64_DIR}\*.*"
;    File osvr_logo.ico
;    File osvr_user_settings.json
;    ; used to facilitate Synapse uninstall
;    File rzUninstaller.xml
;  SectionEnd
;  Section "32-Bit Core"
    ${TimeStamp} $0
    LogEx::Write true true "$0:32-Bit CoreSection Install"
    ; need to fix this later to make more general
    SetOutPath "$APP_INSTALL_DIR\${CORE_DIRX}"
    File /r /x . "${distroDirectory}\${CORE_32_DIR}\*.*"
    SetOutPath "$APP_INSTALL_DIR"
    File osvr_server.ico
    File osvr_logo.ico
    File ${distroDirectory}\${README_FILE}
    SetOutPath "$APP_INSTALL_DIR\${CORE_DIRX}\bin"
    File "${distroDirectory}\osvr_config_HDK_2X_default.json"
    File "${distroDirectory}\osvr_config_HDK_1X_default.json"
    ; SetOutPath "C:\OSVR"
    ; File "${distroDirectory}\HDK13_10mm_client.json"
    ; File "${distroDirectory}\HDK20_11mm_client.json"
    ; File osvr_user_settings.json
    ; used to facilitate Synapse uninstall
    SetOutPath "$APP_INSTALL_DIR\${CORE_DIRX}\bin\displays"
    File "${distroDirectory}\HDK20_11mm_client.json"
    File "${distroDirectory}\OSVR_HDK_2_0_with_mesh.json"
    ${StrRep} $forwardPath "$APP_INSTALL_DIR\${CORE_DIRX}\bin\displays" "\" "/"
    !insertmacro _ReplaceInFile "OSVR_HDK_2_0_with_mesh.json" "??PLACEHOLDER_ROOT" $forwardPath
    SetOutPath "$APP_INSTALL_DIR"
    File rzUninstaller.xml
;  SectionEnd
SectionEnd
 
;------------------------------------------------------------------------------------------
;
;
Section "!OSVR Tray App" TraySection
  ${If} $TRAY_INSTALL == "true"
    ; install tray app
    SetOutPath "$APP_INSTALL_DIR\${TRAY_DIR}"
    File /r /x . "${distroDirectory}\${TRAY_DIR}\*.*"
    ; Make tray run at startup
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Run\" "OSVR_TrayApp" "$APP_INSTALL_DIR\${TRAY_DIR}\${TRAY_APP}"
    ; start Tray app now
    ExecShell "" "$APP_INSTALL_DIR\${TRAY_DIR}\${TRAY_APP}"
    CreateShortCut "$SMPROGRAMS\OSVR\OSVR Tray App.lnk" "$APP_INSTALL_DIR\${TRAY_DIR}\${TRAY_APP}" "" "$APP_INSTALL_DIR\osvr_logo.ico"
  ${Endif}
SectionEnd

;------------------------------------------------------------------------------------------
;
;
Section "!OSVR Control Panel Interface" CPISection
  ${If} $CPI_INSTALL == "true"
    SetOutPath "$APP_INSTALL_DIR\${CPI_DIR}"
    File /r /x . "${distroDirectory}\${CPI_DIR}\*.*"
    CreateShortCut "$SMPROGRAMS\OSVR\OSVR CPI.lnk" "$APP_INSTALL_DIR\${CPI_DIR}\${CPI_APP}" "" "$APP_INSTALL_DIR\osvr_logo.ico"
    Exec '$APP_INSTALL_DIR\${CPI_DIR}\EnableOSVRDirectMode.exe'
  ${Endif}
 SectionEnd

;------------------------------------------------------------------------------------------
;
;
Section "!OSVR Sample Scene" SampleSceneSection
  ${If} $SAMPLESCENE_INSTALL == "true"
    SetOutPath "$APP_INSTALL_DIR\${SAMPLESCENE_DIR}"
    File /r /x . "${distroDirectory}\${SAMPLESCENE_DIR}\*.*"
    CreateShortCut "$SMPROGRAMS\OSVR\OSVR Sample Scene.lnk" "$APP_INSTALL_DIR\${SAMPLESCENE_DIR}\${SAMPLESCENE_APP}" "" "$APP_INSTALL_DIR\osvr_logo.ico"
  ${Endif}
 SectionEnd

;------------------------------------------------------------------------------------------
;
;
Section "!OSVR Tracker View" TrackerViewerSection
  ${If} $TRACKER_INSTALL == "true"
    SetOutPath "$APP_INSTALL_DIR\${TRACKER_DIR}"
    File /r /x . "${distroDirectory}\${TRACKER_DIR}\*.*"
    CreateShortCut "$SMPROGRAMS\OSVR\OSVR Tracker View.lnk" "$APP_INSTALL_DIR\${TRACKER_DIR}\${TRACKER_APP}" "" "$APP_INSTALL_DIR\osvr_logo.ico"
  ${Endif}
SectionEnd

;------------------------------------------------------------------------------------------
;
;
;Section "!OSVR Render Manager" RenderManagerSection
;     SetOutPath "$APP_INSTALL_DIR\${RENDERMANAGER_DIR}"
;     File /r /x . "${distroDirectory}\${RENDERMANAGER_DIR}\*.*"
;     Exec '$APP_INSTALL_DIR\${RENDERMANAGER_DIR}\EnableOSVRDirectMode.exe'
;SectionEnd

;------------------------------------------------------------------------------------------
;
;
Section "!OSVR-SteamVR Drivers" SteamVRSection
     SetOutPath "$APP_INSTALL_DIR\${STEAMVR_DIR}"
     File /r /x . "${distroDirectory}\${STEAMVR_DIR}\*.*"
     File "register_osvr_driver.cmd"
     File "unregister_osvr_driver.cmd"
     ; install the driver into the steam area
     Exec '$APP_INSTALL_DIR\${STEAMVR_DIR}\register_osvr_driver.cmd'
SectionEnd

;------------------------------------------------------------------------------------------
;
;
Section "!OSVR HDK Drivers" HDKDriverSection
  SetOutPath "$APP_INSTALL_DIR"
  
  File "${distroDirectory}\${DRIVER_PACKAGE_20_EXE}"
  ; plain Exec call...
  Exec '$APP_INSTALL_DIR\${DRIVER_PACKAGE_20_EXE}'

  File "${distroDirectory}\${DRIVER_PACKAGE_EXE}"
  ; plain Exec call...
  Exec '$APP_INSTALL_DIR\${DRIVER_PACKAGE_EXE}'
  ; Pop $0 ; return value - process exit code or error or STILL_ACTIVE (0x103).
  ; MessageBox MB_OK "HDKInstaller Exit code $0"
SectionEnd

;------------------------------------------------------------------------------------------
;
;
Section -FinishSection
  SetShellVarContext all
  ; Copy over default config file to the run directory
  CreateDirectory "$APPDATA\OSVR"
  CopyFiles "$APP_INSTALL_DIR\$CORE_DIR\bin\osvr_server_config.json" "$APPDATA\OSVR\osvr_server_config.json"
  CopyFiles "osvr_user_settings.json" "$APPDATA\OSVR\osvr_user_settings.json"
  AccessControl::GrantOnFile "$APPDATA\OSVR" "Everyone" "FullAccess"

  ;Give full access to all users in the system
  ;AccessControl::GrantOnFile "$APP_INSTALL_DIR" "(S-1-5-32-545)" "FullAccess"
  AccessControl::GrantOnFile "$APP_INSTALL_DIR" "Everyone" "FullAccess"

   ${TimeStamp} $0
  LogEx::Write true true "$0:Creating uninstaller $APP_INSTALL_DIR"

 ;Create local uninstaller
  setOutPath "$APP_INSTALL_DIR"
  WriteUninstaller "$APP_INSTALL_DIR\${LOCAL_UNINSTALLER_NAME}"
  
  ;----------------------------------------------------------------------------------------------------
  ;----------------------------------------------------------------------------------------------------
  ; Synapse integration for uninstall cleanup...
  ; check if Synapse list exists
  IfFileExists '$APPDATA\Razer\Synapse\ProductUpdates\UpdaterWorkList.current.xml' write_osvr_synapse_uninstaller skip_osvr_synapse_uninstaller

  write_osvr_synapse_uninstaller:
  CreateDirectory "$APPDATA\Razer\Synapse\ProductUpdates\Uninstallers\RazerOSVRServices"
  WriteUninstaller "$APPDATA\Razer\Synapse\ProductUpdates\Uninstallers\RazerOSVRServices\${LOCAL_UNINSTALLER_NAME}"
  CopyFiles "RzUninstaller.xml" "$APPDATA\Razer\Synapse\ProductUpdates\Uninstallers\RazerOSVRServices\rzUninstaller.xml"

  skip_osvr_synapse_uninstaller:
 
 
  ${TimeStamp} $0
  LogEx::Write true true "$0:Setting up shortcuts"

  ; point the new shortcut at the program uninstaller
  CreateShortCut "$SMPROGRAMS\OSVR\OSVR Uninstall.lnk" "$APP_INSTALL_DIR\${LOCAL_UNINSTALLER_NAME}" "" "$APP_INSTALL_DIR\osvr_logo.ico"

  ; finish setting up the rest of the shortcuts for the service...
  ; only install shortcuts if we are doing a service install
  ${If} $SERVER_ONLY_INSTALL == "true"
    ; we want to just install the shortcut to the regular stand-alone server
    setOutPath "$APP_INSTALL_DIR\$CORE_DIR\bin"
    CreateShortCut "$SMPROGRAMS\OSVR\OSVR Server.lnk" "$APP_INSTALL_DIR\$CORE_DIR\bin\osvr_server.exe" "" "$APP_INSTALL_DIR\osvr_server.ico"
    ;CreateShortCut "$SMPROGRAMS\OSVR\video_calibration.lnk" "$APP_INSTALL_DIR\$CORE_DIR\bin\${VIDEO_CALIBRATION_TOOL}" "" "$APP_INSTALL_DIR\osvr_server.ico"


  ${Else}
    ; otherwise we install and startup service
    CreateShortCut "$SMPROGRAMS\OSVR\osvr_service_stop.lnk" "$APP_INSTALL_DIR\$CORE_DIR\bin\osvr_services.exe" "-stop" "$APP_INSTALL_DIR\osvr_server.ico"
    ShellLink::SetRunAsAdministrator "$SMPROGRAMS\OSVR\osvr_service_stop.lnk"
    Pop $0
    CreateShortCut "$SMPROGRAMS\OSVR\osvr_service_start.lnk" "$APP_INSTALL_DIR\$CORE_DIR\bin\osvr_services.exe" "-start" "$APP_INSTALL_DIR\osvr_server.ico"
    ShellLink::SetRunAsAdministrator "$SMPROGRAMS\OSVR\osvr_service_start.lnk"
    Pop $0
    ; install and startup service
    ${TimeStamp} $0
    LogEx::Write true true "$0:Finished with install"
    ${TimeStamp} $0
    LogEx::Write true true "$0:Installing service"
    nsExec::ExecToStack /timeout=5000 '$APP_INSTALL_DIR\$CORE_DIR\bin\${SERVICE_FILENAME} -install'
    ${TimeStamp} $0
    LogEx::Write true true "$0:Starting service"
    ; start service by default
    nsExec::ExecToStack /timeout=5000 '$APP_INSTALL_DIR\$CORE_DIR\bin\${SERVICE_FILENAME} -start'
  ${Endif}

  ${TimeStamp} $0
  LogEx::Write true true "$0:Setting up Run registry"

  WriteRegStr HKLM "Software\OSVR" "InstallationDirectory"        "$APP_INSTALL_DIR\"
  WriteRegStr HKLM "Software\OSVR" "InstalledVersion"             "${CCVERSION}"
 
  ; set up environment variables
  ; include for some of the windows messages defines
  !include "winmessages.nsh"
  ; HKLM (all users) vs HKCU (current user) defines
   ${TimeStamp} $0
  LogEx::Write true true "$0:Setting up Environment variables"

  !define env_hklm 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
  !define env_hkcu 'HKCU "Environment"'
  ; set variable
  WriteRegExpandStr ${env_hklm} "OSVR_INSTALL_DIR" "$APP_INSTALL_DIR\"
  ; make sure windows knows about the change
  ${TimeStamp} $0
  LogEx::Write true true "$0:Broadcasting change"
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\osvr_server" "DisplayName" "OSVR Setup"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\osvr_server" "DisplayVersion" "${CCVERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\osvr_server" "UninstallString" "$\"$APP_INSTALL_DIR\${LOCAL_UNINSTALLER_NAME}$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\osvr_server" "QuietUninstallString" "$\"$APP_INSTALL_DIR\${LOCAL_UNINSTALLER_NAME}$\" /S"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\osvr_server" "DisplayIcon" "$\"$APP_INSTALL_DIR\osvr_server.ico$\""
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\osvr_server" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\osvr_server" "NoRepair" 1
 
  LogEx::Close
SectionEnd

#------------------------------------------------------------------------------------------
# Uninstaller

Function un.onInit
	SetShellVarContext all

	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanantly remove ${PRODUCT_NAME}?" IDOK next
		Abort
	next:
	!InsertMacro VerifyUserIsAdmin
FunctionEnd

Section "Uninstall"
  SetShellVarContext all
  SetAutoClose true
  LogEx::Init "$TEMP\osvr_log.txt"
  
  ; get install directory
  ReadRegStr $0 "HKLM" "Software\OSVR" "InstallationDirectory"
    ${If} ${Errors}
		Strcpy $APP_INSTALL_DIR "$PROGRAMFILES\OSVR"
	${Else}
		Strcpy $APP_INSTALL_DIR $0
	${Endif}

  ${TimeStamp} $0
  LogEx::Write true true "$0:Uninstall start $APP_INSTALL_DIR"

  ; Stop and Uninstall the service
  ${TimeStamp} $0
  LogEx::Write true true "$0:Stopping service $APP_INSTALL_DIR\$CORE_DIR\bin\${SERVICE_FILENAME}"
  nsExec::ExecToStack /timeout=5000 '$APP_INSTALL_DIR\$CORE_DIR\bin\${SERVICE_FILENAME} -stop'
  ${TimeStamp} $0
  LogEx::Write true true "$0:Uninstalling service"
  nsExec::ExecToStack /timeout=5000 '$APP_INSTALL_DIR\$CORE_DIR\bin\${SERVICE_FILENAME} -uninstall'

  ; Kill all possible running apps and services so we can get a clean uninstall
  !InsertMacro KillExe "${APP_EXE}"
  !InsertMacro KillExe "${TRACKER_APP}"
  !InsertMacro KillExe "${TRAY_APP}"
  !InsertMacro KillExe "${CPI_APP}"
  !InsertMacro KillExe "${SAMPLESCENE_APP}"

  ;MessageBox MB_OK "nsProcess::Unload$\n$\n"
  ${nsProcess::Unload}

  ; delete driver from the SteamVR area
  ; install the driver into the steam area
  ; must run from the directory where the driver is located
  SetOutPath '$APP_INSTALL_DIR\${STEAMVR_DIR}'
  ExecWait 'unregister_osvr_driver.cmd'
  SetOutPath '$PROGRAMFILES'

  ; Clean up environment variables
  ; delete variable
  DeleteRegValue ${env_hklm} "OSVR_INSTALL_DIR"
  ; make sure windows knows about the change
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  ${TimeStamp} $0
  LogEx::Write true true "$0:Cleaning up registry"
  
  ; Delete Tray app from run registry
  
  DeleteRegKey HKLM "Software\OSVR\"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Run\OSVR_TrayApp"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" 
 
  ${TimeStamp} $0
  LogEx::Write true true "$0:Cleaning up start menu"
  Delete "$SMPROGRAMS\OSVR\OSVR Server.lnk"
  Delete "$SMPROGRAMS\OSVR\OSVR Uninstall.lnk"
  RMDIR /r  "$SMPROGRAMS\OSVR"
  
  ; Wait for everything to close down
  Sleep 1000 
  ; Delete the app folder and app data folder
  
  ${TimeStamp} $0
  LogEx::Write true true "$0:Deleting directories"
  Delete "$APP_INSTALL_DIR\${LOCAL_UNINSTALLER_NAME}"
  ${If} $APP_INSTALL_DIR == "$PROGRAMFILES\OSVR\"
      RMDIR /r $APP_INSTALL_DIR
  ${Else}
      RMDIR /r $APP_INSTALL_DIR\${CORE_64_DIR}
      RMDIR /r $APP_INSTALL_DIR\${CORE_32_DIR}
      RMDIR /r $APP_INSTALL_DIR\${CPI_DIR}
      RMDIR /r $APP_INSTALL_DIR\${TRACKER_DIR}
      RMDIR /r $APP_INSTALL_DIR\${TRAY_DIR}
      RMDIR /r $APP_INSTALL_DIR\${SAMPLESCENE_DIR}
 ;     RMDIR /r $APP_INSTALL_DIR\${RENDERMANAGER_DIR}
      RMDIR /r $APP_INSTALL_DIR\${STEAMVR_DIR}
  ${Endif}
  RMDIR /r $APPDATA\OSVR
  
  ; initialize the driver’s path
  Var /GLOBAL UNINSTDIR
  StrCpy $UNINSTDIR '$APPDATA\Razer\Synapse\ProductUpdates\Uninstallers\Razer_OSVR_Driver'
 
  ; run the driver’s uninstaller in silent mode
  ${TimeStamp} $0
  LogEx::Write true true "$0:Running RazerOSVRUninstaller.exe"
  nsExec::Exec '"$UNINSTDIR\RazerOSVRUninstaller.exe" /S'
 
  ; check if Synapse list exists
  IfFileExists '$APPDATA\Razer\Synapse\ProductUpdates\UpdaterWorkList.current.xml' remove_from_worklist ignore_worklist

  remove_from_worklist:
  ; remove service and driver component’s entry in Synapse list
  nsExec::Exec '$APPDATA\Razer\Synapse\ProductUpdates\Uninstallers\Razer OSVR Driver\wlEdit\wlEdit.exe -pEmily -n"Razer OSVR Service" -d'

  ignore_worklist: 
  
  ${TimeStamp} $0
  LogEx::Write true true "$0:Finished uninstall"
  LogEx::Close /NOUNLOAD
SectionEnd

LangString DESC_CoreSection ${LANG_ENGLISH} "Core OSVR runtime components."
LangString DESC_TraySection ${LANG_ENGLISH} "Tray application for quick launching of utilities."
LangString DESC_CPISection ${LANG_ENGLISH} "Control Panel Interface for managing the server and your OSVR HDK."
LangString DESC_SampleSceneSection ${LANG_ENGLISH} "Sample VR application to test your setup."
LangString DESC_TrackerViewerSection ${LANG_ENGLISH} "Utility application to visualize OSVR data streams."
;LangString DESC_RenderManagerSection ${LANG_ENGLISH} "Libraries and test applications related to OSVR Render Manager."
LangString DESC_SteamVRSection ${LANG_ENGLISH} "SteamVR drivers enabling use with OSVR."
LangString DESC_HDKDriverSection ${LANG_ENGLISH} "OSVR Device Drivers."


!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${CoreSection} $(DESC_CoreSection)
  !insertmacro MUI_DESCRIPTION_TEXT ${TraySection} $(DESC_TraySection)
  !insertmacro MUI_DESCRIPTION_TEXT ${CPISection} $(DESC_CPISection)
  !insertmacro MUI_DESCRIPTION_TEXT ${SampleSceneSection} $(DESC_SampleSceneSection)
  !insertmacro MUI_DESCRIPTION_TEXT ${TrackerViewerSection} $(DESC_TrackerViewerSection)
 ; !insertmacro MUI_DESCRIPTION_TEXT ${RenderManagerSection} $(DESC_RenderManagerSection)
  !insertmacro MUI_DESCRIPTION_TEXT ${SteamVRSection} $(DESC_SteamVRSection)
  !insertmacro MUI_DESCRIPTION_TEXT ${HDKDriverSection} $(DESC_HDKDriverSection)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Set languages (first is default language)
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_RESERVEFILE_LANGDLL

VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "OSVR Runtime Setup"
VIProductVersion ${productVersion}
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "OSVR"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright OSVR"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "OSVR Apps, Services and Runtime installer"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" ${CCVERSION}
