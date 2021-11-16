unit mnXMLNodes;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher, zaherdirkey>
 *}

{$M+}
{$H+}
{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, Contnrs,
  mnClasses, mnUtils, mnStreams,
  mnXML, mnXMLReader, mnXMLWriter;

type
  TmnXMLNodeKind = (xmlnNormal, xmlnText, xmlnComment, xmlnCDATA);
  TmnXMLNodeState = (xmlsOpened, xmlsClosed);

  TmnXMLNodes = class;
  TmnXMLNode = class;
  TmnXMLNodesList = class;

  { TmnCustomNode }

  TmnCustomNode = class(TmnXMLObject)
  protected
    type

      { TmnXMLNodeEnumerator }

      TmnXMLNodeEnumerator = class(TObject)
      private
        FList: TmnXMLNode;
        FIndex: Integer;
      public
        constructor Create(AList: TmnXMLNode);
        function GetCurrent: TmnXMLNode;
        function MoveNext: Boolean;
        property Current: TmnXMLNode read GetCurrent;
      end;

  end;

  { TmnXMLNodesList }

  TmnXMLNodesList = class(TObjectList)
  private
    function GetItem(Index: Integer): TmnXMLNode;
    procedure SetItem(Index: Integer; const Value: TmnXMLNode);
  public
    function Find(Name:string):TmnXMLNode;
    property Items[Index: Integer]: TmnXMLNode read GetItem write SetItem; default;
  end;

  { TmnXMLNode }

  TmnXMLNode = class(TmnCustomNode)
  private
    FNameSpace: string;
    FNodes: TmnXMLNodes;
    FParent: TmnXMLNode;
    FValue: string;
    FAttributes: TmnXMLAttributes;
    FName: string;
    FKind: TmnXMLNodeKind;
    FState: TmnXMLNodeState;
    FItems: TmnXMLNodesList;
    function GetCount: Integer;
    function GetEmpty: Boolean;
    function GetItem(Index: Integer): TmnXMLNode;
  protected
  public
    constructor Create(Nodes: TmnXMLNodes; Parent: TmnXMLNode); virtual;
    destructor Destroy; override;
    function GetEnumerator: TmnCustomNode.TmnXMLNodeEnumerator; inline;
    procedure Close;
    procedure Add(Node:TmnXMLNode);
    //this will split Name to NameSpace, Name
    procedure SetName(Name: string); virtual;
    property Nodes: TmnXMLNodes read FNodes;
    property Parent: TmnXMLNode read FParent;
    property State: TmnXMLNodeState read FState;
    property Items: TmnXMLNodesList read FItems;
    property Attributes: TmnXMLAttributes read FAttributes;
    property Empty:Boolean read GetEmpty;
    property NameSpace: string read FNameSpace write FNameSpace;
    property Value: string read FValue write FValue;
    property Name: string read FName write FName;
    property Kind: TmnXMLNodeKind read FKind write FKind;
    property Count: Integer read GetCount;
    property Item[Index: Integer]: TmnXMLNode read GetItem; default;
  end;

  TmnXMLNodeOption = (
    xnoNameSpace, //Split NameSpace
    xnoTrimValue  //Trim CDATA, TEXT value
  );
  TmnXMLNodeOptions = set of TmnXMLNodeOption;

  { TmnXMLNodes }

  TmnXMLNodes = class(TmnCustomNode)
  private
    FCurrent: TmnXMLNode;
    FOptions: TmnXMLNodeOptions;
    FRoot: TmnXMLNode;
    FEnhanced: Boolean;
    function GetItems(Index: string): TmnXMLNode;
    procedure CheckClosed;
    function GetEmpty: Boolean;
  protected
    function Open(Name: string): TmnXMLNode;
    function Close(Name: string): TmnXMLNode;
    function AddAttributes(Value: string): TmnXMLNode;
    function AddText(Value: string): TmnXMLNode;
    function AddCDATA(Value: string): TmnXMLNode;
    function AddComment(Value: string): TmnXMLNode;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function GetEnumerator: TmnCustomNode.TmnXMLNodeEnumerator; inline;

    procedure LoadFromString(S: string);
    procedure LoadFromFile(AFileName: string);
    procedure LoadFromStream(AStream: TStream);

    procedure Clear;
    function GetAttribute(Name, Attribute: string; Default: string = ''): string;
    property Empty: Boolean read GetEmpty;
    property Current: TmnXMLNode read FCurrent;
    property Root: TmnXMLNode read FRoot;
    property Items[Index: string]: TmnXMLNode read GetItems; default;
    property Options: TmnXMLNodeOptions read FOptions write FOptions;
    //Enhanced = true it is useful when need to rewrite the xml data, when Enhanced = false mean we take the nodes for proceess the data, the comment will ignored and all text and cdata merged
    property Enhanced: Boolean read FEnhanced write FEnhanced default False;
  end;

  { TmnXMLNodeReader }

  TmnXMLNodeReader = class(TmnXMLReader)
  protected
    FNodes: TmnXMLNodes;
    procedure ReadOpenTag(const Name: string); override;
    procedure ReadAttributes(const Text: string); override;
    procedure ReadText(const Text: string); override;
    procedure ReadComment(const Text: string); override;
    procedure ReadCDATA(const Text: string); override;
    procedure ReadCloseTag(const Name: string); override;
  public
    constructor Create; override;
    destructor Destroy; override;
    property Nodes: TmnXMLNodes read FNodes write FNodes;
  end;

  { TmnXMLNodeWriter }

  TmnXMLNodeWriter = class(TmnXMLWriter)
  private
  end;

implementation

{ TmnCustomNode.TmnXMLNodeEnumerator }

constructor TmnCustomNode.TmnXMLNodeEnumerator.Create(AList: TmnXMLNode);
begin
  inherited Create;
  FList := Alist;
  FIndex := -1;
end;

function TmnCustomNode.TmnXMLNodeEnumerator.GetCurrent: TmnXMLNode;
begin
  Result := FList[FIndex];
end;

function TmnCustomNode.TmnXMLNodeEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FList.Count;
end;

{ TmnXMLNode }

procedure TmnXMLNode.Add(Node: TmnXMLNode);
begin
  Items.Add(Node);
end;

procedure TmnXMLNode.SetName(Name: string);
begin
  if (xnoNameSpace in Nodes.Options) and (Pos(':', Name) > 0) then
    SpliteStr(Name, ':', FNameSpace, FName)
  else
    FName := Name;
end;

procedure TmnXMLNode.Close;
begin
  FState := xmlsClosed;
end;

constructor TmnXMLNode.Create(Nodes: TmnXMLNodes; Parent: TmnXMLNode);
begin
  inherited Create;
  FNodes := Nodes;
  FParent := Parent;
  FAttributes := TmnXMLAttributes.Create();
  FItems := TmnXMLNodesList.Create;
end;

destructor TmnXMLNode.Destroy;
begin
  FreeAndNil(FAttributes);
  FreeAndNil(FItems);
  inherited;
end;

function TmnXMLNode.GetEmpty: Boolean;
begin
  Result := Items.Count = 0;
end;

function TmnXMLNode.GetCount: Integer;
begin
  Result := Items.Count;
end;

function TmnXMLNode.GetItem(Index: Integer): TmnXMLNode;
begin
  Result := Items[Index];
end;

function TmnXMLNode.GetEnumerator: TmnCustomNode.TmnXMLNodeEnumerator;
begin
  Result := TmnCustomNode.TmnXMLNodeEnumerator.Create(Self);
end;

{ TmnXMLNodeReader }

constructor TmnXMLNodeReader.Create;
begin
  inherited;
end;

destructor TmnXMLNodeReader.Destroy;
begin
  inherited;
end;

procedure TmnXMLNodeReader.ReadAttributes(const Text: string);
begin
  inherited;
  Nodes.AddAttributes(EntityDecode(Text));
end;

procedure TmnXMLNodeReader.ReadCDATA(const Text: string);
begin
  inherited;
  Nodes.AddCDATA(Text);
end;

procedure TmnXMLNodeReader.ReadCloseTag(const Name: string);
begin
  inherited;
  FNodes.Close(Name);
end;

procedure TmnXMLNodeReader.ReadComment(const Text: string);
begin
  inherited;
  Nodes.AddComment(Text);
end;

procedure TmnXMLNodeReader.ReadOpenTag(const Name: string);
begin
  inherited;
  FNodes.Open(Name);
end;

procedure TmnXMLNodeReader.ReadText(const Text: string);
begin
  inherited;
  Nodes.AddText(Text);
end;

{ TmnXMLNodesList }

function TmnXMLNodesList.Find(Name: string): TmnXMLNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Name, Items[i].Name) then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TmnXMLNodesList.GetItem(Index: Integer): TmnXMLNode;
begin
  Result := inherited Items[Index] as TmnXMLNode;
end;

procedure TmnXMLNodesList.SetItem(Index: Integer; const Value: TmnXMLNode);
begin
  inherited Items[Index] := Value;
end;

{ TmnXMLNodes }

function TmnXMLNodes.AddAttributes(Value: string): TmnXMLNode;
begin
  CheckClosed;
  FCurrent.Attributes.SetText(Value);
  Result := FCurrent;
end;

function TmnXMLNodes.AddCDATA(Value: string): TmnXMLNode;
begin
  CheckClosed;
  if Enhanced then //we add the text as node
  begin
    Result := TmnXMLNode.Create(Self, FCurrent);
    Result.FKind := xmlnCDATA;
    Result.FValue := Value;
  end
  else
  begin
    FCurrent.FValue := FCurrent.FValue + Value;
    Result := FCurrent;
  end;
end;

function TmnXMLNodes.AddComment(Value: string): TmnXMLNode;
begin
  //CheckClosed; //svg have comment not inside
  if Enhanced then //we ignore the comment if not
  begin
    Result := TmnXMLNode.Create(Self, FCurrent);
    Result.FKind := xmlnComment;
    Result.Value := Value;
  end
  else
    Result := FCurrent;
end;

function TmnXMLNodes.AddText(Value: string): TmnXMLNode;
begin
  CheckClosed;
  if xnoTrimValue in Options then
    Value := Trim(Value);
  if Enhanced then //we add the text as node
  begin
    Result := TmnXMLNode.Create(Self, FCurrent);
    Result.FKind := xmlnText;
    Result.FValue := Value;
  end
  else
  begin
    FCurrent.FValue := FCurrent.FValue + Value;
    Result := FCurrent;
  end;
end;

procedure TmnXMLNodes.CheckClosed;
begin
  if FCurrent = nil then
    raise EmnXMLException.Create('There is not tag opened');
  if FCurrent.State = xmlsClosed then
    raise EmnXMLException.Create(FCurrent.Name + ' is already close tag');
end;

procedure TmnXMLNodes.Clear;
begin
  FCurrent := nil;
  FreeAndNil(FRoot);
end;

function TmnXMLNodes.Close(Name: string): TmnXMLNode;
begin
  CheckClosed;
  FCurrent.FState := xmlsClosed;
  if FCurrent.Parent <> nil then
    FCurrent := FCurrent.Parent;
  Result := FCurrent;
end;

constructor TmnXMLNodes.Create;
begin
  inherited Create;
end;

destructor TmnXMLNodes.Destroy;
begin
  FreeAndNil(FRoot);
  inherited;
end;

function TmnXMLNodes.GetEnumerator: TmnCustomNode.TmnXMLNodeEnumerator;
begin
  Result := TmnCustomNode.TmnXMLNodeEnumerator.Create(FRoot);
end;

procedure TmnXMLNodes.LoadFromString(S: string);
var
  Reader: TmnXMLNodeReader;
begin
  Reader := TmnXMLNodeReader.Create;
  try
    Reader.Nodes := Self;
    Reader.Start;
    Reader.Parse(S);
  finally
    Reader.Free;
  end;
end;

procedure TmnXMLNodes.LoadFromFile(AFileName: string);
var
  AStream: TFileStream;
begin
  AStream := TFileStream.Create(AFileName, fmOpenRead);
  try
    LoadFromStream(AStream);
  finally
    AStream.Free;
  end;
end;

procedure TmnXMLNodes.LoadFromStream(AStream: TStream);
var
  AWrapperStream: TmnWrapperStream;
  Reader: TmnXMLNodeReader;
begin
  AWrapperStream := TmnWrapperStream.Create(AStream);
  Reader := TmnXMLNodeReader.Create(AWrapperStream, False);
  try
    Reader.Nodes := Self;
    Reader.Start;
  finally
    Reader.Free;
  end;
end;

function TmnXMLNodes.GetAttribute(Name, Attribute: string; Default: string): string;
var
  aNode: TmnXMLNode;
  aAttribute: TmnXMLAttribute;
begin
  if FRoot = nil then
    Result := Default
  else
  begin
    if FRoot.Name = Name then
      aNode := FRoot
    else
      aNode := Items[Name];
    if aNode = nil then
      Result := Default
    else
    begin
      aAttribute := aNode.Attributes.Find(Attribute);
      if aAttribute = nil then
        Result := Default
      else
        Result := aAttribute.Value;
    end;
  end;
end;

function TmnXMLNodes.GetEmpty: Boolean;
begin
  Result := (Root = nil) or (Root.Empty);
end;

function TmnXMLNodes.GetItems(Index: string): TmnXMLNode;
begin
  if FRoot <> nil then
  begin
    if SameText(FRoot.Name, Index) then
      Result := FRoot
    else
      Result := FRoot.Items.Find(Index);
  end
  else
    Result := nil;
end;

function TmnXMLNodes.Open(Name: string): TmnXMLNode;
begin
  Result := TmnXMLNode.Create(Self, FCurrent);
  Result.SetName(Name);
  if FRoot = nil then
    FRoot := Result
  else
  begin
    CheckClosed;
    FCurrent.Add(Result);
  end;
  FCurrent := Result;
end;

end.

