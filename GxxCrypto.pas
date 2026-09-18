unit GxxCrypto;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes;

type
  TClientVersion = (cv176, cv185, cvHero, cvSerial, cvMirSequel, cvMirNewUI205);

  TLoginClientParam = packed record
    Handle: THandle;
    sGameLoginFileName: string[255];
    sServerCaption: string[100];
    sServeraddr: string[100];
    nServerPort: Integer;
    sUpdateAddr: string[100];
    nUpdatePort: Integer;
    sUpdatePassWord: string[100];
    nClientCrc: Cardinal;
    nLoginCrc: Cardinal;
    sDomainName: array[0..999] of Char;
    sHomePage: string[255];
    btMaxClientCount: Byte;
    wScreenWidth: Word;
    wScreenHeight: Word;
    btBitCount: Byte;
    boWindowMode: Boolean;
    boVSync: Boolean;
    boHardware: Boolean;
    ClientVersion: TClientVersion;
    sSemaphoreName: string[40];
    sMachineID: string[32];
    sClientDataFile: string[255];
    ConfigUrlMD5: array[0..15] of Byte;
    sPromotionFlag: string[40];
  end;

function RandomClientKey: Integer;
function ClientKeyText(AKey: Integer): AnsiString;
function EncryptClientParam(const Param: TLoginClientParam; AKey: Integer): AnsiString;
function EncryptLegacyString(const Value: AnsiString): AnsiString;
function EncryptLegacyStringWithKey(const Value, CipherKey: AnsiString): AnsiString;
function DecryptLegacyStringWithKey(const Value, CipherKey: AnsiString): AnsiString;
function EncryptPakPassword(const Value: AnsiString): AnsiString;
function EncryptListLine(const Value: AnsiString): AnsiString;
procedure EncryptListFile(const AFileName: string);
function EncryptClientKey(const Value: AnsiString): AnsiString;
function DecryptClientKey(const Value: AnsiString): AnsiString;
function DecryptClientKeyWithKey(const Value, CipherKey: AnsiString): AnsiString;
function DecryptClientParam(const Value: AnsiString; AKey: Integer;
  out Param: TLoginClientParam): Boolean;

implementation

uses
  UnitDes, DesUtils, ZlibEx;

function Encode6Bit(const Value: AnsiString): AnsiString;
var
  I, OutPos, Remainder: Integer;
  A, B, C: Byte;
begin
  if Value = '' then
    Exit('');
  SetLength(Result, (Length(Value) * 4 + 2) div 3);
  I := 1;
  OutPos := 1;
  while I + 2 <= Length(Value) do
  begin
    A := Ord(Value[I]); B := Ord(Value[I + 1]); C := Ord(Value[I + 2]);
    Result[OutPos] := AnsiChar(((A shr 2) and $3F) + $3C);
    Result[OutPos + 1] := AnsiChar((((A shl 4) or (B shr 4)) and $3F) + $3C);
    Result[OutPos + 2] := AnsiChar((((B shl 2) or (C shr 6)) and $3F) + $3C);
    Result[OutPos + 3] := AnsiChar((C and $3F) + $3C);
    Inc(I, 3);
    Inc(OutPos, 4);
  end;
  Remainder := Length(Value) - I + 1;
  if Remainder = 1 then
  begin
    A := Ord(Value[I]);
    Result[OutPos] := AnsiChar(((A shr 2) and $3F) + $3C);
    Result[OutPos + 1] := AnsiChar((((A and 3) shl 4) and $3F) + $3C);
  end
  else if Remainder = 2 then
  begin
    A := Ord(Value[I]); B := Ord(Value[I + 1]);
    Result[OutPos] := AnsiChar(((A shr 2) and $3F) + $3C);
    Result[OutPos + 1] := AnsiChar((((A shl 4) or (B shr 4)) and $3F) + $3C);
    Result[OutPos + 2] := AnsiChar(((B shl 2) and $3F) + $3C);
  end;
end;

function Base64Encode(const Value: AnsiString): AnsiString;
const
  Alphabet: AnsiString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var
  I, O: Integer;
  A, B, C: Byte;
begin
  if Value = '' then Exit('');
  SetLength(Result, ((Length(Value) + 2) div 3) * 4);
  I := 1; O := 1;
  while I <= Length(Value) do
  begin
    A := Ord(Value[I]);
    if I + 1 <= Length(Value) then B := Ord(Value[I + 1]) else B := 0;
    if I + 2 <= Length(Value) then C := Ord(Value[I + 2]) else C := 0;
    Result[O] := Alphabet[(A shr 2) + 1];
    Result[O + 1] := Alphabet[((A and 3) shl 4 or (B shr 4)) + 1];
    if I + 1 <= Length(Value) then Result[O + 2] := Alphabet[((B and $F) shl 2 or (C shr 6)) + 1] else Result[O + 2] := '=';
    if I + 2 <= Length(Value) then Result[O + 3] := Alphabet[(C and $3F) + 1] else Result[O + 3] := '=';
    Inc(I, 3); Inc(O, 4);
  end;
end;

function Decode6Bit(const Value: AnsiString): AnsiString;
var
  I, O, Count: Integer;
  A, B, C, D: Byte;
begin
  if Value = '' then Exit('');
  SetLength(Result, (Length(Value) * 3) div 4);
  I := 1; O := 1; Count := 0;
  while I <= Length(Value) do
  begin
    A := Ord(Value[I]) - $3C;
    if I + 1 <= Length(Value) then B := Ord(Value[I + 1]) - $3C else B := 0;
    if I + 2 <= Length(Value) then C := Ord(Value[I + 2]) - $3C else C := 0;
    if I + 3 <= Length(Value) then D := Ord(Value[I + 3]) - $3C else D := 0;
    Result[O] := AnsiChar((A shl 2) or (B shr 4)); Inc(O); Inc(Count);
    if I + 2 <= Length(Value) then begin Result[O] := AnsiChar((B shl 4) or (C shr 2)); Inc(O); Inc(Count); end;
    if I + 3 <= Length(Value) then begin Result[O] := AnsiChar((C shl 6) or D); Inc(O); Inc(Count); end;
    Inc(I, 4);
  end;
  SetLength(Result, Count);
end;

function Base64Decode(const Value: AnsiString): AnsiString;
  function Code(C: AnsiChar): Integer;
  begin
    if (C >= 'A') and (C <= 'Z') then Result := Ord(C) - Ord('A')
    else if (C >= 'a') and (C <= 'z') then Result := Ord(C) - Ord('a') + 26
    else if (C >= '0') and (C <= '9') then Result := Ord(C) - Ord('0') + 52
    else if C = '+' then Result := 62
    else if C = '/' then Result := 63
    else Result := 0;
  end;
var
  I, O, Count, A, B, C, D: Integer;
begin
  if Value = '' then Exit('');
  SetLength(Result, (Length(Value) div 4) * 3);
  I := 1; O := 1; Count := 0;
  while I + 3 <= Length(Value) do
  begin
    A := Code(Value[I]); B := Code(Value[I + 1]);
    C := Code(Value[I + 2]); D := Code(Value[I + 3]);
    Result[O] := AnsiChar((A shl 2) or (B shr 4)); Inc(O); Inc(Count);
    if Value[I + 2] <> '=' then begin Result[O] := AnsiChar((B shl 4) or (C shr 2)); Inc(O); Inc(Count); end;
    if Value[I + 3] <> '=' then begin Result[O] := AnsiChar((C shl 6) or D); Inc(O); Inc(Count); end;
    Inc(I, 4);
  end;
  SetLength(Result, Count);
end;

function RandomClientKey: Integer;
begin
  Result := MakeLong(MakeWord(Random(58), Random(58)), MakeWord(Random(58), Random(58)));
end;

function ClientKeyText(AKey: Integer): AnsiString;
const
  Alphabet: array[0..58] of Byte = (65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80,
    81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
    109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 60, 61, 62, 64, 91, 92, 93);
begin
  SetLength(Result, 4);
  Result[1] := AnsiChar(Alphabet[Byte(AKey)]);
  Result[2] := AnsiChar(Alphabet[Byte(AKey shr 8)]);
  Result[3] := AnsiChar(Alphabet[Byte(AKey shr 16)]);
  Result[4] := AnsiChar(Alphabet[Byte(AKey shr 24)]);
end;

function EncryptClientParam(const Param: TLoginClientParam; AKey: Integer): AnsiString;
var
  Compressed, Encrypted: AnsiString;
  CompressedBuf: Pointer;
  CompressedSize: Integer;
  Key: AnsiString;
begin
  CompressedBuf := nil;
  CompressedSize := 0;
  CompressBuf(@Param, SizeOf(Param), CompressedBuf, CompressedSize);
  try
    SetString(Compressed, PAnsiChar(CompressedBuf), CompressedSize);
  finally
    FreeMem(CompressedBuf);
  end;
  SetLength(Encrypted, Length(Compressed));
  Key := ClientKeyText(AKey);
  EncryptDes(Compressed[1], Encrypted[1], Length(Compressed), Key);
  Result := Encode6Bit(Base64Encode(Encrypted));
end;

function EncryptLegacyString(const Value: AnsiString): AnsiString;
begin
  Result := EncryptLegacyStringWithKey(Value, '-1064573647');
end;

function EncryptLegacyStringWithKey(const Value, CipherKey: AnsiString): AnsiString;
var
  Encrypted: AnsiString;
begin
  if Value = '' then Exit('');
  SetLength(Encrypted, Length(Value));
  EncryptDes(Value[1], Encrypted[1], Length(Value), CipherKey);
  Result := Encode6Bit(Base64Encode(Encrypted));
end;

function DecryptLegacyStringWithKey(const Value,
  CipherKey: AnsiString): AnsiString;
begin
  Result := Base64Decode(Decode6Bit(Value));
  if Result <> '' then
    DecryptDes(Result[1], Result[1], Length(Result), CipherKey);
end;

function EncryptPakPassword(const Value: AnsiString): AnsiString;
type
  TPakPasswordData = packed record
    KeyData: array[0..31] of LongWord;
    Chain: array[0..19] of Byte;
    KeyDataLz: array[0..31] of LongWord;
    ChainLz: array[0..19] of Byte;
  end;
var
  PasswordData: TPakPasswordData;
  RawData: AnsiString;
begin
  if Value = '' then Exit('');
  FillChar(PasswordData, SizeOf(PasswordData), 0);
  GetKeyDataPak(Value, @PasswordData.Chain, @PasswordData.KeyData);
  GetKeyData(Value, @PasswordData.ChainLz, @PasswordData.KeyDataLz);
  EncryptDes(PasswordData, PasswordData, SizeOf(PasswordData),
    #10#11#2#9#2#1#12#32#1#9#5#230#211#190);
  SetString(RawData, PAnsiChar(@PasswordData), SizeOf(PasswordData));
  Result := Encode6Bit(RawData);
end;

function EncryptListLine(const Value: AnsiString): AnsiString;
var
  Encrypted, Encoded: AnsiString;
  I: Integer;
const
  Hex: AnsiString = '0123456789ABCDEF';
begin
  if Value = '' then Exit('');
  SetLength(Encrypted, Length(Value));
  EncryptDes(Value[1], Encrypted[1], Length(Value), '3230393649');
  Encoded := Base64Encode(Encrypted);
  SetLength(Result, Length(Encoded) * 2);
  for I := 1 to Length(Encoded) do
  begin
    Result[I * 2 - 1] := Hex[(Byte(Encoded[I]) shr 4) + 1];
    Result[I * 2] := Hex[(Byte(Encoded[I]) and $0F) + 1];
  end;
end;

procedure EncryptListFile(const AFileName: string);
var
  Input, Output: TStringList;
  I: Integer;
  Line: AnsiString;
begin
  Input := TStringList.Create;
  Output := TStringList.Create;
  try
    Input.LoadFromFile(AFileName, TEncoding.ANSI);
    Output.Add(';++++++++++++++++++++');
    for I := 0 to Input.Count - 1 do
    begin
      Line := AnsiString(Input[I]);
      if Line = '' then Output.Add('')
      else Output.Add(string(EncryptListLine(Line)));
    end;
    Output.SaveToFile(AFileName, TEncoding.ANSI);
  finally
    Output.Free;
    Input.Free;
  end;
end;

function EncryptClientKey(const Value: AnsiString): AnsiString;
var
  Encrypted: AnsiString;
begin
  if Value = '' then Exit('');
  Encrypted := Value;
  EncryptDes_New(Encrypted[1], Encrypted[1], Length(Encrypted), '-1064573647');
  Result := Encode6Bit(Base64Encode(Encrypted));
end;

function DecryptClientKey(const Value: AnsiString): AnsiString;
begin
  Result := DecryptClientKeyWithKey(Value, '-1064573647');
end;

function DecryptClientKeyWithKey(const Value, CipherKey: AnsiString): AnsiString;
begin
  Result := Base64Decode(Decode6Bit(Value));
  if Result <> '' then
    DecryptDes_New(Result[1], Result[1], Length(Result), CipherKey);
end;

function DecryptClientParam(const Value: AnsiString; AKey: Integer;
  out Param: TLoginClientParam): Boolean;
var
  Encrypted, Compressed: AnsiString;
  Buffer: Pointer;
  BufferSize: Integer;
begin
  Result := False;
  FillChar(Param, SizeOf(Param), 0);
  Encrypted := Base64Decode(Decode6Bit(Value));
  if Encrypted = '' then Exit;
  SetLength(Compressed, Length(Encrypted));
  DecryptDes(Encrypted[1], Compressed[1], Length(Encrypted), ClientKeyText(AKey));
  Buffer := nil;
  BufferSize := 0;
  try
    DecompressBuf(@Compressed[1], Length(Compressed), SizeOf(Param), Buffer, BufferSize);
    Result := BufferSize = SizeOf(Param);
    if Result then Move(Buffer^, Param, SizeOf(Param));
  except
    Result := False;
  end;
  if Buffer <> nil then FreeMem(Buffer);
end;

end.
