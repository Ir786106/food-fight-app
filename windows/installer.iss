[Setup]
AppId=FoodFight
AppName=Food Fight
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\Food Fight
DefaultGroupName=Food Fight
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename=FoodFight-{#AppVersion}-Windows-x64-Setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Food Fight"; Filename: "{app}\food_fight.exe"

[Run]
Filename: "{app}\food_fight.exe"; Description: "Launch Food Fight"; Flags: nowait postinstall skipifsilent
