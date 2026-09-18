unit GxxDialogs;

interface

uses
  Winapi.Windows, System.SysUtils, System.StrUtils, System.Classes, System.IniFiles,
  System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Dialogs, Vcl.Graphics, Vcl.Grids, Vcl.FileCtrl, GxxCrypto, GxxGuiEdit,
  GxxSkin;

procedure ShowGxxDialog(AKind: Integer; AOwner: TComponent);

implementation

type
  TControlAccess = class(TControl);

  TPluginDialog = class(TForm)
  private
    FPluginList: TListBox;
    procedure RefreshPlugins(Sender: TObject);
  end;

  TReadRulesDialog = class(TForm)
  private
    FMemos: array[0..5] of TMemo;
    procedure DeleteWilDuplicates(Sender: TObject);
    procedure DeleteWzlDuplicates(Sender: TObject);
    procedure AutoScan(Sender: TObject);
    procedure RemoveDuplicates(ATarget, AReference: TStrings);
    procedure ScanFolder(const ARoot, AFolder: string);
  end;

  TSettingsDialog = class(TForm)
  public
    procedure BrowseFile(Sender: TObject);
  end;

  TSkinEditorForm = class(TForm)
  private
    FPreview: TImage;
    FObjectList: TListBox;
    FPropertyGrid: TStringGrid;
    FFileName: string;
    FSkin: TSkinDocument;
    FDragControl: TControl;
    FDragOffsetX, FDragOffsetY: Integer;
    procedure PreviewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PreviewMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure PreviewMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure OpenSkin(Sender: TObject);
    procedure SaveSkinAs(Sender: TObject);
    procedure ObjectSelected(Sender: TObject);
    procedure PropertyChanged(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
    procedure PreviewClick(Sender: TObject);
    procedure BuildPreview;
    procedure ClearPreviewControls;
  public
    property Preview: TImage read FPreview write FPreview;
    property ObjectList: TListBox read FObjectList write FObjectList;
    property PropertyGrid: TStringGrid read FPropertyGrid write FPropertyGrid;
    property FileName: string read FFileName write FFileName;
    property Skin: TSkinDocument read FSkin write FSkin;
  end;

  TUiSettingsDialog = class(TForm)
  private
    FVersionCombo: TComboBox;
    FRootEdit: TEdit;
    FPakEdits: array[0..4] of TEdit;
    FPasswordEdits: array[0..4] of TEdit;
    FGuiIni, FConfigIni: TIniFile;
    procedure OpenMainEditor(Sender: TObject);
    procedure OpenConfigEditor(Sender: TObject);
    procedure OpenStateEditor(Sender: TObject);
    procedure OpenJsyEditor(Sender: TObject);
    procedure SaveUiConfig(Sender: TObject);
    procedure SaveUiFiles(Sender: TObject);
    procedure RestoreUiDefaults(Sender: TObject);
    procedure BrowseRoot(Sender: TObject);
  end;

procedure TUiSettingsDialog.OpenMainEditor(Sender: TObject);
begin
  OpenGuiEditor(Self, gekMain, FVersionCombo.ItemIndex = 1);
end;

procedure TUiSettingsDialog.OpenConfigEditor(Sender: TObject);
begin
  OpenGuiEditor(Self, gekConfig, FVersionCombo.ItemIndex = 1);
end;

procedure TUiSettingsDialog.OpenStateEditor(Sender: TObject);
begin
  OpenGuiEditor(Self, gekState, FVersionCombo.ItemIndex = 1);
end;

procedure TUiSettingsDialog.OpenJsyEditor(Sender: TObject);
begin
  OpenGuiEditor(Self, gekJsy, FVersionCombo.ItemIndex = 1);
end;

procedure TUiSettingsDialog.SaveUiConfig(Sender: TObject);
var
  I: Integer;
begin
  if Assigned(FGuiIni) then
  begin
    FGuiIni.WriteString('Setup', 'ImageLibrary', FRootEdit.Text);
    FGuiIni.WriteString('Setup', 'ResourcesDir', 'Resources');
    for I := 0 to 4 do
    begin
      FGuiIni.WriteString('NewUI' + IntToStr(I + 1) + '_PAK', 'FileName', FPakEdits[I].Text);
      FGuiIni.WriteString('NewUI' + IntToStr(I + 1) + '_PAK', 'Password', FPasswordEdits[I].Text);
    end;
    FGuiIni.UpdateFile;
  end;
  MessageDlg('UI配置保存成功。', mtInformation, [mbOK], 0);
end;

procedure TUiSettingsDialog.SaveUiFiles(Sender: TObject);
var
  Classic: Boolean;
  Saved: Integer;
begin
  Classic := FVersionCombo.ItemIndex = 1;
  Saved := 0;
  if SaveGuiEditorFile(Self, gekMain, Classic) then Inc(Saved);
  if SaveGuiEditorFile(Self, gekConfig, Classic) then Inc(Saved);
  if SaveGuiEditorFile(Self, gekState, Classic) then Inc(Saved);
  if SaveGuiEditorFile(Self, gekJsy, False) then Inc(Saved);
  if Saved > 0 then
    MessageDlg(Format('已保存 %d 个界面文件。', [Saved]), mtInformation, [mbOK], 0)
  else
    MessageDlg('未找到可保存的界面文件。', mtWarning, [mbOK], 0);
end;

procedure TUiSettingsDialog.RestoreUiDefaults(Sender: TObject);
var
  Base, SourceName, TargetName: string;
  K: TGuiEditorKind;
  Classic: Boolean;
begin
  if MessageDlg('恢复默认界面文件？当前文件将被覆盖。', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  Base := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'tools\original-action\NewUI\';
  Classic := FVersionCombo.ItemIndex = 1;
  for K := Low(TGuiEditorKind) to High(TGuiEditorKind) do
  begin
    if K = gekJsy then
      SourceName := Base + 'JSY.ini'
    else
    begin
      case K of
        gekMain: SourceName := Base + 'Mir';
        gekConfig: SourceName := Base + 'MirConfigDlg';
        gekState: SourceName := Base + 'StateWin';
      else
        SourceName := '';
      end;
      if Classic then SourceName := SourceName + '205';
      SourceName := SourceName + '.ui';
    end;
    if FileExists(SourceName) then
    begin
      case K of
        gekMain: TargetName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'NewUI\Mir' + IfThen(Classic, '205', '') + '.ui';
        gekConfig: TargetName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'NewUI\MirConfigDlg' + IfThen(Classic, '205', '') + '.ui';
        gekState: TargetName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'NewUI\StateWin' + IfThen(Classic, '205', '') + '.ui';
        gekJsy: TargetName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'NewUI\JSY.ini';
      end;
      CopyFile(PChar(SourceName), PChar(TargetName), False);
    end;
  end;
  MessageDlg('默认界面文件已恢复。', mtInformation, [mbOK], 0);
end;

procedure TUiSettingsDialog.BrowseRoot(Sender: TObject);
var
  Path: string;
begin
  Path := FRootEdit.Text;
  if SelectDirectory('选择传奇根目录', '', Path) then
    FRootEdit.Text := Path;
end;

procedure TSettingsDialog.BrowseFile(Sender: TObject);
var
  D: TOpenDialog;
  E: TEdit;
begin
  E := TEdit(TButton(Sender).Tag);
  D := TOpenDialog.Create(Self);
  try
    D.Filter := '所有文件 (*.*)|*.*';
    if D.Execute then E.Text := D.FileName;
  finally
    D.Free;
  end;
end;

procedure TSkinEditorForm.OpenSkin(Sender: TObject);
var
  D: TOpenDialog;
begin
  D := TOpenDialog.Create(Self);
  try
    D.Title := '打开登录器皮肤';
    D.Filter := '登录器皮肤 (loginskin)|loginskin|所有文件 (*.*)|*.*';
    D.Options := [ofFileMustExist, ofPathMustExist];
    if D.Execute then
    begin
      try
        FSkin.LoadFromFile(D.FileName);
        FileName := D.FileName;
        if Assigned(FPreview) then
          FSkin.LoadPreview(FPreview.Picture.Bitmap);
        BuildPreview;
        if Assigned(FObjectList) and (FObjectList.ItemIndex < 0) then
          FObjectList.ItemIndex := 0;
        if Assigned(FObjectList) then ObjectSelected(FObjectList);
      except
        on E: Exception do
          MessageDlg('打开皮肤失败：' + E.Message, mtError, [mbOK], 0);
      end;
    end;
  finally
    D.Free;
  end;
end;

procedure TSkinEditorForm.SaveSkinAs(Sender: TObject);
var
  D: TSaveDialog;
begin
  if (not Assigned(FSkin)) or (not FSkin.IsLoaded) then
  begin
    MessageDlg('请先打开一个登录器皮肤文件。', mtWarning, [mbOK], 0);
    Exit;
  end;
  D := TSaveDialog.Create(Self);
  try
    D.Title := '另存为登录器皮肤';
    D.Filter := '登录器皮肤 (loginskin)|loginskin|所有文件 (*.*)|*.*';
    D.FileName := ExtractFileName(FileName);
    if D.Execute then
    begin
      try
        FSkin.SaveToFile(D.FileName);
        FileName := D.FileName;
        MessageDlg('皮肤文件已保存。', mtInformation, [mbOK], 0);
      except
        on E: Exception do
          MessageDlg('保存皮肤失败：' + E.Message, mtError, [mbOK], 0);
      end;
    end;
  finally
    D.Free;
  end;
end;

procedure TSkinEditorForm.ObjectSelected(Sender: TObject);
var
  Name: string;
  O: TSkinObject;
  Index: Integer;
begin
  if (not Assigned(FObjectList)) or (not Assigned(FPropertyGrid)) or
    (FObjectList.ItemIndex < 0) then Exit;
  Name := FObjectList.Items[FObjectList.ItemIndex];
  Index := FObjectList.ItemIndex;
  if Assigned(FSkin) and (Index < FSkin.ObjectCount) then
    O := FSkin.Objects[Index]
  else
  begin
    O.Left := 0; O.Top := 0; O.Width := 0; O.Height := 0;
    O.FontName := ''; O.FontSize := 0; O.Enabled := True; O.Visible := True;
  end;
  FPropertyGrid.BeginUpdate;
  try
    FPropertyGrid.RowCount := 10;
    FPropertyGrid.Cells[0, 0] := '属性';
    FPropertyGrid.Cells[1, 0] := '值';
    FPropertyGrid.Cells[0, 1] := '对象';
    FPropertyGrid.Cells[1, 1] := Name;
    FPropertyGrid.Cells[0, 2] := '左边';
    FPropertyGrid.Cells[1, 2] := IntToStr(O.Left);
    FPropertyGrid.Cells[0, 3] := '顶边';
    FPropertyGrid.Cells[1, 3] := IntToStr(O.Top);
    FPropertyGrid.Cells[0, 4] := '宽度';
    FPropertyGrid.Cells[1, 4] := IntToStr(O.Width);
    FPropertyGrid.Cells[0, 5] := '高度';
    FPropertyGrid.Cells[1, 5] := IntToStr(O.Height);
    FPropertyGrid.Cells[0, 6] := '字体';
    FPropertyGrid.Cells[1, 6] := O.FontName;
    FPropertyGrid.Cells[0, 7] := '字体大小';
    FPropertyGrid.Cells[1, 7] := IntToStr(O.FontSize);
    FPropertyGrid.Cells[0, 8] := '可用';
    FPropertyGrid.Cells[1, 8] := BoolToStr(O.Enabled, True);
    FPropertyGrid.Cells[0, 9] := '可见';
    FPropertyGrid.Cells[1, 9] := BoolToStr(O.Visible, True);
  finally
    FPropertyGrid.EndUpdate;
  end;
end;

procedure TSkinEditorForm.ClearPreviewControls;
var
  I: Integer;
  C: TControl;
begin
  if (not Assigned(FPreview)) or (not Assigned(FPreview.Parent)) then Exit;
  for I := FPreview.Parent.ControlCount - 1 downto 0 do
  begin
    C := FPreview.Parent.Controls[I];
    if C <> FPreview then C.Free;
  end;
end;

procedure TSkinEditorForm.PreviewClick(Sender: TObject);
var
  Index: Integer;
begin
  if not (Sender is TControl) then Exit;
  Index := TControl(Sender).Tag;
  if Assigned(FObjectList) and (Index >= 0) and
     (Index < FObjectList.Items.Count) then
  begin
    FObjectList.ItemIndex := Index;
    ObjectSelected(FObjectList);
  end;
end;

procedure TSkinEditorForm.PreviewMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbLeft) or not (Sender is TControl) then Exit;
  FDragControl := TControl(Sender);
  FDragOffsetX := X;
  FDragOffsetY := Y;
  PreviewClick(Sender);
end;

procedure TSkinEditorForm.PreviewMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if (FDragControl = nil) or (Sender <> FDragControl) or
     not (ssLeft in Shift) then Exit;
  FDragControl.Left := FDragControl.Left + X - FDragOffsetX;
  FDragControl.Top := FDragControl.Top + Y - FDragOffsetY;
end;

procedure TSkinEditorForm.PreviewMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  O: TSkinObject;
  Index: Integer;
begin
  if (FDragControl = nil) or (Sender <> FDragControl) then Exit;
  if Assigned(FSkin) then
  begin
    Index := FDragControl.Tag;
    if (Index >= 0) and (Index < FSkin.ObjectCount) then
    begin
      O := FSkin.Objects[Index];
      O.Left := FDragControl.Left;
      O.Top := FDragControl.Top;
      FSkin.Objects[Index] := O;
    end;
  end;
  FDragControl := nil;
  BuildPreview;
  if Assigned(FObjectList) then ObjectSelected(FObjectList);
end;

procedure TSkinEditorForm.BuildPreview;
const
  ButtonCaptions: array[13..22] of string =
    ('开始游戏', '游戏设置', '官方网站', '客户服务', '添加游戏',
     '注册帐号', '修改密码', '密码找回', '退出游戏', '取消更新');
var
  Parent: TWinControl;
  O: TSkinObject;
  I: Integer;
  L: TLabel;
  P: TPanel;
  B: TButton;
  M: TMemo;
  Box: TComboBox;
  Check: TCheckBox;
  Tree: TListBox;
  Bar: TProgressBar;
  procedure ApplyObject(AControl: TControl; AIndex: Integer);
  begin
    if (not Assigned(FSkin)) or (AIndex < 0) or
       (AIndex >= FSkin.ObjectCount) then Exit;
    O := FSkin.Objects[AIndex];
    AControl.SetBounds(O.Left, O.Top, O.Width, O.Height);
    AControl.Tag := AIndex;
    AControl.Visible := O.Visible and (O.Width > 0) and (O.Height > 0);
    if O.FontName <> '' then TControlAccess(AControl).Font.Name := O.FontName;
    if O.FontSize > 0 then TControlAccess(AControl).Font.Size := O.FontSize;
    TControlAccess(AControl).OnClick := PreviewClick;
    TControlAccess(AControl).OnMouseDown := PreviewMouseDown;
    TControlAccess(AControl).OnMouseMove := PreviewMouseMove;
    TControlAccess(AControl).OnMouseUp := PreviewMouseUp;
  end;
  function NewPanel(AIndex: Integer; const Caption: string): TPanel;
  begin
    Result := TPanel.Create(Parent);
    Result.Parent := Parent;
    Result.Caption := Caption;
    Result.Alignment := taCenter;
    Result.BevelOuter := bvRaised;
    Result.Color := RGB(96, 0, 0);
    Result.Font.Color := clWhite;
    Result.ParentBackground := False;
    ApplyObject(Result, AIndex);
  end;
begin
  if (not Assigned(FPreview)) or (not Assigned(FPreview.Parent)) then Exit;
  Parent := FPreview.Parent;
  ClearPreviewControls;
  if not Assigned(FSkin) or (FSkin.ObjectCount = 0) then Exit;

  P := NewPanel(0, '-');
  P.Font.Size := 9;
  NewPanel(1, 'x');

  Tree := TListBox.Create(Parent);
  Tree.Parent := Parent;
  Tree.Items.Add('服务器列表');
  Tree.Items.Add('默认服务器');
  Tree.ItemIndex := 0;
  ApplyObject(Tree, 2);

  Box := TComboBox.Create(Parent);
  Box.Parent := Parent; Box.Style := csDropDownList;
  Box.Items.Add('默认服务器'); Box.Items.Add('推荐线路'); Box.ItemIndex := 0;
  ApplyObject(Box, 3);
  Box := TComboBox.Create(Parent);
  Box.Parent := Parent; Box.Style := csDropDownList;
  Box.Items.Add('800 x 600'); Box.Items.Add('1024 x 768'); Box.ItemIndex := 0;
  ApplyObject(Box, 4);

  Check := TCheckBox.Create(Parent);
  Check.Parent := Parent; Check.Caption := '窗口模式';
  Check.Font.Color := clLime;
  ApplyObject(Check, 5);
  for I := 0 to 2 do
  begin
    L := TLabel.Create(Parent); L.Parent := Parent; L.Transparent := True;
    L.Font.Color := clYellow;
    case I of
      0: begin L.Caption := '当前状态'; ApplyObject(L, 6); end;
      1: begin L.Caption := '当前进度'; ApplyObject(L, 8); end;
      2: begin L.Caption := '整体进度'; ApplyObject(L, 10); end;
    end;
  end;
  L := TLabel.Create(Parent); L.Parent := Parent; L.Transparent := True;
  L.Caption := '正在获取远程配置信息...'; L.Font.Color := clAqua;
  ApplyObject(L, 7);
  Bar := TProgressBar.Create(Parent); Bar.Parent := Parent; Bar.Position := 35;
  ApplyObject(Bar, 9);
  Bar := TProgressBar.Create(Parent); Bar.Parent := Parent; Bar.Position := 65;
  ApplyObject(Bar, 11);

  M := TMemo.Create(Parent); M.Parent := Parent; M.ReadOnly := True;
  M.ScrollBars := ssVertical; M.Lines.Text := '公告栏';
  ApplyObject(M, 12);

  for I := 13 to 22 do
  begin
    B := TButton.Create(Parent); B.Parent := Parent; B.Caption := ButtonCaptions[I];
    ApplyObject(B, I);
  end;
end;

procedure TSkinEditorForm.PropertyChanged(Sender: TObject; ACol, ARow: Integer;
  const Value: string);
var
  O: TSkinObject;
  Index, N: Integer;
  B: Boolean;
begin
  if (ACol <> 1) or (ARow < 2) or (not Assigned(FSkin)) or
     (not Assigned(FObjectList)) or (FObjectList.ItemIndex < 0) then Exit;
  Index := FObjectList.ItemIndex;
  if Index >= FSkin.ObjectCount then Exit;
  O := FSkin.Objects[Index];
  if ARow = 6 then O.FontName := Value
  else if ARow = 8 then
  begin
    B := SameText(Trim(Value), 'true') or (Trim(Value) = '1') or
      SameText(Trim(Value), '是');
    O.Enabled := B;
  end
  else if ARow = 9 then
  begin
    B := SameText(Trim(Value), 'true') or (Trim(Value) = '1') or
      SameText(Trim(Value), '是');
    O.Visible := B;
  end
  else if TryStrToInt(Trim(Value), N) then
    case ARow of
      2: O.Left := N;
      3: O.Top := N;
      4: O.Width := N;
      5: O.Height := N;
      7: O.FontSize := N;
    end
  else Exit;
  FSkin.Objects[Index] := O;
  BuildPreview;
end;

procedure TPluginDialog.RefreshPlugins(Sender: TObject);
var
  Search: TSearchRec;
  PluginPath: string;
begin
  FPluginList.Items.BeginUpdate;
  try
    FPluginList.Clear;
    PluginPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
      '补丁文件夹\Plugin\';
    if FindFirst(PluginPath + '*.*', faAnyFile, Search) = 0 then
    try
      repeat
        if (Search.Name <> '.') and (Search.Name <> '..') and
           ((Search.Attr and faDirectory) = 0) then
          FPluginList.Items.Add(Search.Name);
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
  finally
    FPluginList.Items.EndUpdate;
  end;
end;

function RuleFilePart(const ALine: string): string;
var
  P: Integer;
begin
  Result := Trim(ALine);
  P := Pos('|', Result);
  if P > 0 then Result := Copy(Result, 1, P - 1);
end;

procedure TReadRulesDialog.RemoveDuplicates(ATarget, AReference: TStrings);
var
  Keys: TStringList;
  I: Integer;
  S: string;
begin
  Keys := TStringList.Create;
  try
    Keys.Sorted := True;
    Keys.Duplicates := dupIgnore;
    Keys.CaseSensitive := False;
    for I := 0 to AReference.Count - 1 do
    begin
      S := RuleFilePart(AReference[I]);
      if S <> '' then Keys.Add(ChangeFileExt(S, ''));
    end;
    for I := ATarget.Count - 1 downto 0 do
    begin
      S := RuleFilePart(ATarget[I]);
      if (S = '') or (not FileExists(S)) or
         (Keys.IndexOf(ChangeFileExt(S, '')) >= 0) then
        ATarget.Delete(I);
    end;
  finally
    Keys.Free;
  end;
end;

procedure TReadRulesDialog.DeleteWilDuplicates(Sender: TObject);
begin
  RemoveDuplicates(FMemos[0].Lines, FMemos[1].Lines);
end;

procedure TReadRulesDialog.DeleteWzlDuplicates(Sender: TObject);
begin
  RemoveDuplicates(FMemos[1].Lines, FMemos[0].Lines);
end;

procedure TReadRulesDialog.ScanFolder(const ARoot, AFolder: string);
var
  Search: TSearchRec;
  Name, RelativeName, RelativeLower, Ext: string;
begin
  if FindFirst(IncludeTrailingPathDelimiter(AFolder) + '*', faAnyFile, Search) <> 0 then
    Exit;
  try
    repeat
      if (Search.Name = '.') or (Search.Name = '..') then Continue;
      Name := IncludeTrailingPathDelimiter(AFolder) + Search.Name;
      if (Search.Attr and faDirectory) <> 0 then
      begin
        ScanFolder(ARoot, Name);
        Continue;
      end;
      RelativeName := Copy(Name, Length(IncludeTrailingPathDelimiter(ARoot)) + 1,
        MaxInt);
      RelativeLower := LowerCase(StringReplace(RelativeName, '/', '\', [rfReplaceAll]));
      Ext := LowerCase(ExtractFileExt(Name));
      if Ext = '.wil' then FMemos[0].Lines.Add(Name)
      else if Ext = '.wzl' then FMemos[1].Lines.Add(Name)
      else if Ext = '.pak' then FMemos[2].Lines.Add(Name);
      if StartsText('resources\data\', RelativeLower) then
        FMemos[3].Lines.Add(Name)
      else if StartsText('resources\map\', RelativeLower) then
        FMemos[4].Lines.Add(Name)
      else if StartsText('resources\wav\', RelativeLower) then
        FMemos[5].Lines.Add(Name);
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

procedure TReadRulesDialog.AutoScan(Sender: TObject);
var
  Root: string;
  I: Integer;
begin
  Root := '';
  if not SelectDirectory('选择传奇客户端根目录', '', Root) then Exit;
  for I := 0 to 5 do
  begin
    FMemos[I].Lines.BeginUpdate;
    FMemos[I].Lines.Clear;
  end;
  try
    ScanFolder(ExcludeTrailingPathDelimiter(Root), ExcludeTrailingPathDelimiter(Root));
    for I := 0 to 5 do TStringList(FMemos[I].Lines).Sort;
  finally
    for I := 0 to 5 do FMemos[I].Lines.EndUpdate;
  end;
end;

function ConfigIniName: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'Config.ini';
end;

procedure LoadTaggedChecks(AParent: TWinControl; AIni: TIniFile);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[I];
    if (C is TCheckBox) and (C.Tag > 0) then
      TCheckBox(C).Checked := AIni.ReadBool('Setup',
        'Checked' + IntToStr(C.Tag - 1), TCheckBox(C).Checked);
    if C is TWinControl then LoadTaggedChecks(TWinControl(C), AIni);
  end;
end;

procedure SaveTaggedChecks(AParent: TWinControl; AIni: TIniFile);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[I];
    if (C is TCheckBox) and (C.Tag > 0) then
      AIni.WriteBool('Setup', 'Checked' + IntToStr(C.Tag - 1),
        TCheckBox(C).Checked);
    if C is TWinControl then SaveTaggedChecks(TWinControl(C), AIni);
  end;
end;

procedure LoadNumberedSection(AIni: TIniFile; const ASection: string;
  ALines: TStrings);
var
  I, Count: Integer;
begin
  ALines.BeginUpdate;
  try
    ALines.Clear;
    Count := AIni.ReadInteger(ASection, 'Count', 0);
    for I := 0 to Count - 1 do
      ALines.Add(AIni.ReadString(ASection, IntToStr(I), ''));
  finally
    ALines.EndUpdate;
  end;
end;

procedure SaveNumberedSection(AIni: TIniFile; const ASection: string;
  ALines: TStrings);
var
  I: Integer;
begin
  AIni.EraseSection(ASection);
  AIni.WriteInteger(ASection, 'Count', ALines.Count);
  for I := 0 to ALines.Count - 1 do
    AIni.WriteString(ASection, IntToStr(I), ALines[I]);
end;

function LabelAt(AParent: TWinControl; const S: string; X, Y: Integer): TLabel; forward;
function EditAt(AParent: TWinControl; const S: string; X, Y, W: Integer): TEdit; forward;
function CheckAt(AParent: TWinControl; const S: string;
  X, Y: Integer; Checked: Boolean = False): TCheckBox; forward;
procedure SpinAt(AParent: TWinControl; const S: string;
  X, Y, W, AMin, AMax: Integer; out AEdit: TEdit); overload; forward;

function KeyEditAt(AParent: TWinControl; const ACaption, AKey, AValue: string;
  X, Y, W: Integer): TEdit;
begin
  LabelAt(AParent, ACaption, X, Y + 3);
  Result := EditAt(AParent, AValue, X + 92, Y, W);
  Result.Hint := AKey;
end;

function KeyCheckAt(AParent: TWinControl; const ACaption, AKey: string;
  X, Y: Integer): TCheckBox;
begin
  Result := CheckAt(AParent, ACaption, X, Y);
  Result.Hint := AKey;
end;

function HintEditAt(AParent: TWinControl; const AValue, AKey: string;
  X, Y, W: Integer): TEdit;
begin
  Result := EditAt(AParent, AValue, X, Y, W);
  Result.Hint := AKey;
end;

function HintSpinAt(AParent: TWinControl; const AValue, AKey: string;
  X, Y, W, AMin, AMax: Integer): TEdit;
begin
  SpinAt(AParent, AValue, X, Y, W, AMin, AMax, Result);
  Result.Hint := AKey;
end;

procedure LoadHintFields(AParent: TWinControl; AIni: TIniFile);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[I];
    if C.Hint <> '' then
    begin
      if C is TEdit then
        TEdit(C).Text := AIni.ReadString('Setup', C.Hint, TEdit(C).Text)
      else if C is TCheckBox then
        TCheckBox(C).Checked := AIni.ReadBool('Setup', C.Hint, TCheckBox(C).Checked);
    end;
    if C is TWinControl then LoadHintFields(TWinControl(C), AIni);
  end;
end;

procedure SaveHintFields(AParent: TWinControl; AIni: TIniFile);
var
  I: Integer;
  C: TControl;
begin
  for I := 0 to AParent.ControlCount - 1 do
  begin
    C := AParent.Controls[I];
    if C.Hint <> '' then
    begin
      if C is TEdit then
        AIni.WriteString('Setup', C.Hint, TEdit(C).Text)
      else if C is TCheckBox then
        AIni.WriteBool('Setup', C.Hint, TCheckBox(C).Checked);
    end;
    if C is TWinControl then SaveHintFields(TWinControl(C), AIni);
  end;
end;

function NewDialog(AOwner: TComponent; const ACaption: string;
  AClientWidth, AClientHeight: Integer): TForm;
begin
  Result := TForm.CreateNew(AOwner);
  Result.BorderStyle := bsSingle;
  Result.BorderIcons := [biSystemMenu, biMinimize];
  Result.Caption := ACaption;
  Result.ClientWidth := AClientWidth;
  Result.ClientHeight := AClientHeight + 10;
  Result.Position := poOwnerFormCenter;
  Result.Scaled := False;
  Result.Font.Name := '宋体';
  Result.Font.Size := 9;
  Result.Color := clBtnFace;
end;

function LabelAt(AParent: TWinControl; const S: string; X, Y: Integer): TLabel;
begin
  Result := TLabel.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := S;
  Result.SetBounds(X, Y, Result.Canvas.TextWidth(S) + 4, 17);
end;

function EditAt(AParent: TWinControl; const S: string; X, Y, W: Integer): TEdit;
begin
  Result := TEdit.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(X, Y, W, 20);
  Result.Text := S;
end;

function ButtonAt(AParent: TWinControl; const S: string;
  X, Y, W, H: Integer; ModalResult: TModalResult = mrNone): TButton;
begin
  Result := TButton.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := S;
  Result.SetBounds(X, Y, W, H);
  Result.ModalResult := ModalResult;
end;

function CheckAt(AParent: TWinControl; const S: string;
  X, Y: Integer; Checked: Boolean = False): TCheckBox;
begin
  Result := TCheckBox.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := S;
  Result.SetBounds(X, Y, Length(S) * 14 + 24, 17);
  Result.Checked := Checked;
end;

function GroupAt(AParent: TWinControl; const S: string;
  X, Y, W, H: Integer): TGroupBox;
begin
  Result := TGroupBox.Create(AParent);
  Result.Parent := AParent;
  Result.Caption := S;
  Result.SetBounds(X, Y, W, H);
end;

procedure SpinAt(AParent: TWinControl; const S: string;
  X, Y, W, AMin, AMax: Integer); overload;
var
  E: TEdit;
  U: TUpDown;
begin
  E := EditAt(AParent, S, X, Y, W);
  U := TUpDown.Create(AParent);
  U.Parent := AParent;
  U.Associate := E;
  U.Min := AMin;
  U.Max := AMax;
  U.Position := StrToIntDef(S, AMin);
  U.Thousands := False;
end;

procedure SpinAt(AParent: TWinControl; const S: string;
  X, Y, W, AMin, AMax: Integer; out AEdit: TEdit); overload;
var
  U: TUpDown;
begin
  AEdit := EditAt(AParent, S, X, Y, W);
  U := TUpDown.Create(AParent);
  U.Parent := AParent;
  U.Associate := AEdit;
  U.Min := AMin;
  U.Max := AMax;
  U.Position := StrToIntDef(S, AMin);
  U.Thousands := False;
end;

procedure AddPathRow(AParent: TWinControl; const Caption: string; Y: Integer); overload;
var
  E: TEdit;
  B: TButton;
  F: TCustomForm;
begin
  CheckAt(AParent, Caption, 16, Y + 2);
  E := EditAt(AParent, '', 122, Y, 300);
  B := ButtonAt(AParent, '...', 405, Y, 17, 20);
  B.Tag := NativeInt(E);
  F := GetParentForm(AParent);
  if F is TSettingsDialog then B.OnClick := TSettingsDialog(F).BrowseFile;
end;

procedure AddPathRow(AParent: TWinControl; const Caption: string; Y: Integer;
  out ACheck: TCheckBox; out AEdit: TEdit); overload;
var
  B: TButton;
  F: TCustomForm;
begin
  ACheck := CheckAt(AParent, Caption, 16, Y + 2);
  AEdit := EditAt(AParent, '', 122, Y, 300);
  B := ButtonAt(AParent, '...', 405, Y, 17, 20);
  B.Tag := NativeInt(AEdit);
  F := GetParentForm(AParent);
  if F is TSettingsDialog then B.OnClick := TSettingsDialog(F).BrowseFile;
end;

procedure ShowPluginDialog(AOwner: TComponent);
var
  F: TPluginDialog;
  T: TLabel;
  B: TButton;
begin
  F := TPluginDialog.CreateNew(AOwner);
  try
    F.BorderStyle := bsSingle;
    F.BorderIcons := [biSystemMenu, biMinimize];
    F.Caption := '客户端插件';
    F.ClientWidth := 640; F.ClientHeight := 305;
    F.Position := poOwnerFormCenter; F.Scaled := False;
    F.Font.Name := '宋体'; F.Font.Size := 9;
    F.FPluginList := TListBox.Create(F);
    F.FPluginList.Parent := F;
    F.FPluginList.SetBounds(8, 8, 612, 250);
    T := LabelAt(F, '将插件文件放到“补丁文件夹\Plugin”文件夹下面', 8, 269);
    T.Font.Color := clBlue;
    B := ButtonAt(F, '刷新(&R)', 548, 266, 72, 24);
    B.OnClick := F.RefreshPlugins;
    F.RefreshPlugins(nil);
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure ShowReadRules(AOwner: TComponent);
const
  TabNames: array[0..4] of string = ('Wil', 'Wzl', 'Pak', 'Resources\Data', 'Resources\Map');
  RuleFiles: array[0..5] of string =
    ('Wil.txt', 'Wzl.txt', 'Pak.txt', 'Data.txt', 'Map.txt', 'Wav.txt');
var
  F: TReadRulesDialog;
  P: TPageControl;
  T: TTabSheet;
  Panel, G: TGroupBox;
  L: TLabel;
  I: Integer;
  B: TButton;
  Radios: array[0..4] of TRadioButton;
  Ini: TIniFile;
  BasePath: string;
begin
  F := TReadRulesDialog.CreateNew(AOwner);
  try
    F.BorderStyle := bsSingle;
    F.BorderIcons := [biSystemMenu, biMinimize];
    F.Caption := '客户端按照以下文件读取';
    F.ClientWidth := 976; F.ClientHeight := 669;
    F.Position := poOwnerFormCenter; F.Scaled := False;
    F.Font.Name := '宋体'; F.Font.Size := 9; F.Color := clBtnFace;
    P := TPageControl.Create(F);
    P.Parent := F;
    P.SetBounds(8, 0, 962, 527);
    P.TabHeight := 24;
    for I := Low(TabNames) to High(TabNames) do
    begin
      T := TTabSheet.Create(P);
      T.PageControl := P;
      T.Caption := TabNames[I];
      F.FMemos[I] := TMemo.Create(T);
      F.FMemos[I].Parent := T;
      F.FMemos[I].Align := alClient;
      F.FMemos[I].ScrollBars := ssBoth;
      F.FMemos[I].WordWrap := False;
    end;
    T := TTabSheet.Create(P);
    T.PageControl := P;
    T.Caption := 'Resources\Wav';
    F.FMemos[5] := TMemo.Create(T); F.FMemos[5].Parent := T;
    F.FMemos[5].Align := alClient; F.FMemos[5].ScrollBars := ssBoth;
    F.FMemos[5].WordWrap := False;

    B := ButtonAt(F, '删除Wil列表中Wzl格式已经存在的文件', 8, 535, 217, 25);
    B.OnClick := F.DeleteWilDuplicates;
    B := ButtonAt(F, '删除Wzl列表中Wil格式已经存在的文件', 8, 567, 217, 25);
    B.OnClick := F.DeleteWzlDuplicates;
    B := ButtonAt(F, '选择传奇客户端自动读取', 8, 599, 217, 25);
    B.OnClick := F.AutoScan;
    ButtonAt(F, '保存', 8, 631, 217, 25, mrOk);
    Panel := GroupAt(F, '资源读取顺序', 232, 531, 121, 125);
    Radios[0] := TRadioButton.Create(Panel); Radios[0].Parent := Panel;
    Radios[0].Caption := 'Pak→Wzl→Wil'; Radios[0].SetBounds(8, 17, 108, 17); Radios[0].Checked := True;
    Radios[1] := TRadioButton.Create(Panel); Radios[1].Parent := Panel;
    Radios[1].Caption := 'Pak→Wil→Wzl'; Radios[1].SetBounds(8, 38, 108, 17);
    Radios[2] := TRadioButton.Create(Panel); Radios[2].Parent := Panel;
    Radios[2].Caption := 'Pak→Wil'; Radios[2].SetBounds(8, 59, 108, 17);
    Radios[3] := TRadioButton.Create(Panel); Radios[3].Parent := Panel;
    Radios[3].Caption := 'Pak→Wzl'; Radios[3].SetBounds(8, 80, 108, 17);
    Radios[4] := TRadioButton.Create(Panel); Radios[4].Parent := Panel;
    Radios[4].Caption := 'Pak'; Radios[4].SetBounds(8, 101, 108, 17);
    G := GroupAt(F, '读取规则说明：', 359, 531, 611, 125);
    L := LabelAt(G, '1、当使用微端时，且读取规则列表中有pak，微端直接请求更新pak，而不再读 wzl、wil', 14, 30);
    L.Font.Color := clRed;
    L := LabelAt(G, '2、不使用微端时，读取按配置的规则进行', 14, 54); L.Font.Color := clRed;
    L := LabelAt(G, '【说明：服务器列表中，微端网关端口写不为0表示使用微端，为0表示不用微端】', 14, 78);
    L.Font.Color := clRed;
    BasePath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
    for I := 0 to 5 do
      if FileExists(BasePath + RuleFiles[I]) then
        F.FMemos[I].Lines.LoadFromFile(BasePath + RuleFiles[I]);
    Ini := TIniFile.Create(ConfigIniName);
    try
      I := Ini.ReadInteger('Setup', 'LoadResourcesOrder', 0);
      if not (I in [0..4]) then I := 0;
      Radios[I].Checked := True;
      if F.ShowModal = mrOk then
      begin
        for I := 0 to 5 do F.FMemos[I].Lines.SaveToFile(BasePath + RuleFiles[I]);
        for I := 0 to 4 do
          if Radios[I].Checked then
          begin
            Ini.WriteInteger('Setup', 'LoadResourcesOrder', I);
            Break;
          end;
      end;
    finally
      Ini.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure ShowInnerSettings(AOwner: TComponent);
const
  C1: array[0..13] of string = ('显示血条','数字显血','职业等级','经验过滤','顶部信息','显示人名','隐藏封号','数字飘血','自动捡取','攻击不卡','武器简装','稳如泰山','免负重','魔法锁定');
  C2: array[0..13] of string = ('全部拾取','自动放药','自动关组','持久警告','免Shift开关','Shift开关','隐藏尸体','隐藏翅膀效果','隐藏武器效果','显示地图标识','人物高亮显血','自动隐身','自动断空斩','自动开盾');
  C3: array[0..13] of string = ('接近开盾','刀刀刺杀','隔位刺杀','走位刺杀','智能半月','自动烈火','逐日剑法','双龙斩','龙影剑法','背景音乐','重复音乐','显示怪名','内功黄条','防止石化');
  C4: array[0..13] of string = ('手动冰咆哮','手动爆裂火焰','疾光电影锁定目标','手动流星火雨','红绿毒互换','免助跑','自动开天斩','英雄持续开盾','副英雄持续开盾','主将英雄药品','副将英雄药品','屏幕震动','NPC名字','NPC血条');
  C5: array[0..13] of string = ('隐藏称号','自动凝聚技能','禁止拉动聊天框','装备对比','音量','持续挖取','禁止交易','微端状态显示','怪物简装','外显时装','手动十步一杀','衣服简装','隐藏特效','自动合击');
  C6: array[0..13] of string = ('合击不打怪','背包对比','手动控制地狱火','血量单位','显示目标光圈','左侧显示组队信息','宝宝简装','自定义技能1','自定义技能2','自定义技能3','自定义技能4','自定义技能5','自定义技能6','自定义技能7');
  C7: array[0..13] of string = ('自定义技能8','手动技能预留1','手动技能预留2','手动技能预留3','手动技能预留4','手动技能预留5','极品特效','自动连击','隐藏顶戴花翎','隐藏怪物顶戴','火墙淡化','自动绕行','','');
  Xs: array[0..6] of Integer = (8, 81, 178, 251, 372, 482, 603);
var
  F: TForm;
  G, Reserve, Ext: TGroupBox;
  I, J: Integer;
  S: string;
  Ini: TIniFile;
  C: TCheckBox;
begin
  F := NewDialog(AOwner, '内挂相关设置', 730, 409);
  try
    G := GroupAt(F, '内挂默认状态  (登录器第一次启动时内挂的各个选项默认是开启或关闭)', 8, 8, 713, 319);
    for J := 0 to 6 do
      for I := 0 to 13 do
      begin
        case J of
          0: S := C1[I]; 1: S := C2[I]; 2: S := C3[I]; 3: S := C4[I];
          4: S := C5[I]; 5: S := C6[I]; else S := C7[I];
        end;
        if S <> '' then
        begin
          C := CheckAt(G, S, Xs[J], 20 + I * 21,
            (J < 4) and (I mod 5 <> 3));
          C.Tag := J * 14 + I + 1;
        end;
      end;
    Reserve := GroupAt(F, '手动技能预留对应技能ID', 8, 333, 590, 48);
    for I := 0 to 4 do
    begin
      LabelAt(Reserve, '预留' + IntToStr(I + 1) + ':', 8 + I * 117, 22);
      SpinAt(Reserve, '0', 48 + I * 117, 17, 68, 0, 65535);
    end;
    Ext := GroupAt(F, '内挂默认状态扩展', 605, 333, 116, 48);
    C := CheckAt(Ext, '自动修复持久', 8, 22, False);
    C.Tag := 112;
    ButtonAt(F, '确定(&O)', 646, 384, 75, 25, mrOk);
    Ini := TIniFile.Create(ConfigIniName);
    try
      LoadTaggedChecks(F, Ini);
      if F.ShowModal = mrOk then SaveTaggedChecks(F, Ini);
    finally
      Ini.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure ShowClientOptions(AOwner: TComponent);
var
  F: TForm;
  G: TGroupBox;
  ProtectMemo, BossMemo: TMemo;
  L: TLabel;
  CWindowMax, CHealth, C1024, COpenDoor, CVersion, CLoadProgress,
    CRunProgress, CChangeBit, CWaitStart, CCtrlZ, COldMusic: TCheckBox;
  EMaxClient, EThreads, EQueue: TEdit;
  Ini: TIniFile;
begin
  F := NewDialog(AOwner, '客户端选项', 582, 327);
  try
    G := GroupAt(F, '显示控制', 8, 8, 251, 142);
    CWindowMax := CheckAt(G, '窗口模式最大化', 12, 18);
    CHealth := CheckAt(G, '显示健康公告', 12, 38, True);
    C1024 := CheckAt(G, '显示1024界面', 143, 38, True);
    COpenDoor := CheckAt(G, '显示开门动作', 12, 58, True);
    CVersion := CheckAt(G, '显示版本信息', 143, 58, True);
    CLoadProgress := CheckAt(G, '在公告显示之前显示资源加载进度信息', 12, 78, True);
    CRunProgress := CheckAt(G, '启动时显示带有进度条红色背景对话框', 12, 98);
    CChangeBit := CheckAt(G, '窗口化登录强制修改桌面颜色为16位色', 12, 118);

    G := GroupAt(F, '其他设置', 8, 154, 251, 99);
    LabelAt(G, '限定游戏多开数量:', 12, 18).Font.Color := clBlue;
    SpinAt(G, '6', 112, 12, 49, 1, 99, EMaxClient);
    CWaitStart := CheckAt(G, '小退开始按钮变灰时，等几秒才能点击', 14, 37, True);
    CCtrlZ := CheckAt(G, '启用Ctrl+Z键显示地上物品', 14, 57, True);
    COldMusic := CheckAt(G, '复古背景音乐', 14, 77, True);

    G := GroupAt(F, '微端更新设置', 8, 258, 251, 42);
    LabelAt(G, '线程数量:', 12, 18); SpinAt(G, '12', 63, 12, 59, 1, 99, EThreads);
    LabelAt(G, '请求队列数:', 132, 18); SpinAt(G, '1', 196, 12, 49, 1, 99, EQueue);

    G := GroupAt(F, '自定义保护使用物品', 269, 8, 145, 292);
    ProtectMemo := TMemo.Create(G); ProtectMemo.Parent := G;
    ProtectMemo.SetBounds(8, 17, 129, 234); ProtectMemo.ScrollBars := ssBoth;
    L := LabelAt(G, '留空则使用默认配置', 8, 255); L.Font.Color := clRed;
    L := LabelAt(G, '每行一个，;号不用加', 8, 272); L.Font.Color := clRed;

    G := GroupAt(F, '自定义BOSS', 421, 8, 150, 292);
    BossMemo := TMemo.Create(G); BossMemo.Parent := G;
    BossMemo.SetBounds(8, 17, 132, 235); BossMemo.ScrollBars := ssBoth;
    L := LabelAt(G, '客户端未配置BOSS时', 8, 255); L.Font.Color := clRed;
    L := LabelAt(G, '默认使用上面的配置列表', 8, 272); L.Font.Color := clRed;
    ButtonAt(F, '确定', 410, 305, 75, 25, mrOk);
    ButtonAt(F, '取消', 495, 305, 75, 25, mrCancel);
    Ini := TIniFile.Create(ConfigIniName);
    try
      CWindowMax.Checked := Ini.ReadBool('Setup', 'WindowBiMaximize', CWindowMax.Checked);
      CHealth.Checked := Ini.ReadBool('Setup', 'ShowHealthNotice', CHealth.Checked);
      C1024.Checked := Ini.ReadBool('Setup', 'Show1024', C1024.Checked);
      COpenDoor.Checked := Ini.ReadBool('Setup', 'ShowOpenDoor', COpenDoor.Checked);
      CVersion.Checked := Ini.ReadBool('Setup', 'ShowVersion', CVersion.Checked);
      CLoadProgress.Checked := Ini.ReadBool('Setup', 'ShowLoadResProgress', CLoadProgress.Checked);
      CRunProgress.Checked := Ini.ReadBool('Setup', 'ShowProgressOnRun', CRunProgress.Checked);
      CChangeBit.Checked := Ini.ReadBool('Setup', 'ChangeSrceenBitCount', CChangeBit.Checked);
      EMaxClient.Text := Ini.ReadString('Setup', '多开数量', EMaxClient.Text);
      CWaitStart.Checked := Ini.ReadBool('Setup', 'WaitStart', CWaitStart.Checked);
      CCtrlZ.Checked := Ini.ReadBool('Setup', 'EnableCtrlZ', CCtrlZ.Checked);
      COldMusic.Checked := Ini.ReadBool('Setup', 'PlayOldVerSound', COldMusic.Checked);
      EThreads.Text := Ini.ReadString('Setup', 'UpdateThreadCount', EThreads.Text);
      EQueue.Text := Ini.ReadString('Setup', 'UpdateQueueCount', EQueue.Text);
      LoadNumberedSection(Ini, 'GJUseItems', ProtectMemo.Lines);
      LoadNumberedSection(Ini, 'BossList', BossMemo.Lines);
      if F.ShowModal = mrOk then
      begin
        Ini.WriteBool('Setup', 'WindowBiMaximize', CWindowMax.Checked);
        Ini.WriteBool('Setup', 'ShowHealthNotice', CHealth.Checked);
        Ini.WriteBool('Setup', 'Show1024', C1024.Checked);
        Ini.WriteBool('Setup', 'ShowOpenDoor', COpenDoor.Checked);
        Ini.WriteBool('Setup', 'ShowVersion', CVersion.Checked);
        Ini.WriteBool('Setup', 'ShowLoadResProgress', CLoadProgress.Checked);
        Ini.WriteBool('Setup', 'ShowProgressOnRun', CRunProgress.Checked);
        Ini.WriteBool('Setup', 'ChangeSrceenBitCount', CChangeBit.Checked);
        Ini.WriteString('Setup', '多开数量', EMaxClient.Text);
        Ini.WriteBool('Setup', 'WaitStart', CWaitStart.Checked);
        Ini.WriteBool('Setup', 'EnableCtrlZ', CCtrlZ.Checked);
        Ini.WriteBool('Setup', 'PlayOldVerSound', COldMusic.Checked);
        Ini.WriteString('Setup', 'UpdateThreadCount', EThreads.Text);
        Ini.WriteString('Setup', 'UpdateQueueCount', EQueue.Text);
        SaveNumberedSection(Ini, 'GJUseItems', ProtectMemo.Lines);
        SaveNumberedSection(Ini, 'BossList', BossMemo.Lines);
      end;
    finally
      Ini.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure ShowUiSettings(AOwner: TComponent);
var
  F: TUiSettingsDialog;
  G, G2: TGroupBox;
  P: TPageControl;
  T, Other, Text1, Text2, Tips: TTabSheet;
  OtherScroll: TScrollBox;
  C: TComboBox;
  L: TLabel;
  Ini: TIniFile;
  GuiIni: TIniFile;
  RootEdit: TEdit;
  PakEdits, PasswordEdits: array[0..4] of TEdit;
  B: TButton;
  I, Col, Row: Integer;
  TextKeys: array[0..11] of string;
  TextNames: array[0..11] of string;
  PropertyKeys: array[0..24] of string;
  TipKeys: array[0..7] of string;
  TipNames: array[0..7] of string;
  ColorKeys: array[0..7] of string;
  ColorNames: array[0..7] of string;
begin
  F := TUiSettingsDialog.CreateNew(AOwner);
  F.BorderStyle := bsSingle;
  F.BorderIcons := [biSystemMenu, biMinimize];
  F.Caption := '界面UI设置';
  F.ClientWidth := 683;
  F.ClientHeight := 544;
  F.Position := poOwnerFormCenter;
  F.Scaled := False;
  F.Font.Name := '宋体';
  F.Font.Size := 9;
  try
    LabelAt(F, '传奇根目录:', 8, 14);
    RootEdit := EditAt(F, 'E:\Legend of mir', 80, 8, 414);
    F.FRootEdit := RootEdit;
    B := ButtonAt(F, '...', 477, 8, 17, 20); B.OnClick := F.BrowseRoot;
    L := LabelAt(F, '自定义素材，放入Resources目录', 498, 14); L.Font.Color := clBlue;

    G := GroupAt(F, '自定义UI素材读取配置', 8, 35, 377, 136);
    for I := 0 to 4 do
    begin
      LabelAt(G, 'NewUI' + IntToStr(I + 1) + '.PAK', 8, 24 + I * 22);
      if I = 4 then
        PakEdits[I] := EditAt(G, 'NewopUI.Pak', 72, 18 + I * 22, 143)
      else
        PakEdits[I] := EditAt(G, 'NewUI' + IntToStr(I + 1) + '.PAK',
          72, 18 + I * 22, 143);
      LabelAt(G, '密码', 226, 24 + I * 22);
      PasswordEdits[I] := EditAt(G, 'V8M2', 256, 18 + I * 22, 112);
      F.FPakEdits[I] := PakEdits[I];
      F.FPasswordEdits[I] := PasswordEdits[I];
    end;

    G := GroupAt(F, '客户端界面编辑', 394, 35, 277, 136);
    LabelAt(G, '发布成自定义UI基础版本:', 8, 24);
    C := TComboBox.Create(G); C.Parent := G; C.SetBounds(152, 18, 116, 21);
    C.Items.Add('13周年版'); C.Items.Add('经典版'); C.ItemIndex := 0;
    F.FVersionCombo := C;
    ButtonAt(G, '主界面', 8, 46, 59, 25).OnClick := F.OpenMainEditor;
    ButtonAt(G, '内挂界面', 71, 46, 59, 25).OnClick := F.OpenConfigEditor;
    ButtonAt(G, '连击界面', 134, 46, 59, 25).OnClick := F.OpenStateEditor;
    ButtonAt(G, '及时雨界面', 197, 46, 68, 25).OnClick := F.OpenJsyEditor;
    B := ButtonAt(G, '保存配置', 8, 76, 82, 25); B.OnClick := F.SaveUiConfig;
    B := ButtonAt(G, '保存界面文件', 96, 76, 82, 25); B.OnClick := F.SaveUiFiles;
    B := ButtonAt(G, '恢复默认', 183, 76, 82, 25); B.OnClick := F.RestoreUiDefaults;
    KeyCheckAt(G, '完全自定义内挂各选项及位置', 'CustomConfigDlg', 8, 108);
    L := LabelAt(F, '提示：修改UI后点击“保存界面文件”后重新生成功能生效； 若不再使用自定义界面，删除NewUI文件夹下的对应文件即可', 8, 178);
    L.Font.Color := clRed;

    P := TPageControl.Create(F); P.Parent := F; P.SetBounds(8, 198, 664, 340); P.TabHeight := 24;
    T := TTabSheet.Create(P); T.PageControl := P; T.Caption := '主界面';
    Other := TTabSheet.Create(P); Other.PageControl := P; Other.Caption := '其它配置';
    OtherScroll := TScrollBox.Create(Other);
    OtherScroll.Parent := Other;
    OtherScroll.Align := alClient;
    OtherScroll.VertScrollBar.Range := 430;
    Text1 := TTabSheet.Create(P); Text1.PageControl := P; Text1.Caption := '自定义文字';
    Text2 := TTabSheet.Create(P); Text2.PageControl := P; Text2.Caption := '自定义文字2';
    Tips := TTabSheet.Create(P); Tips.PageControl := P; Tips.Caption := '装备提示';

    G := GroupAt(T, '小地图交易等按钮', 4, 0, 126, 87);
    KeyCheckAt(G, '位置保持不变', 'ChatTopButtonNoMove', 8, 17);
    LabelAt(G, 'X间距:', 8, 43); HintSpinAt(G, '29', 'ChatTopButtonXSpace', 45, 36, 74, -999, 999);
    LabelAt(G, 'Y间距:', 8, 67); HintSpinAt(G, '0', 'ChatTopButtonYSpace', 45, 60, 74, -999, 999);
    G := GroupAt(T, '喊话等功能间距', 135, 0, 126, 87);
    KeyCheckAt(G, '位置保持不变', 'LeftButtonNoMove', 8, 17);
    LabelAt(G, 'X间距:', 8, 43); HintSpinAt(G, '0', 'LeftButtonXSpace', 45, 36, 74, -999, 999);
    LabelAt(G, 'Y间距:', 8, 67); HintSpinAt(G, '20', 'LeftButtonYSpace', 45, 60, 74, -999, 999);
    G := GroupAt(T, '飘血分开显示', 270, 0, 183, 61);
    KeyCheckAt(G, '飘血分开显示', 'HealthNumberSeparate', 8, 15);
    LabelAt(G, '自己:', 8, 38); HintSpinAt(G, '0', 'HealthNumberSelfOffset', 43, 31, 52, -999, 999);
    LabelAt(G, '人物:', 99, 38); HintSpinAt(G, '0', 'HealthNumberHumOffset', 134, 31, 42, -999, 999);
    G := GroupAt(T, '动态显示装备星星', 468, 0, 183, 125);
    KeyCheckAt(G, '动态显示装备星星', 'ShowAniStarImage', 8, 15);
    LabelAt(G, '星星开始图片:', 8, 39); HintSpinAt(G, '0', 'ShowAniStarImageIndex', 100, 31, 74, 0, 999999);
    LabelAt(G, '每组星星数量:', 8, 61); HintSpinAt(G, '0', 'ShowAniStarImageCount', 100, 53, 74, 0, 999999);
    LabelAt(G, '星星间距调整:', 8, 83); HintSpinAt(G, '0', 'ShowAniStarImageIncSpacing', 100, 75, 74, -999, 999);
    LabelAt(G, '图片播放间隔:', 8, 105); HintSpinAt(G, '100', 'ShowAniStarImagePlayTime', 100, 97, 74, 0, 9999);
    G := GroupAt(T, '快捷物品栏数字', 4, 90, 257, 42);
    LabelAt(G, 'X偏移:', 8, 18); HintSpinAt(G, '0', 'GoodNumOffsetX', 45, 12, 74, -999, 999);
    LabelAt(G, 'Y偏移:', 135, 18); HintSpinAt(G, '0', 'GoodNumOffsetY', 175, 12, 74, -999, 999);
    G := GroupAt(T, '聊天框物品颜色设置', 4, 135, 257, 43);
    LabelAt(G, '前景色:', 8, 19); HintEditAt(G, '', 'ChatMemoItemFColor', 52, 13, 64);
    LabelAt(G, '背景色:', 135, 19); HintEditAt(G, '', 'ChatMemoItemBColor', 184, 13, 64);
    G := GroupAt(T, '动态显示背包对比图标', 468, 128, 183, 104);
    KeyCheckAt(G, '动态显示背包对比', 'ShowAniBagCompareImg', 8, 15);
    LabelAt(G, '显示开始图片:', 8, 39); HintSpinAt(G, '0', 'ShowAniBagCompareImgIndex', 100, 31, 74, 0, 999999);
    LabelAt(G, '播放图片数量:', 8, 61); HintSpinAt(G, '0', 'ShowAniBagCompareImgCount', 100, 53, 74, 0, 999999);
    LabelAt(G, '图片播放间隔:', 8, 83); HintSpinAt(G, '100', 'ShowAniBagCompareImgPlayTime', 100, 75, 74, 0, 9999);
    G := GroupAt(T, '自定义怪物简装', 270, 65, 183, 61);
    KeyCheckAt(G, '自定义怪物简装', 'CustomActorSimpleShow', 62, 0);
    LabelAt(G, 'Race', 8, 23); HintSpinAt(G, '83', 'SimpleActorRace', 38, 16, 39, 0, 999);
    LabelAt(G, 'RaceImg', 81, 23); HintSpinAt(G, '18', 'SimpleActorRaceImg', 130, 16, 39, 0, 999);
    LabelAt(G, 'Appr', 8, 47); HintSpinAt(G, '27', 'SimpleActorAppr', 38, 40, 39, 0, 999);
    G := GroupAt(T, '自定义宝宝简装', 270, 130, 183, 61);
    KeyCheckAt(G, '自定义宝宝简装', 'CustomBBSimpleShow', 62, 0);
    LabelAt(G, 'Race', 8, 23); HintSpinAt(G, '83', 'SimpleBBRace', 38, 16, 39, 0, 999);
    LabelAt(G, 'RaceImg', 81, 23); HintSpinAt(G, '18', 'SimpleBBRaceImg', 130, 16, 39, 0, 999);
    LabelAt(G, 'Appr', 8, 47); HintSpinAt(G, '27', 'SimpleBBAppr', 38, 40, 39, 0, 999);
    G := GroupAt(T, '已装备图片坐标偏移', 468, 235, 183, 42);
    LabelAt(G, 'X:', 8, 19); HintSpinAt(G, '0', 'EquipmentImgOffsetX', 26, 12, 55, -999, 999);
    LabelAt(G, 'Y:', 93, 19); HintSpinAt(G, '0', 'EquipmentImgOffsetY', 111, 12, 55, -999, 999);
    G2 := GroupAt(T, '人物简装', 4, 194, 448, 71);
    KeyCheckAt(G2, '自定义人物简装', 'CustomHuamSimpleShow', 70, 0);
    LabelAt(G2, '战士衣服Shape:', 8, 23); HintSpinAt(G2, '3', 'SimpleDressShape0', 95, 17, 52, 0, 999);
    LabelAt(G2, '法师衣服Shape:', 156, 23); HintSpinAt(G2, '4', 'SimpleDressShape1', 243, 17, 52, 0, 999);
    LabelAt(G2, '道士衣服Shape:', 304, 23); HintSpinAt(G2, '5', 'SimpleDressShape2', 391, 17, 52, 0, 999);
    LabelAt(G2, '战士武器Shape:', 8, 47); HintSpinAt(G2, '24', 'SimpleWeaponShape0', 95, 41, 52, 0, 999);
    LabelAt(G2, '法师武器Shape:', 156, 47); HintSpinAt(G2, '28', 'SimpleWeaponShape1', 243, 41, 52, 0, 999);
    LabelAt(G2, '道士武器Shape:', 304, 47); HintSpinAt(G2, '25', 'SimpleWeaponShape2', 391, 41, 52, 0, 999);
    KeyCheckAt(T, '显示人物属性时默认打开详细属性', 'DefShowStateWinEx', 8, 272);
    KeyCheckAt(T, '聊天框物品提示不显示关闭', 'ChatSayItemHideClose', 232, 272);
    KeyCheckAt(T, '主界面等级文字使用系统默认字体', 'BottomLevelTextUseSystemDef', 8, 293).Checked := True;
    KeyCheckAt(T, '叠加物品数量复古方式显示', 'OverLapItemNumOldShow', 232, 293);
    KeyCheckAt(T, 'HP百分比显示', 'HPPercentShow', 416, 293);
    KeyCheckAt(T, 'MP百分比显示', 'MPPercentShow', 516, 293);

    G := GroupAt(OtherScroll, '连击版角色发型修正', 4, 0, 184, 88);
    KeyEditAt(G, '玩家X:', 'UserHairOffsetX2', '0', 8, 20, 72);
    KeyEditAt(G, '玩家Y:', 'UserHairOffsetY2', '0', 8, 44, 72);
    G := GroupAt(OtherScroll, '合击版角色发型修正', 194, 0, 184, 88);
    KeyEditAt(G, '玩家X:', 'UserHairOffsetX', '0', 8, 20, 72);
    KeyEditAt(G, '玩家Y:', 'UserHairOffsetY', '0', 8, 44, 72);
    G := GroupAt(OtherScroll, '地面物品极品特效', 388, 0, 263, 142);
    KeyCheckAt(G, '显示特效', 'ShowValueItemEffect', 8, 18);
    KeyEditAt(G, '开始图片:', 'ValueItemEffectIndex', '0', 8, 42, 72);
    KeyEditAt(G, '播放数量:', 'ValueItemEffectCount', '0', 134, 42, 72);
    KeyEditAt(G, '播放间隔:', 'ValueItemEffectPlayTime', '80', 8, 74, 72);
    KeyEditAt(G, 'X偏移:', 'ValueItemEffectOffsetX', '0', 134, 74, 72);
    KeyEditAt(G, 'Y偏移:', 'ValueItemEffectOffsetY', '0', 8, 104, 72);
    KeyCheckAt(G, '混合绘制', 'ValueItemEffectBlendDraw', 134, 104);
    G := GroupAt(OtherScroll, 'NPC对话框文字坐标修正', 4, 94, 184, 66);
    KeyEditAt(G, 'X坐标修正:', 'NPCMsgDlgTextOffsetX', '0', 8, 18, 72);
    KeyEditAt(G, 'Y坐标修正:', 'NPCMsgDlgTextOffsetY', '0', 8, 41, 72);
    G := GroupAt(OtherScroll, '可探索怪物显示图标', 194, 94, 184, 190);
    KeyCheckAt(G, '显示探索图标', 'ShowExploreItemIcon', 8, 17);
    KeyEditAt(G, '图标开始:', 'ExploreItemIconIndex', '0', 8, 41, 72);
    KeyEditAt(G, '播放数量:', 'ExploreItemIconCount', '0', 8, 65, 72);
    KeyEditAt(G, '播放间隔:', 'ExploreItemIconPlayTime', '80', 8, 89, 72);
    KeyEditAt(G, '显示类型:', 'ExploreItemIconShowType', '0', 8, 113, 72);
    KeyEditAt(G, 'X偏移:', 'ExploreItemIconOffstX', '0', 8, 137, 72);
    KeyEditAt(G, 'Y偏移:', 'ExploreItemIconOffstY', '0', 8, 161, 72);
    G := GroupAt(OtherScroll, '拍卖全服公告坐标', 388, 94, 263, 66);
    KeyEditAt(G, 'X坐标:', 'AuctionBroadcastDlgX', '0', 8, 18, 72);
    KeyEditAt(G, 'Y坐标:', 'AuctionBroadcastDlgY', '0', 134, 18, 72);
    G := GroupAt(OtherScroll, '微端状态位置', 4, 164, 184, 102);
    KeyEditAt(G, '水平偏移:', 'UpdateStateDlgOffsetX', '-10', 8, 18, 72);
    KeyEditAt(G, '垂直偏移:', 'UpdateStateDlgOffsetY', '10', 8, 42, 72);
    KeyEditAt(G, '水平对齐:', 'UpdateStateDlgHorzAlign', '1', 8, 66, 72);
    KeyEditAt(G, '垂直对齐:', 'UpdateStateDlgVertAlign', '0', 8, 90, 72);
    G := GroupAt(OtherScroll, '创建角色对话框固定位置', 194, 232, 184, 34);
    KeyCheckAt(G, '固定位置', 'NoMoveNewChrDlg', 8, 8);
    KeyEditAt(OtherScroll, '他人发型X:', 'OtherUserHairOffsetX', '0', 194, 166, 72);
    KeyEditAt(OtherScroll, '他人发型Y:', 'OtherUserHairOffsetY', '0', 194, 190, 72);
    KeyEditAt(OtherScroll, '英雄发型X:', 'HeroUserHairOffsetX', '0', 194, 214, 72);
    KeyEditAt(OtherScroll, '他人连击X:', 'OtherUserHairOffsetX2', '0', 388, 242, 72);
    KeyEditAt(OtherScroll, '英雄连击X:', 'HeroUserHairOffsetX2', '0', 388, 266, 72);
    KeyCheckAt(OtherScroll, '禁止拖出技能图标', 'DisableDrogMagicIcon', 388, 174);
    KeyCheckAt(OtherScroll, '不显示烈火/野蛮冷却间隔', 'DisableShowFireHitCDTime', 388, 198);
    KeyCheckAt(OtherScroll, '保存技能图标位置', 'SaveMagicIconPosition', 388, 222);

    G := GroupAt(OtherScroll, '动态显示英雄背包对比图标', 4, 300, 184, 116);
    KeyCheckAt(G, '启用英雄背包对比', 'ShowAniBagCompareHeroImg', 8, 16);
    KeyEditAt(G, '开始图片:', 'ShowAniBagCompareHeroImgIndex', '0', 8, 40, 72);
    KeyEditAt(G, '播放数量:', 'ShowAniBagCompareHeroImgCount', '0', 8, 64, 72);
    KeyEditAt(G, '播放间隔:', 'ShowAniBagCompareHeroImgPlayTime', '100', 8, 88, 72);

    G := GroupAt(OtherScroll, '提示跳转', 194, 300, 184, 116);
    KeyCheckAt(G, 'BOSS提示跳转', 'HintGotoBoss', 8, 16);
    KeyCheckAt(G, '物品提示跳转', 'HintGotoItem', 8, 38);
    KeyCheckAt(G, '好友提示跳转', 'HintGotoFriend', 8, 60);
    KeyCheckAt(G, '仇人提示跳转', 'HintGotoEnemy', 8, 82);

    TextKeys[0] := 'AttackModeText1'; TextKeys[1] := 'AttackModeText2';
    TextKeys[2] := 'AttackModeText3'; TextKeys[3] := 'AttackModeText4';
    TextKeys[4] := 'AttackModeText5'; TextKeys[5] := 'AttackModeText6';
    TextKeys[6] := 'AttackModeText7'; TextKeys[7] := 'AttackModeText8';
    TextKeys[8] := 'ExpAddHintText'; TextKeys[9] := 'NGExpAddHintText';
    TextKeys[10] := 'ItemHintNoShowZeroValue'; TextKeys[11] := 'OtherHintAlignment';
    TextNames[0] := '全体攻击模式'; TextNames[1] := '和平攻击模式';
    TextNames[2] := '夫妻攻击模式'; TextNames[3] := '师徒攻击模式';
    TextNames[4] := '编组攻击模式'; TextNames[5] := '行会攻击模式';
    TextNames[6] := '红名攻击模式'; TextNames[7] := '国家攻击模式';
    TextNames[8] := '经验增加提示'; TextNames[9] := '内功经验提示';
    TextNames[10] := '装备提示零值'; TextNames[11] := '提示文字对齐';
    for I := 0 to High(TextKeys) do
      KeyEditAt(Text1, TextNames[I] + ':', TextKeys[I], '',
        8 + (I div 6) * 330, 6 + (I mod 6) * 29, 210);

    for I := 0 to 24 do
      PropertyKeys[I] := 'ElementNewPropertyText' + IntToStr(I + 1);
    for I := 0 to 24 do
    begin
      Col := I div 13; Row := I mod 13;
      KeyEditAt(Text2, '属性' + IntToStr(I + 1) + ':', PropertyKeys[I], '',
        8 + Col * 330, 4 + Row * 24, 210);
    end;

    TipKeys[0] := 'ItemHintBaseGroupText'; TipNames[0] := '基础属性标题';
    TipKeys[1] := 'ItemHintFluteCountText'; TipNames[1] := '凹槽数量文字';
    TipKeys[2] := 'ItemHintElementsGroupText'; TipNames[2] := '元素属性标题';
    TipKeys[3] := 'ItemHintTZGroupText'; TipNames[3] := '套装属性标题';
    TipKeys[4] := 'ItemHintFluteStoneText'; TipNames[4] := '镶嵌宝石文字';
    TipKeys[5] := 'ItemHintNoFluteStoneText'; TipNames[5] := '未镶嵌宝石文字';
    TipKeys[6] := 'ItemHintInsuranceText'; TipNames[6] := '投保信息文字';
    TipKeys[7] := 'ItemHintItemFromText'; TipNames[7] := '物品来源文字';
    for I := 0 to High(TipKeys) do
      KeyEditAt(Tips, TipNames[I] + ':', TipKeys[I], '',
        8 + (I div 4) * 330, 10 + (I mod 4) * 42, 210);

    ColorKeys[0] := 'ItemHintBaseGroupColor';
    ColorKeys[1] := 'ItemHintFluteCountColor';
    ColorKeys[2] := 'ItemHintElementsGroupColor';
    ColorKeys[3] := 'ItemHintTZGroupColor';
    ColorKeys[4] := 'ItemHintFluteStoneColor';
    ColorKeys[5] := 'ItemHintNoFluteStoneColor';
    ColorKeys[6] := 'ItemHintInsuranceColor';
    ColorKeys[7] := 'ItemHintItemFromColor';
    ColorNames[0] := '基础属性颜色';
    ColorNames[1] := '凹槽数量颜色';
    ColorNames[2] := '元素属性颜色';
    ColorNames[3] := '套装属性颜色';
    ColorNames[4] := '已镶嵌宝石颜色';
    ColorNames[5] := '未镶嵌宝石颜色';
    ColorNames[6] := '投保信息颜色';
    ColorNames[7] := '物品来源颜色';
    G := GroupAt(Tips, '装备开孔及镶嵌', 4, 178, 648, 124);
    for I := 0 to High(ColorKeys) do
      KeyEditAt(G, ColorNames[I] + ':', ColorKeys[I], '',
        8 + (I div 4) * 320, 10 + (I mod 4) * 27, 190);

    GuiIni := TIniFile.Create(IncludeTrailingPathDelimiter(
      ExtractFilePath(ParamStr(0))) + 'GUI_Config.ini');
    F.FGuiIni := GuiIni;
    try
      RootEdit.Text := GuiIni.ReadString('Setup', 'ImageLibrary', RootEdit.Text);
      for I := 0 to 4 do
      begin
        PakEdits[I].Text := GuiIni.ReadString('NewUI' + IntToStr(I + 1) + '_PAK',
          'FileName', PakEdits[I].Text);
        PasswordEdits[I].Text := GuiIni.ReadString('NewUI' + IntToStr(I + 1) + '_PAK',
          'Password', PasswordEdits[I].Text);
      end;

      Ini := TIniFile.Create(ConfigIniName);
      F.FConfigIni := Ini;
      try
        LoadHintFields(F, Ini);
        F.ShowModal;
        SaveHintFields(F, Ini);
      finally
        Ini.Free;
      end;

      GuiIni.WriteString('Setup', 'ImageLibrary', RootEdit.Text);
      GuiIni.WriteString('Setup', 'ResourcesDir', 'Resources');
      for I := 0 to 4 do
      begin
        GuiIni.WriteString('NewUI' + IntToStr(I + 1) + '_PAK',
          'FileName', PakEdits[I].Text);
        GuiIni.WriteString('NewUI' + IntToStr(I + 1) + '_PAK',
          'Password', PasswordEdits[I].Text);
      end;
    finally
      GuiIni.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure ShowIntegration(AOwner: TComponent);
const
  CheckKeys: array[0..9] of string = ('集成外挂检测列表', '集成服务器列表',
    '集成物品备注', '集成顶行物品备注', '集成内挂捡起物品', '集成套装备注',
    '集成神佑备注', '集成怪物配置', '集成技能配置', '集成NPC配置');
  FileKeys: array[0..9] of string = ('外挂检测列表文件', '服务器列表文件',
    '物品备注文件', '顶行物品备注文件', '内挂捡起物品文件', '套装备注文件',
    '神佑备注文件', '怪物配置文件', '技能配置文件', 'NPC配置文件');
var
  F: TSettingsDialog;
  G: TGroupBox;
  Checks: array[0..9] of TCheckBox;
  Edits: array[0..9] of TEdit;
  Ini: TIniFile;
  I: Integer;
begin
  F := TSettingsDialog.CreateNew(AOwner);
  try
    F.BorderStyle := bsSingle; F.BorderIcons := [biSystemMenu, biMinimize];
    F.Caption := '集成设置'; F.ClientWidth := 456; F.ClientHeight := 337;
    F.Position := poOwnerFormCenter; F.Scaled := False;
    F.Font.Name := '宋体'; F.Font.Size := 9;
    G := GroupAt(F, '登录器集成文件', 8, 8, 435, 67);
    AddPathRow(G, '外挂检测列表', 18, Checks[0], Edits[0]);
    AddPathRow(G, '集成服务器列表', 42, Checks[1], Edits[1]);
    G := GroupAt(F, '客户端集成文件', 8, 81, 435, 215);
    AddPathRow(G, '物品备注信息', 18, Checks[2], Edits[2]);
    AddPathRow(G, '顶行物品备注', 42, Checks[3], Edits[3]);
    AddPathRow(G, '内挂捡起物品', 66, Checks[4], Edits[4]);
    AddPathRow(G, '套装备注信息', 90, Checks[5], Edits[5]);
    AddPathRow(G, '神佑备注信息', 114, Checks[6], Edits[6]);
    AddPathRow(G, '自定义怪物配置', 138, Checks[7], Edits[7]);
    AddPathRow(G, '自定义技能配置', 162, Checks[8], Edits[8]);
    AddPathRow(G, '自定义NPC配置', 186, Checks[9], Edits[9]);
    ButtonAt(F, '确定(&O)', 288, 303, 75, 25, mrOk);
    ButtonAt(F, '取消(&C)', 368, 303, 75, 25, mrCancel);
    Ini := TIniFile.Create(ConfigIniName);
    try
      for I := 0 to 9 do
      begin
        Checks[I].Checked := Ini.ReadBool('Setup', CheckKeys[I], False);
        Edits[I].Text := Ini.ReadString('Setup', FileKeys[I], '');
      end;
      if F.ShowModal = mrOk then
        for I := 0 to 9 do
        begin
          Ini.WriteBool('Setup', CheckKeys[I], Checks[I].Checked);
          Ini.WriteString('Setup', FileKeys[I], Edits[I].Text);
        end;
    finally
      Ini.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure ShowLoginOptions(AOwner: TComponent);
var
  F: TForm;
  P: TPageControl;
  T, Search: TTabSheet;
  G: TGroupBox;
  C: TComboBox;
  DirList, FileList: TListBox;
  EWidth, EHeight, EMinWidth, EMaxWidth, EMinHeight, EMaxHeight,
    EKeyword, ESetup, EServer, EUpgrade: TEdit;
  CWindow, CHardware, CVSync, CLocalList, CMinimize, CCloseAll,
    CDisableUpdate: TCheckBox;
  Ini: TIniFile;
  BasePath: string;
begin
  F := NewDialog(AOwner, '登录器设置', 375, 381);
  try
    P := TPageControl.Create(F); P.Parent := F; P.SetBounds(8, 4, 355, 344); P.TabHeight := 24;
    T := TTabSheet.Create(P); T.PageControl := P; T.Caption := '常规设置';
    Search := TTabSheet.Create(P); Search.PageControl := P; Search.Caption := '客户端搜索条件';
    G := GroupAt(T, '基本设置', 7, 2, 334, 108);
    LabelAt(G, '默认分辨率:', 10, 21); SpinAt(G, '800', 80, 15, 64, 320, 9999, EWidth);
    LabelAt(G, '×', 148, 21); SpinAt(G, '600', 160, 15, 64, 200, 9999, EHeight);
    LabelAt(G, '色彩:', 232, 21); C := TComboBox.Create(G); C.Parent := G; C.SetBounds(264, 15, 60, 21); C.Items.Add('32位色'); C.ItemIndex := 0;
    CWindow := CheckAt(G, '窗口模式', 10, 41, True);
    CHardware := CheckAt(G, '硬件加速', 94, 41, True);
    CVSync := CheckAt(G, '垂直同步(无效)', 183, 41, True);
    CLocalList := CheckAt(G, '服务器列表读取本地配置', 10, 62, True);
    CMinimize := CheckAt(G, '登录后隐藏登录器', 183, 62, True);
    CCloseAll := CheckAt(G, '关闭登录器后关闭所有游戏窗口', 10, 83, True);
    G := GroupAt(T, '限定分辨率', 7, 114, 334, 66);
    LabelAt(G, '宽度范围:', 10, 21); SpinAt(G, '800', 67, 15, 80, 320, 9999, EMinWidth);
    LabelAt(G, '——', 151, 21); SpinAt(G, '1920', 244, 15, 80, 320, 9999, EMaxWidth);
    LabelAt(G, '高度范围:', 10, 44); SpinAt(G, '600', 67, 38, 80, 200, 9999, EMinHeight);
    LabelAt(G, '——', 151, 44); SpinAt(G, '1080', 244, 38, 80, 200, 9999, EMaxHeight);
    G := GroupAt(T, '更新设置', 7, 183, 334, 60);
    LabelAt(G, '服务器列表检测关键字:', 10, 20); EKeyword := EditAt(G, '[Server]', 144, 14, 115);
    LabelAt(G, '区分大小写', 264, 20).Font.Color := clBlue;
    CDisableUpdate := CheckAt(G, '关闭登录器自更新功能', 10, 39);
    G := GroupAt(T, '自定义配置文件区段（含远程配置及集成配置）', 7, 247, 334, 67);
    LabelAt(G, 'Setup:', 10, 23); ESetup := EditAt(G, 'Setup', 60, 17, 106);
    LabelAt(G, 'Server:', 177, 23); EServer := EditAt(G, 'Server', 221, 17, 106);
    LabelAt(G, 'Upgrade:', 10, 47); EUpgrade := EditAt(G, 'Upgrade', 60, 41, 106);
    G := GroupAt(Search, '检测目录', 8, 2, 160, 266);
    DirList := TListBox.Create(G); DirList.Parent := G; DirList.SetBounds(8, 17, 144, 217);
    G := GroupAt(Search, '检测文件', 180, 2, 160, 266);
    FileList := TListBox.Create(G); FileList.Parent := G; FileList.SetBounds(8, 17, 144, 217);
    ButtonAt(F, '确定(&O)', 223, 353, 67, 25, mrOk);
    ButtonAt(F, '取消(&C)', 297, 353, 66, 25, mrCancel);
    Ini := TIniFile.Create(ConfigIniName);
    try
      EWidth.Text := Ini.ReadString('Setup', 'ScreenWidth', EWidth.Text);
      EHeight.Text := Ini.ReadString('Setup', 'ScreenHeight', EHeight.Text);
      C.ItemIndex := Ini.ReadInteger('Setup', 'BitCount', C.ItemIndex);
      if C.ItemIndex < 0 then C.ItemIndex := 0;
      CWindow.Checked := Ini.ReadBool('Setup', 'WindowMode', CWindow.Checked);
      CHardware.Checked := Ini.ReadBool('Setup', 'Hardware', CHardware.Checked);
      CVSync.Checked := Ini.ReadBool('Setup', 'VSync', CVSync.Checked);
      CLocalList.Checked := Ini.ReadBool('Setup', 'ReadLocalSvrList', CLocalList.Checked);
      CMinimize.Checked := Ini.ReadBool('Setup', 'GameLoginMinimize', CMinimize.Checked);
      CCloseAll.Checked := Ini.ReadBool('Setup', 'LoginCloseAllGame', CCloseAll.Checked);
      EMinWidth.Text := Ini.ReadString('Setup', 'MinPelsWidth', EMinWidth.Text);
      EMaxWidth.Text := Ini.ReadString('Setup', 'MaxPelsWidth', EMaxWidth.Text);
      EMinHeight.Text := Ini.ReadString('Setup', 'MinPelsHeight', EMinHeight.Text);
      EMaxHeight.Text := Ini.ReadString('Setup', 'MaxPelsHeight', EMaxHeight.Text);
      EKeyword.Text := Ini.ReadString('Setup', 'ServerListCheckKey', EKeyword.Text);
      CDisableUpdate.Checked := Ini.ReadBool('Setup', 'DisableUpdateGameLogin', CDisableUpdate.Checked);
      ESetup.Text := Ini.ReadString('Setup', 'IniSectionSetup', ESetup.Text);
      EServer.Text := Ini.ReadString('Setup', 'IniSectionServer', EServer.Text);
      EUpgrade.Text := Ini.ReadString('Setup', 'IniSectionUpgrade', EUpgrade.Text);
      BasePath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
      if FileExists(BasePath + 'SearchMirDirectory.txt') then
        DirList.Items.LoadFromFile(BasePath + 'SearchMirDirectory.txt');
      if FileExists(BasePath + 'SearchMirFileName.txt') then
        FileList.Items.LoadFromFile(BasePath + 'SearchMirFileName.txt');
      if F.ShowModal = mrOk then
      begin
        Ini.WriteString('Setup', 'ScreenWidth', EWidth.Text);
        Ini.WriteString('Setup', 'ScreenHeight', EHeight.Text);
        Ini.WriteInteger('Setup', 'BitCount', C.ItemIndex);
        Ini.WriteBool('Setup', 'WindowMode', CWindow.Checked);
        Ini.WriteBool('Setup', 'Hardware', CHardware.Checked);
        Ini.WriteBool('Setup', 'VSync', CVSync.Checked);
        Ini.WriteBool('Setup', 'ReadLocalSvrList', CLocalList.Checked);
        Ini.WriteBool('Setup', 'GameLoginMinimize', CMinimize.Checked);
        Ini.WriteBool('Setup', 'LoginCloseAllGame', CCloseAll.Checked);
        Ini.WriteString('Setup', 'MinPelsWidth', EMinWidth.Text);
        Ini.WriteString('Setup', 'MaxPelsWidth', EMaxWidth.Text);
        Ini.WriteString('Setup', 'MinPelsHeight', EMinHeight.Text);
        Ini.WriteString('Setup', 'MaxPelsHeight', EMaxHeight.Text);
        Ini.WriteString('Setup', 'ServerListCheckKey', EKeyword.Text);
        Ini.WriteBool('Setup', 'DisableUpdateGameLogin', CDisableUpdate.Checked);
        Ini.WriteString('Setup', 'IniSectionSetup', ESetup.Text);
        Ini.WriteString('Setup', 'IniSectionServer', EServer.Text);
        Ini.WriteString('Setup', 'IniSectionUpgrade', EUpgrade.Text);
        DirList.Items.SaveToFile(BasePath + 'SearchMirDirectory.txt');
        FileList.Items.SaveToFile(BasePath + 'SearchMirFileName.txt');
      end;
    finally
      Ini.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure ShowSkinEditor(AOwner: TComponent);
const
  ObjectNames: array[0..22] of string = ('最小化按钮','关闭按钮','服务器树形列表','服务器下拉列表','分辨率','窗口模式','状态文字标题','状态文字','当前进度标题','当前进度','总进度标题','总进度','公告栏','开始运行','游戏设置','官网主页','服务器','添加游戏','注册帐号','修改密码','找回密码','退出游戏','取消更新');
var
  F: TSkinEditorForm;
  LeftTop, LeftBottom, Header, PreviewHost: TPanel;
  Lb: TListBox;
  P: TPageControl;
  T: TTabSheet;
  Scroll: TScrollBox;
  Img: TImage;
  R: TResourceStream;
  Grid: TStringGrid;
  I: Integer;
begin
  F := TSkinEditorForm.CreateNew(AOwner);
  F.Skin := TSkinDocument.Create;
  F.BorderStyle := bsSingle;
  F.BorderIcons := [biSystemMenu, biMinimize];
  F.Caption := 'FrmLoginSkin';
  F.ClientWidth := 1194;
  F.ClientHeight := 800;
  F.Position := poOwnerFormCenter;
  F.Scaled := False;
  F.Font.Name := '宋体';
  F.Font.Size := 9;
  F.Color := clBtnFace;
  try
    LeftTop := TPanel.Create(F); LeftTop.Parent := F; LeftTop.SetBounds(0, 0, 200, 360); LeftTop.BevelOuter := bvNone;
    ButtonAt(LeftTop, '打开', 20, 8, 68, 25).OnClick := F.OpenSkin;
    ButtonAt(LeftTop, '另存为...', 108, 8, 70, 25).OnClick := F.SaveSkinAs;
    Header := TPanel.Create(LeftTop); Header.Parent := LeftTop; Header.SetBounds(0, 41, 200, 24); Header.Caption := '对象浏览器'; Header.Alignment := taLeftJustify; Header.BevelOuter := bvLowered; Header.Font.Style := [fsBold];
    Lb := TListBox.Create(LeftTop); Lb.Parent := LeftTop; Lb.SetBounds(4, 64, 194, 294);
    for I := Low(ObjectNames) to High(ObjectNames) do Lb.Items.Add(ObjectNames[I]);
    F.ObjectList := Lb;
    Lb.OnClick := F.ObjectSelected;

    LeftBottom := TPanel.Create(F); LeftBottom.Parent := F; LeftBottom.SetBounds(0, 365, 200, 425); LeftBottom.BevelOuter := bvNone;
    Header := TPanel.Create(LeftBottom); Header.Parent := LeftBottom; Header.SetBounds(0, 0, 200, 24); Header.Caption := ' 属性编辑器'; Header.Alignment := taLeftJustify; Header.BevelOuter := bvLowered; Header.Font.Style := [fsBold];
    Grid := TStringGrid.Create(LeftBottom); Grid.Parent := LeftBottom; Grid.SetBounds(0, 24, 200, 401); Grid.ColCount := 2; Grid.FixedCols := 0; Grid.RowCount := 16; Grid.DefaultRowHeight := 20; Grid.ColWidths[0] := 88; Grid.ColWidths[1] := 108;
    Grid.Options := Grid.Options + [goEditing];
    Grid.Cells[0,0] := '属性'; Grid.Cells[1,0] := '值';
    Grid.OnSetEditText := F.PropertyChanged;
    F.PropertyGrid := Grid;
    Lb.ItemIndex := 0;
    F.ObjectSelected(Lb);

    P := TPageControl.Create(F); P.Parent := F; P.SetBounds(205, 0, 982, 790); P.TabHeight := 24;
    T := TTabSheet.Create(P); T.PageControl := P; T.Caption := '登录器主界面';
    Scroll := TScrollBox.Create(T); Scroll.Parent := T; Scroll.Align := alClient; Scroll.HorzScrollBar.Range := 840; Scroll.VertScrollBar.Range := 580;
    PreviewHost := TPanel.Create(Scroll); PreviewHost.Parent := Scroll; PreviewHost.SetBounds(4, 4, 831, 571); PreviewHost.BevelOuter := bvNone; PreviewHost.Caption := '';
    Img := TImage.Create(PreviewHost); Img.Parent := PreviewHost; Img.Align := alClient; Img.Stretch := False;
    R := TResourceStream.Create(HInstance, 'SKINPREVIEW', RT_RCDATA);
    try
      Img.Picture.Bitmap.LoadFromStream(R);
    finally
      R.Free;
    end;
    F.Preview := Img;
    F.FileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'loginskin';
    if FileExists(F.FileName) then
    begin
      try
        F.Skin.LoadFromFile(F.FileName);
        F.Skin.LoadPreview(F.Preview.Picture.Bitmap);
        F.ObjectSelected(Lb);
      except
        // Keep the editor usable when a custom skin is absent or malformed.
      end;
    end;
    F.BuildPreview;
    F.ShowModal;
  finally
    F.Skin.Free;
    F.Free;
  end;
end;

procedure ShowEncryptDialog(AOwner: TComponent);
var
  D: TOpenDialog;
begin
  D := TOpenDialog.Create(AOwner);
  try
    D.Title := '打开';
    D.Filter := '文本文件 (*.txt)|*.txt';
    D.Options := [ofFileMustExist, ofPathMustExist];
    if not D.Execute then Exit;
    EncryptListFile(D.FileName);
  finally
    D.Free;
  end;
end;

procedure ShowGxxDialog(AKind: Integer; AOwner: TComponent);
begin
  case AKind of
    1: ShowPluginDialog(AOwner);
    2: ShowEncryptDialog(AOwner);
    3: ShowReadRules(AOwner);
    4: ShowInnerSettings(AOwner);
    5: ShowClientOptions(AOwner);
    6: ShowUiSettings(AOwner);
    7: ShowIntegration(AOwner);
    8: ShowLoginOptions(AOwner);
    9: ShowSkinEditor(AOwner);
  end;
end;

end.
