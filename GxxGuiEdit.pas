unit GxxGuiEdit;

interface

uses
  Winapi.Windows, Winapi.ActiveX, System.SysUtils, System.Classes,
  System.UITypes, Vcl.Forms, Vcl.Dialogs;

type
  TGuiEditorKind = (gekMain, gekConfig, gekState, gekJsy);

function OpenGuiEditor(AOwner: TCustomForm; AKind: TGuiEditorKind;
  AClassic: Boolean): Boolean;
function SaveGuiEditorFile(AOwner: TCustomForm; AKind: TGuiEditorKind;
  AClassic: Boolean): Boolean;

implementation

type
  TShowDlg = procedure(const Data: IStream); stdcall;
  TShowDlgEx = procedure(const Data: IStream; Kind: Integer); stdcall;
  TSaveGUIToStream = procedure(const Data: IStream); stdcall;
  TSetApplicationMainFormHandle = procedure(Value: THandle); stdcall;

var
  GuiEditModule: HMODULE = 0;
  ShowDlgProc: TShowDlg = nil;
  ShowDlgExProc: TShowDlgEx = nil;
  SaveGUIToStreamProc: TSaveGUIToStream = nil;
  SetApplicationMainFormHandleProc: TSetApplicationMainFormHandle = nil;

function EnsureGuiEditLoaded: Boolean;
var
  FileName: string;
begin
  if GuiEditModule <> 0 then Exit(True);
  FileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'GuiEdit.dll';
  GuiEditModule := LoadLibrary(PChar(FileName));
  if GuiEditModule = 0 then Exit(False);
  @ShowDlgProc := GetProcAddress(GuiEditModule, 'ShowDlg');
  @ShowDlgExProc := GetProcAddress(GuiEditModule, 'ShowDlgEx');
  @SaveGUIToStreamProc := GetProcAddress(GuiEditModule, 'SaveGUIToStream');
  @SetApplicationMainFormHandleProc := GetProcAddress(GuiEditModule,
    'SetApplicationMainFormHandle');
  Result := Assigned(ShowDlgProc) and Assigned(ShowDlgExProc) and
    Assigned(SaveGUIToStreamProc) and
    Assigned(SetApplicationMainFormHandleProc);
end;

function EditorFileName(AKind: TGuiEditorKind; AClassic: Boolean): string;
const
  BaseNames: array[TGuiEditorKind] of string =
    ('Mir', 'MirConfigDlg', 'StateWin', 'JSY');
begin
  Result := BaseNames[AKind];
  if AClassic and (AKind <> gekJsy) then Result := Result + '205';
  if AKind = gekJsy then Result := Result + '.ini'
  else Result := Result + '.ui';
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'NewUI' + PathDelim + Result;
end;

function OpenGuiEditor(AOwner: TCustomForm; AKind: TGuiEditorKind;
  AClassic: Boolean): Boolean;
var
  FileName: string;
  FileStream: TFileStream;
  Stream: IStream;
begin
  Result := False;
  FileName := EditorFileName(AKind, AClassic);
  if not FileExists(FileName) then
  begin
    MessageDlg(#$627E#$4E0D#$5230#$754C#$9762#$6587#$4EF6#$FF1A +
      sLineBreak + FileName, mtError, [mbOK], 0);
    Exit;
  end;
  if not EnsureGuiEditLoaded then
  begin
    MessageDlg(#$627E#$4E0D#$5230 + ' GuiEdit.dll' + #$FF0C#$65E0#$6CD5#$6253#$5F00#$754C#$9762#$7F16#$8F91#$5668#$3002,
      mtError, [mbOK], 0);
    Exit;
  end;

  SetApplicationMainFormHandleProc(AOwner.Handle);
  FileStream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareDenyNone);
  Stream := TStreamAdapter.Create(FileStream, soOwned);
  try
    if AKind = gekJsy then
      ShowDlgExProc(Stream, Ord(AKind))
    else
      ShowDlgProc(Stream);
    Result := True;
  finally
    Stream := nil;
  end;
end;

function SaveGuiEditorFile(AOwner: TCustomForm; AKind: TGuiEditorKind;
  AClassic: Boolean): Boolean;
var
  FileName: string;
  FileStream: TFileStream;
  Stream: IStream;
begin
  Result := False;
  FileName := EditorFileName(AKind, AClassic);
  if not FileExists(FileName) then Exit;
  if not EnsureGuiEditLoaded then Exit;
  SetApplicationMainFormHandleProc(AOwner.Handle);
  FileStream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareDenyNone);
  Stream := TStreamAdapter.Create(FileStream, soOwned);
  try
    SaveGUIToStreamProc(Stream);
    Result := True;
  finally
    Stream := nil;
  end;
end;

end.
