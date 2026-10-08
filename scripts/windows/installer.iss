; Windows 安装包（Inno Setup 6.5+）。不要直接编译，用 scripts/windows-package.sh：
; 它先构建 release、把 VC++ 运行库放进构建目录，再传入版本号与目录调用 ISCC。
;
; 装到当前用户目录（%LOCALAPPDATA%\Programs\长命百岁），不需要管理员权限。
; 用户数据在 %APPDATA%\com.example\Live a Long Life，备份在"文档\长命百岁备份"，
; 覆盖安装与卸载都不碰（A-07）。

#ifndef AppVersion
  #error 用 scripts/windows-package.sh 打包，由它传入 AppVersion
#endif
#ifndef BuildDir
  #error 用 scripts/windows-package.sh 打包，由它传入 BuildDir
#endif
#ifndef OutputDir
  #define OutputDir "..\..\app\build\windows\installer"
#endif

#define AppName "长命百岁"
#define AppExe "live_a_long_life.exe"

[Setup]
; AppId 固定不变：升级安装靠它找到旧版本。
AppId={{303E4AF2-8AD0-4091-9C69-592E2EA30C74}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=com.example
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=长命百岁-{#AppVersion}-windows-setup
SetupIconFile=..\..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "chs"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "在桌面创建快捷方式"; GroupDescription: "附加选项："
Name: "autostart"; Description: "开机自动启动，在托盘里接收手机同步"; GroupDescription: "附加选项："

[Files]
; 构建目录里已经有 VC++ 运行库（msvcp140 等），没装过 VS 的电脑也能启动。
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; 开机自启（P-34）：带 --autostart 时只在托盘里运行，不弹窗口。
; 升级时没勾选就删掉旧的启动项。
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "{#AppName}"; ValueData: """{app}\{#AppExe}"" --autostart"; Tasks: autostart; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "{#AppName}"; Tasks: not autostart; Flags: deletevalue

[Run]
Filename: "{app}\{#AppExe}"; Description: "启动{#AppName}"; Flags: nowait postinstall skipifsilent

[Code]
// 应用关窗后还常驻托盘（P-34），覆盖安装和卸载前要先结束它，否则 exe 被占用、
// 替换不了。关闭按钮只会隐藏窗口，所以只能强制结束；数据库写入是事务的，
// 同步中断后下次从游标续传（P-32）。
procedure StopRunningApp();
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM {#AppExe}', '',
    SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  StopRunningApp();
  Result := '';
end;

function InitializeUninstall(): Boolean;
begin
  StopRunningApp();
  Result := True;
end;
