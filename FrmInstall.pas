unit FrmInstall;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UnitConfig, DUIBase, DUIBitmap32, DUIContainer, DUIManager,
  DUIButton, DUIImage, DUIGraphics, DUICore, DUILabel, DUIType, UnitFuc,
  DUILabelEx, DUIConfig, DUICheck, UnitStat, UnitType;

type
  TInstallFrmRtn = (rtn_unknow, rtn_know);

  TFFrmInstall = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
  public
    
    FUIManager: TDUIManager;
    FImgBk: TDUIImage;
    FlabCaption: TDUILabelEx;
    FlabSoft: TDUILabelEx;
    FBtnKnow: TDUIButton;
    FTaskBox: TDUICheck;

    procedure UIOnClick(Sender: TObject);
    procedure UIOnRadioChanged(Sender: TObject);
  public
    FrmRtn: TInstallFrmRtn;
  end;

var
  FFrmInstall: TFFrmInstall;

implementation

{$R *.dfm}

procedure TFFrmInstall.FormCreate(Sender: TObject);
var
  rcWork: TRect;
  crChk: Cardinal;
begin
  FrmRtn := rtn_unknow;
  if (TaskList[3].Count <= 0) then
  begin
    Self.Close;
    Exit;
  end;
  Self.Caption := AppName;
  Self.Icon := Application.Icon;
  rcWork := Screen.WorkAreaRect;
  Self.SetBounds(rcWork.Right - Self.Width - 8,
    rcWork.Bottom - Self.Height - 8, Self.Width, Self.Height);

  FUIManager := TDUIManager.Create(Self);
  with FUIManager do
  begin
    IsLoading := True;

    Attach(Self.Handle, Rect(0, 0, Self.Width, Self.Height));
    FUIManager.UseBack := True;
    FUIManager.BackColor := $FFFFFFFF;
    
    FImgBk := TDUIImage.Create(FUIManager);
    FImgBk.Bitmap := LoadBmpByName('img_installbk');
    FImgBk.DrawStyle := dsGrid;
    FImgBk.GridRect := Rect(10, 40, 50, 50);
    FImgBk.SetBounds(0, 0, Width, Height);
    FImgBk.OnClick := Self.UIOnClick;
    
    with TDUIImage.Create(FUIManager) do
    begin
      Bitmap := LoadBmpByName('img_installicon');
      DoAutoSize;
      SetSite(12, (36 - Height) div 2);
    end;
    
    FlabCaption := TDUILabelEx.Create(FUIManager);
    with FlabCaption do
    begin
      Font.Name := DefaultFontName;
      Font.Color := RGBToColor($FF83A8C6);
      Font.Size := 10;
      Font.Style := [fsBold];
      Backer := FUIManager;
      Caption := '安装完成';
      DoAutoSize;
      SetSite(42, (36 - Height) div 2);
    end;
    
    FlabSoft := TDUILabelEx.Create(FUIManager);
    with FlabSoft do
    begin
      AutoSize := False;
      Font.Name := DefaultFontName;
      Font.Color := RGBToColor($FF808080);
      Font.Size := 10;
      Backer := FUIManager;
      MaxWidth := 210;
      MaxHeight := 50;
      SetBounds(50, 60, 210, 50);

      Caption := SoftInfo.softname + '已安装完成！';
    end;
    
    FBtnKnow := TDUIButton.Create(FUIManager);
    with FBtnKnow do
    begin
      BtnStateCount := 3;
      BtnImage := LoadBmpByName('btn_know');
      DoAutoSize;
      Cursor := Screen.Cursors[crHandPoint];
      SetSite(FUIManager.Width - Width - 22, FUIManager.Height - Height - 10);
      OnClick := Self.UIOnClick;
    end;

    FTaskBox := TDUICheck.Create(FUIManager);
    with FTaskBox do
    begin
      Tag := 0;
      CheckStateCount := 3;
      CheckSpliteCount := 2;
      ImgCheck := LoadBmpByName('img_check2');

      crChk := TaskList[3].Items[0].taskcolor;
      if (crChk = 0) then
        crChk := $FFC4C4C4;
      Bitmap.Font.Color := crChk;

      Checked := TaskList[3].Items[0].defcheck;
      Caption := TaskList[3].Items[0].taskname;

      DoAutoSize;
      SetSite(12, FUIManager.Height - Height - 10);
      Visible := TaskList[3].Items[0].Visible;

      OnRadioChanged := UIOnRadioChanged;
    end;

    IsLoading := False;
    Refresh;
  end;
end;

procedure TFFrmInstall.UIOnClick(Sender: TObject);
begin
  
  if Sender = FBtnKnow then
  begin
    FrmRtn := rtn_know;
    Self.Close;
  end;
end;

procedure TFFrmInstall.UIOnRadioChanged(Sender: TObject);
var
  TmpTask: TTaskInfo;
begin
  if NeedSendStat() then
  begin
    
    if (Sender = FTaskBox) then
    begin
      if FTaskBox.Tag < TaskList[4].Count then
      begin
        TmpTask := TaskList[4].Items[FTaskBox.Tag];
        statManager.PushStat(sevent_mouse, Format(
            'type=click&content=chk_task&value=%d|%s', [TmpTask.taskid,
            BoolToStr(FTaskBox.Checked)]));
      end;
    end;
  end;
end;

end.
 