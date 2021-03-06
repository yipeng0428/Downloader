unit UnitStat;

interface

uses
  Windows, Classes, SysUtils, EncdDecd, UnitFuc, SyncObjs,
  Generics.Collections, Clipbrd;

type
  
  TStatEvent = (sevent_signup, sevent_signoff, sevent_error, sevent_info,
    sevent_window, sevent_mouse, sevent_keyboard);
  
const
  TStatEventString: array [0 .. 6] of string = ('signup', 'signoff', 'error',
    'info', 'window', 'mouse', 'keyboard');

type
  
  TCriticalClass = class
  protected
    FCri: TCriticalSection;
  public
    procedure EnterCri();
    procedure LeaveCri();
    function TryEnterCri(): Boolean;
  public
    constructor Create(); virtual;
    destructor Destroy(); override;
  end;

  TStatData = record
    event: TStatEvent;
    data: string;
  end;

  TStatDataList = TList<TStatData>;

  TStatManager = class;

  TStatThread = class(TThread)
  private
    FManager: TStatManager;
    FBWorking: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(Owner: TStatManager);
    property bWorking: Boolean read FBWorking;
  end;
  
  TStatManager = class(TCriticalClass)
  private
    FUserId: string;
    FToken: string;
    FSession: string; 
    FStatList: TStatDataList;
    FThread: TStatThread;
  protected
    function GetStatCount(): Integer;
  public
    constructor Create(); override;
    destructor Destroy(); override;
    
    function SendStat(event: TStatEvent; data: string): string;
    
    function PushStat(event: TStatEvent; data: string): Integer;
    
    function PopStat(var stat: TStatData): Boolean;
    
    function StartStat(): Boolean;
    
    procedure StopStat(bForce: Boolean = False);
    
    function WaitStatStop(maxTime: Integer = -1): Boolean;

    property userid: string read FUserId write FUserId;
    property token: string read FToken write FToken;
    property Session: string read FSession write FSession;
  end;

const
  
  statUrl: string = 'http://statapi.jiekou.zheguow.com/stat.php';

var
  statManager: TStatManager = nil;
  
function NeedSendStat(): Boolean;

implementation

uses
  UnitConfig;

function NeedSendStat(): Boolean;
begin
  Result := (bDebugReport) and Assigned(statManager);
end;

constructor TCriticalClass.Create;
begin
  FCri := TCriticalSection.Create;
end;

destructor TCriticalClass.Destroy;
begin
  if Assigned(FCri) then
    FreeAndNil(FCri);
  inherited;
end;

procedure TCriticalClass.EnterCri;
begin
  if Assigned(FCri) then
    FCri.Enter;
end;

procedure TCriticalClass.LeaveCri;
begin
  if Assigned(FCri) then
    FCri.Leave;
end;

function TCriticalClass.TryEnterCri: Boolean;
begin
  if Assigned(FCri) then
    Result := FCri.TryEnter
  else
    Result := False;
end;

constructor TStatManager.Create;
begin
  inherited;
  FStatList := TStatDataList.Create;
  FThread := nil;
end;

destructor TStatManager.Destroy;
begin
  FreeAndNil(FStatList);
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FreeAndNil(FThread);
  end;
  inherited;
end;

function TStatManager.GetStatCount: Integer;
begin
  EnterCri;
  try
    if not Assigned(FStatList) then
      Exit;
    Result := FStatList.Count;
  finally
    LeaveCri;
  end;
end;

function TStatManager.PopStat(var stat: TStatData): Boolean;
begin
  Result := False;
  EnterCri;
  try
    if Assigned(FStatList) and (FStatList.Count > 0) then
    begin
      stat := FStatList.Items[0];
      FStatList.Delete(0);
      Result := True;
    end;
  finally
    LeaveCri;
  end;
end;

function TStatManager.PushStat(event: TStatEvent; data: string): Integer;
var
  stat: TStatData;
begin
  EnterCri;
  try
    if not Assigned(FStatList) then
      Exit;
    stat.event := event;
    stat.data := data;

    Result := FStatList.Add(stat);
  finally
    LeaveCri;
  end;
end;

function TStatManager.SendStat(event: TStatEvent; data: string): string;
var
  postStr: string;
begin

  postStr := Format('session=%s&userid=%s&time=%s&token=%s&event=%s&data=%s',
    [FSession, FUserId, FormatDateTime('YYYY-MM-DD hh:mm:ss', Now()), FToken,
    TStatEventString[Integer(event)], EncdDecd.EncodeString(data)]);

  Result := PostWebString(statUrl, postStr, nil, False);
end;

function TStatManager.StartStat: Boolean;
begin
  if Assigned(FThread) and (not FThread.Terminated) then
  begin
    Result := True;
    Exit;
  end;
  FThread := TStatThread.Create(Self);
  Result := Assigned(FThread);
end;

procedure TStatManager.StopStat(bForce: Boolean);
begin
  if Assigned(FThread) then
  begin
    if bForce then
    begin
      TerminateThread(FThread.Handle, 0);
      FreeAndNil(FThread);
    end
    else
      FThread.Terminate;
  end;
end;

function TStatManager.WaitStatStop(maxTime: Integer): Boolean;
var
  dwStart: Cardinal;
  nCount: Integer;
begin
  Result := False;
  dwStart := GetTickCount;
  while True do
  begin
    if ((maxTime = -1) or (GetTickCount - dwStart < maxTime)) then 
    begin
      nCount := GetStatCount();
      if (nCount = 0) and Assigned(FThread) then
      begin
        if not FThread.Terminated then
          FThread.Terminate;
        if (not FThread.bWorking) then
        begin
          Result := True;
          Exit;
        end;
      end;
    end
    else
      Exit;
    Sleep(400);
  end;
end;

constructor TStatThread.Create(Owner: TStatManager);
begin
  FreeOnTerminate := True;
  FManager := Owner;
  FBWorking := False;
  inherited Create(False);
end;

procedure TStatThread.Execute;
var
  stat: TStatData;
begin
  inherited;
  while (not Terminated) do
  begin
    try
      if FManager.PopStat(stat) then
      begin
        FBWorking := True;
        try
          FManager.SendStat(stat.event, stat.data);
        finally
          FBWorking := False;
        end;
      end;
    except
    end;
    Sleep(400);
  end;
end;

end.
 