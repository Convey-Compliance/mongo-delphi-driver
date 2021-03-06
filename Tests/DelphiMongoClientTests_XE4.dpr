program DelphiMongoClientTests_XE4;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options 
  to use the console test runner.  Otherwise the GUI test runner will be used by 
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF FASTMM}
  FastMM4,
  {$ENDIF }
  SysUtils,
  Forms,
  XMLTestRunner2,
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  TestMongoDB in 'TestMongoDB.pas',
  TestMongoBson in 'TestMongoBson.pas',
  TestGridFS in 'TestGridFS.pas',
  TestMongoStream in 'TestMongoStream.pas',
  TestMongoPool in 'TestMongoPool.pas',
  APPEXEC in '..\APPEXEC.PAS',
  uWinProcHelper in '..\uWinProcHelper.pas',
  GridFS in '..\GridFS.pas',
  MongoAPI in '..\MongoAPI.pas',
  MongoBson in '..\MongoBson.pas',
  MongoDB in '..\MongoDB.pas',
  MongoPool in '..\MongoPool.pas',
  MongoStream in '..\MongoStream.pas',
  uAllocators,
  LibBsonAPI in '..\LibBsonAPI.pas',
  TestMongoBsonSerializer in 'TestMongoBsonSerializer.pas',
  MongoBsonSerializer in '..\MongoBsonSerializer.pas',
  MongoBsonSerializableClasses in '..\MongoBsonSerializableClasses.pas',
  uCnvDictionary in '..\uCnvDictionary.pas';

{$R *.RES}

var
  GUITestRunner_ :TGUITestRunner;

begin
  if ParamStr(1) = '-console' then
    IsConsole := True;
  Application.Initialize;
  if IsConsole then
    XMLTestRunner2.RunRegisteredTests(ExpandFileName(ParamStr(2)))
  else
    begin
      Application.CreateForm(TGUITestRunner, GUITestRunner_);
      GUITestRunner_.Suite := RegisteredTests;
      Application.Run;
    end;
end.

