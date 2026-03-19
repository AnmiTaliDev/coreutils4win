; AnmiTaliDev CoreUtils4Win - Inno Setup Script
; Copyright (C) 2026 AnmiTaliDev
; Licensed under the Apache License, Version 2.0

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppName=AnmiTaliDev CoreUtils4Win
AppVersion={#AppVersion}
AppPublisher=AnmiTaliDev
AppPublisherURL=https://github.com/AnmiTaliDev/coreutils4win
AppSupportURL=https://github.com/AnmiTaliDev/coreutils4win/issues
AppUpdatesURL=https://github.com/AnmiTaliDev/coreutils4win/releases
DefaultDirName={autopf}\CoreUtils4Win
DefaultGroupName=CoreUtils4Win
LicenseFile=..\LICENSE
OutputDir=..\dist
OutputBaseFilename=coreutils4win-{#AppVersion}-setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
ChangesEnvironment=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\zig-out\bin\*.exe"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKLM; \
  Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
  ValueType: expandsz; ValueName: "Path"; \
  ValueData: "{olddata};{app}"; \
  Check: not IsInPath(ExpandConstant('{app}')); \
  Flags: preservestringtype

[UninstallDelete]
Type: dirifempty; Name: "{app}"

[Code]
function IsInPath(Dir: string): Boolean;
var
  Path: string;
begin
  RegQueryStringValue(HKLM,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', Path);
  Result := Pos(LowerCase(Dir), LowerCase(Path)) > 0;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Path, Dir, NewPath: string;
  P: Integer;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    Dir := ExpandConstant('{app}');
    RegQueryStringValue(HKLM,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
      'Path', Path);
    P := Pos(';' + LowerCase(Dir), LowerCase(Path));
    if P = 0 then
      P := Pos(LowerCase(Dir) + ';', LowerCase(Path));
    if P > 0 then
    begin
      NewPath := Copy(Path, 1, P - 1) + Copy(Path, P + Length(Dir) + 1, MaxInt);
      RegWriteExpandStrValue(HKLM,
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        'Path', NewPath);
    end;
  end;
end;
