unit LoginBootstrapMain;

interface

procedure RunLoginBootstrap;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, Winapi.WinSock, System.SysUtils, System.Classes,
  System.IniFiles, System.IOUtils, System.Net.HttpClient, System.UITypes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Graphics, Vcl.Buttons, Vcl.Dialogs, Vcl.OleCtrls, SHDocVw,
  GxxCrypto, GxxSkin;

const
  PayloadMagic: array[0..7] of AnsiChar =
    ('G', 'X', 'X', 'P', 'A', 'Y', 'L', '1');
  PayloadVersion = 1;

type
  TPayloadTrailer = packed record
    Magic: array[0..7] of AnsiChar;
    Version: Cardinal;
    EntryCount: Cardinal;
    ManifestOffset: Int64;
    ManifestSize: Int64;
    OriginalSize: Int64;
  end;

  TServerInfo = class
  public
    GroupName: string;
    DisplayName: string;
    ServerName: string;
    Address: string;
    Port: Integer;
    AutoExpand: Boolean;
    MicroAddress: string;
    MicroPort: Integer;
    FirewallPort: Integer;
    FirewallType: Integer;
  end;

  TLauncherForm = class(TForm)
  private
    FExtractDir: string;
    FClientPath: string;
    FClientDataFile: string;
    FConfigURL: string;
    FBackupURL: string;
    FNoticeURL: string;
    FHomeURL: string;
    FServiceURL: string;
    FRegisterURL: string;
    FChangePasswordURL: string;
    FRecoverPasswordURL: string;
    FUpdatePassword: string;
    FPromotionID: string;
    FLoginMode: Integer;
    FMaxClients: Integer;
    FVSync: Boolean;
    FHardware: Boolean;
    FRefreshSeconds: Integer;
    FAutoRefresh: Boolean;
    FBackground: TImage;
    FServerTree: TTreeView;
    FBrowser: TWebBrowser;
    FResolution: TComboBox;
    FWindowMode: TCheckBox;
    FStatus: TLabel;
    FCurrentProgress: TProgressBar;
    FTotalProgress: TProgressBar;
    FRefreshTimer: TTimer;
    FClientTimer: TTimer;
    FClientProcess: THandle;
    FButtons: array[0..22] of TSpeedButton;
    procedure BuildUI;
    procedure LoadSettings;
    procedure LoadSkin;
    procedure FormShown(Sender: TObject);
    procedure RefreshTimerTick(Sender: TObject);
    procedure ClientTimerTick(Sender: TObject);
    procedure RefreshClick(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure ServerChanged(Sender: TObject; Node: TTreeNode);
    procedure SettingsClick(Sender: TObject);
    procedure HomeClick(Sender: TObject);
    procedure ServiceClick(Sender: TObject);
    procedure RegisterClick(Sender: TObject);
    procedure ChangePasswordClick(Sender: TObject);
    procedure RecoverPasswordClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure MinimizeClick(Sender: TObject);
    procedure FreeServers;
    procedure SetStatus(const Value: string);
    procedure OpenURL(const Value: string);
    procedure RefreshConfig;
    function DownloadText(const URL: string; out Text: string): Boolean;
    procedure ParseConfig(const Text: string);
    procedure AddServerLine(const Value: string);
    function FindGroup(const Name: string): TTreeNode;
    function SelectedServer: TServerInfo;
    function CheckServerConnection(Info: TServerInfo;
      ShowResult: Boolean): Boolean;
    procedure NavigateNotice;
    procedure ReadResolution(out Width, Height: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  BootstrapExtractDir: string;
  BootstrapClientPath: string;

function ReadInt64(Stream: TFileStream): Int64;
begin
  Stream.ReadBuffer(Result, SizeOf(Result));
end;

function ReadCardinal(Stream: TFileStream): Cardinal;
begin
  Stream.ReadBuffer(Result, SizeOf(Result));
end;

function ReadAnsiString(Stream: TFileStream; Count: Cardinal): AnsiString;
begin
  SetLength(Result, Count);
  if Count > 0 then
    Stream.ReadBuffer(Result[1], Count);
end;

function SafeRelativePath(const Value: string): string;
var
  S: string;
begin
  S := StringReplace(Value, '/', '\', [rfReplaceAll]);
  if (S = '') or TPath.IsPathRooted(S) or (Pos('..', S) > 0) then
    Exit('');
  Result := S;
end;

function ReadTrailer(Stream: TFileStream;
  out Trailer: TPayloadTrailer): Boolean;
begin
  Result := False;
  if Stream.Size < SizeOf(Trailer) then
    Exit;
  Stream.Position := Stream.Size - SizeOf(Trailer);
  Stream.ReadBuffer(Trailer, SizeOf(Trailer));
  if not CompareMem(@Trailer.Magic, @PayloadMagic, SizeOf(PayloadMagic)) then
    Exit;
  if Trailer.Version <> PayloadVersion then
    Exit;
  if (Trailer.OriginalSize <= 0) or (Trailer.OriginalSize > Stream.Size) or
     (Trailer.ManifestOffset < Trailer.OriginalSize) or
     (Trailer.ManifestSize < 0) or
     (Trailer.ManifestOffset + Trailer.ManifestSize >
      Stream.Size - SizeOf(Trailer)) then
    Exit;
  Result := True;
end;

function NewExtractionDirectory: string;
var
  TempPath: array[0..MAX_PATH] of Char;
  TempLength: DWORD;
begin
  TempLength := GetTempPath(MAX_PATH, TempPath);
  SetString(Result, TempPath, TempLength);
  if Result = '' then
    Result := IncludeTrailingPathDelimiter(GetCurrentDir);
  Result := IncludeTrailingPathDelimiter(Result) + 'GxxLogin_' +
    IntToHex(GetCurrentProcessId, 8) + '_' + IntToHex(GetTickCount, 8);
  ForceDirectories(Result);
end;

function ExtractPayload(const ExeName, TargetDir: string;
  out ClientPath: string): Boolean;
var
  Stream: TFileStream;
  Trailer: TPayloadTrailer;
  I: Cardinal;
  NameLength: Cardinal;
  NameAnsi: AnsiString;
  RelativeName, OutputName: string;
  Offset, Size: Int64;
  Names: array of string;
  Offsets, Sizes: array of Int64;
  OutStream: TFileStream;
begin
  Result := False;
  ClientPath := '';
  Stream := TFileStream.Create(ExeName, fmOpenRead or fmShareDenyNone);
  try
    if not ReadTrailer(Stream, Trailer) then
      Exit;
    Stream.Position := Trailer.ManifestOffset;
    SetLength(Names, Trailer.EntryCount);
    SetLength(Offsets, Trailer.EntryCount);
    SetLength(Sizes, Trailer.EntryCount);
    for I := 1 to Trailer.EntryCount do
    begin
      NameLength := ReadCardinal(Stream);
      if (NameLength = 0) or (NameLength > 4096) then
        Exit;
      NameAnsi := ReadAnsiString(Stream, NameLength);
      RelativeName := SafeRelativePath(string(
        TEncoding.UTF8.GetString(TBytes(NameAnsi))));
      Offset := ReadInt64(Stream);
      Size := ReadInt64(Stream);
      if (RelativeName = '') or (Offset < Trailer.OriginalSize) or
         (Size < 0) or (Offset + Size > Trailer.ManifestOffset) then
        Exit;
      Names[I - 1] := RelativeName;
      Offsets[I - 1] := Offset;
      Sizes[I - 1] := Size;
    end;
    for I := 0 to Trailer.EntryCount - 1 do
    begin
      RelativeName := Names[I];
      OutputName := IncludeTrailingPathDelimiter(TargetDir) + RelativeName;
      ForceDirectories(ExtractFilePath(OutputName));
      Stream.Position := Offsets[I];
      OutStream := TFileStream.Create(OutputName, fmCreate);
      try
        if Sizes[I] > 0 then
          OutStream.CopyFrom(Stream, Sizes[I]);
      finally
        OutStream.Free;
      end;
      if SameText(RelativeName, 'Client.exe') then
        ClientPath := OutputName;
    end;
    Result := ClientPath <> '';
  finally
    Stream.Free;
  end;
end;

function ClampInt(const Value, MinValue, MaxValue: Integer): Integer;
begin
  Result := Value;
  if Result < MinValue then Result := MinValue;
  if Result > MaxValue then Result := MaxValue;
end;

function IsValidUTF8(const Bytes: TBytes): Boolean;
var
  I, Needed, J: Integer;
  B: Byte;
begin
  Result := False;
  I := 0;
  while I < Length(Bytes) do
  begin
    B := Bytes[I];
    if B < $80 then
      Needed := 0
    else if (B >= $C2) and (B <= $DF) then
      Needed := 1
    else if (B >= $E0) and (B <= $EF) then
      Needed := 2
    else if (B >= $F0) and (B <= $F4) then
      Needed := 3
    else
      Exit;
    if I + Needed >= Length(Bytes) then Exit;
    for J := 1 to Needed do
      if (Bytes[I + J] and $C0) <> $80 then Exit;
    if (Needed = 2) and (B = $E0) and (Bytes[I + 1] < $A0) then Exit;
    if (Needed = 2) and (B = $ED) and (Bytes[I + 1] >= $A0) then Exit;
    if (Needed = 3) and (B = $F0) and (Bytes[I + 1] < $90) then Exit;
    if (Needed = 3) and (B = $F4) and (Bytes[I + 1] >= $90) then Exit;
    Inc(I, Needed + 1);
  end;
  Result := True;
end;

function TestTCPPort(const Host: string; Port, TimeoutMS: Integer): Boolean;
var
  WSAData: TWSAData;
  Sock: TSocket;
  Addr: TSockAddrIn;
  HostEnt: PHostEnt;
  HostAnsi: AnsiString;
  NonBlocking: u_long;
  WriteSet, ErrorSet: TFDSet;
  Timeout: TTimeVal;
  SocketError, ErrorSize, SelectResult: Integer;
begin
  Result := False;
  if (Trim(Host) = '') or (Port <= 0) or (Port > 65535) then Exit;
  if WSAStartup($0202, WSAData) <> 0 then Exit;
  try
    Sock := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if Sock = INVALID_SOCKET then Exit;
    try
      FillChar(Addr, SizeOf(Addr), 0);
      Addr.sin_family := AF_INET;
      Addr.sin_port := htons(Port);
      HostAnsi := AnsiString(Trim(Host));
      Addr.sin_addr.S_addr := inet_addr(PAnsiChar(HostAnsi));
      if Addr.sin_addr.S_addr = High(u_long) then
      begin
        HostEnt := gethostbyname(PAnsiChar(HostAnsi));
        if (HostEnt = nil) or (HostEnt^.h_addr_list = nil) or
           (HostEnt^.h_addr_list[0] = nil) then Exit;
        Move(HostEnt^.h_addr_list[0]^, Addr.sin_addr.S_addr,
          SizeOf(Addr.sin_addr.S_addr));
      end;
      NonBlocking := 1;
      if ioctlsocket(Sock, FIONBIO, NonBlocking) = SOCKET_ERROR then Exit;
      if connect(Sock, TSockAddr(Addr), SizeOf(Addr)) = 0 then
        Exit(True);
      if WSAGetLastError <> WSAEWOULDBLOCK then Exit;
      FD_ZERO(WriteSet);
      FD_ZERO(ErrorSet);
      FD_SET(Sock, WriteSet);
      FD_SET(Sock, ErrorSet);
      Timeout.tv_sec := TimeoutMS div 1000;
      Timeout.tv_usec := (TimeoutMS mod 1000) * 1000;
      SelectResult := Winapi.WinSock.select(0, nil, @WriteSet, @ErrorSet,
        @Timeout);
      if SelectResult <= 0 then Exit;
      SocketError := 0;
      ErrorSize := SizeOf(SocketError);
      if getsockopt(Sock, SOL_SOCKET, SO_ERROR, PAnsiChar(@SocketError),
        ErrorSize) = SOCKET_ERROR then Exit;
      Result := SocketError = 0;
    finally
      closesocket(Sock);
    end;
  finally
    WSACleanup;
  end;
end;

constructor TLauncherForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FClientProcess := 0;
  FExtractDir := BootstrapExtractDir;
  FClientPath := BootstrapClientPath;
  LoadSettings;
  BuildUI;
  LoadSkin;
  OnShow := FormShown;
end;

destructor TLauncherForm.Destroy;
begin
  if FClientProcess <> 0 then
    CloseHandle(FClientProcess);
  FreeServers;
  inherited;
end;

procedure TLauncherForm.LoadSettings;
var
  Ini: TMemIniFile;
  IniName: string;
begin
  IniName := IncludeTrailingPathDelimiter(FExtractDir) + 'Launcher.ini';
  if not FileExists(IniName) then
    raise Exception.Create('登录器配置文件 Launcher.ini 不存在。');
  Ini := TMemIniFile.Create(IniName, TEncoding.UTF8);
  try
    Caption := Ini.ReadString('Launcher', 'Title', '传奇登录器');
    FClientDataFile := Ini.ReadString('Launcher', 'ClientDataFile',
      'Client.dat');
    FConfigURL := Ini.ReadString('Launcher', 'ConfigURL', '');
    FBackupURL := Ini.ReadString('Launcher', 'BackupURL', '');
    FNoticeURL := Ini.ReadString('Launcher', 'NoticeURL', '');
    FHomeURL := Ini.ReadString('Launcher', 'HomeURL', '');
    FServiceURL := Ini.ReadString('Launcher', 'ServiceURL', '');
    FUpdatePassword := Ini.ReadString('Launcher', 'UpdatePassword', '');
    FPromotionID := Ini.ReadString('Launcher', 'PromotionID', '');
    FLoginMode := ClampInt(Ini.ReadInteger('Launcher', 'LoginMode', 0), 0, 1);
    FMaxClients := ClampInt(Ini.ReadInteger('Launcher', 'MaxClients', 6), 1, 30);
    FVSync := Ini.ReadBool('Launcher', 'VSync', True);
    FHardware := Ini.ReadBool('Launcher', 'Hardware', True);
    FAutoRefresh := Ini.ReadBool('Launcher', 'AutoRefresh', True);
    FRefreshSeconds := ClampInt(
      Ini.ReadInteger('Launcher', 'RefreshSeconds', 120), 1, 86400);
  finally
    Ini.Free;
  end;
end;

procedure TLauncherForm.BuildUI;
  function AddFlatButton(const Text: string; X, Y, W, H: Integer;
    Handler: TNotifyEvent): TSpeedButton;
  begin
    Result := TSpeedButton.Create(Self);
    Result.Parent := Self;
    Result.SetBounds(X, Y, W, H);
    Result.Caption := Text;
    Result.Flat := True;
    Result.Transparent := True;
    Result.Font.Name := '宋体';
    Result.Font.Size := 10;
    Result.Font.Color := clWhite;
    Result.OnClick := Handler;
  end;
var
  Ini: TMemIniFile;
  Width, Height: Integer;
begin
  BorderStyle := bsNone;
  BorderIcons := [];
  Position := poScreenCenter;
  ClientWidth := 829;
  ClientHeight := 570;
  Color := clBlack;
  Font.Name := '宋体';
  Font.Size := 9;

  FBackground := TImage.Create(Self);
  FBackground.Parent := Self;
  FBackground.SetBounds(0, 0, ClientWidth, ClientHeight);
  FBackground.Stretch := False;
  FBackground.SendToBack;

  FServerTree := TTreeView.Create(Self);
  FServerTree.Parent := Self;
  FServerTree.SetBounds(75, 70, 245, 342);
  FServerTree.Color := clBlack;
  FServerTree.Font.Name := '宋体';
  FServerTree.Font.Size := 9;
  FServerTree.Font.Color := clYellow;
  FServerTree.BorderStyle := bsNone;
  FServerTree.ReadOnly := True;
  FServerTree.HideSelection := False;
  FServerTree.ShowLines := True;
  FServerTree.ShowButtons := True;
  FServerTree.OnChange := ServerChanged;
  FServerTree.OnDblClick := StartClick;

  FBrowser := TWebBrowser.Create(Self);
  TWinControl(FBrowser).Parent := Self;
  FBrowser.SetBounds(344, 70, 407, 369);

  FResolution := TComboBox.Create(Self);
  FResolution.Parent := Self;
  FResolution.SetBounds(75, 423, 162, 22);
  FResolution.Style := csDropDownList;
  FResolution.Items.Add('800 x 600');
  FResolution.Items.Add('1024 x 768');
  FResolution.Items.Add('1280 x 720');
  FResolution.Items.Add('1280 x 800');
  FResolution.Items.Add('1366 x 768');
  FResolution.Items.Add('1440 x 900');
  FResolution.Items.Add('1600 x 900');
  FResolution.Items.Add('1920 x 1080');
  Ini := TMemIniFile.Create(IncludeTrailingPathDelimiter(FExtractDir) +
    'Launcher.ini', TEncoding.UTF8);
  try
    Width := Ini.ReadInteger('Launcher', 'ScreenWidth', 800);
    Height := Ini.ReadInteger('Launcher', 'ScreenHeight', 600);
    FWindowMode := TCheckBox.Create(Self);
    FWindowMode.Parent := Self;
    FWindowMode.SetBounds(252, 423, 72, 21);
    FWindowMode.Caption := '窗口模式';
    FWindowMode.Font.Color := clLime;
    FWindowMode.Checked := Ini.ReadBool('Launcher', 'WindowMode', True);
  finally
    Ini.Free;
  end;
  FResolution.ItemIndex := FResolution.Items.IndexOf(
    IntToStr(Width) + ' x ' + IntToStr(Height));
  if FResolution.ItemIndex < 0 then
  begin
    FResolution.Items.Insert(0, IntToStr(Width) + ' x ' + IntToStr(Height));
    FResolution.ItemIndex := 0;
  end;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.SetBounds(126, 461, 190, 17);
  FStatus.AutoSize := False;
  FStatus.Transparent := True;
  FStatus.Font.Color := clYellow;
  FStatus.Caption := '正在准备登录器...';

  FCurrentProgress := TProgressBar.Create(Self);
  FCurrentProgress.Parent := Self;
  FCurrentProgress.SetBounds(123, 483, 191, 11);
  FCurrentProgress.Min := 0;
  FCurrentProgress.Max := 100;

  FTotalProgress := TProgressBar.Create(Self);
  FTotalProgress.Parent := Self;
  FTotalProgress.SetBounds(123, 501, 191, 11);
  FTotalProgress.Min := 0;
  FTotalProgress.Max := 100;

  FButtons[12] := AddFlatButton('开始游戏', 331, 459, 103, 27, StartClick);
  FButtons[13] := AddFlatButton('游戏设置', 444, 459, 103, 27, SettingsClick);
  FButtons[14] := AddFlatButton('官方网站', 556, 459, 103, 27, HomeClick);
  FButtons[22] := AddFlatButton('客户服务', 668, 459, 103, 27, ServiceClick);
  FButtons[20] := AddFlatButton('取消更新', 331, 495, 103, 27, RefreshClick);
  FButtons[16] := AddFlatButton('注册帐号', 444, 495, 103, 27, RegisterClick);
  FButtons[17] := AddFlatButton('修改密码', 556, 495, 103, 27, ChangePasswordClick);
  FButtons[18] := AddFlatButton('密码找回', 668, 495, 103, 27, RecoverPasswordClick);
  FButtons[15] := AddFlatButton('添加游戏', 331, 531, 103, 27, RefreshClick);
  FButtons[19] := AddFlatButton('退出游戏', 444, 531, 103, 27, ExitClick);
  FButtons[0] := AddFlatButton('_', 780, 4, 20, 20, MinimizeClick);
  FButtons[1] := AddFlatButton('X', 803, 4, 20, 20, ExitClick);

  FRefreshTimer := TTimer.Create(Self);
  FRefreshTimer.Enabled := False;
  FRefreshTimer.Interval := FRefreshSeconds * 1000;
  FRefreshTimer.OnTimer := RefreshTimerTick;

  FClientTimer := TTimer.Create(Self);
  FClientTimer.Enabled := False;
  FClientTimer.Interval := 250;
  FClientTimer.OnTimer := ClientTimerTick;
end;

procedure TLauncherForm.LoadSkin;
var
  Skin: TSkinDocument;
  SkinName: string;
  O: TSkinObject;
  I: Integer;
  procedure ApplyObject(Control: TControl; Index: Integer);
  begin
    if (Control = nil) or (Index >= Skin.ObjectCount) then Exit;
    O := Skin.Objects[Index];
    if (O.Width > 0) and (O.Height > 0) then
      Control.SetBounds(O.Left, O.Top, O.Width, O.Height);
    Control.Visible := (O.Width > 0) and (O.Height > 0);
  end;
begin
  SkinName := IncludeTrailingPathDelimiter(FExtractDir) + 'loginskin';
  if not FileExists(SkinName) then
    Exit;
  Skin := TSkinDocument.Create;
  try
    Skin.LoadFromFile(SkinName);
    if Skin.LoadPreview(FBackground.Picture.Bitmap) then
    begin
      ClientWidth := FBackground.Picture.Bitmap.Width;
      ClientHeight := FBackground.Picture.Bitmap.Height;
      FBackground.SetBounds(0, 0, ClientWidth, ClientHeight);
    end;
    ApplyObject(FButtons[0], 0);
    ApplyObject(FButtons[1], 1);
    ApplyObject(FServerTree, 2);
    ApplyObject(FResolution, 3);
    ApplyObject(FWindowMode, 4);
    ApplyObject(FStatus, 6);
    ApplyObject(FCurrentProgress, 8);
    ApplyObject(FTotalProgress, 10);
    ApplyObject(FBrowser, 11);
    for I := 12 to 20 do
      ApplyObject(FButtons[I], I);
    ApplyObject(FButtons[22], 22);
  finally
    Skin.Free;
  end;
end;

procedure TLauncherForm.FormShown(Sender: TObject);
begin
  Application.ProcessMessages;
  RefreshConfig;
  FRefreshTimer.Enabled := FAutoRefresh;
end;

procedure TLauncherForm.SetStatus(const Value: string);
begin
  FStatus.Caption := Value;
  FStatus.Update;
end;

function TLauncherForm.DownloadText(const URL: string;
  out Text: string): Boolean;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  Bytes: TBytes;
  Encoding: TEncoding;
  Content: TMemoryStream;
begin
  Result := False;
  Text := '';
  if Trim(URL) = '' then
    Exit;
  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := 8000;
    Client.ResponseTimeout := 12000;
    Client.HandleRedirects := True;
    try
      Response := Client.Get(URL);
      if (Response.StatusCode < 200) or (Response.StatusCode >= 300) then
        Exit;
      Content := TMemoryStream.Create;
      try
        if Response.ContentStream <> nil then
        begin
          Response.ContentStream.Position := 0;
          Content.CopyFrom(Response.ContentStream, 0);
        end;
        SetLength(Bytes, Content.Size);
        Content.Position := 0;
        if Content.Size > 0 then
          Content.ReadBuffer(Bytes[0], Content.Size);
      finally
        Content.Free;
      end;
      if Length(Bytes) = 0 then
        Exit;
      if (Length(Bytes) >= 3) and (Bytes[0] = $EF) and
         (Bytes[1] = $BB) and (Bytes[2] = $BF) then
        Text := TEncoding.UTF8.GetString(Bytes, 3, Length(Bytes) - 3)
      else if IsValidUTF8(Bytes) then
        Text := TEncoding.UTF8.GetString(Bytes)
      else
      begin
        Encoding := TEncoding.GetEncoding(936);
        try
          Text := Encoding.GetString(Bytes);
        finally
          Encoding.Free;
        end;
      end;
      Result := True;
    except
      Result := False;
    end;
  finally
    Client.Free;
  end;
end;

procedure TLauncherForm.RefreshConfig;
var
  Text: string;
begin
  FRefreshTimer.Enabled := False;
  FCurrentProgress.Position := 10;
  FTotalProgress.Position := 10;
  SetStatus('正在获取远程配置信息...');
  Application.ProcessMessages;
  if not DownloadText(FConfigURL, Text) then
  begin
    SetStatus('主地址失败，正在连接备用地址...');
    Application.ProcessMessages;
    if not DownloadText(FBackupURL, Text) then
    begin
      SetStatus('服务器列表下载失败');
      FCurrentProgress.Position := 0;
      FTotalProgress.Position := 0;
      FRefreshTimer.Enabled := FAutoRefresh;
      Exit;
    end;
  end;
  FCurrentProgress.Position := 70;
  FTotalProgress.Position := 70;
  ParseConfig(Text);
  FCurrentProgress.Position := 100;
  FTotalProgress.Position := 100;
  SetStatus('服务器列表更新完成');
  NavigateNotice;
  FRefreshTimer.Enabled := FAutoRefresh;
end;

procedure TLauncherForm.FreeServers;
var
  I: Integer;
begin
  if FServerTree = nil then
    Exit;
  for I := 0 to FServerTree.Items.Count - 1 do
    if FServerTree.Items[I].Data <> nil then
    begin
      TObject(FServerTree.Items[I].Data).Free;
      FServerTree.Items[I].Data := nil;
    end;
end;

function TLauncherForm.FindGroup(const Name: string): TTreeNode;
var
  Node: TTreeNode;
begin
  Result := nil;
  Node := FServerTree.Items.GetFirstNode;
  while Node <> nil do
  begin
    if (Node.Level = 0) and SameText(Trim(Node.Text), Trim(Name)) then
      Exit(Node);
    Node := Node.GetNextSibling;
  end;
end;

procedure TLauncherForm.AddServerLine(const Value: string);
var
  Parts: TStringList;
  GroupNode, Node: TTreeNode;
  Info: TServerInfo;
begin
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := '|';
    Parts.DelimitedText := Value;
    if (Parts.Count = 0) or (Trim(Parts[0]) = '') then
      Exit;
    GroupNode := FindGroup(Parts[0]);
    if GroupNode = nil then
      GroupNode := FServerTree.Items.Add(nil, Trim(Parts[0]));
    if (Parts.Count < 5) or (Trim(Parts[1]) = '') then
      Exit;
    Info := TServerInfo.Create;
    Info.GroupName := Trim(Parts[0]);
    Info.DisplayName := Trim(Parts[1]);
    Info.ServerName := Trim(Parts[2]);
    Info.Address := Trim(Parts[3]);
    Info.Port := StrToIntDef(Trim(Parts[4]), 7000);
    if Parts.Count > 5 then
      Info.AutoExpand := StrToIntDef(Trim(Parts[5]), 0) <> 0;
    if Parts.Count > 6 then Info.MicroAddress := Trim(Parts[6]);
    if Parts.Count > 7 then
      Info.MicroPort := StrToIntDef(Trim(Parts[7]), 0);
    if Parts.Count > 8 then
      Info.FirewallPort := StrToIntDef(Trim(Parts[8]), 0);
    if Parts.Count > 9 then
      Info.FirewallType := StrToIntDef(Trim(Parts[9]), 0);
    Node := FServerTree.Items.AddChildObject(GroupNode,
      Info.DisplayName, Info);
    if Info.AutoExpand then GroupNode.Expand(False);
  finally
    Parts.Free;
  end;
end;

procedure TLauncherForm.ParseConfig(const Text: string);
var
  Lines: TStringList;
  I, P: Integer;
  Line, Section, Key, Value: string;
begin
  FreeServers;
  FServerTree.Items.Clear;
  Lines := TStringList.Create;
  FServerTree.Items.BeginUpdate;
  try
    Lines.Text := Text;
    Section := '';
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[I]);
      if (Line = '') or (Line[1] = ';') or (Line[1] = '#') then
        Continue;
      if (Line[1] = '[') and (Line[Length(Line)] = ']') then
      begin
        Section := Trim(Copy(Line, 2, Length(Line) - 2));
        Continue;
      end;
      P := Pos('=', Line);
      if P <= 0 then
        Continue;
      Key := Trim(Copy(Line, 1, P - 1));
      Value := Trim(Copy(Line, P + 1, MaxInt));
      if SameText(Section, 'Server') then
        AddServerLine(Value)
      else if SameText(Section, 'Setup') then
      begin
        if Key = '公告地址' then FNoticeURL := Value
        else if Key = '官方首页' then FHomeURL := Value
        else if Key = '客户服务' then FServiceURL := Value
        else if (Key = '注册帐号') or (Key = '注册账号') then
          FRegisterURL := Value
        else if Key = '修改密码' then FChangePasswordURL := Value
        else if Key = '密码找回' then FRecoverPasswordURL := Value
        else if Key = '刷新速度' then
          FRefreshSeconds := ClampInt(StrToIntDef(Value,
            FRefreshSeconds), 1, 86400)
        else if Key = '自动刷新' then
          FAutoRefresh := StrToIntDef(Value, Ord(FAutoRefresh)) <> 0;
      end;
    end;
    if FServerTree.Selected = nil then
      for I := 0 to FServerTree.Items.Count - 1 do
        if FServerTree.Items[I].Data <> nil then
        begin
          FServerTree.Selected := FServerTree.Items[I];
          Break;
        end;
    FRefreshTimer.Interval := FRefreshSeconds * 1000;
  finally
    FServerTree.Items.EndUpdate;
    Lines.Free;
  end;
end;

function TLauncherForm.SelectedServer: TServerInfo;
var
  Node: TTreeNode;
begin
  Result := nil;
  Node := FServerTree.Selected;
  if Node = nil then Exit;
  if Node.Data = nil then Node := Node.GetFirstChild;
  if (Node <> nil) and (Node.Data <> nil) then
    Result := TServerInfo(Node.Data);
end;

function TLauncherForm.CheckServerConnection(Info: TServerInfo;
  ShowResult: Boolean): Boolean;
begin
  Result := False;
  if Info = nil then Exit;
  if ShowResult then
  begin
    FStatus.Font.Color := clYellow;
    SetStatus('正在连接服务器...');
    Application.ProcessMessages;
  end;
  Result := TestTCPPort(Info.Address, Info.Port, 1500);
  if ShowResult then
  begin
    if Result then
    begin
      FStatus.Font.Color := clLime;
      SetStatus('服务器连接成功');
    end
    else
    begin
      FStatus.Font.Color := clRed;
      SetStatus('服务器连接失败');
    end;
  end;
end;

procedure TLauncherForm.ServerChanged(Sender: TObject; Node: TTreeNode);
begin
  CheckServerConnection(SelectedServer, True);
end;

procedure TLauncherForm.ReadResolution(out Width, Height: Integer);
var
  S: string;
  P: Integer;
begin
  Width := 800;
  Height := 600;
  S := StringReplace(FResolution.Text, ' ', '', [rfReplaceAll]);
  P := Pos('x', LowerCase(S));
  if P > 0 then
  begin
    Width := ClampInt(StrToIntDef(Copy(S, 1, P - 1), 800), 320,
      High(Word));
    Height := ClampInt(StrToIntDef(Copy(S, P + 1, MaxInt), 600), 200,
      High(Word));
  end;
end;

procedure TLauncherForm.StartClick(Sender: TObject);
var
  Info: TServerInfo;
  Param: TLoginClientParam;
  Key: Integer;
  KeyArg, ParamArg: AnsiString;
  CommandLine: string;
  StartInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Width, Height: Integer;
begin
  Info := SelectedServer;
  if Info = nil then
  begin
    MessageDlg('请先选择一个游戏服务器。', mtWarning, [mbOK], 0);
    Exit;
  end;
  if not FileExists(FClientPath) then
  begin
    MessageDlg('客户端文件不存在：' + FClientPath, mtError, [mbOK], 0);
    Exit;
  end;
  if not CheckServerConnection(Info, True) then
  begin
    MessageDlg('服务器 ' + Info.Address + ':' + IntToStr(Info.Port) +
      ' 当前无法连接。', mtWarning, [mbOK], 0);
    Exit;
  end;
  SetStatus('正在进入 ' + Info.DisplayName + '...');
  ReadResolution(Width, Height);
  FillChar(Param, SizeOf(Param), 0);
  Param.Handle := Handle;
  Param.sGameLoginFileName := ExtractFileName(ParamStr(0));
  Param.sServerCaption := Info.ServerName;
  Param.sServeraddr := Info.Address;
  Param.nServerPort := Info.Port;
  if (FLoginMode = 1) and (Info.MicroPort > 0) then
  begin
    Param.sUpdateAddr := Info.MicroAddress;
    Param.nUpdatePort := Info.MicroPort;
  end
  else
  begin
    Param.sUpdateAddr := Info.Address;
    Param.nUpdatePort := 0;
  end;
  if FUpdatePassword <> '' then
    Param.sUpdatePassWord := EncryptLegacyStringWithKey(
      AnsiString(FUpdatePassword), '3230393649');
  Param.sHomePage := FHomeURL;
  Param.btMaxClientCount := FMaxClients;
  Param.wScreenWidth := Width;
  Param.wScreenHeight := Height;
  Param.btBitCount := 32;
  Param.boWindowMode := FWindowMode.Checked;
  Param.boVSync := FVSync;
  Param.boHardware := FHardware;
  Param.ClientVersion := cvSerial;
  Param.sSemaphoreName := 'GxxClient_' + IntToHex(GetTickCount, 8);
  Param.sClientDataFile := FClientDataFile;
  Param.sPromotionFlag := FPromotionID;

  Key := RandomClientKey;
  KeyArg := EncryptLegacyStringWithKey(AnsiString(IntToStr(Key)),
    '3230393649');
  ParamArg := EncryptClientParam(Param, Key);
  CommandLine := '"' + FClientPath + '" 0 "' + string(KeyArg) +
    '" "' + string(ParamArg) + '"';
  UniqueString(CommandLine);
  FillChar(StartInfo, SizeOf(StartInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);
  if CreateProcess(nil, PChar(CommandLine), nil, nil, False, 0, nil,
    PChar(FExtractDir), StartInfo, ProcessInfo) then
  begin
    CloseHandle(ProcessInfo.hThread);
    FClientProcess := ProcessInfo.hProcess;
    FRefreshTimer.Enabled := False;
    Hide;
    FClientTimer.Enabled := True;
  end
  else
  begin
    SetStatus('客户端启动失败');
    MessageDlg(SysErrorMessage(GetLastError), mtError, [mbOK], 0);
  end;
end;

procedure TLauncherForm.ClientTimerTick(Sender: TObject);
begin
  if (FClientProcess <> 0) and
     (WaitForSingleObject(FClientProcess, 0) = WAIT_OBJECT_0) then
  begin
    FClientTimer.Enabled := False;
    CloseHandle(FClientProcess);
    FClientProcess := 0;
    Application.Terminate;
  end;
end;

procedure TLauncherForm.NavigateNotice;
begin
  if Trim(FNoticeURL) = '' then Exit;
  try
    FBrowser.OleObject.Silent := True;
    FBrowser.Navigate(FNoticeURL);
  except
    SetStatus('公告页面无法打开');
  end;
end;

procedure TLauncherForm.OpenURL(const Value: string);
begin
  if Trim(Value) <> '' then
    ShellExecute(Handle, 'open', PChar(Value), nil, nil, SW_SHOWNORMAL);
end;

procedure TLauncherForm.SettingsClick(Sender: TObject);
begin
  FResolution.SetFocus;
  SetStatus('游戏设置已就绪');
end;

procedure TLauncherForm.HomeClick(Sender: TObject);
begin
  OpenURL(FHomeURL);
end;

procedure TLauncherForm.ServiceClick(Sender: TObject);
begin
  OpenURL(FServiceURL);
end;

procedure TLauncherForm.RegisterClick(Sender: TObject);
begin
  if FRegisterURL <> '' then OpenURL(FRegisterURL) else OpenURL(FHomeURL);
end;

procedure TLauncherForm.ChangePasswordClick(Sender: TObject);
begin
  if FChangePasswordURL <> '' then OpenURL(FChangePasswordURL)
  else OpenURL(FHomeURL);
end;

procedure TLauncherForm.RecoverPasswordClick(Sender: TObject);
begin
  if FRecoverPasswordURL <> '' then OpenURL(FRecoverPasswordURL)
  else OpenURL(FHomeURL);
end;

procedure TLauncherForm.RefreshClick(Sender: TObject);
begin
  RefreshConfig;
end;

procedure TLauncherForm.RefreshTimerTick(Sender: TObject);
begin
  RefreshConfig;
end;

procedure TLauncherForm.ExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TLauncherForm.MinimizeClick(Sender: TObject);
begin
  Application.Minimize;
end;

procedure RunLoginBootstrap;
var
  ExtractDir, ClientPath: string;
  Form: TLauncherForm;
begin
  Randomize;
  try
    // Generated launchers normally live in the complete game directory.
    // Use that directory so Client.exe can still see Map/Data/Wav and any
    // other loose resources.  The appended payload remains a standalone
    // fallback when only the launcher executable is copied elsewhere.
    ExtractDir := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
    ClientPath := IncludeTrailingPathDelimiter(ExtractDir) + 'Client.exe';
    if not (FileExists(ClientPath) and FileExists(
      IncludeTrailingPathDelimiter(ExtractDir) + 'Launcher.ini')) then
    begin
      ExtractDir := NewExtractionDirectory;
      if not ExtractPayload(ParamStr(0), ExtractDir, ClientPath) then
      begin
        MessageBox(0, '登录器数据不完整，无法启动客户端。', '传奇登录器',
          MB_ICONERROR or MB_OK);
        Exit;
      end;
    end;
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    BootstrapExtractDir := ExtractDir;
    BootstrapClientPath := ClientPath;
    Application.CreateForm(TLauncherForm, Form);
    Application.Run;
  except
    on E: Exception do
      MessageBox(0, PChar(E.Message), '传奇登录器', MB_ICONERROR or MB_OK);
  end;
end;

end.
