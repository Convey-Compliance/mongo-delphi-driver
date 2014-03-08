unit TestMongoBsonSerializer;

interface

uses
  TestFramework{$IFNDEF VER130}, Variants{$EndIf}, MongoBsonSerializer;

type
  TestTMongoBsonSerializer = class(TTestCase)
  private
    FSerializer: TBaseBsonSerializer;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreate;
    procedure TestSerializePrimitiveTypes;
  end;

implementation

uses
  MongoBson, MongoApi, System.Classes;

type
  TEnumeration = (eFirst, eSecond);
  TEnumerationSet = set of TEnumeration;
  TMethodEvent = procedure of object;
  {$M+}
  TSubObject = class
  private
    FTheInt: Integer;
  published
    property TheInt: Integer read FTheInt write FTheInt;
  end;

  TTestObject = class
  private
    FThe_02_AnsiChar: AnsiChar;
    FThe_00_Int: Integer;
    FThe_01_Int64: Int64;
    FThe_03_Enumeration: TEnumeration;
    FThe_04_Float: Extended;
    FThe_05_String: String;
    FThe_06_ShortString: ShortString;
    FThe_07_Set: TEnumerationSet;
    FThe_08_SubObject: TSubObject;
    FThe_09_MethodPointer: TMethodEvent;
    FThe_10_WChar: WideChar;
    FThe_11_AnsiString: AnsiString;
    FThe_12_WideString: WideString;
    FThe_13_StringList: TStringList;
    FThe_14_VariantAsInteger : Variant;
    FThe_15_VariantAsString: Variant;
    FThe_16_VariantAsArray : Variant;
    FThe_17_VariantTwoDimArray : Variant;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property The_00_Int: Integer read FThe_00_Int write FThe_00_Int;
    property The_01_Int64: Int64 read FThe_01_Int64 write FThe_01_Int64;
    property The_02_AnsiChar: AnsiChar read FThe_02_AnsiChar write FThe_02_AnsiChar;
    property The_03_Enumeration: TEnumeration read FThe_03_Enumeration write FThe_03_Enumeration;
    property The_04_Float: Extended read FThe_04_Float write FThe_04_Float;
    property The_05_String: String read FThe_05_String write FThe_05_String;
    property The_06_ShortString: ShortString read FThe_06_ShortString write FThe_06_ShortString;
    property The_07_Set: TEnumerationSet read FThe_07_Set write FThe_07_Set;
    property The_08_SubObject: TSubObject read FThe_08_SubObject write FThe_08_SubObject;
    property The_09_MethodPointer: TMethodEvent read FThe_09_MethodPointer write FThe_09_MethodPointer;
    property The_10_WChar: WideChar read FThe_10_WChar write FThe_10_WChar;
    property The_11_AnsiString: AnsiString read FThe_11_AnsiString write FThe_11_AnsiString;
    property The_12_WideString: WideString read FThe_12_WideString write FThe_12_WideString;
    property The_13_StringList: TStringList read FThe_13_StringList write FThe_13_StringList;
    property The_14_VariantAsInteger : Variant read FThe_14_VariantAsInteger write FThe_14_VariantAsInteger;
    property The_15_VariantAsString: Variant read FThe_15_VariantAsString write FThe_15_VariantAsString;
    property The_16_VariantAsArray: Variant read FThe_16_VariantAsArray write FThe_16_VariantAsArray;
    property The_17_VariantTwoDimArray: Variant read FThe_17_VariantTwoDimArray write FThe_17_VariantTwoDimArray;
  end;
  {$M-}

constructor TTestObject.Create;
begin
  inherited Create;
  FThe_08_SubObject := TSubObject.Create;
  FThe_13_StringList := TStringList.Create;
end;

destructor TTestObject.Destroy;
begin
  FThe_13_StringList.Free;
  FThe_08_SubObject.Free;
  inherited Destroy;
end;

procedure TestTMongoBsonSerializer.SetUp;
begin
  FSerializer := CreateSerializer(TObject);
end;

procedure TestTMongoBsonSerializer.TearDown;
begin
  FSerializer.Free;
end;

procedure TestTMongoBsonSerializer.TestCreate;
begin
  Check(FSerializer <> nil, 'FSerializer should be <> nil');
end;

procedure TestTMongoBsonSerializer.TestSerializePrimitiveTypes;
var
  it, SubIt : IBsonIterator;
  Obj : TTestObject;
  v : Variant;
begin
  FSerializer.Target := NewBsonBuffer();
  Obj := TTestObject.Create;
  try
    FSerializer.Source := Obj;
    Obj.The_00_Int := 10;
    Obj.The_01_Int64 := 11;
    Obj.The_02_AnsiChar := 'B';
    Obj.The_03_Enumeration := eSecond;
    Obj.The_04_Float := 1.5;
    Obj.The_05_String := 'дом';
    Obj.The_06_ShortString := 'Hello';
    Obj.The_07_Set := [eFirst, eSecond];
    Obj.The_08_SubObject.TheInt := 12;
    Obj.The_09_MethodPointer := nil;
    Obj.The_10_WChar := 'д';
    Obj.The_11_AnsiString := 'Hello World';
    Obj.The_12_WideString := 'дом дом';
    Obj.The_13_StringList.Add('дом');
    Obj.The_13_StringList.Add('ом');
    Obj.The_14_VariantAsInteger := 14;
    Obj.The_15_VariantAsString := 'дом дом дом';
    v := VarArrayCreate([0, 1], varInteger);
    v[0] := 16;
    v[1] := 22;
    Obj.The_16_VariantAsArray := v;
    v := VarArrayCreate([0, 1, 0, 1], varInteger);
    v[0, 0] := 16;
    v[0, 1] := 22;
    v[1, 0] := 33;
    v[1, 1] := 44;
    Obj.The_17_VariantTwoDimArray := v;
    FSerializer.Serialize('');

    it := NewBsonIterator(FSerializer.Target.finish);
    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_00_Int', it.key);
    CheckEquals(10, it.value, 'Iterator should be equals to 10');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_01_Int64', it.key);
    CheckEquals(11, it.AsInt64, 'Iterator should be equals to 11');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_02_AnsiChar', it.key);
    CheckEquals(AnsiChar('B'), ShortString(it.Value), 'Iterator should be equals to "B"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_03_Enumeration', it.key);
    CheckEqualsString('eSecond', AnsiString(it.Value), 'Iterator should be equals to "eSecond"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_04_Float', it.key);
    CheckEquals(1.5, it.Value, 'Iterator should be equals to 1.5');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_05_String', it.key);
    CheckEqualsString('дом', it.Value, 'Iterator should be equals to "дом"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_06_ShortString', it.key);
    CheckEqualsString('Hello', it.Value, 'Iterator should be equals to "Hello"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_07_Set', it.key);
    Check(it.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEqualsString('eFirst', SubIt.Value, 'Iterator should be equals to "eFirst"');
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEqualsString('eSecond', SubIt.Value, 'Iterator should be equals to "eSecond"');
    Check(not SubIt.next, 'Iterator should be at end');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_08_SubObject', it.key);
    Check(it.Kind = bsonOBJECT, 'Type of iterator value should be bsonOBJECT');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(12, SubIt.Value, 'Iterator should be equals to 12');
    Check(not SubIt.next, 'Iterator should be at end');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_10_WChar', it.key);
    CheckEqualsString('д', it.Value, 'Iterator should be equals to "д"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_11_AnsiString', it.key);
    CheckEqualsString('Hello World', it.Value, 'Iterator should be equals to "Hello World"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_12_WideString', it.key);
    CheckEqualsString('дом дом', it.Value, 'Iterator should be equals to "дом дом"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_13_StringList', it.key);
    Check(it.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEqualsString('дом', SubIt.Value, 'Iterator should be equals to "дом"');
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEqualsString('ом', SubIt.Value, 'Iterator should be equals to "ом"');
    Check(not SubIt.next, 'Iterator should be at end');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_14_VariantAsInteger', it.key);
    CheckEquals(14, it.value, 'Iterator should be equals to 14');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_15_VariantAsString', it.key);
    CheckEqualsString('дом дом дом', it.Value, 'Iterator should be equals to "дом дом дом"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_16_VariantAsArray', it.key);
    Check(it.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(16, SubIt.Value, 'Iterator should be equals to 16');
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(22, SubIt.Value, 'Iterator should be equals to 22');
    Check(not SubIt.next, 'Iterator should be at end');

    Check(not it.next, 'Iterator should be at end');
  finally
    Obj.Free;
  end;
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TestTMongoBsonSerializer.Suite);
end.

