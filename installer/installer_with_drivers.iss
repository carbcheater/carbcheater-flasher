; CarbCheater Flasher Installer Script with Driver Installation
; Requires Inno Setup: https://jrsoftware.org/isdl.php

#define MyAppName "CarbCheater Flasher"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "CarbCheater"
#define MyAppURL "https://thecarbcheater.com"
#define MyAppExeName "carbcheaterflasher.exe"

[Setup]
AppId={{CB847F9A-4E2B-4D1C-9F3A-8E5D6C7B8A9F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer_output
OutputBaseFilename=CarbCheaterFlasher_Setup_v{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Request admin privileges to install drivers
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "installdrivers"; Description: "Install USB drivers (CH340 and CP210x) if not present"; GroupDescription: "Additional options:"; Flags: checkedonce

[Files]
; Main executable and Flutter files
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; ESPTool
Source: "..\tools\esptool.exe"; DestDir: "{app}\tools"; Flags: ignoreversion

; USB Drivers (place these in drivers folder)
Source: "..\drivers\CH34x_Install_Windows_v3_4.EXE"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: installdrivers
Source: "..\drivers\CP201x_Windows_Drivers.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Tasks: installdrivers

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Run]
; Install drivers if task is selected
Filename: "{tmp}\CH34x_Install_Windows_v3_4.EXE"; Description: "Installing CH340 USB driver..."; StatusMsg: "Installing CH340 driver..."; Flags: waituntilterminated skipifdoesntexist; Tasks: installdrivers; Check: NeedsCH340Driver
Filename: "{tmp}\CP201x_Windows_Drivers.exe"; Description: "Installing CP210x USB driver..."; StatusMsg: "Installing CP210x driver..."; Flags: waituntilterminated skipifdoesntexist; Tasks: installdrivers; Check: NeedsCP210xDriver
; Launch app after install
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Check if CH340 driver is already installed
function NeedsCH340Driver: Boolean;
var
  ResultCode: Integer;
begin
  // Check if driver exists in Windows drivers folder
  Result := not FileExists(ExpandConstant('{sys}\drivers\CH341S64.SYS')) and 
            not FileExists(ExpandConstant('{sys}\drivers\CH341SER.SYS'));
  
  // Also check registry for driver
  if Result then
  begin
    Result := not RegKeyExists(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Services\CH341SER') and
              not RegKeyExists(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Services\CH341SER_A64');
  end;
  
  if not Result then
    Log('CH340 driver already installed, skipping installation');
end;

// Check if CP210x driver is already installed  
function NeedsCP210xDriver: Boolean;
begin
  // Check if driver exists in Windows drivers folder
  Result := not FileExists(ExpandConstant('{sys}\drivers\silabser.sys'));
  
  // Also check registry for driver
  if Result then
  begin
    Result := not RegKeyExists(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Services\silabser');
  end;
  
  if not Result then
    Log('CP210x driver already installed, skipping installation');
end;

// Custom page to show driver installation status
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Drivers have been installed (if needed)
    Log('Driver installation complete');
  end;
end;
