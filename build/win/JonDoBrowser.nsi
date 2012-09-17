/*
 Copyright (c) 2012, JonDos GmbH
 All rights reserved.
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

  - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

  - Neither the name of the JonDos GmbH nor the names of its contributors
 may be used to endorse or promote products derived from this software without specific
 prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS
 OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS
 BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE

##############################################

There is one exception to the above mentioned license. The functions FindPortablePath and GetDrivesCallBack are under the following license:

Copyright 2007 John T. Haller

Website: http://PortableApps.com/

This software is OSI Certified Open Source Software.
OSI Certified is a certification mark of the Open Source Initiative.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

EXCEPTION: Can be used with non-GPLed open source apps distributed by PortableApps.com
 */

Var varPortableAppsPath
Var varFoundPortableAppsPath
Var extensionGUID
Var profileExtensionPath

!define JDB_VERSION "0.1"
!define NAME "JonDoBrowser"
!define VERSION "0.0.1.0"
!define INSTALLERCOMMENTS "For additional details, visit anonymous-proxy-servers.net"
!define INSTALLERADDITIONALTRADEMARKS "PortableApps.com is a Trademark of Rare Ideas, LLC. JonDo is a trademark of JonDos GmbH. Firefox is a Trademark of the Mozilla Foundation. " ;end this entry with a period and a space if used 
!define INSTALLERLEGALCOPYRIGHT "JonDos GmbH"
!define INSTALLERVERSION "0.1"

;=== Runtime Switches
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On
CRCCheck on
AutoCloseWindow True
RequestExecutionLevel user

# Installer attributes
XPStyle on
ShowInstDetails show

;=== Program Details
Name "${NAME}"
OutFile "..\..\..\${NAME}-win-${JDB_VERSION}.paf.exe"
InstallDir "\${NAME}"
Caption "${NAME}"
VIProductVersion "${VERSION}"
VIAddVersionKey ProductName "${NAME}"
VIAddVersionKey Comments "${INSTALLERCOMMENTS}"
VIAddVersionKey CompanyName "JonDos GmbH"
VIAddVersionKey LegalCopyright "${INSTALLERLEGALCOPYRIGHT}"
VIAddVersionKey FileDescription "${NAME}"
VIAddVersionKey FileVersion "${VERSION}"
VIAddVersionKey ProductVersion "${VERSION}"
VIAddVersionKey InternalName "${NAME}"
VIAddVersionKey LegalTrademarks "${INSTALLERADDITIONALTRADEMARKS}"
VIAddVersionKey OriginalFilename "${NAME}.paf.exe"
VIAddVersionKey JonDoBrowserInstallerVersion "${INSTALLERVERSION}"

# Included files
!include Sections.nsh
!include MUI.nsh
!include FileFunc.nsh

!insertmacro GetOptions
!insertmacro GetFileAttributes
!insertmacro GetParent
!insertmacro GetDrives
!insertmacro GetParameters

# MUI defines
!define MUI_ICON "appicon.ico"

!define MUI_COMPONENTSPAGE_SMALLDESC

; MUI Settings / Icons
;!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"

; MUI Settings / Header
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_LEFT
!define MUI_HEADERIMAGE_BITMAP "blau2.bmp"
;!define MUI_HEADERIMAGE_UNBITMAP "${NSISDIR}\Contrib\Graphics\Header\orange-uninstall-r.bmp"

; MUI Settings / Wizard
!define MUI_WELCOMEFINISHPAGE_BITMAP "blau.bmp"
;!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange-uninstall.bmp"

# Reserved Files
ReserveFile "${NSISDIR}\Plugins\BGImage.dll"

# Installer pages
!insertmacro MUI_PAGE_WELCOME

#!define MUI_PAGE_CUSTOMFUNCTION_PRE dirPre
#!define MUI_PAGE_CUSTOMFUNCTION_LEAVE dirPost
!define MUI_DIRECTORYPAGE_TEXT_TOP $(SelectJonDoBrowser)
!insertmacro MUI_PAGE_DIRECTORY

#!define MUI_PAGE_CUSTOMFUNCTION_PRE instPre Otherwise the logic gets called
#twice!!
#!define MUI_PAGE_CUSTOMFUNCTION_LEAVE EditProfilesIni
!insertmacro MUI_PAGE_INSTFILES


!define MUI_PAGE_CUSTOMFUNCTION_LEAVE FinishedInstall

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION FinishRun
!insertmacro MUI_PAGE_FINISH

# Installer languages
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "English"

# Inlcude the language strings
!include JonDoBrowser-Lang-English.nsh
!include JonDoBrowser-Lang-German.nsh

/* In UAC_JonDo.nsh we have added some german language support. Because all
the warnings and error messages which may occur during elevating were, of
course, just in english. Well, and if we want language support we have to load
the UAC_JonDo.nsh after we included the relevant language-macro. */

!include UAC_JonDo.nsh

Function .onInit
  ${GetOptions} "$CMDLINE" "/DESTINATION=" $R0
  ${If} $R0 != ""
    StrCpy $INSTDIR "$R0${NAME}"
  ${Else}
    Call SearchPortableApps
    StrCpy $INSTDIR $varPortableAppsPath
  ${EndIf}
  InitPluginsDir
  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Function SearchPortableApps
  ClearErrors
  ${GetDrives} "HDD+FDD" GetDrivesCallBack
  StrCmp $varFoundPortableAppsPath "" DefaultDestination
  StrCpy $varPortableAppsPath "$varFoundPortableAppsPath\${NAME}"
  Goto done

 DefaultDestination:
  ${If} $DESKTOP == ""
    # No $DESKTOP check for $PROFILE...
    ${If} $PROFILE == ""
      StrCpy $varPortableAppsPath "$PROGRAMFILES\${NAME}\"
    ${Else}
      StrCpy $varPortableAppsPath "$PROFILE\${NAME}\"
    ${Endif}
  ${Else}
    StrCpy $varPortableAppsPath "$DESKTOP\${NAME}\"
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
  StrCpy $varFoundPortableAppsPath "$9PortableApps"
 End:
  Push $0
FunctionEnd

Section JFPortable
  ${If} $PROFILE == ""
    MessageBox MB_ICONEXCLAMATION|MB_OK $(FF30Win9x)
  ${EndIf}
  SetOutPath $INSTDIR
  SetOverwrite on

  File /r /x .svn /x Source "..\..\*.*"
  File /r /x .svn "..\..\..\FirefoxByLanguage\enFirefoxPortablePatch\*.*"

  # Copying the JonDoBrowser.ini in order to allow a desktop and
  # a portable Firefox running in parallel
  File "JonDoBrowser.ini"

  SetOutPath $INSTDIR\Data\profile

  ${If} $LANGUAGE == "1031"
    File "/oname=prefs.js" "..\..\..\full\profile\prefs_browser_de.js"
    File "/oname=places.sqlite" "..\..\..\full\profile\places.sqlite_de"
  ${ElseIf} $LANGUAGE == "1033"
    File "/oname=prefs.js" "..\..\..\full\profile\prefs_browser_en.js"
    File "/oname=places.sqlite" "..\..\..\full\profile\places.sqlite_en"
  ${EndIf}

  # The search plugins...

  SetOutPath $INSTDIR\Data\profile\searchplugins

  File /x .svn "..\..\..\full\profile\searchplugins\*"

  # Now the extensions:
  # ===================
  StrCpy $profileExtensionPath "$INSTDIR\Data\profile\extensions"

  #Adblock
  SetOutPath "$profileExtensionPath"
  File /r /x .svn "..\..\..\full\profile\extensions\{d10d0bf8-f5b5-c8b4-a8b2-2b9879e08c5d}.xpi"

  # CookieMonster
  StrCpy $extensionGUID "{45d8ff86-d909-11db-9705-005056c00008}"
  SetOutPath "$profileExtensionPath\$extensionGUID"
  File /r /x .svn "..\..\..\full\profile\extensions\{45d8ff86-d909-11db-9705-005056c00008}\*.*"

  # HTTPSEverywhere
  StrCpy $extensionGUID "https-everywhere@eff.org"
  SetOutPath "$profileExtensionPath\$extensionGUID"
  File /r /x .svn "..\..\..\full\profile\extensions\https-everywhere@eff.org\*.*"

  # JonDoFox        
  StrCpy $extensionGUID "{437be45a-4114-11dd-b9ab-71d256d89593}"
  SetOutPath "$profileExtensionPath\$extensionGUID"
  File /r /x .svn "..\..\..\full\profile\extensions\{437be45a-4114-11dd-b9ab-71d256d89593}\*.*"

  # NoScript        
  SetOutPath "$profileExtensionPath"
  File /r /x .svn "..\..\..\full\profile\extensions\{73a6fe31-595d-460b-a920-fcc0f8843232}.xpi"

  # UnPlug
  StrCpy $extensionGUID "unplug@compunach"
  SetOutPath "$profileExtensionPath\$extensionGUID"
  File /r /x .svn "..\..\..\full\profile\extensions\unplug@compunach\*.*"

  ${If} $LANGUAGE == "1031"
    # German language strings
    StrCpy $extensionGUID "langpack-de@firefox.mozilla.org.xpi"
    SetOutPath "$profileExtensionPath"
    File /r /x .svn "..\..\..\full\profile\extensions\langpack-de@firefox.mozilla.org.xpi"
  ${EndIf}
SectionEnd

Function FinishedInstall
  ExecShell "open" $INSTDIR
FunctionEnd

Function FinishRun
  Exec "$INSTDIR\${NAME}.exe"
FunctionEnd
