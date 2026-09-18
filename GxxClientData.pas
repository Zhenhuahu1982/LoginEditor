unit GxxClientData;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics;

type
  TItemHintInfoData = record
    Index: Byte;
    PropertyType: Byte;
    ShowSpliter: Boolean;
    HintWindow: Byte;
    ShowNormalHint: Boolean;
    Alignment: TAlignment;
    Color: TColor;
    ShowText: string[80];
  end;

  TItemHintTextInfoData = record
    Alignment: TAlignment;
    Text: string[80];
  end;

  TConfigClientData = packed record
    nSize: Integer;
    nCrc: Cardinal;
    nBaseUIOffSet, nBaseUISize: Integer;
    nShareUIOffSet, nShareUISize: Integer;
    nNewStateWindowUIOffSet, nNewStateWindowUISize: Integer;
    nConfigDlgUIOffSet, nConfigDlgUISize: Integer;
    nJSYUIOffSet, nJSYUISize: Integer;
    nBackBmpOffSet, nBackBmpSize: Integer;
    nBackBmpCrc: Cardinal;
    nCursorDefOffset, nCursorDefSize: Integer;
    nCursorDefCrc: Cardinal;
    nCursorMountOffset, nCursorMountSize: Integer;
    nCursorMountCrc: Cardinal;
    nCursorUnmountOffset, nCursorUnmountSize: Integer;
    nCursorUnmountCrc: Cardinal;
    nPlugFileOffset, nPlugFileSize: Integer;
    nCustomMonsterConfigOffset, nCustomMonsterConfigSize: Integer;
    nCustomMagicConfigOffset, nCustomMagicConfigSize: Integer;
    nCustomNpcConfigOffset, nCustomNpcConfigSize: Integer;
    nCustomProtectItemsOffset, nCustomProtectItemsSize: Integer;
    nCustomBossListOffset, nCustomBossListSize: Integer;
    nItemDescListOffset, nItemDescListSize: Integer;
    nItemDescTopListOffset, nItemDescTopListSize: Integer;
    nFilterItemListOffset, nFilterItemListSize: Integer;
    nTZItemDescListOffset, nTZItemDescListSize: Integer;
    nGodBlessItemsOffset, nGodBlessItemsSize: Integer;
    nDataFileOffSet, nDataFileSize: Integer;
    nMapFileOffSet, nMapFileSize: Integer;
    nWavFileOffSet, nWavFileSize: Integer;
    nPlugFileNameOffSet, nPlugFileNameSize: Integer;
    nImageFileOffSet, nImageFileSize: Integer;
    sGamePlanName: string[30];
    boChangeSrceenBitCount, boShowOpenDoor, boShow1024: Boolean;
    sRunGatePassWord: string[50];
    ClientConfigs: array[0..95] of Boolean;
    ClientConfigs_Ex: array[0..0] of Boolean;
    HumManuallyCustomHits: array[0..4] of LongWord;
    sResourcesDir: string[50];
    boWindowBiMaximize: Boolean;
    nLoadResourcesOrder: Byte;
    boShowVersion, boShowHealthNotice, boCustomUI, boCustomConfigDlg: Boolean;
    NewUiFileNames: array[0..4] of string[50];
    nGoodNumOffsetX, nGoodNumOffsetY: Integer;
    nChatMemoItemFColor, nChatMemoItemBColor: TColor;
    nPivateClientKey1: LongWord;
    boChatTopButtonNoMove: Boolean;
    nChatTopButtonXSpace, nChatTopButtonYSpace: Integer;
    boLeftButtonNoMove: Boolean;
    nLeftButtonXSpace, nLeftButtonYSpace: Integer;
    boBottomLevelTextUseSystemDef, boDefShowStateWinEx: Boolean;
    boHPPercentShow, boMPPercentShow, boChatSayItemHideClose: Boolean;
    boOverLapItemNumOldShow, boHealthNumberSeparate: Boolean;
    nHealthNumberSelfOffset, nHealthNumberHumOffset: Integer;
    nPivateClientKey2: LongWord;
    boShowAniStarImage: Boolean;
    nShowAniStarImageIndex, nShowAniStarImageCount: Integer;
    nShowAniStarImageIncSpacing, nShowAniStarImagePlayTime: Integer;
    boShowAniBagCompareImg: Boolean;
    nShowAniBagCompareImgIndex, nShowAniBagCompareImgCount: Integer;
    nShowAniBagCompareImgPlayTime, nEquipmentImgOffsetX, nEquipmentImgOffsetY: Integer;
    boCustomActorSimpleShow: Boolean;
    nSimpleActorRace, nSimpleActorRaceImg, nSimpleActorAppr: Integer;
    boCustomHuamSimpleShow: Boolean;
    nSimpleDressShapeArr: array[0..2] of Integer;
    nSimpleWeaponShapeArr: array[0..2] of Integer;
    boCustomBBSimpleShow: Boolean;
    nSimpleBBRace, nSimpleBBRaceImg, nSimpleBBAppr: Integer;
    boShowExploreItemIcon: Boolean;
    btExploreItemIconShowType: Byte;
    dwExploreItemIconIndex, dwExploreItemIconCount, dwExploreItemIconPlayTime: LongWord;
    nExploreItemIconOffsetX, nExploreItemIconOffsetY: Integer;
    boShowValueItemEffect: Boolean;
    dwValueItemEffectIndex, dwValueItemEffectCount, dwValueItemEffectPlayTime: LongWord;
    nValueItemEffectOffsetX, nValueItemEffectOffsetY: Integer;
    sAttackModeTexts: array[0..7] of string[40];
    sExpAddHintText, sNGExpAddHintText: string[60];
    nPivateClientKey3: LongWord;
    nNPCMsgDlgTextOffsetX, nNPCMsgDlgTextOffsetY: Integer;
    nAuctionBroadcastDlgX, nAuctionBroadcastDlgY: Integer;
    UpdateStateDlgHorzAlign: TAlignment;
    UpdateStateDlgVertAlign: TVerticalAlignment;
    UpdateStateDlgOffsetX, UpdateStateDlgOffsetY: Integer;
    sElementNewPropertyTexts: array[0..24] of string[80];
    sHumPropertyGroupCaption: array[0..6] of string[40];
    sItemHintFluteStoneText, sItemHintNoFluteStoneText: string[80];
    nItemHintFluteStoneColor, nItemHintNoFluteStoneColor: Integer;
    nUserHairOffsetX, nUserHairOffsetY: Integer;
    nOtherUserHairOffsetX, nOtherUserHairOffsetY: Integer;
    nHeroUserHairOffsetX, nHeroUserHairOffsetY: Integer;
    nUserHairOffsetX2, nUserHairOffsetY2: Integer;
    nOtherUserHairOffsetX2, nOtherUserHairOffsetY2: Integer;
    nHeroUserHairOffsetX2, nHeroUserHairOffsetY2: Integer;
    boNoMoveNewChrDlg, boSaveMagicIconPosition: Boolean;
    boDisableDrogMagicIcon, boDisableShowFireHitCDTime: Boolean;
    boItemHintNoShowZeroValue: Boolean;
    nMaxClientCount: Integer;
    boWaitStart, boEnableCtrlZ, boShowProgressOnRun: Boolean;
    boShowLoadResProgress, boPlayOldVerSound, boShowUrlVerNotEqual: Boolean;
    sShowUrlVerNotEqual: string[99];
    wUpdateThreadCount, wUpdateQueueCount: Word;
    sGameLoginVersion: string[10];
    OtherHintAlignment: TAlignment;
    ItemHintConfig: array[0..13] of TItemHintInfoData;
    ItemHintTextConfig: array[0..207] of TItemHintTextInfoData;
    nLoginMode: Byte;
  end;

function ClientDataCRC(ABuffer: Pointer; ASize: Integer): Cardinal;
procedure CreateClientDataFile(const AFileName, AIniFileName: string);

implementation

uses
  Winapi.Windows, System.IniFiles, UnitDes, ZlibEx, GxxCrypto;

function ClientDataCRC(ABuffer: Pointer; ASize: Integer): Cardinal;
var
  P: PByte;
  I, J: Integer;
begin
  if (ABuffer = nil) or (ASize <= 0) then Exit(0);
  Result := $DBC66688 xor $FFFFFFFF;
  P := ABuffer;
  for I := 0 to ASize - 1 do
  begin
    Result := Result xor P^;
    for J := 0 to 7 do
      if (Result and 1) <> 0 then Result := (Result shr 1) xor $EDB88320
      else Result := Result shr 1;
    Inc(P);
  end;
  Result := Result xor $FFFFFFFF;
end;

function Clamp(const AValue, AMin, AMax: Integer): Integer;
begin
  Result := AValue;
  if Result < AMin then Result := AMin;
  if Result > AMax then Result := AMax;
end;

const
  KeyPatchFile = #$8865#$4E01#$6587#$4EF6;
  KeyResourcesDir = 'Resources' + #$76EE#$5F55;
  KeyAllowWeb = #$5141#$8BB8#$5F39#$51FA#$7F51#$9875;
  KeyWebUrl = #$5F39#$51FA#$7F51#$9875;
  KeyVersion = #$7248#$672C#$53F7;
  KeyMaxClients = #$591A#$5F00#$6570#$91CF;
  KeyBackImage = #$80CC#$666F#$56FE#$7247;
  KeyCursorDef = #$6E38#$620F#$5149#$6807;
  KeyCursorMount = #$9576#$5D4C#$5149#$6807;
  KeyCursorUnmount = #$62C6#$5378#$5149#$6807;
  KeyMustPluginFile = #$5FC5#$5907#$63D2#$4EF6#$6587#$4EF6;
  KeyUseMonsterConfig = #$96C6#$6210#$602A#$7269#$914D#$7F6E;
  KeyMonsterConfigFile = #$602A#$7269#$914D#$7F6E#$6587#$4EF6;
  KeyUseMagicConfig = #$96C6#$6210#$6280#$80FD#$914D#$7F6E;
  KeyMagicConfigFile = #$6280#$80FD#$914D#$7F6E#$6587#$4EF6;
  KeyUseNpcConfig = #$96C6#$6210#$004E#$0050#$0043#$914D#$7F6E;
  KeyNpcConfigFile = #$004E#$0050#$0043#$914D#$7F6E#$6587#$4EF6;
  KeyUseItemDesc = #$96C6#$6210#$7269#$54C1#$5907#$6CE8;
  KeyItemDescFile = #$7269#$54C1#$5907#$6CE8#$6587#$4EF6;
  KeyUseItemDescTop = #$96C6#$6210#$9876#$884C#$7269#$54C1#$5907#$6CE8;
  KeyItemDescTopFile = #$9876#$884C#$7269#$54C1#$5907#$6CE8#$6587#$4EF6;
  KeyUseFilterItems = #$96C6#$6210#$5185#$6302#$6361#$8D77#$7269#$54C1;
  KeyFilterItemsFile = #$5185#$6302#$6361#$8D77#$7269#$54C1#$6587#$4EF6;
  KeyUseTZItemDesc = #$96C6#$6210#$5957#$88C5#$5907#$6CE8;
  KeyTZItemDescFile = #$5957#$88C5#$5907#$6CE8#$6587#$4EF6;
  KeyUseGodBless = #$96C6#$6210#$795E#$4F51#$5907#$6CE8;
  KeyGodBlessFile = #$795E#$4F51#$5907#$6CE8#$6587#$4EF6;
  PatchFolderName = #$8865#$4E01#$6587#$4EF6#$5939;

function ResolveConfigFileName(const AIniFileName, AValue: string): string;
begin
  Result := Trim(AValue);
  if Result = '' then Exit;
  if (ExtractFileDrive(Result) = '') and
     not ((Length(Result) > 0) and (Result[1] = PathDelim)) then
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(AIniFileName)) + Result;
  Result := ExpandFileName(Result);
end;

procedure AppendCompressedBuffer(APayload: TMemoryStream; ABuffer: Pointer;
  ABufferSize: Integer; var AOffset, ASize: Integer; ACrc: PCardinal = nil);
var
  Compressed: Pointer;
  CompressedSize: Integer;
begin
  AOffset := APayload.Size;
  ASize := 0;
  if (ABuffer = nil) or (ABufferSize <= 0) then Exit;
  if ACrc <> nil then
    ACrc^ := ClientDataCRC(ABuffer, ABufferSize);
  Compressed := nil;
  CompressedSize := 0;
  CompressBuf(ABuffer, ABufferSize, Compressed, CompressedSize);
  try
    if (Compressed <> nil) and (CompressedSize > 0) then
    begin
      APayload.Position := APayload.Size;
      APayload.WriteBuffer(Compressed^, CompressedSize);
      ASize := CompressedSize;
    end;
  finally
    if Compressed <> nil then FreeMem(Compressed);
  end;
end;

procedure AppendCompressedFile(APayload: TMemoryStream; const AFileName: string;
  var AOffset, ASize: Integer; ACrc: PCardinal = nil);
var
  Source: TMemoryStream;
begin
  AOffset := APayload.Size;
  ASize := 0;
  if (AFileName = '') or not FileExists(AFileName) then Exit;
  Source := TMemoryStream.Create;
  try
    Source.LoadFromFile(AFileName);
    AppendCompressedBuffer(APayload, Source.Memory, Source.Size, AOffset, ASize, ACrc);
  finally
    Source.Free;
  end;
end;

procedure AppendCompressedText(APayload: TMemoryStream; const AText: AnsiString;
  var AOffset, ASize: Integer);
begin
  if AText = '' then
    AppendCompressedBuffer(APayload, nil, 0, AOffset, ASize)
  else
    AppendCompressedBuffer(APayload, Pointer(AText), Length(AText), AOffset, ASize);
end;

procedure AppendRawText(APayload: TMemoryStream; const AText: AnsiString;
  var AOffset, ASize: Integer);
begin
  AOffset := APayload.Size;
  ASize := Length(AText);
  if ASize > 0 then
  begin
    APayload.Position := APayload.Size;
    APayload.WriteBuffer(Pointer(AText)^, ASize);
  end;
end;

function NumberedSectionText(AIni: TIniFile; const ASection: string): AnsiString;
var
  Lines: TStringList;
  I, Count: Integer;
begin
  Lines := TStringList.Create;
  try
    Count := AIni.ReadInteger(ASection, 'Count', 0);
    for I := 0 to Count - 1 do
      Lines.Add(AIni.ReadString(ASection, IntToStr(I), ''));
    Result := AnsiString(Lines.Text);
  finally
    Lines.Free;
  end;
end;

function RuleFilesText(const ABaseDirectory: string): AnsiString;
const
  Names: array[0..2] of string = ('Wil.txt', 'Wzl.txt', 'Pak.txt');
var
  AllLines, Lines: TStringList;
  I, J, SeparatorPos: Integer;
  FileName, Line, Password: string;
begin
  AllLines := TStringList.Create;
  Lines := TStringList.Create;
  try
    for I := Low(Names) to High(Names) do
    begin
      FileName := IncludeTrailingPathDelimiter(ABaseDirectory) + Names[I];
      if FileExists(FileName) then
      begin
        Lines.LoadFromFile(FileName);
        if SameText(Names[I], 'Pak.txt') then
          for J := 0 to Lines.Count - 1 do
          begin
            Line := Lines[J];
            SeparatorPos := Pos('|', Line);
            if SeparatorPos > 0 then
            begin
              Password := Copy(Line, SeparatorPos + 1, MaxInt);
              if Password <> '' then
                Lines[J] := Copy(Line, 1, SeparatorPos) +
                  string(EncryptPakPassword(AnsiString(Password)));
            end;
          end;
        AllLines.AddStrings(Lines);
      end;
    end;
    Result := AnsiString(AllLines.Text);
  finally
    Lines.Free;
    AllLines.Free;
  end;
end;

function PluginFileNamesText(const ABaseDirectory: string): AnsiString;
var
  Search: TSearchRec;
  Lines: TStringList;
  PluginDirectory: string;
begin
  Lines := TStringList.Create;
  try
    PluginDirectory := IncludeTrailingPathDelimiter(ABaseDirectory) +
      PatchFolderName + PathDelim + 'Plugin' + PathDelim;
    if FindFirst(PluginDirectory + '*.*', faAnyFile, Search) = 0 then
    try
      repeat
        if (Search.Name <> '.') and (Search.Name <> '..') and
           ((Search.Attr and faDirectory) = 0) then
          Lines.Add(Search.Name);
      until FindNext(Search) <> 0;
    finally
      System.SysUtils.FindClose(Search);
    end;
    Result := AnsiString(Lines.Text);
  finally
    Lines.Free;
  end;
end;

procedure CreateClientDataFile(const AFileName, AIniFileName: string);
var
  Config: TConfigClientData;
  Encrypted: TBytes;
  Ini: TIniFile;
  GuiIni: TIniFile;
  Stream: TMemoryStream;
  Resource: TResourceStream;
  I: Integer;
  BaseDirectory: string;
  FileName: string;
  TextData: AnsiString;
begin
  Stream := TMemoryStream.Create;
  try
    try
      Resource := TResourceStream.Create(HInstance, 'CLIENTDATATEMPLATE', RT_RCDATA);
      try
        Resource.SaveToStream(Stream);
      finally
        Resource.Free;
      end;
    except
      Stream.Clear;
    end;
    if Stream.Size >= SizeOf(Config) then
    begin
      SetLength(Encrypted, SizeOf(Config));
      Stream.Position := Stream.Size - SizeOf(Config);
      Stream.ReadBuffer(Encrypted[0], Length(Encrypted));
      DecryptDes(Encrypted[0], Config, SizeOf(Config), '3230393649');
      Stream.Size := Stream.Size - SizeOf(Config);
    end
    else
    begin
      Stream.Clear;
      FillChar(Config, SizeOf(Config), 0);
    end;
  Ini := TIniFile.Create(AIniFileName);
  try
    Config.sGamePlanName := Ini.ReadString('Setup', '补丁文件', 'NewopUI.Pak');
    Config.sResourcesDir := Ini.ReadString('Setup', 'Resources目录', 'Resources');
    Config.sRunGatePassWord := Ini.ReadString('Setup', 'RunGatePassword', 'GxxM2');
    Config.boChangeSrceenBitCount := Ini.ReadBool('Setup', 'ChangeSrceenBitCount', False);
    Config.boShowOpenDoor := Ini.ReadBool('Setup', 'ShowOpenDoor', True);
    Config.boShow1024 := Ini.ReadBool('Setup', 'Show1024', True);
    Config.boWindowBiMaximize := Ini.ReadBool('Setup', 'WindowBiMaximize', False);
    Config.boShowVersion := Ini.ReadBool('Setup', 'ShowVersion', True);
    Config.boShowHealthNotice := Ini.ReadBool('Setup', 'ShowHealthNotice', True);
    Config.boBottomLevelTextUseSystemDef := Ini.ReadBool('Setup', 'BottomLevelTextUseSystemDef', True);
    Config.boWaitStart := Ini.ReadBool('Setup', 'WaitStart', True);
    Config.boEnableCtrlZ := Ini.ReadBool('Setup', 'EnableCtrlZ', True);
    Config.boShowProgressOnRun := Ini.ReadBool('Setup', 'ShowProgressOnRun', False);
    Config.boShowLoadResProgress := Ini.ReadBool('Setup', 'ShowLoadResProgress', True);
    Config.boPlayOldVerSound := Ini.ReadBool('Setup', 'PlayOldVerSound', True);
    Config.wUpdateThreadCount := Ini.ReadInteger('Setup', 'UpdateThreadCount', 6);
    Config.wUpdateQueueCount := Ini.ReadInteger('Setup', 'UpdateQueueCount', 1);
    Config.sGameLoginVersion := Ini.ReadString('Setup', '版本号', '2021-11-08');
    for I := 0 to High(Config.ClientConfigs) do
      Config.ClientConfigs[I] := Ini.ReadBool('Setup', 'Checked' + IntToStr(I), False);
  finally
    Ini.Free;
  end;
  Ini := TIniFile.Create(AIniFileName);
  try
    Config.sGamePlanName := Ini.ReadString('Setup', '补丁文件', 'NewopUI.Pak');
    Config.sResourcesDir := Ini.ReadString('Setup', 'Resources目录', 'Resources');
    Config.nLoadResourcesOrder := Byte(Clamp(Ini.ReadInteger('Setup',
      'LoadResourcesOrder', Config.nLoadResourcesOrder), 0, 4));
    Config.boCustomConfigDlg := Ini.ReadBool('Setup', 'CustomConfigDlg',
      Config.boCustomConfigDlg);
    Config.nGoodNumOffsetX := Ini.ReadInteger('Setup', 'GoodNumOffsetX', 0);
    Config.nGoodNumOffsetY := Ini.ReadInteger('Setup', 'GoodNumOffsetY', 0);
    Config.nChatMemoItemFColor := Ini.ReadInteger('Setup', 'ChatMemoItemFColor',
      Config.nChatMemoItemFColor);
    Config.nChatMemoItemBColor := Ini.ReadInteger('Setup', 'ChatMemoItemBColor',
      Config.nChatMemoItemBColor);
    Config.boChatTopButtonNoMove := Ini.ReadBool('Setup', 'ChatTopButtonNoMove', False);
    Config.nChatTopButtonXSpace := Ini.ReadInteger('Setup', 'ChatTopButtonXSpace', 29);
    Config.nChatTopButtonYSpace := Ini.ReadInteger('Setup', 'ChatTopButtonYSpace', 0);
    Config.boLeftButtonNoMove := Ini.ReadBool('Setup', 'LeftButtonNoMove', False);
    Config.nLeftButtonXSpace := Ini.ReadInteger('Setup', 'LeftButtonXSpace', 0);
    Config.nLeftButtonYSpace := Ini.ReadInteger('Setup', 'LeftButtonYSpace', 20);
    Config.boDefShowStateWinEx := Ini.ReadBool('Setup', 'DefShowStateWinEx', False);
    Config.boHPPercentShow := Ini.ReadBool('Setup', 'HPPercentShow', False);
    Config.boMPPercentShow := Ini.ReadBool('Setup', 'MPPercentShow', False);
    Config.boChatSayItemHideClose := Ini.ReadBool('Setup', 'ChatSayItemHideClose', False);
    Config.boOverLapItemNumOldShow := Ini.ReadBool('Setup', 'OverLapItemNumOldShow', False);
    Config.boHealthNumberSeparate := Ini.ReadBool('Setup', 'HealthNumberSeparate', False);
    Config.nHealthNumberSelfOffset := Ini.ReadInteger('Setup', 'HealthNumberSelfOffset', 0);
    Config.nHealthNumberHumOffset := Ini.ReadInteger('Setup', 'HealthNumberHumOffset', 0);
    Config.boShowUrlVerNotEqual := Ini.ReadBool('Setup', '允许弹出网页', False);
    Config.sShowUrlVerNotEqual := Ini.ReadString('Setup', '弹出网页', '');
    Config.sGameLoginVersion := Ini.ReadString('Setup', '版本号', '2021-11-08');
    Config.nMaxClientCount := Ini.ReadInteger('Setup', '多开数量', 6);
    Config.OtherHintAlignment := TAlignment(Clamp(Ini.ReadInteger('Setup',
      'OtherHintAlignment', 0), 0, 2));
    Config.nLoginMode := Byte(Clamp(Ini.ReadInteger('Setup', 'LoginMode', 0), 0, 255));
    Config.ClientConfigs_Ex[0] := Ini.ReadBool('Setup', 'CheckedEx0', False);
    for I := 0 to 4 do
      Config.HumManuallyCustomHits[I] := Ini.ReadInteger('Setup',
        'HumManuallyCustomHits' + IntToStr(I), 0);
  finally
    Ini.Free;
  end;
  Ini := TIniFile.Create(AIniFileName);
  try
    Config.boShowAniStarImage := Ini.ReadBool('Setup', 'ShowAniStarImage', False);
    Config.nShowAniStarImageIndex := Ini.ReadInteger('Setup', 'ShowAniStarImageIndex', 0);
    Config.nShowAniStarImageCount := Ini.ReadInteger('Setup', 'ShowAniStarImageCount', 0);
    Config.nShowAniStarImageIncSpacing := Ini.ReadInteger('Setup', 'ShowAniStarImageIncSpacing', 0);
    Config.nShowAniStarImagePlayTime := Ini.ReadInteger('Setup', 'ShowAniStarImagePlayTime', 100);
    Config.boShowAniBagCompareImg := Ini.ReadBool('Setup', 'ShowAniBagCompareImg', False);
    Config.nShowAniBagCompareImgIndex := Ini.ReadInteger('Setup', 'ShowAniBagCompareImgIndex', 0);
    Config.nShowAniBagCompareImgCount := Ini.ReadInteger('Setup', 'ShowAniBagCompareImgCount', 0);
    Config.nShowAniBagCompareImgPlayTime := Ini.ReadInteger('Setup', 'ShowAniBagCompareImgPlayTime', 100);
    Config.nEquipmentImgOffsetX := Ini.ReadInteger('Setup', 'EquipmentImgOffsetX', 0);
    Config.nEquipmentImgOffsetY := Ini.ReadInteger('Setup', 'EquipmentImgOffsetY', 0);
    Config.boCustomActorSimpleShow := Ini.ReadBool('Setup', 'CustomActorSimpleShow', False);
    Config.nSimpleActorRace := Ini.ReadInteger('Setup', 'SimpleActorRace', 83);
    Config.nSimpleActorRaceImg := Ini.ReadInteger('Setup', 'SimpleActorRaceImg', 18);
    Config.nSimpleActorAppr := Ini.ReadInteger('Setup', 'SimpleActorAppr', 27);
    Config.boCustomHuamSimpleShow := Ini.ReadBool('Setup', 'CustomHuamSimpleShow', False);
    for I := 0 to 2 do
    begin
      Config.nSimpleDressShapeArr[I] := Ini.ReadInteger('Setup',
        'SimpleDressShape' + IntToStr(I), Config.nSimpleDressShapeArr[I]);
      Config.nSimpleWeaponShapeArr[I] := Ini.ReadInteger('Setup',
        'SimpleWeaponShape' + IntToStr(I), Config.nSimpleWeaponShapeArr[I]);
    end;
    Config.boCustomBBSimpleShow := Ini.ReadBool('Setup', 'CustomBBSimpleShow', False);
    Config.nSimpleBBRace := Ini.ReadInteger('Setup', 'SimpleBBRace', 83);
    Config.nSimpleBBRaceImg := Ini.ReadInteger('Setup', 'SimpleBBRaceImg', 18);
    Config.nSimpleBBAppr := Ini.ReadInteger('Setup', 'SimpleBBAppr', 27);
    Config.boShowExploreItemIcon := Ini.ReadBool('Setup', 'ShowExploreItemIcon', False);
    Config.btExploreItemIconShowType := Byte(Clamp(Ini.ReadInteger('Setup',
      'ExploreItemIconShowType', 0), 0, 255));
    Config.dwExploreItemIconIndex := Ini.ReadInteger('Setup', 'ExploreItemIconIndex', 0);
    Config.dwExploreItemIconCount := Ini.ReadInteger('Setup', 'ExploreItemIconCount', 0);
    Config.dwExploreItemIconPlayTime := Ini.ReadInteger('Setup', 'ExploreItemIconPlayTime', 80);
    Config.nExploreItemIconOffsetX := Ini.ReadInteger('Setup', 'ExploreItemIconOffstX', 0);
    Config.nExploreItemIconOffsetY := Ini.ReadInteger('Setup', 'ExploreItemIconOffstY', 0);
    Config.boShowValueItemEffect := Ini.ReadBool('Setup', 'ShowValueItemEffect', False);
    Config.dwValueItemEffectIndex := Ini.ReadInteger('Setup', 'ValueItemEffectIndex', 0);
    Config.dwValueItemEffectCount := Ini.ReadInteger('Setup', 'ValueItemEffectCount', 0);
    Config.dwValueItemEffectPlayTime := Ini.ReadInteger('Setup', 'ValueItemEffectPlayTime', 80);
    Config.nValueItemEffectOffsetX := Ini.ReadInteger('Setup', 'ValueItemEffectOffsetX', 0);
    Config.nValueItemEffectOffsetY := Ini.ReadInteger('Setup', 'ValueItemEffectOffsetY', 0);
    for I := 0 to 7 do
      Config.sAttackModeTexts[I] := Ini.ReadString('Setup',
        'AttackModeText' + IntToStr(I + 1), Config.sAttackModeTexts[I]);
    Config.sExpAddHintText := Ini.ReadString('Setup', 'ExpAddHintText', Config.sExpAddHintText);
    Config.sNGExpAddHintText := Ini.ReadString('Setup', 'NGExpAddHintText', Config.sNGExpAddHintText);
    Config.nNPCMsgDlgTextOffsetX := Ini.ReadInteger('Setup', 'NPCMsgDlgTextOffsetX', 0);
    Config.nNPCMsgDlgTextOffsetY := Ini.ReadInteger('Setup', 'NPCMsgDlgTextOffsetY', 0);
    Config.nAuctionBroadcastDlgX := Ini.ReadInteger('Setup', 'AuctionBroadcastDlgX', 0);
    Config.nAuctionBroadcastDlgY := Ini.ReadInteger('Setup', 'AuctionBroadcastDlgY', 0);
    Config.UpdateStateDlgHorzAlign := TAlignment(Clamp(Ini.ReadInteger('Setup',
      'UpdateStateDlgHorzAlign', 1), 0, 2));
    Config.UpdateStateDlgVertAlign := TVerticalAlignment(Clamp(Ini.ReadInteger('Setup',
      'UpdateStateDlgVertAlign', 0), 0, 2));
    Config.UpdateStateDlgOffsetX := Ini.ReadInteger('Setup', 'UpdateStateDlgOffsetX', -10);
    Config.UpdateStateDlgOffsetY := Ini.ReadInteger('Setup', 'UpdateStateDlgOffsetY', 10);

    for I := 0 to High(Config.sElementNewPropertyTexts) do
      Config.sElementNewPropertyTexts[I] := Ini.ReadString('Setup',
        'ElementNewPropertyText' + IntToStr(I + 1),
        Config.sElementNewPropertyTexts[I]);
    for I := 0 to High(Config.sHumPropertyGroupCaption) do
      Config.sHumPropertyGroupCaption[I] := Ini.ReadString('Setup',
        'HumPropertyGroupCaption' + IntToStr(I + 1),
        Config.sHumPropertyGroupCaption[I]);

    Config.sItemHintFluteStoneText := Ini.ReadString('Setup',
      'ItemHintFluteStoneText', Config.sItemHintFluteStoneText);
    Config.sItemHintNoFluteStoneText := Ini.ReadString('Setup',
      'ItemHintNoFluteStoneText', Config.sItemHintNoFluteStoneText);
    Config.nItemHintFluteStoneColor := Ini.ReadInteger('Setup',
      'ItemHintFluteStoneColor', Config.nItemHintFluteStoneColor);
    Config.nItemHintNoFluteStoneColor := Ini.ReadInteger('Setup',
      'ItemHintNoFluteStoneColor', Config.nItemHintNoFluteStoneColor);

    Config.ItemHintConfig[5].ShowText := Ini.ReadString('Setup',
      'ItemHintBaseGroupText', Config.ItemHintConfig[5].ShowText);
    Config.ItemHintConfig[5].Color := Ini.ReadInteger('Setup',
      'ItemHintBaseGroupColor', Config.ItemHintConfig[5].Color);
    Config.ItemHintConfig[6].ShowText := Ini.ReadString('Setup',
      'ItemHintFluteCountText', Config.ItemHintConfig[6].ShowText);
    Config.ItemHintConfig[6].Color := Ini.ReadInteger('Setup',
      'ItemHintFluteCountColor', Config.ItemHintConfig[6].Color);
    Config.ItemHintConfig[7].ShowText := Ini.ReadString('Setup',
      'ItemHintElementsGroupText', Config.ItemHintConfig[7].ShowText);
    Config.ItemHintConfig[7].Color := Ini.ReadInteger('Setup',
      'ItemHintElementsGroupColor', Config.ItemHintConfig[7].Color);
    Config.ItemHintConfig[9].ShowText := Ini.ReadString('Setup',
      'ItemHintInsuranceText', Config.ItemHintConfig[9].ShowText);
    Config.ItemHintConfig[9].Color := Ini.ReadInteger('Setup',
      'ItemHintInsuranceColor', Config.ItemHintConfig[9].Color);
    Config.ItemHintConfig[10].ShowText := Ini.ReadString('Setup',
      'ItemHintItemFromText', Config.ItemHintConfig[10].ShowText);
    Config.ItemHintConfig[10].Color := Ini.ReadInteger('Setup',
      'ItemHintItemFromColor', Config.ItemHintConfig[10].Color);
    Config.ItemHintConfig[12].ShowText := Ini.ReadString('Setup',
      'ItemHintTZGroupText', Config.ItemHintConfig[12].ShowText);
    Config.ItemHintConfig[12].Color := Ini.ReadInteger('Setup',
      'ItemHintTZGroupColor', Config.ItemHintConfig[12].Color);

    Config.nUserHairOffsetX := Ini.ReadInteger('Setup', 'UserHairOffsetX', 0);
    Config.nUserHairOffsetY := Ini.ReadInteger('Setup', 'UserHairOffsetY', 0);
    Config.nOtherUserHairOffsetX := Ini.ReadInteger('Setup', 'OtherUserHairOffsetX', 0);
    Config.nOtherUserHairOffsetY := Ini.ReadInteger('Setup', 'OtherUserHairOffsetY', 0);
    Config.nHeroUserHairOffsetX := Ini.ReadInteger('Setup', 'HeroUserHairOffsetX', 0);
    Config.nHeroUserHairOffsetY := Ini.ReadInteger('Setup', 'HeroUserHairOffsetY', 0);
    Config.nUserHairOffsetX2 := Ini.ReadInteger('Setup', 'UserHairOffsetX2', 0);
    Config.nUserHairOffsetY2 := Ini.ReadInteger('Setup', 'UserHairOffsetY2', 0);
    Config.nOtherUserHairOffsetX2 := Ini.ReadInteger('Setup', 'OtherUserHairOffsetX2', 0);
    Config.nOtherUserHairOffsetY2 := Ini.ReadInteger('Setup', 'OtherUserHairOffsetY2', 0);
    Config.nHeroUserHairOffsetX2 := Ini.ReadInteger('Setup', 'HeroUserHairOffsetX2', 0);
    Config.nHeroUserHairOffsetY2 := Ini.ReadInteger('Setup', 'HeroUserHairOffsetY2', 0);
    Config.boNoMoveNewChrDlg := Ini.ReadBool('Setup', 'NoMoveNewChrDlg', False);
    Config.boSaveMagicIconPosition := Ini.ReadBool('Setup', 'SaveMagicIconPosition', True);
    Config.boDisableDrogMagicIcon := Ini.ReadBool('Setup', 'DisableDrogMagicIcon', False);
    Config.boDisableShowFireHitCDTime := Ini.ReadBool('Setup',
      'DisableShowFireHitCDTime', False);
    Config.boItemHintNoShowZeroValue := Ini.ReadBool('Setup',
      'ItemHintNoShowZeroValue', False);
  finally
    Ini.Free;
  end;

  { These keys contain Chinese text.  Keep the source representation ASCII-only
    so their names survive any ANSI/UTF-8 conversion of this unit. }
  Ini := TIniFile.Create(AIniFileName);
  try
    Config.sGamePlanName := Ini.ReadString('Setup', KeyPatchFile, 'NewopUI.Pak');
    Config.sResourcesDir := Ini.ReadString('Setup', KeyResourcesDir, 'Resources');
    Config.boShowUrlVerNotEqual := Ini.ReadBool('Setup', KeyAllowWeb, False);
    Config.sShowUrlVerNotEqual := Ini.ReadString('Setup', KeyWebUrl, '');
    Config.sGameLoginVersion := Ini.ReadString('Setup', KeyVersion, '2021-11-08');
    Config.nMaxClientCount := Ini.ReadInteger('Setup', KeyMaxClients, 6);
  finally
    Ini.Free;
  end;
  GuiIni := TIniFile.Create(IncludeTrailingPathDelimiter(
    ExtractFilePath(AIniFileName)) + 'GUI_Config.ini');
  try
    for I := 0 to 4 do
      Config.NewUiFileNames[I] := GuiIni.ReadString('NewUI' + IntToStr(I + 1) + '_PAK',
        'FileName', Config.NewUiFileNames[I]);
  finally
    GuiIni.Free;
  end;

  { Add configured binary/text payloads after the preserved UI template.  Old
    template blocks may remain before these new blocks, but the record offsets
    always point at the newest data and the payload CRC covers the whole stream. }
  BaseDirectory := ExtractFilePath(AIniFileName);
  Ini := TIniFile.Create(AIniFileName);
  try
    FileName := ResolveConfigFileName(AIniFileName,
      Ini.ReadString('Setup', KeyBackImage, ''));
    if FileExists(FileName) then
      AppendCompressedFile(Stream, FileName, Config.nBackBmpOffSet,
        Config.nBackBmpSize, @Config.nBackBmpCrc);

    FileName := ResolveConfigFileName(AIniFileName,
      Ini.ReadString('Setup', KeyCursorDef, ''));
    if FileExists(FileName) then
      AppendCompressedFile(Stream, FileName, Config.nCursorDefOffset,
        Config.nCursorDefSize, @Config.nCursorDefCrc);
    FileName := ResolveConfigFileName(AIniFileName,
      Ini.ReadString('Setup', KeyCursorMount, ''));
    if FileExists(FileName) then
      AppendCompressedFile(Stream, FileName, Config.nCursorMountOffset,
        Config.nCursorMountSize, @Config.nCursorMountCrc);
    FileName := ResolveConfigFileName(AIniFileName,
      Ini.ReadString('Setup', KeyCursorUnmount, ''));
    if FileExists(FileName) then
      AppendCompressedFile(Stream, FileName, Config.nCursorUnmountOffset,
        Config.nCursorUnmountSize, @Config.nCursorUnmountCrc);

    FileName := ResolveConfigFileName(AIniFileName,
      Ini.ReadString('Setup', KeyMustPluginFile, ''));
    AppendCompressedFile(Stream, FileName, Config.nPlugFileOffset,
      Config.nPlugFileSize);

    if Ini.ReadBool('Setup', KeyUseMonsterConfig, False) then
      AppendCompressedFile(Stream, ResolveConfigFileName(AIniFileName,
        Ini.ReadString('Setup', KeyMonsterConfigFile, '')),
        Config.nCustomMonsterConfigOffset, Config.nCustomMonsterConfigSize)
    else
      Config.nCustomMonsterConfigSize := 0;
    if Ini.ReadBool('Setup', KeyUseMagicConfig, False) then
      AppendCompressedFile(Stream, ResolveConfigFileName(AIniFileName,
        Ini.ReadString('Setup', KeyMagicConfigFile, '')),
        Config.nCustomMagicConfigOffset, Config.nCustomMagicConfigSize)
    else
      Config.nCustomMagicConfigSize := 0;
    if Ini.ReadBool('Setup', KeyUseNpcConfig, False) then
      AppendCompressedFile(Stream, ResolveConfigFileName(AIniFileName,
        Ini.ReadString('Setup', KeyNpcConfigFile, '')),
        Config.nCustomNpcConfigOffset, Config.nCustomNpcConfigSize)
    else
      Config.nCustomNpcConfigSize := 0;

    TextData := NumberedSectionText(Ini, 'GJUseItems');
    AppendRawText(Stream, TextData, Config.nCustomProtectItemsOffset,
      Config.nCustomProtectItemsSize);
    TextData := NumberedSectionText(Ini, 'BossList');
    AppendRawText(Stream, TextData, Config.nCustomBossListOffset,
      Config.nCustomBossListSize);

    if Ini.ReadBool('Setup', KeyUseItemDesc, False) then
      AppendCompressedFile(Stream, ResolveConfigFileName(AIniFileName,
        Ini.ReadString('Setup', KeyItemDescFile, '')),
        Config.nItemDescListOffset, Config.nItemDescListSize)
    else
      Config.nItemDescListSize := 0;
    if Ini.ReadBool('Setup', KeyUseItemDescTop, False) then
      AppendCompressedFile(Stream, ResolveConfigFileName(AIniFileName,
        Ini.ReadString('Setup', KeyItemDescTopFile, '')),
        Config.nItemDescTopListOffset, Config.nItemDescTopListSize)
    else
      Config.nItemDescTopListSize := 0;
    if Ini.ReadBool('Setup', KeyUseFilterItems, False) then
      AppendCompressedFile(Stream, ResolveConfigFileName(AIniFileName,
        Ini.ReadString('Setup', KeyFilterItemsFile, '')),
        Config.nFilterItemListOffset, Config.nFilterItemListSize)
    else
      Config.nFilterItemListSize := 0;
    if Ini.ReadBool('Setup', KeyUseTZItemDesc, False) then
      AppendCompressedFile(Stream, ResolveConfigFileName(AIniFileName,
        Ini.ReadString('Setup', KeyTZItemDescFile, '')),
        Config.nTZItemDescListOffset, Config.nTZItemDescListSize)
    else
      Config.nTZItemDescListSize := 0;
    if Ini.ReadBool('Setup', KeyUseGodBless, False) then
      AppendCompressedFile(Stream, ResolveConfigFileName(AIniFileName,
        Ini.ReadString('Setup', KeyGodBlessFile, '')),
        Config.nGodBlessItemsOffset, Config.nGodBlessItemsSize)
    else
      Config.nGodBlessItemsSize := 0;
  finally
    Ini.Free;
  end;

  if FileExists(IncludeTrailingPathDelimiter(BaseDirectory) + 'Data.txt') then
    AppendCompressedFile(Stream, IncludeTrailingPathDelimiter(BaseDirectory) +
      'Data.txt', Config.nDataFileOffSet, Config.nDataFileSize);
  if FileExists(IncludeTrailingPathDelimiter(BaseDirectory) + 'Map.txt') then
    AppendCompressedFile(Stream, IncludeTrailingPathDelimiter(BaseDirectory) +
      'Map.txt', Config.nMapFileOffSet, Config.nMapFileSize);
  if FileExists(IncludeTrailingPathDelimiter(BaseDirectory) + 'Wav.txt') then
    AppendCompressedFile(Stream, IncludeTrailingPathDelimiter(BaseDirectory) +
      'Wav.txt', Config.nWavFileOffSet, Config.nWavFileSize);

  if FileExists(IncludeTrailingPathDelimiter(BaseDirectory) + 'Wil.txt') or
     FileExists(IncludeTrailingPathDelimiter(BaseDirectory) + 'Wzl.txt') or
     FileExists(IncludeTrailingPathDelimiter(BaseDirectory) + 'Pak.txt') then
  begin
    TextData := RuleFilesText(BaseDirectory);
    AppendCompressedText(Stream, TextData, Config.nImageFileOffSet,
      Config.nImageFileSize);
  end;

  if DirectoryExists(IncludeTrailingPathDelimiter(BaseDirectory) +
     PatchFolderName + PathDelim + 'Plugin') then
  begin
    TextData := PluginFileNamesText(BaseDirectory);
    AppendCompressedText(Stream, TextData, Config.nPlugFileNameOffSet,
      Config.nPlugFileNameSize);
  end;

  Config.nSize := Stream.Size;
  if Stream.Size > 0 then Config.nCrc := ClientDataCRC(Stream.Memory, Stream.Size)
  else Config.nCrc := 0;
  SetLength(Encrypted, SizeOf(Config));
  EncryptDes(Config, Encrypted[0], SizeOf(Config), '3230393649');
  Stream.Position := Stream.Size;
  Stream.WriteBuffer(Encrypted[0], Length(Encrypted));
  Stream.SaveToFile(AFileName);
  finally
    Stream.Free;
  end;
end;

end.
