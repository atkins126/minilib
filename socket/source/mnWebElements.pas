﻿unit mnWebElements;//* BETA
{$IFDEF FPC}
{$mode delphi}
{$modeswitch prefixedattributes}
{$modeswitch arrayoperators}
{$modeswitch arraytodynarray}
{$modeswitch functionreferences}{$modeswitch anonymousfunctions}
{$ENDIF}
{$H+}{$M+}
{**
 *  This file is part of the "Mini Connections"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher, zaherdirkey>
 *
 *}

{

    Application
      Document

┌──────┬──────── Header ──────────────────────┐
│ Column                                      │
│      │                                      │
├──────┴──────────────────────────────────────┤
│ Navigator/Menu                              │
├────────────┬─ Content ─────────────┬────────┤
│ ASideColumn │                      │ PeerColumn
│            │ ┌─ TabControl ──────┐ │        │
│            │ │ Tab │    │        │ │        │
│            │ ├─────┴────┴────────┤ │        │
│            │ │                   │ │        │
│            │ ├─ Form ────────────┤ │        │
│            │ │                   │ │        │
│            │ │ ┌─ Control ────┐  │ │        │
│            │ │ └──────────────┘  │ │        │
│            │ │                   │ │        │
│            │ │                   │ │        │
│            │ │                   │ │        │
│            │ │                   │ │        │
│            │ └───────────────────┘ │        │
│            │                       │        │
├────────────┴── Footer ─────────────┴────────┤
│                                             │
│                                             │
└─────────────────────────────────────────────┘

Add:
  https://leafletjs.com/examples.html

}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, Contnrs, Variants, Types, RTTI,
  {$ifdef FPC}
  LCLType, //* for RT_RCDATA
  {$endif}
  syncobjs, mnDON, mnJSON,
	mnUtils, mnClasses, mnStreams, mnLogs, mnMIME, mnParams,
  mnMultipartData, mnModules, mnWebModules;

{.$define rtti_objects}

type

  TmnwSchema = class;
  TmnwRenderer = class;
  TmnwElement = class;
  TmnwWriter = class;
  TmnwOutput = class;
  TmnwElementRenderer = class;
  TmnwRendererClass = class of TmnwRenderer;

  TmnwElementClass = class of TmnwElement;
  TElementExtension = class;
  TElementExtensionClass = class of TElementExtension;

  { TElementExtension }

  TElementExtension = class(TCustomAttribute)
  public
    class procedure Update(Element: TmnwElement); virtual; abstract;
    constructor Create; //* Leave it
  end;

  { TIDExtension }

  TIDExtension = class(TElementExtension)
  private
  public
    class procedure Update(Element: TmnwElement); override;
  end;

  { TRouteExtension }

  TRouteExtension = class(TElementExtension)
  private
  public
    class procedure Update(Element: TmnwElement); override;
  end;

  { TmnwAttribute }

  TmnwAttribute = class(TmnNameValueObject)
  public
    function CreateSubValues(vSeparators: TSysCharSet = [' ']): TStringList;
  end;

  { TmnwAttributes }

  TmnwAttributes = class(TmnNameValueObjectList<TmnwAttribute>)
  protected
    procedure Created; override;
  public
    function GetText(WithExtraSpace: Boolean = False): string;
    function HaveSubValue(const AName, AValue: String; vSeparators: TSysCharSet = [' ']): Boolean;
    function SetSubValue(const AName, AValue: String; vSeparators: TSysCharSet = [' ']): Boolean;
    function UnsetSubValue(const AName, AValue: String; vSeparators: TSysCharSet = [' ']): Boolean;
    procedure Append(AAttributes: TmnwAttributes);
  end;

  { TmnwContext }

  TmnwRenderContext = record
    Sender: TObject;
    Schema: TmnwSchema;
    Renderer: TmnwRenderer;

    ParentRenderer: TmnwElementRenderer;
    Output: TmnwOutput;
  end;

  { TmnwScope }

  TmnwScope = record
    Element: TmnwElement;
    Attributes: TmnwAttributes;
  end;

  TmnwRespondContext = record
    Sender: TObject;
    Schema: TmnwSchema;
    Renderer: TmnwRenderer;

    SessionID: string;
    Route: string;

    Stream: TmnBufferStream;
    MultipartData: TmnMultipartData;
  end;

  TmnwRespondResult = record
    ContentType: string;
    SessionID: string;
    HttpResult: THttpResult;
    Location: string; //* New local to forward
    Resume: Boolean;
  end;

  TmnwObject = class(TmnNamedObject);

  TmnwLibrary = class abstract(TmnNamedObject)
  private
    FUsage: Integer;
  protected
  public
    IsLocal: Boolean;
    procedure AddHead(AElement: TmnwElement; const Context: TmnwRenderContext); virtual; abstract;
    procedure IncUsage;
    procedure DecUsage;
    property Usage: Integer read FUsage;
  end;

  TmnwLibraryClass = class of TmnwLibrary;

  { TmnwLibraries }

  TmnwLibraries = class(TmnNamedObjectList<TmnwLibrary>)
  public
    Local: Boolean; //* when find lib, find local first
    procedure Use(ALibrary: TmnwLibrary); overload;
    procedure Use(ALibraryName: string); overload;
    function Find(ALibrary: string; OnlyLocal: Boolean = False): TmnwLibrary; overload;
    procedure RegisterLibrary(ALibraryName: string; IsLocal: Boolean; ALibraryClass: TmnwLibraryClass);
  end;

  TJQuery_Library = class(TmnwLibrary)
  public
    procedure AddHead(AElement: TmnwElement; const Context: TmnwRenderContext); override;
  end;

  { TJQuery_LocalLibrary }

  TJQuery_LocalLibrary = class(TmnwLibrary)
  public
    procedure AddHead(AElement: TmnwElement; const Context: TmnwRenderContext); override;
  end;

  TElementExecute = reference to procedure;

  TmnwRequestState = (rsBeforeRequest, rsAfterRequest);

  TmnwElementState = set of (
    estComposing,
    estComposed
  );

  TmnwElementKind = set of(
//    elRender,
    elEmbed, //* created by parent
    elInternal, //* do not render we will call it manually
    elHighLevel, //Rendered first like scripts
    elFallback //* if no child have the route name, it take the respond if have a name
  );


  TmnwAlign = (alignDefault, alignStart, alignCenter, alignStreach, alignEnd);
  TmnwFixed= (fixedDefault, fixedTop, fixedBottom);

  { TmnwElement }

  TmnwElement = class(TmnObjectList<TmnwElement>)
  private
    FEnabled: Boolean;
    FVisible: Boolean;
    FRenderIt: Boolean;
    FSchema: TmnwSchema;
    FParent: TmnwElement;

    FRoute: String;
    FComment: String;
    FID: String;
    FName: String;
    FStyleClass: String;
    FStyle: String;
    FAttributes: TmnwAttributes;
    FKind: TmnwElementKind;
    FState: TmnwElementState;
    FOnExecute: TElementExecute;
    procedure SetState(const AValue: TmnwElementState);
  protected
    procedure Update; virtual;
    procedure Added(Item: TmnwElement); override;
    procedure Check; virtual;
    function FindObject(ObjectClass: TmnwElementClass; AName: string; RaiseException: Boolean = false): TmnwElement;

    procedure DoCompose; virtual;
    procedure DoRespondHeader(AContext: TmnwRespondContext); virtual;
    procedure DoAction(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); virtual;
    procedure DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); virtual;

    procedure DoExecute; virtual;
    procedure Execute;
    procedure DoChanged; virtual;
    procedure Changed;
    procedure SendMessage(AMessage: string); overload;
    procedure SendMessage(JSON: TDON_Pair); overload; virtual;
    procedure ReceiveMessage(JSON: TDON_Pair); virtual;
  public
    constructor Create(AParent: TmnwElement; AKind: TmnwElementKind = []; ARenderIt: Boolean = True); virtual;
    destructor Destroy; override;

    class function ClassLevel: Integer;

    procedure Add(O: TmnwElement); overload;
    function Add<O: TmnwElement>(const AID: String = ''; const AName: String = ''): O; overload;
    function Find(const Name: string): TmnwElement;
    function FindByRoute(const Route: string): TmnwElement;
    function FindByID(const aID: string): TmnwElement;
    function FindByName(const aName: string): TmnwElement;
    function IndexOfName(vName: string): Integer;

    function This: TmnwElement; virtual; //I wish i have templates/meta programming in pascal
    property Schema: TmnwSchema read FSchema;
    property Parent: TmnwElement read FParent;

    function GetPath: string; virtual;

    function CreateRender(Context: TmnwRenderContext): TmnwElementRenderer;
    procedure Compose; virtual;
    procedure AddState(AState: TmnwElementState);
    procedure RemoveState(AState: TmnwElementState);

    procedure Clear; {$ifdef FPC} override; {$else} virtual; {$endif} //* see TmnObjectList

    function GetContentType(Route: string): string; virtual;

    procedure Action(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
    procedure Respond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); overload;
    procedure Respond(AContext: TmnwRenderContext; var ARespondResult: TmnwRespondResult); overload;

    //* Original Render
    procedure Render(Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); overload;

    //* This will just prepare to Render(Context)
    function Render(Sender: TObject; Schema: TmnwSchema; Renderer: TmnwRenderer; AOutput: TmnwOutput; var ARespondResult: TmnwRespondResult): Boolean; overload;
    function Render(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult): Boolean; overload;

    property Route: String read FRoute write FRoute; //TODO change it to Alias
    property Name: String read FName write FName;
    property StyleClass: String read FStyleClass write FStyleClass;
    property Style: String read FStyle write FStyle;
    property ID: String read FID write FID;
    property Comment: String read FComment write FComment;
    property Visible: Boolean read FVisible write FVisible;
    property Enabled: Boolean read FEnabled write FEnabled;

    property RenderIt: Boolean read FRenderIt write FRenderIt;

    property Attributes: TmnwAttributes read FAttributes;
    property Kind: TmnwElementKind read FKind write FKind;
    property State: TmnwElementState read FState write SetState;

    property OnExecute: TElementExecute read FOnExecute write FOnExecute;
  end;

  { TmnwWriter }

  TmnwWriterOptions = set of (woEndLine, woOpenTag, woCloseTag);

  TmnwWriter = class(TmnNamedObject)
  private
    Level: Integer;
    NewLine: Boolean;
    FStream: TmnBufferStream;
  public
    constructor Create(AName: string; AStream: TmnBufferStream);
    procedure Write(S: string; Options: TmnwWriterOptions = []); virtual;
    property Stream: TmnBufferStream read FStream write FStream;
  end;

  { TmnwOutput }

  TmnwOutput = class(TmnNamedObjectList<TmnwWriter>)
  private
  public
    procedure Write(const Target, S: string; Options: TmnwWriterOptions = []); overload;
    procedure WriteLn(const Target, S: string; Options: TmnwWriterOptions = []); overload;
    property Item; default;
  end;

  TmnwMessage = class(TObject)
  public
    Content: string;
  end;

  { TmnwMessages }

  TmnwMessages = class(TmnObjectList<TmnwMessage>)
  public
    procedure Add(s: string); overload;
  end;

  { TmnwAttachment }

  TmnwAttachment = class(TObject)
  private
    FTerminated: Boolean;
    procedure SendMessage(const Message: string);
  protected
    procedure Loop; virtual;
    procedure Terminate; virtual;
  public
    Schema: TmnwSchema;
    Stream: TmnBufferStream;
    destructor Destroy; override;
    property Terminated: Boolean read FTerminated;
  end;

  { TmnwAttachments }

  TmnwAttachments = class(TmnObjectList<TmnwAttachment>)
  private
    FLock: TCriticalSection;
  protected
    procedure Created; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Terminate;
    procedure SendMessage(const Message: string);
    procedure Add(AAttachment: TmnwAttachment);
    procedure Remove(AAttachment: TmnwAttachment);
    property Lock: TCriticalSection read FLock;
  end;

  TmnwSchamaCapability = (
		schemaSession,
		schemaDynamic,  //* dynamic, do not add it to the list, not cached, becareful
    schemaInteractive,  //* Attach websocket
    schemaSessions
	);

  TmnwSchemaCapabilities = set of TmnwSchamaCapability;

  { TmnwSchema }

  TmnwSchema = class(TmnwElement)
  private
    FAttached: Boolean;
    FAttachments: TmnwAttachments;
    FLock: TCriticalSection;
  protected
    NameingLastNumber: Integer;
    procedure UpdateAttached;
    procedure GenID(Element: TmnwElement); inline;
    procedure GenRoute(Element: TmnwElement); inline;
    procedure DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
    procedure ProcessMessage(const s: string);
  public
    SessionID: string;
    constructor Create(AParent: TmnwElement; AKind: TmnwElementKind = []; ARenderIt: Boolean = True); override;
    destructor Destroy; override;

    class function GetCapabilities: TmnwSchemaCapabilities; virtual;

		//* Attaching cap
    function Interactive: Boolean;

    procedure Compose; override;

    // Executed from a thread of connection of WebSocket, it stay inside until the disconnect or terminate
    procedure Attach(Route: string; Sender: TObject; AStream: TmnBufferStream); // in connection thread

    property Attachments: TmnwAttachments read FAttachments;
    property Attached: Boolean read FAttached;
    property Lock: TCriticalSection read FLock;
  end;

  TmnwSchemaClass = class of TmnwSchema;

  TmnwRendererRegister = class;

  { TmnwElementRenderer }

  TmnwElementRenderer = class(TObject)
  private
    FRenderer: TmnwRenderer;
    FRendererRegister: TmnwRendererRegister;
  protected
    procedure DoCollectAttributes(Scope: TmnwScope); virtual;
    //* This called once from the TmnwRenderer
    procedure DoPrepare(AElement: TmnwElement; ARenderer: TmnwRenderer); virtual;
    procedure Prepare(AElement: TmnwElement; ARenderer: TmnwRenderer);

    procedure RenderChilds(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);

    //* Called to parent to wrap the child rendering, each chiled will wrap it with this render
    //* This method exists in parent render
		procedure DoEnterChildRender(Scope: TmnwScope; const Context: TmnwRenderContext); virtual;
    procedure DoLeaveChildRender(Scope: TmnwScope; const Context: TmnwRenderContext); virtual;

    //* Called only if have parent but exists in a child
		procedure DoEnterOuterRender(Scope: TmnwScope; const Context: TmnwRenderContext); virtual;
    procedure DoLeaveOuterRender(Scope: TmnwScope; const Context: TmnwRenderContext); virtual;

    //* Content render
    procedure DoEnterInnerRender(Scope: TmnwScope; const Context: TmnwRenderContext); virtual;
    procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); virtual;
    procedure DoAfterRender(Scope: TmnwScope; const Context: TmnwRenderContext); virtual;

    property Renderer: TmnwRenderer read FRenderer;
    property RendererRegister: TmnwRendererRegister read FRendererRegister;
  public
    procedure Render(AElement: TmnwElement; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
    constructor Create(ARenderer: TmnwRenderer; ARendererRegister: TmnwRendererRegister); virtual; //useful for creating it by RendererClass.Create
    procedure CollectAttributes(Scope: TmnwScope);
  end;

  TmnwElementRendererClass = class of TmnwElementRenderer;

  { TmnwRenderer }

  TmnwRenderer = class(TmnwObject)
  private
    FModule: TmodWebModule;
    FLibraries: TmnwLibraries;
    FParams: TmnwAttributes;
  protected
    {$ifdef rtti_objects}
    procedure RegisterClasses(ASchemaClass: TmnwSchemaClass);
    {$endif}
    procedure DoBeginRender; virtual;
    procedure DoEndRender; virtual;

    class constructor RegisterObjects;
  public
    type
      TmnwRegisterHow = (None, Replace, Extend);
    constructor Create(AModule: TmodWebModule; IsLocal: Boolean); virtual;
    destructor Destroy; override;
    class destructor Destroy;

    procedure BeginRender;
    procedure EndRender;

    class procedure RegisterRenderer(AElementClass: TmnwElementClass; ARendererClass: TmnwElementRendererClass; How: TmnwRegisterHow = None);
    function CreateRenderer(AElementClass: TmnwElementClass): TmnwElementRenderer; overload;
    function CreateRenderer(AObject: TmnwElement): TmnwElementRenderer; overload;

    property Params: TmnwAttributes read FParams;
    property Libraries: TmnwLibraries read FLibraries;
    property Module: TmodWebModule read FModule;
  end;

  { TmnwSchemaObject }

  TmnwSchemaObject = class(TmnNamedObject)
  private
    FLock: TCriticalSection;
  public
    SchemaClass: TmnwSchemaClass;
    Schema: TmnwSchema;
    constructor Create;
    destructor Destroy; override;
    property Lock: TCriticalSection read FLock;
  end;

  { TmnwSchemas }

  TmnwSchemas = class(TmnNamedObjectList<TmnwSchemaObject>)
  private
    FLock: TCriticalSection;
  protected
    procedure SchemaCreated(Schema: TmnwSchema); virtual;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterSchema(AName: string; SchemaClass: TmnwSchemaClass);

    function FindBy(aSchemaName: string; aSessionID: string): TmnwSchemaObject;
		procedure GetElement(var Route: string; out Schema: TmnwSchema; out Element: TmnwElement);

    function Respond(var AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult): TmnwElement;
    //for websocket
    function Attach(Route: string; Sender: TObject; AStream: TmnBufferStream): TmnwAttachment;
    property Lock: TCriticalSection read FLock;
  end;

  TDirection = (dirUnkown, dirLTR, dirRTL);

{-------------------------------------------------------}
{-----------------    STANDARD    ----------------------}
{-------------------------------------------------------}

  { THTML }

  THTML =class(TmnwSchema)
  private
  public
    type

      { THTMLElement }

      THTMLElement = class(TmnwElement)
      protected
      public
      end;

      { TContent }

      TContent = class abstract(THTMLElement)
      protected
        procedure Added(Item: TmnwElement); override;
      public
        Align: TmnwAlign;
        Fixed: TmnwFixed;
      end;

      TComment = class(THTMLElement)
      public
        Comment: string;
      end;

      TBody = class;
      TNavBar = class;
      THeader = class;
      TFooter = class;
      TContainer = class;
      TImage = class;
      //TButtons = class;

      TFileOptions = set of (ftEmbed, ftResource);

      { TFile }

      //* For resource Use FileName := 'myfile.js' but the resource name will took as myfile only, extention will be for mime

      [TIDExtension]
      TFile = class(THTMLElement)
      protected
        procedure DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
      public
        FileName: string;
        Options: TFileOptions;
        constructor Create(AParent: TmnwElement; AOptions: TFileOptions = []; AFileName: string = ''); reintroduce;
        function GetContentType(Route: string): string; override;
      end;

      { TJSFile }

      TJSFile = class(TFile)
      protected
      end;

      { TAssets }

      TAssets = class(THTMLElement)
      protected
        procedure DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
      public
        HomePath: string;
        function GetContentType(Route: string): string; override;
      end;

      TContentComposeProc = reference to procedure(Inner: TmnwElement);

      { TContentCompose }

      TContentCompose = class(THTMLElement)
      protected
        type

          { TInnerComposer }

          TInnerComposer = class(THTMLElement)
          public
          end;

        procedure InnerCompose(Inner: TmnwElement); virtual;

        procedure DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
      public
        OnCompose: TContentComposeProc;
        constructor Create(AParent: TmnwElement; AOnCompose: TContentComposeProc = nil); reintroduce;
      end;

      [TIDExtension]
      [TRouteExtension]
      TIntervalCompose = class(TContentCompose)
      end;

      { TDocument }

      TDocument = class(TAssets)
      private
        FTitle: string;
        FVersion: integer;
        FBody: TBody;
      protected
        procedure Created; override;
      public
        Direction: TDirection;
        property Version: integer read FVersion write FVersion;
        property Title: string read FTitle write FTitle;
        destructor Destroy; override;
        property Body: TBody read FBody;
      end;

      { TBody }

      TBody = class(TContent)
      private
        //function GetNavBar: TNavBar;
        function GetHeader: THeader;
        function GetContainer: TContainer;
        function GetFooter: TFooter;
      protected
        //FNavBar: TNavBar;
        FHeader: THeader;
        FFooter: TFooter;
        FContainer: TContainer;
      protected
        procedure Created; override;
      public
        property Header: THeader read GetHeader;
        property Container: TContainer read GetContainer;
        property Footer: TFooter read GetFooter;
        destructor Destroy; override;
      end;

      THeader = class(TContent)
      public
        Text: string;
      end;

      TNavBar = class(TContent)
      public
        //Logo: TImage;
        //Items: TButtons;
      end;

      TFooter = class(TContent)
      public
        Text: string;
      end;

      TContainer = class(TContent)
      protected
        procedure Created; override;
      public
        Margin: Integer;
        Size: Integer;
      end;

      TRow = class(TContent)
      public
        Size: Integer;
      end;

      TColumn = class(TContent)
      public
        Size: Integer;
      end;

      [TIDExtension]
      TCard = class(TContent)
      public
        Collapse: Boolean;
        Caption: string;
      end;

      [TIDExtension]
      TPanel = class(TContent)
      public
        Caption: string;
      end;

      { TForm }

      TFormButton = record
        Caption: string;
      end;

      [TIDExtension]
      TForm = class(TContent)
      private
      protected
        procedure DoAction(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
      public
        PostTo: string;
        RedirectTo: string;

        Submit: TFormButton;
        Cancel: TFormButton;
        Reset: TFormButton;
      end;

      TParagraph = class(TContent)
      public
        Text: string;
        constructor Create(AParent: TmnwElement; AText: string = ''); reintroduce;
      end;

      { TAction }

      [TRouteExtension]
      TAction = class(THTMLElement)
      protected
        procedure DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
      public
        procedure Loop; virtual;
      end;

      { TButton }

      TButton = class(THTMLElement)
      private
        FCaption: string;
        procedure SetCaption(const AValue: string);
      protected
        procedure ReceiveMessage(JSON: TDON_Pair); override;
        procedure DoChanged; override;
      public
        property Caption: string read FCaption write SetCaption;
      end;

      {TButtons = class(THTMLElement)
      end;}

      { TInput }

      [TIDExtension]
      TInput = class(THTMLElement)
      private
        FText: string;
        procedure SetText(const AValue: string);
      protected
        procedure Created; override;
        procedure ReceiveMessage(JSON: TDON_Pair); override;
      public
        Caption: string;
        PlaceHolder: string;
        EditType: string;
        Required: Boolean;
      public
        property Text: string read FText write SetText;
      end;

      { TInputPassword }

      [TIDExtension]
      TInputPassword = class(TInput)
      protected
        procedure Created; override;
      end;

      [TIDExtension]
      TImage = class(THTMLElement)
      protected
        procedure DoCompose; override;
      public
        Source: string;
        AltText: string;
        //Width, Height: double;
      end;

      { TMemoryImage }

      [TIDExtension]
      TMemoryImage = class(TImage)
      private
        FData: TMemoryStream;
      protected
        procedure DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
      protected
        procedure Created; override;
      public
        FileName: string;
        FilePath: string;
        destructor Destroy; override;
        function GetContentType(Route: string): string; override;
        procedure LoadFromFile(const AFileName: string);
        procedure LoadFromStream(AStream: TStream);
        property Data: TMemoryStream read FData;
      end;

      { Break }

      TBreak = class(THTMLElement)
      private
      public
      end;

      //* Custom Tag
      TTag = class(THTMLElement) //TODO
      public
      end;

      TList = class(THTMLElement)
      public
      end;

  protected
    procedure DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
    function GetContentType(Route: string): string; override;
  public
    ServeFiles: Boolean;
  end;

  { TmnwHTMLRenderer }

  TmnwHTMLRenderer = class(TmnwRenderer)
  protected
  public
  type

      { TElement }

      TElementHTML = class abstract(TmnwElementRenderer)
      protected
        procedure AddHead(AElement: TmnwElement; const Context: TmnwRenderContext); virtual;
        procedure DoEnterInnerRender(Scope: TmnwScope; const Context: TmnwRenderContext); override;
      end;

      { TComment }

      TComment = class(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TDocument }

      TDocument = class(TElementHTML)
      protected
        procedure DoCollectAttributes(Scope: TmnwScope); override;
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TBody }

      TBody = class(TElementHTML)
      protected
        procedure DoCollectAttributes(Scope: TmnwScope); override;
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TFile }

      TFile = class(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TJSFile }

      TJSFile = class(TFile)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TContentCompose }

      TContentCompose = class(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TIntervalCompose }

      TIntervalCompose = class(TContentCompose)
      protected
        procedure DoCollectAttributes(Scope: TmnwScope); override;
      end;

      { THeader }

      THeader = class(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TFooter }

      TFooter = class(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TContainer }

      TContainer = class abstract(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      TRow = class abstract(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      TColumn = class abstract(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TCard }

      TCard = class abstract(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      TPanel = class abstract(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TForm }

      TForm = class abstract(TElementHTML)
      protected
        procedure DoEnterChildRender(Scope: TmnwScope; const Context: TmnwRenderContext); override;
        procedure DoLeaveChildRender(Scope: TmnwScope; const Context: TmnwRenderContext); override;
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TParagraph }

      TParagraph = class(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TBreak }

      TBreak = class(TElementHTML)
      protected
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TButton }

      { TTButton }

      TButton = class(TElementHTML)
      protected
        procedure DoCollectAttributes(Scope: TmnwScope); override;
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TInput }

      TInput = class(TElementHTML)
      protected
        procedure DoCollectAttributes(Scope: TmnwScope); override;
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      TInputPassword = class(TInput)
      end;

      { TImage }

      TImage = class(TElementHTML)
      protected
        procedure DoPrepare(AElement: TmnwElement; ARenderer: TmnwRenderer); override;
        procedure DoCollectAttributes(Scope: TmnwScope); override;
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

      { TMemoryImage }

      TMemoryImage = class(TElementHTML)
      protected
        procedure DoPrepare(AElement: TmnwElement; ARenderer: TmnwRenderer); override;
        procedure DoCollectAttributes(Scope: TmnwScope); override;
        procedure DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult); override;
      end;

  protected
    procedure Created; override;
    procedure AddHead(AElement: TmnwElement; const Context: TmnwRenderContext); virtual;
    class constructor RegisterObjects;
  public
  end;

  { TmnwRendererRegister }

  TmnwRendererRegister = class(TObject)
  public
    ElementClass: TmnwElementClass;
    RendererClass: TmnwElementRendererClass;
    Renderers: array of TmnwElementRendererClass;
    Extensions: TClassList;
    Level: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  { TmnwElementRenderers }

  TmnwElementRenderers = class(TmnObjectList<TmnwRendererRegister>)
  protected
    function Compare(Item1, Item2: TmnwRendererRegister): Integer; override;
  public
    Sorted: Boolean;
    procedure QuickSort; override;
    function Find(AElementClass: TmnwElementClass; Nearst: Boolean = False): TmnwRendererRegister;
  end;

  TmnwWebModule = class;

  { TmnwHttpGetHomeCommand }

  TmnwHttpGetHomeCommand = class(TmodHttpCommand)
  private
    function GetModule: TmnwWebModule;
  protected
  public
    procedure RespondResult(var Result: TmodRespondResult); override;
    property Module: TmnwWebModule read GetModule;
  end;

  TmnwWebSchema = class(THTML)
  public
    Module: TmnwWebModule;
  end;

  TmnwWebSchemas = class(TmnwSchemas)
  protected
    Module: TmnwWebModule;
    procedure SchemaCreated(Schema: TmnwSchema); override;
  end;

  TmnwWebModule = class(TmodWebModule)
  private
  protected
    function CreateRenderer(IsLocal: Boolean): TmnwRenderer; virtual;
    procedure CreateItems; override;
    procedure DoPrepareRequest(ARequest: TmodRequest); override;
    procedure Created; override;
  public
    AppPath: string;
    Schemas: TmnwWebSchemas;
    destructor Destroy; override;
  end;

function LevelStr(vLevel: Integer): String;

{$ifdef RTTI_OBJECTS}
type
  TCacheClassObject = class(TObject)
  public
    ObjectClass: TClass;
  end;

  { TmnwRendererRegisters }

  TCacheClassObjects = class(TmnObjectList<TCacheClassObject>)
  public
    procedure AddClass(ObjectClass: TClass);
  end;

var
  CacheClassObjects: TCacheClassObjects = nil;

procedure CacheClasses;
{$endif}

//* You need to compile it by brcc32 mnWebElements.rc or wait another 100 years till Delphi/FPC auto compile it
{$R 'mnWebElements.res' 'mnWebElements.rc'}

implementation

function SQ(s: string): string; inline;
begin
  Result := QuoteStr(s, '''');
end;

function DQ(s: string): string; inline;
begin
  Result := QuoteStr(s, '"');
end;

//return "Name" "Value" if Value not empty
function NV(const Name, Value: string): string; overload; inline;
begin
  if Value <> '' then
    Result := ' ' + Name + '=' + DQ(Value)
  else
    Result := '';

end;

function NV(const Name, Value, Default: string): string; overload; inline;
begin
  if Value <> '' then
    Result := ' ' + DQ(Name) + '=' + DQ(Value)
  else if Default <> '' then
    Result := ' ' + DQ(Name) + '=' + DQ(Default)
  else
    Result := '';
end;

function When(Condition: Boolean; Value: string; Default: string = ''): string; inline;
begin
  if Condition then
    Result := Value
  else
    Result := Default;
end;

var
  //*Should be by base class categoried
  ElementRenderers: TmnwElementRenderers = nil;

{$ifdef rtti_objects}
procedure CacheClasses;
var
  Context: TRTTIContext;
  rTypes: TArray<TRttiType>;
  rType: TRttiType;
begin
  if CacheClassObjects <> nil then
    exit;
  CacheClassObjects := TCacheClassObjects.Create;
  Context := TRTTIContext.Create;
  try
    rTypes := Context.GetTypes;
    for rType in rTypes do
      if (rType.TypeKind = tkClass) and rType.IsInstance
        and (rType.AsInstance.MetaclassType.InheritsFrom(TmnwElement)
            or
            rType.AsInstance.MetaclassType.InheritsFrom(TmnwRenderer)
            )
        then
      begin
        CacheClassObjects.AddClass(TmnwElementClass(rType.AsInstance.MetaclassType));
//        log.WriteLn(rType.ToString);
      end;
  finally
    Context.Free;
  end;
end;
{$endif}

procedure rttiCollectExtensions(rttiContext: TRttiContext; ElementClass: TClass; List: TClassList); overload;
var
  rttiType: TRttiType;
  attribute: TCustomAttribute;
begin
  rttiType := rttiContext.GetType(ElementClass);
  for attribute in rttiType.GetAttributes do
    if List.IndexOf(attribute.ClassType)<0 then
      List.Add(attribute.ClassType);
  if ElementClass.ClassParent <> nil then
    rttiCollectExtensions(rttiContext, ElementClass.ClassParent, List);
end;

procedure rttiCollectExtensions(ElementClass: TmnwElementClass; ToList: TClassList); overload;
var
  rttiContext: TRttiContext;
  attribute: TCustomAttributeClass;
  list: TClassList;
begin
//  log.Write(Element.ClassName);
  if ElementClass = nil then
    raise Exception.Create('Element is nil');
  if ElementClass <> nil then
  begin
    list := TClassList.Create;
    rttiContext := TRttiContext.Create;
    try
      rttiCollectExtensions(rttiContext, ElementClass, list);
      for attribute in list do
        if attribute.InheritsFrom(TElementExtension) then
          ToList.Add(attribute);
    finally
      rttiContext.Free;
      list.Free;
    end;
  end;
end;


{ TmnwOutput }

procedure TmnwOutput.Write(const Target, S: string; Options: TmnwWriterOptions);
var
  Writer: TmnwWriter;
begin
  Writer := Find(Target);
  if Writer <> nil then
    Writer.Write(S, Options);
end;

procedure TmnwOutput.WriteLn(const Target, S: string; Options: TmnwWriterOptions);
begin
  Write(Target, S, Options + [woEndLine]);
end;

{ TmnwMessages }

procedure TmnwMessages.Add(s: string);
var
  aMessage: TmnwMessage;
begin
  aMessage := TmnwMessage.Create;
  aMessage.Content := s;
  Add(aMessage);
end;

{ TmnwAttachment }

procedure TmnwAttachment.SendMessage(const Message: string);
begin
  Stream.WriteUTF8Line(Message);
//  Stream.Close([cloData]);
end;

procedure TmnwAttachment.Loop;
var
  s: string;
begin
  while not Terminated and Stream.Connected and not (cloTransmission in Stream.State) do
  begin
    if Stream.ReadUTF8String(s) then
    begin
      log.writeln('Socket: '+s);
{      Schema.Attachments.Lock.Enter;
      try
        Schema.Attachments.Messages.Add(s);
      finally
        Schema.Attachments.Lock.Leave;
      end;}
      if s.StartsWith('{') then
        Schema.ProcessMessage(s)
      else if s = 'attach' then
        Stream.WriteUTF8Line('attached')
      else
        Schema.ProcessMessage(s);
    end;
  end;
end;

procedure TmnwAttachment.Terminate;
begin
  FTerminated := True;
  Stream.Close;
end;

destructor TmnwAttachment.Destroy;
begin
  inherited;
end;

{ TmnwAttachments }

procedure TmnwAttachments.Created;
begin
  inherited;
end;

constructor TmnwAttachments.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
//  FMessages := TmnwMessages.Create;
end;

destructor TmnwAttachments.Destroy;
begin
//  FreeAndNil(FMessages);
  FreeAndNil(FLock);
  inherited;
end;

procedure TmnwAttachments.Terminate;
var
  Attachment: TmnwAttachment;
begin
  Lock.Enter;
  try
    for Attachment in Self do
    begin
      Attachment.Terminate;
    end;
  finally
    Lock.Leave;
  end;
end;

procedure TmnwAttachments.SendMessage(const Message: string);
var
  Attachment: TmnwAttachment;
begin
  Lock.Enter;
  try
    for Attachment in Self do
    begin
      Attachment.SendMessage(Message);
    end;
  finally
    Lock.Leave;
  end;
end;

procedure TmnwAttachments.Add(AAttachment: TmnwAttachment);
begin
  Lock.Enter;
  try
    inherited Add(AAttachment);
  finally
    Lock.Leave;
  end;
end;

procedure TmnwAttachments.Remove(AAttachment: TmnwAttachment);
begin
  Lock.Enter;
  try
    inherited Remove(AAttachment);
  finally
    Lock.Leave;
  end;
end;

{ TmnwAttributes }

function TmnwAttributes.GetText(WithExtraSpace: Boolean): string;
var
  a: TmnwAttribute;
begin
  Result := '';
  for a in Self do
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + a.Name + '='+ QuoteStr(a.Value, '"');
  end;
  if Result <> '' then
    Result := ' ' + Result;
end;

function TmnwAttributes.HaveSubValue(const AName, AValue: String; vSeparators: TSysCharSet): Boolean;
var
  SubValues: TStringList;
  aAttribute: TmnwAttribute;
begin
  aAttribute := Find(AName);
  Result := aAttribute <> nil;
  if Result then
  begin
    SubValues := aAttribute.CreateSubValues(vSeparators);
    try
      Result := SubValues.IndexOf(AValue) >= 0;
    finally
      SubValues.Free;
    end;
  end;
end;

function TmnwAttributes.SetSubValue(const AName, AValue: String; vSeparators: TSysCharSet): Boolean;
var
  SubValues: TStringList;
  aAttribute: TmnwAttribute;
begin
  aAttribute := Find(AName);
  Result := aAttribute <> nil;
  if not Result then
  begin
    aAttribute := TmnwAttribute.Create(AName, '');
    Add(aAttribute);
  end;

  SubValues := aAttribute.CreateSubValues(vSeparators);
  try
    Result := SubValues.IndexOf(AValue)<0;
    if Result then
    begin
      SubValues.Add(AValue);
      SubValues.Delimiter := ' ';
      aAttribute.Value := SubValues.DelimitedText;
    end;
  finally
    SubValues.Free;
  end;
end;

function TmnwAttributes.UnsetSubValue(const AName, AValue: String; vSeparators: TSysCharSet): Boolean;
var
  SubValues: TStringList;
  i: Integer;
  aAttribute: TmnwAttribute;
begin
  aAttribute := Find(AName);
  Result := aAttribute = nil;
  if not Result then
  begin
    SubValues := aAttribute.CreateSubValues(vSeparators);
    try
      i := SubValues.IndexOf(AValue);
      Result := i>=0;
      if Result then
      begin
        SubValues.Delete(i);
        SubValues.Delimiter := ' ';
        aAttribute.Value := SubValues.DelimitedText;
        if AutoRemove and (aAttribute.Value = '') then
          Remove(aAttribute);
      end;
    finally
      SubValues.Free;
    end;
  end;
end;

procedure TmnwAttributes.Append(AAttributes: TmnwAttributes);
var
  fromAttibute: TmnwAttribute;
begin
  for fromAttibute in AAttributes do
  begin
    Add(TmnwAttribute.CreateFrom(fromAttibute));
  end;
end;

procedure TmnwAttributes.Created;
begin
  inherited;
  //AutoRemove := True; //no AltTxt in image should writen even if it empty
end;

{ TmnwElementRenderer }

procedure TmnwElementRenderer.RenderChilds(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  o: TmnwElement;
begin
  Context.ParentRenderer := Self;
  for o in Scope.Element do
  begin
    if (elHighLevel in o.Kind) then
      if not (elInternal in o.Kind) then
        o.Render(Context, ARespondResult);
  end;

  for o in Scope.Element do
  begin
    if not (elHighLevel in o.Kind) then
      if not (elInternal in o.Kind) then
        o.Render(Context, ARespondResult);
  end;
end;

procedure TmnwElementRenderer.DoEnterChildRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
end;

procedure TmnwElementRenderer.DoEnterInnerRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
end;

procedure TmnwElementRenderer.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
begin
  RenderChilds(Scope, Context, ARespondResult);
end;

procedure TmnwElementRenderer.DoAfterRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
end;

procedure TmnwElementRenderer.DoLeaveChildRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
end;

procedure TmnwElementRenderer.DoEnterOuterRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
end;

procedure TmnwElementRenderer.DoLeaveOuterRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
end;

procedure TmnwElementRenderer.DoCollectAttributes(Scope: TmnwScope);
begin
end;

procedure TmnwElementRenderer.DoPrepare(AElement: TmnwElement; ARenderer: TmnwRenderer);
begin
end;

procedure TmnwElementRenderer.Prepare(AElement: TmnwElement; ARenderer: TmnwRenderer);
var
  o: TmnwElement;
  r: TmnwElementRenderer;
begin
  DoPrepare(AElement, ARenderer);
  for o in AElement do
  begin
    r := ARenderer.CreateRenderer(o);
    try
      r.Prepare(AElement, ARenderer);
    finally
      r.Free;
    end;
  end;
end;

procedure TmnwElementRenderer.Render(AElement: TmnwElement; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  aScope: TmnwScope;
begin
  aScope.Attributes := TmnwAttributes.Create;
  aScope.Element := AElement;
  try
    CollectAttributes(aScope);

    if Context.ParentRenderer <> nil then
      Context.ParentRenderer.DoEnterChildRender(aScope, Context);

    DoEnterInnerRender(aScope, Context);
    DoInnerRender(aScope, Context, ARespondResult);
    DoAfterRender(aScope, Context);

    if Context.ParentRenderer <> nil then
      Context.ParentRenderer.DoLeaveChildRender(aScope, Context);

  finally
    FreeAndNil(aScope.Attributes);
  end;
end;

constructor TmnwElementRenderer.Create(ARenderer: TmnwRenderer; ARendererRegister: TmnwRendererRegister);
begin
  inherited Create;
  FRenderer := ARenderer;
  FRendererRegister:= ARendererRegister;
end;

procedure TmnwElementRenderer.CollectAttributes(Scope: TmnwScope);
begin
  Scope.Attributes.Append(Scope.Element.Attributes);

  if Scope.Element.ID <> '' then
    Scope.Attributes['id'] := Scope.Element.ID;
  if Scope.Element.Name <> '' then
    Scope.Attributes['name'] := Scope.Element.Name;
  if Scope.Element.Style <> '' then
    Scope.Attributes['style'] := Scope.Element.Style;
  if Scope.Element.StyleClass <> '' then
    Scope.Attributes.SetSubValue('class', Scope.Element.StyleClass);

  DoCollectAttributes(Scope);
end;

{ TElementExtension }

constructor TElementExtension.Create;
begin
  inherited Create;
end;

function TmnwAttribute.CreateSubValues(vSeparators: TSysCharSet): TStringList;
begin
  Result := TStringList.Create;
  if Self <> nil then
    StrToStrings(Value, Result, vSeparators, []);
end;

procedure TmnwElement.Render(Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  Renderer: TmnwElementRenderer;
begin
  if RenderIt then
  begin
    Renderer := CreateRender(Context);
    if Renderer <> nil then
    begin
      try
        Renderer.Render(Self, Context, ARespondResult);
      finally
        Renderer.Free;
      end;
    end;
  end;
end;

function TmnwElement.CreateRender(Context: TmnwRenderContext): TmnwElementRenderer;
begin
  if (Context.Renderer <> nil) then
    Result := Context.Renderer.CreateRenderer(Self)
  else
    Result := nil;
end;

{ TmnwSchema.TmnwElementRenderers }

function TmnwElementRenderers.Compare(Item1, Item2: TmnwRendererRegister): Integer;
begin
  Result := Item2.Level - Item1.Level;
end;

procedure TmnwElementRenderers.QuickSort;
begin
  inherited;
  Sorted := True;
end;

function TmnwElementRenderers.Find(AElementClass: TmnwElementClass; Nearst: Boolean): TmnwRendererRegister;
var
  o: TmnwRendererRegister;
  i: Integer;
begin
  Result := nil;
  for i:= 0 to Count - 1 do
  begin
    o := Items[i];
    if AElementClass = o.ElementClass then
    begin
      Result := o;
      break;
    end
    else if Nearst and AElementClass.InheritsFrom(o.ElementClass) then
    begin
      Result := o;
      break; //* because it sorted down
    end;
  end;
end;

{function TmnwElementRenderers.FindRendererClass(AObjectClass: TmnwElementClass): TmnwElementRendererClass;
var
  o: TmnwRendererRegister;
begin
  o := Find(AObjectClass, True);
  if o <> nil then
    Result := o.RendererClass
  else
    Result := TmnwElementRenderer;
end;}

{ TmnwSchemaObject }

constructor TmnwSchemaObject.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
end;

destructor TmnwSchemaObject.Destroy;
begin
  FreeAndNil(Schema);
  FreeAndNil(FLock);
  inherited;
end;

{ TmnwSchemas }

destructor TmnwSchemas.Destroy;
begin
  inherited;
  FreeAndNil(FLock);
end;

procedure TmnwSchemas.RegisterSchema(AName: string; SchemaClass: TmnwSchemaClass);
var
  SchemaObject: TmnwSchemaObject;
begin
  SchemaObject := TmnwSchemaObject.Create;
  SchemaObject.Name := AName;
	SchemaObject.SchemaClass := SchemaClass;
  inherited Add(SchemaObject);
end;

function TmnwSchemas.FindBy(aSchemaName: string; aSessionID: string): TmnwSchemaObject;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Items[i].Name, aSchemaName) and ((aSessionID = '') or ((Items[i].Schema <> nil) and (aSessionID = Items[i].Schema.SessionID))) then
      Result := Items[i];
    if Result <> nil then
      break;
  end;
end;

procedure TmnwSchemas.GetElement(var Route: string; out Schema: TmnwSchema; out Element: TmnwElement);
var
  SchemaObject: TmnwSchemaObject;
  aElement: TmnwElement;
  Routes: TStringList;
  i: Integer;
  aSchemaName, aRoute: string;
begin
  Element := nil;
  Schema := nil;
  Routes := TStringList.Create;
  try
    StrToStrings(Route, Routes, ['/']);
    if (Routes.Count > 0) then
    begin
      aSchemaName := Routes[0];
      Routes.Delete(0);
      Route := DeleteSubPath(aSchemaName, Route);
      SchemaObject := Find(aSchemaName);
    end
    else
      SchemaObject := nil;

    if SchemaObject = nil then
      SchemaObject := First; //* fallback

    if SchemaObject <> nil then
    begin
      SchemaObject.Lock.Enter;
      try
        if SchemaObject.Schema = nil then
        begin
          Schema := SchemaObject.SchemaClass.Create(nil);
          Schema.Route := Route;
          SchemaCreated(Schema);
          Schema.Compose;
          if not (schemaDynamic in Schema.GetCapabilities) then
            SchemaObject.Schema := Schema;
        end
        else
          Schema := SchemaObject.Schema;
      finally
        SchemaObject.Lock.Leave;
      end;
      aElement := Schema;
    end
    else
      aElement := nil;

    if aElement <> nil then
    begin
      Element := aElement;
      i := 0;
      while i < Routes.Count do
      begin
        aRoute := Routes[i];
        aElement := aElement.FindByRoute(aRoute);
        if aElement = nil then
        begin
          //if elFallback in Element.Kind then
          break;
        end
        else
        begin
          Route := DeleteSubPath(aRoute, Route);
          Element := aElement;
        end;
        inc(i);
      end;
    end;
  finally
    Routes.Free;
  end;
end;

function TmnwSchemas.Respond(var AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult): TmnwElement;
var
  aSchema: TmnwSchema;
begin
  GetElement(AContext.Route, aSchema, Result);
  if Result <> nil then
  begin
    aContext.Schema := aSchema;
    Result.Action(AContext, ARespondResult);
    if ARespondResult.Resume then
      Result.Respond(AContext, ARespondResult);
  end;

  if aSchema <> nil then
  begin
    if (aSchema <> nil) and (schemaDynamic in aSchema.GetCapabilities) then
      aSchema.Free;
  end;
end;

function TmnwSchemas.Attach(Route: string; Sender: TObject; AStream: TmnBufferStream): TmnwAttachment;
var
  SchemaObject: TmnwSchemaObject;
  Routes: TStringList;
  i: Integer;
  aRoute: string;
  aSchema: TmnwSchema;
begin
  aSchema := nil;
  Routes := TStringList.Create;
  try
    i := 0;
    StrToStrings(Route, Routes, ['/']);
    if (i<Routes.Count) then
    begin
      aRoute := Routes[i];
      inc(i);
      SchemaObject := Find(aRoute);
    end
    else
      SchemaObject := nil;

    if SchemaObject = nil then
      SchemaObject := First; //* fallback

    if SchemaObject <> nil then
    begin
      DeleteSubPath(aRoute, Route);
      if SchemaObject.Schema = nil then
      begin
        if not (schemaDynamic in SchemaObject.SchemaClass.GetCapabilities) then
        begin
          aSchema := SchemaObject.SchemaClass.Create(nil);
          aSchema.Route := Route;
          SchemaCreated(aSchema);
          aSchema.Compose;
        end;
      end
      else
        aSchema := SchemaObject.Schema;
    end;
  finally
    Routes.Free;
  end;

  if aSchema <> nil then
  begin
    aSchema.Attach(aRoute, Sender, AStream);
  end
  else
    Result := nil;
end;

procedure TmnwSchemas.SchemaCreated(Schema: TmnwSchema);
begin
end;

constructor TmnwSchemas.Create;
begin
  FLock := TCriticalSection.Create;
  inherited Create;
end;

{ THTML }

procedure THTML.DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
var
  fs: TFileStream;
  aFileName: string;
begin
  inherited;
  if ServeFiles then
  begin
    if AContext.Renderer.Module.HomePath <> '' then
    begin
      if WebExpandFile(AContext.Renderer.Module.HomePath, AContext.Route, aFileName) then
      begin
        if FileExists(aFileName) then
        begin
          fs := TFileStream.Create(aFileName, fmShareDenyWrite or fmOpenRead);
          try
            AContext.Stream.WriteStream(fs, 0);
          finally
            fs.Free;
          end;
        end;
      end;
    end;
  end;
end;

function THTML.GetContentType(Route: string): string;
begin
  if Route = '' then
    Result := inherited GetContentType(Route)
  else
    Result := DocumentToContentType(Route);
end;

procedure TmnwHTMLRenderer.Created;
begin
  inherited;
  Libraries.RegisterLibrary('JQuery', False, TJQuery_Library);
  Libraries.RegisterLibrary('JQuery', False, TJQuery_LocalLibrary);
end;

procedure TmnwHTMLRenderer.AddHead(AElement: TmnwElement; const Context: TmnwRenderContext);
begin
end;

class constructor TmnwHTMLRenderer.RegisterObjects;
begin
  //RegisterClasses(THTML);
  RegisterRenderer(THTML.TContentCompose, TContentCompose);
  RegisterRenderer(THTML.TIntervalCompose, TIntervalCompose);
  RegisterRenderer(THTML.TFile, TFile);
  RegisterRenderer(THTML.TJSFile, TJSFile);

  RegisterRenderer(THTML.TComment ,TComment);
  RegisterRenderer(THTML.TDocument ,TDocument);
  RegisterRenderer(THTML.TBody ,TBody);
  RegisterRenderer(THTML.TParagraph, TParagraph);
  RegisterRenderer(THTML.TBreak, TBreak);
  RegisterRenderer(THTML.TButton, TButton);
  RegisterRenderer(THTML.TInput, TInput);
  RegisterRenderer(THTML.TInputPassword, TInputPassword);
  RegisterRenderer(THTML.TImage, TImage);
  RegisterRenderer(THTML.TMemoryImage, TMemoryImage);
  RegisterRenderer(THTML.THeader, THeader);
  RegisterRenderer(THTML.TFooter, TFooter);
  RegisterRenderer(THTML.TContainer, TContainer);
  RegisterRenderer(THTML.TCard, TCard);
  RegisterRenderer(THTML.TForm, TForm);
  RegisterRenderer(THTML.TRow, TRow);
  RegisterRenderer(THTML.TColumn, TColumn);
  RegisterRenderer(THTML.TPanel, TPanel);
end;

{ TmnwHTMLRenderer.TElementHTML }

procedure TmnwHTMLRenderer.TElementHTML.AddHead(AElement: TmnwElement; const Context: TmnwRenderContext);
begin
end;

procedure TmnwHTMLRenderer.TElementHTML.DoEnterInnerRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
  if Scope.Element.Comment <> '' then
    Context.Output.WriteLn('html', '<!-- ' + Scope.Element.Comment + ' -->');
  inherited;
end;

{ TmnwHTMLRenderer.TComment }

procedure TmnwHTMLRenderer.TComment.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TComment;
begin
  inherited;
  e := Scope.Element as THTML.TComment;
  Context.Output.WriteLn('html', '<!--' + e.Comment + '-->', [woOpenTag, woCloseTag]);
end;

{ TmnwHTMLRenderer.TDocumentHTML }

procedure TmnwHTMLRenderer.TDocument.DoCollectAttributes(Scope: TmnwScope);
var
  e: THTML.TDocument;
begin
  e := Scope.Element as THTML.TDocument;
  if e.Direction = dirRTL then
    Scope.Attributes['dir'] := 'rtl'
  else if E.Direction = dirLTR then
    Scope.Attributes['dir'] := 'ltr';
  Scope.Attributes['lang'] := 'en'
end;

procedure TmnwHTMLRenderer.TDocument.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TDocument;
  aLibrary: TmnwLibrary;
//  o: TmnwElement;
//  r: TElementHTML;
begin
  e := Scope.Element as THTML.TDocument;
//  //Log.WriteLn(ClassName);
  Context.Output.WriteLn('html', '<!DOCTYPE html>');
  Context.Output.WriteLn('html', '<html' + Scope.Attributes.GetText(True) + '>', [woOpenTag]);
  Context.Output.WriteLn('html', '<head>', [woOpenTag]);
  Context.Output.WriteLn('html', '<title>'+ e.Title + '</title>', [woOpenTag, woCloseTag]);
  Context.Output.WriteLn('html', '<link rel="shortcut icon" href="#" />', [woOpenTag, woCloseTag]);
  AddHead(Scope.Element, Context);

  for aLibrary in Renderer.Libraries do
  begin
    if aLibrary.Usage > 0 then
      aLibrary.AddHead(Scope.Element, Context);
  end;

  (Renderer as TmnwHTMLRenderer).AddHead(Scope.Element, Context);

  //* Collect head from childs
  {for o in Scope.Element do
  begin
    if o is THTML.THTMLElement then
    begin
      r := Renderer.CreateRenderer(o) as TElementHTML;
      try
        r.AddHeader(o, Context);
      finally
        r.free;
      end;
    end;
  end;}
  Context.Output.WriteLn('html', '</head>', [woCloseTag]);
  e.Body.Render(Context, ARespondResult);
  Context.Output.WriteLn('html', '</html>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.THeaderHTML }

procedure TmnwHTMLRenderer.THeader.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.THeader;
begin
  e := Scope.Element as THTML.THeader;
  Context.Output.WriteLn('html', '<header class="bg-primary text-white text-left py-3">', [woOpenTag]);
  inherited;
  if e.Text <> '' then
    Context.Output.WriteLn('html', '<h1>'+e.Text+'</h1>', [woOpenTag, woCloseTag]);
  Context.Output.WriteLn('html', '</header>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TFooterHTML }

procedure TmnwHTMLRenderer.TFooter.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TFooter;
begin
  e := Scope.Element as THTML.TFooter;
  Context.Output.WriteLn('html', '<footer class="bg-body-tertiary text-center text-lg-start">', [woOpenTag]);
  if e.Text <> '' then
    Context.Output.WriteLn('html', '<h6>'+e.Text+'</h6>', [woOpenTag, woCloseTag]);
  inherited;
  Context.Output.WriteLn('html', '</footer>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TContainerHTML }

procedure TmnwHTMLRenderer.TContainer.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TContainer;
begin
  e := Scope.Element as THTML.TContainer;
  Context.Output.WriteLn('html', '<main class="container" '+Scope.Attributes.GetText(True)+'>', [woOpenTag]);
  inherited;
  Context.Output.WriteLn('html', '</main>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TCardHTML }

procedure TmnwHTMLRenderer.TCard.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TCard;
begin
  e := Scope.Element as THTML.TCard;
  Context.Output.WriteLn('html', '<div class="card">', [woOpenTag]);
  if e.Caption <> '' then
    Context.Output.WriteLn('html', '<div class="card-header">' + e.Caption + '</div>', [woOpenTag, woCloseTag]);

  Context.Output.WriteLn('html', '<div class="card-body">', [woOpenTag]);
  inherited;
  Context.Output.WriteLn('html', '</div>', [woCloseTag]);
  Context.Output.Writeln('html', '</div>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TFormHTML }

procedure TmnwHTMLRenderer.TForm.DoEnterChildRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
  Scope.Attributes.SetSubValue('class', 'form-control');
  inherited;
end;

procedure TmnwHTMLRenderer.TForm.DoLeaveChildRender(Scope: TmnwScope; const Context: TmnwRenderContext);
begin
  inherited;
end;

procedure TmnwHTMLRenderer.TForm.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TForm;
  aPostTo: string;
begin
  e := Scope.Element as THTML.TForm;
  if e.PostTo <> '' then
  begin
    if e.PostTo = '.' then
      aPostTo := Renderer.Module.GetHomeUrl
    else
      aPostTo := e.PostTo
  end
  else
    aPostTo := IncludeURLDelimiter(Renderer.Module.GetHomeUrl) + Scope.Element.GetPath;
  Context.Output.WriteLn('html', '<form method="post"'+ NV('action', aPostTo) + ' enctype="multipart/form-data"' + Scope.Attributes.GetText(True)+'>', [woOpenTag]);
  inherited;
  if e.RedirectTo <> '' then
    Context.Output.WriteLn('html', '<input type="hidden" name="redirect" value="'+e.RedirectTo+'">', [woOpenTag, woCloseTag]);
  Context.Output.WriteLn('html', '</form>', [woCloseTag]);

  if e.Submit.Caption <> '' then
    Context.Output.WriteLn('html', '<button class="btn btn-success" type="submit" form="'+e.ID+'" value="Submit">' + e.Submit.Caption + '</button>', [woOpenTag, woCloseTag]);
  if e.Cancel.Caption <> '' then
    Context.Output.WriteLn('html', '<button class="btn btn-primary" type="cancel" form="'+e.ID+'" value="Cancel">' + e.Cancel.Caption + '</button>', [woOpenTag, woCloseTag]);
  if e.Reset.Caption <> '' then
    Context.Output.WriteLn('html', '<button class="btn btn-primary" type="reset" form="'+e.ID+'" value="Reset">' + e.Reset.Caption + '</button>', [woOpenTag, woCloseTag]);
end;

{ TmnwHTMLRenderer.TParagraphHTML }

procedure TmnwHTMLRenderer.TParagraph.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TParagraph;
begin
  e := Scope.Element as THTML.TParagraph;
  Context.Output.Write('html', '<p>', [woOpenTag]);
  if e.Text <> '' then
    Context.Output.Write('html', e.Text, []);
  inherited;
  Context.Output.WriteLn('html', '</p>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TBreakHTML }

procedure TmnwHTMLRenderer.TBreak.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
begin
  Context.Output.WriteLn('html', '<br>');
end;

{ TmnwHTMLRenderer.TTButton }

procedure TmnwHTMLRenderer.TButton.DoCollectAttributes(Scope: TmnwScope);
begin
  inherited;
  //Scope.Attributes['type'] := (Scope.Element as THTML.TButton).EditType;
end;

procedure TmnwHTMLRenderer.TButton.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TButton;
  event: string;
begin
  e := Scope.Element as THTML.TButton;
  if Context.Schema.Interactive then
    event := ' onclick="mnw.send(' + SQ(e.ID) + ', '+ SQ('click') + ')"';
  Context.Output.WriteLn('html', '<button type="button"' + event + '' + Scope.Attributes.GetText(True)+' >'+e.Caption+'</button>', [woOpenTag, woCloseTag]);
  inherited;
end;

{ TmnwHTMLRenderer.TInputHTML }

procedure TmnwHTMLRenderer.TInput.DoCollectAttributes(Scope: TmnwScope);
begin
  Scope.Attributes['placeholder'] := (Scope.Element as THTML.TInput).PlaceHolder;
  Scope.Attributes['type'] := (Scope.Element as THTML.TInput).EditType;
  inherited;
end;

procedure TmnwHTMLRenderer.TInput.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TInput;
  event: string;
begin
  e := Scope.Element as THTML.TInput;
  if e.Caption <> '' then
    Context.Output.WriteLn('html', '<label for="'+e.ID+'" >' + e.Caption + '</label>', [woOpenTag, woCloseTag]);
  if Context.Schema.Interactive then
    event := ' onchange="mnw.send(' + SQ(e.ID) + ', '+ SQ('change') + ',' + 'this.value' + ')"';

  Context.Output.WriteLn('html', '<input'+ event + When(e.Required, 'required') + Scope.Attributes.GetText(True)+' >', [woOpenTag, woCloseTag]);
  inherited;
end;

{ TmnwHTMLRenderer.TImageHTML }

procedure TmnwHTMLRenderer.TImage.DoPrepare(AElement: TmnwElement; ARenderer: TmnwRenderer);
begin
  inherited;
  ARenderer.Libraries.Use('JQuery');
end;

procedure TmnwHTMLRenderer.TImage.DoCollectAttributes(Scope: TmnwScope);
begin
  Scope.Attributes['src'] := (Scope.Element as THTML.TImage).Source;
  Scope.Attributes['alt'] := (Scope.Element as THTML.TImage).AltText; //* always set
  inherited;
end;

procedure TmnwHTMLRenderer.TImage.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
begin
  Context.Output.WriteLn('html', '<img' + Scope.Attributes.GetText(True)+' >', [woOpenTag, woCloseTag]);
  inherited;
end;

{ TmnwHTMLRenderer.TMemoryImageHTML }

procedure TmnwHTMLRenderer.TMemoryImage.DoPrepare(AElement: TmnwElement; ARenderer: TmnwRenderer);
begin
  inherited;
  ARenderer.Libraries.Use('JQuery');
end;

procedure TmnwHTMLRenderer.TMemoryImage.DoCollectAttributes(Scope: TmnwScope);
begin
  inherited;
  Scope.Attributes['src'] := IncludeURLDelimiter(Renderer.Module.GetHomeUrl) + Scope.Element.GetPath;
  Scope.Attributes['alt'] := (Scope.Element as THTML.TImage).AltText;
end;

procedure TmnwHTMLRenderer.TMemoryImage.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TMemoryImage;
begin
  e := Scope.Element as THTML.TMemoryImage;
  Context.Output.WriteLn('html', '<img'+ Scope.Attributes.GetText(True)+' >', [woOpenTag, woCloseTag]);
  inherited;
end;

{ TmnwRendererRegister }

constructor TmnwRendererRegister.Create;
begin
  inherited Create;
  Extensions := TClassList.Create;
end;

destructor TmnwRendererRegister.Destroy;
begin
  FreeAndNil(Extensions);
  inherited;
end;

{ TmnwSchema }

constructor TmnwSchema.Create(AParent: TmnwElement; AKind: TmnwElementKind; ARenderIt: Boolean);
begin
  inherited;
  FSchema := Self;
  FAttachments := TmnwAttachments.Create;
  FLock := TCriticalSection.Create;
  {$ifdef rtti_objects}
  CacheClasses;
  {$endif}
end;

destructor TmnwSchema.Destroy;
begin
  FAttachments.Terminate;
  FAttachments.Clear;
  FreeAndNil(FAttachments);
  FreeAndNil(FLock);
  inherited;
end;

procedure TmnwSchema.Attach(Route: string; Sender: TObject; AStream: TmnBufferStream);
var
  Attachment: TmnwAttachment;
begin
  Attachment := TmnwAttachment.Create;
  Attachment.Schema := Self;
  Attachment.Stream := AStream;
  Attachments.Add(Attachment);
  UpdateAttached;
  try
    Attachment.Loop;
    if not Attachment.Terminated then
      Attachment.Terminate;
  finally
    Attachments.Remove(Attachment);
    UpdateAttached;
  end;
end;

procedure TmnwSchema.DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
begin
  inherited;
  Render(AContext, ARespondResult);
end;

procedure TmnwSchema.ProcessMessage(const s: string);
var
  Json: TDON_Pair;
  element: TmnwElement;
  elementID: string;
  Error: string;
begin
  log.WriteLn(s);
  if s.StartsWith('{') then
  begin
    Json := JsonParseStringPair(s, Error, [jsoSafe]);
    try
      elementID := Json['element'].AsString;
      element := FindByID(elementID);
      if element <> nil then
      begin
        Lock.Enter;
        try
          element.ReceiveMessage(Json);
        finally
          Lock.Leave;
        end;
      end;
    finally
      Json.Free;
    end;
  end
end;

procedure UpdateElement(Element: TmnwElement);
var
  rttiContext: TRttiContext;
  attribute: TCustomAttributeClass;
  list: TClassList;
begin
//  log.Write(Element.ClassName);
  if Element = nil then
    raise Exception.Create('Element is nil');
  if Element.ClassType <> nil then
  begin
    list := TClassList.Create;
    rttiContext := TRttiContext.Create;
    try
      rttiCollectExtensions(rttiContext, Element.ClassType, list);
      for attribute in list do
        if attribute.InheritsFrom(TElementExtension) then
          TElementExtensionClass(attribute).Update(Element);
    finally
      rttiContext.Free;
      list.Free;
    end;
  end;
end;

class function TmnwSchema.GetCapabilities: TmnwSchemaCapabilities;
begin
  Result := [];
end;

function TmnwSchema.Interactive: Boolean;
begin
  Result := schemaInteractive in GetCapabilities;
end;

procedure TmnwSchema.Compose;
begin
  AddState([estComposing]);
  inherited;
  RemoveState([estComposing]);
  AddState([estComposed]);
end;

procedure TmnwSchema.UpdateAttached;
begin
  Attachments.Lock.Enter;
  try
    FAttached := Attachments.Count > 0;
  finally
    Attachments.Lock.Leave;
  end;
end;

procedure TmnwSchema.GenID(Element: TmnwElement);
var
  s: string;
  p: Integer;
begin
  if Element.ID = '' then
  begin
    Inc(NameingLastNumber);
    s := Element.ClassName;
    p := ReversePos('.', s);
    if p > 0 then
      s := Copy(s, p + 2, MaxInt) //* skip T
    else
      s := Copy(s, 2, MaxInt); //* skip T
    Element.ID := LowerCase(s + '-' + NameingLastNumber.ToString);
  end;
end;

procedure TmnwSchema.GenRoute(Element: TmnwElement);
var
  s: string;
  p: Integer;
begin
  if Element.Route = '' then
  begin
    Inc(NameingLastNumber);
    s := Element.ClassName;
    p := ReversePos('.', s);
    if p > 0 then
      s := Copy(s, p + 2, MaxInt) //* skip T
    else
      s := Copy(s, 2, MaxInt); //* skip T
    Element.Route := LowerCase(s + '-' + NameingLastNumber.ToString);
  end;
end;

{$ifdef rtti_objects}
procedure TmnwRenderer.RegisterClasses(ASchemaClass: TmnwSchemaClass);
var
  aObjectClass: TCacheClassObject;
  aName, aClassName: string;
begin
  aClassName := ClassName;
  for aObjectClass in CacheClassObjects do
  begin
    aName := SubStr(aObjectClass.ObjectClass.ClassName, '.', 1);
    if (aName = aClassName) then
    begin
    end;
  end;
end;
{$endif}

class procedure TmnwRenderer.RegisterRenderer(AElementClass: TmnwElementClass; ARendererClass: TmnwElementRendererClass; How: TmnwRegisterHow);
var
  aRendererRegister: TmnwRendererRegister;
begin
  aRendererRegister := ElementRenderers.Find(AElementClass);
  if aRendererRegister <> nil then
  begin
//    log.WriteLn('Replacing : '+AObjectClass.ClassName);
    if (How = Replace) and (AElementClass.InheritsFrom(aRendererRegister.ElementClass)) then
      aRendererRegister.RendererClass := ARendererClass
    else if (How = Extend) and (AElementClass.InheritsFrom(aRendererRegister.ElementClass)) then
      aRendererRegister.Renderers := aRendererRegister.Renderers + [ARendererClass]
    else
      raise Exception.Create('You can''t re-register same class: '+ AElementClass.ClassName);
  end
  else
  begin
    if (How = Extend) then
      raise Exception.Create('Ops we can''t add extended, we need to optimize code: '+ AElementClass.ClassName);
    //log.WriteLn(AObjectClass.ClassName);
    aRendererRegister := TmnwRendererRegister.Create;
    aRendererRegister.ElementClass := AElementClass;
    aRendererRegister.RendererClass := ARendererClass;
    aRendererRegister.Level := AElementClass.ClassLevel;
    rttiCollectExtensions(aRendererRegister.ElementClass, aRendererRegister.Extensions);
    ElementRenderers.Add(aRendererRegister);
  end;
end;

function TmnwRenderer.CreateRenderer(AElementClass: TmnwElementClass): TmnwElementRenderer;
var
  aRendererRegister: TmnwRendererRegister;
begin
  aRendererRegister := ElementRenderers.Find(AElementClass, True);
  if aRendererRegister <> nil then
    Result := aRendererRegister.RendererClass.Create(Self, aRendererRegister)
  else
    Result := nil;
end;

function TmnwRenderer.CreateRenderer(AObject: TmnwElement): TmnwElementRenderer;
begin
  Result := CreateRenderer(TmnwElementClass(AObject.ClassType));
end;

{ TContent }

procedure THTML.TContent.Added(Item: TmnwElement);
begin
  inherited Added(Item);
end;

{ THTML.TDocument }

procedure THTML.TDocument.Created;
begin
  inherited;
  FBody := TBody.Create(Self, [elEmbed, elInternal], True);
end;

destructor THTML.TDocument.Destroy;
begin
{  FreeAndNil(FBody); }
  inherited;
end;

{ THTML.TInput }

procedure THTML.TInput.SetText(const AValue: string);
begin
  if FText =AValue then Exit;
  FText :=AValue;
  if (estComposed in State) and (Schema <> nil) and Schema.Attached then
    SendMessage('"command": "change", "content": ' + DQ(Text));
end;

procedure THTML.TInput.Created;
begin
  inherited;
  EditType := 'text';
end;

procedure THTML.TInput.ReceiveMessage(JSON: TDON_Pair);
begin
  if JSON['command'].AsString = 'change' then
  begin
    if JSON['content'].IsExists then
      FText := JSON['content'].AsString;
    if JSON['caption'].IsExists then
      FText := JSON['caption'].AsString;
  end;
end;

{ THTML.TInputPassword }

procedure THTML.TInputPassword.Created;
begin
  inherited;
  EditType := 'password';
end;

{ THTML.TMemoryImage }

procedure THTML.TMemoryImage.Created;
begin
  inherited;
  FData := TMemoryStream.Create;
end;

destructor THTML.TMemoryImage.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

function THTML.TMemoryImage.GetContentType(Route: string): string;
begin
  Result := DocumentToContentType(FileName);
end;

procedure THTML.TMemoryImage.DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
begin
  Data.Seek(0, soBeginning);
  AContext.Stream.WriteStream(Data, 0);
end;

procedure THTML.TMemoryImage.LoadFromFile(const AFileName: string);
begin
  Data.LoadFromFile(AFileName);
  FileName := ExtractFilePath(ExtractFileName(AFileName));
end;

procedure THTML.TMemoryImage.LoadFromStream(AStream: TStream);
begin
  Data.LoadFromStream(AStream);
  FileName := '';
  FilePath := '';
end;

{ TmnwElement }

function TmnwElement.This: TmnwElement;
begin
  Result := Self;
end;

function TmnwElement.GetPath: string;
begin
  if (Parent <> nil) then
  begin
    if Route <> '' then
      Result := IncludeURLDelimiter(Parent.GetPath) + Route
    else
      Result := Parent.GetPath;
  end
  else
    Result := Route;
end;

procedure TmnwElement.SetState(const AValue: TmnwElementState);
begin
  if FState =AValue then Exit;
  FState :=AValue;
end;

procedure TmnwElement.Update;
begin

end;

procedure TmnwElement.Added(Item: TmnwElement);
begin
  inherited;
  Item.Update;
end;

procedure TmnwElement.Check;
var
  o: TmnwElement;
begin
  for o in Self do
    o.Check;
end;

function TmnwElement.Find(const Name: string): TmnwElement;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Items[i].Name, Name) then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TmnwElement.FindObject(ObjectClass: TmnwElementClass; AName: string; RaiseException: Boolean): TmnwElement;
var
  o: TmnwElement;
begin
  Result := nil;
  for o in Self do
  begin
    if (o.InheritsFrom(ObjectClass) and (SameText(o.Name, AName))) then
    begin
      Result := o;
      exit;
    end;
  end;
  for o in Self do
  begin
    Result := o.FindObject(ObjectClass, AName);
    if Result <> nil then
      exit;
  end;
  if RaiseException and (Result = nil) then
    raise Exception.Create(ObjectClass.ClassName + ': ' + AName +  ' not exists in ' + Name);
end;

function TmnwElement.FindByID(const aID: string): TmnwElement;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Items[i].ID, aID) then
      Result := Items[i]
    else
      Result := Items[i].FindByID(aID);
    if Result <> nil then
      break;
  end;
end;

function TmnwElement.FindByName(const aName: string): TmnwElement;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Items[i].Name, aName) then
      Result := Items[i]
    else
      Result := Items[i].FindByID(aName);
    if Result <> nil then
      break;
  end;
end;

function TmnwElement.FindByRoute(const Route: string): TmnwElement;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if (Items[i].Route <> '') then
    begin
      if SameText(Items[i].Route, Route) then
        Result := Items[i];
    end
    else
      Result := Items[i].FindByRoute(Route);
    if Result <> nil then
      break;
  end;
  {if (Result = nil) and (Route <> '') then
    Result := Self;}
end;

procedure TmnwElement.DoCompose;
begin
end;

procedure TmnwElement.DoExecute;
begin
end;

procedure TmnwElement.Execute;
begin
  if Assigned(OnExecute) then
    OnExecute();
  DoExecute;
end;

procedure TmnwElement.DoChanged;
begin
  DoChanged;
end;

procedure TmnwElement.Changed;
begin

end;

procedure TmnwElement.SendMessage(AMessage: string);
begin
  if Schema <> nil then
    Schema.Attachments.SendMessage('{"element": ' + DQ(ID) + ', ' + AMessage + '}');
end;

procedure TmnwElement.SendMessage(JSON: TDON_Pair);
begin
end;

procedure TmnwElement.ReceiveMessage(JSON: TDON_Pair);
begin
end;

procedure TmnwElement.DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
begin
end;

procedure TmnwElement.DoRespondHeader(AContext: TmnwRespondContext);
begin
end;

procedure TmnwElement.DoAction(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
begin
end;

constructor TmnwElement.Create(AParent: TmnwElement; AKind: TmnwElementKind; ARenderIt: Boolean);
begin
  inherited Create;
  FEnabled := True;
  FVisible := True;
  FRenderIt := ARenderIt;
  FName := '';
  FAttributes := TmnwAttributes.Create;
  FKind := AKind;
  FParent := AParent;
  if FParent <> nil then
  begin
    FSchema:= FParent.FSchema;
    FParent.Add(Self);
  end;
end;

destructor TmnwElement.Destroy;
begin
  FreeAndNil(FAttributes);
  inherited;
end;

class function TmnwElement.ClassLevel: Integer;
var
  c: TClass;
begin
  Result := 0;
  c := Self;
  while c <> nil do
  begin
    c := c.ClassParent;
    inc(Result);
  end;
end;

procedure TmnwElement.Add(O: TmnwElement);
begin
  O.FParent := Self;
  O.FSchema := FSchema;
  inherited Add(O);
end;

//in FPC if you got error, change <O: TmnwElement> to <O>
function TmnwElement.Add<O>(const AID: String; const AName: String): O;
begin
  Result := O.Create(Self);
  Result.FID := AID;
  Result.FName := AName;
end;

function TmnwElement.IndexOfName(vName: string): Integer;
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

function LevelStr(vLevel: Integer): String;
begin
  Result := StringOfChar(' ', vLevel * 4);
end;

function TmnwElement.Render(Sender: TObject; Schema: TmnwSchema; Renderer: TmnwRenderer; AOutput: TmnwOutput; var ARespondResult: TmnwRespondResult): Boolean;
var
  aContext: TmnwRenderContext;
begin
  Result := False;
  aContext.Schema := Schema;
  aContext.Renderer := Renderer;
  aContext.Sender := Sender;
  aContext.ParentRenderer := nil;
  aContext.Output := AOutput;
  Render(aContext, ARespondResult);
  Result := True;
end;

procedure TmnwElement.Respond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
begin
  DoRespond(AContext, ARespondResult);
end;

procedure TmnwElement.Respond(AContext: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  context: TmnwRespondContext;
begin
  context.Route := '';
  context.Sender := AContext.Sender;
  context.Schema := AContext.Schema;
  context.Renderer := AContext.Renderer;
  context.Stream := AContext.Output['html'].Stream;
  context.MultipartData := nil;
  Respond(context, ARespondResult);
end;

function TmnwElement.Render(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult): Boolean;
var
  Writer: TmnwWriter;
  Output: TmnwOutput;
begin
  Writer := TmnwWriter.Create('html', AContext.Stream);
  Output := TmnwOutput.Create;
  Output.Add(Writer);
  try
    Result := Render(AContext.Sender, AContext.Schema, AContext.Renderer, Output, ARespondResult);
  finally
    FreeAndNil(Output);
  end;
  Result := True;
end;

procedure TmnwElement.Compose;
var
  o: TmnwElement;
begin
//  Clear; //*Should not clear here
  DoCompose;
  UpdateElement(Self);
  for o in Self do
  begin
    o.Compose;
  end;
end;

procedure TmnwElement.AddState(AState: TmnwElementState);
var
  o: TmnwElement;
begin
  FState := FState + AState;
  for o in Self do
  begin
    o.AddState(AState);
  end;
end;

procedure TmnwElement.RemoveState(AState: TmnwElementState);
var
  o: TmnwElement;
begin
  FState := FState - AState;
  for o in Self do
  begin
    o.RemoveState(AState);
  end;
end;

procedure TmnwElement.Clear;
begin
  inherited;
  RemoveState([estComposed]);
end;

function TmnwElement.GetContentType(Route: string): string;
begin
  Result := 'text/html';
end;

procedure TmnwElement.Action(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
begin
  (AContext.Sender as TmodHttpCommand).Respond.PutHeader('Content-Type', GetContentType(AContext.Route)); //* move outside of mnWebElement.pas please
  DoRespondHeader(AContext);
  ARespondResult.Resume := True;
  DoAction(AContext, ARespondResult);
  if ARespondResult.ContentType <> '' then
  (AContext.Sender as TmodHttpCommand).Respond.PutHeader('Content-Type', ARespondResult.ContentType); //* move outside of mnWebElement.pas please
end;

constructor TmnwWriter.Create(AName: string; AStream: TmnBufferStream);
begin
  inherited Create;
  Name := AName;
  FStream := AStream;
end;

procedure TmnwWriter.Write(S: string; Options: TmnwWriterOptions);
begin
	if (woCloseTag in Options) and not (woOpenTag in Options) then
    Dec(Level);

  if (NewLine) then
    S := LevelStr(Level) + S;

  NewLine := False;

	if (woEndLine in Options) then
  begin
    NewLine := True;
    s := S + sWinEndOfLine;
  end;

  FStream.WriteUtf8String(S);

	if (woOpenTag in Options) and not (woCloseTag in Options) then
    Inc(Level);
end;

{ TmnwRenderer }

procedure TmnwRenderer.BeginRender;
begin
  DoBeginRender;
end;

constructor TmnwRenderer.Create(AModule: TmodWebModule; IsLocal: Boolean);
{var
  o: TmnwRenderer.TmnwRendererRegister;}
begin
  FLibraries := TmnwLibraries.Create;
  FLibraries.Local := IsLocal;
  inherited Create;
  FModule := AModule;
  FParams := TmnwAttributes.Create;
  //Renderers := TmnwElementRenderers.Create();
{  for o in Renderers do
    log.WriteLn(o.ObjectClass.ClassName);}
  if not ElementRenderers.Sorted then
    ElementRenderers.QuickSort;
  {log.WriteLn('---------------------------');
  for o in Renderers do
    log.WriteLn(o.ObjectClass.ClassName);}
end;

destructor TmnwRenderer.Destroy;
begin
  FreeAndNil(FParams);
  FreeAndNil(FLibraries);
  inherited;
end;

class destructor TmnwRenderer.Destroy;
begin
end;

procedure TmnwRenderer.EndRender;
begin
  DoEndRender;
end;

procedure TmnwRenderer.DoBeginRender;
begin
end;

procedure TmnwRenderer.DoEndRender;
begin
end;

class constructor TmnwRenderer.RegisterObjects;
begin
  ElementRenderers := TmnwElementRenderers.Create;
  RegisterRenderer(TmnwElement, TmnwElementRenderer);
end;

{$ifdef rtti_objects}
{ TCacheClassObjects }

procedure TCacheClassObjects.AddClass(ObjectClass: TClass);
var
  aObject: TCacheClassObject;
begin
  aObject:=TCacheClassObject.Create;
  aObject.ObjectClass := ObjectClass;
  inherited Add(aObject);
end;
{$endif}

{ THTML.TFile }

procedure THTML.TFile.DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
var
  ResStream: TStream;
begin
  inherited;
  if ftResource in Options then
  begin
    ResStream := TResourceStream.Create(hInstance, ChangeFileExt(FileName, ''), RT_RCDATA) //* remove extension
  end
  else
    ResStream := TFileStream.Create(FileName, fmShareDenyWrite or fmOpenRead);
  try
    AContext.Stream.WriteStream(ResStream, 0);
  finally
    ResStream.Free;
  end;
end;

constructor THTML.TFile.Create(AParent: TmnwElement; AOptions: TFileOptions; AFileName: string);
begin
  inherited Create(AParent);
  Options := AOptions;
  FileName := AFileName;
  if not (ftEmbed in Options) then
    Route := ChangeFileExt(ExtractFileName(FileName), '');
end;

function THTML.TFile.GetContentType(Route: string): string;
begin
  Result := DocumentToContentType(FileName);
end;

{ THTML.TAssets }

procedure THTML.TAssets.DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
var
  fs: TFileStream;
  aFileName: string;
begin
  inherited;
  if HomePath <> '' then
  begin
    if WebExpandFile(HomePath, AContext.Route, aFileName) then
    begin
      if FileExists(aFileName) then
      begin
        fs := TFileStream.Create(aFileName, fmShareDenyWrite or fmOpenRead);
        try
          AContext.Stream.WriteStream(fs, 0);
        finally
          fs.Free;
        end;
      end;
    end;
  end;
end;

function THTML.TAssets.GetContentType(Route: string): string;
begin
  Result := DocumentToContentType(Route);
end;

{ THTML.TContentCompose }

constructor THTML.TContentCompose.Create(AParent: TmnwElement; AOnCompose: TContentComposeProc);
begin
  inherited Create(AParent);
  OnCompose := AOnCompose;
end;

procedure THTML.TContentCompose.DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
var
  InnerComposer: TInnerComposer;
begin
  inherited;
  //Clear; //here not in Compose
  //Compose;
  {InnerComposer := TInnerComposer.Create(nil);
  InnerComposer.FParent := Self;
  TContentCompose(InnerComposer).DoCompose;
  //InnerComposer.OnCompose;
  Render(ARenderer, Sender, AStream);}

  InnerComposer := TInnerComposer.Create(nil);
  try
    //InnerComposer.FSchema := Schema;
    InnerCompose(InnerComposer);
    if Assigned(OnCompose) then
      OnCompose(InnerComposer);
    InnerComposer.Render(AContext, ARespondResult);
  finally
    InnerComposer.Free;
  end;

end;

procedure THTML.TContentCompose.InnerCompose(Inner: TmnwElement);
begin
end;

{ TmnwLibrary }

procedure TmnwLibrary.DecUsage;
begin
  FUsage := FUsage - 1;
end;

procedure TmnwLibrary.IncUsage;
begin
  FUsage := FUsage + 1;
end;

{ TmnwLibraries }

function TmnwLibraries.Find(ALibrary: string; OnlyLocal: Boolean): TmnwLibrary;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
    if (SameText(Items[i].Name, ALibrary)) and (not OnlyLocal or Items[i].IsLocal)  then
    begin
      Result := Items[i];
      break;
    end;
end;

procedure TmnwLibraries.RegisterLibrary(ALibraryName: string; IsLocal: Boolean; ALibraryClass: TmnwLibraryClass);
var
  ALibrary: TmnwLibrary;
begin
  ALibrary := ALibraryClass.Create;
  ALibrary.Name := ALibraryName;
  ALibrary.IsLocal := IsLocal;
  Add(ALibrary);
end;

procedure TmnwLibraries.Use(ALibrary: TmnwLibrary);
begin
  if ALibrary <> nil then
    ALibrary.IncUsage
  else
    raise Exception.Create('library is nil');
end;

procedure TmnwLibraries.Use(ALibraryName: string);
var
  ALibrary: TmnwLibrary;
begin
  ALibrary := Find(ALibraryName, Local);
  if (ALibrary = nil) and Local then
    ALibrary := Find(ALibraryName, False);
  if ALibrary <> nil then
    Use(ALibrary)
  else
    raise Exception.Create('There is no library: ' + ALibraryName);
end;

{ TJQuery_Library }

procedure TJQuery_Library.AddHead(AElement: TmnwElement; const Context: TmnwRenderContext);
begin
  Context.Output.WriteLn('html', '<script src="' + 'https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/' + 'jquery.min.js" crossorigin="anonymous"></script>');
end;

{ TJQuery_LocalLibrary }

procedure TJQuery_LocalLibrary.AddHead(AElement: TmnwElement; const Context: TmnwRenderContext);
begin
  Context.Output.WriteLn('html', '<script src="' + IncludeURLDelimiter(Context.Renderer.Module.GetAssetsURL) + 'jquery.min.js" crossorigin="anonymous"></script>');
end;

{ THTML }

{ THTML.TImage }

procedure THTML.TImage.DoCompose;
begin
  inherited;
end;

{ TmnwHTMLRenderer.TFile }

procedure TmnwHTMLRenderer.TFile.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TFile;
begin
  e := Scope.Element as THTML.TFile;
  if ftEmbed in e.Options then
    Scope.Element.Respond(Context, ARespondResult);
  inherited;
end;

{ THTML.TBody }

{function THTML.TBody.GetNavBar: TNavBar;
begin
  if FNavBar = nil then
    FNavBar := TNavBar.Create(Self, [elEmbed], True);
  Result := FNavBar;
end;}

function THTML.TBody.GetHeader: THeader;
begin
  if FHeader = nil then
    FHeader := THeader.Create(Self, [elEmbed], True);
  Result := FHeader
end;

function THTML.TBody.GetContainer: TContainer;
begin
  if FContainer = nil then
    FContainer := TContainer.Create(Self, [elEmbed], True);
   Result := FContainer;
end;

function THTML.TBody.GetFooter: TFooter;
begin
  if FFooter = nil then
  begin
    GetContainer; //force Container be created before footer
    FFooter := TFooter.Create(Self, [elEmbed], True);
  end;
  Result := FFooter;
end;

procedure THTML.TBody.Created;
begin
  inherited;
end;

destructor THTML.TBody.Destroy;
begin
{  FreeAndNil(FHeader); Nope
  FreeAndNil(FFooter);
  FreeAndNil(FContainer);}
  inherited;
end;

{ TmnwHTMLRenderer.TBody }

procedure TmnwHTMLRenderer.TBody.DoCollectAttributes(Scope: TmnwScope);
begin
  inherited;
end;

procedure TmnwHTMLRenderer.TBody.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TBody;
  function GetAttach: string;
  begin
    if schemaInteractive in Context.Schema.GetCapabilities then
    begin
      Result := ' data-mnw-interactive="true"';
    end;
  end;
begin
  e := Scope.Element as THTML.TBody;
  Context.Output.WriteLn('html', '<body' + Scope.Attributes.GetText(True) + GetAttach + '>', [woOpenTag]);
  inherited;
  Context.Output.WriteLn('html', '</body>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TPanel }

procedure TmnwHTMLRenderer.TPanel.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TPanel;
begin
  e := Scope.Element as THTML.TPanel;
  Context.Output.WriteLn('html', '<div class="panel">', [woOpenTag]);
  if e.Caption <> '' then
    Context.Output.WriteLn('html', '<div class="panel-header">' + e.Caption + '</div>', [woOpenTag, woCloseTag]);

  Context.Output.WriteLn('html', '<div class="panel-body">', [woOpenTag]);
  inherited;
  Context.Output.WriteLn('html', '</div>', [woCloseTag]);
  Context.Output.Writeln('html', '</div>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TRow }

procedure TmnwHTMLRenderer.TRow.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TRow;
begin
  e := Scope.Element as THTML.TRow;
  Context.Output.WriteLn('html', '<div class="row">', [woOpenTag]);
  inherited;
  Context.Output.Writeln('html', '</div>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TColumn }

procedure TmnwHTMLRenderer.TColumn.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TColumn;
begin
  e := Scope.Element as THTML.TColumn;
  Context.Output.WriteLn('html', '<div class="column">', [woOpenTag]);
  inherited;
  Context.Output.Writeln('html', '</div>', [woCloseTag]);
end;

{ THTML.TContainer }

procedure THTML.TContainer.Created;
begin
  inherited;
  Margin := 3;
  Size := 1;
end;

{ THTML.TForm }

procedure THTML.TForm.DoAction(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
begin
  inherited;
  if (RedirectTo <> '') and (ARespondResult.HttpResult = hrNone) then
  begin
    ARespondResult.HttpResult := hrRedirect;
    ARespondResult.Location := RedirectTo;
  end;
end;

{ THTML.TParagraph }

constructor THTML.TParagraph.Create(AParent: TmnwElement; AText: string);
begin
  inherited Create(AParent);
  Text := AText;
end;

{ THTML.TAction }

procedure THTML.TAction.DoRespond(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
begin
  inherited;
  try
    Execute;
    AContext.Stream.WriteUTF8Line('Executed');
  finally
  end;
end;

procedure THTML.TAction.Loop;
begin
end;

{ THTML.TButton }

procedure THTML.TButton.SetCaption(const AValue: string);
begin
  if FCaption =AValue then Exit;
  FCaption :=AValue;
  if (estComposed in State) and (Schema <> nil) and Schema.Attached then
    SendMessage('"command": "change", "content": ' + DQ(Caption));
end;

procedure THTML.TButton.ReceiveMessage(JSON: TDON_Pair);
begin
  if JSON['command'].AsString = 'change' then
  begin
    if JSON['caption'].IsExists then
      FCaption := JSON['caption'].AsString;
  end
  else if JSON['command'].AsString = 'click' then
    Execute;
end;

procedure THTML.TButton.DoChanged;
begin
  inherited;
end;

{ TNameAttribute }

class procedure TIDExtension.Update(Element: TmnwElement);
begin
  Element.Schema.GenID(Element);
end;

{ TRouteExtension }

class procedure TRouteExtension.Update(Element: TmnwElement);
begin
  Element.Schema.GenRoute(Element);
end;

{ TmnwHTMLRenderer.TContentCompose }

procedure TmnwHTMLRenderer.TContentCompose.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
begin
  Context.Output.WriteLn('html', '<div ' + Scope.Attributes.GetText(True)+'>', [woOpenTag]);
  inherited;
  Scope.Element.Respond(Context, ARespondResult);
  Context.Output.WriteLn('html', '</div>', [woCloseTag]);
end;

{ TmnwHTMLRenderer.TIntervalCompose }

procedure TmnwHTMLRenderer.TIntervalCompose.DoCollectAttributes(Scope: TmnwScope);
var
  URL: string;
begin
  inherited;
  URL := IncludeURLDelimiter(Renderer.Module.GetHomeUrl) + Scope.Element.GetPath;
  Scope.Attributes['data-mnw-refresh-url'] := URL;
end;

{ TmnwHTMLRenderer.TJSFile }

procedure TmnwHTMLRenderer.TJSFile.DoInnerRender(Scope: TmnwScope; Context: TmnwRenderContext; var ARespondResult: TmnwRespondResult);
var
  e: THTML.TJSFile;
  src: string;
begin
  e := Scope.Element as THTML.TJSFile;
  if ftEmbed in e.Options then
  begin
    Context.Output.WriteLn('html', '<script type="text/javascript"'+ Scope.Attributes.GetText(True)+'>', [woOpenTag]);
    inherited;
    Context.Output.WriteLn('html', '');
    Context.Output.WriteLn('html', '</script>', [woCloseTag]);
  end
  else
  begin
    src := IncludeURLDelimiter(Renderer.Module.GetHomeUrl) + Scope.Element.GetPath;
    Context.Output.WriteLn('html', '<script type="text/javascript" src='+ DQ(src) +' ></script>', [woOpenTag, woCloseTag]);
    inherited;
  end;
end;

{ TbsHttpGetHomeCommand }

function TmnwHttpGetHomeCommand.GetModule: TmnwWebModule;
begin
  Result := (inherited Module) as TmnwWebModule;
end;

procedure TmnwHttpGetHomeCommand.RespondResult(var Result: TmodRespondResult);
var
  aContext: TmnwRespondContext;
  aDate: TDateTime;
  aPath: string;
  aRespondResult: TmnwRespondResult;
begin
  Initialize(aContext);
  inherited;
  if Request.ConnectionType = ctWebSocket then
  begin
    (Module as TmnwWebModule).Schemas.Attach(DeleteSubPath('', Request.Path), Self, Respond.Stream); //Serve the websocket
    //Result.Status := Result.Status - [mrKeepAlive]; // Disconnect
  end
  else
  begin
    aContext.Route := DeleteSubPath('', Request.Path);
    aContext.Sender := Self;
    aContext.Stream := Respond.Stream;
    aContext.MultipartData := TmnMultipartData.Create; //yes always created, i maybe pass params that come from Query (after ? )

    aContext.SessionID := Request.Cookies.Values['session'];
    if Request.ConnectionType = ctFormData then
    begin
      aContext.MultipartData.Boundary := Request.Header.Field['Content-Type'].SubValue('boundary');
      aContext.MultipartData.TempPath := (Module as TmnwWebModule).WorkPath + 'temp';
      aContext.MultipartData.Read(Request.Stream);
    end;
    Respond.PutHeader('Content-Type', DocumentToContentType('html'));
    Respond.HttpResult := hrOK;
    aContext.Renderer := (Module as TmnwWebModule).CreateRenderer(True);
    try
      Initialize(aRespondResult);
      aRespondResult.SessionID := '';
      aRespondResult.HttpResult := hrOK;
      aRespondResult.Location := '';
      (Module as TmnwWebModule).Schemas.Respond(aContext, aRespondResult);
      aDate := IncSecond(Now, 30 * SecsPerMin);
      aPath := '';
      Respond.SetCookie('home', 'session', 'session; Expires='+FormatHTTPDate(aDate)+'; SameSite=None; Domain=' + Module.Domain + '; Path=/'+aPath+'; Secure');
      //SessionID
    finally
      aContext.Renderer.Free;
      aContext.MultipartData.Free;
    end;
  end;
end;

{ TmnwWebModule }

procedure TmnwWebModule.DoPrepareRequest(ARequest: TmodRequest);
begin
  inherited;
  if StartsStr('.', ARequest.Route[ARequest.Route.Count - 1]) then
    ARequest.Command := ARequest.Route[ARequest.Route.Count - 1]
  else
    ARequest.Command := ARequest.Route[1];
  //ARequest.Path := DeleteSubPath(ARequest.Command, ARequest.Path);
end;

procedure TmnwWebModule.CreateItems;
begin
  inherited;
  Schemas := TmnwWebSchemas.Create;
  Schemas.Module := Self;
  RegisterCommand('', TmnwHttpGetHomeCommand, true);
end;

procedure TmnwWebModule.Created;
begin
  inherited;
end;

function TmnwWebModule.CreateRenderer(IsLocal: Boolean): TmnwRenderer;
begin
  Result := TmnwHTMLRenderer.Create(Self, IsLocal);
end;

destructor TmnwWebModule.Destroy;
begin
  inherited;
  FreeAndNil(Schemas); //keep behind inherited
end;

{ TmnwWebSchemas }

procedure TmnwWebSchemas.SchemaCreated(Schema: TmnwSchema);
begin
  inherited;
  if Schema is TmnwWebSchema then
    (Schema as TmnwWebSchema).Module := Module;
end;

initialization

finalization
  FreeAndNil(ElementRenderers);
{$ifdef rtti_objects}
  FreeAndNil(CacheClassObjects);
{$endif}
end.
