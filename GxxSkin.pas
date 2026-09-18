unit GxxSkin;

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics;

type
  TSkinObject = record
    Left, Top, Width, Height: Integer;
    FontName: string;
    FontSize: Integer;
    Visible: Boolean;
    Enabled: Boolean;
  end;

  TSkinDocument = class
  private
    FBytes: TBytes;
    FObjectCount: Integer;
    function GetObject(Index: Integer): TSkinObject;
    procedure SetObject(Index: Integer; const Value: TSkinObject);
    function RecordOffset(Index: Integer): Integer;
    procedure CheckIndex(Index: Integer);
  public
    constructor Create;
    procedure Clear;
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    function IsLoaded: Boolean;
    function LoadPreview(ABitmap: TBitmap): Boolean;
    property ObjectCount: Integer read FObjectCount;
    property Objects[Index: Integer]: TSkinObject read GetObject write SetObject;
  end;

implementation

const
  // The first byte at $1C is the skin's global flag; the first control
  // record begins at $1D.  Every control record is a fixed 55-byte block.
  SkinHeaderSize = $1D;
  SkinRecordSize = $37;
  SkinRecordTotal = 30; // records 0..29 are controls; record 30 stores colors
  SkinPreviewOffset = $717;

function ReadInt32(const B: TBytes; Offset: Integer): Integer;
begin
  if (Offset < 0) or (Offset + SizeOf(Integer) > Length(B)) then
    Exit(0);
  Move(B[Offset], Result, SizeOf(Result));
end;

procedure WriteInt32(var B: TBytes; Offset, Value: Integer);
begin
  if (Offset < 0) or (Offset + SizeOf(Integer) > Length(B)) then Exit;
  Move(Value, B[Offset], SizeOf(Value));
end;

constructor TSkinDocument.Create;
begin
  inherited Create;
  Clear;
end;

procedure TSkinDocument.Clear;
begin
  SetLength(FBytes, 0);
  FObjectCount := 0;
end;

function TSkinDocument.IsLoaded: Boolean;
begin
  Result := Length(FBytes) >= SkinHeaderSize + SkinRecordSize;
end;

procedure TSkinDocument.LoadFromFile(const AFileName: string);
var
  S: TFileStream;
begin
  Clear;
  S := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(FBytes, S.Size);
    if S.Size > 0 then S.ReadBuffer(FBytes[0], S.Size);
  finally
    S.Free;
  end;
  if not IsLoaded then
    raise EStreamError.Create('无效的登录器皮肤文件。');
  FObjectCount := SkinRecordTotal;
end;

procedure TSkinDocument.SaveToFile(const AFileName: string);
var
  S: TFileStream;
begin
  if not IsLoaded then
    raise EInvalidOp.Create('尚未打开登录器皮肤。');
  S := TFileStream.Create(AFileName, fmCreate);
  try
    S.WriteBuffer(FBytes[0], Length(FBytes));
  finally
    S.Free;
  end;
end;

procedure TSkinDocument.CheckIndex(Index: Integer);
begin
  if (Index < 0) or (Index >= FObjectCount) then
    raise EArgumentOutOfRangeException.Create('皮肤对象索引超出范围。');
end;

function TSkinDocument.RecordOffset(Index: Integer): Integer;
begin
  CheckIndex(Index);
  Result := SkinHeaderSize + Index * SkinRecordSize;
end;

function TSkinDocument.GetObject(Index: Integer): TSkinObject;
var
  O, L, N, I: Integer;
  Len: Byte;
  Raw: TBytes;
begin
  O := RecordOffset(Index);
  Result.Left := 0;
  Result.Top := 0;
  Result.Width := 0;
  Result.Height := 0;
  Result.FontName := '';
  Result.FontSize := 0;
  Result.Visible := False;
  Result.Enabled := True;
  Result.Left := ReadInt32(FBytes, O);
  Result.Top := ReadInt32(FBytes, O + 4);
  Result.Width := ReadInt32(FBytes, O + 8);
  Result.Height := ReadInt32(FBytes, O + 12);
  Len := 0;
  if O + 16 < Length(FBytes) then Len := FBytes[O + 16];
  L := Len;
  // The legacy record reserves exactly four bytes for the GBK font name;
  // the following byte is a separator and the next dword is the font size.
  if L > 4 then L := 4;
  SetLength(Raw, L);
  for I := 0 to L - 1 do Raw[I] := FBytes[O + 17 + I];
  if L > 0 then
    Result.FontName := TEncoding.GetEncoding(936).GetString(Raw)
  else
    Result.FontName := '';
  N := ReadInt32(FBytes, O + 22);
  Result.FontSize := N;
  // The original stream stores these two flags as bytes near the end of each
  // fixed-size control record.  Keep them exposed for editing while leaving
  // all unknown/private bytes untouched.
  Result.Visible := (O + 46 < Length(FBytes)) and (FBytes[O + 46] <> 0);
  // The stock format has no independent enabled flag for these controls;
  // expose it as an editor convenience without changing unknown bytes.
  Result.Enabled := True;
end;

procedure TSkinDocument.SetObject(Index: Integer; const Value: TSkinObject);
var
  O, I, L: Integer;
  A: AnsiString;
begin
  O := RecordOffset(Index);
  WriteInt32(FBytes, O, Value.Left);
  WriteInt32(FBytes, O + 4, Value.Top);
  WriteInt32(FBytes, O + 8, Value.Width);
  WriteInt32(FBytes, O + 12, Value.Height);
  if O + 16 < Length(FBytes) then
  begin
    A := AnsiString(Value.FontName);
    L := Length(A);
    if L > 4 then L := 4;
    FBytes[O + 16] := Byte(L);
    for I := 0 to 3 do
      if O + 17 + I < Length(FBytes) then
        FBytes[O + 17 + I] := 0;
    for I := 0 to L - 1 do
      FBytes[O + 17 + I] := Byte(A[I + 1]);
  end;
  WriteInt32(FBytes, O + 22, Value.FontSize);
  if O + 46 < Length(FBytes) then
    if Value.Visible then FBytes[O + 46] := 1 else FBytes[O + 46] := 0;
end;

function TSkinDocument.LoadPreview(ABitmap: TBitmap): Boolean;
var
  S: TMemoryStream;
  Size: Cardinal;
begin
  Result := False;
  if (ABitmap = nil) or (Length(FBytes) < SkinPreviewOffset + 6) then Exit;
  if (FBytes[SkinPreviewOffset] <> Ord('B')) or
     (FBytes[SkinPreviewOffset + 1] <> Ord('M')) then Exit;
  Move(FBytes[SkinPreviewOffset + 2], Size, SizeOf(Size));
  if (Size < 54) or (Size > Cardinal(Length(FBytes) - SkinPreviewOffset)) then Exit;
  S := TMemoryStream.Create;
  try
    S.WriteBuffer(FBytes[SkinPreviewOffset], Size);
    S.Position := 0;
    try
      ABitmap.LoadFromStream(S);
      Result := True;
    except
      Result := False;
    end;
  finally
    S.Free;
  end;
end;

end.
