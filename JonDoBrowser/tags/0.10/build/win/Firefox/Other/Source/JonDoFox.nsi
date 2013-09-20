;Copyright 2007-2008 Jondos GmbH

;Developer Philipp Kaplycz

;p.kaplycz@jondos.de

;Website: http://anonymous-proxy-servers.net


;=== BEGIN: BASIC INFORMATION
!define NAME "JonDoFox"
!define ELEVATIONTITLE "${NAME}"
!define SHORTNAME "JonDoFoxPortable"
!define VERSION "2.6.8.0"
!define FILENAME "JonDoFox"
!define FF_VERSION "15.0"
!define FF_URL "http://download.mozilla.org/?product=firefox-${FF_VERSION}&os=win&lang="
!define CHECKRUNNING "JonDoFoxPortable.exe"
!define CLOSENAME "JonDoFox, Portable Edition"
!define ADDONSDIRECTORYPRESERVE "App\firefox\plugins"
!define INSTALLERVERSION "1.1.1.0"
!define INSTALLERCOMMENTS "For additional details, visit anonymous-proxy-servers.net" ; changed by JonDos GmbH 2009
!define INSTALLERADDITIONALTRADEMARKS "Firefox is a Trademark of The Mozilla Foundation. " ;end this entry with a period and a space if used
!define INSTALLERLEGALCOPYRIGHT "JonDos GmbH"
!define LICENSEAGREEMENT "eula.rtf"
; NOTE: For no license agreement, comment out the above line by placing a semicolon at the start of it
;=== END: BASIC INFORMATION

Var /GLOBAL FFInstalled
Var /GLOBAL Error
Var /GLOBAL PathSelectionText

Var /GLOBAL ProfilePath
Var /GLOBAL ProfileExtensionPath

Var /GLOBAL ProgramPath
Var JonDoFoxDesktopInstalled
Var /GLOBAL Update
Var /GLOBAL IsJonDoFox
Var /GLOBAL PrefsFileHandle
Var /GLOBAL i

Var /GLOBAL j

Var /GLOBAL k

Var /GLOBAL l

Var /GLOBAL m

Var /GLOBAL PORTABLEINSTALL
Var /GLOBAL PROGRAMINSTALL

Var /GLOBAL JONDOPORTABLE_PATH

Var /GLOBAL InstDirOkay

Var /GLOBAL ExtensionGUID
Var /GLOBAL ExtensionName
Var PORTABLEAPPSINSTALL
Var InstMode

Var hKey

Var install

Var JonDoInstallation

Var AppdataFolder

Var SMProgramsFolder

Var TempDir

Var FF_DOWNLOAD_URL

Var /GLOBAL IsRoot

Var /GLOBAL varMakeUserAdministrator

Var /GLOBAL varPortableAppsPath

Var /GLOBAL varFOUNDPORTABLEAPPSPATH

Var /GLOBAL varAskAgain

Var /GLOBAL httpsForcedDomains

Var /GLOBAL httpsForcedDomainsExceptions

;=== Runtime Switches
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
#SetCompress Off
SetDatablockOptimize On
CRCCheck on
AutoCloseWindow True
RequestExecutionLevel user

# Installer attributes
XPStyle on
ShowInstDetails show

;=== Program Details
Name "${NAME}"
OutFile "..\..\..\${FILENAME}.paf.exe"
InstallDir "\${SHORTNAME}"
Caption "${NAME}"
VIProductVersion "${VERSION}"
VIAddVersionKey ProductName "${NAME}"
VIAddVersionKey Comments "${INSTALLERCOMMENTS}"
VIAddVersionKey CompanyName "JonDos GmbH"  ; changed by JonDos GmbH 2008
VIAddVersionKey LegalCopyright "${INSTALLERLEGALCOPYRIGHT}"
VIAddVersionKey FileDescription "${NAME}"
VIAddVersionKey FileVersion "${VERSION}"
VIAddVersionKey ProductVersion "${VERSION}"
VIAddVersionKey InternalName "${NAME}"
VIAddVersionKey LegalTrademarks "${INSTALLERADDITIONALTRADEMARKS}PortableApps.com is a Trademark of Rare Ideas, LLC. JonDo is a trademark of JonDos GmbH."
VIAddVersionKey OriginalFilename "${FILENAME}.paf.exe"
VIAddVersionKey JonDoFoxInstallerVersion "${INSTALLERVERSION}"

!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "Software\JonDoFox"
!define MUI_LANGDLL_REGISTRY_VALUENAME "InstallerLanguage"

# Included files
!include Sections.nsh
!include MUI.nsh
!include FileFunc.nsh
!include RemoveFilesAndSubDirs.nsh
!include WordFunc.nsh
!include TextFunc.nsh

!insertmacro GetOptions
!insertmacro GetFileAttributes
!insertmacro GetParent
!insertmacro GetDrives
!insertmacro GetParameters
!insertmacro WordReplace

# MUI defines
!define MUI_ICON "appicon.ico"

!define MUI_CUSTOMFUNCTION_GUIINIT CustomGUIInit
!define MUI_COMPONENTSPAGE_SMALLDESC

; MUI Settings / Icons
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"

; MUI Settings / Header
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_LEFT
#!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis.bmp"
!define MUI_HEADERIMAGE_BITMAP "blau2.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "${NSISDIR}\Contrib\Graphics\Header\orange-uninstall-r.bmp"

; MUI Settings / Wizard
#!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\blau.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "blau.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange-uninstall.bmp"

###############################
!macro SecUnSelect SecId
  SectionSetFlags ${SecId} 0
!macroend

!define UnSelectSection '!insertmacro SecUnSelect'
###################################


/* If we have to enable or disable a button we are going to use this macro */

!macro EnableCtrl dlg id state
  push $0
  GetDlgItem $0 ${dlg} ${id}
  EnableWindow $0 ${state}
  pop $0
!macroend


# Installer pages
!define MUI_PAGE_CUSTOMFUNCTION_PRE SkipPageInElvModePreCB
!insertmacro MUI_PAGE_WELCOME

!insertmacro MUI_PAGE_LICENSE EULA.rtf

!define MUI_PAGE_CUSTOMFUNCTION_PRE comPre
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE comPost
!insertmacro MUI_PAGE_COMPONENTS


!define MUI_PAGE_CUSTOMFUNCTION_PRE dirPre
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE dirPost
!define MUI_DIRECTORYPAGE_TEXT_TOP $PathSelectionText
!insertmacro MUI_PAGE_DIRECTORY


#!define MUI_PAGE_CUSTOMFUNCTION_PRE instPre Otherwise the logic gets called
#twice!!
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE EditProfilesIni
!insertmacro MUI_PAGE_INSTFILES


!define MUI_PAGE_CUSTOMFUNCTION_LEAVE FinishedInstall

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION FinishRun
!insertmacro MUI_PAGE_FINISH


# Installer languages
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "English"

/* In UAC_JonDo.nsh we have added some german language support. Because all
the warnings and error messages which may occur during elevating were, of 
course, just in english. Well, and if we want language support we have to load
the UAC_JonDo.nsh after we included the relevant language-macro. */

!include UAC_JonDo.nsh

!include JonDoFox-Lang-English.nsh
!include JonDoFox-Lang-German.nsh

############################################################

!macro SetMode IsAdmin
!if "${IsAdmin}" > 0
        SetShellVarContext all
	StrCpy $InstMode 1
	StrCpy $hKey HKLM
	!else
	SetShellVarContext current
	StrCpy $InstMode 0
	StrCpy $hKey HKCU
	!endif
!macroend

############################################################

##======================================================================================================================================================
##                                                                           .onInit
##======================================================================================================================================================

Function un.onInit
   !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

Function .onInit
   !insertmacro SetMode 0
   ${GetParameters} $R9
   ${GetOptions} "$R9" "-INSTALLATION=" $0
   IfErrors jondo_checking_done 0
   StrCmp $0 "portable" 0 jondo_desktop
      ${GetOptions} "$R9" "-INSTALLPATH=" $0
      ${WordReplace} "$0" "JonDoPortable" "" "+" $0
      StrCpy $INSTDIR "$0${SHORTNAME}"
      ${GetOptions} "$R9" "-LANGUAGE=" $0
      StrCpy $LANGUAGE "$0"
      StrCpy $JonDoInstallation "portable"
      Goto jondo_checking_done
   jondo_desktop:
      ${GetOptions} "$R9" "-LANGUAGE=" $0
      StrCpy $LANGUAGE "$0"
      StrCpy $JonDoInstallation "desktop"
      StrCpy $PORTABLEINSTALL "false"
   jondo_checking_done:
   ClearErrors
   ${GetOptions} "$R9" UAC $0 ;look for special /UAC:???? parameter (sort of undocumented)
   ${Unless} ${Errors}
	UAC::IsAdmin
	${If} $0 < 1 
		SetErrorLevel 666 ;special return value for outer instance so it knows we did not have admin rights
			Quit 
		${EndIf}
	!insertmacro SetMode 1
	StrCpy $InstMode 2
   ${EndIf}
	
/* We have to check whether the user is already elevated and if so jump to the
end of this function. Otherwise we wouldn't get a silent second installer. And
we would waste time in checking whether we find PortableApps because the user
has already declared that he does not want to install the portable JonDoFox. */

    ${If} $InstMode > 1
       StrCpy $FFInstalled "false"
       StrCpy $PROGRAMINSTALL "false"
       Goto start_elevated
    ${EndIf}
          ${GetOptions} "$CMDLINE" "/DESTINATION=" $R0
          StrCpy $PORTABLEAPPSINSTALL "false"
          StrCpy $PORTABLEINSTALL "false"
          StrCpy $IsRoot "false"

          ${If} $R0 != ""
                StrCpy $PORTABLEAPPSINSTALL "true"
                StrCpy $PORTABLEINSTALL "true"
                StrCpy $INSTDIR "$R0${SHORTNAME}"
                StrCpy $JONDOPORTABLE_PATH "$R0JonDoPortable"
          ${Else}
                Call SearchPortableApps
                StrCpy $INSTDIR $varPortableAppsPath
          ${EndIf}
          StrCmp $JonDoInstallation "" 0 start_elevated
          InitPluginsDir
          StrCpy $Error "false"

        !insertmacro MUI_LANGDLL_DISPLAY
    start_elevated:
FunctionEnd


Function CustomGUIInit

           ${If} $InstMode >= 2
	         ${UAC.GetOuterInstanceHwndParent} $0
	         ${If} $0 <> 0 
		       System::Call /NOUNLOAD "*(i,i,i,i)i.r1"
		       System::Call /NOUNLOAD 'user32::GetWindowRect(i $0,i r1)i.r2'
		       ${If} $2 <> 0
			     System::Call /NOUNLOAD "*$1(i.r2,i.r3)"
			     System::Call /NOUNLOAD 'user32::SetWindowPos(i $hwndParent,i0,ir2,ir3,i0,i0,i 4|1)'
		       ${EndIf}
		       ShowWindow $hwndParent ${SW_SHOW}
		       ShowWindow $0 ${SW_HIDE} ;hide outer instance installer window
		       System::Free $1
		 ${EndIf}
	    ${EndIf}
FunctionEnd

##======================================================================================================================================================
##                                                                           JFPortable
##======================================================================================================================================================


InstType $(InstTypeLite)                     # 1 
InstType $(InstTypeProfileLite)              # 2 
InstType /NOCUSTOM

Section /o $(JonDoFox) JFPortable
SectionIn 1 
        ${If} $PROFILE == ""
              MessageBox MB_ICONEXCLAMATION|MB_OK $(FF30Win9x)
        ${EndIf}
        SetOutPath $ProgramPath
        SetOverwrite on

        File /r /x .svn /x Source "..\..\*.*"

        # Copying the JonDoFoxPortable.ini in order to allow a desktop and
        # a portable Firefox running in parallel
        
	File "JonDoFoxPortable.ini"
        
        ${If} $LANGUAGE == "1031"          # german
              File /r /x .svn "..\..\..\FirefoxByLanguage\deFirefoxPortablePatch\*.*"
        ${ElseIf} $LANGUAGE == "1033"      # english
        			File /r /x .svn "..\..\..\FirefoxByLanguage\enFirefoxPortablePatch\*.*"
        ${EndIf}
        
SectionEnd


##======================================================================================================================================================
##                                                                           Profile
##======================================================================================================================================================


Section - ProfileCore
SectionIn 1 2 

        SetOutPath $ProfilePath
        SetOverwrite on
        File appicon.ico
        File /r /x .svn /x extensions /x bookmarks_de.html /x bookmarks_en.html /x prefs_portable_de.js /x prefs_portable_en.js /x places.sqlite_de /x places.sqlite_en "..\..\..\full\profile\*.*"
        ${If} $LANGUAGE == "1031"          # german
              File "/oname=places.sqlite" "..\..\..\full\profile\places.sqlite_de"
              ${If} $PROGRAMINSTALL == "true"
                    File "/oname=prefs.js" "..\..\..\full\profile\prefs_portable_de.js"
#File "/oname=extensions.sqlite" "..\..\..\full\profile\extensions.sqlite_portable"
              ${Else} 
                    # Copying the help file and the images, but why?
                    File /r /x .svn /x App /x Other "..\..\..\FirefoxByLanguage\deFirefoxPortablePatch\*.*"
              ${EndIf}
        ${ElseIf} $LANGUAGE == "1033"      # english
              File "/oname=places.sqlite" "..\..\..\full\profile\places.sqlite_en"
              ${If} $PROGRAMINSTALL == "true"
                    File "/oname=prefs.js" "..\..\..\full\profile\prefs_portable_en.js"
#File "/oname=extensions.sqlite" "..\..\..\full\profile\extensions.sqlite_portable"
              ${Else}
                    File /r /x .svn /x App /x Other "..\..\..\FirefoxByLanguage\enFirefoxPortablePatch\*.*"
              ${EndIf}
        ${EndIf}

SectionEnd


Section /o - ProfileCoreUpdate              #Update

        SetOutPath $ProfilePath
        SetOverwrite on
        
        File /r /x .svn /x extensions /x bookmarks_en.html /x bookmarks_de.html /x prefs_portable_de.js /x prefs_portable_de.js "..\..\..\full\profile\*.*"
        ${If} $LANGUAGE == "1031" 
        ${AndIf} $PROGRAMINSTALL == "true"
              File "/oname=prefs.js" "..\..\..\full\profile\prefs_portable_de.js"   
        ${ElseIf} $LANGUAGE == "1031"
        ${AndIf} $PROGRAMINSTALL == "false"
                File /r /x .svn /x App /x Other "..\..\..\FirefoxByLanguage\deFirefoxPortablePatch\*.*"
        ${ElseIf} $LANGUAGE == "1033"
        ${AndIf} $PROGRAMINSTALL == "true"
              File "/oname=prefs.js" "..\..\..\full\profile\prefs_portable_en.js"
        ${ElseIf} $LANGUAGE == "1033"
        ${AndIf} $PROGRAMINSTALL == "false" 
                File /r /x .svn /x App /x Other "..\..\..\FirefoxByLanguage\enFirefoxPortablePatch\*.*"
        ${EndIf}

SectionEnd


##======================================================================================================================================================
##                                                                           Required Extensions
##======================================================================================================================================================


SectionGroup /e $(JonDoFoxProfile) ProfileGroup

        Section "Adblock Plus" AdblockPlus
        SectionIn 1 2 
                StrCpy $ExtensionName "Adblock Plus"

                SetOutPath "$ProfileExtensionPath"
                SetOverwrite on

                File /r /x .svn "..\..\..\full\profile\extensions\{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi"

        SectionEnd


        Section "Cookie Monster" CMonster
        SectionIn 1 2         
                StrCpy $ExtensionGUID "{45d8ff86-d909-11db-9705-005056c00008}"
                StrCpy $ExtensionName "Cookie Monster"

                SetOutPath "$ProfileExtensionPath\$ExtensionGUID"
                SetOverwrite on

                File /r /x .svn "..\..\..\full\profile\extensions\{45d8ff86-d909-11db-9705-005056c00008}\*.*"

        SectionEnd

        Section "HTTPS-Everywhere" HTTPSEverywhere
        SectionIn 1 2 
                StrCpy $ExtensionGUID "https-everywhere@eff.org"
                StrCpy $ExtensionName "HTTPS Everywhere"

                SetOutPath "$ProfileExtensionPath\$ExtensionGUID"
                SetOverwrite on

                File /r /x .svn "..\..\..\full\profile\extensions\https-everywhere@eff.org\*.*"

        SectionEnd
        

        Section "JonDoFox" JonDoFox
        SectionIn 1 2 
        
                StrCpy $ExtensionName "JonDoFox"

                SetOutPath "$ProfileExtensionPath"
                SetOverwrite on

                File /r /x .svn "..\..\..\full\profile\extensions\{437be45a-4114-11dd-b9ab-71d256d89593}.xpi"

        SectionEnd


        Section "NoScript" NoScript
        SectionIn 1 2
        
                StrCpy $ExtensionName "NoScript"

                SetOutPath "$ProfileExtensionPath"
                SetOverwrite on

                File /r /x .svn "..\..\..\full\profile\extensions\{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi"

        SectionEnd


        Section "UnPlug" UnPlug
        SectionIn 1 2
        
                StrCpy $ExtensionGUID "unplug@compunach"
                StrCpy $ExtensionName "UnPlug"

                SetOutPath "$ProfileExtensionPath\$ExtensionGUID"
                SetOverwrite on

                File /r /x .svn "..\..\..\full\profile\extensions\unplug@compunach\*.*"

        SectionEnd


        Section /o "ProfileSwitcher" ProfileSwitcher
        SectionIn 2 
                
                StrCpy $ExtensionGUID "{fa8476cf-a98c-4e08-99b4-65a69cb4b7d4}"
                StrCpy $ExtensionName "ProfileSwitcher"

                SetOutPath "$ProfileExtensionPath\$ExtensionGUID"
                SetOverwrite on

                File /r /x .svn "..\..\..\full\profile\extensions\{fa8476cf-a98c-4e08-99b4-65a69cb4b7d4}\*.*"

        SectionEnd

SectionGroupEnd

Section Uninstall
       StrCpy $FFInstalled "false"
       # Hack to get the the proper message box popped up (indicating that
       # the profile gets only properly deleted if FF is not running
       StrCpy $Update "true"
       StrCpy $k 0
       StrCpy $l 0
       MessageBox MB_ICONEXCLAMATION|MB_YESNO $(DeletingProfile) IDYES deleting
       Quit
     deleting:
       StrCpy $ProfilePath "$APPDATA\Mozilla\Firefox\Profiles\JonDoFox"
       Call un.CheckFirefoxRunning
       StrCpy $AppdataFolder "$APPDATA"
       Call un.GetLastProfilCounter
       Pop $i
       StrCpy $j "$i"
     loop:
       ReadINIStr $0 $APPDATA\Mozilla\Firefox\profiles.ini Profile$i Name
       StrCmp $0 "JonDoFox" deleting_ini searching_ini
       deleting_ini:
         DeleteINISec $APPDATA\Mozilla\Firefox\profiles.ini Profile$i
         IntOp $k $k + 1

        #GEORG: Normally, we could jump to deleting_sm now. But maybe the
        #       user has deleted the JonDoFox-files before by hand but has
        #       not adapted the profiles.ini as well. So we check all entries to
        #       be sure that all JonDoFox stuff is gone. War mit altem Installer noch möglich und vermutlich in den Fällen, wo "mittlere" Profile gelöscht werden!
        # Goto deleting_sm

       searching_ini:
         ${If} $i == 0 
            Goto deleting_sm
         ${EndIf}
         IntOp $i $i - 1
         Goto loop
       deleting_sm:
       Call un.GetLastProfilCounter
       Pop $i
       IntOp $m $k + $i
       ${If} $m < $j
         IntOp $i $i + 1
        loop_adapting_profiles:
         ClearErrors
         ReadINIStr $0 $APPDATA\Mozilla\Firefox\profiles.ini Profile$i Name
         IfErrors 0 +5
           IntOp $i $i + 1
           IntOp $l $l + 1
           IntCmp $i $j loop_deleting_sections 0
           Goto loop_adapting_profiles
         ReadINIStr $1 $APPDATA\Mozilla\Firefox\profiles.ini Profile$i IsRelative
         ReadINIStr $2 $APPDATA\Mozilla\Firefox\profiles.ini Profile$i Path
         ClearErrors
         ReadINIStr $3 $APPDATA\Mozilla\Firefox\profiles.ini Profile$i Default
         IfErrors 0 +2
         StrCpy $3 "nodefault"
         IntOp $i $i - 1
         IntOp $i $i - $l
         WriteINIStr $APPDATA\Mozilla\Firefox\profiles.ini Profile$i Name $0
         WriteINIStr $APPDATA\Mozilla\Firefox\profiles.ini Profile$i IsRelative $1
         WriteINIStr $APPDATA\Mozilla\Firefox\profiles.ini Profile$i Path $2
         StrCmp $3 "nodefault" +2 0
         WriteINIStr $APPDATA\Mozilla\Firefox\profiles.ini Profile$i Default $3
         IntOp $i $i + 2
         IntOp $i $i + $l
         ${If} $i < $j
           Goto loop_adapting_profiles
         ${Else}
          loop_deleting_sections:
           IntOp $i $i - 1
           DeleteINISec $APPDATA\Mozilla\Firefox\profiles.ini Profile$i
           IntOp $k $k - 1
           IntCmp $k 0 0 0 loop_deleting_sections
         ${EndIf}
       ${EndIf}
       RMDir /r $SMPROGRAMS\JonDoFox
       RMDir /r $APPDATA\Mozilla\Firefox\Profiles\JonDoFox
       DeleteRegKey HKCU "Software\JonDoFox"
SectionEnd

##===========================================================================
## End sections
##===========================================================================

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${JFPortable} $(DescJFPortable)
  !insertmacro MUI_DESCRIPTION_TEXT ${AdblockPlus} $(DescAdblockPlus)
  !insertmacro MUI_DESCRIPTION_TEXT ${CMonster} $(DescCMonster)
  !insertmacro MUI_DESCRIPTION_TEXT ${HTTPSEverywhere} $(DescHTTPSEverywhere)
  !insertmacro MUI_DESCRIPTION_TEXT ${UnPlug} $(DescUnPlug)
  !insertmacro MUI_DESCRIPTION_TEXT ${JonDoFox} $(DescJonDoFox)  
  !insertmacro MUI_DESCRIPTION_TEXT ${NoScript} $(DescNoScript)
  !insertmacro MUI_DESCRIPTION_TEXT ${ProfileSwitcher} $(DescProfileSwitcher)  
!insertmacro MUI_FUNCTION_DESCRIPTION_END


##======================================================================================================================================================
##                                                                           Functions
##======================================================================================================================================================

Function SearchPortableApps

	ClearErrors
	${GetDrives} "HDD+FDD" GetDrivesCallBack
        StrCmp $varFOUNDPORTABLEAPPSPATH "" DefaultDestination
        StrCpy $varPortableAppsPath "$varFOUNDPORTABLEAPPSPATH\${SHORTNAME}"
        Goto done

	DefaultDestination:
                ${If} $PROFILE == ""
                      StrCpy $varPortableAppsPath "$PROGRAMFILES\${SHORTNAME}\"
                ${Else}
		      StrCpy $varPortableAppsPath "$PROFILE\${SHORTNAME}\"
                ${EndIf}
done:

FunctionEnd


Function GetDrivesCallBack
	;=== Skip usual floppy letters
	StrCmp $8 "FDD" "" CheckForPortableAppsPath
	StrCmp $9 "A:\" End
	StrCmp $9 "B:\" End

	CheckForPortableAppsPath:
		IfFileExists "$9PortableApps" "" End
			StrCpy $varFOUNDPORTABLEAPPSPATH "$9PortableApps"
                        StrCpy $PORTABLEINSTALL "true"
                        StrCpy $JONDOPORTABLE_PATH "$9PortableApps\JonDoPortable"

	End:
		Push $0
FunctionEnd

Function RequiredSelections

         IntOp $0 ${SF_SELECTED} | ${SF_RO}
         SectionSetFlags ${AdblockPlus} $0
   	 SectionSetFlags ${CMonster} $0
         SectionSetFlags ${HTTPSEverywhere} $0
         SectionSetFlags ${JonDoFox} $0
         SectionSetFlags ${NoScript} $0
         SectionSetFlags ${UnPlug} $0
         SectionSetFlags ${ProfileSwitcher} $0
FunctionEnd



##======================================================================================================================================================
##                                                                           dirPre
##======================================================================================================================================================


Function dirPre
        ${If} $InstMode > 1
              SetShellVarContext all
                              FileOpen $0 $APPDATA\UserElevating_tmp r
                              FileRead $0 $TempDir
                              FileClose $0
                              Delete $APPDATA\UserElevating_tmp
              SetShellVarContext current
        ${ElseIf} $InstMode == 1
              StrCpy $TempDir "$TEMP"
        ${EndIf}
                     
        ${If} $InstMode > 0
            ${If} $PROGRAMINSTALL == "false"
            ${AndIf} $FFInstalled == "false"
               ExecWait '"$TempDir\Firefox Setup ${FF_VERSION}.exe"'
               StrCpy $FFInstalled "true"
               Delete '$TempDir\Firefox Setup ${FF_VERSION}.exe'
               Call instPre
               Abort
            ${ElseIf} $PROGRAMINSTALL == "false"
               Abort
            ${EndIf}
        ${ElseIf} $PROGRAMINSTALL == "false"
               Abort
        ${EndIf}
FunctionEnd


##======================================================================================================================================================
##                                                                           dirPost
##======================================================================================================================================================


Function dirPost


        ${If} $PROGRAMINSTALL == "true"

              ${If} $IsRoot == "false"

                      # check if admin rights are needed
                      Push $INSTDIR                      
                      Call CheckFolder                                           
                      ${If} $InstDirOkay == "Read only"
                            StrCpy $Error "true"

                            # Ask for Admin Rights

                            MessageBox MB_ICONQUESTION|MB_YESNO $(YouNeedAdminRights) IDYES yes IDNO no

                            no:
                            StrCpy $varMakeUserAdministrator "false"
                            
                            StrCpy $R9 "0"
                            Call RelGotoPage
                            Abort

                            Goto next

                            yes:
                            StrCpy $varMakeUserAdministrator "true"

                            next:
                      ${EndIf}
                      
                     
                ${EndIf}

        ${ElseIf} $PROGRAMINSTALL == "false"
            
    
                ${If} $FFInstalled == "false"  # check user select folder

                                          
                      ${If} $IsRoot == "false"

                              Push $INSTDIR
                              Call CheckFolder                                             # CheckFolder

                              ${If} $InstDirOkay == "Read only"
                                    StrCpy $Error "true"

                                    # Ask for Admin Rights

                                    MessageBox MB_ICONQUESTION|MB_YESNO $(YouNeedAdminRights) IDYES yes2 IDNO no2

                                    no2:
                                    StrCpy $varMakeUserAdministrator "false"

                                    StrCpy $R9 "0"
                                    Call RelGotoPage
                                    Abort

                                    Goto next2

                                    yes2:
                                    StrCpy $varMakeUserAdministrator "true"

                                    next2:

                              ${EndIf}

                        ${EndIf}

                ${EndIf}

        ${EndIf}

        Call instPre

FunctionEnd

##======================================================================================================================================================
##                                                                           .onVerifyInstDir
##======================================================================================================================================================


Function .onVerifyInstDir


        ${If} $PROGRAMINSTALL == "false"                                            # Profile install:

                ${If} $FFInstalled == "false"  # check user select folder

                      # Check Folder

                      IfFileExists $INSTDIR\App\firefox\firefox.exe okay wrong

                      okay:
                            StrCpy $Error "false"

                             Goto done

                      wrong:                            # Folder invalid, back to Folderselection Window
                      
                            
                            # Call CheckInstallingFirefox
                            #StrCpy $Error "true"
                            #Abort

                ${EndIf}
                
        ${EndIf}


        done:
        
FunctionEnd


Function CheckInstallingFirefox
      IfFileExists "$TEMP\Firefox Setup ${FF_VERSION}.exe" 0 download_check
      MessageBox MB_YESNO $(FirefoxFound) IDYES ff_yes IDNO download_check
    ff_yes:
      UAC::IsAdmin
      ${If} $0 < 1
            Call ElevatingUser
      ${Else}
            StrCpy $InstMode "1"
      ${EndIf}
      Goto install_done  
    download_check:
      MessageBox MB_ICONEXCLAMATION|MB_YESNO $(FirefoxDownloading) IDYES ff_down_yes IDNO done
    ff_down_yes:
      ${If} $LANGUAGE == "1031"
            StrCpy $FF_DOWNLOAD_URL "${FF_URL}de"
      ${ElseIf} $LANGUAGE == "1033"
            StrCpy $FF_DOWNLOAD_URL "${FF_URL}en-US"
      ${EndIf}
    loop:
      InetLoad::load /TIMEOUT=30000 /NOPROXY /BANNER "JonDoFox - Firefox Download" $(FirefoxDownload) $FF_DOWNLOAD_URL "$TEMP\Firefox Setup ${FF_VERSION}.exe" /END
      Pop $R1
      StrCmp $R1 "OK" +2
      MessageBox MB_ICONEXCLAMATION|MB_YESNO $(DownloadErrorRetry) IDYES loop IDNO done
      UAC::IsAdmin
      ${If} $0 < 1
            Call ElevatingUser
      ${Else}
            StrCpy $InstMode "1"
      ${EndIf}
      Goto install_done
    done:
      Abort
    install_done:
FunctionEnd

#######################################################

Function SkipPageInElvModePreCB
  ${IfThen} $InstMode > 1 ${|} Abort ${|} ;skip this page so we get to the mode selection page
  ${If} $JonDoInstallation != ""
        Abort
  ${EndIf}
FunctionEnd

#######################################################

Function ElevatingUser
        StrCpy $1 $APPDATA
        StrCpy $2 $SMPROGRAMS
        StrCpy $3 $TEMP
        SetShellVarContext all
        FileOpen $0 $APPDATA\UserElevating_app w
        FileWrite $0 "$1"
        FileClose $0
        FileOpen $0 $APPDATA\UserElevating_smp w
        FileWrite $0 "$2"
        FileClose $0
        FileOpen $0 $APPDATA\UserElevating_tmp w
        FileWrite $0 "$3"
        FileClose $0
        SetShellVarContext current
        System::Call /NoUnload 'user32::GetWindowText(i $HwndParent,t.R1,i ${NSIS_MAX_STRLEN})' ;get original window title
	System::Call /NoUnload 'user32::SetWindowText(i $HwndParent,t "${ELEVATIONTITLE}")' ;set out special title
	StrCpy $2 "" ;reset special return, only gets set when sub process is executed, not when user cancels
	!insertmacro EnableCtrl $HWNDParent 1 0 ;Disable next button, just because it looks good ;)
	${UAC.RunElevatedAndProcessMessages}
	!insertmacro EnableCtrl $HWNDParent 1 1
	System::Call 'user32::SetWindowText(i $HwndParent,t "$R1")' ;restore title
	${If} $2 = 666 ;our special return, the new process was not admin after all 
		MessageBox MB_ICONEXCLAMATION $(AdminLogin)
		Abort 
		${ElseIf} $0 = 1223 ;cancel
		Abort
		${EndIf} 
	Quit ;We now have a new process, the install will continue there, we have nothing left to do here
FunctionEnd


Function .OnInstFailed
    UAC::Unload ;Must call unload!
FunctionEnd

Function .OnInstSuccess
    UAC::Unload ;Must call unload!
FunctionEnd


##======================================================================================================================================================
##                                                                           CheckFolder
##======================================================================================================================================================


Function CheckFolder

        Pop $0

        Push $R0
        Push $R1
        Push $R2

        StrCpy $R0 $0
        #StrCpy $R0 "$INSTDIR"
        
        StrCpy $R2 "some_unique_name"

        loop:
          StrLen $R1 "$R0"
          StrCmp $R1 0 pathbad
          IfFileExists "$R0" next 0

          Push $0
          Push $R0
          Call isRoot
          Pop $0

          ${If} $0 == "true"
              Pop $0
              Goto next
          ${ElseIf} $0 == "false"
              Pop $0
              Goto parentLoop
          ${EndIf}

        next:
        ${GetFileAttributes} "$R0" "DIRECTORY" $R1
        StrCmp $R1 0 parentLoop
#        ${GetFileAttributes} "$R0" "READONLY" $R1
#        StrCmp $R1 1 pathbad
        ClearErrors
        IfFileExists "$R0\$R2" pathgood 0
        CreateDirectory "$R0\$R2"
        IfErrors pathbad 0
        RMDir "$R0\$R2"
        Goto pathgood

        parentLoop:

        Push $0

        StrCpy $0 $R0 1 -1       # Append "\"

        ${If} $0 != "\"
              StrCpy $R0 "$R0\"
        ${EndIf}

        ${GetParent} "$R0" "$R0"
        Goto loop

        pathbad:
        StrCpy $InstDirOkay "Read only"
        Goto done

        pathgood:
        StrCpy $InstDirOkay "okay"
        
        Pop $R2
        Pop $R1
        Pop $R0

done:
FunctionEnd


Function CheckFirefoxInstalled            # 2

# Get Firefox Folder from Registry, just to see if it is installed
        ClearErrors
        ReadRegStr $0 HKLM "SOFTWARE\Mozilla\Mozilla Firefox" 'CurrentVersion'
        
        StrCmp $0 "" NotInstalled 0

        ClearErrors
        ReadRegStr $0 HKLM "SOFTWARE\Mozilla\Mozilla Firefox\$0\Main" 'Install Directory'
        

# Debug:
        #StrCpy $0 "" # Simulates Firefox not installed

        StrCmp $0 "" 0 Installed

        NotInstalled:
                  StrCpy $FFInstalled "false"
                  Goto ende

        Installed:
        
                  MessageBox MB_ICONQUESTION|MB_YESNO $(FirefoxInstallationDetected) IDYES yes IDNO no

                  no:
                  StrCpy $FFInstalled "false"
                  StrCpy $PROGRAMINSTALL "true"
                  SectionSetFlags ${JFPortable} ${SF_SELECTED}
                  Goto next
                  
                  yes:
                  StrCpy $FFInstalled "true"

                  Call instPre

                  #Abort # Dont show MUI_PAGE_DIRECTORY
                  
                  next:
        ende:
        
FunctionEnd


!macro CheckFirefoxRunning_macro un
   Function ${un}CheckFirefoxRunning                    # 3
      Push $5
      # We just test for firefox.exe as the option of having a desktop
      # and a portable version running in parallel disables the opportunity
      # to check for JonDoFoxPortable.exe. That's quite inconvenient if one
      # has to quit Firefox in order to install the portable version but
      # probably safer.
      Push "firefox.exe"
      processwork::existsprocess
      Pop $5
      IntCmp $5 1 is1 is0 is0
      is1:
        # Is FF installed at all? (Maybe there is just a porable one available)
        StrCmp $FFInstalled "true" 0 profilecheck
        StrCmp $PROGRAMINSTALL "true" 0 mb         

        # Checking here only whether we try to overwrite the open JonDoFox
        # profile.
        profilecheck:
        IfFileExists "$ProfilePath\parent.lock" mb done
        mb: 
          StrCpy $Update "true"
          MessageBox MB_ICONQUESTION|MB_YESNO $(FirefoxDetected) IDYES quitFF IDNO Exit
        quitFF:
	       Push "firefox.exe"
	       processwork::KillProcess
	       Sleep 1000
        
        is0:
        # Everything is fine
          Goto done
                 
        Exit:
             ${If} $FFInstalled == "false"
               ${AndIf} $Update == "true"
                 MessageBox MB_ICONEXCLAMATION|MB_OK $(JonDoFoxDeleteError)
             ${EndIf}
             StrCpy $R9 "-1"
             Call ${un}RelGotoPage
             Abort

        done:
   FunctionEnd
!macroend

!insertmacro CheckFirefoxRunning_macro ""
!insertmacro CheckFirefoxRunning_macro "un."


##======================================================================================================================================================
##                                                                           SearchProfileFolder
##======================================================================================================================================================


Function SearchProfileFolder


    IfFileExists $INSTDIR\Data\settings\JonDoFoxPortableSettings.ini exists 0      # exists ini?

    # NO
                 StrCpy $Error ""
                 IfFileExists $INSTDIR\Data\*.* +3 0        # Create Data
                 StrCpy $Error "$INSTDIR\Data\"
                 CreateDirectory $INSTDIR\Data
                 IfErrors createerror

                 StrCpy $Error ""
                 IfFileExists $INSTDIR\Data\settings\*.* +3 0        # Create Data\settings
                 StrCpy $Error "$INSTDIR\Data\settings\"
                 CreateDirectory $INSTDIR\Data\settings
                 IfErrors createerror

                 StrCpy $Error "$INSTDIR\Data\settings\JonDoFoxPortableSettings.ini"
                 FileOpen $0 $INSTDIR\Data\settings\JonDoFoxPortableSettings.ini w   # create File
                 FileClose $0
                 IfErrors createerror

                 StrCpy $Error "$INSTDIR\Data\settings\JonDoFoxPortableSettings.ini" # write profile to ini
                 WriteINIStr $INSTDIR\Data\settings\JonDoFoxPortableSettings.ini JonDoFoxPortableSettings LastProfileDirectory $INSTDIR\Data\profile
                 IfErrors writeerror

exists:

                 StrCpy $Error "$INSTDIR\Data\settings\JonDoFoxPortableSettings.ini"
                 ReadINIStr $0 $INSTDIR\Data\settings\JonDoFoxPortableSettings.ini JonDoFoxPortableSettings LastProfileDirectory          # Get profile directory

                 IfErrors INIreaderror INIreadokay

                 INIreaderror:         # This could happen if Firefox-Portable is installed, but never started !!!

                 WriteINIStr $INSTDIR\Data\settings\JonDoFoxPortableSettings.ini JonDoFoxPortableSettings LastProfileDirectory $INSTDIR\Data\profile
                 IfErrors writeerror
                 ReadINIStr $0 $INSTDIR\Data\settings\JonDoFoxPortableSettings.ini JonDoFoxPortableSettings LastProfileDirectory          # Get profile directory again
                 IfErrors readerror

                 INIreadokay:

                 StrCpy $ProfilePath $0     # Save Profilepath
                 StrCpy $ProfileExtensionPath "$ProfilePath\extensions"
                 StrCpy $Error "false"

                 Goto done

createerror:

                 MessageBox MB_ICONEXCLAMATION|MB_ICONSTOP "Error, Can not create:$\n$Error"
                 Goto done

writeerror:

                 MessageBox MB_ICONEXCLAMATION|MB_ICONSTOP "Error, Can not write:$\n$Error"
                 Goto done

readerror:

                 MessageBox MB_ICONEXCLAMATION|MB_ICONSTOP "Error, Can not read:$\n$Error"
                 Goto done

done:

FunctionEnd


##======================================================================================================================================================
##                                                                           SearchProfileFolderWithoutPermissions
##======================================================================================================================================================


Function SearchProfileFolderWithoutPermissions

         # If writing is denied

    IfFileExists $INSTDIR\Data\settings\JonDoFoxPortableSettings.ini 0 INIreaderror      # exists ini?
    ReadINIStr $0 $INSTDIR\Data\settings\JonDoFoxPortableSettings.ini JonDoFoxPortableSettings LastProfileDirectory          # Get profile directory
    IfErrors INIreaderror INIreadokay
    
    INIreaderror:
    StrCpy $0 $INSTDIR\Data\profile
    
    INIreadokay:
    
    StrCpy $ProfilePath $0     # Save Profilepath
    StrCpy $ProfileExtensionPath "$ProfilePath\extensions"
    StrCpy $Error "false"

FunctionEnd

##======================================================================================================================================================
##                                                                           instPre
##======================================================================================================================================================


Function instPre

        StrCpy $Update "false"
        

        # Check if Profile exists -> then update only

          ${If} $PROGRAMINSTALL == "false"    # only profile

                  ${If} $FFInstalled == "true"

                        # Check if folder "JonDoFox" exists
                        # if yes, update only
                        # else normal install
                        ${If} $InstMode > 1
                              SetShellVarContext all
                              FileOpen $0 $APPDATA\UserElevating_app r
                              FileRead $0 $AppdataFolder
                              FileClose $0
                              Delete $APPDATA\UserElevating_app
                              FileOpen $0 $APPDATA\UserElevating_smp r
                              FileRead $0 $SMProgramsFolder
                              FileClose $0
                              Delete $APPDATA\UserElevating_smp
                              SetShellVarContext current
                        Goto +3
                        ${EndIf}
                        StrCpy $AppdataFolder "$APPDATA"
                        StrCpy $SMProgramsFolder "$SMPROGRAMS"
                        StrCpy $ProfilePath "$AppdataFolder\Mozilla\Firefox\Profiles\JonDoFox"
                        StrCpy $ProfileExtensionPath "$AppdataFolder\Mozilla\Firefox\Profiles\JonDoFox\extensions"
 
                        Call CheckFirefoxRunning 
                        IfFileExists $ProfilePath\*.* update create

                  ${ElseIf} $FFInstalled == "false"

                        ${If} $varMakeUserAdministrator == "true"
                              Call SearchProfileFolderWithoutPermissions
                              Goto done
                        ${Else}
                              Call SearchProfileFolder
                        ${EndIf}

                        IfFileExists $ProfilePath\*.* 0 create

                        # selected firefox is a JonDoFox
                        StrCmp $IsJonDoFox "true" update 0
                        
                        Call Update

                        Goto done

                  ${EndIf}


                  update:

                          StrCpy $Update "true"
                          
                          Call Update
                          
                          Goto done

                  create:
                          ClearErrors
                          CreateDirectory $ProfilePath
                          IfErrors 0 +3
                          MessageBox MB_ICONEXCLAMATION|MB_OK $(CreateFolderError)
                          Quit



        ${ElseIf} $PROGRAMINSTALL == "true"
                  ReadRegStr $0 HKCU "SOFTWARE\JonDoFox" 'InstallerLanguage' 
                  StrCmp $0 "" NotInstalled 0
                    StrCpy $JonDoFoxDesktopInstalled "true"
                    Goto +2
                  NotInstalled: 
                    StrCpy $JonDoFoxDesktopInstalled "false"
                  
                  IfFileExists $INSTDIR\App\firefox\firefox.exe update2 install

                  update2:

                         Call SearchProfileFolder

                         StrCpy $ProgramPath $INSTDIR
                         
                         StrCpy $Update "true"
                         
                         Call CheckFirefoxRunning 

                         Call Update
                         StrCmp $IsJonDoFox "true" 0 install
                         # StrCpy $Update "true"  (Better do this before, as even if it is not jdf profile, bookmarks should be kept)
                         
                         Goto done

                  install:

                          StrCpy $ProgramPath $INSTDIR
                          StrCpy $ProfilePath $INSTDIR\Data\profile
                          StrCpy $ProfileExtensionPath "$ProfilePath\extensions"
                          
        ${EndIF}

done:


        ${If} $Update == "true"
                SectionSetFlags ${ProfileCoreUpdate} 1
                SectionSetFlags ${ProfileCore} 0
        ${Else}
                SectionSetFlags ${ProfileCoreUpdate} 0
                SectionSetFlags ${ProfileCore} 1
        ${EndIf}
        
        ${If} $varMakeUserAdministrator == "true"
                    #Call MakeUserAdministrator
        ${EndIf}
FunctionEnd

##======================================================================================================================================================
##                                                                           Update
##======================================================================================================================================================


Function Update

        Call ParsePrefsJS

        # selected firefox is a JonDoFox
        # StrCmp $IsJonDoFox "true" done BackupBookmarksCerts

        # BackupBookmarksCerts:

        MessageBox MB_ICONINFORMATION|MB_YESNO $(OverwriteProfile) IDYES updating IDNO Exit
        updating:

        nxs::Show /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /h 1 /can 0 /pos 0 /can 1 /marquee 40 /end
        IfFileExists $ProfilePath\BookmarkBackup\*.* +5
        CreateDirectory $ProfilePath\BookmarkBackup
        IfErrors Error
        CreateDirectory $ProfilePath\BookmarkBackup\bookmarkbackups
        IfErrors Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 10 /end 
        IfFileExists $ProfilePath\BookmarkBackup\bookmarkbackups\*.* +3
        CreateDirectory $ProfilePath\BookmarkBackup\bookmarkbackups
        IfErrors Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 20 /end
        
        IfFileExists $ProfilePath\BookmarkBackup\bookmarkbackups\bookmarks.html 0 +2
        Goto Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 30 /end

        IfFileExists $ProfilePath\BookmarkBackup\bookmarkbackups\places.sqlite 0 +2
        Goto Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 40 /end

        IfFileExists $ProfilePath\bookmarks.html 0 +3
        CopyFiles $ProfilePath\bookmarks.html $ProfilePath\BookmarkBackup
        IfErrors Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 50 /end

        IfFileExists $ProfilePath\places.sqlite 0 +3
        CopyFiles $ProfilePath\places.sqlite $ProfilePath\BookmarkBackup
        IfErrors Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 60 /end

        IfFileExists $ProfilePath\bookmarkbackups\*.* 0 +3
        CopyFiles $ProfilePath\bookmarkbackups\*.* $ProfilePath\BookmarkBackup\bookmarkbackups
        IfErrors Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 70 /end
        
        IfFileExists $TEMP\BookmarkBackup\*.* +3
        CreateDirectory $TEMP\BookmarkBackup
        IfErrors Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 80 /end

        IfFileExists $ProfilePath\BookmarkBackup\*.* 0 +3
        CopyFiles $ProfilePath\BookmarkBackup\*.* $TEMP\BookmarkBackup
        IfErrors Error

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 90 /end

	IfFileExists $ProfilePath\CertPatrol.sqlite 0 +3
        CopyFiles $ProfilePath\CertPatrol.sqlite $TEMP
	IfErrors Error

        # Now, we parse the prefs.js to extract the forced https domains.
        # and the accompanying exceptions. That is quite ugly but I did not find
        # a better way.
	IfFileExists $ProfilePath\prefs.js 0 done_httpsForcedBackup 
	FileOpen $0 $ProfilePath\prefs.js r
      loop:
	FileRead $0 $1
        StrCpy $2 $1 32 
        StrCmp $2 'user_pref("noscript.httpsForced"' found notfound
      notfound:
        StrCpy $3 $1 42
        StrCmp $3 'user_pref("noscript.httpsForcedExceptions"' found_Exceptions noExceptionsFound
      Goto loop
      found:
        StrCpy $httpsForcedDomains $1
        # Checking for httpsForcedExceptions as well
        Goto loop
      found_Exceptions:
        StrCpy $httpsForcedDomainsExceptions $1
        Goto done_httpsForcedbackup
      noExceptionsFound:
        StrCpy $3 $1 12
        # We need some kind of stop here otherwise the installer would get
        # stalled if there is no pref starting with
        # 'user_pref("noscript.httpsForced"'. 
        StrCmp $3 'user_pref("p' done_httpsForcedBackup loop
      done_httpsForcedBackup:
	IfErrors Error
	FileClose $0

        nxs::Update /NOUNLOAD "Backup" /top $(BackupBookmarksCerts) /pos 100 /end

        IfFileExists $ProfilePath\NoScriptSTS.db 0 +3
        CopyFiles $ProfilePath\NoScriptSTS.db $TEMP
	IfErrors Error 

        IfFileExists $ProfilePath\HTTPSEverywhereUserRules\*.* 0 +4
        CreateDirectory $TEMP\HTTPSEverywhereUserRules
        CopyFiles $ProfilePath\HTTPSEverywhereUserRules\*.* $TEMP\HTTPSEverywhereUserRules
        IfErrors Error

        nxs::Destroy
        
        Call DeleteProfile

        Goto done

          Error:
          
                  nxs::Destroy

                  MessageBox MB_ICONEXCLAMATION|MB_OK $(BackupError)

                  Quit

          Exit:

                  # Back to folder-selection page
                            StrCpy $varAskAgain "false"
                            ${If} $PROGRAMINSTALL == "true"
                              StrCpy $R9 "-1"
                            ${Else}
                              StrCpy $R9 "0"
                            ${EndIf}
                            Call RelGotoPage
                            Abort
                  
done:

FunctionEnd

##======================================================================================================================================================
##                                                                           DeleteProfile
##======================================================================================================================================================

Function DeleteProfile
    
      !insertmacro RemoveFilesAndSubDirs "$ProfilePath\"
         
FunctionEnd

##======================================================================================================================================================
##                                                                           RestoreBackup
##======================================================================================================================================================


Function RestoreBackup
ClearErrors
           IfFileExists $TEMP\BookmarkBackup\*.* 0 +2 
           CopyFiles "$TEMP\BookmarkBackup\*.*" $ProfilePath
           IfFileExists $TEMP\CertPatrol.sqlite 0 +2 
           CopyFiles "$TEMP\CertPatrol.sqlite" $ProfilePath
           IfFileExists $TEMP\NoScriptSTS.db 0 +2 
           CopyFiles "$TEMP\NoScriptSTS.db" $ProfilePath 
           IfFileExists $TEMP\HTTPSEverywhereUserRules\*.* 0 +2
           # We have a new profile here. Avoid overwriting new rules regarding
           # our domains with old ones. As CopyFiles is overwriting files
           # automatically we have to copy the new rules for our domain to the
           # temp folder first, ugh.
           CopyFiles $ProfilePath\HTTPSEverywhereUserRules\*.* "$TEMP\HTTPSEverywhereUserRules"
           CopyFiles "$TEMP\HTTPSEverywhereUserRules\*.*" $ProfilePath\HTTPSEverywhereUserRules
           # Adding the user chosen forced domains or exceptions
           IfFileExists "$ProfilePath\prefs.js" 0 httpsForcedDone
           StrCmp $httpsForcedDomains "" checkExceptions
           FileOpen $0 "$ProfilePath\prefs.js" a
           FileSeek $0 0 END
           FileWrite $0 "$\r$\n"
           FileWrite $0 $httpsForcedDomains
           FileWrite $0 "$\r$\n"
           FileClose $0
           checkExceptions:
           StrCmp $httpsForcedDomainsExceptions "" httpsForcedDone 
           FileOpen $0 "$ProfilePath\prefs.js" a
           FileSeek $0 0 END
           FileWrite $0 "$\r$\n"
           FileWrite $0 $httpsForcedDomainsExceptions
           FileWrite $0 "$\r$\n"
           FileClose $0 
           httpsForcedDone:

           IfErrors 0 done
	    MessageBox MB_ICONEXCLAMATION|MB_OK $(RestoreError)
 
           done:
        
FunctionEnd



Function ParsePrefsJS

        # prefs.js
        # search JonDoFox

        StrCpy $IsJonDoFox "false"

        FileOpen $PrefsFileHandle $ProfilePath\prefs.js r
        Push $PrefsFileHandle
        Push ''
        Push 'JonDoFox'
        Push 'anywhere'
        Call SearchInFile
        Pop $0
        FileClose $PrefsFileHandle


        StrCmp $0 yes 0 +3
        StrCpy $IsJonDoFox "true"
        Goto done

        StrCpy $IsJonDoFox "false"

        done:

FunctionEnd



Function EditProfilesIni

        ${If} $FFInstalled == "true"

              Call GetLastProfilCounter

              Pop $i
              StrCpy $j "$i"
              IntOp $j $j - 1
              ClearErrors
              WriteINIStr $AppdataFolder\Mozilla\Firefox\profiles.ini General StartWithLastProfile 0
              IfErrors writeerror
     loop:
         ClearErrors
         ReadINIStr $0 $AppdataFolder\Mozilla\Firefox\profiles.ini Profile$j Name
         IfErrors write_profileini
         StrCmp $0 "JonDoFox" done searching_ini
       searching_ini:
         ${If} $j == 0
            Goto write_profileini
         ${EndIf}
         IntOp $j $j - 1
         Goto loop
      
          write_profileini:
              WriteINIStr $AppdataFolder\Mozilla\Firefox\profiles.ini Profile$i Name JonDoFox
              IfErrors writeerror
              WriteINIStr $AppdataFolder\Mozilla\Firefox\profiles.ini Profile$i IsRelative 1
              IfErrors writeerror
              WriteINIStr $AppdataFolder\Mozilla\Firefox\profiles.ini Profile$i Path Profiles/JonDoFox
              IfErrors writeerror

              writeerror:

        ${EndIf}

        done:

        StrCpy $FFInstalled "done"

        ${If} $PROGRAMINSTALL == "false"

              CreateDirectory "$SMProgramsFolder\JonDoFox"
              CreateShortcut "$SMProgramsFolder\JonDoFox\$(^InstallLink).lnk" "$PROGRAMFILES\Mozilla Firefox\firefox.exe" "-P JonDoFox" "$ProfilePath\appicon.ico"
              CreateShortCut "$SMProgramsFolder\JonDoFox\$(^ProfilMLink).lnk" "$PROGRAMFILES\Mozilla Firefox\firefox.exe" "-P"
              SetOutPath $ProfilePath
              CreateShortCut "$SMProgramsFolder\JonDoFox\$(^UninstallLink).lnk" "$ProfilePath\uninstall.exe"
              ${If} $LANGUAGE == "1031"
                    StrCpy $0 "de"
              ${Else}
                    StrCpy $0 "en"
              ${EndIf}
              CreateShortCut "$SMProgramsFolder\JonDoFox\$(^HelpLink).lnk" "$PROGRAMFILES\Mozilla Firefox\firefox.exe" "-P JonDoFox $\"file:///$ProfilePath\help.html$\"" "noicon_ico" #otherwise the default one is used
              WriteUninstaller "$ProfilePath\uninstall.exe"

        ${EndIf}
        

FunctionEnd


!macro GetLastProfilCounter_macro un
   Function ${un}GetLastProfilCounter

        StrCpy $i 0

        start:
        FileOpen $PrefsFileHandle $AppdataFolder\Mozilla\Firefox\profiles.ini r
        Push $PrefsFileHandle
        Push ''
        Push '[Profile$i]'
        Push 'begin'
        Call ${un}SearchInFile
        Pop $0
        FileClose $PrefsFileHandle

        StrCmp $0 yes 0 +5
        StrCpy $0 $i
        IntOp $0 $0 + 1
        StrCpy $i $0
        Goto start

        Push $i

   FunctionEnd
!macroend

!insertmacro GetLastProfilCounter_macro ""
!insertmacro GetLastProfilCounter_macro "un."


Function comPre         # Reset wrong path error

         ${If} $InstMode > 1
               Abort
         ${EndIf}
         ${If} $PORTABLEINSTALL == "true"
         ${OrIf} $JonDoInstallation == "portable"
               SectionSetFlags ${JFPortable} ${SF_SELECTED}
               IntOp $0 0 | ${SF_RO}
               SectionSetFlags ${ProfileSwitcher} $0 
               ${If} $PORTABLEAPPSINSTALL == "true"
               ${OrIf} $JonDoInstallation == "portable"
                          StrCpy $PROGRAMINSTALL "true"
                          Abort
               ${EndIf}
               Goto +2
         ${EndIf}

         Call RequiredSelections

         StrCpy $Error "false"
         StrCpy $varAskAgain "true"
         ${If} $JonDoInstallation == "desktop"
               Call comPost
               Abort
         ${EndIf}
FunctionEnd

Function comPost
       
         StrCpy $varAskAgain "true"
         
          # Check if Portable is selected

                StrCpy $FFInstalled "false"

                SectionGetFlags ${JFPortable} $R0
                IntOp $R0 $R0 & ${SF_SELECTED}

                ${If} $R0 == ${SF_SELECTED}
                        StrCpy $PROGRAMINSTALL "true"
                        Goto goon
                ${EndIf}
                
                # Check if Firefox is installed

                StrCpy $PROGRAMINSTALL "false"

                # We know that the user has chosen the desktop version
                # thus...

                StrCpy $PORTABLEINSTALL == "false"
                 
                      ${If} $varAskAgain == "true"
                            Call CheckFirefoxInstalled     # -> 2
                      ${EndIf}

        goon:

                ${If} $FFInstalled == "false"  # Show MUI_PAGE_DIRECTORY, change text
                ${AndIf} $PROGRAMINSTALL == "false"
                      
                     Call CheckInstallingFirefox
                 
                    

                ${ElseIf} $FFInstalled == "false"

                      ${If} $Error == "false"

                        StrCpy $PathSelectionText $(SelectFirefoxPortable)

                      ${ElseIf} $Error == "true"

                        StrCpy $PathSelectionText $(SelectedFolderInvalid)
                        
                      ${EndIf}
                      
                ${EndIf}
FunctionEnd

!macro RelGotoPage_macro un
Function ${un}RelGotoPage
          IntCmp $R9 0 0 Move Move
            StrCmp $R9 "X" 0 Move
              StrCpy $R9 "120"

          Move:
          SendMessage $HWNDPARENT "0x408" "$R9" ""
FunctionEnd
!macroend

!insertmacro RelGotoPage_macro ""
!insertmacro RelGotoPage_macro "un."


Function FinishedInstall
        StrCmp $JonDoInstallation "" 0 finish_install
        ClearErrors
        ${If} $PROGRAMINSTALL == "true"
          ${AndIf} $PORTABLEINSTALL == "false"
             IfFileExists $PROFILE\JonDoPortable\*.* finish_install 0
             MessageBox MB_YESNO $(InstallingPortableJonDo) IDYES 0 IDNO finish_install
             StrCpy $install "portable"
        ${ElseIf} $PORTABLEINSTALL == "true"
             IfFileExists $JONDOPORTABLE_PATH\*.* finish_install 0
             MessageBox MB_YESNO $(InstallingPortableJonDo) IDYES 0 IDNO finish_install
             StrCpy $install "portable"
        ${Else}
             ClearErrors
             ReadRegStr $1 HKLM "Software\JonDo\Components" Main
             IfErrors 0 finish_install
             ClearErrors
             ReadRegStr $1 HKLM "Software\JAP\Components" Main
             IfErrors 0 finish_install
             MessageBox MB_ICONEXCLAMATION|MB_YESNO $(InstallingJonDo) IDYES 0 IDNO finish_install
             StrCpy $install "desktop"
        ${EndIf}
       loop:
        SetShellVarContext all
        InetLoad::load /TIMEOUT=30000 /NOPROXY /BANNER "JonDoFox - JonDo Download" $(JonDoDownload) https://anonymous-proxy-servers.net/downloads/JonDoSetup.paf.exe "$APPDATA\JonDoSetup.paf.exe" /END
        Pop $R0
        StrCmp $R0 "OK" +2
        MessageBox MB_ICONEXCLAMATION|MB_YESNO $(DownloadErrorRetry) IDYES loop IDNO finish_install
        ExecWait '"$APPDATA\JonDoSetup.paf.exe" -INSTALLATION=$install -INSTALLPATH=$INSTDIR -LANGUAGE=$LANGUAGE'
        Sleep 1000
        Delete $APPDATA\JonDoSetup.paf.exe
        SetShellVarContext current
       finish_install:
        ${If} $Update == "true"
              Call RestoreBackup
        ${EndIf}

        ${If} $PROGRAMINSTALL == "true"
          ${AndIf} $JonDoFoxDesktopInstalled == "false"
              DeleteRegKey HKCU "Software\JonDoFox"
              ExecShell "open" $INSTDIR
        ${ElseIf} $InstMode > 1
              GetFunctionAddress $0 InstallerLanguage
              UAC::ExecCodeSegment $0
        ${EndIf}
FunctionEnd

Function FinishRun
        ${If} $LANGUAGE == "1031"
              StrCpy $0 "de"
        ${ElseIf} $LANGUAGE == "1033"
              StrCpy $0 "en"
        ${EndIf}
        ${If} $PROGRAMINSTALL == "true"
              Exec "$INSTDIR\JonDoFoxPortable.exe"
        ${Else} 
              ${If} $FFInstalled == "done"
                 UAC::Exec '' '"$PROGRAMFILES\Mozilla Firefox\firefox.exe" -no-remote -P JonDoFox' '' ''
              ${EndIf}
        ${EndIf}
FunctionEnd

Function InstallerLanguage
        WriteRegStr HKCU "Software\JonDoFox" "InstallerLanguage" "$LANGUAGE"
FunctionEnd


!macro SearchInFile_macro un
   Function ${un}SearchInFile
        ; HOW USE
        ; FileOpen $1 'C:\WINNT\system32\drivers\etc\services' r
        ; Push $handle  ; handle of file (open in 'a' or 'r' mode)
        ; Push '#'      ; comments delimiter (All symbols more to the right
        ;               ; are ignored)
        ; Push 'gds_db' ; sample of search
        ;               ; push '' if comment_symbol are not defined
        ; Push 'no'     ; search mode. If 'begin' to search only from the
        ;               ; beginning of string
        ; Call SearchInFile
        ; Pop $0        ; Result of search: yes/no
        ;

        Exch $3 ; search mode
        Exch 3
        Exch $2 ; file handle
        Exch 2
        Exch $1 ; comments delimiter
        Exch
        Exch $0 ; search sample
        Exch 3
        Exch
        Exch 2
        Exch

        Push $4 ; string from file
        Push $5	; length of string
        Push $6 ; not used
        Push $7 ; search result
        Push $8 ; not used
        Push $9 ; not used
        Push $R0 ;length of the search sample
        Push $R1 ;length of the comment symbol
        Push $R2 ;tmp

        ClearErrors
        StrLen $5 $0
        StrCpy $7 no

        StrLen $R0 $0
        StrLen $R1 $1

        lbl_SearchInFile_loop:
        FileRead $2 $4
        IfErrors lbl_SearchInFile_done

        StrCmp $3 'begin' lbl_SearchFromBeginOnly lbl_SearchInString_loop

        lbl_SearchFromBeginOnly:
        StrLen $5 $4
        StrCpy $R2 $4 $R0
        StrCmp $R2 $0 lbl_SampleIsFound lbl_SearchInFile_loop

        lbl_SearchInString_loop:
        StrCmp "" $4  lbl_SearchInFile_loop
        StrLen $5 $4
        StrCmp "" $1  lbl_SearchSampleCont  ; search for the comments delimiter
        StrCpy $R2 $4 $R1
        StrCmp $R2 $1 lbl_SearchInFile_loop

        lbl_SearchSampleCont:
        StrCpy $R2 $4 $R0	                  ; search as such the sample
        StrCmp $R2 $0 lbl_SampleIsFound
        IntOp $5 $5 - 1 	 ; cut a char at the left and continue search
        StrCpy $4 $4 $5 1
        Goto lbl_SearchInString_loop

        lbl_SampleIsFound:
        StrCpy $7 yes

        lbl_SearchInFile_done:
          StrCpy $0 $7

        Pop $R2
        Pop $R1
        Pop $R0
        Pop $9
        Pop $8
        Pop $7
        Pop $6
        Pop $5
        Pop $4
        Pop $3
        Pop $2
        Pop $1
        Exch $0 ;output yes/no

   FunctionEnd
!macroend 

!insertmacro SearchInFile_macro ""
!insertmacro SearchInFile_macro "un."


Function isRoot
  Exch $0

  # get rid of leading/trailing spaces
  Push $1
  _loop_left:
    StrCpy $1 "$0" 1
    StrCmp "$1" " " _left
    goto _loop_right
  _left:
    StrCpy $0 "$0" "" 1
    goto _loop_left

  _loop_right:
    StrCpy $1 "$0" 1 -1
    StrCmp "$1" " " _right
    goto _loop_end
  _right:
    StrCpy $0 "$0" -1
    goto _loop_right

  _loop_end:
  Pop $1

  # check whether the path is (now) an empty string
  StrCmp $0 "" _root

  # get rid of any trailing backslashes.  If the path were "c:\", it'll now be "c:"
  Push $0
    Exch $EXEDIR
    Exch $EXEDIR
  Pop $0

  # check whether the last char is a colon.  If it is, then we're looking at a root dir.
  StrCpy $0 $0 1 -1
  StrCmp $0 ":" _root _not_root

  _root:
    StrCpy $0 "true"
    goto _end

  _not_root:
    StrCpy $0 "false"
    goto _end

  _end:
    Exch $0
FunctionEnd




