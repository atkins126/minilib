unit ntvImgBtns;

interface

uses
  Messages, SysUtils, Variants, Classes, Graphics, Themes, ImgList,
  Controls, StdCtrls, Forms;

type
  TntvImgBtnStyle = (ibsNormal, ibsToolbar);

  { TntvImgBtn }

  TntvImgBtn = class(TGraphicControl)
  private
    FCaption: TCaption;
    FDown: boolean;
    FChecked: Boolean;
    FAutoCheck: Boolean;
    FImageIndex: TImageIndex;
    FImages: TImageList;
    FImageChangeLink: TChangeLink;
    FStyle: TntvImgBtnStyle;
    FActive: Boolean;
    procedure SetDown(Value: Boolean);
    procedure SetCaption(Value: TCaption);
    procedure SetChecked(const Value: Boolean);
    procedure SetImageIndex(const Value: TImageIndex);
    procedure SetImages(const Value: TImageList);
    procedure SetStyle(const Value: TntvImgBtnStyle);
    procedure SetActive(const Value: Boolean);

    procedure ImageListChange(Sender: TObject);
  protected
    procedure MouseLeave; override;
    procedure MouseEnter; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    property Down: Boolean read FDown write SetDown;
    property Active: Boolean read FActive write SetActive;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure Click; override;
    property Checked: Boolean read FChecked write SetChecked;
  published
    property Action;
    property Caption: TCaption read FCaption write SetCaption;
    property Images: TImageList read FImages write SetImages;
    property ImageIndex: TImageIndex read FImageIndex write SetImageIndex default -1;
    property Style: TntvImgBtnStyle read FStyle write SetStyle;
    property BidiMode;
    property ParentBidiMode;
    property Anchors;
    property Align;
    property Font;
    property Color;
    property DragCursor;
    property DragMode;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property AutoCheck: Boolean read FAutoCheck write FAutoCheck;
  end;

implementation

uses
  Types, GraphType;

procedure TntvImgBtn.SetDown(Value: Boolean);
begin
  if FDown <> Value then
  begin
    FDown := Value;
    Invalidate;
  end;
end;

procedure TntvImgBtn.SetCaption(Value: TCaption);
begin
  if FCaption <> Value then
  begin
    FCaption := Value;
    Invalidate;
  end;
end;

procedure TntvImgBtn.MouseLeave;
begin
  inherited;
  if not (csDesigning in ComponentState) then
    if Style = ibsToolbar then
    begin
      Active := False;
    end;
end;

procedure TntvImgBtn.MouseEnter;
begin
  inherited;
  if Style = ibsToolbar then
    Active := True;
end;

procedure TntvImgBtn.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Down := True;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TntvImgBtn.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  PT: TPoint;
begin
  if MouseCapture then
  begin
    PT.X := X;
    PT.Y := Y;
    if PtInRect(ClientRect, PT) then
      Down := True
    else
      Down := False;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TntvImgBtn.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Down := False;
  inherited MouseUp(Button, Shift, X, Y);
end;

constructor TntvImgBtn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csSetCaption, csClickEvents, csDoubleClicks];
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := @ImageListChange;
  Width := 60;
  Height := 22;
end;

procedure TntvImgBtn.DblClick;
begin
  Click;
  inherited;
end;

destructor TntvImgBtn.Destroy;
begin
  FreeAndNil(FImageChangeLink);
  inherited Destroy;
end;

procedure TntvImgBtn.Paint;
var
  X, Y: integer;
  aImageWidth: Integer;
  aCaptionRect, aRect: TRect;
  procedure DrawButtonText(TextBounds: TRect);
  var
    TS: TTextStyle;
  begin
    with Canvas do
    begin
      Brush.Style := bsClear;
      //InitMemory(TS, SizeOf(TS));
      with TS do
      begin
        Alignment := BidiFlipAlignment(taLeftJustify, UseRightToLeftAlignment);
        WordBreak := False;
        SingleLine:= True;
        Clipping := True;
        ShowPrefix := False;
        SystemFont := False;
        RightToLeft := UseRightToLeftReading;
        ExpandTabs := True;
      end;

      if not Enabled then
      begin
        Font.Color := clBtnShadow;
        Canvas.TextRect(TextBounds, TextBounds.Left, TextBounds.Top, Caption, TS);
      end
      else
        Canvas.TextRect(TextBounds, TextBounds.Left, TextBounds.Top, Caption, TS);
    end;
  end;
begin
  inherited;
  aRect := ClientRect;
  if Active then
  begin
    ThemeServices.DrawElement(Canvas.Handle, ThemeServices.GetElementDetails(ttbButtonHot), aRect);
    //Canvas.Pen.Color := clHotLight;
    //Canvas.Frame(aRect);
  end;

  InflateRect(aRect, -1, -1);

  if ((Images <> nil) and (ImageIndex >= 0)) then
    aImageWidth := Images.Width
  else
    aImageWidth := aRect.Bottom - aRect.Top;

  aCaptionRect := aRect;
  if Caption <> '' then
  begin
    if UseRightToLeftAlignment then
    begin
      aCaptionRect.Right := aCaptionRect.Right - aImageWidth;
      aRect.Left := aCaptionRect.Right;
    end
    else
    begin
      aCaptionRect.Left := aCaptionRect.Left + aImageWidth;
      aRect.Right := aCaptionRect.Left;
    end;
    if Down then
      OffsetRect(aCaptionRect, 1, 1);
    DrawButtonText(aCaptionRect);
  end;

  if aImageWidth <> 0 then
  begin
    if (FImages <> nil) and (FImageIndex >= 0) then
    begin
      if Down then
        OffsetRect(aRect, 1, 1);
      x := aRect.Left + ((aRect.Right - aRect.Left) div 2) - (FImages.Width div 2);
      y := aRect.Top + ((aRect.Bottom - aRect.Top) div 2) - (FImages.Height div 2);
      if Active and Enabled then
        Images.Draw(Canvas, X, Y, ImageIndex, gdeShadowed)
      else
        Images.Draw(Canvas, X, Y, ImageIndex, Enabled);
    end
  end;
end;

procedure TntvImgBtn.Click;
var
  Pt: TPoint;
begin
  inherited;
  if PopupMenu <> nil then
  begin
    Pt.X := BoundsRect.Left;
    Pt.Y := BoundsRect.Bottom;
    Pt := Parent.ClientToScreen(Pt);
    PopupMenu.Popup(Pt.X, Pt.Y);
  end;
end;

procedure TntvImgBtn.SetChecked(const Value: Boolean);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    Invalidate;
  end;
end;

procedure TntvImgBtn.SetImageIndex(const Value: TImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := Value;
    Invalidate;
  end;
end;

procedure TntvImgBtn.SetImages(const Value: TImageList);
begin
  if FImages = Value then
    exit;

  if FImages <> nil then
  begin
    FImages.UnRegisterChanges(FImageChangeLink);
    FImages.RemoveFreeNotification(Self);
  end;
  FImages := Value;
  if FImages <> nil then
  begin
    FImages.RegisterChanges(FImageChangeLink);
    FImages.FreeNotification(Self);
  end;
end;

procedure TntvImgBtn.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
  begin
    FImages := nil;
  end;
end;

procedure TntvImgBtn.SetStyle(const Value: TntvImgBtnStyle);
begin
  FStyle := Value;
end;

procedure TntvImgBtn.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    Invalidate;
  end;
end;

procedure TntvImgBtn.ImageListChange(Sender: TObject);
begin
  Invalidate;
end;

end.