program GuiProbe;

{$APPTYPE GUI}

uses
  Winapi.Windows, Winapi.ActiveX, System.SysUtils, System.Classes, Vcl.Forms;

procedure ShowDlg(const Data: IStream); stdcall; external 'GuiEdit.dll' name 'ShowDlg';
procedure ShowDlgEx(const Data: IStream; Kind: Integer); stdcall; external 'GuiEdit.dll' name 'ShowDlgEx';
procedure SetApplicationMainFormHandle(Value: THandle); stdcall; external 'GuiEdit.dll' name 'SetApplicationMainFormHandle';

var
  HostForm: TForm;
  FileStream: TFileStream;
  Stream: IStream;
begin
  CoInitialize(nil);
  Application.Initialize;
  HostForm := TForm.Create(nil);
  HostForm.Caption := 'GuiProbeHost';
  HostForm.SetBounds(100, 100, 100, 100);
  HostForm.Show;
  SetApplicationMainFormHandle(HostForm.Handle);
  if ParamCount = 0 then
    ShowDlg(nil)
  else
  begin
    FileStream := TFileStream.Create(ParamStr(1), fmOpenReadWrite or fmShareDenyNone);
    Stream := TStreamAdapter.Create(FileStream, soOwned);
    if ParamCount > 1 then
      ShowDlgEx(Stream, StrToIntDef(ParamStr(2), 0))
    else
      ShowDlg(Stream);
    Stream := nil;
  end;
  HostForm.Free;
  CoUninitialize;
end.
