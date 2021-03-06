unit DUITaskItem;

interface

uses
  Windows, Classes, SysUtils, DUIBase, DUIContainer, DUICore, DUIConfig,
  DUIType, DUIImage, DUICheck, DUILabelEx, DUIBitmap32, Graphics, UnitConfig;

type
  TDUITaskItem = class(TDUIContainer)
  private
    
    FbShowCheckText: Boolean;

    procedure SetIcon(Value: IDUIBitmap32);
    function GetIcon(): IDUIBitmap32;
    procedure SetCheckImg(Value: IDUIBitmap32);
    function GetCheckImg(): IDUIBitmap32;
    procedure SetTitle(Value: string);
    function GetTitle(): string;
    procedure SetTitleTip(Value: string);
    function GetTitleTip(): string;
    procedure SetChecked(Value: Boolean);
    function GetChecked(): Boolean;
  protected
  public
    FTitleTip: TDUILabelEx;
    FIcon: TDUIImage;
    FIconSize: TSize;
    FCheck: TDUICheck;
    FTitle: TDUILabelEx;
    FTitleFixX, FTitleFixY: Integer;
    constructor Create(AOwner: TComponent; bShowCheckText: Boolean = False);
    destructor Destroy; override;
    
    procedure Redraw(); overload; override;
    
    property Icon: IDUIBitmap32 read GetIcon write SetIcon;
    property CheckImg: IDUIBitmap32 read GetCheckImg write SetCheckImg;
    property Title: string read GetTitle write SetTitle;
    property TitleTip: string read GetTitleTip write SetTitleTip;
    property Checked: Boolean read GetChecked write SetChecked;

    property ShowCheckText: Boolean read FbShowCheckText write FbShowCheckText;
  published
  end;

implementation

constructor TDUITaskItem.Create(AOwner: TComponent; bShowCheckText: Boolean);
begin
  inherited Create(AOwner);

  FbShowCheckText := bShowCheckText;
  
  FTitleFixX := 2;
  FTitleFixY := 2;//6;
  
  //SetBounds(0, 0, 156, 56);
  SetBounds(0, 0, 126, 55);

  FIconSize.cx := 40;
  FIconSize.cy := 40;
  FIcon := TDUIImage.Create(Self);
  FIcon.SetBounds(0, (Height - FIconSize.cy) div 2, FIconSize.cx, FIconSize.cy);
  //FIcon.SetBounds(0, (Height - FIconSize.cy) div 2, 40, 40);

  FCheck := TDUICheck.Create(Self);
  FCheck.CheckStateCount := 3;
  FCheck.CheckSpliteCount := 2;
  FCheck.Checked := True;
  if (FbShowCheckText) then
  begin
    FCheck.Caption := '������װ';
    FCheck.Bitmap.Font.Name := DefaultFontName;
    FCheck.Bitmap.Font.Color := ChkTipColor;
  end;

  FTitle := TDUILabelEx.Create(Self);
  if Assigned(Self.Owner) and (Self.Owner is TDUIContainer) then
    FTitle.Backer := Self.Owner as TDUIContainer;
  FTitle.Font.Name := DefaultFontName;
  FTitle.Font.Size := 9;
  //FTitle.Font.Style := [fsBold];
  FTitle.Font.Color := $323232;//RGBToColor(ChkCapColor);

  FTitleTip := TDUILabelEx.Create(Self);
  FTitleTip.Backer := FTitle.Backer;
  FTitleTip.Font.Name := DefaultFontName;
  FTitleTip.Font.Size := 9;
  FTitleTip.Font.Color := $767676;//RGBToColor(ChkTipColor);
end;

destructor TDUITaskItem.Destroy;
begin
  inherited;
end;

function TDUITaskItem.GetChecked: Boolean;
begin
  Result := FCheck.Checked;
end;

function TDUITaskItem.GetCheckImg: IDUIBitmap32;
begin
  Result := FCheck.ImgCheck;
end;

function TDUITaskItem.GetIcon: IDUIBitmap32;
begin
  Result := FIcon.Bitmap;
end;

function TDUITaskItem.GetTitle: string;
begin
  Result := FTitle.Caption;
end;

function TDUITaskItem.GetTitleTip: string;
begin
  Result := FTitleTip.Caption;
end;

procedure TDUITaskItem.Redraw;
begin
  if (FbShowCheckText) then
  begin
    FTitle.SetSite(FIcon.Right + FTitleFixX, FIcon.Top - 2);
    FTitleTip.SetSite(FIcon.Right + FTitleFixX,
      FIcon.Top + (FIcon.Height - FTitleTip.Height) div 2);
  end
  else
  begin
    //FTitle.SetSite(FIcon.Right + FTitleFixX, FIcon.Top + FTitleFixY);
    FTitle.SetSite(FIcon.Right + FTitleFixX, FIcon.Top + FTitleFixY);
    //FTitleTip.SetSite(FIcon.Right + FTitleFixX,
    //  FIcon.Bottom - FTitleFixY - FTitleTip.Height);
    FTitleTip.SetSite(FIcon.Right + FTitleFixX,
      FIcon.Top + FTitleFixY + 21);
  end;
  inherited;
end;

procedure TDUITaskItem.SetChecked(Value: Boolean);
begin
  FCheck.Checked := Value;
end;

procedure TDUITaskItem.SetCheckImg(Value: IDUIBitmap32);
begin
  FCheck.ImgCheck := Value;
  FCheck.DoAutoSize;
  if (FbShowCheckText) then
    FCheck.SetSite(FIcon.Right + FTitleFixX, FIcon.Bottom - FCheck.Height + 2)
  else
    FCheck.SetSite(FIcon.Right - FCheck.Width, FIcon.Bottom - FCheck.Height);
end;

procedure TDUITaskItem.SetIcon(Value: IDUIBitmap32);
begin
  FIcon.Bitmap := Value;
end;

procedure TDUITaskItem.SetTitle(Value: string);
begin
  FTitle.Caption := Value;
end;

procedure TDUITaskItem.SetTitleTip(Value: string);
begin
  FTitleTip.Caption := Value;
end;

end.
 