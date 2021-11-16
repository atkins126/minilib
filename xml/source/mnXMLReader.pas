unit mnXMLReader;
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
  Classes, SysUtils, mnXMLScanner;

type
  TmnXMLReadState = record
    Name: string;
    Attributes: string; //must be a list object and take the default attributes from DTD
    Empty: Boolean; //with out a content
  end;

  TmnXMLReader = class(TmnXMLScanner)
  private
    procedure ParseStream;
  protected
    procedure DoStart; override;
    procedure DoStop; override;
    procedure DoReadState(ReadState: TmnXMLReadState); virtual;
  end;

implementation

uses
  mnStreams;

{ TmnXMLReader }

procedure TmnXMLReader.DoStart;
begin
  inherited;
  if Stream <> nil then
  begin
    ParseStream;
  end;
end;

procedure TmnXMLReader.DoStop;
begin
  inherited;
end;

procedure TmnXMLReader.ParseStream;
var
  Text: utf8string;
  Line: Integer;
begin
  Line := 1;
  try
    while not (cloRead in Stream.Done) and not Completed do
    begin
      Text := '';
      if Stream.ReadLineUTF8(Text, False) then
        ParseLine(Text, Line);
      Line := Line + 1;
    end;
  except
    raise;
  end;
{  if not Completed then
    raise EmnXMLParserException.Create('Not completed xml', Line, Column);}
end;

procedure TmnXMLReader.DoReadState(ReadState: TmnXMLReadState);
begin
end;

end.

