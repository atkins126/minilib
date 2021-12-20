program Project1;

{$MODE Delphi}

{**
 *  This file is part of the "Mini Library"
 *
 * @license   modifiedLGPL (modified of http://www.gnu.org/licenses/lgpl.html)
 *            See the file COPYING.MLGPL, included in this distribution,
 * @author    Zaher Dirkey
 *}
uses
  Forms, Interfaces,
  Unit1 in 'Unit1.pas' {Form1},
  mnXML in '..\..\source\mnXML.pas',
  mnXMLWriter in '..\..\source\mnXMLWriter.pas',
  mnXMLReader in '..\..\source\mnXMLReader.pas',
  mnXMLScanner in '..\..\source\mnXMLScanner.pas',
  mnXMLNodes in '..\..\source\mnXMLNodes.pas',
  mnXMLUtils in '..\..\source\mnXMLUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
