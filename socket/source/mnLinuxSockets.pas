unit mnLinuxSockets;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher, zaherdirkey>
 *}
{$IFDEF FPC}
{$mode delphi}
{$M+}
{$H+}
{$endif}

interface

uses
  Classes,
  netdb,
  SysUtils,
  sockets,
  Termio,
  mnSockets;

type

  { TmnSocket }

  TmnSocket = class(TmnCustomSocket)
  private
    FAddress: TINetSockAddr;
  protected
    function GetActive: Boolean; override;
    function DoSelect(Timeout: Integer; Check: TSelectCheck): TmnError; override;
    function DoShutdown(How: TmnShutdowns): TmnError; override;
    function DoListen: TmnError; override;
    function DoReceive(var Buffer; var Count: Longint): TmnError; override;
    function DoSend(const Buffer; var Count: Longint): TmnError; override;
    function DoClose: TmnError; override;
    function DoPending: Boolean; override;
  public
    function Accept: TmnCustomSocket; override;
    function GetLocalAddress: ansistring; override;
    function GetRemoteAddress: ansistring; override;
    function GetLocalName: string; override;
    function GetRemoteName: string; override;
  end;

  { TmnWallSocket }

  TmnWallSocket = class(TmnCustomWallSocket)
  private
    procedure FreeSocket(var vHandle: TSocketHandle; out vErr: integer);
    function LookupPort(Port: string): Word;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Bind(Options: TmnsoOptions; ReadTimeout: Integer; const Port: string; const Address: string; out vSocket: TmnCustomSocket; out vErr: Integer); override;
    procedure Connect(Options: TmnsoOptions; ConnectTimeout, ReadTimeout: Integer; const Port: ansistring; const Address: AnsiString; out vSocket: TmnCustomSocket; out vErr: Integer); override;
  end;

implementation

uses
  BaseUnix;

const
  INVALID_SOCKET		= TSocketHandle(NOT(0));
  SOCKET_ERROR			= -1;

{ TmnSocket }

function TmnSocket.DoReceive(var Buffer; var Count: Longint): TmnError;
var
  ret: Integer;
//  errno: longint;
begin
  ret := fprecv(FHandle, @Buffer, Count, MSG_NOSIGNAL);
  if ret = 0 then
  begin
    Count := 0;
    Result := erClosed;
  end
  else if ret = SOCKET_ERROR then
  begin
    Count := 0;
    //errno := SocketError;
    //TODO copy it from windows
    //Result := erTimout; //maybe closed, but we will pass it as timeout, the caller will close it depend on options
    Result := erInvalid;
  end
  else
  begin
    Count := ret;
    Result := erSuccess;
  end;
end;

function TmnSocket.DoSend(const Buffer; var Count: Longint): TmnError;
var
  ret: Integer;
begin
  ret := fpsend(FHandle, @Buffer, Count, MSG_NOSIGNAL);
  if ret = 0 then
  begin
    Result := erClosed;
    Count := 0;
  end
  else if ret = SOCKET_ERROR then
  begin
    Count := 0;
    Result := erInvalid;
  end
  else
  begin
    Count := ret;
    Result := erSuccess;
  end;
end;

function TmnSocket.DoSelect(Timeout: Integer; Check: TSelectCheck): TmnError;
var
  FSet: TFDSet;
  PSetRead, PSetWrite: PFDSet;
  c: Integer;
begin
  //CheckActive; no need select will return error for it, as i tho
  if FHandle = INVALID_SOCKET then
    Result := erClosed
  else
  begin
    fpfd_zero(FSet);
    fpfd_set(FHandle, FSet);
    if Check = slRead then
    begin
      PSetRead := @FSet;
      PSetWrite := nil;
    end
    else
    begin
      PSetRead := nil;
      PSetWrite := @FSet;
    end;

    c := fpselect(FHandle + 1, PSetRead, PSetWrite, PSetRead, Timeout);
    if (c = SOCKET_ERROR) then
      Result := erInvalid
    else if (c = 0) then
      Result := erTimeout
    else
      Result := erSuccess;
  end;
end;

function TmnSocket.GetActive: Boolean;
begin
  Result := FHandle <> INVALID_SOCKET;
end;

function TmnSocket.DoClose: TmnError;
var
  err: Longint;
begin
  if Active then
  begin
    err := closesocket(FHandle);
    if err = 0 then
      Result := erSuccess
    else
      Result := erInvalid;
    FHandle := INVALID_SOCKET;
  end
  else
    Result := erClosed;
end;

function TmnSocket.DoPending: Boolean;
begin
  Result := inherited DoPending;
  //ioctl(fd,FIONREAD,&bytes_available)
end;

function TmnSocket.DoShutdown(How: TmnShutdowns): TmnError;
var
  c: Integer;
  iHow: Integer;
begin
  if [sdReceive, sdSend] = How then
    iHow := 2
  else if sdSend in How then
    iHow := 1
  else if sdReceive in How then
    iHow := 0;

  CheckActive;
  c := fpshutdown(FHandle, iHow);
  if c = SOCKET_ERROR then
    Result := erInvalid
  else
    Result := erSuccess;
end;

function TmnSocket.Accept: TmnCustomSocket;
var
  aHandle: TSocketHandle;
  aSize: Integer;
begin
  CheckActive;
  aSize := SizeOf(FAddress);
  aHandle := fpaccept(FHandle, @FAddress, @aSize);
  if aHandle < 0 then
    Result := nil
  else
    Result := TmnSocket.Create(aHandle, Options, skServer);
end;

function TmnSocket.DoListen: TmnError;
var
  c: Integer;
begin
  CheckActive;
  c := fplisten(FHandle, 5);
  if c = SOCKET_ERROR then
    Result := erInvalid
  else
    Result := erSuccess;
end;

function TmnSocket.GetRemoteAddress: ansistring;
var
  SockAddr: TSockAddr;
  aSize: Integer;
begin
  CheckActive;
  aSize := SizeOf(SockAddr);
  if fpGetPeerName(FHandle, @SockAddr, @aSize) = 0 then
//    Result := NetAddrToStr(SockAddr.in_addr)
  else
    Result := '';
end;

function TmnSocket.GetRemoteName: string;
var
  SockAddr: TSockAddr;
  Size: Integer;
  s: ansistring;
begin
  CheckActive;
  Size := SizeOf(SockAddr);
  if fpgetpeername(FHandle, @SockAddr, @Size) = 0 then
  begin
    s := '';//temp
    //gethostbyaddr(@SockAddr.sin_addr.s_addr, 4, AF_INET);
  end
  else
    s := '';
  Result := s;
end;

function TmnSocket.GetLocalAddress: ansistring;
var
  SockAddr: TSockAddr;
  aSize: Integer;
begin
  CheckActive;
  aSize := SizeOf(SockAddr);
  if fpGetSockName(FHandle, @SockAddr, @aSize) = 0 then
//    Result := NetAddrToStr(SockAddr)
  else
    Result := '';
end;

function TmnSocket.GetLocalName: string;
var
  s: ansistring;
begin
  CheckActive;
  SetLength(s, 250);
//  fpgethostname(PChar(s), Length(s));
  s := '';//temp
  Result := s;
end;

{ TmnWallSocket }

constructor TmnWallSocket.Create;
begin
  inherited;
end;

const
  SO_TRUE:Longbool=True;
//  SO_FALSE:Longbool=False;

procedure TmnWallSocket.Bind(Options: TmnsoOptions; ReadTimeout: Integer;
  const Port: string; const Address: string; out vSocket: TmnCustomSocket; out
  vErr: Integer);
var
  aHandle: TSocketHandle;
  aAddr : TINetSockAddr;
begin
  aHandle := fpsocket(AF_INET, SOCK_STREAM, 0{IPPROTO_TCP});
  if aHandle <> INVALID_SOCKET then
  begin
    if soReuseAddr in Options then
      fpsetsockopt(aHandle, SOL_SOCKET, SO_REUSEADDR, PChar(@SO_TRUE), SizeOf(SO_TRUE));

    if soNoDelay in Options then
      fpsetsockopt(aHandle, IPPROTO_TCP, TCP_NODELAY, PAnsiChar(@SO_TRUE), SizeOf(SO_TRUE));

   //  fpsetsockopt(aHandle, SOL_SOCKET, SO_NOSIGPIPE, PChar(@SO_TRUE), SizeOf(SO_TRUE));

    aAddr.sin_family := AF_INET;
    aAddr.sin_port := htons(StrToIntDef(Port, 0));
    if Address = '' then
      aAddr.sin_addr.s_addr := INADDR_ANY
    else
      aAddr.sin_addr := StrToNetAddr(Address);

    if fpbind(aHandle,@aAddr, Sizeof(aAddr)) <> 0 then
    begin
      FreeSocket(aHandle, vErr);
    end;
  end;

  if aHandle <> INVALID_SOCKET then
    vSocket := TmnSocket.Create(aHandle, Options, skListener)
  else
    vSocket := nil;
end;

destructor TmnWallSocket.Destroy;
begin
  inherited;
end;

procedure TmnWallSocket.FreeSocket(var vHandle: TSocketHandle; out vErr: integer );
begin
  vErr := SocketError;
  closesocket(vHandle);
  vHandle := INVALID_SOCKET;
end;

function TmnWallSocket.LookupPort(Port: string): Word;
begin
  Result := StrToIntDef(Port, 0);
end;

procedure TmnWallSocket.Connect(Options: TmnsoOptions; ConnectTimeout, ReadTimeout: Integer; const Port: ansistring; const Address: AnsiString; out vSocket: TmnCustomSocket; out vErr: Integer);
var
  aHandle: TSocketHandle;
  aAddr : TINetSockAddr;
  ret: cint;
  aHost: THostEntry;
  aMode: longint;
  time: ttimeval;
  DW: Integer;
begin
  //nonblick connect  https://stackoverflow.com/questions/1543466/how-do-i-change-a-tcp-socket-to-be-non-blocking
  //https://stackoverflow.com/questions/14254061/setting-time-out-for-connect-function-tcp-socket-programming-in-c-breaks-recv
  aHandle := fpsocket(AF_INET, SOCK_STREAM{TODO: for nonblock option: or O_NONBLOCK}, 0{IPPROTO_TCP});
  if aHandle <> INVALID_SOCKET then
  begin
    if soNoDelay in Options then
      fpsetsockopt(aHandle, IPPROTO_TCP, TCP_NODELAY, PAnsiChar(@SO_TRUE), SizeOf(SO_TRUE));

  //http://support.microsoft.com/default.aspx?kbid=140325
    if soKeepAlive in Options then
      fpsetsockopt(aHandle, SOL_SOCKET, SO_KEEPALIVE, PAnsiChar(@SO_TRUE), SizeOf(SO_TRUE));

    if not (soWaitBeforeRead in Options) then
    begin
      if ReadTimeout <> -1 then
      begin
        time.tv_sec:= ReadTimeout div 1000;
        time.tv_usec:=(ReadTimeout mod 1000) * 1000;
        fpsetsockopt(aHandle, SOL_SOCKET, SO_RCVTIMEO, @time, SizeOf(time));
      end;
    end;

    if ConnectTimeout <> -1 then
    begin
      aMode := 1;
      ret := FpIOCtl(aHandle, FIONBIO, @aMode);
      if ret = Longint(SOCKET_ERROR) then
      begin
        FreeSocket(aHandle, vErr);
      end;
    end;

  //  fpsetsockopt(aHandle, SOL_SOCKET, SO_NOSIGPIPE, PChar(@SO_TRUE), SizeOf(SO_TRUE));

    aAddr.sin_family := AF_INET;
    aAddr.sin_port := htons(StrToIntDef(Port, 0));
    if Address = '' then
      aAddr.sin_addr.s_addr := INADDR_ANY
    else
    begin
      aAddr.sin_addr := StrToNetAddr(Address);
      if (aAddr.sin_addr.s_addr = 0) then
      begin
        if ResolveHostByName(Address, aHost) then
        begin
          aAddr.sin_addr.s_addr := aHost.Addr.s_addr;
        end;
      end;
    end;
    ret := fpconnect(aHandle, @aAddr, SizeOf(aAddr));
    if ret = -1 then
    begin
      FreeSocket(aHandle, vErr);
    end;
  end;

  if aHandle <> INVALID_SOCKET then
    vSocket := TmnSocket.Create(aHandle, Options, skClient)
  else
    vSocket := nil;
end;

end.

//StrToHostAddr
