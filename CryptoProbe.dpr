program CryptoProbe;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows, System.SysUtils, System.Classes, GxxCrypto, GxxClientData,
  UnitDes, ZlibEx;

var
  P: TLoginClientParam;
  Cfg: TConfigClientData;
  K: Integer;
  Base: string;
  S: TStringList;
  RawKey: AnsiString;
  I: Integer;
  FS: TFileStream;
  EncCfg: TBytes;
  Payload: TBytes;
begin
  if (ParamCount = 2) and SameText(ParamStr(1), 'clientdata') then
  begin
    FS := TFileStream.Create(ParamStr(2), fmOpenRead or fmShareDenyNone);
    try
      if FS.Size < SizeOf(Cfg) then raise Exception.Create('File too small');
      SetLength(EncCfg, SizeOf(Cfg));
      FS.Position := FS.Size - SizeOf(Cfg);
      FS.ReadBuffer(EncCfg[0], Length(EncCfg));
      DecryptDes(EncCfg[0], Cfg, SizeOf(Cfg), '3230393649');
      Writeln('FileSize=', FS.Size);
      Writeln('RecordSize=', SizeOf(Cfg));
      Writeln('PayloadSize=', Cfg.nSize, ' CRC=', IntToHex(Cfg.nCrc, 8));
      if Cfg.nSize > 0 then
      begin
        SetLength(Payload, Cfg.nSize);
        FS.Position := 0;
        FS.ReadBuffer(Payload[0], Length(Payload));
        Writeln('ComputedCRC=', IntToHex(ClientDataCRC(@Payload[0], Cfg.nSize), 8));
      end;
      Writeln('Back=', Cfg.nBackBmpOffSet, ',', Cfg.nBackBmpSize, ',', IntToHex(Cfg.nBackBmpCrc, 8));
      Writeln('BaseUI=', Cfg.nBaseUIOffSet, ',', Cfg.nBaseUISize);
      Writeln('ConfigUI=', Cfg.nConfigDlgUIOffSet, ',', Cfg.nConfigDlgUISize);
      Writeln('Cursors=', Cfg.nCursorDefOffset, ',', Cfg.nCursorDefSize, ';',
        Cfg.nCursorMountOffset, ',', Cfg.nCursorMountSize, ';',
        Cfg.nCursorUnmountOffset, ',', Cfg.nCursorUnmountSize);
      Writeln('CustomConfigs=', Cfg.nCustomMonsterConfigOffset, ',',
        Cfg.nCustomMonsterConfigSize, ';', Cfg.nCustomMagicConfigOffset, ',',
        Cfg.nCustomMagicConfigSize, ';', Cfg.nCustomNpcConfigOffset, ',',
        Cfg.nCustomNpcConfigSize);
      Writeln('ProtectBoss=', Cfg.nCustomProtectItemsOffset, ',',
        Cfg.nCustomProtectItemsSize, ';', Cfg.nCustomBossListOffset, ',',
        Cfg.nCustomBossListSize);
      Writeln('Descriptions=', Cfg.nItemDescListOffset, ',', Cfg.nItemDescListSize,
        ';', Cfg.nItemDescTopListOffset, ',', Cfg.nItemDescTopListSize, ';',
        Cfg.nFilterItemListOffset, ',', Cfg.nFilterItemListSize, ';',
        Cfg.nTZItemDescListOffset, ',', Cfg.nTZItemDescListSize, ';',
        Cfg.nGodBlessItemsOffset, ',', Cfg.nGodBlessItemsSize);
      Writeln('Lists=', Cfg.nDataFileOffSet, ',', Cfg.nDataFileSize, ';',
        Cfg.nMapFileOffSet, ',', Cfg.nMapFileSize, ';', Cfg.nWavFileOffSet, ',',
        Cfg.nWavFileSize, ';', Cfg.nPlugFileNameOffSet, ',',
        Cfg.nPlugFileNameSize, ';', Cfg.nImageFileOffSet, ',', Cfg.nImageFileSize);
      Writeln('Plan=', string(Cfg.sGamePlanName));
      Writeln('Resources=', string(Cfg.sResourcesDir));
      Writeln('Version=', string(Cfg.sGameLoginVersion));
      Writeln('CustomUI=', Cfg.boCustomUI, ' LoginMode=', Cfg.nLoginMode);
      Writeln('MainUI=ChatTop(', Cfg.boChatTopButtonNoMove, ',',
        Cfg.nChatTopButtonXSpace, ',', Cfg.nChatTopButtonYSpace,
        ') Left(', Cfg.boLeftButtonNoMove, ',', Cfg.nLeftButtonXSpace, ',',
        Cfg.nLeftButtonYSpace, ') Good(', Cfg.nGoodNumOffsetX, ',',
        Cfg.nGoodNumOffsetY, ')');
      Writeln('Stars=', Cfg.boShowAniStarImage, ',', Cfg.nShowAniStarImageIndex,
        ',', Cfg.nShowAniStarImageCount, ',', Cfg.nShowAniStarImageIncSpacing,
        ',', Cfg.nShowAniStarImagePlayTime);
      Writeln('Hair=', Cfg.nUserHairOffsetX, ',', Cfg.nUserHairOffsetY, ';',
        Cfg.nOtherUserHairOffsetX, ',', Cfg.nOtherUserHairOffsetY, ';',
        Cfg.nHeroUserHairOffsetX, ',', Cfg.nHeroUserHairOffsetY, ';',
        Cfg.nUserHairOffsetX2, ',', Cfg.nUserHairOffsetY2);
      Writeln('UIFiles=', string(Cfg.NewUiFileNames[0]), ';',
        string(Cfg.NewUiFileNames[1]), ';', string(Cfg.NewUiFileNames[2]), ';',
        string(Cfg.NewUiFileNames[3]), ';', string(Cfg.NewUiFileNames[4]));
    finally
      FS.Free;
    end;
    Exit;
  end;
  if (ParamCount = 2) and SameText(ParamStr(1), 'listfile') then
  begin
    EncryptListFile(ParamStr(2));
    Exit;
  end;
  if (ParamCount = 2) and SameText(ParamStr(1), 'listline') then
  begin
    Writeln(string(EncryptListLine(AnsiString(ParamStr(2)))));
    Exit;
  end;
  if (ParamCount = 3) and SameText(ParamStr(1), 'decode') then
  begin
    RawKey := DecryptClientKey(AnsiString(ParamStr(2)));
    Write('SignedKeyText=', string(RawKey), ' Hex=');
    for I := 1 to Length(RawKey) do Write(IntToHex(Byte(RawKey[I]), 2));
    Writeln;
    RawKey := DecryptLegacyStringWithKey(AnsiString(ParamStr(2)), '3230393649');
    Write('UnsignedKeyText=', string(RawKey), ' Hex=');
    for I := 1 to Length(RawKey) do Write(IntToHex(Byte(RawKey[I]), 2));
    Writeln;
    K := StrToIntDef(string(RawKey), 0);
    Writeln('Key=', K);
    if DecryptClientParam(AnsiString(ParamStr(3)), K, P) then
    begin
      Writeln('Size=', SizeOf(P));
      Writeln('Caption=', string(P.sServerCaption));
      Writeln('Address=', string(P.sServeraddr));
      Writeln('Port=', P.nServerPort);
      Writeln('UpdateAddress=', string(P.sUpdateAddr));
      Writeln('UpdatePort=', P.nUpdatePort);
      Writeln('ClientData=', string(P.sClientDataFile));
      Writeln('Width=', P.wScreenWidth, ' Height=', P.wScreenHeight);
      Writeln('WindowMode=', P.boWindowMode, ' Version=', Ord(P.ClientVersion));
    end
    else
      Writeln('DECODE_FAILED');
    Exit;
  end;
  Base := ExtractFilePath(ParamStr(0));
  CreateClientDataFile(IncludeTrailingPathDelimiter(Base) + 'Client.dat',
    IncludeTrailingPathDelimiter(Base) + 'Config.ini');
  FillChar(P, SizeOf(P), 0);
  P.sGameLoginFileName := 'Client.exe';
  P.sServerCaption := 'Test';
  P.sServeraddr := '127.0.0.1';
  P.nServerPort := 7000;
  P.sUpdateAddr := '127.0.0.1';
  P.nUpdatePort := 7000;
  P.sHomePage := 'http://127.0.0.1/';
  P.btMaxClientCount := 6;
  P.wScreenWidth := 800;
  P.wScreenHeight := 600;
  P.btBitCount := 32;
  P.boWindowMode := True;
  P.boVSync := True;
  P.boHardware := True;
  P.ClientVersion := cvSerial;
  P.sSemaphoreName := 'GxxProbe';
  P.sClientDataFile := 'Client.dat';
  K := MakeLong(MakeWord(2, 3), MakeWord(4, 5));
  S := TStringList.Create;
  try
    S.Add('"Client.exe" ' + string(EncryptClientKey(AnsiString(IntToStr(K)))) + ' ' +
      string(EncryptClientParam(P, K)));
    S.Add('"Client.exe" 0 ' + string(EncryptLegacyString(AnsiString(IntToStr(K)))) + ' ' +
      string(EncryptClientParam(P, K)));
    S.Add('"Client.exe" 0 ' + string(EncryptLegacyStringWithKey(
      AnsiString(IntToStr(K)), '3230393649')) + ' ' + string(EncryptClientParam(P, K)));
    S.SaveToFile(IncludeTrailingPathDelimiter(Base) + 'probe-command.txt', TEncoding.ANSI);
  finally
    S.Free;
  end;
  Writeln('SizeOf(TLoginClientParam)=', SizeOf(P));
  Writeln('SizeOf(TConfigClientData)=', SizeOf(TConfigClientData));
  Writeln('Command written to probe-command.txt');
end.
