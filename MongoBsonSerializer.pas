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
    procedure SerializeObject(APropInfo: PPropInfo);
    procedure SerializePropInfo(APropInfo: PPropInfo);
    procedure SerializeSet(APropInfo: PPropInfo);
  public
    constructor Create(ASource: TObject; ATarget: IBsonBuffer); overload; virtual;
    constructor Create; overload; virtual;
    procedure Serialize(const AName: String); virtual;
    property Source: TObject read FSource write FSource;
    property Target: IBsonBuffer read FTarget write FTarget;
  end;

  TDefaultObjectBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

  TStringListBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

procedure RegisterClassSerializer(AClass : TClass; ASerializer : TBaseBsonSerializerClass);
procedure UnRegisterClassSerializer(AClass: TClass; ASerializer : TBaseBsonSerializerClass);

implementation

uses
  Classes, System.Generics.Collections;

var
  Serializers : TList<TPair<TClass, TBaseBsonSerializerClass>>;

procedure RegisterClassSerializer(AClass : TClass; ASerializer :
    TBaseBsonSerializerClass);
begin
  Serializers.Add(TPair<TClass, TBaseBsonSerializerClass>.Create(AClass, ASerializer));
end;

procedure UnRegisterClassSerializer(AClass: TClass; ASerializer : TBaseBsonSerializerClass);
begin
  Serializers.Remove(TPair<TClass, TBaseBsonSerializerClass>.Create(AClass, ASerializer));
end;

{ TBaseBsonSerializer }

constructor TBaseBsonSerializer.Create(ASource: TObject; ATarget: IBsonBuffer);
begin
  inherited Create;
  FSource := ASource;
  FTarget := ATarget;
end;

constructor TBaseBsonSerializer.Create;
begin
  inherited Create;
end;

procedure TBaseBsonSerializer.Serialize(const AName: String);
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

procedure TBaseBsonSerializer.SerializePropInfo(APropInfo: PPropInfo);
begin
  case APropInfo.PropType^.Kind of
    tkInteger : Target.append(APropInfo.Name, GetOrdProp(Source, APropInfo));
    tkInt64 : Target.append(APropInfo.Name, GetInt64Prop(Source, APropInfo));
    tkChar : Target.append(APropInfo.Name, UTF8String(AnsiChar(GetOrdProp(Source, APropInfo))));
    tkWChar : Target.append(APropInfo.Name, UTF8String(Char(GetOrdProp(Source, APropInfo))));
    tkEnumeration : Target.append(APropInfo.Name, UTF8String(GetEnumProp(Source, APropInfo)));
    tkFloat : Target.append(APropInfo.Name, GetFloatProp(Source, APropInfo));
    tkLString, tkString, tkUString, tkWString : Target.append(APropInfo.Name, GetStrProp(Source, APropInfo));
    tkSet : begin
      Target.startArray(APropInfo.Name);
      SerializeSet(APropInfo);
      Target.finishObject;
    end;
    tkClass : SerializeObject(APropInfo);
  end;
end;

procedure TBaseBsonSerializer.SerializeSet(APropInfo: PPropInfo);
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

procedure TBaseBsonSerializer.SerializeObject(APropInfo: PPropInfo);
var
  SubSerializerClass : TBaseBsonSerializerClass;
  SubSerializer : TBaseBsonSerializer;
  SubObject : TObject;
  i : integer;
begin
  SubSerializerClass := nil;
  SubObject := GetObjectProp(Source, APropInfo);
  for i := Serializers.Count - 1 downto 0 do
    if SubObject.InheritsFrom(Serializers[i].Key) then
      begin
        SubSerializerClass := Serializers[i].Value;
        break;
      end;
  if SubSerializerClass = nil then
    raise EBsonSerializer.CreateFmt('Could not find bson serializer for property %s', [APropInfo.Name]);
  SubSerializer := SubSerializerClass.Create(SubObject, Target);
  try
    SubSerializer.Serialize(APropInfo.Name);
  finally
    SubSerializer.Free;
  end;
end;

{ TStringListBsonSerializer }

procedure TStringListBsonSerializer.Serialize(const AName: String);
var
  i : integer;
  AList : TStringList;
begin
  Target.startArray(AName);
  AList := Source as TStringList;
  for i := 0 to AList.Count - 1 do
    Target.append('', AList[i]);
  Target.finishObject;
end;

{ TDefaultObjectBsonSerializer }

procedure TDefaultObjectBsonSerializer.Serialize(const AName: String);
begin
  Target.startObject(AName);
  inherited Serialize(AName);
  Target.finishObject;
end;

initialization
  Serializers := TList<TPair<TClass, TBaseBsonSerializerClass>>.Create;
  RegisterClassSerializer(TObject, TDefaultObjectBsonSerializer);
  RegisterClassSerializer(TStringList, TStringListBsonSerializer);
finalization
  UnRegisterClassSerializer(TStringList, TStringListBsonSerializer);
  UnRegisterClassSerializer(TObject, TDefaultObjectBsonSerializer);
  Serializers.Free;
end.
