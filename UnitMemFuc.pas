unit UnitMemFuc;

interface

uses
  Windows, Classes, SysUtils, UnitCompress, UnitLoadDll, MD5Unit, UnitFuc, WinInet;

function GetWebStream(const AURL: string; outStream: TStream;
  AUseCache: Boolean = True; APostQuery: string = '';
  AProxy: PChar = nil; AProxyPort: Integer = 80; AUserAgent: PChar = nil;
  AReferer: PChar = nil): Boolean;

implementation

function GetWebStream(const AURL: string; outStream: TStream;
  AUseCache: Boolean = True; APostQuery: string = '';
  AProxy: PChar = nil; AProxyPort: Integer = 80; AUserAgent: PChar = nil;
  AReferer: PChar = nil): Boolean;
var
  hSession, hConnect, hRequest: hInternet;
  HostName, FileName: String;
  RequestMethod: PChar;
  InternetFlag: DWORD;
  AcceptType: packed array [0 .. 1] of LPWSTR;
  Buf: Pointer;
  dwBufLen, dwIndex: DWORD;
  Data: Array [0 .. $400] of Char;
  szLength, BytesReaded, BytesToRead: DWORD;
  procedure ParseURL(URL: String; var HostName, FileName: String);

    procedure ReplaceChar(c1, c2: Char; var St: String);
    var
      p: Integer;
    begin
      while True do
      begin
        p := Pos(c1, St);
        if p = 0 then
          Break
        else
          St[p] := c2;
      end;
    end;

  var
    i: Integer;
  begin
    if Pos('http://', LowerCase(URL)) <> 0 then
      System.Delete(URL, 1, 7);

    i := Pos('/', URL);
    HostName := Copy(URL, 1, i);
    FileName := Copy(URL, i, Length(URL) - i + 1);

    if (Length(HostName) > 0) and (HostName[Length(HostName)] = '/') then
      SetLength(HostName, Length(HostName) - 1);
  end;

  procedure CloseHandles;
  begin
    InternetCloseHandle(hRequest);
    InternetCloseHandle(hConnect);
    InternetCloseHandle(hSession);
  end;

begin
  Result := False;
  if not Assigned(outStream) then
    Exit;
  try
    outStream.Size := 0;
    ParseURL(AURL, HostName, FileName);
    if (Assigned(AProxy)) then
      hSession := InternetOpen(AUserAgent,
        INTERNET_OPEN_TYPE_PRECONFIG or INTERNET_OPEN_TYPE_PROXY, AProxy,
        PChar(IntToStr(AProxyPort)), 0)
    else
      hSession := InternetOpen(AUserAgent, INTERNET_OPEN_TYPE_PRECONFIG, nil,
        nil, 0);

    hConnect := InternetConnect(hSession, PChar(HostName),
      INTERNET_DEFAULT_HTTP_PORT, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);

    if APostQuery = '' then
      RequestMethod := 'GET'
    else
      RequestMethod := 'POST';

    if AUseCache then
      InternetFlag := 0
    else
      InternetFlag := INTERNET_FLAG_RELOAD;

    AcceptType[0] := PChar('Accept: */*');
    AcceptType[1] := nil;

    hRequest := HttpOpenRequest(hConnect, RequestMethod, PChar(FileName),
      'HTTP/1.1', PChar(AReferer), @AcceptType, InternetFlag, 0);

    if APostQuery = '' then
      HttpSendRequest(hRequest, nil, 0, nil, 0)
    else
      HttpSendRequest(hRequest,
        'Content-Type: application/x-www-form-urlencoded', 47,
        PChar(APostQuery), Length(APostQuery));

    dwIndex := 0;
    dwBufLen := 1024;
    GetMem(Buf, dwBufLen);

    Result := HttpQueryInfo(hRequest, HTTP_QUERY_CONTENT_LENGTH, Buf, dwBufLen,
      dwIndex);
    if Result then
    begin
      szLength := StrToInt(StrPas(PChar(Buf)));
      BytesReaded := 0;
      BytesToRead := 0;
      while (InternetReadFile(hRequest, @Data, SizeOf(Data), BytesToRead)) do
      begin
        if BytesToRead = 0 then
          Break;
        outStream.Write(Data, BytesToRead);
        inc(BytesReaded, BytesToRead);
      end;
      Result := (szLength = BytesReaded) and (szLength > 0);
    end;
    FreeMem(Buf);
    CloseHandles;
  except
  end;
end;

end.
 