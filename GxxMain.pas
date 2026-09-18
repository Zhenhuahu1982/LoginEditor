unit GxxMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils,
  System.Classes, System.IniFiles, System.UITypes, System.Hash,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Dialogs, Vcl.Graphics, Vcl.FileCtrl, GxxDialogs, GxxCrypto,
  GxxClientData;

type
  // Appended payload metadata used by the optional self-extracting launcher.
  // The bootstrap reader lives in LoginBootstrapMain.pas.
  TPayloadTrailer = packed record
    Magic: array[0..7] of AnsiChar;
    Version: Cardinal;
    EntryCount: Cardinal;
    ManifestOffset: Int64;
    ManifestSize: Int64;
    OriginalSize: Int64;
  end;

  TServerEntry = class
  public
    GroupName: string;
    DisplayName: string;
    ServerName: string;
    Address: string;
    Port: string;
    AutoExpand: Boolean;
    MicroAddress: string;
    MicroPort: string;
    FirewallPort: string;
    FirewallType: string;
  end;

  TFrmMain = class(TForm)
  private
    FMainPages: TPageControl;
    FConfigPages: TPageControl;
    FClientFile, FClientData, FPatchFile, FResourcesDir: TEdit;
    FClientPassword, FMicroPassword: TEdit;
    FVersion, FBackgroundFile, FMouseFile, FKeyFile, FUnpackFile,
      FVersionURL: TEdit;
    FLoginTitle, FLoginSkin, FLoginConfig, FMainIP, FMainPort: TEdit;
    FBackupIP, FBackupPort, FConfigURL, FBackupURL, FCheckURL: TEdit;
    FMainTCPFile, FBackupTCPFile, FPromotionID: TEdit;
    FRequiredPatch, FAllowVersionURL: TCheckBox;
    FLoginMode: TComboBox;
    FNoticeURL, FHomeURL, FServiceURL: TEdit;
    FAutoRefresh: TCheckBox;
    FRefreshSeconds: TEdit;
    FServerTree: TTreeView;
    FServerAutoExpand: TCheckBox;
    FGroupName, FServerGroup, FServerName, FServerIP, FServerPort: TEdit;
    FServerMicroIP, FServerMicroPort, FServerFirewallPort: TEdit;
    FAddGroupButton, FEditGroupButton, FDeleteGroupButton: TButton;
    FAddServerButton, FEditServerButton, FDeleteServerButton: TButton;
    FUpdateList: TListView;
    FUpdateTypes: array[0..3] of TRadioButton;
    FUpdateDirectory: TComboBox;
    FUpdateFile, FUpdateURL, FUpdateMD5: TEdit;
    FEditUpdateButton, FDeleteUpdateButton: TButton;
    FConfigPreviousButton, FConfigNextButton: TButton;
    procedure BuildUI;
    procedure BuildLoginPage(AParent: TWinControl);
    procedure BuildConfigPage(AParent: TWinControl);
    procedure BuildAboutPage(AParent: TWinControl);
    procedure OpenSettings(Sender: TObject);
    procedure BrowseFile(Sender: TObject);
    procedure SaveConfig(Sender: TObject);
    procedure GenerateLogin(Sender: TObject);
    procedure ConfigNext(Sender: TObject);
    procedure ConfigPrevious(Sender: TObject);
    procedure ConfigPageChanged(Sender: TObject);
    procedure SelectUpdateFile(Sender: TObject);
    procedure AddUpdate(Sender: TObject);
    procedure EditUpdate(Sender: TObject);
    procedure DeleteUpdate(Sender: TObject);
    procedure UpdateSelected(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure AddServerGroup(Sender: TObject);
    procedure EditServerGroup(Sender: TObject);
    procedure DeleteServerGroup(Sender: TObject);
    procedure AddServer(Sender: TObject);
    procedure EditServer(Sender: TObject);
    procedure DeleteServer(Sender: TObject);
    procedure ServerSelectionChanged(Sender: TObject; Node: TTreeNode);
    procedure GenerateList(Sender: TObject);
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    procedure EnsureDefaultConfig;
    procedure LoadConfig;
    procedure LoadEditorData(AIni: TIniFile);
    procedure SaveEditorData(AIni: TIniFile);
    procedure UpdateServerButtons;
    procedure UpdateUpdateButtons;
    procedure FillServerEditor(ANode: TTreeNode);
    procedure FillUpdateEditor(AItem: TListItem);
    procedure SetUpdateType(AIndex: Integer);
    function GetUpdateType: Integer;
    function GetUpdateTypeName(AIndex: Integer): string;
    function FindGroup(const AName: string): TTreeNode;
    function SelectedGroup: TTreeNode;
    function FileMD5(const AFileName: string): string;
    function IniName: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

function ClampInt(const AValue, AMin, AMax: Integer): Integer;
begin
  Result := AValue;
  if Result < AMin then Result := AMin;
  if Result > AMax then Result := AMax;
end;

function AddLabel(AParent: TWinControl; const ACaption: string;
  X, Y: Integer): TLabel;
begin
  Result := TLabel.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.Left := X;
  Result.Top := Y;
  Result.AutoSize := True;
end;

function AddEdit(AParent: TWinControl; const AText: string;
  X, Y, W: Integer): TEdit;
begin
  Result := TEdit.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(X, Y, W, 20);
  Result.Text := AText;
end;

function AddButton(AParent: TWinControl; const ACaption: string;
  X, Y, W, H: Integer; AOnClick: TNotifyEvent = nil): TButton;
begin
  Result := TButton.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.SetBounds(X, Y, W, H);
  Result.OnClick := AOnClick;
end;

function AddCheck(AParent: TWinControl; const ACaption: string;
  X, Y: Integer; AChecked: Boolean = False): TCheckBox;
begin
  Result := TCheckBox.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.SetBounds(X, Y, Length(ACaption) * 14 + 24, 17);
  Result.Checked := AChecked;
end;

function AddGroup(AParent: TWinControl; const ACaption: string;
  X, Y, W, H: Integer): TGroupBox;
begin
  Result := TGroupBox.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := ACaption;
  Result.SetBounds(X, Y, W, H);
end;

procedure AddBrowseButton(AOwner: TFrmMain; AParent: TWinControl;
  AEdit: TEdit; X, Y: Integer);
var
  B: TButton;
begin
  B := AddButton(AParent, '...', X, Y, 17, 20, AOwner.BrowseFile);
  B.Tag := NativeInt(AEdit);
end;

procedure AddSpin(AParent: TWinControl; const AText: string;
  X, Y, W: Integer; AMin, AMax: Integer; out AEdit: TEdit);
var
  U: TUpDown;
begin
  AEdit := AddEdit(AParent, AText, X, Y, W);
  U := TUpDown.Create(AParent);
  U.Parent := AParent;
  U.Associate := AEdit;
  U.Min := AMin;
  U.Max := AMax;
  U.Position := StrToIntDef(AText, AMin);
  U.Thousands := False;
end;

constructor TFrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BuildUI;
  DragAcceptFiles(Handle, True);
  EnsureDefaultConfig;
  LoadConfig;
end;

destructor TFrmMain.Destroy;
var
  I: Integer;
begin
  DragAcceptFiles(Handle, False);
  if Assigned(FServerTree) then
    for I := 0 to FServerTree.Items.Count - 1 do
      if Assigned(FServerTree.Items[I].Data) then
        TObject(FServerTree.Items[I].Data).Free;
  inherited;
end;

procedure TFrmMain.BuildUI;
var
  LoginTab, ConfigTab, AboutTab: TTabSheet;
  Progress: TProgressBar;
  Status: TStatusBar;
begin
  BorderStyle := bsSingle;
  BorderIcons := [biSystemMenu, biMinimize];
  Caption := '登录器生成器';
  ClientWidth := 496;
  ClientHeight := 581;
  Position := poScreenCenter;
  Scaled := False;
  Visible := True;
  Font.Name := '宋体';
  Font.Size := 9;
  Color := clBtnFace;

  FMainPages := TPageControl.Create(Self);
  FMainPages.Parent := Self;
  FMainPages.SetBounds(8, 4, 481, 538);
  FMainPages.TabHeight := 24;

  LoginTab := TTabSheet.Create(FMainPages);
  LoginTab.PageControl := FMainPages;
  LoginTab.Caption := '登录器生成';
  BuildLoginPage(LoginTab);

  ConfigTab := TTabSheet.Create(FMainPages);
  ConfigTab.PageControl := FMainPages;
  ConfigTab.Caption := '配置文件生成';
  BuildConfigPage(ConfigTab);

  AboutTab := TTabSheet.Create(FMainPages);
  AboutTab.PageControl := FMainPages;
  AboutTab.Caption := '相关信息';
  BuildAboutPage(AboutTab);

  Progress := TProgressBar.Create(Self);
  Progress.Parent := Self;
  Progress.SetBounds(4, 540, 492, 15);
  Progress.Min := 0;
  Progress.Max := 100;

  Status := TStatusBar.Create(Self);
  Status.Parent := Self;
  Status.Align := alBottom;
  Status.Height := 23;
  Status.SimplePanel := False;
  with Status.Panels.Add do
  begin
    Text := 'BuildTime:  2023/11/15 14:23:16';
    Width := 320;
  end;
  with Status.Panels.Add do
  begin
    Text := 'ver:  1.0.0.64';
    Width := 160;
  end;
end;

procedure TFrmMain.BuildLoginPage(AParent: TWinControl);
var
  G: TGroupBox;
  B: TButton;
  L: TLabel;
begin
  G := AddGroup(AParent, '基本设置', 4, 0, 465, 199);
  AddLabel(G, '客户端文件', 8, 22);
  FClientFile := AddEdit(G, 'Client.dat', 75, 16, 140);
  AddLabel(G, '客户端数据文件', 224, 22);
  FClientData := AddEdit(G, 'ClientData.dat', 315, 16, 140);

  FRequiredPatch := AddCheck(G, '必备补丁', 8, 42, True);
  FPatchFile := AddEdit(G, 'NewopUI.Pak', 75, 38, 140);
  AddLabel(G, 'Resources目录', 224, 44);
  FResourcesDir := AddEdit(G, 'Resources', 315, 38, 140);

  AddLabel(G, '登录密码', 8, 66);
  FClientPassword := AddEdit(G, 'GxxM2', 75, 60, 140);
  AddLabel(G, '微端更新密码', 224, 66);
  FMicroPassword := AddEdit(G, 'GxxM2', 315, 60, 140);

  AddLabel(G, '游戏背景图', 8, 88);
  FBackgroundFile := AddEdit(G, '', 75, 82, 140);
  AddBrowseButton(Self, G, FBackgroundFile, 198, 82);
  AddLabel(G, '版本号', 256, 88);
  FVersion := AddEdit(G, '2021-11-08', 315, 82, 140);

  AddLabel(G, '鼠标光标', 8, 110);
  FMouseFile := AddEdit(G, '', 75, 104, 380);
  AddBrowseButton(Self, G, FMouseFile, 438, 104);
  AddLabel(G, '键前光标', 8, 132);
  FKeyFile := AddEdit(G, '', 75, 126, 380);
  AddBrowseButton(Self, G, FKeyFile, 438, 126);
  AddLabel(G, '拆卸光标', 8, 154);
  FUnpackFile := AddEdit(G, '', 75, 148, 380);
  AddBrowseButton(Self, G, FUnpackFile, 438, 148);
  FAllowVersionURL := AddCheck(G, '版本不符弹出网页', 8, 175, False);
  FVersionURL := AddEdit(G, '', 123, 170, 332);

  G := AddGroup(AParent, '登录器设置', 4, 202, 465, 175);
  AddLabel(G, '快捷方式名', 8, 22);
  FLoginTitle := AddEdit(G, '传奇登陆器', 75, 16, 140);
  AddLabel(G, '登录器配置文件', 224, 22);
  FLoginConfig := AddEdit(G, 'GameMir2.ini', 315, 16, 140);

  AddLabel(G, '登录器图标', 8, 44);
  FLoginSkin := AddEdit(G, '', 75, 38, 140);
  AddBrowseButton(Self, G, FLoginSkin, 198, 38);
  AddLabel(G, '登录模式', 256, 44);
  FLoginMode := TComboBox.Create(G);
  FLoginMode.Parent := G;
  FLoginMode.SetBounds(315, 38, 140, 21);
  FLoginMode.Style := csDropDownList;
  FLoginMode.Items.Add('普通登录模式');
  FLoginMode.Items.Add('微端登录模式');
  FLoginMode.ItemIndex := 0;

  AddLabel(G, '主TCP', 35, 66);
  FMainIP := AddEdit(G, '', 75, 60, 120);
  AddLabel(G, '端口号:', 203, 66);
  AddSpin(G, '1923', 251, 60, 73, 1, 65535, FMainPort);
  AddLabel(G, '文件', 330, 66);
  FMainTCPFile := AddEdit(G, '', 367, 60, 88);

  AddLabel(G, '备用TCP', 23, 88);
  FBackupIP := AddEdit(G, '', 75, 82, 120);
  AddLabel(G, '端口号:', 203, 88);
  AddSpin(G, '1923', 251, 82, 73, 1, 65535, FBackupPort);
  AddLabel(G, '文件', 330, 88);
  FBackupTCPFile := AddEdit(G, '', 367, 82, 88);

  AddLabel(G, '配置地址', 8, 110);
  FConfigURL := AddEdit(G, 'http://www.gxxm2.com/Config.txt', 75, 104, 380);
  AddLabel(G, '备用地址', 8, 132);
  FBackupURL := AddEdit(G, 'http://www.gxxm2.com/Config.txt', 75, 126, 380);
  AddLabel(G, '外挂检测', 8, 154);
  FCheckURL := AddEdit(G, 'http://www.gxxm2.com/外挂检测.txt', 75, 148, 380);

  G := AddGroup(AParent, '其他设置', 4, 381, 465, 94);
  AddLabel(G, '推广标识：', 8, 16);
  FPromotionID := AddEdit(G, '', 8, 38, 162);
  B := AddButton(G, '客户端插件', 178, 13, 78, 23, OpenSettings); B.Tag := 1;
  B := AddButton(G, '加密列表', 262, 13, 78, 23, OpenSettings); B.Tag := 2;
  B := AddButton(G, '资源读取规则', 346, 13, 108, 23, OpenSettings); B.Tag := 3;
  B := AddButton(G, '内挂设置', 178, 38, 78, 23, OpenSettings); B.Tag := 4;
  B := AddButton(G, '客户端选项', 262, 38, 78, 23, OpenSettings); B.Tag := 5;
  B := AddButton(G, '客户端界面设置', 346, 38, 108, 23, OpenSettings); B.Tag := 6;
  B := AddButton(G, '集成配置', 178, 63, 78, 23, OpenSettings); B.Tag := 7;
  B := AddButton(G, '登录器选项', 262, 63, 78, 23, OpenSettings); B.Tag := 8;
  B := AddButton(G, '登录器皮肤编辑', 346, 63, 108, 23, OpenSettings); B.Tag := 9;

  L := AddLabel(AParent, 'Gxx引擎  持续领先  >>', 69, 470);
  L.Font.Color := clBlue;
  L := AddLabel(AParent, 'Gxx引擎,持续领先 - www.gxxm2.com', 4, 489);
  L.Font.Color := clBlue;
  AddButton(AParent, '保存配置(&G)', 256, 479, 81, 29, SaveConfig);
  B := AddButton(AParent, '生成登录器(&M)', 344, 479, 125, 29, GenerateLogin);
  B.Default := True;
end;

procedure TFrmMain.BuildConfigPage(AParent: TWinControl);
var
  RemoteTab, SettingsTab, UpdateTab: TTabSheet;
  LV: TListView;
  G: TGroupBox;
begin
  FConfigPages := TPageControl.Create(AParent);
  FConfigPages.Parent := AParent;
  FConfigPages.SetBounds(2, 2, 469, 473);
  FConfigPages.TabHeight := 24;
  FConfigPages.OnChange := ConfigPageChanged;

  RemoteTab := TTabSheet.Create(FConfigPages);
  RemoteTab.PageControl := FConfigPages;
  RemoteTab.Caption := '远程列表①';
  FServerTree := TTreeView.Create(RemoteTab);
  FServerTree.Parent := RemoteTab;
  FServerTree.SetBounds(4, 4, 185, 437);
  FServerTree.ReadOnly := True;
  FServerTree.OnChange := ServerSelectionChanged;
  FServerAutoExpand := AddCheck(RemoteTab, '自动展开', 200, 9, False);
  AddLabel(RemoteTab, '服务器分组名称:', 198, 35);
  FGroupName := AddEdit(RemoteTab, '电信服务器', 302, 29, 155);
  FAddGroupButton := AddButton(RemoteTab, '加分组', 301, 56, 49, 25, AddServerGroup);
  FEditGroupButton := AddButton(RemoteTab, '改分组', 354, 56, 49, 25, EditServerGroup);
  FDeleteGroupButton := AddButton(RemoteTab, '删分组', 407, 56, 49, 25, DeleteServerGroup);
  AddLabel(RemoteTab, '服务器分组:', 198, 99);
  FServerGroup := AddEdit(RemoteTab, '电信服务器', 302, 93, 155);
  AddLabel(RemoteTab, '服务器名称:', 198, 123);
  FServerName := AddEdit(RemoteTab, '传奇归来', 302, 117, 155);
  AddLabel(RemoteTab, '服务器地址:', 198, 147);
  FServerIP := AddEdit(RemoteTab, '127.0.0.1', 302, 141, 155);
  AddLabel(RemoteTab, '服务器端口:', 198, 171);
  FServerPort := AddEdit(RemoteTab, '7000', 302, 165, 155);
  AddLabel(RemoteTab, '微端网关地址:', 198, 195);
  FServerMicroIP := AddEdit(RemoteTab, '127.0.0.1', 302, 189, 155);
  AddLabel(RemoteTab, '微端网关端口:', 198, 219);
  FServerMicroPort := AddEdit(RemoteTab, '0', 302, 213, 155);
  AddLabel(RemoteTab, '安全盾防火墙端口:', 198, 243);
  FServerFirewallPort := AddEdit(RemoteTab, '0', 302, 237, 155);
  FAddServerButton := AddButton(RemoteTab, '增加', 222, 413, 75, 25, AddServer);
  FEditServerButton := AddButton(RemoteTab, '修改', 302, 413, 75, 25, EditServer);
  FDeleteServerButton := AddButton(RemoteTab, '删除', 382, 413, 75, 25, DeleteServer);

  SettingsTab := TTabSheet.Create(FConfigPages);
  SettingsTab.PageControl := FConfigPages;
  SettingsTab.Caption := '配置信息②';
  AddLabel(SettingsTab, '公告地址:', 4, 12);
  FNoticeURL := AddEdit(SettingsTab, 'http://www.ywm2.com', 64, 6, 393);
  AddLabel(SettingsTab, '官方首页:', 4, 36);
  FHomeURL := AddEdit(SettingsTab, 'http://www.ywm2.com', 64, 30, 393);
  AddLabel(SettingsTab, '客户服务:', 4, 60);
  FServiceURL := AddEdit(SettingsTab, 'http://www.ywm2.com', 64, 54, 393);
  FAutoRefresh := AddCheck(SettingsTab, '自动刷新远程列表', 64, 81, False);
  AddLabel(SettingsTab, '刷新速度:', 177, 83);
  AddSpin(SettingsTab, '120', 239, 76, 49, 1, 9999, FRefreshSeconds);
  AddLabel(SettingsTab, '秒', 291, 83);

  UpdateTab := TTabSheet.Create(FConfigPages);
  UpdateTab.PageControl := FConfigPages;
  UpdateTab.Caption := '文件更新③';
  LV := TListView.Create(UpdateTab);
  LV.Parent := UpdateTab;
  LV.SetBounds(4, 4, 453, 313);
  LV.ViewStyle := vsReport;
  LV.GridLines := True;
  LV.ReadOnly := True;
  with LV.Columns.Add do begin Caption := '文件类型'; Width := 80; end;
  with LV.Columns.Add do begin Caption := '存放目录'; Width := 60; end;
  with LV.Columns.Add do begin Caption := '文件名称'; Width := 100; end;
  with LV.Columns.Add do begin Caption := 'MD5'; Width := 80; end;
  with LV.Columns.Add do begin Caption := '下载地址'; Width := 120; end;
  FUpdateList := LV;

  G := AddGroup(UpdateTab, '文件类型', 4, 321, 97, 118);
  FUpdateTypes[0] := TRadioButton.Create(G); FUpdateTypes[0].Parent := G;
  FUpdateTypes[0].Caption := '普通文件'; FUpdateTypes[0].SetBounds(8, 18, 82, 17); FUpdateTypes[0].Checked := True;
  FUpdateTypes[1] := TRadioButton.Create(G); FUpdateTypes[1].Parent := G;
  FUpdateTypes[1].Caption := '登陆器文件'; FUpdateTypes[1].SetBounds(8, 43, 82, 17);
  FUpdateTypes[2] := TRadioButton.Create(G); FUpdateTypes[2].Parent := G;
  FUpdateTypes[2].Caption := 'ZIP压缩文件'; FUpdateTypes[2].SetBounds(8, 68, 82, 17);
  FUpdateTypes[3] := TRadioButton.Create(G); FUpdateTypes[3].Parent := G;
  FUpdateTypes[3].Caption := '7Z压缩文件'; FUpdateTypes[3].SetBounds(8, 93, 82, 17);
  AddLabel(UpdateTab, '存放目录:', 107, 329);
  FUpdateDirectory := TComboBox.Create(UpdateTab); FUpdateDirectory.Parent := UpdateTab;
  FUpdateDirectory.SetBounds(163, 323, 119, 21);
  FUpdateDirectory.Items.Add('根目录'); FUpdateDirectory.Items.Add('Resources');
  FUpdateDirectory.Items.Add('Data'); FUpdateDirectory.ItemIndex := 0;
  AddLabel(UpdateTab, '文件名称:', 289, 329);
  FUpdateFile := AddEdit(UpdateTab, '', 347, 323, 110);
  AddLabel(UpdateTab, '下载地址:', 107, 353);
  FUpdateURL := AddEdit(UpdateTab, '', 163, 347, 294);
  AddLabel(UpdateTab, '文件MD5:', 107, 377);
  FUpdateMD5 := AddEdit(UpdateTab, '', 163, 371, 294);
  AddLabel(UpdateTab, '点击“选择文件”或直接拖动文件放到界面上获取MD5值', 163, 397).Font.Color := clRed;
  AddButton(UpdateTab, '选择文件', 163, 412, 70, 25, SelectUpdateFile);
  AddButton(UpdateTab, '增加', 237, 412, 70, 25, AddUpdate);
  FEditUpdateButton := AddButton(UpdateTab, '修改', 311, 412, 70, 25, EditUpdate);
  FDeleteUpdateButton := AddButton(UpdateTab, '删除', 385, 412, 70, 25, DeleteUpdate);
  FUpdateList.OnSelectItem := UpdateSelected;

  FConfigPreviousButton := AddButton(AParent, '上一步(&P)', 305, 479, 80, 28, ConfigPrevious);
  FConfigNextButton := AddButton(AParent, '下一步(&N)', 390, 479, 79, 28, ConfigNext);
  ConfigPageChanged(nil);
  UpdateServerButtons;
  UpdateUpdateButtons;
end;

procedure TFrmMain.BuildAboutPage(AParent: TWinControl);
begin
  AddLabel(AParent, '软件名称：GxxM2登录器生成器', 6, 10);
  AddLabel(AParent, '软件版本：1.0.0.64', 6, 29);
  AddLabel(AParent, '程序制作：Gxx', 6, 48);
  AddLabel(AParent, '官方网站：http://www.gxxm2.com', 6, 67);
end;

procedure TFrmMain.OpenSettings(Sender: TObject);
begin
  ShowGxxDialog(TButton(Sender).Tag, Self);
end;

procedure TFrmMain.BrowseFile(Sender: TObject);
var
  D: TOpenDialog;
  E: TEdit;
begin
  E := TEdit(TButton(Sender).Tag);
  D := TOpenDialog.Create(Self);
  try
    D.Filter := '所有文件 (*.*)|*.*';
    if D.Execute then
      E.Text := D.FileName;
  finally
    D.Free;
  end;
end;

function TFrmMain.IniName: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'Config.ini';
end;

procedure TFrmMain.EnsureDefaultConfig;
var
  R: TResourceStream;
begin
  if FileExists(IniName) then
    Exit;
  R := TResourceStream.Create(HInstance, 'DEFAULTCONFIG', RT_RCDATA);
  try
    R.SaveToFile(IniName);
  finally
    R.Free;
  end;
end;

function ReadSetupValue(AIni: TIniFile; const AKey, ALegacyKey,
  ADefault: string): string;
begin
  if AIni.ValueExists('Setup', AKey) then
    Result := AIni.ReadString('Setup', AKey, ADefault)
  else if (ALegacyKey <> '') and AIni.ValueExists('Setup', ALegacyKey) then
    Result := AIni.ReadString('Setup', ALegacyKey, ADefault)
  else
    Result := ADefault;
end;

procedure TFrmMain.LoadConfig;
var
  I: TIniFile;
begin
  if not FileExists(IniName) then
    Exit;
  I := TIniFile.Create(IniName);
  try
    FClientFile.Text := ReadSetupValue(I, '客户端文件', 'ClientFile', FClientFile.Text);
    FClientData.Text := ReadSetupValue(I, '客户端数据文件', 'ClientData', FClientData.Text);
    FPatchFile.Text := ReadSetupValue(I, '补丁文件', 'PatchFile', FPatchFile.Text);
    FRequiredPatch.Checked := FPatchFile.Text <> '';
    FResourcesDir.Text := ReadSetupValue(I, 'Resources目录', 'ResourcesDir', FResourcesDir.Text);
    FClientPassword.Text := ReadSetupValue(I, 'RunGatePassword', 'ClientPassword', FClientPassword.Text);
    FMicroPassword.Text := ReadSetupValue(I, '更新密码', 'MicroPassword', FMicroPassword.Text);
    FBackgroundFile.Text := ReadSetupValue(I, '背景图片', '', FBackgroundFile.Text);
    FVersion.Text := ReadSetupValue(I, '版本号', 'Version', FVersion.Text);
    FMouseFile.Text := ReadSetupValue(I, '游戏光标', '', FMouseFile.Text);
    FKeyFile.Text := ReadSetupValue(I, '镶嵌光标', '', FKeyFile.Text);
    FUnpackFile.Text := ReadSetupValue(I, '拆卸光标', '', FUnpackFile.Text);
    FAllowVersionURL.Checked := I.ReadBool('Setup', '允许弹出网页', False);
    FVersionURL.Text := ReadSetupValue(I, '弹出网页', '', FVersionURL.Text);
    FLoginTitle.Text := ReadSetupValue(I, '快捷方式', 'LoginTitle', FLoginTitle.Text);
    FLoginSkin.Text := ReadSetupValue(I, '快捷方式图标', '', FLoginSkin.Text);
    FLoginConfig.Text := ReadSetupValue(I, 'LoginConfigFileNameEx', 'LoginConfig', FLoginConfig.Text);
    FLoginMode.ItemIndex := I.ReadInteger('Setup', 'LoginMode', 0);
    if not (FLoginMode.ItemIndex in [0, 1]) then FLoginMode.ItemIndex := 0;
    FMainIP.Text := ReadSetupValue(I, '主TCP列表服务器', 'MainIP', FMainIP.Text);
    FMainPort.Text := ReadSetupValue(I, '主TCP端口', 'MainPort', FMainPort.Text);
    FMainTCPFile.Text := ReadSetupValue(I, '主TCP配置文件', '', FMainTCPFile.Text);
    FBackupIP.Text := ReadSetupValue(I, '备用TCP列表服务器', 'BackupIP', FBackupIP.Text);
    FBackupPort.Text := ReadSetupValue(I, '备用TCP端口', 'BackupPort', FBackupPort.Text);
    FBackupTCPFile.Text := ReadSetupValue(I, '备用TCP配置文件', '', FBackupTCPFile.Text);
    FConfigURL.Text := ReadSetupValue(I, '配置文件', 'ConfigURL', FConfigURL.Text);
    FBackupURL.Text := ReadSetupValue(I, '备用地址', 'BackupURL', FBackupURL.Text);
    FCheckURL.Text := ReadSetupValue(I, '外挂检测', 'CheckURL', FCheckURL.Text);
    FPromotionID.Text := ReadSetupValue(I, '推广ID', '', FPromotionID.Text);
    FNoticeURL.Text := ReadSetupValue(I, '公告地址', 'NoticeURL', FNoticeURL.Text);
    FHomeURL.Text := ReadSetupValue(I, '官方首页', 'HomeURL', FHomeURL.Text);
    FServiceURL.Text := ReadSetupValue(I, '客户服务', 'ServiceURL', FServiceURL.Text);
    FAutoRefresh.Checked := I.ReadBool('Setup', '自动刷新', FAutoRefresh.Checked);
    FRefreshSeconds.Text := I.ReadString('Setup', '刷新速度', FRefreshSeconds.Text);
    LoadEditorData(I);
  finally
    I.Free;
  end;
end;

procedure TFrmMain.SaveConfig(Sender: TObject);
var
  I: TIniFile;
begin
  I := TIniFile.Create(IniName);
  try
    I.WriteString('Setup', '客户端文件', FClientFile.Text);
    I.WriteString('Setup', '客户端数据文件', FClientData.Text);
    if FRequiredPatch.Checked then
      I.WriteString('Setup', '补丁文件', FPatchFile.Text)
    else
      I.WriteString('Setup', '补丁文件', '');
    I.WriteString('Setup', 'Resources目录', FResourcesDir.Text);
    I.WriteString('Setup', 'RunGatePassword', FClientPassword.Text);
    I.WriteString('Setup', '更新密码', FMicroPassword.Text);
    I.WriteString('Setup', '背景图片', FBackgroundFile.Text);
    I.WriteString('Setup', '版本号', FVersion.Text);
    I.WriteString('Setup', '游戏光标', FMouseFile.Text);
    I.WriteString('Setup', '镶嵌光标', FKeyFile.Text);
    I.WriteString('Setup', '拆卸光标', FUnpackFile.Text);
    I.WriteBool('Setup', '允许弹出网页', FAllowVersionURL.Checked);
    I.WriteString('Setup', '弹出网页', FVersionURL.Text);
    I.WriteString('Setup', '快捷方式', FLoginTitle.Text);
    I.WriteString('Setup', '快捷方式图标', FLoginSkin.Text);
    I.WriteString('Setup', 'LoginConfigFileNameEx', FLoginConfig.Text);
    I.WriteInteger('Setup', 'LoginMode', FLoginMode.ItemIndex);
    I.WriteString('Setup', '主TCP列表服务器', FMainIP.Text);
    I.WriteString('Setup', '主TCP端口', FMainPort.Text);
    I.WriteString('Setup', '主TCP配置文件', FMainTCPFile.Text);
    I.WriteString('Setup', '备用TCP列表服务器', FBackupIP.Text);
    I.WriteString('Setup', '备用TCP端口', FBackupPort.Text);
    I.WriteString('Setup', '备用TCP配置文件', FBackupTCPFile.Text);
    I.WriteString('Setup', '配置文件', FConfigURL.Text);
    I.WriteString('Setup', '备用地址', FBackupURL.Text);
    I.WriteString('Setup', '外挂检测', FCheckURL.Text);
    I.WriteString('Setup', '推广ID', FPromotionID.Text);
    I.WriteString('Setup', '公告地址', FNoticeURL.Text);
    I.WriteString('Setup', '官方首页', FHomeURL.Text);
    I.WriteString('Setup', '客户服务', FServiceURL.Text);
    I.WriteBool('Setup', '自动刷新', FAutoRefresh.Checked);
    I.WriteString('Setup', '刷新速度', FRefreshSeconds.Text);
    SaveEditorData(I);
  finally
    I.Free;
  end;
  if Sender <> nil then
    MessageDlg('配置保存成功。', mtInformation, [mbOK], 0);
end;

procedure TFrmMain.GenerateLogin(Sender: TObject);
var
  TargetDir, TargetFile, ClientFile, ClientOutputFile, ClientDataFile: string;
  BootstrapFile, LaunchConfigFile, SkinFile: string;
  ClientResource: TResourceStream;
  Ini, IntegrationIni: TIniFile;
  ClientParam: TLoginClientParam;
  Key: Integer;
  I: Integer;
  KeyArg, ParamArg, CommandLine: AnsiString;
  TestProcess: TProcessInformation;
  StartInfo: TStartupInfo;
  TestPassed: Boolean;
  PayloadNames: TStringList;
  PayloadOffsets, PayloadSizes: array of Int64;
  PayloadHashes: array of string;
const
  IntegrationFileKeys: array[0..11] of string = (
    '外挂检测列表文件', '服务器列表文件', '物品备注文件',
    '顶行物品备注文件', '内挂捡起物品文件', '套装备注文件',
    '神佑备注文件', '怪物配置文件', '技能配置文件', 'NPC配置文件',
    '风盾dll文件', '恶魔盾dll文件');
  procedure CopyTree(const SourceDir, TargetRoot: string);
  var
    Search: TSearchRec;
    SourceName, TargetName: string;
  begin
    if not DirectoryExists(SourceDir) then
      Exit;
    ForceDirectories(TargetRoot);
    if FindFirst(IncludeTrailingPathDelimiter(SourceDir) + '*',
      faAnyFile, Search) <> 0 then
      Exit;
    try
      repeat
        if (Search.Name = '.') or (Search.Name = '..') then
          Continue;
        SourceName := IncludeTrailingPathDelimiter(SourceDir) + Search.Name;
        TargetName := IncludeTrailingPathDelimiter(TargetRoot) + Search.Name;
        if (Search.Attr and faDirectory) <> 0 then
          CopyTree(SourceName, TargetName)
        else
          CopyFile(PChar(SourceName), PChar(TargetName), False);
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
  end;
  function LocalPath(const Value: string): string;
  begin
    Result := Trim(Value);
    if Result = '' then
      Exit;
    if not FileExists(Result) and not DirectoryExists(Result) then
      Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + Result;
    Result := ExpandFileName(Result);
  end;
  procedure CopyFileIfPresent(const SourceName, TargetName: string);
  begin
    if FileExists(SourceName) then
      CopyFile(PChar(SourceName), PChar(TargetName), False);
  end;
  procedure AddPayloadFile(const RelativeName, SourceName: string);
  begin
    if (Trim(RelativeName) = '') or not FileExists(SourceName) then
      Exit;
    if PayloadNames.IndexOfName(RelativeName) < 0 then
      PayloadNames.Add(RelativeName + '=' + SourceName);
  end;
  procedure AddPayloadTree(const SourceDir, RelativeRoot: string);
  var
    Search: TSearchRec;
    SourceName, RelativeName: string;
  begin
    if not DirectoryExists(SourceDir) then
      Exit;
    if FindFirst(IncludeTrailingPathDelimiter(SourceDir) + '*',
      faAnyFile, Search) <> 0 then
      Exit;
    try
      repeat
        if (Search.Name = '.') or (Search.Name = '..') then
          Continue;
        SourceName := IncludeTrailingPathDelimiter(SourceDir) + Search.Name;
        RelativeName := RelativeRoot + Search.Name;
        if (Search.Attr and faDirectory) <> 0 then
          AddPayloadTree(SourceName, RelativeName + '\')
        else
          AddPayloadFile(RelativeName, SourceName);
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
  end;
  procedure AppendPayload;
  var
    Stream, Source: TFileStream;
    I, J, MatchIndex, NameLength: Integer;
    Name, SourceName: string;
    NameBytes: TBytes;
    SourceHash: string;
    ManifestOffset, ManifestSize, OriginalSize: Int64;
    Trailer: TPayloadTrailer;
  begin
    if (PayloadNames = nil) or (PayloadNames.Count = 0) then
      Exit;
    SetLength(PayloadOffsets, PayloadNames.Count);
    SetLength(PayloadSizes, PayloadNames.Count);
    SetLength(PayloadHashes, PayloadNames.Count);
    Stream := TFileStream.Create(TargetFile, fmOpenReadWrite or fmShareDenyWrite);
    try
      OriginalSize := Stream.Size;
      Stream.Position := OriginalSize;
      for I := 0 to PayloadNames.Count - 1 do
      begin
        Name := PayloadNames.Names[I];
        SourceName := PayloadNames.ValueFromIndex[I];
        SourceHash := '';
        Source := TFileStream.Create(SourceName, fmOpenRead or fmShareDenyNone);
        try
          SourceHash := THashMD5.GetHashString(Source);
        finally
          Source.Free;
        end;
        MatchIndex := -1;
        for J := 0 to I - 1 do
          if SameText(PayloadHashes[J], SourceHash) then
          begin
            MatchIndex := J;
            Break;
          end;
        if MatchIndex >= 0 then
        begin
          PayloadOffsets[I] := PayloadOffsets[MatchIndex];
          PayloadSizes[I] := PayloadSizes[MatchIndex];
          PayloadHashes[I] := SourceHash;
          Continue;
        end;
        PayloadOffsets[I] := Stream.Position;
        Source := TFileStream.Create(SourceName, fmOpenRead or fmShareDenyNone);
        try
          PayloadSizes[I] := Source.Size;
          Stream.CopyFrom(Source, 0);
        finally
          Source.Free;
        end;
        PayloadHashes[I] := SourceHash;
      end;
      ManifestOffset := Stream.Position;
      ManifestSize := 0;
      for I := 0 to PayloadNames.Count - 1 do
      begin
        NameBytes := TEncoding.UTF8.GetBytes(PayloadNames.Names[I]);
        NameLength := Length(NameBytes);
        Stream.WriteBuffer(NameLength, SizeOf(NameLength));
        if NameLength > 0 then
          Stream.WriteBuffer(NameBytes[0], NameLength);
        Stream.WriteBuffer(PayloadOffsets[I], SizeOf(Int64));
        Stream.WriteBuffer(PayloadSizes[I], SizeOf(Int64));
        Inc(ManifestSize, SizeOf(NameLength) + NameLength +
          2 * SizeOf(Int64));
      end;
      FillChar(Trailer, SizeOf(Trailer), 0);
      Trailer.Magic[0] := 'G'; Trailer.Magic[1] := 'X';
      Trailer.Magic[2] := 'X'; Trailer.Magic[3] := 'P';
      Trailer.Magic[4] := 'A'; Trailer.Magic[5] := 'Y';
      Trailer.Magic[6] := 'L'; Trailer.Magic[7] := '1';
      Trailer.Version := 1;
      Trailer.EntryCount := PayloadNames.Count;
      Trailer.ManifestOffset := ManifestOffset;
      Trailer.ManifestSize := ManifestSize;
      Trailer.OriginalSize := OriginalSize;
      Stream.WriteBuffer(Trailer, SizeOf(Trailer));
    finally
      Stream.Free;
    end;
  end;
  procedure WriteLauncherSettings;
  var
    Settings, SourceSettings: TMemIniFile;
  begin
    LaunchConfigFile := IncludeTrailingPathDelimiter(TargetDir) + 'Launcher.ini';
    Settings := TMemIniFile.Create(LaunchConfigFile, TEncoding.UTF8);
    SourceSettings := TMemIniFile.Create(IniName, TEncoding.Default);
    try
      Settings.WriteString('Launcher', 'Title', Trim(FLoginTitle.Text));
      Settings.WriteString('Launcher', 'ClientFile', 'Client.exe');
      Settings.WriteString('Launcher', 'ClientDataFile', ExtractFileName(ClientDataFile));
      Settings.WriteString('Launcher', 'ConfigURL', Trim(FConfigURL.Text));
      Settings.WriteString('Launcher', 'BackupURL', Trim(FBackupURL.Text));
      Settings.WriteString('Launcher', 'NoticeURL', Trim(FNoticeURL.Text));
      Settings.WriteString('Launcher', 'HomeURL', Trim(FHomeURL.Text));
      Settings.WriteString('Launcher', 'ServiceURL', Trim(FServiceURL.Text));
      Settings.WriteString('Launcher', 'UpdatePassword', Trim(FMicroPassword.Text));
      Settings.WriteString('Launcher', 'PromotionID', Trim(FPromotionID.Text));
      // Keep the generator's client mode in both Launcher.ini and Client.dat.
      // The launcher uses it when choosing the micro-update endpoint, while
      // the client reads the same value from its packed data file.
      Settings.WriteInteger('Launcher', 'LoginMode', FLoginMode.ItemIndex);
      Settings.WriteInteger('Launcher', 'MaxClients', ClampInt(
        SourceSettings.ReadInteger('Setup', '多开数量', 6), 1, 30));
      Settings.WriteInteger('Launcher', 'ScreenWidth', ClampInt(
        SourceSettings.ReadInteger('Setup', 'ScreenWidth', 800), 320, High(Word)));
      Settings.WriteInteger('Launcher', 'ScreenHeight', ClampInt(
        SourceSettings.ReadInteger('Setup', 'ScreenHeight', 600), 200, High(Word)));
      Settings.WriteBool('Launcher', 'WindowMode',
        SourceSettings.ReadBool('Setup', 'WindowMode', True));
      Settings.WriteBool('Launcher', 'VSync',
        SourceSettings.ReadBool('Setup', 'VSync', True));
      Settings.WriteBool('Launcher', 'Hardware',
        SourceSettings.ReadBool('Setup', 'Hardware', True));
      Settings.WriteBool('Launcher', 'AutoRefresh', FAutoRefresh.Checked);
      Settings.WriteInteger('Launcher', 'RefreshSeconds', ClampInt(
        StrToIntDef(Trim(FRefreshSeconds.Text), 120), 1, 9999));
      Settings.UpdateFile;
    finally
      SourceSettings.Free;
      Settings.Free;
    end;
  end;
begin
  SaveConfig(nil);
  TargetDir := '';
  if not SelectDirectory('浏览文件夹', '', TargetDir) then
    Exit;
  TargetFile := IncludeTrailingPathDelimiter(TargetDir) +
    ChangeFileExt(Trim(FLoginTitle.Text), '.exe');
  if SameText(ExtractFileName(TargetFile), 'Client.exe') then
  begin
    MessageDlg('登录器名称不能为 Client，否则会与游戏客户端冲突。',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  if FileExists(TargetFile) and
    (MessageDlg('文件已经存在，是否覆盖？', mtConfirmation,
      [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  // LoginBootstrap is the generated launcher's UI.  Client.exe is started
  // only after the player selects a server and clicks Start Game.
  BootstrapFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'LoginBootstrap.exe';
  if FileExists(BootstrapFile) then
  begin
    if not CopyFile(PChar(BootstrapFile), PChar(TargetFile), False) then
      RaiseLastOSError;
  end
  else
  begin
    try
      ClientResource := TResourceStream.Create(HInstance,
        'LOGINBOOTSTRAP', RT_RCDATA);
      try
        ClientResource.SaveToFile(TargetFile);
      finally
        ClientResource.Free;
      end;
    except
      on E: Exception do
      begin
        MessageDlg('登录器模板资源损坏，无法生成：' + E.Message,
          mtError, [mbOK], 0);
        Exit;
      end;
    end;
  end;

  ClientFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    Trim(FClientFile.Text);
  ClientOutputFile := IncludeTrailingPathDelimiter(TargetDir) + 'Client.exe';
  // The legacy default is Client.dat (the data file), not an executable.
  // Never copy a data/config file over Client.exe; use a supplied executable
  // only when the configured path actually points to one.
  if FileExists(ClientFile) and
    SameText(ExtractFileExt(ClientFile), '.exe') and
    not SameFileName(ClientFile, TargetFile) then
    CopyFile(PChar(ClientFile), PChar(ClientOutputFile), False)
  else if not SameFileName(TargetFile, ClientOutputFile) then
  begin
    try
      ClientResource := TResourceStream.Create(HInstance,
        'CLIENTLATEST', RT_RCDATA);
    except
      ClientResource := TResourceStream.Create(HInstance, 'CLIENT', RT_RCDATA);
    end;
    try
      ClientResource.SaveToFile(ClientOutputFile);
    finally
      ClientResource.Free;
    end;
  end;

  { Keep the files selected by the original generator beside the client.  The
    client still reads these names from ClientData when a custom build does
    not embed the corresponding payload. }
  ClientFile := LocalPath(FClientFile.Text);
  if FileExists(ClientFile) and
     not SameText(ExtractFileExt(ClientFile), '.exe') then
    CopyFileIfPresent(ClientFile,
      IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(ClientFile));
  if FRequiredPatch.Checked then
  begin
    ClientFile := LocalPath(FPatchFile.Text);
    if FileExists(ClientFile) then
      CopyFileIfPresent(ClientFile,
        IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(ClientFile));
  end;
  ClientFile := LocalPath(FResourcesDir.Text);
  if not DirectoryExists(ClientFile) and
     SameText(ExtractFileName(ExcludeTrailingPathDelimiter(FResourcesDir.Text)),
       'Resources') then
    ClientFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
      'tools\original-runtime\Resources';
  if DirectoryExists(ClientFile) then
    CopyTree(ClientFile,
      IncludeTrailingPathDelimiter(TargetDir) +
      ExtractFileName(ExcludeTrailingPathDelimiter(ClientFile)));
  ClientFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'NewUI';
  if DirectoryExists(ClientFile) then
    CopyTree(ClientFile, IncludeTrailingPathDelimiter(TargetDir) + 'NewUI');
  ClientFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'bass.dll';
  if not FileExists(ClientFile) then
    ClientFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
      'tools\original-runtime\bass.dll';
  CopyFileIfPresent(ClientFile,
    IncludeTrailingPathDelimiter(TargetDir) + 'bass.dll');

  // The embedded client and the generated launcher use the legacy DirectX 8
  // helper DLL at run time.  Keep the dependency beside the generated files,
  // matching the original distribution layout, while remaining harmless when
  // a custom build does not ship the DLL.
  ClientFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'D3DX81ab.dll';
  if FileExists(ClientFile) then
    CopyFile(PChar(ClientFile),
      PChar(IncludeTrailingPathDelimiter(TargetDir) + 'D3DX81ab.dll'), False);

  ClientDataFile := IncludeTrailingPathDelimiter(TargetDir) +
    ExtractFileName(Trim(FClientData.Text));
  if ExtractFileName(ClientDataFile) = '' then
    ClientDataFile := IncludeTrailingPathDelimiter(TargetDir) + 'Client.dat';
  CreateClientDataFile(ClientDataFile, IniName);
  // The generated client reads these companion configuration files from its
  // working directory.  Keep them beside the launcher and in the appended
  // payload so the self-extracting build behaves like the loose-file build.
  CopyFileIfPresent(IniName,
    IncludeTrailingPathDelimiter(TargetDir) + 'Config.ini');
  IntegrationIni := TIniFile.Create(IniName);
  try
    for I := Low(IntegrationFileKeys) to High(IntegrationFileKeys) do
    begin
      ClientFile := LocalPath(IntegrationIni.ReadString('Setup',
        IntegrationFileKeys[I], ''));
      if FileExists(ClientFile) then
        CopyFileIfPresent(ClientFile,
          IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(ClientFile));
    end;
  finally
    IntegrationIni.Free;
  end;
  ClientFile := LocalPath(FLoginConfig.Text);
  if FileExists(ClientFile) then
    CopyFileIfPresent(ClientFile,
      IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(ClientFile));
  ClientFile := LocalPath(FLoginSkin.Text);
  if FileExists(ClientFile) then
    CopyFileIfPresent(ClientFile,
      IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(ClientFile));
  ClientFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'GUI_Config.ini';
  CopyFileIfPresent(ClientFile,
    IncludeTrailingPathDelimiter(TargetDir) + 'GUI_Config.ini');

  SkinFile := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'loginskin';
  CopyFileIfPresent(SkinFile,
    IncludeTrailingPathDelimiter(TargetDir) + 'loginskin');
  WriteLauncherSettings;

  // Add every runtime file under a relative, traversal-safe name.  The
  // external copies above remain in place for clients that do not use the
  // bootstrap, while the generated launcher itself is self-contained.
  PayloadNames := TStringList.Create;
  try
    PayloadNames.NameValueSeparator := '=';
    AddPayloadFile('Client.exe', ClientOutputFile);
    AddPayloadFile(ExtractFileName(ClientDataFile), ClientDataFile);
    AddPayloadFile('Config.ini',
      IncludeTrailingPathDelimiter(TargetDir) + 'Config.ini');
    AddPayloadFile('Launcher.ini', LaunchConfigFile);
    AddPayloadFile('loginskin',
      IncludeTrailingPathDelimiter(TargetDir) + 'loginskin');
    IntegrationIni := TIniFile.Create(IniName);
    try
      for I := Low(IntegrationFileKeys) to High(IntegrationFileKeys) do
      begin
        ClientFile := ExtractFileName(LocalPath(IntegrationIni.ReadString(
          'Setup', IntegrationFileKeys[I], '')));
        if ClientFile <> '' then
          AddPayloadFile(ClientFile,
            IncludeTrailingPathDelimiter(TargetDir) + ClientFile);
      end;
    finally
      IntegrationIni.Free;
    end;
    AddPayloadFile(ExtractFileName(ClientFile),
      IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(ClientFile));
    AddPayloadFile(ExtractFileName(LocalPath(FLoginConfig.Text)),
      IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(
      LocalPath(FLoginConfig.Text)));
    AddPayloadFile(ExtractFileName(LocalPath(FLoginSkin.Text)),
      IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(
      LocalPath(FLoginSkin.Text)));
    AddPayloadFile(ExtractFileName(IncludeTrailingPathDelimiter(TargetDir) +
      ExtractFileName(Trim(FClientFile.Text))),
      IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(
      Trim(FClientFile.Text)));
    AddPayloadFile(ExtractFileName(IncludeTrailingPathDelimiter(TargetDir) +
      ExtractFileName(Trim(FPatchFile.Text))),
      IncludeTrailingPathDelimiter(TargetDir) + ExtractFileName(
      Trim(FPatchFile.Text)));
    AddPayloadTree(IncludeTrailingPathDelimiter(TargetDir) + 'Resources',
      'Resources\');
    AddPayloadTree(IncludeTrailingPathDelimiter(TargetDir) + 'NewUI',
      'NewUI\');
    AddPayloadFile('bass.dll',
      IncludeTrailingPathDelimiter(TargetDir) + 'bass.dll');
    AddPayloadFile('D3DX81ab.dll',
      IncludeTrailingPathDelimiter(TargetDir) + 'D3DX81ab.dll');
    AppendPayload;
  finally
    PayloadNames.Free;
    PayloadNames := nil;
  end;

  FillChar(ClientParam, SizeOf(ClientParam), 0);
  ClientParam.Handle := Handle;
  ClientParam.sGameLoginFileName := ExtractFileName(TargetFile);
  ClientParam.sServerCaption := Trim(FLoginTitle.Text);
  ClientParam.sServeraddr := Trim(FMainIP.Text);
  ClientParam.nServerPort := StrToIntDef(Trim(FMainPort.Text), 7000);
  ClientParam.sUpdateAddr := Trim(FMainIP.Text);
  ClientParam.nUpdatePort := StrToIntDef(Trim(FMainPort.Text), 7000);
  if Trim(FMicroPassword.Text) <> '' then
    ClientParam.sUpdatePassWord := EncryptLegacyStringWithKey(
      AnsiString(Trim(FMicroPassword.Text)), '3230393649');
  ClientParam.sHomePage := Trim(FHomeURL.Text);
  ClientParam.btMaxClientCount := 6;
  ClientParam.wScreenWidth := 800;
  ClientParam.wScreenHeight := 600;
  ClientParam.btBitCount := 32;
  ClientParam.boWindowMode := True;
  ClientParam.boVSync := True;
  ClientParam.boHardware := True;
  ClientParam.ClientVersion := cvSerial;
  ClientParam.sSemaphoreName := 'GxxClient_' + IntToHex(GetTickCount, 8);
  // Use the actual output name, including the Client.dat fallback when the
  // edit box is left empty, so the generated client and payload agree.
  ClientParam.sClientDataFile := ExtractFileName(ClientDataFile);
  ClientParam.sPromotionFlag := Trim(FPromotionID.Text);
  Ini := TIniFile.Create(IniName);
  try
    ClientParam.btMaxClientCount := Byte(ClampInt(
      Ini.ReadInteger('Setup', '多开数量', 6), 1, 30));
    ClientParam.wScreenWidth := Word(ClampInt(
      Ini.ReadInteger('Setup', 'ScreenWidth', 800), 320, High(Word)));
    ClientParam.wScreenHeight := Word(ClampInt(
      Ini.ReadInteger('Setup', 'ScreenHeight', 600), 200, High(Word)));
    ClientParam.boWindowMode := Ini.ReadBool('Setup', 'WindowMode', True);
    ClientParam.boVSync := Ini.ReadBool('Setup', 'VSync', True);
    ClientParam.boHardware := Ini.ReadBool('Setup', 'Hardware', True);
  finally
    Ini.Free;
  end;

  Key := RandomClientKey;
  KeyArg := EncryptLegacyStringWithKey(AnsiString(IntToStr(Key)), '3230393649');
  ParamArg := EncryptClientParam(ClientParam, Key);
  CommandLine := '"' + AnsiString(IncludeTrailingPathDelimiter(TargetDir) +
    'Client.exe') + '" 0 ' + KeyArg + ' ' + ParamArg;
  FillChar(StartInfo, SizeOf(StartInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  FillChar(TestProcess, SizeOf(TestProcess), 0);
  UniqueString(CommandLine);
  TestPassed := CreateProcess(nil, PChar(string(CommandLine)), nil, nil, False,
    CREATE_SUSPENDED, nil, PChar(TargetDir), StartInfo, TestProcess);
  if TestPassed then
  begin
    TerminateProcess(TestProcess.hProcess, 0);
    CloseHandle(TestProcess.hThread);
    CloseHandle(TestProcess.hProcess);
  end;

  with TStringList.Create do
  try
    Add('@echo off');
    Add('start "" "Client.exe" 0 "' + string(KeyArg) + '" "' +
      string(ParamArg) + '"');
    SaveToFile(IncludeTrailingPathDelimiter(TargetDir) + '启动游戏.bat', TEncoding.ANSI);
  finally
    Free;
  end;

  if TestPassed then
    MessageDlg('登录器及客户端启动参数生成成功：' + sLineBreak + TargetFile,
      mtInformation, [mbOK], 0)
  else
    MessageDlg('登录器已生成，但客户端启动参数验证失败。', mtWarning, [mbOK], 0);
end;

procedure TFrmMain.ConfigNext(Sender: TObject);
begin
  if FConfigPages.ActivePageIndex < FConfigPages.PageCount - 1 then
    FConfigPages.ActivePageIndex := FConfigPages.ActivePageIndex + 1;
  ConfigPageChanged(nil);
end;

procedure TFrmMain.ConfigPrevious(Sender: TObject);
begin
  if FConfigPages.ActivePageIndex > 0 then
    FConfigPages.ActivePageIndex := FConfigPages.ActivePageIndex - 1;
  ConfigPageChanged(nil);
end;

procedure TFrmMain.ConfigPageChanged(Sender: TObject);
begin
  FConfigPreviousButton.Visible := FConfigPages.ActivePageIndex > 0;
  if FConfigPages.ActivePageIndex = FConfigPages.PageCount - 1 then
  begin
    FConfigNextButton.Caption := '生成列表(&N)';
    FConfigNextButton.OnClick := GenerateList;
  end
  else
  begin
    FConfigNextButton.Caption := '下一步(&N)';
    FConfigNextButton.OnClick := ConfigNext;
  end;
end;

procedure TFrmMain.SelectUpdateFile(Sender: TObject);
var
  D: TOpenDialog;
begin
  D := TOpenDialog.Create(Self);
  try
    if D.Execute then
    begin
      FUpdateFile.Text := ExtractFileName(D.FileName);
      FUpdateMD5.Text := FileMD5(D.FileName);
    end;
  finally
    D.Free;
  end;
end;

procedure TFrmMain.AddUpdate(Sender: TObject);
var
  Item: TListItem;
begin
  if Trim(FUpdateFile.Text) = '' then
  begin
    MessageDlg('请输入或选择文件名称。', mtWarning, [mbOK], 0);
    Exit;
  end;
  Item := FUpdateList.Items.Add;
  Item.Caption := GetUpdateTypeName(GetUpdateType);
  Item.SubItems.Add(FUpdateDirectory.Text);
  Item.SubItems.Add(FUpdateFile.Text);
  Item.SubItems.Add(FUpdateMD5.Text);
  Item.SubItems.Add(FUpdateURL.Text);
  Item.Selected := True;
  UpdateUpdateButtons;
end;

function TFrmMain.FileMD5(const AFileName: string): string;
var
  S: TFileStream;
begin
  S := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := UpperCase(THashMD5.GetHashString(S));
  finally
    S.Free;
  end;
end;

function TFrmMain.GetUpdateType: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(FUpdateTypes) to High(FUpdateTypes) do
    if FUpdateTypes[I].Checked then
      Exit(I);
end;

procedure TFrmMain.SetUpdateType(AIndex: Integer);
begin
  if not (AIndex in [0..3]) then
    AIndex := 0;
  FUpdateTypes[AIndex].Checked := True;
end;

function TFrmMain.GetUpdateTypeName(AIndex: Integer): string;
const
  Names: array[0..3] of string =
    ('普通文件', '登陆器文件', 'ZIP压缩文件', '7Z压缩文件');
begin
  if not (AIndex in [0..3]) then
    AIndex := 0;
  Result := Names[AIndex];
end;

procedure TFrmMain.FillUpdateEditor(AItem: TListItem);
var
  I: Integer;
begin
  if (AItem = nil) or (AItem.SubItems.Count < 4) then
    Exit;
  for I := 0 to 3 do
    if SameText(AItem.Caption, GetUpdateTypeName(I)) then
    begin
      SetUpdateType(I);
      Break;
    end;
  FUpdateDirectory.ItemIndex := FUpdateDirectory.Items.IndexOf(AItem.SubItems[0]);
  if FUpdateDirectory.ItemIndex < 0 then
    FUpdateDirectory.Text := AItem.SubItems[0];
  FUpdateFile.Text := AItem.SubItems[1];
  FUpdateMD5.Text := AItem.SubItems[2];
  FUpdateURL.Text := AItem.SubItems[3];
end;

procedure TFrmMain.UpdateSelected(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected then
    FillUpdateEditor(Item);
  UpdateUpdateButtons;
end;

procedure TFrmMain.UpdateUpdateButtons;
begin
  FEditUpdateButton.Enabled := FUpdateList.Selected <> nil;
  FDeleteUpdateButton.Enabled := FUpdateList.Selected <> nil;
end;

procedure TFrmMain.EditUpdate(Sender: TObject);
var
  Item: TListItem;
begin
  Item := FUpdateList.Selected;
  if Item = nil then Exit;
  Item.Caption := GetUpdateTypeName(GetUpdateType);
  while Item.SubItems.Count < 4 do Item.SubItems.Add('');
  Item.SubItems[0] := FUpdateDirectory.Text;
  Item.SubItems[1] := FUpdateFile.Text;
  Item.SubItems[2] := FUpdateMD5.Text;
  Item.SubItems[3] := FUpdateURL.Text;
end;

procedure TFrmMain.DeleteUpdate(Sender: TObject);
begin
  if FUpdateList.Selected <> nil then
    FUpdateList.Selected.Delete;
  UpdateUpdateButtons;
end;

procedure TFrmMain.WMDropFiles(var Msg: TWMDropFiles);
var
  FileName: array[0..MAX_PATH] of Char;
begin
  try
    if DragQueryFile(Msg.Drop, 0, FileName, Length(FileName)) > 0 then
    begin
      FMainPages.ActivePageIndex := 1;
      FConfigPages.ActivePageIndex := 2;
      ConfigPageChanged(nil);
      FUpdateFile.Text := ExtractFileName(FileName);
      FUpdateMD5.Text := FileMD5(FileName);
    end;
  finally
    DragFinish(Msg.Drop);
  end;
end;

function TFrmMain.FindGroup(const AName: string): TTreeNode;
var
  Node: TTreeNode;
begin
  Result := nil;
  Node := FServerTree.Items.GetFirstNode;
  while Node <> nil do
  begin
    if (Node.Level = 0) and SameText(Node.Text, Trim(AName)) then
      Exit(Node);
    Node := Node.GetNextSibling;
  end;
end;

function TFrmMain.SelectedGroup: TTreeNode;
begin
  Result := FServerTree.Selected;
  if (Result <> nil) and (Result.Level > 0) then
    Result := Result.Parent;
end;

procedure TFrmMain.UpdateServerButtons;
var
  Node: TTreeNode;
begin
  Node := FServerTree.Selected;
  FEditGroupButton.Enabled := (Node <> nil) and (Node.Level = 0);
  FDeleteGroupButton.Enabled := FEditGroupButton.Enabled;
  FAddServerButton.Enabled := FServerTree.Items.Count > 0;
  FEditServerButton.Enabled := (Node <> nil) and (Node.Level > 0);
  FDeleteServerButton.Enabled := FEditServerButton.Enabled;
end;

procedure TFrmMain.FillServerEditor(ANode: TTreeNode);
var
  Entry: TServerEntry;
begin
  if ANode = nil then Exit;
  if ANode.Level = 0 then
  begin
    FGroupName.Text := ANode.Text;
    FServerGroup.Text := ANode.Text;
    Exit;
  end;
  Entry := TServerEntry(ANode.Data);
  if Entry = nil then Exit;
  FServerGroup.Text := Entry.GroupName;
  FServerName.Text := Entry.ServerName;
  FServerIP.Text := Entry.Address;
  FServerPort.Text := Entry.Port;
  FServerMicroIP.Text := Entry.MicroAddress;
  FServerMicroPort.Text := Entry.MicroPort;
  FServerFirewallPort.Text := Entry.FirewallPort;
  FServerAutoExpand.Checked := Entry.AutoExpand;
end;

procedure TFrmMain.ServerSelectionChanged(Sender: TObject; Node: TTreeNode);
begin
  FillServerEditor(Node);
  UpdateServerButtons;
end;

procedure TFrmMain.AddServerGroup(Sender: TObject);
var
  Node: TTreeNode;
begin
  if Trim(FGroupName.Text) = '' then Exit;
  Node := FindGroup(FGroupName.Text);
  if Node = nil then
    Node := FServerTree.Items.Add(nil, Trim(FGroupName.Text));
  FServerTree.Selected := Node;
  FServerGroup.Text := Node.Text;
  UpdateServerButtons;
end;

procedure TFrmMain.EditServerGroup(Sender: TObject);
var
  Node, Child: TTreeNode;
  Entry: TServerEntry;
begin
  Node := FServerTree.Selected;
  if (Node = nil) or (Node.Level <> 0) or (Trim(FGroupName.Text) = '') then Exit;
  if (FindGroup(FGroupName.Text) <> nil) and
     (FindGroup(FGroupName.Text) <> Node) then
  begin
    MessageDlg('已经存在同名分组。', mtWarning, [mbOK], 0);
    Exit;
  end;
  Node.Text := Trim(FGroupName.Text);
  Child := Node.GetFirstChild;
  while Child <> nil do
  begin
    Entry := TServerEntry(Child.Data);
    if Entry <> nil then Entry.GroupName := Node.Text;
    Child := Child.GetNextSibling;
  end;
  FServerGroup.Text := Node.Text;
end;

procedure TFrmMain.DeleteServerGroup(Sender: TObject);
var
  Node, Child: TTreeNode;
begin
  Node := FServerTree.Selected;
  if (Node = nil) or (Node.Level <> 0) then Exit;
  if MessageDlg('确定删除该分组及其中的服务器吗？', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  Child := Node.GetFirstChild;
  while Child <> nil do
  begin
    TObject(Child.Data).Free;
    Child.Data := nil;
    Child := Child.GetNextSibling;
  end;
  Node.Delete;
  UpdateServerButtons;
end;

procedure TFrmMain.AddServer(Sender: TObject);
var
  GroupNode, Node: TTreeNode;
  Entry: TServerEntry;
begin
  GroupNode := FindGroup(FServerGroup.Text);
  if GroupNode = nil then GroupNode := SelectedGroup;
  if GroupNode = nil then
  begin
    MessageDlg('请先增加服务器分组。', mtWarning, [mbOK], 0);
    Exit;
  end;
  if Trim(FServerName.Text) = '' then Exit;
  Entry := TServerEntry.Create;
  Entry.GroupName := GroupNode.Text;
  Entry.DisplayName := Trim(FServerName.Text);
  Entry.ServerName := Trim(FServerName.Text);
  Entry.Address := Trim(FServerIP.Text);
  Entry.Port := Trim(FServerPort.Text);
  Entry.AutoExpand := FServerAutoExpand.Checked;
  Entry.MicroAddress := Trim(FServerMicroIP.Text);
  Entry.MicroPort := Trim(FServerMicroPort.Text);
  Entry.FirewallPort := Trim(FServerFirewallPort.Text);
  Entry.FirewallType := '0';
  Node := FServerTree.Items.AddChildObject(GroupNode, Entry.DisplayName, Entry);
  GroupNode.Expand(False);
  FServerTree.Selected := Node;
  UpdateServerButtons;
end;

procedure TFrmMain.EditServer(Sender: TObject);
var
  Node, GroupNode: TTreeNode;
  Entry: TServerEntry;
begin
  Node := FServerTree.Selected;
  if (Node = nil) or (Node.Level = 0) then Exit;
  Entry := TServerEntry(Node.Data);
  if Entry = nil then Exit;
  GroupNode := FindGroup(FServerGroup.Text);
  if GroupNode = nil then GroupNode := Node.Parent;
  Entry.GroupName := GroupNode.Text;
  Entry.DisplayName := Trim(FServerName.Text);
  Entry.ServerName := Trim(FServerName.Text);
  Entry.Address := Trim(FServerIP.Text);
  Entry.Port := Trim(FServerPort.Text);
  Entry.AutoExpand := FServerAutoExpand.Checked;
  Entry.MicroAddress := Trim(FServerMicroIP.Text);
  Entry.MicroPort := Trim(FServerMicroPort.Text);
  Entry.FirewallPort := Trim(FServerFirewallPort.Text);
  if Entry.FirewallType = '' then Entry.FirewallType := '0';
  Node.Text := Entry.DisplayName;
  if Node.Parent <> GroupNode then Node.MoveTo(GroupNode, naAddChild);
end;

procedure TFrmMain.DeleteServer(Sender: TObject);
var
  Node: TTreeNode;
begin
  Node := FServerTree.Selected;
  if (Node = nil) or (Node.Level = 0) then Exit;
  TObject(Node.Data).Free;
  Node.Data := nil;
  Node.Delete;
  UpdateServerButtons;
end;

procedure TFrmMain.LoadEditorData(AIni: TIniFile);
var
  I, Count, TypeIndex: Integer;
  Parts: TStringList;
  GroupNode: TTreeNode;
  Entry: TServerEntry;
  Item: TListItem;
  S: string;
begin
  Count := AIni.ReadInteger('ServerEditor', 'GroupCount', 0);
  for I := 0 to Count - 1 do
  begin
    S := AIni.ReadString('ServerEditor', 'Group' + IntToStr(I), '');
    if (S <> '') and (FindGroup(S) = nil) then FServerTree.Items.Add(nil, S);
  end;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := '|';
    Count := AIni.ReadInteger('ServerEditor', 'ServerCount', 0);
    for I := 0 to Count - 1 do
    begin
      Parts.DelimitedText := AIni.ReadString('ServerEditor', 'Server' + IntToStr(I), '');
      if Parts.Count < 10 then Continue;
      GroupNode := FindGroup(Parts[0]);
      if GroupNode = nil then GroupNode := FServerTree.Items.Add(nil, Parts[0]);
      Entry := TServerEntry.Create;
      Entry.GroupName := Parts[0]; Entry.DisplayName := Parts[1];
      Entry.ServerName := Parts[2]; Entry.Address := Parts[3]; Entry.Port := Parts[4];
      Entry.AutoExpand := StrToIntDef(Parts[5], 0) <> 0;
      Entry.MicroAddress := Parts[6]; Entry.MicroPort := Parts[7];
      Entry.FirewallPort := Parts[8]; Entry.FirewallType := Parts[9];
      FServerTree.Items.AddChildObject(GroupNode, Entry.DisplayName, Entry);
      if Entry.AutoExpand then GroupNode.Expand(False);
    end;
    Count := AIni.ReadInteger('UpdateEditor', 'Count', 0);
    for I := 0 to Count - 1 do
    begin
      Parts.DelimitedText := AIni.ReadString('UpdateEditor', IntToStr(I), '');
      if Parts.Count < 5 then Continue;
      TypeIndex := StrToIntDef(Parts[0], 0);
      Item := FUpdateList.Items.Add;
      Item.Caption := GetUpdateTypeName(TypeIndex);
      Item.SubItems.Add(Parts[1]); Item.SubItems.Add(Parts[2]);
      Item.SubItems.Add(Parts[3]); Item.SubItems.Add(Parts[4]);
    end;
  finally
    Parts.Free;
  end;
  UpdateServerButtons;
  UpdateUpdateButtons;
end;

procedure TFrmMain.SaveEditorData(AIni: TIniFile);
var
  I, GroupCount, ServerCount, TypeIndex: Integer;
  Node: TTreeNode;
  Entry: TServerEntry;
  Item: TListItem;
begin
  AIni.EraseSection('ServerEditor');
  GroupCount := 0; ServerCount := 0;
  Node := FServerTree.Items.GetFirstNode;
  while Node <> nil do
  begin
    if Node.Level = 0 then
    begin
      AIni.WriteString('ServerEditor', 'Group' + IntToStr(GroupCount), Node.Text);
      Inc(GroupCount);
    end
    else if Node.Data <> nil then
    begin
      Entry := TServerEntry(Node.Data);
      AIni.WriteString('ServerEditor', 'Server' + IntToStr(ServerCount),
        Entry.GroupName + '|' + Entry.DisplayName + '|' + Entry.ServerName + '|' +
        Entry.Address + '|' + Entry.Port + '|' + IntToStr(Ord(Entry.AutoExpand)) + '|' +
        Entry.MicroAddress + '|' + Entry.MicroPort + '|' + Entry.FirewallPort + '|' +
        Entry.FirewallType);
      Inc(ServerCount);
    end;
    Node := Node.GetNext;
  end;
  AIni.WriteInteger('ServerEditor', 'GroupCount', GroupCount);
  AIni.WriteInteger('ServerEditor', 'ServerCount', ServerCount);

  AIni.EraseSection('UpdateEditor');
  AIni.WriteInteger('UpdateEditor', 'Count', FUpdateList.Items.Count);
  for I := 0 to FUpdateList.Items.Count - 1 do
  begin
    Item := FUpdateList.Items[I]; TypeIndex := 0;
    while (TypeIndex < 3) and not SameText(Item.Caption,
      GetUpdateTypeName(TypeIndex)) do Inc(TypeIndex);
    AIni.WriteString('UpdateEditor', IntToStr(I), IntToStr(TypeIndex) + '|' +
      Item.SubItems[0] + '|' + Item.SubItems[1] + '|' + Item.SubItems[2] + '|' +
      Item.SubItems[3]);
  end;
end;

procedure TFrmMain.GenerateList(Sender: TObject);
var
  D: TSaveDialog;
  Ini: TMemIniFile;
  Node: TTreeNode;
  Entry: TServerEntry;
  Item: TListItem;
  I, ServerIndex, TypeIndex: Integer;
begin
  D := TSaveDialog.Create(Self);
  try
    D.Title := '生成列表'; D.Filter := '文本文件 (*.txt)|*.txt';
    D.DefaultExt := 'txt'; D.FileName := 'Config.txt';
    if not D.Execute then Exit;
    Ini := TMemIniFile.Create(D.FileName, TEncoding.Default);
    try
      Ini.Clear;
      ServerIndex := 251;
      Node := FServerTree.Items.GetFirstNode;
      while Node <> nil do
      begin
        if (Node.Level > 0) and (Node.Data <> nil) then
        begin
          Entry := TServerEntry(Node.Data);
          Ini.WriteString('Server', IntToStr(ServerIndex), Entry.GroupName + '|' +
            Entry.DisplayName + '|' + Entry.ServerName + '|' + Entry.Address + '|' +
            Entry.Port + '|' + IntToStr(Ord(Entry.AutoExpand)) + '|' +
            Entry.MicroAddress + '|' + Entry.MicroPort + '|' + Entry.FirewallPort +
            '|' + Entry.FirewallType);
          Inc(ServerIndex);
        end;
        Node := Node.GetNext;
      end;
      Ini.WriteString('Setup', '公告地址', FNoticeURL.Text);
      Ini.WriteString('Setup', '官方首页', FHomeURL.Text);
      Ini.WriteString('Setup', '客户服务', FServiceURL.Text);
      Ini.WriteString('Setup', '刷新速度', FRefreshSeconds.Text);
      Ini.WriteInteger('Setup', '自动刷新', Ord(FAutoRefresh.Checked));
      for I := 0 to FUpdateList.Items.Count - 1 do
      begin
        Item := FUpdateList.Items[I]; TypeIndex := 0;
        while (TypeIndex < 3) and not SameText(Item.Caption,
          GetUpdateTypeName(TypeIndex)) do Inc(TypeIndex);
        Ini.WriteString('Upgrade', IntToStr(I), IntToStr(TypeIndex) + ' ' +
          Item.SubItems[0] + ' ' + Item.SubItems[1] + ' ' + Item.SubItems[2] +
          ' ' + Item.SubItems[3]);
      end;
      Ini.UpdateFile;
    finally
      Ini.Free;
    end;
    MessageDlg('列表生成成功：' + sLineBreak + D.FileName,
      mtInformation, [mbOK], 0);
  finally
    D.Free;
  end;
end;

end.
