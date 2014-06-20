unit TestMongoBsonSerializer;

{$i DelphiVersion_defines.inc}

interface

uses
  TestFramework{$IFNDEF VER130}, Variants{$EndIf}, MongoBsonSerializer, MongoBsonSerializableClasses;

type
  {$M+}
  TestTMongoBsonSerializer = class(TTestCase)
  private
    FSerializer: TBaseBsonSerializer;
    FDeserializer : TBaseBsonDeserializer;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreateDeserializer(FSerializer: TBaseBsonSerializer; const Value:
        string);
    procedure TestCreateSerializer;
    procedure TestSerializeObjectAsStringList_Flat;
    procedure TestSerializeObjectDeserializeWithDynamicBuilding;
    procedure TestSerializeObjectDeserializeWithDynamicBuilding_FailTypeNotFound;
    procedure TestSerializeObjectDeserializeWithDynamicBuildingOfObjProp;
    procedure TestSerializePrimitiveTypes;
  end;
  {$M-}

implementation

uses
  MongoBson, MongoApi, Classes, SysUtils;

type
  TEnumeration = (eFirst, eSecond);
  TEnumerationSet = set of TEnumeration;
  TDynIntArr = array of Integer;
  TDynIntArrArr = array of array of Integer;
  {$M+}
  TSubObject = class
  private
    FTheInt: Integer;
  published
    property TheInt: Integer read FTheInt write FTheInt;
  end;

  TTestObject = class
  private
    F_a : integer;
    FThe_02_AnsiChar: AnsiChar;
    FThe_00_Int: Integer;
    FThe_01_Int64: Int64;
    FThe_03_Enumeration: TEnumeration;
    FThe_04_Float: Extended;
    FThe_05_String: String;
    FThe_06_ShortString: ShortString;
    FThe_07_Set: TEnumerationSet;
    FThe_08_SubObject: TSubObject;
    FThe_09_DynIntArr: TDynIntArr;
    FThe_10_WChar: WideChar;
    FThe_11_AnsiString: AnsiString;
    FThe_12_WideString: WideString;
    FThe_13_StringList: TStringList;
    FThe_14_VariantAsInteger : Variant;
    FThe_15_VariantAsString: Variant;
    FThe_16_VariantAsArray : Variant;
    FThe_17_VariantTwoDimArray : Variant;
    FThe_18_VariantAsArrayEmpty: Variant;
    FThe_19_Boolean: Boolean;
    FThe_20_DateTime: TDateTime;
    FThe_21_MemStream: TMemoryStream;
    FThe_22_BlankMemStream: TMemoryStream;
    FThe_23_EmptySet: TEnumerationSet;
    FThe_24_DynIntArrArr: TDynIntArrArr;
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
    property The_09_DynIntArr: TDynIntArr read FThe_09_DynIntArr write FThe_09_DynIntArr;
    property The_10_WChar: WideChar read FThe_10_WChar write FThe_10_WChar;
    property The_11_AnsiString: AnsiString read FThe_11_AnsiString write FThe_11_AnsiString;
    property The_12_WideString: WideString read FThe_12_WideString write FThe_12_WideString;
    property The_13_StringList: TStringList read FThe_13_StringList write FThe_13_StringList;
    property The_14_VariantAsInteger : Variant read FThe_14_VariantAsInteger write FThe_14_VariantAsInteger;
    property The_15_VariantAsString: Variant read FThe_15_VariantAsString write FThe_15_VariantAsString;
    property The_16_VariantAsArray: Variant read FThe_16_VariantAsArray write FThe_16_VariantAsArray;
    property The_17_VariantTwoDimArray: Variant read FThe_17_VariantTwoDimArray write FThe_17_VariantTwoDimArray;
    property The_18_VariantAsArrayEmpty: Variant read FThe_18_VariantAsArrayEmpty write FThe_18_VariantAsArrayEmpty;
    property The_19_Boolean: Boolean read FThe_19_Boolean write FThe_19_Boolean;
    property The_20_DateTime: TDateTime read FThe_20_DateTime write FThe_20_DateTime;
    property The_21_MemStream: TMemoryStream read FThe_21_MemStream;
    property The_22_BlankMemStream: TMemoryStream read FThe_22_BlankMemStream;
    property The_23_EmptySet: TEnumerationSet read FThe_23_EmptySet write FThe_23_EmptySet;
    property The_24_DynIntArrArr: TDynIntArrArr read FThe_24_DynIntArrArr write FThe_24_DynIntArrArr;
    property _a : integer read F_a write F_a; // this property serves the purpose to test mongo dynamics to return _type first
  end;

  TTestObjectWithObjectAsStringList = class
  private
    FObjectAsStringList: TObjectAsStringList;
    procedure SetObjectAsStringList(const Value: TObjectAsStringList);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property ObjectAsStringList: TObjectAsStringList read FObjectAsStringList write SetObjectAsStringList;
  end;
  {$M-}

constructor TTestObject.Create;
begin
  inherited Create;
  FThe_08_SubObject := TSubObject.Create;
  FThe_13_StringList := TStringList.Create;
  FThe_21_MemStream := TMemoryStream.Create;
  FThe_22_BlankMemStream := TMemoryStream.Create;
end;

destructor TTestObject.Destroy;
begin
  FThe_22_BlankMemStream.Free;
  FThe_21_MemStream.Free;
  FThe_13_StringList.Free;
  FThe_08_SubObject.Free;
  inherited Destroy;
end;

procedure TestTMongoBsonSerializer.SetUp;
begin
  FSerializer := CreateSerializer(TObject);
  FDeserializer := CreateDeserializer(TObject);
end;

procedure TestTMongoBsonSerializer.TearDown;
begin
  FDeserializer.Free;
  FSerializer.Free;
end;

procedure TestTMongoBsonSerializer.TestCreateDeserializer(FSerializer:
    TBaseBsonSerializer; const Value: string);
begin
  Check(FDeserializer <> nil, 'FDeserializer should be <> nil');
end;

procedure TestTMongoBsonSerializer.TestCreateSerializer;
begin
  Check(FSerializer <> nil, 'FSerializer should be <> nil');
end;

procedure TestTMongoBsonSerializer.TestSerializeObjectAsStringList_Flat;
var
  TestObject1, TestObject2 : TTestObjectWithObjectAsStringList;
  b : IBson;
  it, SubIt : IBsonIterator;
begin
  FSerializer.Target := NewBsonBuffer();
  TestObject1 := TTestObjectWithObjectAsStringList.Create();
  try
    TestObject1.ObjectAsStringList.Add('Name1=Value1');
    TestObject1.ObjectAsStringList.Add('Name2=Value2');
    TestObject1.ObjectAsStringList.Add('Name3=Value3');
    TestObject1.ObjectAsStringList.Add('Name4=Value4');
    TestObject1.ObjectAsStringList.Add('Name5=Value5');

    FSerializer.Serialize('', TestObject1);

    b := FSerializer.Target.finish;
    it := NewBsonIterator(b);
    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('_type', it.key);
    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('ObjectAsStringList', it.key);
    Check(it.Kind = bsonObject, 'Type of iterator value should be bsonObject');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals('Name1', SubIt.key, 'Iterator should be equals to Value1');
    CheckEquals('Value1', SubIt.value, 'Iterator should be equals to Value1');
    SubIt.next;
    SubIt.next;
    SubIt.next;
    SubIt.next;
    CheckEquals('Name5', SubIt.key, 'Iterator should be equals to Value1');
    CheckEquals('Value5', SubIt.value, 'Iterator should be equals to Value1');

    TestObject2 := TTestObjectWithObjectAsStringList.Create;
    try
      FDeserializer.Source := NewBsonIterator(b);
      FDeserializer.Deserialize(TObject(TestObject2));

      CheckEquals('Name1=Value1', TestObject2.ObjectAsStringList[0]);
      CheckEquals('Name5=Value5', TestObject2.ObjectAsStringList[4]);
    finally
      FreeAndNil(TestObject2);
    end;
  finally
    FreeAndNil(TestObject1);
  end;
end;

function BuildTTestObject(const AClassName : string) : TObject;
begin
  Result := TTestObject.Create;
end;

procedure TestTMongoBsonSerializer.TestSerializeObjectDeserializeWithDynamicBuilding;
var
  AObj : TTestObject;
begin
  AObj := TTestObject.Create;
  try
    AObj.The_00_Int := 123;
    FSerializer.Target := NewBsonBuffer();
    FSerializer.Serialize('', AObj);
  finally
    AObj.Free;
  end;
  AObj := nil;
  FDeserializer.Source := FSerializer.Target.finish.iterator;
  RegisterBuildableSerializableClass(TTestObject.ClassName, BuildTTestObject);
  try
    FDeserializer.Deserialize(TObject(AObj));
    Check(AObj <> nil, 'Object returned from deserialization must be <> nil');
    CheckEquals(123, AObj.The_00_Int, 'The_00_Int attribute should be equals to 123');
  finally
    UnregisterBuildableSerializableClass(TTestObject.ClassName);
  end;
end;

function BuildTSubObject(const AClassName : string) : TObject;
begin
  Result := TSubObject.Create;
end;

procedure
    TestTMongoBsonSerializer.TestSerializeObjectDeserializeWithDynamicBuilding_FailTypeNotFound;
var
  AObj : TTestObject;
begin
  AObj := TTestObject.Create;
  try
    AObj.The_00_Int := 123;
    FSerializer.Target := NewBsonBuffer();
    FSerializer.Serialize('', AObj);
  finally
    AObj.Free;
  end;
  AObj := nil;
  FDeserializer.Source := FSerializer.Target.finish.iterator;
  try
    FDeserializer.Deserialize(TObject(AObj));
    Fail('Should have raised exception that it cound not find suitable builder for class TTestObject');
  except
    on E : Exception do CheckEqualsString('Suitable builder not found for class <TTestObject>', E.Message);
  end;
end;

procedure TestTMongoBsonSerializer.TestSerializeObjectDeserializeWithDynamicBuildingOfObjProp;
var
  AObj : TTestObject;
begin
  AObj := TTestObject.Create;
  try
    FSerializer.Target := NewBsonBuffer();
    AObj.The_08_SubObject.TheInt := 123;
    FSerializer.Serialize('', AObj);
  finally
    AObj.Free;
  end;
  AObj := nil;
  AObj := TTestObject.Create;
  try
    AObj.The_08_SubObject.Free;
    AObj.The_08_SubObject := nil;
    FDeserializer.Source := FSerializer.Target.finish.iterator;
    RegisterBuildableSerializableClass(TSubObject.ClassName, BuildTSubObject);
    try
      FDeserializer.Deserialize(TObject(AObj));
      Check(AObj.The_08_SubObject <> nil, 'AObj.The_08_SubObject must be <> nil after deserialization');
      CheckEquals(123, AObj.The_08_SubObject.TheInt, 'The_00_Int attribute should be equals to 123');
    finally
      UnregisterBuildableSerializableClass(TSubObject.ClassName);
    end;
  finally
    AObj.Free;
  end;
end;

procedure TestTMongoBsonSerializer.TestSerializePrimitiveTypes;
const
  SomeData : PAnsiChar = '1234567890qwertyuiop';
  Buf      : PAnsiChar = '                    ';
var
  it, SubIt, SubSubIt : IBsonIterator;
  Obj : TTestObject;
  Obj2 : TTestObject;
  v : Variant;
  b : IBson;
  bin : IBsonBinary;
  dynIntArr : TDynIntArr;
  dynIntArrArr : TDynIntArrArr;
  I : Integer;
begin
  FSerializer.Target := NewBsonBuffer();
  Obj := TTestObject.Create;
  try
    Obj.The_00_Int := 10;
    Obj.The_01_Int64 := 11;
    Obj.The_02_AnsiChar := 'B';
    Obj.The_03_Enumeration := eSecond;
    Obj.The_04_Float := 1.5;
    {$IFDEF DELPHIXE}
    Obj.The_05_String := 'дом';
    {$ELSE}
    Obj.The_05_String := 'home';
    {$ENDIF}
    Obj.The_06_ShortString := 'Hello';
    Obj.The_07_Set := [eFirst, eSecond];
    Obj.The_08_SubObject.TheInt := 12;
    Obj.The_10_WChar := 'д';
    SetLength(dynIntArr, 2);
    dynIntArr[0] := 1;
    dynIntArr[1] := 2;
    Obj.The_09_DynIntArr := dynIntArr;
    Obj.The_11_AnsiString := 'Hello World';
    Obj.The_12_WideString := 'дом дом';
    {$IFDEF DELPHIXE}
    Obj.The_13_StringList.Add('дом');
    Obj.The_13_StringList.Add('ом');
    {$ELSE}
    Obj.The_13_StringList.Add('home');
    Obj.The_13_StringList.Add('ome');
    {$ENDIF}
    Obj.The_14_VariantAsInteger := 14;
    {$IFDEF DELPHIXE}
    Obj.The_15_VariantAsString := 'дом дом дом';
    {$ELSE}
    Obj.The_15_VariantAsString := 'alo';
    {$ENDIF}
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
    Obj.The_18_VariantAsArrayEmpty := Null;
    Obj.The_19_Boolean := True;
    Obj.The_20_DateTime := Now;
    Obj.The_21_MemStream.Write(SomeData^, length(SomeData));
    SetLength(dynIntArrArr, 2);
    for I := 0 to Length(dynIntArrArr) - 1 do
      SetLength(dynIntArrArr[I], 2);
    dynIntArrArr[0, 0] := 1;
    dynIntArrArr[0, 1] := 2;
    dynIntArrArr[1, 0] := 3;
    dynIntArrArr[1, 1] := 4;
    Obj.The_24_DynIntArrArr := dynIntArrArr;

    FSerializer.Serialize('', Obj);

    b := FSerializer.Target.finish;
    it := NewBsonIterator(b);
    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('_type', it.key);
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
    {$IFDEF DELPHIXE}
    CheckEqualsString('дом', it.Value, 'Iterator should be equals to "дом"');
    {$ELSE}
    CheckEqualsString('home', it.Value, 'Iterator should be equals to "home"');
    {$ENDIF}

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
    CheckTrue(Subit.Next, 'SubIterator should not be at end');
    CheckEqualsString('_type', Subit.key);
    CheckTrue(SubIt.Next, 'SubIterator should not be at end');
    CheckEquals(12, SubIt.Value, 'Iterator should be equals to 12');
    Check(not SubIt.next, 'Iterator should be at end');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_09_DynIntArr', it.key);
    Check(it.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(1, SubIt.Value, 'Iterator should be equals to 1');
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(2, SubIt.Value, 'Iterator should be equals to 2');
    Check(not SubIt.next, 'Iterator should be at end');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_10_WChar', it.key);
    CheckEqualsWideString('д', UTF8Decode(it.AsUTF8String), 'Iterator does''t match');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_11_AnsiString', it.key);
    CheckEqualsString('Hello World', it.Value, 'Iterator should be equals to "Hello World"');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_12_WideString', it.key);
    CheckEqualsWideString('дом дом', UTF8Decode(it.AsUTF8String), 'Iterator doesn''t match');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_13_StringList', it.key);
    Check(it.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    {$IFDEF DELPHIXE}
    CheckEqualsString('дом', SubIt.AsUTF8String, 'Iterator should be equals to "дом"');
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEqualsString('ом', SubIt.Value, 'Iterator should be equals to "ом"');
    {$ELSE}
    CheckEqualsString('home', SubIt.Value, 'Iterator should be equals to "home"');
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEqualsString('ome', SubIt.Value, 'Iterator should be equals to "ome"');
    {$ENDIF}
    Check(not SubIt.next, 'Iterator should be at end');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_14_VariantAsInteger', it.key);
    CheckEquals(14, it.value, 'Iterator should be equals to 14');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_15_VariantAsString', it.key);
    {$IFDEF DELPHIXE}
    CheckEqualsWideString('дом дом дом', UTF8Decode(it.AsUTF8String), 'Iterator doesn''t match');
    {$ELSE}
    CheckEqualsWideString('alo', UTF8Decode(it.AsUTF8String), 'Iterator doesn''t match');
    {$ENDIF}

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_16_VariantAsArray', it.key);
    Check(it.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(16, SubIt.Value, 'Iterator should be equals to 16');
    CheckTrue(SubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(22, SubIt.Value, 'Iterator should be equals to 22');
    Check(not SubIt.next, 'Iterator should be at end');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_17_VariantTwoDimArray', it.key);
    Check(it.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Iterator should not be at end');
    Check(SubIt.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubSubIt := SubIt.subiterator;
    CheckTrue(SubSubIt.Next, 'Iterator should not be at end');
    Check(SubSubIt.Kind = bsonINT, 'Type of iterator value should be bsonARRAY');
    CheckEquals(16, SubSubIt.Value, 'Iterator should be equals to 16');
    CheckTrue(SubSubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(22, SubSubIt.Value, 'Iterator should be equals to 22');
    SubIt.next;
    SubSubIt := SubIt.subiterator;
    CheckTrue(SubSubIt.Next, 'Iterator should not be at end');
    Check(SubSubIt.Kind = bsonINT, 'Type of iterator value should be bsonARRAY');
    CheckEquals(33, SubSubIt.Value, 'Iterator should be equals to 16');
    CheckTrue(SubSubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(44, SubSubIt.Value, 'Iterator should be equals to 22');

    Check(it.next, 'Iterator should not be at end');
    Check(VarIsNull(it.value), 'expected null value');

    Check(it.next, 'Iterator should not be at end');
    Check(it.value, 'expected true');

    Check(it.next, 'Iterator should not be at end');
    CheckEquals(Obj.The_20_DateTime, it.value, 0.1, 'expected date to match');

    Check(it.next, 'Iterator should not be at end');
    Check(it.Kind = bsonBINDATA, 'expecting binary bson');
    bin := it.getBinary;
    CheckEquals(length(SomeData), bin.Len, 'binary data expected');
    Check(CompareMem(SomeData, bin.Data, bin.len), 'memory doesn''t match');

    Check(it.next, 'Iterator should not be at end');
    Check(it.Kind = bsonBINDATA, 'expecting binary bson');
    bin := it.getBinary;
    CheckEquals(0, bin.Len, 'blank binary data expected');

    Check(it.next, 'Iterator should not be at end');
    Check(it.Kind = bsonARRAY, 'expecting binary bson');

    CheckTrue(it.Next, 'Iterator should not be at end');
    CheckEqualsString('The_24_DynIntArrArr', it.key);
    Check(it.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubIt := it.subiterator;
    CheckTrue(SubIt.Next, 'Iterator should not be at end');
    Check(SubIt.Kind = bsonARRAY, 'Type of iterator value should be bsonARRAY');
    SubSubIt := SubIt.subiterator;
    CheckTrue(SubSubIt.Next, 'Iterator should not be at end');
    Check(SubSubIt.Kind = bsonINT, 'Type of iterator value should be bsonARRAY');
    CheckEquals(1, SubSubIt.Value, 'Iterator should be equals to 16');
    CheckTrue(SubSubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(2, SubSubIt.Value, 'Iterator should be equals to 22');
    SubIt.next;
    SubSubIt := SubIt.subiterator;
    CheckTrue(SubSubIt.Next, 'Iterator should not be at end');
    Check(SubSubIt.Kind = bsonINT, 'Type of iterator value should be bsonARRAY');
    CheckEquals(3, SubSubIt.Value, 'Iterator should be equals to 16');
    CheckTrue(SubSubIt.Next, 'Array SubIterator should not be at end');
    CheckEquals(4, SubSubIt.Value, 'Iterator should be equals to 22');

    CheckTrue(it.Next, 'Array SubIterator should not be at end');
    CheckEquals(0, it.Value, 'Iterator should be equals to 0'); // property _a

    Check(not it.next, 'Iterator should be at end');

    Obj2 := TTestObject.Create;
    Obj2.The_17_VariantTwoDimArray := VarArrayCreate([0, 1, 0, 1], varInteger);
    SetLength(dynIntArrArr, 2);
    for I := 0 to Length(dynIntArrArr) - 1 do
      SetLength(dynIntArrArr[I], 2);
    obj2.The_24_DynIntArrArr := dynIntArrArr;
    try
      obj2.The_23_EmptySet := [eFirst];
      FDeserializer.Source := NewBsonIterator(b);
      FDeserializer.Deserialize(TObject(Obj2));

      CheckEquals(10, obj2.The_00_Int, 'Value of The_00_Int doesn''t match');
      CheckEquals(11, obj2.The_01_Int64, 'Value of The_01_Int64 doesn''t match');
      CheckEquals(integer(eSecond), integer(obj2.The_03_Enumeration), 'Value of The_03_Enumeration doesn''t match');
      CheckEquals(1.5, obj2.The_04_Float, 'Value of The_04_Float doesn''t match');
      {$IFDEF DELPHIXE}
      CheckEqualsString('дом', obj2.The_05_String, 'The_05_String should be equals to "дом"');
      {$ELSE}
      CheckEqualsString('home', obj2.The_05_String, 'The_05_String should be equals to "home"');
      {$ENDIF}
      CheckEqualsString('Hello', obj2.The_06_ShortString, 'The_06_ShortString should be equals to "Hello"');
      Check(obj2.The_07_Set = [eFirst, eSecond], 'obj2.The_07_Set = [eFirst, eSecond]');

      CheckEquals(12, Obj2.The_08_SubObject.TheInt, 'Obj.The_08_SubObject.TheInt should be 12');

      CheckEquals(2, Length(Obj2.The_09_DynIntArr), 'Obj2.The_09_DynIntArr Length should = 2');
      CheckEquals(1, Obj2.The_09_DynIntArr[0], 'Value of The_09_DynIntArr[0] doesn''t match');
      CheckEquals(2, Obj2.The_09_DynIntArr[1], 'Value of The_09_DynIntArr[1] doesn''t match');

      CheckEqualsString('Hello World', Obj2.The_11_AnsiString, 'Obj2.The_11_AnsiString doesn''t match value');

      {$IFDEF DELPHIXE}
      CheckEqualsString('дом', Obj2.The_13_StringList[0]);
      CheckEqualsString('ом', Obj.The_13_StringList[1]);
      {$ELSE}
      CheckEqualsString('home', Obj2.The_13_StringList[0]);
      CheckEqualsString('ome', Obj.The_13_StringList[1]);
      {$ENDIF}

      CheckEqualsWideString('д', Obj2.The_10_WChar, 'Obj2.The_10_WChar doesn''t match');

      CheckEquals(14, Obj2.The_14_VariantAsInteger, 'Obj2.The_14_VariantAsInteger doesn''t match value');

      {$IFDEF DELPHIXE}
      CheckEqualsString('дом дом дом', Obj2.The_15_VariantAsString, 'Obj2.The_15_VariantAsString doesn''t match expected value');
      {$ELSE}
      CheckEqualsWideString('alo', UTF8Decode(Obj2.The_15_VariantAsString), 'Iterator doesn''t match');
      {$ENDIF}

      CheckEquals(0, VarArrayLowBound(Obj2.The_16_VariantAsArray, 1), 'Obj2.The_16_VariantAsArray low bound equals 0');
      CheckEquals(1, VarArrayHighBound(Obj2.The_16_VariantAsArray, 1), 'Obj2.The_16_VariantAsArray high bound equals 1');
      CheckEquals(16, Obj2.The_16_VariantAsArray[0], 'Value of The_16_VariantAsArray[0] doesn''t match');
      CheckEquals(22, Obj2.The_16_VariantAsArray[1], 'Value of The_16_VariantAsArray[1] doesn''t match');

      CheckEquals(16, Obj2.The_17_VariantTwoDimArray[0, 0], 'Value of The_17_VariantTwoDimArray[0, 0] doesn''t match');
      CheckEquals(22, Obj2.The_17_VariantTwoDimArray[0, 1], 'Value of The_17_VariantTwoDimArray[0, 1] doesn''t match');
      CheckEquals(33, Obj2.The_17_VariantTwoDimArray[1, 0], 'Value of The_17_VariantTwoDimArray[1, 0] doesn''t match');
      CheckEquals(44, Obj2.The_17_VariantTwoDimArray[1, 1], 'Value of The_17_VariantTwoDimArray[1, 1] doesn''t match');

      Check(Obj2.The_19_Boolean, 'Obj2.The_19_Boolean should be true');

      CheckEquals(obj.The_20_DateTime, obj2.The_20_DateTime, 0.1, 'obj.The_20_DateTime = obj2.The_20_DateTime');

      Check(obj2.The_23_EmptySet = [], 'The_23_EmptySet should be empty');

      CheckEquals(length(SomeData), obj2.The_21_MemStream.Size, 'data size doesn''t match');
      Check(CompareMem(SomeData, obj2.The_21_MemStream.Memory, obj2.The_21_MemStream.Size), 'memory doesn''t match');

      CheckEquals(1, Obj2.The_24_DynIntArrArr[0, 0], 'Value of The_24_DynIntArrArr[0, 0] doesn''t match');
      CheckEquals(2, Obj2.The_24_DynIntArrArr[0, 1], 'Value of The_24_DynIntArrArr[0, 1] doesn''t match');
      CheckEquals(3, Obj2.The_24_DynIntArrArr[1, 0], 'Value of The_24_DynIntArrArr[1, 0] doesn''t match');
      CheckEquals(4, Obj2.The_24_DynIntArrArr[1, 1], 'Value of The_24_DynIntArrArr[1, 1] doesn''t match');
    finally
      Obj2.Free;
    end;
  finally
    Obj.Free;
  end;
end;

constructor TTestObjectWithObjectAsStringList.Create;
begin
  inherited Create;
  FObjectAsStringList := TObjectAsStringList.Create;
end;

destructor TTestObjectWithObjectAsStringList.Destroy;
begin
  FreeAndNil(FObjectAsStringList);
  inherited Destroy;
end;

procedure TTestObjectWithObjectAsStringList.SetObjectAsStringList(const Value: TObjectAsStringList);
begin
  FObjectAsStringList.Assign(Value);
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TestTMongoBsonSerializer.Suite);
end.

