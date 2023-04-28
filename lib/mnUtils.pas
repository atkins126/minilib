unit mnUtils;
{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey <zaher, zaherdirkey>
 *}

{$IFDEF FPC}
{$MODE delphi}
{$modeswitch arrayoperators}
{$ModeSwitch advancedrecords}
{$ModeSwitch typehelpers}
{$ENDIF}
{$M+}{$H+}

{$ifdef mswindows}
{$define windows}
{$endif}

interface

uses
  {$ifdef windows}Windows,{$endif}
  Classes, SysUtils, StrUtils, DateUtils, Types, Character;

const
  sUTF8BOM: array[1..3] of Char = (#$EF, #$BB, #$BF);
  {$ifdef FPC}
  {$else}
  JulianEpoch = TDateTime(-2415018.5);  //check EpochAsJulianDate
  {$endif}

procedure Nothing;
{
  StrHave: test the string if it have Separators
}
function QuoteStr(Str: string; QuoteChar: string = '"'): string;

{**
  Resume: if false then stop, default is true
*}
type
  TStrToStringsCallbackProc = procedure(Sender: Pointer; Index: Integer; S: string; var Resume: Boolean);
  TStrToStringsExCallbackProc = procedure(Sender: Pointer; Index, CharIndex, NextIndex: Integer; S: string; var Resume: Boolean);
  TArgumentsCallbackProc = procedure(Sender: Pointer; Index: Integer; Name, Value: string; IsSwitch:Boolean; var Resume: Boolean);

{**
  IgnoreInitialWhiteSpace: Ignore the first chars of this white space, not need it
*}

TStrToStringsOptions = set of (
  stsoGroupSeparators //TODO, not tested yet, if one of separators come it will ignores chars in next separators like if separators = #13, #10, now #13#10 will considered as one line break
); //

//I want to StrToStrings to replace it with StrToStringsEx

function StrToStringsCallback(Content: string; Sender: Pointer; const CallBackProc: TStrToStringsCallbackProc; Separators: TSysCharSet = [#0, #10, #13]; IgnoreInitialWhiteSpace: TSysCharSet = [' ']; Quotes: TSysCharSet = ['''', '"']; vOptions: TStrToStringsOptions = []): Integer; overload;
function StrToStrings(Content: string; Strings: TStrings; Separators: TSysCharSet = [#0, #10, #13]; IgnoreInitialWhiteSpace: TSysCharSet = [' ']; Quotes: TSysCharSet = ['''', '"']): Integer; overload;

{
  Example
  StrToStringsExCallback(Memo1.Text, 1, self, @AddString, ['::', ';', #13#10, #13, #10, #0]);
  HINT: Put longest seperator first ::  befire ;

}
function StrToStringsExCallback(Content: string; FromIndex: Integer; Sender: Pointer; const CallBackProc: TStrToStringsExCallbackProc; Separators: Array of string; IgnoreInitialWhiteSpace: TSysCharSet = [' ']; Quotes: TSysCharSet = ['''', '"']; vOptions: TStrToStringsOptions = []): Integer; overload;
function StrToStringsEx(Content: string; Strings: TStrings; Separators: Array of string; IgnoreInitialWhiteSpace: TSysCharSet = [' ']; Quotes: TSysCharSet = ['''', '"']): Integer; overload;
function StrScanTo(Content: string; FromIndex: Integer; out S: string; out CharIndex, NextIndex: Integer; Separators: Array of string; IgnoreInitialWhiteSpace: TSysCharSet = [' ']; Quotes: TSysCharSet = ['''', '"']): Boolean;
//function StrToStringsEx(Content: string; Strings: TStrings; IgnoreInitialWhiteSpace: TSysCharSet = [' ']; Quotes: TSysCharSet = ['''', '"']): Integer; overload;

procedure StrToStringsCallbackProc(Sender: Pointer; Index: Integer; S: string; var Resume: Boolean);
procedure StrToStringsDequoteCallbackProc(Sender: Pointer; Index:Integer; S: string; var Resume: Boolean);

{
  examples:
  -t -s -v: value test

  -t -s --value: "value test"

}
type
  TParseArgumentsOptions = set of (
    pargSmartSwitch
  );

//*  -t --test cmd1 cmd2 -t: value -t:value -t value
function ParseArgumentsCallback(Content: string; const CallBackProc: TArgumentsCallbackProc; Sender: Pointer; Switches: TArray<Char>; WhiteSpaces: TArray<Char> {= [' ', #9]}; Quotes: TArray<Char> {= ['''', '"']};  ValueSeperators: TArray<Char> {= [':', '=']}; Options: TParseArgumentsOptions = [pargSmartSwitch]): Integer; overload;
function ParseArgumentsCallback(Content: string; const CallBackProc: TArgumentsCallbackProc; Sender: Pointer): Integer; overload;

//*
function ParseArguments(Content: string; Strings: TStrings; Switches: TArray<Char>; WhiteSpaces: TArray<Char>{ = [' ', #9]}; Quotes: TArray<Char> {= ['''', '"']}; ValueSeperators: TArray<Char> {= [':', '=']}): Integer; overload;
function ParseArguments(Content: string; Strings: TStrings): Integer; overload;

//* Skip first param
function ParseCommandLine(Content: string; Strings: TStrings; Switches: TArray<Char>; WhiteSpaces: TArray<Char>{ = [' ', #9]}; Quotes: TArray<Char> {= ['''', '"']}; ValueSeperators: TArray<Char> {= [':', '=']}): Integer; overload;
function ParseCommandLine(Content: string; Strings: TStrings): Integer; overload;

{
  param1 param2 -s -w: value

  =param1
  =param2
  -s
  -w=value
}

function GetArgumentValue(Strings: TStrings; out Value: String; Switch: string; AltSwitch: string = ''): Boolean; overload;
function GetArgumentSwitch(Strings: TStrings; Switch: string; AltSwitch: string = ''): Boolean; overload;

//Get Param (non switch value by index)
function GetArgument(Strings: TStrings; out Value: String; Index: Integer): Boolean; overload;

function GetArgument(Strings: TStrings; OutStrings: TStrings; AltSwitch: string = ''): Boolean; overload;
function GetArgument(Strings: TStrings; out OutStrings: TArray<String>): Boolean; overload;

function StringsToString(Strings: TStrings; LineBreak: string = sLineBreak): string;

function CompareLeftStr(const Str: string; const WithStr: string; Start: Integer = 1): Boolean;
function ContainsText(const SubStr, InStr: string): Boolean; deprecated 'Use StrUtils.ContainsText and swap params';

//Same as Copy/MidStr but From To index
function CopyStr(const AText: String; const AFromIndex, AToIndex: Integer): String; overload;
{
  Index started from 0
}
function SubStr(const Str: String; vSeperator: Char; vFromIndex, vToIndex: Integer): String; overload;
function SubStr(const Str: String; vSeperator: Char; vIndex: Integer = 0): String; overload;

function StrHave(S: string; Separators: TSysCharSet): Boolean; deprecated;
procedure SpliteStr(const S, Separator: string; out Name, Value: string);

function FetchStr(var AInput: string; const ADelim: string = '.'; const ADelete: Boolean = True; const ACaseSensitive: Boolean = True): string; deprecated;

function StrInArray(const Str: String; const InArray : Array of String; CaseInsensitive: Boolean = False) : Boolean; overload;
function StrInArray(const Str: string; const StartIndex: Integer; const InArray: array of string; out SepLength: Integer; CaseInsensitive: Boolean = False): Boolean; overload;
function CharInArray(const C: string; const ArrayOfChar : array of Char; CaseInsensitive: Boolean = False) : Boolean;

//vPeriod is a datetime not tickcount
function PeriodToString(vPeriod: Double; WithSeconds: Boolean): string;
//Used by GetTickCount, return minuts,secons,miliseconds
function TicksToString(vTicks: Int64): string;
function DequoteStr(const Str: string; QuoteChar: string = #0): string;
function ExcludeTrailing(const Str: string; TrailingChar: string = #0): string;
function RemoveEncloseStr(const S, Left, Right: string): string;
function EncloseStr(const S, Left, Right: string): string;

function RepeatString(const Str: string; Count: Integer): string;

function ConcatString(const S1, Delimiter: string; S2: string = ''): string;
function CollectStrings(Strings: TStrings; Delimiter: Char = ','; TrailingChar: Char = #0): string; overload;
function CollectStrings(Strings: array of string; Delimiter: Char = ','; TrailingChar: Char = #0): string; overload;

function ReversePos(const SubStr, S : String): Integer; overload;
function ReversePos(const SubStr, S: String; const Start: Integer): Integer; overload;

{* VarReplace
  VarInit = '$'
  Example: VarReplace('c:\$project\$[name]';
}
type
  TVarOptions = set of (
    vrSmartLowerCase,
    vrAllowBrackets //TODO
  );
  TVarReplacesCallbackProc = procedure(Sender: Pointer; Name: string; var Value: string);

function VarReplace(S: string; Values: TStrings; Prefix: string; Suffix: String = ''; ExtraChar: TSysCharSet = []; VarOptions: TVarOptions = []; Sender: Pointer = nil; ReplacesCallbackProc: TVarReplacesCallbackProc = nil): string; overload;

type
  //alsCut = if the string > count we cut it as count or keep the string
  TAlignStrOptions = set of (alsLeft, alsRight, alsCut); {TODO left+right=center TODO use righttoleft}

function AlignStr(const S: string; Count: Integer; Options: TAlignStrOptions = [alsLeft]; vChar: Char = ' '): string; overload;

{
  Useful to make your project path related (Portable)
  FileName:
          ./myfile
          ../myfile
          /myfile
          \myfile
  Path:
  Root: is optional, added before Path
}
function ExpandToPath(FileName: string; Path: string; Root: string = ''): string;

{
  EscapeString: Example
    EscapeString(Text, '\', [#13, #10, #9 , #8, '"'], ['r', 'n', 't', 'b', '"']);

  DescapeString: Reverse of EscapeString with same params
  Both functions is case sensitive

  sBS = #8 = \b
  sTAB = #9 = \t
  sLF = #10 = \n
  sCR = #13 = \r
  sCRLF = #13#10 \r\n
}

const
  cDefEscapeChars =  [#8, #9, #10, #13, '\', '"'];
  cDefEscapeStrings = ['b', 't', 'n', 'r', '\', '"'];
  cDefEscapePrefix = '\';

function EscapeString(const S: string; Esc: string; Chars: array of Char; Escapes: array of string): string;
function DescapeString(const S: string; Esc: string; Chars: array of Char; Escapes: array of string): string;

function EscapeStringC(const S: string): string;
function DescapeStringC(const S: string): string;
function ToUnixPathDelimiter(const S: string): string;

//TODO pascal
//function EscapeStringPas(const S: string): string;
//function DescapeStringPas(const S: string): string;

//IncludePathDelimiter add the Delimiter when S not = ''
function IncludePathDelimiter(const S: string): string;
function IncludePathSeparator(const S: string): string; deprecated 'Use IncludePathDelimiter';
function IncludeURLDelimiter(S: string): string;
function ExcludePathDelimiter(Path: string): string;

//Similer to ZeroMemory
procedure InitMemory(out V; Count: {$ifdef FPC}SizeInt{$else}Longint{$endif});

//Rect functions
procedure CenterRect(var R1: TRect; R2: TRect);

function GetFormatSettings: TFormatSettings;

//Ported from UniDates

procedure ISOStrToDate(ISODate: String; out Y, M, D, H, N, S: Word; vDateSeparator: Char = '-'; TimeDivider: Char = #0; UseDefault: Boolean = False); overload;
function ISOStrToDate(ISODate: String; vDateSeparator: Char = '-'; TimeDivider: Char = #0; UseDefault: Boolean = False): TDateTime; overload;

function ISODateToStr(DateTime: TDateTime; vDateSeparator: Char = '-'; TimeDivider: Char = ' '; WithTime: Boolean = False): String; overload;
function ISODateToStr(DateTime: TDateTime; vDateSeparator: Char = '-'; TimeDivider: Char = ' '; TimeSeparator: Char = ':'; WithTime: Boolean = False): String; overload;
function IsAllLowerCase(S: string): Boolean;

//Zero Based
type
  TEncodingHelper = class helper for TEncoding
  public
    function GetString(Bytes: PByte; ByteCount: Integer): String; overload;
    class function CodePageEncoding(CodePage: Word): TEncoding;
    {$ifdef FPC}
    function GetString(Bytes: array of Byte): String; overload;
    {$endif}
  end;

function StringOf(const Value: Array of Byte; CodePage: Word = CP_UTF8): string; overload;
function StringOf(const Value: TBytes; CodePage: Word = CP_UTF8): string; overload;
function StringOf(const Value: PByte; Size: Integer; CodePage: Word = CP_UTF8): string; overload;

//TODO fix ansi to widestring
function HexToBin(Text : PByte; Buffer: PByte; BufSize: longint): Integer; overload;
procedure BinToHex(Buffer: PByte; Text: PByte; BufSize: longint); overload;
function String2Hex(const vData: string): string; overload;
function String2Hex(const vData: PByte; vCount: Integer): string; overload;
function Hex2String(const vData: string): string; overload;

//Files Utils

type
  TEnumFilesOptions = set of (efFile, efDirectory, efFullPath);
  //If set Resume to false it will stop loop
  TEnumFilesCallback = procedure(AObject: TObject; const FileName: string; Count, Level:Integer; IsDirectory: Boolean; var Resume: Boolean);

procedure EnumFiles(FileList: TStringList; Folder, Filter: string; Options: TEnumFilesOptions = [efFile]); overload;
function FirstFile(Path, Files: string): string;
function DeleteFiles(Path, Files: string): Integer;
function GetSizeOfFile(const vFile: string): Int64; //GetFileSize

var
  SystemAnsiCodePage: Cardinal; //used to convert from Ansi string, it is the default

implementation

{$ifdef FPC}
{$else}
  {$if CompilerVersion < 22}
  var
    FFormatSettings: TFormatSettings;
  {$ifend}
{$endif}

procedure Nothing;
begin
end;

function StrHave(S: string; Separators: TSysCharSet): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to Length(S) do
  begin
     if CharInSet(S[i], Separators) then
     begin
       Result := True;
       Break; 
     end;
  end;
end;

function QuoteStr(Str: string; QuoteChar: string): string;
begin
  if Str = '' then
    Result := QuoteChar + QuoteChar
  else
  begin
    if Str[1] = '"' then
    begin
      if Str[Length(Str)] <> '"' then
        Result := Result + '"'
    end
    else if Str[1] = '''' then
    begin
      if Str[Length(Str)] <> '''' then
        Result := Result + '''';
    end
    else
      Result := QuoteChar + Str + QuoteChar;
  end;
end;

function DequoteStr(const Str: string; QuoteChar: string = #0): string;
begin
  if Str = '' then
    Result := ''
  else
  begin
    if (QuoteChar > #0) and (Str[1] = QuoteChar) then
    begin
      if Str[Length(Str)] =QuoteChar then
        Result := MidStr(Str, 2, Length(Str) - 2)
      else
        Result := MidStr(Str, 2, Length(Str) - 1)
    end
    else if Str[1] = '"' then
    begin
      if Str[Length(Str)] = '"' then
        Result := MidStr(Str, 2, Length(Str) - 2)
      else
        Result := MidStr(Str, 2, Length(Str) - 1)
    end
    else if Str[1] = '''' then
    begin
      if Str[Length(Str)] = '''' then
        Result := MidStr(Str, 2, Length(Str) - 2)
      else
        Result := MidStr(Str, 2, Length(Str) - 1)
    end
    else
      Result := Str;
  end;
end;

function ExcludeTrailing(const Str: string; TrailingChar: string = #0): string;
begin
  if (TrailingChar > #0) and (RightStr(Str, 1) = TrailingChar) then
    Result := MidStr(Str, 1, Length(Str) - 1)
  else
    Result := Str;
end;

function RemoveEncloseStr(const S, Left, Right: string): string;
var
  start, count: Integer;
begin
  if UpperCase(LeftStr(s, 1)) = UpperCase(Left) then
    start := Length(Left) + 1
  else
    start := 0;
  if UpperCase(RightStr(s, 1)) = UpperCase(Right) then
    count := Length(Right)
  else
    count := 0;
  count := Length(s) - start - count + 1;
  Result := MidStr(S, start, count);
end;

function EncloseStr(const S, Left, Right: string): string;
begin
  if S <> '' then
    Result := Left + S + Right
  else
    Result := '';
end;

function AlignStr(const S: string; Count: Integer; Options: TAlignStrOptions; vChar: Char): string;
var
  l: integer;
begin
  l := Length(S);
  if l >= Count then
  begin
    if alsCut in Options then
      Result := LeftStr(S, Count)
    else
    begin
      Result := S;
      exit;//or cut
    end;
  end;
  if (alsLeft in Options) and (alsRight in Options) then
    Result := StringOfChar(vChar, Count div 2) + S + StringOfChar(vChar, Count - (Count div 2) - l) //the rest if div used in right
  else if alsLeft in Options then
    Result := S + StringOfChar(vChar, Count  - l)
 else if alsRight in Options then
    Result := StringOfChar(vChar, Count  - l) + S
end;

function RepeatString(const Str: string; Count: Integer): string;
begin
  Result := '';
  while Count > 0 do
  begin
    Result := Result + Str;
    Count := Count - 1;
  end;
end;

function ConcatString(const S1, Delimiter: string; S2: string): string;
begin
  Result := S1;
  if (Result <> '') and (S2 <> '') then
    Result := Result + Delimiter;
  Result := Result + S2;
end;

function CollectStrings(Strings: TStrings; Delimiter: Char; TrailingChar: Char): string;
var
  s: string;
  i: Integer;
begin
  Result := '';
  for i :=0 to Strings.Count -1 do
  begin
    s := Trim(Strings[i]);
    if TrailingChar <> #0 then
      s := ExcludeTrailing(s, TrailingChar);
    Result := ConcatString(Result, Delimiter, s);
  end;
end;

function CollectStrings(Strings: array of string; Delimiter: Char; TrailingChar: Char): string;
var
  s, v: string;
begin
  Result := '';
  for s in Strings do
  begin
    v := Trim(s);
    if TrailingChar <> #0 then
      v := ExcludeTrailing(v, TrailingChar);
    Result := ConcatString(Result, Delimiter, v);
  end;
end;

function ReversePos(const SubStr, S: String; const Start: Integer): Integer;
var
  i: Integer;
  pStr: PChar;
  pSub: PChar;
begin
  pSub := Pointer(SubStr);

  for i := Start downto 1 do
  begin
    pStr := @(S[i]);
    if (pStr^ = pSub^) then
    begin
      if CompareMem(pSub, pStr, Length(SubStr)) then
      begin
        Result := i;
        exit;
      end;
    end;
  end;
  Result := 0;
end;


function ReversePos(const SubStr, S: String): Integer;
begin
  Result := ReversePos(SubStr, S, Length(S) - Length(SubStr) + 1);
end;

{**
*  Replace multipe variables $var for example with value in Values
*  Use name values in strings
*}

function VarReplace(S: string; Values: TStrings; Prefix: string; Suffix: String; ExtraChar: TSysCharSet; VarOptions: TVarOptions; Sender: Pointer; ReplacesCallbackProc: TVarReplacesCallbackProc): string;
var
  Start: Integer;
  OpenStart: Integer;
  InsideBlock: Boolean;
  InitIndex: Integer;
  procedure check(Index: Integer);
  var
    Name, Value: string;
  begin
    //* string before variable
    Result := Result + MidStr(S, Start, OpenStart - Start);
    Name := MidStr(S, OpenStart + Length(Prefix), Index - OpenStart + 1 - Length(Prefix) - Length(Suffix));
    if (LeftStr(Name, 1) = '[') and (RightStr(Name, 1) = ']') then
      Name := MidStr(Name, 2, Length(Name) - 2);
    Value := MidStr(S, OpenStart, Index - OpenStart + 1);
    if Values.IndexOfName(Name) >= 0 then
    begin
      if (vrSmartLowerCase in VarOptions) and IsAllLowerCase(Name) then //Smart idea, right ^.^
        Value := LowerCase(Values.Values[Name])
      else
        Value := Values.Values[Name];
    end
    else if Assigned(ReplacesCallbackProc) then
      ReplacesCallbackProc(Sender, Name, Value);
    Result := Result + Value;
    Start := Index + 1;
    OpenStart := 0;
  end;
var
  Current: Char;
  Len: Integer;
  Index: Integer;
begin
  if Length(Suffix) > 1 then
    raise Exception.Create('');
  InsideBlock := False;
  OpenStart := 0;
  Result := '';
  Len := Length(S);
  InitIndex := 1;
  Index := 1;
  Start := Index;
  while Index <= Len do
  begin
    Current := S[Index];
    if (OpenStart > 0) then
    begin
      if not InsideBlock and CharInSet(Current, ['[']) then
        InsideBlock := True
      else if InsideBlock and CharInSet(Current, [']']) then
        InsideBlock := False;

      if not InsideBlock then
      begin
        if ((Suffix <> '') and (Current = Suffix[1])) then
          Check(Index)
        else if ((Suffix = '') and not CharInSet(Current, ['0'..'9', 'a'..'z', 'A'..'Z', '_'] + ExtraChar)) then
        begin
          Dec(Index);
          Check(Index);
        end;
      end;
    end
    else if (Current = Prefix[InitIndex]) then
    begin
      if InitIndex = Length(Prefix) then
      begin
        OpenStart := Index - Length(Prefix) + 1;
        InitIndex := 1;
      end
      else
        Inc(InitIndex);
    end
    else
      InitIndex := 1;
    Inc(Index);
  end;
  if (OpenStart > 0) then
    Check(Index);
  Result := Result + MidStr(S, Start, MaxInt);
end;

{
for example 4 fields
f1,f2,f3,f4
f1,f2,f3,
f1,f2,,f4
,f2,f3,f4
}

procedure StrToStringsCallbackProc(Sender: Pointer; Index: Integer; S: string; var Resume: Boolean);
begin
  TStrings(Sender).Add(S); //Be sure sender is TStrings
end;

procedure StrToStringsDequoteCallbackProc(Sender: Pointer; Index:Integer; S: string; var Resume: Boolean);
var
  Name, Value: string;
  p: Integer;
begin
  p := pos('=', s);
  if p >= 0 then
  begin
    Name := Copy(s, 1, p - 1);
    Value := DequoteStr(Copy(s, p + 1, MaxInt));
  end
  else
  begin
    Name := S;
    Value := '';
  end;
  (TObject(Sender) as TStrings).Add(Name + (TObject(Sender) as TStrings).NameValueSeparator + Value);
end;

function StrToStringsCallback(Content: string; Sender: Pointer; const CallBackProc: TStrToStringsCallbackProc; Separators: TSysCharSet; IgnoreInitialWhiteSpace: TSysCharSet; Quotes: TSysCharSet; vOptions: TStrToStringsOptions): Integer;
var
  Start, Cur: Integer;
  Resume: Boolean;
  InQuote: Boolean;
  QuoteChar: Char;
  S: string;
  Index: Integer;
begin
  Result := 0;
  Index := 0;
  if (@CallBackProc = nil) then
    raise Exception.Create('StrToStrings: CallBackProc is nil');
  if (Content <> '') then
  begin
    Cur := 1;
    InQuote := False;
    QuoteChar := #0;
    repeat
      //bypass white spaces
      if IgnoreInitialWhiteSpace <> [] then
        while (Cur <= Length(Content)) and CharInSet(Content[Cur], IgnoreInitialWhiteSpace) do
          Cur := Cur + 1;

      //start from the first char
      Start := Cur - 1;
      while True do
      begin
        //seek until the separator and skip the separator if inside quoting
        while (Cur <= Length(Content)) and not (CharInSet(Content[Cur], Quotes) or (not InQuote and (CharInSet(Content[Cur], Separators)))) do
          Cur := Cur + 1;

        if (Cur <= Length(Content)) and CharInSet(Content[Cur], Quotes) then
        begin
          if (QuoteChar <> #0) and (QuoteChar = Content[Cur]) then
            QuoteChar := #0
          else if QuoteChar = #0 then
            QuoteChar := Content[Cur];
          InQuote := QuoteChar <> #0;
          Cur := Cur + 1;
        end
        else
          Break;
      end;

      if (Cur >= Start) then
      begin
        S := Copy(Content, Start + 1, Cur - Start - 1);
        Resume := True;
        CallBackProc(Sender, Index, S, Resume);
        Index := Index + 1;
        Inc(Result);
        if not Resume then
          break;
      end;
      Cur := Cur + 1;
    until Cur > Length(Content) + 1;
  end;
end;

function StrToStrings(Content: string; Strings: TStrings; Separators: TSysCharSet; IgnoreInitialWhiteSpace: TSysCharSet; Quotes: TSysCharSet): Integer;
begin
  if (Strings = nil) then
    raise Exception.Create('StrToStrings: Strings is nil');
  Strings.BeginUpdate;
  try
    Result := StrToStringsCallback(Content, Strings, StrToStringsCallbackProc, Separators, IgnoreInitialWhiteSpace, Quotes);
  finally
    Strings.EndUpdate;
  end;
end;

//Ex

function StrToStringsExCallback(Content: string; FromIndex: Integer; Sender: Pointer; const CallBackProc: TStrToStringsExCallbackProc; Separators: array of string; IgnoreInitialWhiteSpace: TSysCharSet; Quotes: TSysCharSet; vOptions: TStrToStringsOptions): Integer;
var
  Start, Cur, SepLength: Integer;
  Resume: Boolean;
  InQuote: Boolean;
  QuoteChar: Char;
  S: string;
  Index: Integer;
begin
  Result := 0;
  Index := 0;
  if (@CallBackProc = nil) then
    raise Exception.Create('StrToStrings: CallBackProc is nil');
  Cur := FromIndex;
  if Cur = 0 then
    Cur := 1;
  if (Content <> '') and (Cur <= Content.Length) then
  begin
    InQuote := False;
    QuoteChar := #0;
    repeat
      //bypass white spaces
      if IgnoreInitialWhiteSpace <> [] then
        while (Cur <= Length(Content)) and CharInSet(Content[Cur], IgnoreInitialWhiteSpace) do
          Cur := Cur + 1;

      //start from the first char
      Start := Cur;
      while True do
      begin
        SepLength := 1;
        //seek until the separator and skip the separator if inside quoting
        while (Cur <= Length(Content)) do
        begin
          SepLength := 1;
          if (InQuote) then
          begin
            if (Content[Cur] = QuoteChar) then
              break;
            Cur := Cur + 1;
          end
          else
          begin
            if CharInSet(Content[Cur], Quotes) then
              break
            else if (StrInArray(Content, Cur, Separators, SepLength)) then
            begin
              Cur := Cur + SepLength - 1;
              break;
            end
            else
            begin
              Cur := Cur + 1
            end;
          end;
        end;

        if (Cur <= Length(Content)) and CharInSet(Content[Cur], Quotes) then
        begin
          if (QuoteChar <> #0) and (QuoteChar = Content[Cur]) then
            QuoteChar := #0
          else if QuoteChar = #0 then
            QuoteChar := Content[Cur];
          InQuote := QuoteChar <> #0;
          Cur := Cur + 1;
        end
        else
          Break;
      end;

      if (Cur >= Start) then
      begin
        S := Copy(Content, Start, Cur - Start - SepLength + 1); //TODO compare it with other function
        Resume := True;
        CallBackProc(Sender, Index, Start, Cur + 1, S, Resume);
        Index := Index + 1;
        Inc(Result);
        if not Resume then
          break;
      end;
      Cur := Cur + 1;
    until Cur > Length(Content) + 1;
  end;
end;

procedure StrToStringsExCallbackProc(Sender: Pointer; Index, CharIndex, NextIndex: Integer; S: string; var Resume: Boolean);
begin
  TStrings(Sender).Add(S); //Be sure sender is TStrings
end;

function StrToStringsEx(Content: string; Strings: TStrings; Separators: array of string; IgnoreInitialWhiteSpace: TSysCharSet; Quotes: TSysCharSet): Integer;
begin
  if (Strings = nil) then
    raise Exception.Create('StrToStrings: Strings is nil');
  Strings.BeginUpdate;
  try
    Result := StrToStringsExCallback(Content, 0, Strings, StrToStringsExCallbackProc, Separators, IgnoreInitialWhiteSpace, Quotes);
  finally
    Strings.EndUpdate;
  end;
end;

type
  TResultString = record
    Found: string;
    CharIndex: Integer;
    NextIndex: Integer;
  end;

procedure StrScanToCallbackProc(Sender: Pointer; Index, CharIndex, NextIndex: Integer; S: string; var Resume: Boolean);
begin
  Resume := False;
  TResultString(Sender^).Found := S;
  TResultString(Sender^).CharIndex := CharIndex;
  TResultString(Sender^).NextIndex := NextIndex;
end;

function StrScanTo(Content: string; FromIndex: Integer; out S: string; out CharIndex, NextIndex: Integer; Separators: array of string; IgnoreInitialWhiteSpace: TSysCharSet; Quotes: TSysCharSet): Boolean;
var
  r: TResultString;
begin
  r.Found := '';
  r.CharIndex := 0;
  r.NextIndex := 0;
  Result := StrToStringsExCallback(Content, FromIndex, @r, StrScanToCallbackProc, Separators, IgnoreInitialWhiteSpace, Quotes) > 0;
  S := r.Found;
  CharIndex := r.CharIndex;
  NextIndex := r.NextIndex;
end;

{function StrToStringsEx(Content: string; Strings: TStrings; IgnoreInitialWhiteSpace: TSysCharSet = [' ']; Quotes: TSysCharSet = ['''', '"']): Integer; overload;
begin
  Result := StrToStringsEx(Content, Strings, [#13, #10, #0], IgnoreInitialWhiteSpace, Quotes);
end;}

function ParseArgumentsCallback(Content: string; const CallBackProc: TArgumentsCallbackProc; Sender: Pointer; Switches: TArray<Char>; WhiteSpaces: TArray<Char>; Quotes: TArray<Char>; ValueSeperators: TArray<Char>; Options: TParseArgumentsOptions): Integer;
var
  Start, Cur: Integer;
  Resume: Boolean;
  Index: Integer;
  Name: string;
  Value: string;
  QuoteChar: Char;
  S: string;
  NextIsValue: Boolean;
  IsSwitch: Boolean;
begin
  IsSwitch := False;
  Result := 0;
  Index := 0;
  Name := '';
  Value := '';
  NextIsValue := False;
  if (@CallBackProc = nil) then
    raise Exception.Create('ParseArguments: CallBackProc is nil');
  if (Content <> '') then
  begin
    Cur := 1;
    repeat
      //bypass white spaces
      while (Cur <= Length(Content)) and CharInArray(Content[Cur], WhiteSpaces) do
        Cur := Cur + 1;

      //start from the first char
      Start := Cur - 1;
      QuoteChar := #0;

      if (Cur <= Length(Content)) and CharInArray(Content[Cur], Quotes) then
      begin
        QuoteChar := Content[Cur];
        Cur := Cur + 1;
      end;

      while (Cur <= Length(Content)) and (not CharInArray(Content[Cur], WhiteSpaces) or (QuoteChar <> #0)) do
      begin
        if (QuoteChar <> #0) then
        begin
          if (Content[Cur] = QuoteChar) then
          begin
            Cur := Cur + 1;
            break;
          end;
        end
        //* if you removed -t:value will break
        else if not NextIsValue and CharInArray(Content[Cur], ValueSeperators) then
        begin
          Cur := Cur + 1;
          break;
        end;

        Cur := Cur + 1;
      end;

      if (Cur >= Start) then
      begin
        S := Copy(Content, Start + 1, Cur - Start - 1);
        if S <> '' then
        begin
          if NextIsValue then
          begin
{            if CharInArray(S[1], Switches) then //* hmmm maybe not //nop, what if i want value is minus
              raise Exception.Create('Value excepted not a switch '+ S);}
            Value := S;
            NextIsValue := False;
          end
          else
          begin
            Name := S;
            Value := '';
            if {CharInArray(Name[1], Switches) and } CharInArray(Name[Length(Name)], ValueSeperators) then
            begin
              Name := Copy(Name, 1, Length(Name) -1);
              { no i want to pass platform=win32 without switch char -
              if not CharInArray(Name[1], Switches) then
                Name := Switches[0] + Name;}
              NextIsValue := True;
            end
            else
              NextIsValue := False;
          end;

          if not NextIsValue then
          begin
            Resume := True;
            if CharInArray(Name[1], Switches) then
            begin
              IsSwitch := True;
              if pargSmartSwitch in Options then
              begin
                if (Name[1] = Name[2]) then
                  Name := Copy(Name, 3, Length(Name)) //change double switch to one switch
                else
                  Name := Copy(Name, 2, Length(Name));
              end
              else
              begin
                if (Name[1] = Name[2]) then
                  Name := Copy(Name, 2, Length(Name)); //change double switch to one switch
                if Name[1] <> Switches[0] then //should be first element in Switches, but i cant convert it to array right now
                  Name[1] := Switches[0];
              end;
            end;
            CallBackProc(Sender, Index, DequoteStr(Name), DequoteStr(Value), IsSwitch, Resume);
            IsSwitch := False;
            Index := Index + 1;
            Inc(Result);
            if not Resume then
              break;
          end;
         end;
      end;
      //Cur := Cur + 1;
    until Cur > Length(Content);
  end;
end;

procedure ArgumentsCallbackProc(Sender: Pointer; Index: Integer; AName, AValue: string; IsSwitch: Boolean; var Resume: Boolean);
begin
  with TObject(Sender) as TStrings do
  begin
    if (AName <> '') and (AValue = '') then
    begin
      if IsSwitch then
        Add(AName + NameValueSeparator)
      else
        Add(NameValueSeparator + AName)
    end
    else
      Add(AName + NameValueSeparator + AValue);
  end;
end;

function ParseArgumentsCallback(Content: string; const CallBackProc: TArgumentsCallbackProc; Sender: Pointer): Integer; overload;
begin
  Result := ParseArgumentsCallback(Content, @CallBackProc, Sender, ['-', '/'], [' ', #9], ['"', ''''], ['=', ':']);
end;

function ParseArguments(Content: string; Strings: TStrings; Switches: TArray<Char>; WhiteSpaces: TArray<Char>; Quotes: TArray<Char>; ValueSeperators: TArray<Char>): Integer;
begin
  Result := ParseArgumentsCallback(Content, @ArgumentsCallbackProc, Strings, Switches, WhiteSpaces, Quotes, ValueSeperators);
end;

function ParseArguments(Content: string; Strings: TStrings): Integer;
begin
  Result := ParseArguments(Content, Strings, ['-', '/'], [' ', #9], ['"', ''''], ['=', ':']);
end;

procedure CommandLineCallbackProc(Sender: Pointer; Index: Integer; Name, Value: string; IsSwitch: Boolean; var Resume: Boolean);
begin
  if Index > 0 then //ignore first param (exe file)
    ArgumentsCallbackProc(Sender, Index, Name, Value, IsSwitch, Resume);
end;

function ParseCommandLine(Content: string; Strings: TStrings; Switches: TArray<Char>; WhiteSpaces: TArray<Char>; Quotes: TArray<Char>; ValueSeperators: TArray<Char>): Integer;
begin
  Result := ParseArgumentsCallback(Content, @CommandLineCallbackProc, Strings, Switches, WhiteSpaces, Quotes, ValueSeperators);
end;

function ParseCommandLine(Content: string; Strings: TStrings): Integer;
begin
  Result := ParseCommandLine(Content, Strings, ['-', '/'], [' ', #9], ['"', ''''], ['=', ':']);
end;

function GetArgumentValue(Strings: TStrings; out Value: String; Switch: string; AltSwitch: string = ''): Boolean;
var
  I, P: Integer;
  S: string;
begin
  Result := False;
  Value := '';
  for I := 0 to Strings.Count - 1 do
  begin
    S := Strings[I];
    P := Pos(Strings.NameValueSeparator, S);
    if (P <> 0) then
    begin
      if (SameText(Copy(S, 1, P - 1), Switch))
        or ((AltSwitch <> '') and (SameText(Copy(S, 1, P - 1), AltSwitch))) then
        begin
          Value := Copy(S, p + 1, MaxInt);
          Exit(True);
        end;
    end;
  end;
end;

function GetArgumentSwitch(Strings: TStrings; Switch: string; AltSwitch: string = ''): Boolean; overload;
var
  I, P: Integer;
  S: string;
begin
  Result := False;
  for I := 0 to Strings.Count - 1 do
  begin
    S := Strings[I];
    P := Pos(Strings.NameValueSeparator, S);
    if (P <> 0) then
    begin
      if (SameText(Copy(S, 1, P - 1), Switch))
        or ((AltSwitch <> '') and (SameText(Copy(S, 1, P - 1), AltSwitch))) then
        begin
          Exit(True);
        end;
    end;
  end;
end;

function GetArgument(Strings: TStrings; out Value: String; Index: Integer): Boolean;
var
  I, P: Integer;
  S: string;
begin
  Result := False;
  Value := '';
  for I := 0 to Strings.Count - 1 do
  begin
    S := Strings[I];
    P := Pos(Strings.NameValueSeparator, S);
    if (P <> 0) then
    begin
      if (Copy(S, 1, P - 1) = '') then
      begin
        if Index = 0 then
        begin
          Value := Copy(S, P + 1, MaxInt);
          Exit(True);
        end;
        Dec(Index);
      end;
    end
    else if (P = 0) then
    begin
      Exit(True);
      Dec(Index);
    end
  end;
end;

function GetArgument(Strings: TStrings; OutStrings: TStrings; AltSwitch: string): Boolean;
  procedure AddNow(S: string);
  begin
    OutStrings.Add(S);
  end;
var
  I, P: Integer;
  S, Value: string;
begin
  Result := False;
  Value := '';
  for I := 0 to Strings.Count - 1 do
  begin
    S := Strings[I];
    P := Pos(Strings.NameValueSeparator, S);
    if (P <> 0) then
    begin
      if (Copy(S, 1, P - 1) = '') then
      begin
        Value := Copy(S, P + 1, MaxInt);
        AddNow(Value);
        Result := True;
      end;
    end
    else if (P = 0) then
      AddNow(S);
  end;
end;

function GetArgument(Strings: TStrings; out OutStrings: TArray<String>): Boolean;
  procedure AddNow(S: string);
  begin
    SetLength(OutStrings, Length(OutStrings) + 1);
    OutStrings[Length(OutStrings) -1] := S;
  end;
var
  I, P: Integer;
  S, Value: string;
begin
  OutStrings := [];
  Result := False;
  Value := '';
  for I := 0 to Strings.Count - 1 do
  begin
    S := Strings[I];
    P := Pos(Strings.NameValueSeparator, S);
    if (P <> 0) then
    begin
      if (Copy(S, 1, P - 1) = '') then
      begin
        Value := Copy(S, P + 1, MaxInt);
        AddNow(Value);
        Result := True;
      end;
    end
    else if (P = 0) then
      AddNow(S);
  end;
end;

function ExpandToPath(FileName: string; Path: string; Root: string): string;
begin
  if (FileName <> '') then
  begin
    if ((LeftStr(FileName, 3) = '../') or (LeftStr(FileName, 3) = '..\')) then
      Result := ExpandFileName(IncludePathDelimiter(Root) + IncludePathDelimiter(Path) + FileName)
    else if ((LeftStr(FileName, 2) = './') or (LeftStr(FileName, 2) = '.\')) then
      Result := IncludePathDelimiter(Root) + IncludePathDelimiter(Path) + RightStr(FileName, Length(FileName) - 2)
{$ifdef MSWINDOWS}
    else if ((LeftStr(FileName, 1) = '/') or (LeftStr(FileName, 1) = '\')) then
      Result := ExtractFileDrive(Path) + FileName
{$endif}
    else
      Result := FileName;
  end
  else
    Result := '';
end;

function CompareLeftStr(const Str: string; const WithStr: string; Start: Integer): Boolean;
var
  i: Integer;
begin
  Result := True;
  if (Length(Str) - Start + 1) < Length(WithStr) then
  begin
    Result := False;
  end
  else
  begin
    for i := 1 to Length(WithStr) do
    begin
      if Str[Start + i - 1] <> WithStr[i] then
      begin
        Result := False;
        break;
      end;
    end;
  end;
end;

function ContainsText(const SubStr, InStr: string): Boolean;
begin
  Result := Pos(UpperCase(SubStr), UpperCase(InStr)) > 0; //Ewww
end;

procedure cMoveStr(var Start: Integer; var Dest: string; const Source: string);
var
  i, l: Integer;
begin
  l := (Length(Dest) - Start) + 1;
  if l > Length(Source) then
    l := Length(Source);
  for i := 1 to l do
  begin
    Dest[Start] := Source[i];
    Start := Start + 1;
  end;
end;

function EscapeString(const S: string; Esc: string; Chars: array of Char; Escapes: array of string): string;
  function InChars(const Char: Char): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    for i := 0 to Length(Chars) - 1 do
    begin
      if Char = Chars[i] then
      begin
        Result := i;
        break;
      end;
    end;
  end;
var
  i: Integer;
  NewLength: Integer;
  p, c: Integer;
  NeedEscape: Boolean;
begin
  if Length(Chars) <> Length(Escapes) then
    raise Exception.Create('Chars and Escapes not identical');
  NeedEscape := False;
  NewLength := Length(S);
  for i := 1 to Length(S) do
  begin
    p := InChars(S[i]);
    if p >= 0 then
    begin
      NewLength := NewLength - 1 + Length(Esc) + Length(Escapes[p]);
      NeedEscape := True;
    end;
  end;
  if not NeedEscape then
    Result := S
  else
  begin
    SetLength(Result, NewLength);
    c := 1;
    for i := 1 to Length(S) do
    begin
      p := InChars(S[i]);
      if p >= 0 then
      begin
        cMoveStr(c, Result, Esc);
        cMoveStr(c, Result, Escapes[p])
      end
      else
      begin
        Result[c] := S[i];
        c := c + 1;
      end;
    end;
  end;
end;

function DescapeString(const S: string; Esc: string; Chars: array of Char; Escapes: array of string): string;
  function InEscape(Start: Integer): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    for i := 0 to Length(Escapes) - 1 do
    begin
      if CompareLeftStr(S, Escapes[i], Start) then
      begin
        Result := i;
        break;
      end;
    end;
  end;
var
  i: Integer;
  NewLength: Integer;
  p, c: Integer;
  NeedDescape: Boolean;
begin
  if Length(Chars) <> Length(Escapes) then
    raise Exception.Create('Chars and Escapes not identical');
  NeedDescape := False;
  NewLength := Length(S);
  i := 1;
  while i <= Length(S) do
  begin
    if CompareLeftStr(S, Esc, i) then
    begin
      i := i + Length(Esc);
      p := InEscape(i);
      if p >= 0 then
      begin
        NewLength := NewLength - Length(Esc) - Length(Escapes[p]) + 1;
        NeedDescape := True;
        i := i + Length(Escapes[p]);
      end;
    end
    else
      i := i + 1;
  end;
  if not NeedDescape then
    Result := S
  else
  begin
    SetLength(Result, NewLength);
    c := 1;
    i := 1;
    while i <= Length(S) do
    begin
      if CompareLeftStr(S, Esc, i) then
      begin
        i := i + Length(Esc);
        p := InEscape(i);
        if p >= 0 then
        begin
          cMoveStr(c, Result, Chars[p]);
          i := i + Length(Escapes[p]);
        end
        else
          cMoveStr(c, Result, Esc);
      end
      else
      begin
        Result[c] := S[i];
        c := c + 1;
        i := i + 1;
      end;
    end;
  end;
end;

function StringsToString(Strings: TStrings; LineBreak: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Strings.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + LineBreak;
    Result := Result + Strings[i];
  end;
end;

function PeriodToString(vPeriod: Double; WithSeconds: Boolean): string;
var
  h, m, s: integer;
  d: Integer;
  g: Boolean;
  function LeadToRight(const vStr: string; Count: integer; vChar: Char): string;
  var
    l: integer;
  begin
    l := Length(vStr);
    if l < Count then
    begin
      Result := StringOfChar(vChar, Count - l) + vStr;
    end
    else
      Result := vStr;
  end;

begin
  g := vPeriod < 0;
  vPeriod := abs(vPeriod);
  d := trunc(vPeriod * SecsPerDay);
  h := d div 3600;
  d := (d  - (h *  3600));
  m := d div 60;
  s := (d  - (m *  60));
  Result := LeadToRight(IntToStr(h), 2, '0') + GetFormatSettings.TimeSeparator + LeadToRight(IntToStr(m), 2, '0');
  if WithSeconds then
  begin
    if s = 0 then
      Result := Result + GetFormatSettings.TimeSeparator + '00'
    else
      Result := Result + GetFormatSettings.TimeSeparator + LeadToRight(IntToStr(s), 2, '0');
  end;
  if g then
    Result := '-' + Result;
end;

function TicksToString(vTicks: Int64): string;
var
  m, s, ms: Cardinal;
begin
  ms := vTicks;
  s := (ms div 1000);
  ms := (ms mod 1000);
  m := (s div 60);
  s := (s mod 60);
//  h := (s mod 60);
  Result := Format('%2d:%2d:%4d', [m, s, ms]);
  //Result := Format('%2d min  : %2d sec  : %2d msec', [m, s, ms]));
end;

procedure InitMemory(out V; Count: {$ifdef FPC}SizeInt{$else}Longint{$endif});
begin
  {$ifdef FPC}
  {$PUSH}
  {$HINTS OFF}
  {$endif}
  FillChar(V, Count, #0);
  {$ifdef FPC}
  {$POP}
  {$endif}
end;

function CopyStr(const AText: String; const AFromIndex, AToIndex: Integer): String;
begin
  Result := Copy(AText, AFromIndex, AToIndex - AFromIndex + 1);
end;

function SubStr(const Str: String; vSeperator: Char; vFromIndex, vToIndex: Integer): String;
var
  Index, B, E: Integer;
  C: Char;
begin
  if Str='' then
    Exit('');

  Index := 0;
  B := 0;
  E := 1;
  for C in Str do
  begin
    if (B = 0) and (Index = vFromIndex) then
      B := E;

    if C = vSeperator then
      Inc(Index);

    if (Index = vToIndex + 1) then
    begin
      E := E - 1;
      Break;
    end;
    Inc(E);
  end;

  if B <> 0 then
    Result := Copy(Str, B, E - B + 1)
  else
    Result := '';
end;

function SubStr(const Str: String; vSeperator: Char; vIndex: Integer): String;
begin
  if Str='' then
    Result := ''
  else
    Result := SubStr(Str, vSeperator, vIndex, vIndex);
end;

procedure SpliteStr(const S, Separator: string; out Name, Value: string);
var
  p: integer;
begin
  p := AnsiPos(Separator, S);
  if P <> 0 then
  begin
    Name := Copy(s, 1, p - 1);
    Value := Copy(s, p + 1, MaxInt);
  end
  else
  begin
    Name := s;
    Value := '';
  end;
end;

function FetchStr(var AInput: string; const ADelim: string; const ADelete: Boolean; const ACaseSensitive: Boolean): string;
var
  LPos: Integer;
begin
  if ADelim = #0 then begin
    // AnsiPos does not work with #0
    LPos := Pos(ADelim, AInput);
  end else begin
    LPos := Pos(ADelim, AInput);
  end;
  if LPos = 0 then begin
    Result := AInput;
    if ADelete then begin
      AInput := '';    {Do not Localize}
    end;
  end
  else begin
    Result := Copy(AInput, 1, LPos - 1);
    if ADelete then begin
      //slower Delete(AInput, 1, LPos + Length(ADelim) - 1); because the
      //remaining part is larger than the deleted
      AInput := Copy(AInput, LPos + Length(ADelim), MaxInt);
    end;
  end;
end;

function StrInArray(const Str: String; const InArray: array of String; CaseInsensitive: Boolean): Boolean;
var
 itm : String;
begin
  for itm in InArray do
  begin
    if CaseInsensitive then
    begin
      if SameText(Str, itm) then
        exit(True);
    end
    else if Str = itm then
       exit(true);
  end;
  Result := False;
end;

function StrInArray(const Str: string; const StartIndex: Integer; const InArray: array of string; out SepLength: Integer; CaseInsensitive: Boolean): Boolean;
var
 itm : String;
begin
  for itm in InArray do
  begin
    if CaseInsensitive then
    begin
      if SameText(MidStr(Str, StartIndex, Length(Itm)), itm) then
      begin
        SepLength := Length(Itm);
        exit(true);
      end;
    end
    else if MidStr(Str, StartIndex, Length(Itm)) = itm then
    begin
      SepLength := Length(Itm);
      exit(true);
    end;
  end;
  SepLength := 0;
  Result := false;
end;

function CharInArray(const C: string; const ArrayOfChar: array of Char; CaseInsensitive: Boolean): Boolean;
var
 itm : String;
begin
  for itm in ArrayOfChar do
  begin
    if CaseInsensitive then
    begin
      if UpperCase(C) = UpperCase(itm) then
        exit(true);
    end
    else if C = itm then
       exit(true);
  end;
  Result := false;
end;

function EscapeStringC(const S: string): string;
begin
  Result := EscapeString(s, '\', [#8, #9, #10, #13, '\', '"'], ['b', 't', 'n', 'r', '\', '"']);
end;

function DescapeStringC(const S: string): string;
begin
  Result := DescapeString(s, '\', [#8, #9, #10, #13, '\', '"'], ['b', 't', 'n', 'r', '\', '"']);
end;

function ToUnixPathDelimiter(const S: string): string;
begin
  Result := StringReplace(S, '\', '/', [rfReplaceAll]);
end;

function IncludePathDelimiter(const S: string): string;
begin
  if (s <> '') and (RightStr(S, 1) <> PathDelim) then
    Result := s + PathDelim
  else
    Result := s;
end;

function IncludePathSeparator(const S: string): string;
begin
  Result := IncludePathDelimiter(S);
end;

function IncludeURLDelimiter(S: string): string;
begin
  if (s <> '') and (RightStr(S, 1) <> '/') then
    Result := S + '/'
  else
    Result := S;
end;

function ExcludePathDelimiter(Path: string): string;
begin
  if Path = '' then
    Result := ''
  else
    Result := ExcludeTrailingPathDelimiter(Path);
end;

procedure CenterRect(var R1: TRect; R2: TRect);
begin
  OffsetRect(R1, ((R2.Right - R2.Left) div 2) - ((R1.Right - R1.Left) div 2) + (R2.Left - R1.Left), ((R2.Bottom - R2.Top) div 2) - ((R1.Bottom - R1.Top) div 2) + (R2.Top - R1.Top));
end;

function GetFormatSettings: TFormatSettings;
begin
  {$ifdef FPC}
  Result := DefaultFormatSettings;
  {$else}
    {$if CompilerVersion >= 22.0}
    Result := FormatSettings;
    {$else}
    Result := FFormatSettings;
    {$ifend}
  {$endif}
end;


procedure ISOStrToDate(ISODate: String; out Y, M, D, H, N, S: Word; vDateSeparator: Char; TimeDivider: Char; UseDefault: Boolean);
var
  Dt, Tm: String;
begin
  try
    if TimeDivider = #0 then
    begin
      if Pos('T', ISODate) > 0 then
        TimeDivider := 'T'
      else
        TimeDivider := ' ';
    end;

    if UseDefault then
      DecodeDate(Now, Y, M, D)
    else
      DecodeDate(0, Y, M, D);

    Dt := SubStr(ISODate, TimeDivider, 0);
    Tm := SubStr(ISODate, TimeDivider, 1);
    if Tm = '' then //one part
    begin
      if Pos(':', Dt) > 0 then //detect if it a time
      begin
        Tm := Dt;
        Dt := '';
      end
    end;

    if Dt <> '' then
    begin
      Y := StrToIntDef(SubStr(Dt, vDateSeparator, 0), Y);
      M := StrToIntDef(SubStr(Dt, vDateSeparator, 1), M);
      D := StrToIntDef(SubStr(Dt, vDateSeparator, 2), D);
    end;

    if Tm <> '' then
    begin
      Tm := SubStr(Tm, '+', 0);//skip time zone after plus
      H := StrToIntDef(SubStr(Tm, ':', 0), 0);
      N := StrToIntDef(SubStr(Tm, ':', 1), 0);
      //S := Round(StrToFloatDef(SubStr(Tm, ':', 2), 0)); //case 59.500s to round to 60 ->Error
      S := Trunc(StrToFloatDef(SubStr(Tm, ':', 2), 0));
    end
    else
    begin
      H := 0;
      N := 0;
      S := 0;
    end;
  except
    raise Exception.Create('Not valid DateTime');
  end;
end;

function ISOStrToDate(ISODate: String; vDateSeparator: Char; TimeDivider: Char; UseDefault: Boolean): TDateTime;
var
  Y, M, D, H, N, S: Word;
begin
  ISOStrToDate(ISODate, Y, M, D, H, N, S, vDateSeparator, TimeDivider, UseDefault);
  Result := EncodeDate(Y, M, D) + EncodeTime(H, N, S, 0);
end;

function ISODateToStr(DateTime: TDateTime; vDateSeparator: Char = '-'; TimeDivider: Char = ' '; TimeSeparator: Char = ':'; WithTime: Boolean = False): String; overload;
var
  Y, M, D, H, N, S, O: Word;
begin
  DecodeDate(DateTime, Y, M, D);
  Result := AlignStr(IntToStr(Y), 4, [alsRight], '0') + vDateSeparator +  AlignStr(IntToStr(M), 2, [alsRight],'0') + vDateSeparator + AlignStr(IntToStr(D), 2, [alsRight], '0');
  if WithTime then
  begin
    DecodeTime(DateTime, H, N, S, O);
    Result := Result + TimeDivider + AlignStr(IntToStr(H), 2, [alsRight],'0') + TimeSeparator + AlignStr(IntToStr(N), 2, [alsRight],'0') + TimeSeparator + AlignStr(IntToStr(S), 2, [alsRight], '0');
  end;
end;

function ISODateToStr(DateTime: TDateTime; vDateSeparator: Char; TimeDivider: Char; WithTime: Boolean): String;
begin
  Result := ISODateToStr(DateTime, vDateSeparator, TimeDivider, ':',  WithTime);
end;

//* thanks to https://stackoverflow.com/a/41726706/585304

{ TEncodingHelper }

class function TEncodingHelper.CodePageEncoding(CodePage: Word): TEncoding;
begin
  case CodePage of
{$IFDEF ANDROID}
    437: Result := ANSI;
{$ENDIF ANDROID}
    1200: Result := Unicode;
    1201: Result := BigEndianUnicode;
    CP_UTF7: Result := UTF7;
    CP_UTF8: Result := UTF8;
  else
    Result := ANSI;
  end;
end;

function TEncodingHelper.GetString(Bytes: PByte; ByteCount: Integer): String;
var
  aLen: Integer;
begin
  Result := '';
  if ByteCount<>0 then
  begin
    aLen := GetCharCount(Bytes, ByteCount);
    if (aLen <>0) then
    begin
      SetLength(Result, aLen);
      {$ifdef FPC}
      GetChars(Bytes, ByteCount, PUnicodeChar(Result), aLen);
      {$else}
      GetChars(Bytes, ByteCount, PChar(Result), aLen);
      {$endif}
    end;
  end
end;

{$ifdef FPC}
function TEncodingHelper.GetString(Bytes: array of Byte): String;
var
  L, Count: Integer;
begin
  {$ifdef FPC}
  Result := '';
  {$endif}
  L := Length(Bytes);
  Count := GetCharCount(@Bytes[0], L);
  if (Count = 0) and (L > 0) then
    raise Exception.Create('Wrong encoding!');
  SetLength(Result, Count);
  GetChars(@Bytes[0], L, PUnicodeChar(Result), Count);
end;
{$endif}

function StringOf(const Value: PByte; Size: Integer; CodePage: Word = CP_UTF8): string;
begin
  Result := TEncoding.CodePageEncoding(CodePage).GetString(Value, Size);
end;

function StringOf(const Value: array of Byte; CodePage: Word): string;
begin
  Result := TEncoding.CodePageEncoding(CodePage).GetString(Value);
end;

function StringOf(const Value: TBytes; CodePage: Word): string;
begin
  Result := TEncoding.CodePageEncoding(CodePage).GetString(Value);
end;

function Hex2String(const vData: string): string; overload;
var
  b, r: TBytes;
begin
  if vData<>'' then
  begin
    b := TEncoding.ANSI.GetBytes(vData);
    SetLength(r, Length(vData) div 2);

    HexToBin(PByte(@b[0]), PByte(@r[0]), Length(r));
    Result := TEncoding.Unicode.GetString(r);
  end
  else
    Result := '';
end;

function String2Hex(const vData: string): string; overload;
begin
  if vData<>'' then
    Result := String2Hex(PByte(vData), ByteLength(vData))
  else
    Result := '';
end;

function String2Hex(const vData: PByte; vCount: Integer): string;
begin
  SetLength(Result, 2*vCount);
  BinToHex(vData, PByte(Result), vCount);
end;

const
  //H2BValidSet = ['0'..'9','A'..'F','a'..'f'];
  //H2BConvert: array['0'..'f'] of SmallInt = ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,-1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,10,11,12,13,14,15);
  H2BValidSet = [$30..$39,$41..$46,$61..$66];
  H2BConvert: array[$30..$66] of SmallInt = ( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,-1,-1,-1,-1,-1,-1,-1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,10,11,12,13,14,15);

function HexToBin(Text : PByte; Buffer: PByte; BufSize: longint): Integer;
var
  I: Integer;
begin
  I := BufSize;
  while I > 0 do
  begin
    if not (Text^ in H2BValidSet) or not ((Text+1)^ in H2BValidset) then Break;
    Buffer^ := (H2BConvert[Text[0]] shl 4) + H2BConvert[Text[1]];
    Inc(Buffer);
    Inc(Text, 2);
    Dec(I);
  end;
  Result := BufSize - I;
end;

procedure BinToHex(Buffer: PByte; Text: PByte; BufSize: longint);
const
  Convert: array[0..15] of Byte = ($30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$41,$42,$43,$44,$45,$46) ; //AnsiString('0123456789ABCDEF');
var
  I: Integer;
  p: PByte;
begin
  p := Text;
  for I := 0 to BufSize - 1 do
  begin
    p^ := Convert[Buffer[I] shr 4];
    Inc(p);
    P^ := Convert[Buffer[I] and $F];
    Inc(p);
  end;
end;

function IsAllLowerCase(S: string): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 1 to Length(S) do
  begin
    {$ifdef FPC}
    if IsUpper(S[i]) then
    {$else}
    if S[i].IsUpper then
    {$endif}
    begin
      Result := False;
      break;
    end;
  end;
end;

function GetSizeOfFile(const vFile: string): Int64;
var
  R: TSearchRec;
begin
  if SysUtils.FindFirst(vFile, faAnyFile, R) = 0 then
  begin
    Result := R.Size;
    SysUtils.FindClose(R);
  end
  else
    Result := -1;
end;

procedure EnumFiles(FileList: TStringList; Folder, Filter: string; Options: TEnumFilesOptions); overload;
var
  R: integer;
  SearchRec: TSearchRec;
begin
  Folder := IncludeTrailingPathDelimiter(Folder);
  R := FindFirst(Folder + Filter, faAnyFile, SearchRec);
  while R = 0 do
  begin
    if (((efDirectory in Options) and ((SearchRec.Attr and faDirectory) = faDirectory))
      or ((efFile in Options) and ((SearchRec.Attr and faDirectory) <> faDirectory)))
      and ((SearchRec.Name <> '.') and (SearchRec.Name <> '..')) then
    begin
      if efFullPath in Options then
        FileList.Add(Folder + SearchRec.Name)
      else
        FileList.Add(SearchRec.Name);
    end;
    R := FindNext(SearchRec);
  end;
  FindClose(SearchRec);
end;

function DeleteFiles(Path, Files: string): Integer;
var
  FileList: TStringList;
  f: string;
begin
  FileList := TStringList.Create;
  try
    EnumFiles(FileList, Path, Files, [efFile, efFullPath]);
    Result := FileList.Count;
    for f in FileList do
      DeleteFile(f);
  finally
    FileList.Free;
  end;
end;

function FirstFile(Path, Files: string): string;
var
  FileList: TStringList;
begin
  FileList := TStringList.Create;
  try
    EnumFiles(FileList, Path, Files, [efFile, efFullPath]);
    if FileList.Count > 0 then
      Result := FileList[0]
    else
      Result := ''
  finally
    FileList.Free;
  end;
end;

initialization
  {$ifdef windows}
  SystemAnsiCodePage := GetACP; //windows only
  {$else}
  SystemAnsiCodePage := 1252; //scpAnsi has no meaning in linux, you can change it in your application
  {$endif}
end.

