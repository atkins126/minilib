unit mnClasses;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey
 *}

{$IFDEF FPC}
{$MODE delphi}
{$modeswitch functionreferences}{$modeswitch anonymousfunctions}
{$WARN 5024 off : Parameter "$1" not used}
{$ENDIF}
{$M+}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Types, DateUtils,
  Generics.Collections, Contnrs;

type

  {$IFDEF FPC} //*Temporary, To be compatiple with Delphi
  TProc = Reference to procedure;
  TProc<T> = reference to procedure (Arg1: T);
  TProc<T1,T2> = reference to procedure (Arg1: T1; Arg2: T2);
  TProc<T1,T2,T3> = reference to procedure (Arg1: T1; Arg2: T2; Arg3: T3);
  TProc<T1,T2,T3,T4> = reference to procedure (Arg1: T1; Arg2: T2; Arg3: T3; Arg4: T4);
  {$endif}

  { TmnObject }

  TmnObject = class(TObject)
  protected
    procedure Created; virtual;
  public
    procedure AfterConstruction; override;
  end;

  TmnInterfacedPersistent = class(TInterfacedPersistent)
  protected
    procedure Created; virtual;
  public
    procedure AfterConstruction; override;
  end;

  TmnRefInterfacedPersistent = class(TmnInterfacedPersistent)
  protected
    FRefCount: Integer;

    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
  end;

  { TmnObjectList }

  //USAGE Delphi: TMyObjectList = class(TmnObjectList<TMyObject>)
  //USAGE FPC: TMyObjectList = class(specialize TmnObjectList<TMyObject>)

  {$ifdef FPC}
  TmnObjectList<_Object_> = class(TObjectList)
  {$else}
  TmnObjectList<_Object_: class> = class(TObjectList<_Object_>)
  {$endif}
  private
    function GetItem(Index: Integer): _Object_;
    procedure SetItem(Index: Integer; AObject: _Object_);
  protected
    type

      { TmnObjectListEnumerator }

      TmnObjectListEnumerator = class(TObject)
      private
        FList: TmnObjectList<_Object_>;
        FIndex: Integer;
      public
        constructor Create(AList: TmnObjectList<_Object_>);
        function GetCurrent: _Object_; inline;
        function MoveNext: Boolean; inline;
        property Current: _Object_ read GetCurrent;
      end;

    function _AddRef: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
    function _Release: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};

    {$ifdef FPC}
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
    {$else}
    procedure Notify(const Value: _Object_; Action: TCollectionNotification); override;
    {$endif}
    //override this function of u want to check the item or create it before returning it
    {$H-}procedure Removing(Item: _Object_); virtual;{$H+}
    {$H-}procedure Added(Item: _Object_); virtual;{$H+}


    //* Belal: If both Left and Right is eaual the orignal sort swap it, we do not want to swapt it
    //* Thanks to Belal
    function Compare(Left, Right: _Object_): Integer; virtual;
    procedure QuickSortItems(iLo, iHi: Integer);

    procedure Created; virtual;
    function RequireItem: _Object_; virtual;
  public
    function GetEnumerator: TmnObjectListEnumerator; inline;
    function QueryInterface({$ifdef FPC}constref{$else}const{$endif} iid : TGuid; out Obj):HResult; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
    procedure AfterConstruction; override;
    function Add(Item: _Object_): Integer;
    procedure Insert(Index: Integer; Item: _Object_);
    function Extract(Item: _Object_): _Object_;
    function IndexOfObject(Item: TObject): Integer;
    {$ifdef FPC} //not now
    function Require(Index: Integer): _Object_;
    {$endif}
    function Peek(Index: Integer): _Object_;

    procedure QuickSort; virtual;

    property Items[Index: Integer]: _Object_ read GetItem write SetItem; default;
    function Last: _Object_;
    function First: _Object_;
    //procedure Clear; {$ifdef FPC} override; {$else} virtual; {TODO talk with belal} {$endif}
  end;

    { TmnNamedObjectList }

    TmnNamedObject = class(TmnObject)
    private
      FName: string;
    protected
      procedure SetName(const Value: string); virtual;
    public
      property Name: string read FName write SetName;
    end;

    //USAGE: TMyNamedObjectList = class(TmnNamedObjectList<TMyNamedObject>)

    TmnNamedObjectList<_Object_: TmnNamedObject> = class(TmnObjectList<_Object_>)
    private
      FDicSize: Integer;
      FDic: TDictionary<string, _Object_>;

    protected
      procedure Created; override;
      {$ifdef FPC}
      procedure Notify(Ptr: Pointer; Action: TListNotification); override;
      {$else}
      procedure Notify(const Value: _Object_; Action: TCollectionNotification); override;
      {$endif}
    public
      //Set DicSize to 0 for not creating hashing list
      //if you use hashing list, you need to assign name to object on creation not after adding it to the list
      constructor Create(ADicSize: Integer = 1024; FreeObjects : boolean = True); overload;
      destructor Destroy; override;
      procedure AfterConstruction; override;
      function Find(const Name: string): _Object_;
      function IndexOfName(vName: string): Integer;
      {$ifdef FPC} //not now
      procedure Clear; override;
      {$endif}
      property Item[const Index: string]: _Object_ read Find;
    end;

    { TmnNameValueObjectList }

    TmnNameValueObject = class(TmnNamedObject)
    private
      FValue: string;
    public
      procedure Assign(FromObject: TObject); virtual;
      constructor Create(const vName: string; const AValue: string = ''); virtual; //must be virtual for generic function
      constructor CreateFrom(FromObject: TmnNameValueObject);
      property Value: string read FValue write FValue;
    end;

    //USAGE: TMyNameValueObjectList = class(TmnNameValueObjectList<TMyNameValueObject>)

    TmnNameValueObjectList<_Object_: TmnNameValueObject> = class(TmnNamedObjectList<_Object_>)
    private
      FAutoRemove: Boolean;
      function GetValues(Index: string): string;
      procedure SetValues(Index: string; AValue: string);
    public
      function Add(Name, Value: string): _Object_; overload;
      property Values[Index: string]: string read GetValues write SetValues; default;
      property AutoRemove: Boolean read FAutoRemove write FAutoRemove;
    end;

    {$ifdef FPC}

    { INamedObject }

    INamedObject = Interface
    ['{E8E58D2B-122D-4EA4-9A1A-BC9EE883D957}']
      function GetName: string;
      property Name: string read GetName;
    end;

    { TINamedObjects }

    TINamedObjects<T: INamedObject> = class(TmnObjectList<T>)
    public
      function Find(const AName: string): T;
      function IndexOfName(AName: string): Integer;
    end;

    {$endif}

implementation

function TmnObjectList<_Object_>.GetItem(Index: Integer): _Object_;
begin
  Result := _Object_(inherited Items[Index]);
end;

procedure TmnObjectList<_Object_>.SetItem(Index: Integer; AObject: _Object_);
begin
  inherited Items[Index] := AObject;
end;

function TmnObjectList<_Object_>.Last: _Object_;
begin
  if Count<>0 then
    Result := _Object_(inherited Last)
  else
    Result := nil;
end;

{$ifdef FPC}
procedure TmnObjectList<_Object_>.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if (Action in [lnExtracted, lnDeleted]) then
    Removing(_Object_(Ptr));
  inherited;
  if (Action = lnAdded) then
    Added(_Object_(Ptr));
end;
{$else}
procedure TmnObjectList<_Object_>.Notify(const Value: _Object_; Action: TCollectionNotification);
begin
  if (Action in [cnExtracted, cnRemoved]) then
    Removing(Value);
  inherited;
  if (Action = cnAdded) then
    Added(Value);
end;
{$endif}

{$ifdef FPC} //not now
function TmnObjectList<_Object_>.Require(Index: Integer): _Object_;
begin
  if (Index < Count) then
    Result := Items[Index]
  else
  begin
    Count := Index + 1;
    Result := nil;
  end;

  if Result = nil then
  begin
    Result := RequireItem;
    Put(Index, Result);
  end;
end;
{$endif}

function TmnObjectList<_Object_>.Peek(Index: Integer): _Object_;
begin
  if (Index < Count) then
    Result := Items[Index]
  else
    Result := nil;
end;

function TmnObjectList<_Object_>._AddRef: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
begin
  Result := 0;
end;

function TmnObjectList<_Object_>._Release: Integer; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
begin
  Result := 0;
end;

procedure TmnObjectList<_Object_>.Removing(Item: _Object_);
begin

end;

function TmnObjectList<_Object_>.QueryInterface({$ifdef FPC}constref{$else}const{$endif} iid : TGuid; out Obj): HResult; {$ifdef WINDOWS}stdcall{$else}cdecl{$endif};
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

procedure TmnObjectList<_Object_>.Added(Item: _Object_);
begin
end;

function TmnObjectList<_Object_>.Add(Item: _Object_): Integer;
begin
  Result := inherited Add(Item);
end;

function TmnObjectList<_Object_>.IndexOfObject(Item: TObject): Integer;
begin
  if Item is TClass(_Object_) then
    Result := IndexOf(_Object_(Item))
  else
    Result := -1;
end;

procedure TmnObjectList<_Object_>.Insert(Index: Integer; Item: _Object_);
begin
  inherited Insert(Index, Item);
end;

function TmnObjectList<_Object_>.Extract(Item: _Object_): _Object_;
begin
  Result := _Object_(inherited Extract(Item));
end;

function TmnObjectList<_Object_>.First: _Object_;
begin
  if Count<>0 then
    Result := _Object_(inherited First)
  else
    Result := nil;
end;

procedure TmnObjectList<_Object_>.QuickSort;
begin
  if Count<>0 then
    QuickSortItems(0, Count - 1);
end;

procedure TmnObjectList<_Object_>.QuickSortItems(iLo, iHi: Integer);
var
  Lo, Hi, Md: integer;
  p: _Object_;
begin
  Lo := iLo;
  Hi := iHi;
  Md := (Lo + Hi) div 2;
  p := Items[ Md ];
  repeat

    while (Lo < Md) and (Compare(Items[Lo], p) < 0) do
		  Inc(Lo);
    while (Hi > Md) and (Compare(Items[Hi], p) > 0) do
		  Dec(Hi);

    if Lo <= Hi then
    begin
      if (Lo<>Hi) then
      begin
        //Swap(Lo, Hi);
        if Compare(Items[Lo], Items[Hi]) <> 0 then
          Exchange(Lo, Hi);
      end;
      Inc(Lo);
      Dec(Hi);
    end;
  until Lo > Hi;
  if Hi > iLo then
	  QuickSortItems(iLo, Hi);
  if Lo < iHi then
	  QuickSortItems(Lo, iHi);
end;

function TmnObjectList<_Object_>.Compare(Left, Right: _Object_): Integer;
begin
  Result := 0;
  raise ENotImplemented.Create(ClassName + '.Compare');
end;

procedure TmnObjectList<_Object_>.Created;
begin
end;

{procedure TmnObjectList<_Object_>.Clear;
begin
  inherited Create;
end;}

function TmnObjectList<_Object_>.RequireItem: _Object_;
begin
  Result := nil;
end;

function TmnObjectList<_Object_>.GetEnumerator: TmnObjectListEnumerator;
begin
  Result := TmnObjectListEnumerator.Create(Self);
end;

procedure TmnObjectList<_Object_>.AfterConstruction;
begin
  inherited;
  Created;
end;

{ TmnNamedObjectList }

procedure TmnNamedObjectList<_Object_>.Created;
begin
  inherited;
end;

procedure TmnNamedObjectList<_Object_>.AfterConstruction;
begin
  inherited;
  if FDicSize > 0 then
    FDic := TDictionary<string, _Object_>.Create(FDicSize);
end;

destructor TmnNamedObjectList<_Object_>.Destroy;
begin
  FreeAndNil(FDic);
  inherited;
end;

{$ifdef FPC} //not now
procedure TmnNamedObjectList<_Object_>.Clear;
begin
  inherited;
  if FDic <> nil then //because there is a clear in Destroy
    FDic.Clear;
end;
{$endif}

function  TmnNamedObjectList<_Object_>.Find(const Name: string): _Object_;
var
  i: integer;
begin
  if FDic <> nil then
    FDic.TryGetValue(Name.ToLower, Result)
  else
  begin
    Result := nil;
		if Name <> '' then
      for i := 0 to Count - 1 do
      begin
        if SameText(Items[i].Name, Name) then
        begin
          Result := Items[i];
          break;
        end;
      end;
  end;
end;

function TmnNamedObjectList<_Object_>.IndexOfName(vName: string): Integer;
var
  t: _Object_;
begin
  t := Find(vName);
  if t<>nil then
    Result := IndexOf(t)
  else
    Result := -1;
end;

{
var
  i: integer;
begin

  Result := -1;
  if vName <> '' then
    for i := 0 to Count - 1 do
    begin
      if SameText(Items[i].Name, vName) then
      begin
        Result := i;
        break;
      end;
    end;
end;
}

{$ifdef FPC}
procedure TmnNamedObjectList<_Object_>.Notify(Ptr: Pointer; Action: TListNotification);
{$else}
procedure TmnNamedObjectList<_Object_>.Notify(const Value: _Object_; Action: TCollectionNotification);
{$endif}
begin
  if FDic <> nil then
  begin
    {$ifdef FPC}
    if Action in [lnExtracted, lnDeleted] then //Need it in FPC https://forum.lazarus.freepascal.org/index.php/topic,60984.0.html
      FDic.Remove(_Object_(Ptr).Name.ToLower);//bug in fpc
    {$else}
    if Action in [cnExtracting, cnDeleting] then
      FDic.Remove(Value.Name.ToLower);
    {$endif}
    inherited;
    {$ifdef FPC}
    if Action = lnAdded then
      FDic.AddOrSetValue(_Object_(Ptr).Name.ToLower, _Object_(Ptr));
    {$else}
    if Action = cnAdded then
      FDic.AddOrSetValue(Value.Name.ToLower, Value);
    {$endif}
  end
  else
    inherited;
end;

constructor TmnNamedObjectList<_Object_>.Create(ADicSize: Integer; FreeObjects: boolean);
begin
  inherited Create(FreeObjects);
  FDicSize := ADicSize;
end;

{ TmnObjectList.TmnObjectListEnumerator }

constructor TmnObjectList<_Object_>.TmnObjectListEnumerator.Create(AList: TmnObjectList<_Object_>);
begin
  inherited Create;
  FList := Alist;
  FIndex := -1;
end;

function TmnObjectList<_Object_>.TmnObjectListEnumerator.GetCurrent: _Object_;
begin
  Result := FList[FIndex];
end;

function TmnObjectList<_Object_>.TmnObjectListEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  Result := FIndex < FList.Count;
end;

{ TmnNameValueObjectList }

function TmnNameValueObjectList<_Object_>.GetValues(Index: string): string;
var
  itm: _Object_;
begin
  itm := Find(Index);
  if itm <> nil then
    Result := itm.Value
  else
    Result := '';
end;

procedure TmnNameValueObjectList<_Object_>.SetValues(Index: string; AValue: string);
var
  itm : _Object_;
begin
  itm := Find(Index);
  if AutoRemove and (AValue = '') then
  begin
    if (itm <> nil) then
      Remove(itm);
  end
  else
  begin
    if itm <> nil then
      itm.Value := AValue
    else
      Add(Index, AValue);
  end;
end;

function TmnNameValueObjectList<_Object_>.Add(Name, Value: string): _Object_;
begin
  Result := _Object_.Create(Name, Value);
  Add(Result);
end;

{ TmnObject }

procedure TmnObject.Created;
begin
end;

procedure TmnObject.AfterConstruction;
begin
  inherited AfterConstruction;
  Created;
end;

{ TmnNameValueObject }

procedure TmnNameValueObject.Assign(FromObject: TObject);
begin
  if FromObject is TmnNameValueObject then
  begin
    FName := (FromObject as TmnNameValueObject).FName;
    FValue := (FromObject as TmnNameValueObject).FValue;
  end
  else
    raise Exception.Create('Invalide assign class')
end;

constructor TmnNameValueObject.Create(const vName, AValue: string);
begin
  inherited Create;
  Name := vName;
  Value := AValue;
end;

constructor TmnNameValueObject.CreateFrom(FromObject: TmnNameValueObject);
begin
  Create('', '');
  Assign(FromObject);
end;

{ TmnNamedObject }

procedure TmnNamedObject.SetName(const Value: string);
begin
  FName := Value;
end;

{$ifdef FPC}

{ TNamedObjects }

function TINamedObjects<T>.Find(const AName: string): T;
var
  i: integer;
begin
  Result := nil;
	if AName <> '' then
    for i := 0 to Count - 1 do
    begin
      if SameText((Items[i] as INamedObject).GetName, AName) then
      begin
        Result := Items[i];
        break;
      end;
    end;
end;

function TINamedObjects<T>.IndexOfName(AName: string): Integer;
var
  i: integer;
begin
  Result := -1;
	if AName <> '' then
    for i := 0 to Count - 1 do
    begin
      if SameText((Items[i] as INamedObject).GetName, AName) then
      begin
        Result := i;
        break;
      end;
    end;
end;

{$endif}

{ TmnRefInterfacedPersistent }

procedure TmnRefInterfacedPersistent.AfterConstruction;
begin
  inherited;
  AtomicDecrement(FRefCount);
end;

procedure TmnRefInterfacedPersistent.BeforeDestruction;
begin
  inherited;
  if FRefCount <> 0 then
  begin
    //MessageBox(0, PChar('not Free'+ClassName), PChar('TMiscParams'), 0);
    System.Error(reInvalidPtr);
  end;
end;

function TmnRefInterfacedPersistent.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TmnRefInterfacedPersistent._AddRef: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TmnRefInterfacedPersistent._Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);

  if Result = 0 then
    Destroy;
end;

{ TmnInterfacedPersistent }

procedure TmnInterfacedPersistent.AfterConstruction;
begin
  inherited;
  Created;
end;

procedure TmnInterfacedPersistent.Created;
begin

end;

end.


