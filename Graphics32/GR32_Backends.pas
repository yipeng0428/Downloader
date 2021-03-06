unit GR32_Backends;

interface

{$I GR32.inc}

uses
{$IFDEF FPC}
  LCLIntf, LCLType, Types, Graphics,
{$ELSE}
  Windows, Messages, Graphics,
{$ENDIF}
  Classes, SysUtils, GR32, GR32_Containers;

type
  ITextSupport = interface(IUnknown)
  ['{225997CC-958A-423E-8B60-9EDE0D3B53B5}']
    procedure Textout(X, Y: Integer; const Text: String); overload;
    procedure Textout(X, Y: Integer; const ClipRect: TRect; const Text: String); overload;
    procedure Textout(var DstRect: TRect; const Flags: Cardinal; const Text: String); overload;
    function  TextExtent(const Text: String): TSize;

    procedure TextoutW(X, Y: Integer; const Text: Widestring); overload;
    procedure TextoutW(X, Y: Integer; const ClipRect: TRect; const Text: Widestring); overload;
    procedure TextoutW(var DstRect: TRect; const Flags: Cardinal; const Text: Widestring); overload;
    function  TextExtentW(const Text: Widestring): TSize;
  end;

  IFontSupport = interface(IUnknown)
  ['{67C73044-1EFF-4FDE-AEA2-56BFADA50A48}']
    function GetOnFontChange: TNotifyEvent;
    procedure SetOnFontChange(Handler: TNotifyEvent);
    function GetFont: TFont;
    procedure SetFont(const Font: TFont);

    procedure UpdateFont;
    property Font: TFont read GetFont write SetFont;
    property OnFontChange: TNotifyEvent read GetOnFontChange write SetOnFontChange;
  end;

  ICanvasSupport = interface(IUnknown)
  ['{5ACFEEC7-0123-4AD8-8AE6-145718438E01}']
    function GetCanvasChange: TNotifyEvent;
    procedure SetCanvasChange(Handler: TNotifyEvent);
    function GetCanvas: TCanvas;

    procedure DeleteCanvas;
    function CanvasAllocated: Boolean;

    property Canvas: TCanvas read GetCanvas;
    property OnCanvasChange: TNotifyEvent read GetCanvasChange write SetCanvasChange;
  end;

  IDeviceContextSupport = interface(IUnknown)
  ['{DD1109DA-4019-4A5C-A450-3631A73CF288}']
    function GetHandle: HDC;

    procedure Draw(const DstRect, SrcRect: TRect; hSrc: HDC);
    procedure DrawTo(hDst: HDC; DstX, DstY: Integer); overload;
    procedure DrawTo(hDst: HDC; const DstRect, SrcRect: TRect); overload;

    property Handle: HDC read GetHandle;
  end;

  IBitmapContextSupport = interface(IUnknown)
  ['{DF0F9475-BA13-4C6B-81C3-D138624C4D08}']
    function GetBitmapInfo: TBitmapInfo;
    function GetBitmapHandle: THandle;

    property BitmapInfo: TBitmapInfo read GetBitmapInfo;
    property BitmapHandle: THandle read GetBitmapHandle;
  end;

  IPaintSupport = interface(IUnknown)
  ['{CE64DBEE-C4A9-4E8E-ABCA-1B1FD6F45924}']
    procedure ImageNeeded;
    procedure CheckPixmap;
    
  end;

  TRequireOperatorMode = (romAnd, romOr);

procedure RequireBackendSupport(TargetBitmap: TCustomBitmap32;
  RequiredInterfaces: array of TGUID;
  Mode: TRequireOperatorMode; UseOptimizedDestructiveSwitchMethod: Boolean;
  out ReleasedBackend: TCustomBackend);

procedure RestoreBackend(TargetBitmap: TCustomBitmap32; const SavedBackend: TCustomBackend);

resourcestring
  RCStrCannotAllocateDIBHandle = 'Can''t allocate the DIB handle';
  RCStrCannotCreateCompatibleDC = 'Can''t create compatible DC';
  RCStrCannotSelectAnObjectIntoDC = 'Can''t select an object into DC';

implementation

uses
  GR32_LowLevel;

procedure RequireBackendSupport(TargetBitmap: TCustomBitmap32;
  RequiredInterfaces: array of TGUID;
  Mode: TRequireOperatorMode; UseOptimizedDestructiveSwitchMethod: Boolean;
  out ReleasedBackend: TCustomBackend);
var
  I: Integer;
  Supported: Boolean;
begin
  Supported := False;
  for I := Low(RequiredInterfaces) to High(RequiredInterfaces) do
  begin
    Supported := Supports(TargetBitmap.Backend, RequiredInterfaces[I]);
    if ((Mode = romAnd) and not Supported) or
      ((Mode = romOr) and Supported) then
      Break;
  end;

  if not Supported then
  begin
    if UseOptimizedDestructiveSwitchMethod then
      TargetBitmap.SetSize(0, 0); 

    ReleasedBackend := TargetBitmap.ReleaseBackend;
    
    TargetBitmap.Backend := GetPlatformBackendClass.Create;
  end
  else
    ReleasedBackend := nil;
end;

procedure RestoreBackend(TargetBitmap: TCustomBitmap32; const SavedBackend: TCustomBackend);
begin
  if Assigned(SavedBackend) then
    TargetBitmap.Backend := SavedBackend;
end;

end.
 