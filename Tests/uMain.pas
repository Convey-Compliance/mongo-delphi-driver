unit uMain;
(* This unit needed to avoid copypast between
   DelphiMongoClientTests.dpr and DelphiMongoClientTests_XE4.dpr *)

interface

procedure Main;

implementation

uses
  SysUtils,
  Forms,
  TestFramework,
  GUITestRunner,
  XmlTestRunner2,
  MongoAPI;

var
  xml_filename: string;
{$IFDEF OnDemandMongoCLoad}
  MongoCDLLName : UTF8String;
{$ENDIF}

procedure Main;
begin
{$IFDEF OnDemandMongoCLoad}
  {$IFDEF Enterprise}
  MongoCDLLName := Default_MongoCDLL;
  {$ELSE}
  if LowerCase(ExtractFileExt(ParamStr(1))) = '.dll' then
    MongoCDLLName := ParamStr(1)
  else
    MongoCDLLName := Default_MongoCDLL;
  {$ENDIF}
  InitMongoDBLibrary(MongoCDLLName);
{$ENDIF}

  if IsConsole then
  begin
    xml_filename := ChangeFileExt(ExtractFileName(Application.ExeName), '.xml');
    XMLTestRunner2.RunRegisteredTests(xml_filename);
  end
  else
    GUITestRunner.RunRegisteredTests;
{$IFDEF OnDemandMongoCLoad}
  DoneMongoDBLibrary;
{$ENDIF}
end;

end.
