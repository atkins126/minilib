program zkt;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  //Crt,
  SysUtils,
  StrUtils,
  Classes,
  zktClients,
  mnStreams;

var
  Client: TZKClient;
  procedure ListAttendances;
  var
    i: Integer;
    Attendances: TZKAttendances;
  begin
    Client.DisableDevice;
    try
      Attendances := TZKAttendances.Create;
      try
        WriteLn('Number'#9'ID'#9'UserID'#9'Verfied'#9'State'#9'WorkCode'#9'Time');
        if Client.GetAddendances(Attendances) then
        begin
          for i := 0 to Attendances.Count - 1 do
          begin
            WriteLn(IntToStr(i) +#9 + IntToStr(Attendances[i].Number) + #9 + Attendances[i].UserID + #9 + IntToStr(Attendances[i].Verified) + #9 + IntToStr(Attendances[i].State) + #9 + IntToStr(Attendances[i].WorkCode) + #9 + DateTimeToStr(Attendances[i].Time));
          end;
        end;
      finally
        FreeAndNil(Attendances);
      end;
    finally
      Client.EnableDevice;
    end;
  end;

  procedure ListUsers;
  var
    i: Integer;
    Users: TZKUsers;
  begin
    Users := TZKUsers.Create;
    Client.GetUsers(Users);
    try
      for i := 0 to Users.Count -1 do
      begin
        WriteLn(IntToStr(i) +#9 + IntToStr(Users[i].Number) + #9 + Users[i].Name + #9 + Users[i].Password + #9#9 + Users[i].UserID + #9#9 + IntToStr(Users[i].Card)+ #9#9 + IntToStr(Users[i].Group) + #9 + IntToStr(Users[i].Role) + #9 + IntToStr(Users[i].TimeZone));
      end;
    finally
      FreeAndNil(Users);
    end;
  end;
type
  TAppCmd = (cmdNone, cmdVersion, cmdTestVoice, cmdAttLog, cmdUsers, cmdSetUser, cmdSetTime, cmdGetTime, cmdClearAttLog);
var
  cmd: TAppCmd;
  cmdStr: string;
  ATime: TDateTime;
begin
  repeat
    WriteLn(Ord(cmdVersion), ' - Version');
    WriteLn(Ord(cmdTestVoice), ' - Test Voice');
    WriteLn(Ord(cmdAttLog), ' - List Attendance Log');
    WriteLn(Ord(cmdUsers), ' - List Users');
    WriteLn(Ord(cmdSetUser), ' - Set User');
    WriteLn(Ord(cmdSetTime), ' - Set Time to now');
    WriteLn(Ord(cmdGetTime), ' - Get Time');
    WriteLn(Ord(cmdClearAttLog), ' - Clear AttLog');
    Write('Enter Command: ');
    Readln(cmdStr);
    cmd := TAppCmd(StrToIntDef(cmdStr, 0));
    if cmd > cmdNone then
    begin
      Client := TZKClient.Create(999999, '192.168.1.201');
      if not Client.Connect then
        WriteLn('Can not connect')
      else
      begin
        WriteLn('Connected');
        case cmd of
          cmdVersion: WriteLn(Client.GetVersion);
          cmdTestVoice: Client.TestVoice;
          cmdAttLog: ListAttendances;
          cmdUsers : ListUsers;
          cmdSetTime:
            Client.SetTime(Now);
          cmdGetTime:
          begin
            Client.GetTime(ATime);
            WriteLn(FormatDateTime('YYYY-MM-DD HH:NN', ATime));
          end;
          cmdSetUser:
          begin
              if Client.SetUser(10, '10', 'Tester') then
                WriteLn('Added successfull')
              else
                WriteLn('Add failed');
          end;
          cmdClearAttLog:
          begin
            if Client.ClearAttLog then
              WriteLn('Clear successfull')
          end;
          else
          begin
            //not yet
          end;
        end;
        Client.Free;
        WriteLn();
        WriteLn('Press any to exit');
      end;
    end;
  until cmd = cmdNone;
end.

