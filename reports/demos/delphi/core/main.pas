unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DateUtils, Math, IniFiles,
  mnrClasses, mnrLists, mnrNodes;
  //dluxdetails dluxdesign

const
  cMaxRows  = 10000;
  cMaxCells = 5;

type

  TSimpleProfiler = class(TmnrProfiler)
  private
    procedure SaveSection(vIni: TCustomIniFile; vSection: TmnrSection);
    procedure SaveSectionRow(vIni: TCustomIniFile; vID: Integer; vRow: TmnrDesignRow);
    procedure LoadSections(vIni: TCustomIniFile);
    function FileName: string;
  public
    procedure SaveReport; override;
    procedure LoadReport; override;

  end;

  TSimpleDetailsReport = class(TmnrCustomReport)
  protected
    BigPos, SubPos: Integer;
    HeaderDeatils, Details, FooterDetails: TmnrSection;
    procedure DoInitSections(vSections: TmnrSections); override;
    procedure InitLayouts(vGroups: TmnrGroups); override;
    procedure HeadersFetch(var vParams: TmnrFetch);
    procedure DetailsFetch(var vParams: TmnrFetch);
    procedure FooterDetailsFetch(var vParams: TmnrFetch);
    function DoCreateProfiler: TmnrProfiler; override;

    function DoCreateReportDesgin: ImnrReportDesigner; override;

  public
    procedure RequestMaster(vCell: TmnrCell);
    procedure RequestNumber(vCell: TmnrCell);
    procedure RequestDate(vCell: TmnrCell);
    procedure RequestName(vCell: TmnrCell);
    procedure RequestCode(vCell: TmnrCell);
    procedure RequestValue(vCell: TmnrCell);

    procedure Start; override;
  end;

  TForm1 = class(TForm)
    TestSpeedBtn: TButton;
    TestReportBtn: TButton;
    TestWriteBtn: TButton;
    DesignReportBtn: TButton;
    procedure TestSpeedBtnClick(Sender: TObject);
    procedure TestReportBtnClick(Sender: TObject);
    procedure TestWriteBtnClick(Sender: TObject);
    procedure DesignReportBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  designer;

{$R *.dfm}

procedure TForm1.DesignReportBtnClick(Sender: TObject);
begin
  DesignmnReport(TSimpleDetailsReport);
end;

procedure TForm1.TestReportBtnClick(Sender: TObject);
var
  r: TmnrCustomReport;
  t: Cardinal;
begin
  t := GetTickCount;
  r := TSimpleDetailsReport.Create;
  try
    r.Prepare;

    r.Generate;
    ShowMessage('Create in '+IntToStr(GetTickCount-t));

    t := GetTickCount;
    r.ExportCSV('c:\temp\1.csv');
    ShowMessage('Export csv in '+IntToStr(GetTickCount-t));

    t := GetTickCount;
    r.ExportHTML('c:\temp\1.html');
    ShowMessage('Export html in '+IntToStr(GetTickCount-t));

    t := GetTickCount;
  finally
    r.Free;
  end;
  ShowMessage('Free in '+IntToStr(GetTickCount-t));
end;

procedure TForm1.TestSpeedBtnClick(Sender: TObject);
var
  rs: TmnrRowNodes;
  r: TmnrRowNode;
  i, j: Integer;
  t: Cardinal;
  idx: TmnrLinkNodesListIndex;
begin
  rs := TmnrRowNodes.Create;
  t := GetTickCount;
  try
    for I := 0 to cMaxRows - 1 do
    begin
      r := rs.Add;
      for j:= 0 to cMaxCells - 1 do
      begin
        r.Add;
      end;
    end;
    ShowMessage(Format('Create %d node in %d ms', [cMaxRows*cMaxCells, GetTickCount-t]));


    t := GetTickCount;
    idx := TmnrLinkNodesListIndex.Create(rs);
    try
      ShowMessage(Format('Create index in %d ms', [GetTickCount-t]));
    finally
      t := GetTickCount;
      idx.Free;
      ShowMessage(Format('Free index in %d ms', [GetTickCount-t]));
    end;

  finally
    t := GetTickCount;
    rs.Free;
    ShowMessage(Format('Free %d node in %d ms', [cMaxRows*cMaxCells, GetTickCount-t]));
  end;
end;

procedure TForm1.TestWriteBtnClick(Sender: TObject);
var
  rep: TSimpleDetailsReport;
  r: TmnrRowNode;
  i, j: Integer;
  t: Cardinal;
  idx: TmnrLinkNodesListIndex;
begin
  rep := TSimpleDetailsReport.Create;
  t := GetTickCount;
  try
    for I := 0 to cMaxRows - 1 do
    begin
      r := rep.Items.Add;
      for j:= 0 to cMaxCells - 1 do
      begin
        r.Add;
      end;
    end;
    ShowMessage(Format('Create %d node in %d ms', [cMaxRows*cMaxCells, GetTickCount-t]));

    t := GetTickCount;
    idx := TmnrLinkNodesListIndex.Create(rep.Items);
    try
      ShowMessage(Format('Create index in %d ms', [GetTickCount-t]));
    finally
      t := GetTickCount;
      idx.Free;
      ShowMessage(Format('Free index in %d ms', [GetTickCount-t]));
    end;

  finally
    t := GetTickCount;
    rep.Free;
    ShowMessage(Format('Free %d node in %d ms', [cMaxRows*cMaxCells, GetTickCount-t]));
  end;
end;

{ TSimpleDetailsReport }

procedure TSimpleDetailsReport.InitLayouts(vGroups: TmnrGroups);
begin
  inherited;
  with vGroups do
  begin
    CreateLayout('Main', TmnrIntegerLayout, 'Master');
    CreateLayout('Main', TmnrTextLayout, 'Name');
    CreateLayout('Main', TmnrIntegerLayout, 'Number');
    CreateLayout('Main', TmnrDateTimeLayout, 'Date');
    CreateLayout('Main', TmnrTextLayout, 'Code');
    CreateLayout('Main', TmnrCurrencyLayout, 'Value');
  end;
end;

function TSimpleDetailsReport.DoCreateProfiler: TmnrProfiler;
begin
  Result := TSimpleProfiler.Create(Self);
end;

procedure TSimpleDetailsReport.DoInitSections(vSections: TmnrSections);
begin
  inherited;
  HeaderDeatils := vSections.RegisterSection('HeaderDetails', '��� �������', sciHeaderDetails, ID_SECTION_HEADERREPORT, HeadersFetch);
  Details := HeaderDeatils.Sections.RegisterSection('Details', '�������', sciDetails, ID_SECTION_DETAILS, DetailsFetch);
  FooterDetails := HeaderDeatils.Sections.RegisterSection('FooterDetails', '���� �������', sciDetails, ID_SECTION_FOOTERDETAILS, FooterDetailsFetch);

  Details.AppendDetailTotals := True;
  Details.AppendReportTotals := True;

  {with HeaderDeatils.DesignRows.Add do
  begin
    //CreateLayout(TmnrIntegerLayout, 'Master');
  end;

  with Details.DesignRows.Add do
  begin
    //Details.AppendTotals := True;
    Details.AppendSummary := True;

    //CreateLayout(TmnrTextLayout, 'Name');
    //CreateLayout(TmnrIntegerLayout, 'Number');
    //CreateLayout(TmnrDateTimeLayout, 'Date');
  //end;
  //with sec.LayoutsRows.Add do
  //begin
    //CreateLayout(TmnrTextLayout, 'Code');
    //CreateLayout(TmnrCurrencyLayout, 'Value');
  end;}
end;

function TSimpleDetailsReport.DoCreateReportDesgin: ImnrReportDesigner;
begin
  Result := TDesignerForm.Create(Application);
end;

procedure TSimpleDetailsReport.DetailsFetch(var vParams: TmnrFetch);
begin
  with vParams do
  begin
    if FetchMode=fmFirst then
      SubPos := 0
    else
      Inc(SubPos);
    if SubPos>20 then
      AcceptMode := acmEof;
  end;
end;

procedure TSimpleDetailsReport.FooterDetailsFetch(var vParams: TmnrFetch);
begin
  with vParams do
  begin
    if FetchMode<>fmFirst then
      AcceptMode := acmEof;
  end;
end;

procedure TSimpleDetailsReport.HeadersFetch(var vParams: TmnrFetch);
begin
  with vParams do
  begin
    if FetchMode=fmFirst then
      BigPos := 0
    else
      Inc(BigPos);
    if BigPos>10 then
      AcceptMode := acmEof;
  end;
end;

procedure TSimpleDetailsReport.RequestNumber(vCell: TmnrCell);
begin
  vCell.AsInteger := SubPos;
end;

procedure TSimpleDetailsReport.RequestDate(vCell: TmnrCell);
begin
  vCell.AsDateTime := IncDay(Now, RandomRange(-100, 100));
  //vCell.AsDateTime := Now;
end;

procedure TSimpleDetailsReport.RequestMaster(vCell: TmnrCell);
begin
  vCell.AsInteger := BigPos;
end;

procedure TSimpleDetailsReport.RequestName(vCell: TmnrCell);
begin
  vCell.AsString := Format('Cell %d', [0]);
  //vCell.AsString := 'Cell %d';
end;

procedure TSimpleDetailsReport.RequestCode(vCell: TmnrCell);
begin
  vCell.AsString := Format('Row = %d    Col = %d', [vCell.Row.ID, 0]);
end;

procedure TSimpleDetailsReport.RequestValue(vCell: TmnrCell);
begin
  vCell.AsCurrency := RandomRange(1, 1000) / RandomRange(6, 66);
end;

procedure TSimpleDetailsReport.Start;
begin
  inherited;
  RegisterRequest('Master', RequestMaster);
  RegisterRequest('Number', RequestNumber);
  RegisterRequest('Date', RequestDate);
  RegisterRequest('Name', RequestName);
  RegisterRequest('Code', RequestCode);
  RegisterRequest('Value', RequestValue);
end;

{ TSimpleProfiler }

function TSimpleProfiler.FileName: string;
begin
  Result := IncludeTrailingPathDelimiter( ExtractFilePath(Application.ExeName) )+ Report.ClassName +'.ini';
end;

procedure TSimpleProfiler.LoadReport;
var
  ini: TIniFile;
begin
  if FileExists(FileName) then
  begin
    ini := TIniFile.Create(FileName);
    try
      LoadSections(ini);
    finally
      ini.Free;
    end;
  end;
end;

procedure TSimpleProfiler.LoadSections(vIni: TCustomIniFile);
var
  st, cl: TStrings;
  s: string;
  i, j, k: Integer;
  sec: TmnrSection;
  c: TmnrDesignCell;
  aRow: TmnrDesignRow;

begin
  st := TStringList.Create;
  cl := TStringList.Create;
  try
    vIni.ReadSection('Sections', st);
    for I := 0 to st.Count - 1 do
    begin
      s := st[i];
      sec := Report.FindSection(s);
      if sec<>nil then
      begin
        //sec.AppendTotals := vIni.ReadBool(sec.Name, 'AppendTotals', False);
        //sec.AppendSummary := vIni.ReadBool(sec.Name, 'AppendSummary', False);

        j := 0;
        while True do
        begin
          s := Format('%s.Row%d', [sec.Name, j]);
          if not vIni.SectionExists(s) then
            Break;
          vIni.ReadSection(s, cl);
          if cl.Count<>0 then
          begin
            aRow := sec.DesignRows.Add;
            for k:= 0 to cl.Count - 1 do
            begin
              c := TmnrDesignCell.Create(aRow);
              c.Name := cl[k];
              c.Width := vIni.ReadInteger(s, cl[k], -1);
            end;
          end;
          Inc(j);
        end;
      end;
    end;
  finally
    st.Free;
    cl.Free;
  end;
end;

procedure TSimpleProfiler.SaveReport;
var
  ini: TIniFile;
  s: TmnrSection;
begin
  if FileExists(FileName) then
    DeleteFile(FileName);
  ini := TIniFile.Create(FileName);
  try
    s := Report.Sections.First;
    while s<>nil do
    begin
      SaveSection(ini, s);
      s := s.Next;
    end;
  finally
    ini.Free;
  end;
end;

procedure TSimpleProfiler.SaveSection(vIni: TCustomIniFile; vSection: TmnrSection);
var
  s: TmnrSection;
  r: TmnrDesignRow;
  i: Integer;
begin
  vIni.WriteString('Sections', vSection.Name, vSection.Caption);
  //vIni.WriteBool(vSection.Name, 'AppendTotals', vSection.AppendTotals);
  //vIni.WriteBool(vSection.Name, 'AppendSummary', vSection.AppendSummary);

  i := 0;
  r := vSection.DesignRows.First;
  while r<>nil do
  begin
    SaveSectionRow(vIni, i, r);
    r := r.Next;
  end;
  
  s := vSection.Sections.First;
  while s<>nil do
  begin
    SaveSection(vIni, s);
    s := s.Next;
  end;
end;

procedure TSimpleProfiler.SaveSectionRow(vIni: TCustomIniFile; vID: Integer; vRow: TmnrDesignRow);
var
  sec: string;
  c: TmnrDesignCell;
begin
  sec := Format('%s.Row%d', [vRow.Section.Name, vID]);
  c := vRow.First;
  while c<>nil do
  begin
    vIni.WriteInteger(Sec, c.Name, c.Width);
    c := c.Next;
  end;
end;

initialization
  Randomize;
  //SetReportDesignerClass(TReportDesigner);

end.
