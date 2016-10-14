; ---------------------
;       osvr_includes.nsh
; ---------------------
;
; A few simple macros to handle miscellaneous functions for install.
;
;
; TimeStamp provides the current time stamp, useful for logging purposes
; CheckFree space
; $0 - space required in kb
; $1 - path to check
; $2 - 0 = ignore quotas, 1 = obey quotas
; trashes $2
;
; VerifyUserIsAdmin checks that the installer will have the correct permission levels
;
;

!ifndef ___OSVR_INCLUDES__NSH___
!define ___OSVR_INCLUDES__NSH___

;--------------------------------
### TimeStamp
!ifndef TimeStamp
    !define TimeStamp "!insertmacro _TimeStamp"
    !macro _TimeStamp FormatedString
        !ifdef __UNINSTALL__
            Call un.__TimeStamp
        !else
            Call __TimeStamp
        !endif
        Pop ${FormatedString}
    !macroend

!macro __TimeStamp UN
Function ${UN}__TimeStamp
    ClearErrors
    ## Store the needed Registers on the stack
        Push $0 ; Stack $0
        Push $1 ; Stack $1 $0
        Push $2 ; Stack $2 $1 $0
        Push $3 ; Stack $3 $2 $1 $0
        Push $4 ; Stack $4 $3 $2 $1 $0
        Push $5 ; Stack $5 $4 $3 $2 $1 $0
        Push $6 ; Stack $6 $5 $4 $3 $2 $1 $0
        Push $7 ; Stack $7 $6 $5 $4 $3 $2 $1 $0
        ;Push $8 ; Stack $8 $7 $6 $5 $4 $3 $2 $1 $0

    ## Call System API to get the current system Time
        System::Alloc 16
        Pop $0
        System::Call 'kernel32::GetLocalTime(i) i(r0)'
        System::Call '*$0(&i2, &i2, &i2, &i2, &i2, &i2, &i2, &i2)i (.r1, .r2, n, .r3, .r4, .r5, .r6, .r7)'
        System::Free $0

        IntFmt $2 "%02i" $2
        IntFmt $3 "%02i" $3
        IntFmt $4 "%02i" $4
        IntFmt $5 "%02i" $5
        IntFmt $6 "%02i" $6

    ## Generate Timestamp
        ;StrCpy $0 "YEAR=$1$\nMONTH=$2$\nDAY=$3$\nHOUR=$4$\nMINUITES=$5$\nSECONDS=$6$\nMS$7"
        StrCpy $0 "$1$2$3$4$5$6.$7"

    ## Restore the Registers and add Timestamp to the Stack
        ;Pop $8  ; Stack $7 $6 $5 $4 $3 $2 $1 $0
        Pop $7  ; Stack $6 $5 $4 $3 $2 $1 $0
        Pop $6  ; Stack $5 $4 $3 $2 $1 $0
        Pop $5  ; Stack $4 $3 $2 $1 $0
        Pop $4  ; Stack $3 $2 $1 $0
        Pop $3  ; Stack $2 $1 $0
        Pop $2  ; Stack $1 $0
        Pop $1  ; Stack $0
        Exch $0 ; Stack ${TimeStamp}

FunctionEnd
!macroend
!insertmacro __TimeStamp ""
!insertmacro __TimeStamp "un."
!endif
###########

;--------------------------------
;Check free space

!define sysGetDiskFreeSpaceEx 'kernel32::GetDiskFreeSpaceExA(t, *l, *l, *l) i'

; $0 - space required in kb
; $1 - path to check
; $2 - 0 = ignore quotas, 1 = obey quotas
; trashes $2
Function CheckSpaceFunc
  IntCmp $2 0 ignorequota
  ; obey quota
  System::Call '${sysGetDiskFreeSpaceEx}(r1,.r2,,.)'
  goto converttokb
  ; ignore quota
  ignorequota:
  System::Call '${sysGetDiskFreeSpaceEx}(r1,.,,.r2)'
  converttokb:
  ; convert the large integer byte values into managable kb
  System::Int64Op $2 / 1024
  Pop $2
  ; check space
  System::Int64Op $2 > $0
  Pop $2
FunctionEnd

;--------------------------------
;
;
!Macro VerifyUserIsAdmin
  UserInfo::GetAccountType
  pop $0
  ${If} $0 != "admin" ;Require admin rights on NT4+
        messageBox mb_iconstop "Administrator rights required!"
        setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
        quit
  ${EndIf}
!MacroEnd

;--------------------------------
;
;
!Macro CommandParameter parameterName parameterValue
  Strcpy ${parameterValue} "true"
  ${GetParameters} $R0
  ${GetOptions} $R0 "${parameterName}" $R1
  ; always true except if the parameter name exists AND is set to false
  ${If} $R1 == "false"
	Strcpy ${parameterValue} "false"
  ${Endif}
!MacroEnd
  
;--------------------------------
; Macro to look for and kill an executable. Necessary for a clean uninstall (running exes will not permit directory deletion).
;
!Macro KillExe WhichExe
 ${TimeStamp} $0
  LogEx::Write true true "$0:Finding ${WhichExe}"
    ; Kill process first before uninstalling if one is running
	${nsProcess::FindProcess} "${WhichExe}" $R0
	;MessageBox MB_OK "nsProcess::FindProcess$\n$\n Errorlevel: [$R0]"

	${If} $R0 == 0
		${TimeStamp} $0
		LogEx::Write true true "$0:Killing ${WhichExe}"
		DetailPrint "${WhichExe} is running. Closing it down"
		${nsProcess::KillProcess} "${WhichExe}" $R0
		;MessageBox MB_OK "nsProcess::KillProcess$\n$\n Errorlevel: [$R0]"
		DetailPrint "Waiting for ${WhichExe} to close"
		Sleep 1000
	${Else}
		DetailPrint "${WhichExe} was not found to be running proceeding with uninstall."
	${EndIf}
!MacroEnd


!include StrRep.nsh

Function RIF

  ClearErrors  ; want to be a newborn

  Exch $0      ; REPLACEMENT
  Exch
  Exch $1      ; SEARCH_TEXT
  Exch 2
  Exch $2      ; SOURCE_FILE

  Push $R0     ; SOURCE_FILE file handle
  Push $R1     ; temporary file handle
  Push $R2     ; unique temporary file name
  Push $R3     ; a line to sar/save
  Push $R4     ; shift puffer

  IfFileExists $2 +1 RIF_error      ; knock-knock
  FileOpen $R0 $2 "r"               ; open the door

  GetTempFileName $R2               ; who's new?
  FileOpen $R1 $R2 "w"              ; the escape, please!

  RIF_loop:                         ; round'n'round we go
    FileRead $R0 $R3                ; read one line
    IfErrors RIF_leaveloop          ; enough is enough
    RIF_sar:                        ; sar - search and replace
      Push "$R3"                    ; (hair)stack
      Push "$1"                     ; needle
      Push "$0"                     ; blood
      Call StrRep               ; do the bartwalk
      StrCpy $R4 "$R3"              ; remember previous state
      Pop $R3                       ; gimme s.th. back in return!
      StrCmp "$R3" "$R4" +1 RIF_sar ; loop, might change again!
    FileWrite $R1 "$R3"             ; save the newbie
  Goto RIF_loop                     ; gimme more

  RIF_leaveloop:                    ; over'n'out, Sir!
    FileClose $R1                   ; S'rry, Ma'am - clos'n now
    FileClose $R0                   ; me 2

    Delete "$2.old"                 ; go away, Sire
    Rename "$2" "$2.old"            ; step aside, Ma'am
    Rename "$R2" "$2"               ; hi, baby!

    ClearErrors                     ; now i AM a newborn
    Goto RIF_out                    ; out'n'away

  RIF_error:                        ; ups - s.th. went wrong...
    SetErrors                       ; ...so cry, boy!

  RIF_out:                          ; your wardrobe?
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
  Pop $2
  Pop $0
  Pop $1

FunctionEnd

!macro _ReplaceInFile SOURCE_FILE SEARCH_TEXT REPLACEMENT
  Push "${SOURCE_FILE}"
  Push "${SEARCH_TEXT}"
  Push "${REPLACEMENT}"
  Call RIF
!macroend

; Push $filenamestring (e.g. 'c:\this\and\that\filename.htm')
; Push "\"
; Call StrSlash
; Pop $R0
; ;Now $R0 contains 'c:/this/and/that/filename.htm'
Function StrSlash
  Exch $R3 ; $R3 = needle ("\" or "/")
  Exch
  Exch $R1 ; $R1 = String to replacement in (haystack)
  Push $R2 ; Replaced haystack
  Push $R4 ; $R4 = not $R3 ("/" or "\")
  Push $R6
  Push $R7 ; Scratch reg
  StrCpy $R2 ""
  StrLen $R6 $R1
  StrCpy $R4 "\"
  StrCmp $R3 "/" loop
  StrCpy $R4 "/"
loop:
  StrCpy $R7 $R1 1
  StrCpy $R1 $R1 $R6 1
  StrCmp $R7 $R3 found
  StrCpy $R2 "$R2$R7"
  StrCmp $R1 "" done loop
found:
  StrCpy $R2 "$R2$R4"
  StrCmp $R1 "" done loop
done:
  StrCpy $R3 $R2
  Pop $R7
  Pop $R6
  Pop $R4
  Pop $R2
  Pop $R1
  Exch $R3
FunctionEnd

!macro _StrSlash ORIGINAL_STRING TO_REPLACE
  Push "${ORIGINAL_STRING}"
  Push "${TO_REPLACE}"
  Call StrSlash
  Pop $R0
!macroend

!endif # !___OSVR_INCLUDES__NSH___