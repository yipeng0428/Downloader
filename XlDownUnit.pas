unit XlDownUnit;

interface

uses
  Windows;

type
{$Z4}    
  TDownTaskParam = packed record
    nReserved: Integer;
    szTaskUrl: array [1 .. 2084] of WideChar; 
    szRefUrl: array [1 .. 2084] of WideChar; 
    szCookies: array [1 .. 4096] of WideChar; 
    szFilename: array [1 .. MAX_PATH] of WideChar; 
    szReserved0: array [1 .. MAX_PATH] of WideChar;
    szSavePath: array [1 .. MAX_PATH] of WideChar; 
    hReserved: HWND;
    bReserved: BOOL;
    szReserved1: array [1 .. 64] of WideChar;
    szReserved2: array [1 .. 64] of WideChar;
    IsOnlyOriginal: BOOL; 
    nReserved1: UINT;
    DisableAutoRename: BOOL; 
    IsResume: BOOL; 
    reserved: array [1 .. 2048] of DWORD;
    procedure Init();
  end;

  TDOWN_TASK_STATUS = (NOITEM = 0, 
    TSC_ERROR, 
    TSC_PAUSE, 
    TSC_DOWNLOAD, 
    TSC_COMPLETE, 
    TSC_STARTPENDING, 
    TSC_STOPPENDING 
    );
  TTASK_ERROR_TYPE = (TASK_ERROR_UNKNOWN = $00, 
    TASK_ERROR_DISK_CREATE = $01, 
    TASK_ERROR_DISK_WRITE = $02, 
    TASK_ERROR_DISK_READ = $03, 
    TASK_ERROR_DISK_RENAME = $04, 
    TASK_ERROR_DISK_PIECEHASH = $05, 
    TASK_ERROR_DISK_FILEHASH = $06, 
    TASK_ERROR_DISK_DELETE = $07, 
    TASK_ERROR_DOWN_INVALID = $10, 
    TASK_ERROR_PROXY_AUTH_TYPE_UNKOWN = $20, 
    TASK_ERROR_PROXY_AUTH_TYPE_FAILED = $21, 
    TASK_ERROR_HTTPMGR_NOT_IP = $30, 
    TASK_ERROR_TIMEOUT = $40, 
    TASK_ERROR_CANCEL = $41, 
    TASK_ERROR_TP_CRASHED = $42, 
    TASK_ERROR_ID_INVALID = $43 
    );
  float = Single;

  TDownTaskInfo = packed record
    stat: TDOWN_TASK_STATUS;
    fail_code: TTASK_ERROR_TYPE;
    szFilename: array [1 .. MAX_PATH] of WideChar; 
    szReserved0: array [1 .. MAX_PATH] of WideChar;
    nTotalSize: Int64; 
    nTotalDownload: Int64; 
    fPercent: float; 
    nReserved0: Integer;
    nSrcTotal: Integer; 
    nSrcUsing: Integer; 
    nReserved1: Integer;
    nReserved2, nReserved3, nReserved4: Integer;
    nReserved5, nDonationP2P, 
    nReserved6, nDonationOrgin, 
    nDonationP2S, 
    nReserved7, nReserved8: Int64;
    nSpeed: Integer; 
    nSpeedP2S: Integer; 
    nSpeedP2P: Integer; 
    bIsOriginUsable: Boolean; 
    fHashPercent: float; 
    IsCreatingFile: Integer; 
    reserved: array [1 .. 64] of DWORD;
    procedure Init;
  end;

  TDOWN_PROXY_TYPE = (PROXY_TYPE_IE = 0, PROXY_TYPE_HTTP = 1,
    PROXY_TYPE_SOCK4 = 2, PROXY_TYPE_SOCK5 = 3, PROXY_TYPE_FTP = 4,
    PROXY_TYPE_UNKOWN = 255);
  TDOWN_PROXY_AUTH_TYPE = (PROXY_AUTH_NONE = 0, PROXY_AUTH_AUTO,
    PROXY_AUTH_BASE64, PROXY_AUTH_NTLM, PROXY_AUTH_DEGEST, PROXY_AUTH_UNKOWN);

  TDOWN_PROXY_INFO = packed record
    bIEProxy: BOOL;
    bProxy: BOOL;
    stPType: TDOWN_PROXY_TYPE;
    stAType: TDOWN_PROXY_AUTH_TYPE;
    szHost: array [1 .. 2048] of WideChar;
    nPort: Int32;
    szUser: array [1 .. 50] of WideChar;
    szPwd: array [1 .. 50] of WideChar;
    szDomain: array [1 .. 2048] of WideChar;
  end;

  TWSAPROTOCOL_INFOW = packed record
  end;

  TPWSAPROTOCOL_INFOW = ^TWSAPROTOCOL_INFOW;
  TszFileID = array [1 .. 40] of AnsiChar;
{$Z1}

type
  TXL_Init = function: BOOL; cdecl;
  TXL_UnInit = function: BOOL; cdecl;
  TXL_CreateTask = function(var stParam: TDownTaskParam): THandle; cdecl;
  TXL_DeleteTask = function(hTask: THandle): BOOL; cdecl;
  TXL_StartTask = function(hTask: THandle): Boolean; cdecl;
  TXL_StopTask = function(hTask: THandle): BOOL; cdecl;
  TXL_ForceStopTask = function(hTask: THandle): BOOL; cdecl;
  TXL_QueryTaskInfo = function(hTask: THandle; var stTaskInfo: TDownTaskInfo)
    : BOOL; cdecl; 
  TXL_QueryTaskInfoEx = function(hTask: THandle; var stTaskInfo: TDownTaskInfo)
    : BOOL; cdecl;
  TXL_DelTempFile = function(var stParam: TDownTaskParam): BOOL; cdecl;
  TXL_SetSpeedLimit = procedure(nKBps: Int32); cdecl;
  TXL_SetUploadSpeedLimit = procedure(nTcpKBps: Int32; nOtherKBps: Int32);
    cdecl;
  TXL_SetProxy = function(var stProxyInfo: TDOWN_PROXY_INFO): BOOL; cdecl;
  TXL_SetUserAgent = procedure(const pszUserAgent: PWideChar); cdecl;
  TXL_ParseThunderPrivateUrl = function(const pszThunderUrl: PWideChar;
    normalUrlBuffer: PWideChar; bufferLen: Int32): BOOL; cdecl;
  TXL_GetFileSizeWithUrl = function(const lpURL: PWideChar;
    var iFileSize: Int64): BOOL; cdecl;
  TXL_SetFileIdAndSize = function(hTask: THandle; szFileId: TszFileID;
    nFileSize: UInt64): BOOL; cdecl;
  TXL_SetAdditionInfo = function(task_id: THandle;
    sock_info: TPWSAPROTOCOL_INFOW; http_resp_buf: PAnsiChar;
    buf_len: LongInt): BOOL; cdecl;
  TXL_CreateTaskByURL = function(const url: PWideChar; const path: PWideChar;
    const filename: PWideChar; IsResume: BOOL): THandle; cdecl;
  TXL_CreateTaskByThunder = function(pszUrl: PWideChar; pszFileName: PWideChar;
    pszReferUrl: PWideChar; pszCharSet: PWideChar;
    pszCookie: PWideChar): LongInt; cdecl;

const
  xlsdk = 'xldl.dll';

var
  XL_Init: TXL_Init = nil;
  XL_UnInit: TXL_UnInit = nil;
  XL_CreateTask: TXL_CreateTask = nil;
  XL_DeleteTask: TXL_DeleteTask = nil;
  XL_StartTask: TXL_StartTask = nil;
  XL_StopTask: TXL_StopTask = nil;
  XL_ForceStopTask: TXL_ForceStopTask = nil;
  XL_QueryTaskInfo: TXL_QueryTaskInfo = nil;
  XL_QueryTaskInfoEx: TXL_QueryTaskInfoEx = nil;
  XL_DelTempFile: TXL_DelTempFile = nil;
  XL_SetSpeedLimit: TXL_SetSpeedLimit = nil;
  XL_SetUploadSpeedLimit: TXL_SetUploadSpeedLimit = nil;
  XL_SetProxy: TXL_SetProxy = nil;
  XL_SetUserAgent: TXL_SetUserAgent = nil;
  XL_ParseThunderPrivateUrl: TXL_ParseThunderPrivateUrl = nil;
  XL_GetFileSizeWithUrl: TXL_GetFileSizeWithUrl = nil;
  XL_SetFileIdAndSize: TXL_SetFileIdAndSize = nil;
  XL_SetAdditionInfo: TXL_SetAdditionInfo = nil;
  XL_CreateTaskByURL: TXL_CreateTaskByURL = nil;
  XL_CreateTaskByThunder: TXL_CreateTaskByThunder = nil;

function InitXlEngine(const ASrcFile: string): Boolean;

implementation

procedure TDownTaskParam.Init;
begin
  ZeroMemory(@self, SizeOf(TDownTaskParam));
  nReserved1 := 5;
  bReserved := FALSE;
  DisableAutoRename := FALSE;
  IsOnlyOriginal := FALSE;
  IsResume := TRUE;
end;

procedure TDownTaskInfo.Init;
begin
  ZeroMemory(@self, SizeOf(TDownTaskInfo));
  stat := TSC_PAUSE;
  fail_code := TASK_ERROR_UNKNOWN;
  fPercent := 0;
  bIsOriginUsable := FALSE;
  fHashPercent := 0;
end;

function InitXlEngine(const ASrcFile: string): Boolean;
var
  h: HMODULE;
begin
  Result := FALSE;
  h := GetModuleHandle(PChar(ASrcFile));
  if h = 0 then
    h := LoadLibrary(PChar(ASrcFile));
  if h = 0 then
    Exit;
  XL_Init := GetProcAddress(h, 'XL_Init');
  XL_UnInit := GetProcAddress(h, 'XL_UnInit');
  XL_CreateTask := GetProcAddress(h, 'XL_CreateTask');
  XL_DeleteTask := GetProcAddress(h, 'XL_DeleteTask');
  XL_StartTask := GetProcAddress(h, 'XL_StartTask');
  XL_StopTask := GetProcAddress(h, 'XL_StopTask');
  XL_ForceStopTask := GetProcAddress(h, 'XL_ForceStopTask');
  XL_QueryTaskInfo := GetProcAddress(h, 'XL_QueryTaskInfo');
  XL_QueryTaskInfoEx := GetProcAddress(h, 'XL_QueryTaskInfoEx');
  XL_DelTempFile := GetProcAddress(h, 'XL_DelTempFile');
  XL_SetSpeedLimit := GetProcAddress(h, 'XL_SetSpeedLimit');
  XL_SetUploadSpeedLimit := GetProcAddress(h, 'XL_SetUploadSpeedLimit');
  XL_SetProxy := GetProcAddress(h, 'XL_SetProxy');
  XL_SetUserAgent := GetProcAddress(h, 'XL_SetUserAgent');
  XL_ParseThunderPrivateUrl := GetProcAddress(h, 'XL_ParseThunderPrivateUrl');
  XL_GetFileSizeWithUrl := GetProcAddress(h, 'XL_GetFileSizeWithUrl');
  XL_SetFileIdAndSize := GetProcAddress(h, 'XL_SetFileIdAndSize');
  XL_SetAdditionInfo := GetProcAddress(h, 'XL_SetAdditionInfo');
  XL_CreateTaskByURL := GetProcAddress(h, 'XL_CreateTaskByURL');
  XL_CreateTaskByThunder := GetProcAddress(h, 'XL_CreateTaskByThunder');
  Result := TRUE;
end;

end.
 