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
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; -------------------------------------------------------
; Main App - Flutter executable and runtime files
; -------------------------------------------------------
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; -------------------------------------------------------
; ESPTool
; -------------------------------------------------------
Source: "..\tools\esptool.exe"; DestDir: "{app}\tools"; Flags: ignoreversion

; -------------------------------------------------------
; CP210x Driver - entire folder (needs .inf, .cat, x64/x86 subfolders)
; -------------------------------------------------------
Source: "..\drivers\cp210x\*"; DestDir: "{tmp}\drivers\cp210x"; Flags: ignoreversion recursesubdirs createallsubdirs deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]

// -------------------------------------------------------
// Driver detection helpers
// -------------------------------------------------------

function CP210xInstalled(): Boolean;
begin
  Result := FileExists(ExpandConstant('{sys}\drivers\silabser.sys')) or
            RegKeyExists(HKLM, 'SYSTEM\CurrentControlSet\Services\silabser');
end;

// -------------------------------------------------------
// Install drivers after main app files are copied
// -------------------------------------------------------

procedure InstallDrivers();
var
  ResultCode: Integer;
begin

  // --- CP210x ---
  // NOTE: Remove the comment below once confirmed working, to re-enable skip-if-installed check
  // if not CP210xInstalled() then
  // begin
    MsgBox('We need to install the CP210x USB driver.' + #13#10 + #13#10 +
           'Click OK and then follow the prompts in the next window.' + #13#10 +
           'This allows your computer to communicate with your CarbCheater device.',
           mbInformation, MB_OK);
    WizardForm.StatusLabel.Caption := 'Installing CP210x USB driver...';
    Exec(ExpandConstant('{tmp}\drivers\cp210x\CP201x_Windows_Drivers.exe'),
         '', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
  // end;

end;

// -------------------------------------------------------
// Hook into the installer steps
// -------------------------------------------------------

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    InstallDrivers();
  end;
end;

