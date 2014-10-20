program DelphiMongoClientTests;

{$IFDEF DCC_ConsoleTarget}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils,
  Forms,
  TestFramework,
  GUITestRunner,
  XmlTestRunner2,
  TestMongoDB in 'TestMongoDB.pas',
  TestMongoBson in 'TestMongoBson.pas',
  TestGridFS in 'TestGridFS.pas',
  TestMongoStream in 'TestMongoStream.pas',
  TestMongoPool in 'TestMongoPool.pas',
  TestMongoBsonSerializer in 'TestMongoBsonSerializer.pas',
  APPEXEC in '..\APPEXEC.PAS',
  GridFS in '..\GridFS.pas',
  LibBsonAPI in '..\LibBsonAPI.pas',
  MongoAPI in '..\MongoAPI.pas',
  MongoBson in '..\MongoBson.pas',
  MongoBsonSerializableClasses in '..\MongoBsonSerializableClasses.pas',
  MongoBsonSerializer in '..\MongoBsonSerializer.pas',
  MongoDB in '..\MongoDB.pas',
  MongoPool in '..\MongoPool.pas',
  MongoStream in '..\MongoStream.pas',
  uAllocators in '..\uAllocators.pas',
  uCnvDictionary in '..\uCnvDictionary.pas',
  uWinProcHelper in '..\uWinProcHelper.pas';

var
  xml_filename: string;

begin
  if IsConsole then
  begin
    xml_filename := ChangeFileExt(ExtractFileName(Application.ExeName), '.xml');
    XMLTestRunner2.RunRegisteredTests(xml_filename);
  end
  else
    GUITestRunner.RunRegisteredTests;
end.