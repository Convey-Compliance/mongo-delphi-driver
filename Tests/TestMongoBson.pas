unit TestMongoBson;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit 
  being tested.

}

interface

uses
  SysUtils, TestFramework, MongoBson;

type
  // Test methods for class IBsonOID
  
  TestIBsonOID = class(TTestCase)
  private
    FIBsonOID: IBsonOID;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSetValueAndGetValue;
    procedure TestAsString;
  end;
  // Test methods for class IBsonCodeWScope
  
  TestIBsonCodeWScope = class(TTestCase)
  private
    FIBsonCodeWScope: IBsonCodeWScope;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestsetAndGetCode;
    procedure TestsetAndGetScope;
  end;
  // Test methods for class IBsonRegex
  
  TestIBsonRegex = class(TTestCase)
  private
    FIBsonRegex: IBsonRegex;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestgetAndsetPattern;
    procedure TestgetAndsetOptions;
  end;
  // Test methods for class IBsonTimestamp
  
  TestIBsonTimestamp = class(TTestCase)
  private
    FIBsonTimestamp: IBsonTimestamp;
  private
    ANow: TDateTime;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestsetAndGetTime;
    procedure TestsetAndGetIncrement;
  end;
  // Test methods for class IBsonBinary
  
  TestIBsonBinary = class(TTestCase)
  private
    FIBsonBinary: IBsonBinary;
  private
    FData: array [0..255] of byte;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestgetLen;
    procedure TestsetAndGetData;
    procedure TestgetKindAndsetKind;
  end;
  // Test methods for class IBsonBuffer
  
  TestIBsonBuffer = class(TTestCase)
  private
    FIBsonBuffer: IBsonBuffer;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAppendStr;
    procedure TestAppendInteger;
    procedure TestAppendInt64;
    procedure TestAppendDouble;
    procedure TestappendDate;
    procedure TestAppendRegEx;
    procedure TestAppendTimeStamp;
    procedure TestAppendBsonBinary;
    procedure TestAppendIBson;
    procedure TestAppendVariantOverloaded;
    procedure TestAppendVariant;
    procedure TestappendIntegerArray;
    procedure TestappendDoubleArray;
    procedure TestappendBooleanArray;
    procedure TestappendStringArray;
    procedure TestappendNull;
    procedure TestappendUndefined;
    procedure TestappendCode;
    procedure TestappendSymbol;
    procedure TestappendBinary;
    procedure TestappendCode_n;
    procedure TestAppendStr_n;
    procedure TestappendSymbol_n;
    procedure TeststartObject;
    procedure TeststartArray;
    procedure Testsize;
  end;
  // Test methods for class IBsonIterator
  
  TestIBsonIterator = class(TTestCase)
  private
    FIBsonIterator: IBsonIterator;
    b: IBson;
    bb: IBson;
    BoolArr: TBooleanArray;
    BsonOID: IBsonOID;
    BsonRegEx: IBsonRegex;
    DblArr: TDoubleArray;
    FTimestamp: IBsonTimestamp;
    IntArr: TIntegerArray;
    StrArr: TStringArray;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGetAsInt64;
    procedure TestgetHandle;
    procedure TestgetBinary;
    procedure TestgetBooleanArray;
    procedure TestgetCodeWScope;
    procedure TestgetDoubleArray;
    procedure TestgetIntegerArray;
    procedure TestgetOID;
    procedure TestgetRegex;
    procedure TestgetStringArray;
    procedure TestgetTimestamp;
    procedure Testkey;
    procedure TestKind;
    procedure Testsubiterator;
    procedure TestValue;
  end;
  // Test methods for class IBson
  
  TestIBson = class(TTestCase)
  private
    FIBson: IBson;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Testfind;
    procedure TestgetHandle;
    procedure Testiterator;
    procedure Testsize;
    procedure TestValue;
  end;

  TestBsonAPI = class(TTestCase)
  public
  published
    procedure Test_bson_set_oid_inc;
    procedure Test_bson_set_oid_fuzz;

  end;

implementation

uses
  Classes, Variants, MongoAPI;

const
  DELTA_DATE = 0.00009999;
  
procedure TestIBsonOID.SetUp;
begin
  FIBsonOID := NewBsonOID;
end;

procedure TestIBsonOID.TearDown;
begin
  FIBsonOID := nil;
  inherited;
end;

procedure TestIBsonOID.TestSetValueAndGetValue;
var
  AValue: TBsonOIDValue;
  i : integer;
begin
  for i := 0 to sizeof(AValue) - 1 do
    AValue[i] := i;
  FIBsonOID.setValue(AValue);
  for I := 0 to sizeof(AValue) - 1 do
    CheckEquals(i, FIBsonOID.getValue[i], 'All values of BSONID should be zero');
end;

procedure TestIBsonOID.TestAsString;
var
  ReturnValue: AnsiString;
  Val64 : Int64;
begin
  ReturnValue := FIBsonOID.AsString;
  HexToBin(PAnsiChar(ReturnValue), PAnsiChar(@Val64), sizeof(Val64));
  CheckNotEqualsString('', ReturnValue, 'Call to FIBsonOID should return value <> from ""');
end;

{ TestIBsonCodeWScope }

procedure TestIBsonCodeWScope.SetUp;
var
  NilBson : IBson;
begin
  NilBson := nil;
  FIBsonCodeWScope := NewBsonCodeWScope('', NilBson);
end;

procedure TestIBsonCodeWScope.TearDown;
begin
  FIBsonCodeWScope := nil;
  inherited;
end;

procedure TestIBsonCodeWScope.TestsetAndGetCode;
var
  ACode: AnsiString;
begin
  ACode := '123';
  FIBsonCodeWScope.setCode(ACode);
  CheckEqualsString('123', FIBsonCodeWScope.getCode, 'Call to FIBsonCodeWScope.GetCode should be equals to "123"');
end;

procedure TestIBsonCodeWScope.TestsetAndGetScope;
var
  AScope: IBson;
begin
  AScope := BSON(['ID', 1]);
  FIBsonCodeWScope.setScope(AScope);
  Check(AScope = FIBsonCodeWScope.getScope, 'Call to FIBsonCodeWScope.getScope should return value equals to AScope');
end;

{ TestIBsonRegex }

procedure TestIBsonRegex.SetUp;
begin
  FIBsonRegex := NewBsonRegex('123', '456');
end;

procedure TestIBsonRegex.TearDown;
begin
  FIBsonRegex := nil;
  inherited;
end;

procedure TestIBsonRegex.TestgetAndsetPattern;
var
  APattern: AnsiString;
begin
  CheckEqualsString('123', FIBsonRegex.getPattern, 'getPattern should return 123');
  APattern := '098';
  FIBsonRegex.setPattern(APattern);
  CheckEqualsString('098', FIBsonRegex.getPattern, 'call to getPattern after setting new value should return "098"');
end;

procedure TestIBsonRegex.TestgetAndsetOptions;
var
  AOptions: AnsiString;
begin
  CheckEqualsString('456', FIBsonRegex.getOptions, 'getOptions call should return "456"');
  AOptions := '789';
  FIBsonRegex.setOptions(AOptions);
  CheckEqualsString('789', FIBsonRegex.getOptions, 'Call to getOptions after setting options should return "789"');
end;

{ TestIBsonTimestamp }

procedure TestIBsonTimestamp.SetUp;
begin
  ANow := Now;
  FIBsonTimestamp := NewBsonTimestamp(ANow, 1);
end;

procedure TestIBsonTimestamp.TearDown;
begin
  FIBsonTimestamp := nil;
  inherited;
end;

procedure TestIBsonTimestamp.TestsetAndGetTime;
var
  ATime: TDateTime;
begin
  CheckEquals(ANow, FIBsonTimestamp.getTime, 'getTime should be equals to value set to ANow');
  ATime := 1.0;
  FIBsonTimestamp.setTime(ATime);
  CheckEquals(ATime, FIBsonTimestamp.getTime, 'getTime should return 1.0 after setting the value');
end;

procedure TestIBsonTimestamp.TestsetAndGetIncrement;
var
  AIncrement: Integer;
begin
  CheckEquals(1, FIBsonTimestamp.getIncrement, 'Initial value of increment should be equals to 1');
  AIncrement := 2;
  FIBsonTimestamp.setIncrement(AIncrement);
  CheckEquals(AIncrement, FIBsonTimestamp.getIncrement, 'New value of Increment should be equals to 2'); 
end;

{ TestIBsonBinary }

procedure TestIBsonBinary.SetUp;
var
  i : integer;
begin
  for I := low(FData) to high(FData) do
    FData[i] := i;
  FIBsonBinary := NewBsonBinary(@FData, sizeof(FData));
end;

procedure TestIBsonBinary.TearDown;
begin
  FIBsonBinary := nil;
  inherited;
end;

procedure TestIBsonBinary.TestgetLen;
var
  ReturnValue: Integer;
begin
  ReturnValue := FIBsonBinary.getLen;
  CheckEquals(sizeof(FData), ReturnValue, 'getLen should return sizeof(FData) local field');
end;

procedure TestIBsonBinary.TestsetAndGetData;
type
  PByteArray = ^TByteArray;
  TByteArray = array[0..255] of Byte;
var
  AData: Pointer;
  i : integer;
  ANewData : array[0..255] of Byte;
begin
  AData := FIBsonBinary.getData;
  for I := low(FData) to high(FData) do
    CheckEquals(i, PByteArray(AData)[i], 'Cached binary data on IBsonBinary doesn''t match with expected value');
  for I := low(ANewData) to high(ANewData) do
    ANewData[i] := sizeof(ANewData) - i;
  FIBsonBinary.setData(@ANewData, sizeof(ANewData));
  AData := FIBsonBinary.getData;
  for I := low(ANewData) to high(ANewData) do
    CheckEquals(byte(sizeof(ANewData) - i), PByteArray(AData)[i], 'Cached binary data on IBsonBinary doesn''t match with expected value');
end;

procedure TestIBsonBinary.TestgetKindAndsetKind;
var
  AKind: Integer;
begin
  CheckEquals(0, FIBsonBinary.getKind, 'Initial value of Kind should be zero');
  AKind := 1;
  FIBsonBinary.setKind(AKind);
  CheckEquals(1, FIBsonBinary.getKind, 'Value of Kind should be one');
end;

{ TestIBsonBuffer }

procedure TestIBsonBuffer.SetUp;
begin
  FIBsonBuffer := NewBsonBuffer;
end;

procedure TestIBsonBuffer.TearDown;
begin
  FIBsonBuffer := nil;
  inherited;
end;

procedure TestIBsonBuffer.TestAppendStr;
var
  ReturnValue: Boolean;
  Value: PAnsiChar;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('STRFLD');
  Value := PAnsiChar('STRVAL');
  ReturnValue := FIBsonBuffer.AppendStr(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEqualsString('STRVAL', b.Value(PAnsiChar('STRFLD')), 'field on BSon object doesn''t match expected value');
end;

procedure TestIBsonBuffer.TestAppendInteger;
var
  ReturnValue: Boolean;
  Value: Integer;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('INTFLD');
  Value := 100;
  ReturnValue := FIBsonBuffer.Append(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEquals(100, b.Value(PAnsiChar('INTFLD')), 'field on BSon object doesn''t match expected value');
end;

procedure TestIBsonBuffer.TestAppendInt64;
var
  ReturnValue: Boolean;
  Value: Int64;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('INT64FLD');
  Value := Int64(MaxInt) * 10;
  ReturnValue := FIBsonBuffer.Append(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEquals(Int64(MaxInt) * 10, b.ValueAsInt64(PAnsiChar('INT64FLD')), 'field on BSon object doesn''t match expected value');
end;

procedure TestIBsonBuffer.TestAppendDouble;
var
  ReturnValue: Boolean;
  Value: Double;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('DBLFLD');
  Value := 100.5;
  ReturnValue := FIBsonBuffer.Append(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEquals(100.5, b.Value(PAnsiChar('DBLFLD')), 'field on BSon object doesn''t match expected value');
end;

procedure TestIBsonBuffer.TestappendDate;
var
  ReturnValue: Boolean;
  Value: TDateTime;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('DATEFLD');
  Value := Now;
  ReturnValue := FIBsonBuffer.appendDate(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEquals(Value, b.Value(PAnsiChar('DATEFLD')), DELTA_DATE, 'field on BSon object doesn''t match expected value');
end;

procedure TestIBsonBuffer.TestAppendRegEx;
var
  ReturnValue: Boolean;
  Value: IBsonRegex;
  Name: PAnsiChar;
  b : IBson;
  i : IBsonIterator;
begin
  Name := PAnsiChar('REGEXFLD');
  Value := NewBsonRegex('123', '456');
  ReturnValue := FIBsonBuffer.Append(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  i := b.find(Name);
  Check(i <> nil, 'Iterator should be <> nil');
  CheckEqualsString('123', i.getRegex.getPattern, 'Pattern should be equals to "123"');
  CheckEqualsString('456', i.getRegex.getOptions, 'Pattern should be equals to "456"');
end;

procedure TestIBsonBuffer.TestAppendTimeStamp;
var
  ReturnValue: Boolean;
  Value: IBsonTimestamp;
  Name: PAnsiChar;
  b : IBson;
  i : IBsonIterator;
begin
  Name := PAnsiChar('TSFLD');
  Value := NewBsonTimestamp(Now, 1);
  ReturnValue := FIBsonBuffer.Append(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  i := b.find(Name);
  Check(i <> nil, 'Iterator should be <> nil');
  CheckEquals(Value.getTime, i.getTimestamp.getTime, DELTA_DATE, 'Time should be equals to Value.getTime');
  CheckEquals(Value.getIncrement, i.getTimestamp.getIncrement, DELTA_DATE, 'Increment should be equals to Value.getIncrement');
end;

procedure TestIBsonBuffer.TestAppendBsonBinary;
type
  PData = ^TData;
  TData = array [0..255] of Byte;
var
  ReturnValue: Boolean;
  Value: IBsonBinary;
  Name: PAnsiChar;
  b : IBson;
  i : IBsonIterator;
  Data : array [0..255] of Byte;
  ii : integer;
begin
  for ii := 0 to sizeof(Data) - 1 do
    Data[ii] := ii;
  Name := PAnsiChar('BSONBINFLD');
  Value := NewBsonBinary(@Data, sizeof(Data));
  ReturnValue := FIBsonBuffer.Append(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  i := b.find(Name);
  Check(i <> nil, 'Iterator should be <> nil');
  for ii := 0 to i.getBinary.getLen - 1 do
    CheckEquals(Data[ii], PData(i.getBinary.getData)[ii], 'Data from BsonBinary object doesn''t match');
end;

procedure TestIBsonBuffer.TestAppendIBson;
var
  ReturnValue: Boolean;
  Value: IBson;
  Name: PAnsiChar;
  b : IBson;
  i : IBsonIterator;
begin
  Name := PAnsiChar('BSFLD');
  Value := BSON(['ID', 1]);
  ReturnValue := FIBsonBuffer.Append(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  i := b.find(Name);
  Check(i <> nil, 'Iterator should be <> nil');
  CheckEquals(1, i.subiterator.Value, 'Value doesn''t match');
end;

procedure TestIBsonBuffer.TestAppendVariantOverloaded;
var
  ReturnValue: Boolean;
  Value: Variant;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('VARIANTFLD');
  Value := 123;
  ReturnValue := FIBsonBuffer.AppendVariant(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEquals(Value, integer(b.Value(Name)), 'Value doesn''t match');
end;

procedure TestIBsonBuffer.TestAppendVariant;
var
  ReturnValue: Boolean;
  Value: Variant;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('VARIANTFLD');
  Value := 123;
  ReturnValue := FIBsonBuffer.AppendVariant(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEquals(Value, integer(b.Value(Name)), 'Value doesn''t match');
end;

procedure TestIBsonBuffer.TestappendIntegerArray;
var
  ReturnValue: Boolean;
  Value: TIntegerArray;
  Name: PAnsiChar;
  i : integer;
  it : IBsonIterator;
  b : IBson;
begin
  Name := PAnsiChar('INTARRFLD');
  SetLength(Value, 10);
  for I := low(Value) to high(Value) do
    Value[i] := i;
  ReturnValue := FIBsonBuffer.appendArray(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  it := b.iterator;
  it.Next;
  CheckEquals(length(Value), length(it.getIntegerArray), 'Array sizes don''t match');
  for I := low(it.getIntegerArray) to high(it.getIntegerArray) do
    CheckEquals(Value[i], it.getIntegerArray[i], 'Items on Integer array don''t match');   
end;

procedure TestIBsonBuffer.TestappendDoubleArray;
var
  ReturnValue: Boolean;
  Value: TDoubleArray;
  Name: PAnsiChar;
  i : integer;
  it : IBsonIterator;
  b : IBson;
begin
  Name := PAnsiChar('DBLARRFLD');
  SetLength(Value, 10);
  for I := low(Value) to high(Value) do
    Value[i] := i + 0.2;
  ReturnValue := FIBsonBuffer.appendArray(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  it := b.iterator;
  it.Next;
  CheckEquals(length(Value), length(it.getDoubleArray), 'Array sizes don''t match');
  for I := low(it.getDoubleArray) to high(it.getDoubleArray) do
    CheckEquals(Value[i], it.getDoubleArray[i], 'Items on Double array don''t match');
end;

procedure TestIBsonBuffer.TestappendBooleanArray;
var
  ReturnValue: Boolean;
  Value: TBooleanArray;
  Name: PAnsiChar;
  i : integer;
  it : IBsonIterator;
  b : IBson;
  BoolArrayResult : TBooleanArray;
begin
  Name := PAnsiChar('BOOLARRFLD');
  SetLength(Value, 10);
  for I := low(Value) to high(Value) do
    Value[i] := i mod 2 = 1;
  ReturnValue := FIBsonBuffer.appendArray(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  it := b.iterator;
  it.Next;
  BoolArrayResult := it.getBooleanArray;
  CheckEquals(length(Value), length(BoolArrayResult), 'Array sizes don''t match');
  for I := low(BoolArrayResult) to high(BoolArrayResult) do
    CheckEquals(Value[i], BoolArrayResult[i], 'Items on Boolean array don''t match');
end;

procedure TestIBsonBuffer.TestappendStringArray;
var
  ReturnValue: Boolean;
  Value: TStringArray;
  Name: PAnsiChar;
  i : integer;
  it : IBsonIterator;
  b : IBson;
begin
  Name := PAnsiChar('BOOLARRFLD');
  SetLength(Value, 10);
  for I := low(Value) to high(Value) do
    Value[i] := IntToStr(i);
  ReturnValue := FIBsonBuffer.appendArray(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  it := b.iterator;
  it.Next;
  CheckEquals(length(Value), length(it.getStringArray), 'Array sizes don''t match');
  for I := low(it.getStringArray) to high(it.getStringArray) do
    CheckEqualsString(Value[i], it.getStringArray[i], 'Items on AnsiString array don''t match');
end;

procedure TestIBsonBuffer.TestappendNull;
var
  ReturnValue: Boolean;
  Name: PAnsiChar;
  v : Variant;
  b : IBson;
begin
  Name := PAnsiChar('NULLFLD');
  ReturnValue := FIBsonBuffer.appendNull(Name);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  v := b.Value(Name);
  Check(VarIsNull(v), 'Field should be NULL');
end;

procedure TestIBsonBuffer.TestappendUndefined;
var
  ReturnValue: Boolean;
  Name: PAnsiChar;
  v : Variant;
  b : IBson;
begin
  Name := PAnsiChar('EMPTYFLD');
  ReturnValue := FIBsonBuffer.appendUndefined(Name);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  v := b.Value(Name);
  Check(VarIsEmpty(v), 'Field should be EMPTY');
end;

procedure TestIBsonBuffer.TestappendCode;
var
  ReturnValue: Boolean;
  Value: PAnsiChar;
  Name: PAnsiChar;
  b : IBson;
  i : IBsonIterator;
begin
  Name := PAnsiChar('CODEFLD');
  Value := PAnsiChar('123456');
  ReturnValue := FIBsonBuffer.appendCode(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  i := b.iterator;
  CheckEqualsString(Value, i.getCodeWScope.getCode, 'Code should be equals to "123456"');
end;

procedure TestIBsonBuffer.TestappendSymbol;
var
  ReturnValue: Boolean;
  Value: PAnsiChar;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('CODEFLD');
  Value := PAnsiChar('SymbolTest');
  ReturnValue := FIBsonBuffer.appendSymbol(Name, Value);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEqualsString(Value, b.Value(Name), 'Symbol value doesn''t match');
end;

procedure TestIBsonBuffer.TestappendBinary;
type
  PData = ^TData;
  TData = array [0..15] of Byte;
const
  AData : TData = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
var
  ReturnValue: Boolean;
  Length: Integer;
  Data: Pointer;
  Kind: Integer;
  Name: PAnsiChar;
  b : IBson;
  i : integer;
  it : IBsonIterator;
begin
  Name := PAnsiChar('BINFLD');
  Length := sizeof(AData);
  Data := @AData;
  Kind := 0;
  ReturnValue := FIBsonBuffer.appendBinary(Name, Kind, Data, Length);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  it := b.iterator;
  for i := low(AData) to high(AData) do
    CheckEquals(AData[i], PData(it.getBinary.getData)^[i], 'Binary data doesn''t match');
end;

procedure TestIBsonBuffer.TestappendCode_n;
var
  ReturnValue: Boolean;
  Value: PAnsiChar;
  Name: PAnsiChar;
  b : IBson;
  i : IBsonIterator;
begin
  Name := PAnsiChar('CODEFLD');
  Value := PAnsiChar('123');
  ReturnValue := FIBsonBuffer.appendCode_n(Name, Value, 3);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  i := b.iterator;
  CheckEqualsString('123', i.getCodeWScope.getCode, 'Code should be equals to "123"');
end;

procedure TestIBsonBuffer.TestAppendStr_n;
var
  ReturnValue: Boolean;
  Value: PAnsiChar;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('STRFLD');
  Value := PAnsiChar('STRVAL');
  ReturnValue := FIBsonBuffer.AppendStr_n(Name, Value, 3);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEqualsString('STR', b.Value(PAnsiChar('STRFLD')), 'field on BSon object doesn''t match expected value');
end;

procedure TestIBsonBuffer.TestappendSymbol_n;
var
  ReturnValue: Boolean;
  Value: PAnsiChar;
  Name: PAnsiChar;
  b : IBson;
begin
  Name := PAnsiChar('SYMFLD');
  Value := PAnsiChar('SymbolTest');
  ReturnValue := FIBsonBuffer.appendSymbol_n(Name, Value, 3);
  Check(ReturnValue, 'ReturnValue should be True');
  b := FIBsonBuffer.finish;
  CheckEqualsString('Sym', b.Value(Name), 'Symbol value doesn''t match');
end;

procedure TestIBsonBuffer.TeststartObject;
var
  ReturnValue: Boolean;
  Name: PAnsiChar;
  b : IBson;
  it : IBsonIterator;
begin
  Name := PAnsiChar('OBJ');
  ReturnValue := FIBsonBuffer.startObject(Name);
  Check(ReturnValue, 'ReturnValue should be True');
  Check(FIBsonBuffer.AppendStr(PAnsiChar('STRFLD'), PAnsiChar('STRVAL')), 'Call to AppendStr should return true');
  Check(FIBsonBuffer.Append(PAnsiChar('INTFLD'), 1), 'Call to Append should return true');
  Check(FIBsonBuffer.finishObject, 'Call to FIBsonBuffer.finishObjects should return true');
  b := FIBsonBuffer.finish;
  it := b.iterator;
  Check(it <> nil, 'Call to subiterator should be  <> nil');
  it.Next;
  it := it.subiterator;
  Check(it <> nil, 'Call to subiterator should be  <> nil');
  it.Next;
  CheckEqualsString('STRVAL', it.Value, 'STRFLD should be equals to STRVAL');
  it.Next;
  CheckEquals(1, it.Value, 'INTFLD should be equals to 1');
end;

procedure TestIBsonBuffer.TeststartArray;
var
  ReturnValue: Boolean;
  Name: PAnsiChar;
  b : IBson;
  it : IBsonIterator;
  Arr : TIntegerArray;
begin
  Name := PAnsiChar('ARR');
  ReturnValue := FIBsonBuffer.startArray(Name);
  Check(ReturnValue, 'ReturnValue should be True');
    Check(FIBsonBuffer.Append(PAnsiChar(AnsiString('0')), 10), 'Call to Append should return True');
    Check(FIBsonBuffer.Append(PAnsiChar(AnsiString('0')), 20), 'Call to Append should return True');
    Check(FIBsonBuffer.Append(PAnsiChar(AnsiString('0')), 30), 'Call to Append should return True');
  FIBsonBuffer.finishObject;
  b := FIBsonBuffer.finish;
  it := b.iterator;
  it.Next;
  Arr := it.getIntegerArray;
  CheckEquals(3, length(Arr), 'Array should contain three elements');
  CheckEquals(10, Arr[0], 'First element of array should be equals to 10');
  CheckEquals(20, Arr[1], 'First element of array should be equals to 20');
  CheckEquals(30, Arr[2], 'First element of array should be equals to 30');
end;

procedure TestIBsonBuffer.Testsize;
var
  InitialSize : Integer;
  ReturnValue: Integer;
begin
  InitialSize := FIBsonBuffer.size;
  CheckNotEquals(0, InitialSize, 'Initial value of Bson buffer should be different from zero');
  FIBsonBuffer.AppendStr(PAnsiChar('STR'), PAnsiChar('VAL'));
  ReturnValue := FIBsonBuffer.size;
  Check(ReturnValue > InitialSize, 'After inserting an element on Bson buffer size should be larger than initial size');
end;

{ TestIBsonIterator }

type
  PBinData = ^TBinData;
  TBinData = array [0..15] of Byte;

const
  ABinData : TBinData = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);

procedure TestIBsonIterator.SetUp;
var
  Buf : IBsonBuffer;
  i : integer;
begin
  Buf := NewBsonBuffer;
  Buf.AppendStr(PAnsiChar('STR'), PAnsiChar('STRVAL'));
  Buf.Append(PAnsiChar('INT'), 1);
  Buf.Append(PAnsiChar('INT64'), Int64(10));
  Buf.appendBinary(PAnsiChar('BIN'), 0, @ABinData, sizeof(ABinData));
  SetLength(BoolArr, 2);
  BoolArr[0] := False;
  BoolArr[1] := True;
  Buf.appendArray(PAnsiChar('BOOLARR'), BoolArr);
  Buf.appendCode(PAnsiChar('CODE'), PAnsiChar('123456'));
  SetLength(DblArr, 5);
  for I := low(DblArr) to high(DblArr) do
    DblArr[i] := i + 0.5;
  Buf.appendArray(PAnsiChar('DBLARR'), DblArr);
  SetLength(IntArr, 5);
  for i := low(IntArr) to high(IntArr) do
    IntArr[i] := i;
  Buf.appendArray(PAnsiChar('INTARR'), IntArr);
  BsonOID := NewBsonOID;
  Buf.Append(PAnsiChar('BSONOID'), BsonOID);
  BsonRegEx := NewBsonRegEx('123', '456');
  Buf.Append(PAnsiChar('BSONREGEX'), BsonRegEx);
  SetLength(StrArr, 5);
  for I := low(StrArr) to high(StrArr) do
    StrArr[i] := IntToStr(i);
  Buf.appendArray(PAnsiChar('STRARR'), StrArr);
  FTimeStamp := NewBsonTimestamp(Now, 0);
  Buf.append(PAnsiChar('TS'), FTimeStamp);
  bb := BSON(['SUBINT', 123]);
  Buf.Append(PAnsiChar('SUBOBJ'), bb);
  b := Buf.finish;
  FIBsonIterator := b.iterator;
  FIBsonIterator.Next;
end;

procedure TestIBsonIterator.TearDown;
begin
  FIBsonIterator := nil;
  b := nil;
  bb := nil;
  BsonOID := nil;
  BsonRegEx := nil;
  FTimestamp := nil;
  inherited;
end;

procedure TestIBsonIterator.TestGetAsInt64;
var
  ReturnValue: Int64;
  i : integer;
begin
  for i := 1 to 2 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.GetAsInt64;
  CheckEquals(10, ReturnValue, 'Call to GetAsInt64 should return 10');
end;

procedure TestIBsonIterator.TestgetHandle;
var
  ReturnValue: Pointer;
begin
  ReturnValue := FIBsonIterator.getHandle;
  CheckNotEquals(0, integer(ReturnValue), 'Call to FIBsonIterator.getHandle should return value <> nil');
end;

procedure TestIBsonIterator.TestgetBinary;
var
  ReturnValue: IBsonBinary;
  i : integer;
begin
  for i := 1 to 3 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getBinary;
  for i := low(ABinData) to high(ABinData) do
    CheckEquals(ABinData[i], PBinData(ReturnValue.getData)^[i], 'Binary data doesn''t match');
end;

procedure TestIBsonIterator.TestgetBooleanArray;
var
  ReturnValue: TBooleanArray;
  i : integer;
begin
  for i := 1 to 4 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getBooleanArray;
  CheckEquals(length(BoolArr), length(ReturnValue), 'Boolean array size doesn''t match');
  CheckEquals(BoolArr[0], ReturnValue[0], 'First element of boolean array doesn''t match');
  CheckEquals(BoolArr[1], ReturnValue[1], 'First element of boolean array doesn''t match');
end;

procedure TestIBsonIterator.TestgetCodeWScope;
var
  ReturnValue: IBsonCodeWScope;
  i : integer;
begin
  for i := 1 to 5 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getCodeWScope;
  Check(ReturnValue <> nil, 'BsonCodeWScope object should be <> nil');
  CheckEqualsString('123456', ReturnValue.getCode, 'Code doesn''t match');
end;

procedure TestIBsonIterator.TestgetDoubleArray;
var
  ReturnValue: TDoubleArray;
  i : integer;
begin
  for i := 1 to 6 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getDoubleArray;
  for i := low(DblArr) to high(DblArr) do
    CheckEquals(DblArr[i], ReturnValue[i], 'Double array element doesn''t match');
end;

procedure TestIBsonIterator.TestgetIntegerArray;
var
  ReturnValue : TIntegerArray;
  i : integer;
begin
  for i := 1 to 7 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getIntegerArray;
  for i := low(IntArr) to high(IntArr) do
    CheckEquals(IntArr[i], ReturnValue[i], 'Integer array element doesn''t match');
end;

procedure TestIBsonIterator.TestgetOID;
var
  ReturnValue: IBsonOID;
  i : integer;
begin
  for i := 1 to 8 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getOID;
  CheckEqualsString(BsonOID.AsString, ReturnValue.AsString, 'BsonOID doesn''t match');
end;

procedure TestIBsonIterator.TestgetRegex;
var
  ReturnValue: IBsonRegex;
  i : integer;
begin
  for i := 1 to 9 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getRegex;
  CheckEqualsString(BsonRegEx.getPattern, ReturnValue.getPattern, 'Pattern of RegEx doesn''t match');
  CheckEqualsString(BsonRegEx.getOptions, ReturnValue.getOptions, 'Options of RegEx doesn''t match');
end;

procedure TestIBsonIterator.TestgetStringArray;
var
  ReturnValue: TStringArray;
  i : integer;
begin
  for i := 1 to 10 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getStringArray;
  for i := low(StrArr) to high(StrArr) do
    CheckEqualsString(StrArr[i], ReturnValue[i], 'AnsiString array element doesn''t match');
end;

procedure TestIBsonIterator.TestgetTimestamp;
var
  ReturnValue: IBsonTimestamp;
  i : integer;
begin
  for i := 1 to 11 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.getTimestamp;
  CheckEquals(FTimeStamp.getTime, ReturnValue.getTime, DELTA_DATE, 'Timestamp date field doesn''t match');
  CheckEquals(FTimeStamp.getIncrement, ReturnValue.getIncrement, 'Timestamp increment field doesn''t match');
end;

procedure TestIBsonIterator.Testkey;
var
  ReturnValue: AnsiString;
  i : integer;
begin
  ReturnValue := FIBsonIterator.key;
  CheckEqualsString('STR', ReturnValue, 'Key of first iterator element should be equals to STR');
  for i := 1 to 11 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.key;    
  CheckEqualsString('TS', ReturnValue, 'Key of last iterator element should be equals to TS');
end;

procedure TestIBsonIterator.TestKind;
var
  ReturnValue: TBsonType;
begin
  ReturnValue := FIBsonIterator.Kind;
  CheckEquals(integer(bsonSTRING), integer(ReturnValue), 'First element returned by iterator should be bsonSTRING');
  FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.Kind;
  CheckEquals(integer(bsonINT), integer(ReturnValue), 'Second element returned by iterator should be bsonINT');
  FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.Kind;
  CheckEquals(integer(bsonLONG), integer(ReturnValue), 'Third element returned by iterator should be bsonLONG');
end;

procedure TestIBsonIterator.Testsubiterator;
var
  ReturnValue: IBsonIterator;
  i : integer;
begin
  for i := 1 to 12 do
    FIBsonIterator.Next;
  ReturnValue := FIBsonIterator.subiterator;
  Check(ReturnValue <> nil, 'FIBsonIterator.subiterator should be different from nil');
  ReturnValue.Next;
  CheckEquals(123, integer(ReturnValue.Value), 'Value of subiterator should be equals to 123');
end;

procedure TestIBsonIterator.TestValue;
var
  ReturnValue: Variant;
begin
  ReturnValue := FIBsonIterator.Value;
  CheckEqualsString('STRVAL', ReturnValue, 'ReturnValue should be equals to STRVAL');
end;

{ TestIBson }

procedure TestIBson.SetUp;
begin
  FIBson := BSON(['ID', 123, 'S', 'STR']);
end;

procedure TestIBson.TearDown;
begin
  FIBson := nil;
  inherited;
end;

procedure TestIBson.Testfind;
var
  ReturnValue: IBsonIterator;
  Name: PAnsiChar;
begin
  Name := PAnsiChar(AnsiString('S'));
  ReturnValue := FIBson.find(Name);
  Check(ReturnValue <> nil, 'Call to FIBson.Find should have returned an iterator');
  CheckEqualsString('STR', ReturnValue.Value, 'Iterator.Value should have returned STR');
end;

procedure TestIBson.TestgetHandle;
var
  ReturnValue: Pointer;
begin
  ReturnValue := FIBson.getHandle;
  Check(ReturnValue <> nil, 'Call to FIBson.getHandle should return value <> nil');
end;

procedure TestIBson.Testiterator;
var
  ReturnValue: IBsonIterator;
begin
  ReturnValue := FIBson.iterator;
  Check(ReturnValue <> nil, 'Call to get Bson iterator should have returned value <> nil');
  ReturnValue.Next;
  CheckEquals(123, ReturnValue.Value, 'Initial value of iterator is 123');
end;

procedure TestIBson.Testsize;
var
  ReturnValue: Integer;
begin
  ReturnValue := FIBson.size;
  CheckNotEquals(0, ReturnValue, 'Call to FIBson.Size should return value <> zero');
end;

procedure TestIBson.TestValue;
var
  ReturnValue: Variant;
  Name: PAnsiChar;
begin
  Name := PAnsiChar('ID');
  ReturnValue := FIBson.Value(Name);
  CheckEquals(123, ReturnValue, 'ReturnValue should be equals to 123');
end;

var
  CustomReturnIntCalled : Boolean;
  CustomOIDFuzz : Boolean;

function CustomOIDReturnIntFunction: Integer; cdecl;
begin
  Result := 0;
  CustomReturnIntCalled := True;
end;

function CustomOIDFuzzFunction: Integer; cdecl;
begin
  Result := 0;
  CustomOIDFuzz := True;
end;

procedure TestBsonAPI.Test_bson_set_oid_inc;
begin
  Check(CustomReturnIntCalled, 'CustomSetOIDIncCalled should be true after creating BsonOID');
end;

procedure TestBsonAPI.Test_bson_set_oid_fuzz;
begin
  Check(CustomOIDFuzz, 'CustomSetOIDIncCalled should be true after creating BsonOID');
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TestIBsonOID.Suite);
  RegisterTest(TestIBsonCodeWScope.Suite);
  RegisterTest(TestIBsonRegex.Suite);
  RegisterTest(TestIBsonTimestamp.Suite);
  RegisterTest(TestIBsonBinary.Suite);
  RegisterTest(TestIBsonBuffer.Suite);
  RegisterTest(TestIBsonIterator.Suite);
  RegisterTest(TestBsonAPI.Suite);
  RegisterTest(TestIBson.Suite);
  {$IFDEF OnDemandMongoCLoad}
  InitMongoDBLibrary;
  {$ENDIF}
  bson_set_oid_fuzz(@CustomOIDFuzzFunction);
  bson_set_oid_inc(@CustomOIDReturnIntFunction);
  try
    NewBsonOID;
  finally
    bson_set_oid_fuzz(nil);
    bson_set_oid_inc(nil);
  end;
end.
