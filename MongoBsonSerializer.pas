unit MongoBsonSerializer;

interface

uses
  MongoBson, SysUtils, TypInfo;

type
  EBsonSerializer = class(Exception);
  TBaseBsonSerializerClass = class of TBaseBsonSerializer;
  TBaseBsonSerializer = class
  private
    FSource: TObject;
    FTarget: IBsonBuffer;
  public
    constructor Create; overload; virtual;
    procedure Serialize(const AName: String); virtual; abstract;
    property Source: TObject read FSource write FSource;
    property Target: IBsonBuffer read FTarget write FTarget;
  end;

  TPrimitivesBsonSerializer = class(TBaseBsonSerializer)
  private
    procedure SerializeObject(APropInfo: PPropInfo);
    procedure SerializePropInfo(APropInfo: PPropInfo);
    procedure SerializeSet(APropInfo: PPropInfo);
    procedure SerializeVariant(APropInfo: PPropInfo; const AName: String; const AVariant: Variant);
  public
    procedure Serialize(const AName: String); override;
  end;

procedure RegisterClassSerializer(AClass : TClass; ASerializer : TBaseBsonSerializerClass);
procedure UnRegisterClassSerializer(AClass: TClass; ASerializer : TBaseBsonSerializerClass);
function CreateSerializer(AClass : TClass): TBaseBsonSerializer;

implementation

uses
  Variants, Classes, System.Generics.Collections;

type
  TSerializerClassList = TList<TPair<TClass, TBaseBsonSerializerClass>>;
  TSerializerClassPair = TPair<TClass, TBaseBsonSerializerClass>;

  TDefaultObjectBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

  TStringsBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

var
  Serializers : TSerializerClassList;

procedure RegisterClassSerializer(AClass : TClass; ASerializer :
    TBaseBsonSerializerClass);
begin
  Serializers.Add(TSerializerClassPair.Create(AClass, ASerializer));
end;

procedure UnRegisterClassSerializer(AClass: TClass; ASerializer : TBaseBsonSerializerClass);
begin
  Serializers.Remove(TSerializerClassPair.Create(AClass, ASerializer));
end;

function CreateSerializer(AClass : TClass): TBaseBsonSerializer;
var
  i : integer;
begin
  for i := Serializers.Count - 1 downto 0 do
    if AClass.InheritsFrom(Serializers[i].Key) then
      begin
        Result := TBaseBsonSerializerClass(Serializers[i].Value).Create;
        exit;
      end;
  raise EBsonSerializer.CreateFmt('Could not find bson serializer for class %s', [AClass.ClassName]);
end;

{ TBaseBsonSerializer }

constructor TBaseBsonSerializer.Create;
begin
  inherited Create;
end;

{ TPrimitivesBsonSerializer }

procedure TPrimitivesBsonSerializer.Serialize(const AName: String);
var
  TypeData : PTypeData;
  PropList : PPropList;
  i : integer;
begin
  TypeData := GetTypeData(Source.ClassInfo);
  if TypeData = nil then
    raise EBsonSerializer.Create('Failed obtaining TypeData of source object');
  GetMem(PropList, TypeData.PropData.PropCount * sizeof(PPropInfo));
  try
    GetPropInfos(Source.ClassInfo, PropList);
    if PropList = nil then
      raise EBsonSerializer.Create('Failed obtaining list of published properties');
    for i := 0 to TypeData.PropData.PropCount - 1 do
      SerializePropInfo(PropList[i]);
  finally
    FreeMem(PropList);
  end;
end;

procedure TPrimitivesBsonSerializer.SerializePropInfo(APropInfo: PPropInfo);
begin
  case APropInfo.PropType^.Kind of
    tkInteger : Target.append(APropInfo.Name, GetOrdProp(Source, APropInfo));
    tkInt64 : Target.append(APropInfo.Name, GetInt64Prop(Source, APropInfo));
    tkChar : Target.append(APropInfo.Name, UTF8String(AnsiChar(GetOrdProp(Source, APropInfo))));
    tkWChar : Target.append(APropInfo.Name, UTF8String(Char(GetOrdProp(Source, APropInfo))));
    tkEnumeration : Target.append(APropInfo.Name, UTF8String(GetEnumProp(Source, APropInfo)));
    tkFloat : Target.append(APropInfo.Name, GetFloatProp(Source, APropInfo));
    tkLString, tkString, tkUString, tkWString : Target.append(APropInfo.Name, GetStrProp(Source, APropInfo));
    tkSet :
      begin
        Target.startArray(APropInfo.Name);
        SerializeSet(APropInfo);
        Target.finishObject;
      end;
    tkClass : SerializeObject(APropInfo);
    tkVariant : SerializeVariant(APropInfo, APropInfo.Name, Null);
  end;
end;

procedure TPrimitivesBsonSerializer.SerializeSet(APropInfo: PPropInfo);
var
  S : TIntegerSet;
  i : Integer;
  TypeInfo : PTypeInfo;
begin
  Integer(S) := GetOrdProp(Source, APropInfo);
  TypeInfo := GetTypeData(APropInfo.PropType^)^.CompType^;
  for i := 0 to SizeOf(Integer) * 8 - 1 do
    if i in S then
      Target.append('', GetEnumName(TypeInfo, i));
end;

procedure TPrimitivesBsonSerializer.SerializeObject(APropInfo: PPropInfo);
var
  SubSerializer : TBaseBsonSerializer;
  SubObject : TObject;
begin
  SubObject := GetObjectProp(Source, APropInfo);
  SubSerializer := CreateSerializer(SubObject.ClassType);
  try
    SubSerializer.Source := SubObject;
    SubSerializer.Target := Target;
    SubSerializer.Serialize(APropInfo.Name);
  finally
    SubSerializer.Free;
  end;
end;

procedure TPrimitivesBsonSerializer.SerializeVariant(APropInfo: PPropInfo;
    const AName: String; const AVariant: Variant);
var
  v : Variant;
  i : integer;
begin
  if APropInfo <> nil then
    v := GetVariantProp(Source, APropInfo)
  else v := AVariant;
  case VarType(v) of
    varNull: Target.appendNull(AName);
    varSmallInt, varInteger, varShortInt, varByte, varWord, varLongWord: Target.append(AName, integer(v));
    varSingle, varDouble, varCurrency: Target.append(AName, Extended(v));
    varDate: Target.append(APropInfo.Name, TDateTime(v));
    varOleStr, varString, varUString: Target.append(AName, UTF8String(String(v)));
    varBoolean: Target.append(AName, Boolean(v));
    varInt64, varUInt64: Target.append(AName, Int64(v));
    else if VarType(v) and varArray = varArray then
      begin
        if VarArrayDimCount(v) > 1 then
          exit; // We will support only one dimensional arrays
        Target.startArray(AName);
        for i := VarArrayLowBound(v, 1) to VarArrayHighBound(v, 1) do
          SerializeVariant(nil, '', v[i]);
        Target.finishObject;
      end;
  end;
end;

{ TStringsBsonSerializer }

procedure TStringsBsonSerializer.Serialize(const AName: String);
var
  i : integer;
  AList : TStrings;
begin
  Target.startArray(AName);
  AList := Source as TStringList;
  for i := 0 to AList.Count - 1 do
    Target.append('', AList[i]);
  Target.finishObject;
end;

{ TDefaultObjectBsonSerializer }

procedure TDefaultObjectBsonSerializer.Serialize(const AName: String);
var
  PrimitivesSerializer : TPrimitivesBsonSerializer;
begin
  if AName <> '' then
    Target.startObject(AName);
  PrimitivesSerializer := TPrimitivesBsonSerializer.Create;
  try
    PrimitivesSerializer.Source := Source;
    PrimitivesSerializer.Target := Target;
    PrimitivesSerializer.Serialize('');
  finally
    PrimitivesSerializer.Free;
  end;
  if AName <> '' then
    Target.finishObject;
end;

initialization
  Serializers := TSerializerClassList.Create;
  RegisterClassSerializer(TObject, TDefaultObjectBsonSerializer);
  RegisterClassSerializer(TStrings, TStringsBsonSerializer);
finalization
  UnRegisterClassSerializer(TStrings, TStringsBsonSerializer);
  UnRegisterClassSerializer(TObject, TDefaultObjectBsonSerializer);
  Serializers.Free;
end.
