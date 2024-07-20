unit HomeModules;

{$H+}{$M+}
{$ifdef fpc}
{$mode delphi}
{$modeswitch functionreferences}{$modeswitch anonymousfunctions}
{$endif}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils,
  mnUtils, mnStreams, mnModules, mnWebModules, mnMultipartData,
	mnLogs, mnWebElements, mnBootstraps;

type
  THomeModule = class;

  TCustomHomeSchema = class(TmnwBootstrapHTML)
  public
    Module: THomeModule;
  end;

  { TAssetsSchema }

  TAssetsSchema = class(TCustomHomeSchema)
  private
  public
  protected
    procedure DoCompose; override;
  public
  end;

  { TWelcomeSchema }

  TWelcomeSchema = class(TCustomHomeSchema)
  private
  protected
    Input1: THTML.TInput;
    Input2: THTML.TInput;
    Input3: THTML.TInput;
    procedure DoCompose; override;
  public
    class function GetCapabilities: TmnwSchemaCapabilities; override;
  end;

  TWSShema = class(TCustomHomeSchema)
  private
  public
  protected
    procedure DoCompose; override;
  public
  end;

  { TLoginSchema }

  TLoginSchema = class(TCustomHomeSchema)
  private
  public
  protected
    procedure DoAction(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult); override;
    procedure DoCompose; override;
  public
  end;

  { TbsHttpGetHomeCommand }

  TbsHttpGetHomeCommand = class(TmodHttpCommand)
  protected
  public
    procedure RespondResult(var Result: TmodRespondResult); override;
  end;

  TWSEchoGetHomeCommand = class(TmodHttpCommand)
  protected
    FPool: TmnPool;
  public
    procedure RespondResult(var Result: TmodRespondResult); override;
    property Pool: TmnPool read FPool;
  end;

  THomeSchemas = class(TmnwSchemas)
  protected
    Module: THomeModule;
    procedure SchemaCreated(Schema: TmnwSchema); override;
  end;

  { THomeModule }

  THomeModule = class(TmodWebModule)
  private
  protected
    procedure DoRegisterCommands; override;
    procedure Start; override;
    procedure Created; override;

    procedure DoPrepareRequest(ARequest: TmodRequest); override;

  public
    AppPath: string;
    Schemas: THomeSchemas;
    destructor Destroy; override;
  end;

implementation

uses
  mnMIME, mnParams;

type

  { TClockComposer }

  TClockCompose = class(THTML.TIntervalCompose)
  public
    procedure InnerCompose(Inner: TmnwElement); override;
  end;

  TThreadTimer = class(TThread)
  public
  end;

  { TMyAction }

  TMyAction = class(THTML.TAction)
  public
    procedure DoExecute; override;
  end;

  { TMyButton }

  TMyButton = class(THTML.TButton)
  public
    procedure DoExecute; override;
  end;

{ TMyButton }

procedure TMyButton.DoExecute;
begin
  inherited;
  with (Schema as TWelcomeSchema) do
  begin
	  Input3.Text := IntToStr(StrToIntDef(Input1.Text, 0) + StrToIntDef(Input2.Text, 0));
  end;
end;

{ TMyAction }

procedure TMyAction.DoExecute;
begin
  inherited;
  if Schema <> nil then
    Schema.Attachments.SendMessage('{"type": "text", "element": "input1", "value": "my new value"}');
end;

{ TClockComposer }

procedure TClockCompose.InnerCompose(Inner: TmnwElement);
begin
  with THTML do
  begin
    TParagraph.Create(Inner, TimeToStr(Now));
    {with TImage.Create(Self) do
    begin
      Name := 'file_logo';
  //          Route := 'logo';
      Source := IncludeURLDelimiter(Module.HomeURL)+'assets/logo.png';
    end;}
  end;
end;

{ TWellcomeSchema }

procedure TWelcomeSchema.DoCompose;
begin
  inherited;
  Name := 'welcome';
  Route := 'welcome';

  with TDocument.Create(This) do
  begin
    Name := 'document';
    //Route := 'document';
    Title := 'MyHome';
    Direction := dirLTR;
    with Body do
    begin
      //TJSFile.Create(This, [ftResource], 'mnWebElements.js');
      TJSFile.Create(This, [], ExpandFileName(Module.AppPath + '../../source/mnWebElements.js'));

      Header.Text := 'Creative Solutions';
      with TImage.Create(This) do
      begin
        Name := 'image_logo';
        Comment := 'Image from another module';
        Source := IncludeURLDelimiter(Module.Host)+'doc/logo.png';
      end;

      Header.RenderIt := True;
      Footer.RenderIt := True;

      with Container do
      begin
        Name := 'Container';
        with TParagraph.Create(This) do
        begin
          Text := 'Hello Word';
          Name := 'p1';
        end;

        with TMyAction.Create(This) do
        begin
          Route := 'myaction';
        end;

        with TCard.Create(This) do
        begin
          Caption := 'Welcome';
          Name := 'card';

          with TMemoryImage.Create(This) do
          begin
            Name := 'logo';
            Route := 'logo';
            LoadFromFile(IncludePathDelimiter(Module.HomePath) + 'logo.png');
          end;

{          with TImage.Create(This) do
          begin
            Name := 'logo';
  //          Route := 'logo';
              Source := IncludeURLDelimiter(Module.HomeURL)+'assets/logo';
          end;}

          with TRow.Create(This) do
          begin
            Input1 := TInput.Create(This);
            with Input1 do
            begin
              Name := 'Input1';
              id := 'input1';
              Caption := 'Number 1';
            end;

            Input2 := TInput.Create(This);
            with Input2 do
            begin
              Name := 'Input2';
              Caption := 'Number 2';
            end;

            with TMyButton.Create(This) do
            begin
              ID := 'Add';
              Name := 'AddBtn';
              Caption := 'Add';
            end;

            Input3 := TInput.Create(This);
            with Input3 do
            begin
              Name := 'Input3';
              Caption := 'Result';
            end;

          end;

{$ifdef fpc}
{          with TClockCompose.Create(This) do
          begin
          end;}
{$else}
          with TIntervalCompose.Create(This) do
          begin
            Route := 'clock';
            OnCompose := procedure(Inner: TmnwElement)
            begin
              TParagraph.Create(Inner, TimeToStr(Now));
              {with TImage.Create(Inner) do
              begin
                Name := 'file_logo';
      //          Route := 'logo'; 
                Source := IncludeURLDelimiter(Module.HomeURL)+'assets/logo.png';
              end;}
            end;
          end;
{$endif}

        end;
      end;
    end;
  end;
end;

class function TWelcomeSchema.GetCapabilities: TmnwSchemaCapabilities;
begin
  Result := [schemaInteractive] + Inherited GetCapabilities;
  //Result := Inherited GetCapabilities;
end;

{ TbsHttpGetHomeCommand }

procedure TbsHttpGetHomeCommand.RespondResult(var Result: TmodRespondResult);
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
    (Module as THomeModule).Schemas.Attach(DeleteSubPath('', Request.Path), Self, Respond.Stream); //Serve the websocket
    //Result.Status := Result.Status - [mrKeepAlive]; // Disconnect
  end
  else
  begin
    aContext.Route := DeleteSubPath('', Request.Path);
    aContext.Sender := Self;
    aContext.Stream := Respond.Stream;

    aContext.SessionID := Request.Cookies.Values['session'];
    if Request.ConnectionType = ctFormData then
    begin
      aContext.MultipartData := TmnMultipartData.Create;
      aContext.MultipartData.Boundary := Request.Header.Field['Content-Type'].SubValue('boundary');
      aContext.MultipartData.TempPath := (Module as THomeModule).WorkPath + 'temp';
      aContext.MultipartData.Read(Request.Stream);
    end
    else
      aContext.MultipartData := nil;
    Respond.PutHeader('Content-Type', DocumentToContentType('html'));
    Respond.HttpResult := hrOK;
    aContext.Renderer := TmnwBootstrapRenderer.Create(Module as TmodWebModule, True);
    try
      Initialize(aRespondResult);
      aRespondResult.SessionID := '';
      aRespondResult.HttpResult := hrOK;
      aRespondResult.Location := '';
      (Module as THomeModule).Schemas.Respond(aContext, aRespondResult);
      aDate := IncSecond(Now, 30 * SecsPerMin);
      aPath := '';
      Respond.SetCookie('home', 'session', Format('%s; Expires=%s; SameSite=None; Domain=%s; Path=/%s; Secure', ['session', FormatHTTPDate(aDate), (Module as THomeModule).DomainName, aPath]))
      //SessionID
    finally
      aContext.Renderer.Free;
      aContext.MultipartData.Free;
    end;
  end;
end;

{ THomeModule }

procedure THomeModule.DoPrepareRequest(ARequest: TmodRequest);
begin
  inherited;
  if StartsStr('.', ARequest.Route[ARequest.Route.Count - 1]) then
    ARequest.Command := ARequest.Route[ARequest.Route.Count - 1]
  else
    ARequest.Command := ARequest.Route[1];
  //ARequest.Path := DeleteSubPath(ARequest.Command, ARequest.Path);
end;

procedure THomeModule.DoRegisterCommands;
begin
  inherited;
  RegisterCommand('page', TbsHttpGetHomeCommand, true);
  RegisterCommand('.ws', TWSEchoGetHomeCommand, false);
end;

procedure THomeModule.Created;
begin
  inherited;
end;

procedure THomeModule.Start;
begin
  inherited;
  Schemas := THomeSchemas.Create;
  Schemas.Module := Self;
  Schemas.RegisterSchema('welcome', TWelcomeSchema);
  Schemas.RegisterSchema('assets', TAssetsSchema);
  Schemas.RegisterSchema('login', TLoginSchema);
  Schemas.RegisterSchema('ws', TWSShema);
end;

destructor THomeModule.Destroy;
begin
  inherited;
  FreeAndNil(Schemas); //keep behind inherited
end;

{ TAssetsSchema }

procedure TAssetsSchema.DoCompose;
begin
  inherited;
  Name := 'Assets';
  Route := 'assets';
  ServeFiles := True;
  Kind := Kind + [elFallback];

  with TFile.Create(This) do
  begin
    Name := 'jquery';
    Route := 'jquery';
    FileName := IncludePathDelimiter(Module.HomePath) + 'jquery-3.7.1.min.js';
  end;

  with TFile.Create(This) do
  begin
    Name := 'logo';
    Route := 'logo';
    FileName := IncludePathDelimiter(Module.HomePath) + 'logo.png';
  end;
end;

{ TWSEchoGetHomeCommand }

procedure TWSEchoGetHomeCommand.RespondResult(var Result: TmodRespondResult);
var
  s: string;
begin
  if Request.ConnectionType = ctWebSocket then
  begin
    //Request.Path := DeleteSubPath(Name, Request.Path);
    while Respond.Stream.Connected do
    begin
      if Respond.Stream.ReadUTF8Line(s) then
      begin
        Respond.Stream.WriteUTF8Line(s);
        log(s);
      end;
    end;
  end;
  inherited;
end;

{ TLoginSchema }

procedure TLoginSchema.DoAction(const AContext: TmnwRespondContext; var ARespondResult: TmnwRespondResult);
var
  aUsername, aPassword: string;
begin
  if AContext.MultipartData <> nil then
  begin
    aUsername := AContext.MultipartData.Values['username'];
    aPassword := AContext.MultipartData.Values['password'];
    ARespondResult.SessionID := aUsername +'/'+ aPassword;
    ARespondResult.Resume := False;
    ARespondResult.HttpResult := hrRedirect;
    ARespondResult.Location := IncludePathDelimiter(Module.GetHomeURL) + 'dashboard';
  end;
  inherited;
end;

procedure TLoginSchema.DoCompose;
begin
  inherited;
  Name := 'welcome';
  Route := 'welcome';
  with TDocument.Create(This) do
  begin
    //Name := 'document';
    Route := 'document';
    Title := 'MyHome';
    Direction := dirLTR;

    with Body do
    begin
      Header.Text := 'Creative Solutions';
      with TImage.Create(This) do
      begin
        Comment := 'Image from another module';
        Source := IncludeURLDelimiter(Module.Host)+'doc/logo.png';
      end;

      Header.RenderIt := True;
      Footer.RenderIt := True;

      with Container do
      begin
        with TParagraph.Create(This) do
        begin
          Text := 'Hello Word';
        end;

        with TCard.Create(This) do
        begin
          Caption := 'Login';

          with TForm.Create(This) do
          begin
            PostTo := '.';
            with TInput.Create(This) do
            begin
              ID := 'username';
              Name := 'username';
              Caption := 'Username';
              PlaceHolder := 'Type user name';
            end;

            with TInputPassword.Create(This) do
            begin
              ID := 'password';
              Name := 'password';
              Caption := 'Password';
            end;

            TBreak.Create(This);

            Submit.Caption := 'Sumbit';
            Reset.Caption := 'Reset';

          end;
        end;
      end;
    end;
  end;
end;

{ THomeSchemas }

procedure THomeSchemas.SchemaCreated(Schema: TmnwSchema);
begin
  inherited;
  if Schema is TCustomHomeSchema then
    (Schema as TCustomHomeSchema).Module := Module;
end;

{ TWSShema }

procedure TWSShema.DoCompose;
begin
  inherited;
  Name := 'ws';
  Route := 'ws';
  with TFile.Create(This) do
  begin
    Route := 'echo';
    FileName := IncludePathDelimiter(Module.HomePath) + 'ws.html';
  end;
end;

end.

