unit MongoBsonSerializer;

interface

{$i DelphiVersion_defines.inc}

uses
  Classes, MongoBson, SysUtils,
  MongoBsonSerializableClasses,
  {$IFDEF DELPHIXE} System.Generics.Collections, {$ELSE} HashTrie, {$ENDIF} TypInfo;

type
  EBsonSerializer = class(Exception);
  TBaseBsonSerializerClass = class of TBaseBsonSerializer;
  TBaseBsonSerializer = class
  private
    FSource: TObject;
    FTarget: IBsonBuffer;
  public
    constructor Create; virtual;
    procedure Serialize(const AName: String); virtual; abstract;
    property Source: TObject read FSource write FSource;
    property Target: IBsonBuffer read FTarget write FTarget;
  end;

  EBsonDeserializer = class(Exception);
  TBaseBsonDeserializerClass = class of TBaseBsonDeserializer;
  TBaseBsonDeserializer = class
  private
    FSource: IBsonIterator;
    FTarget: TObject;
  public
    constructor Create; virtual;
    procedure Deserialize; virtual; abstract;
    property Source: IBsonIterator read FSource write FSource;
    property Target: TObject read FTarget write FTarget;
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

  {$IFDEF DELPHIXE}
  TPropInfosDictionary = TDictionary<string, PPropInfo>;
  {$ELSE}
  TPropInfosDictionary = class(TStringHashTrie)
  public
    function TryGetValue(const key: string; var APropInfo: PPropInfo): Boolean;
  end;
  {$ENDIF}
  TPrimitivesBsonDeserializer = class(TBaseBsonDeserializer)
  private
    PropInfos : TPropInfosDictionary;
    procedure DeserializeIterator;
    procedure DeserializeObject(p: PPropInfo);
    procedure DeserializeSet(p: PPropInfo);
    procedure DeserializeVariantArray(p: PPropInfo);
  public
    procedure Deserialize; override;
  end;

procedure RegisterClassSerializer(AClass : TClass; ASerializer : TBaseBsonSerializerClass);
procedure UnRegisterClassSerializer(AClass: TClass; ASerializer : TBaseBsonSerializerClass);
function CreateSerializer(AClass : TClass): TBaseBsonSerializer;

procedure RegisterClassDeserializer(AClass: TClass; ADeserializer: TBaseBsonDeserializerClass);
procedure UnRegisterClassDeserializer(AClass: TClass; ADeserializer: TBaseBsonDeserializerClass);
function CreateDeserializer(AClass : TClass): TBaseBsonDeserializer;

implementation

uses
  Variants, MongoApi;

resourcestring
  SObjectHasNotPublishedProperties = 'Object has not published properties. review your logic';
  SFailedObtainingListOfPublishedProperties = 'Failed obtaining list of published properties';
  SFailedObtainingTypeDataOfObject = 'Failed obtaining TypeData of object';
  SCouldNotFindClass = 'Could not find target for class %s';

type
  {$IFDEF DELPHIXE}
  TClassPairList = TList<TPair<TClass, TClass>>;
  TClassPair = TPair<TClass, TClass>;
  {$ELSE}
  TClassPair = class
  private
    FKey : TClass;
    FValue: TClass;
  public
    constructor Create(AKey : TClass; AValue : TClass);
    property Key : TClass read FKey;
    property Value: TClass read FValue;
  end;

  TClassPairList = class(TList)
  private
    function GetItem(Index : integer) : TClassPair;
  public
    property Items[Index : integer] : TClassPair read GetItem; default;
  end;
  {$ENDIF}

  TDefaultObjectBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

  TStringsBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

  TStreamBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

  TStringsBsonDeserializer = class(TBaseBsonDeserializer)
  public
    procedure Deserialize; override;
  end;

  TStreamBsonDeserializer = class(TBaseBsonDeserializer)
  public
    procedure Deserialize; override;
  end;

  TObjectAsStringListBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

  TObjectAsStringListBsonDeserializer = class(TBaseBsonDeserializer)
  public
    procedure Deserialize; override;
  end;

var
  Serializers : TClassPairList;
  Deserializers : TClassPairList;

{$IFNDEF DELPHIXE}
constructor TClassPair.Create(AKey : TClass; AValue : TClass);
begin
  inherited Create;
  FKey := AKey;
  FValue := AValue;
end;

function TClassPairList.GetItem(Index : integer) : TClassPair;
begin
  Result := TClassPair(inherited Items[Index]);
end;
{$ENDIF}

procedure RegisterClassSerializer(AClass : TClass; ASerializer :
    TBaseBsonSerializerClass);
begin
  Serializers.Add(TClassPair.Create(AClass, ASerializer));
end;

procedure RemoveRegisteredClassPairFromList(List: TClassPairList; AKey, AValue: TClass);
var
  i : integer;
begin
  for i := 0 to List.Count - 1 do
    if (List[i].Key = AKey) and (List[i].Value = AValue) then
      begin
        {$IFNDEF DELPHIXE}
        List[i].Free;
        {$ENDIF}
        List.Delete(i);
        exit;
      end;
end;

procedure UnRegisterClassSerializer(AClass: TClass; ASerializer : TBaseBsonSerializerClass);
begin
  RemoveRegisteredClassPairFromList(Serializers, AClass, ASerializer);
end;

function CreateClassFromKey(List: TClassPairList; AClass : TClass): TObject;
var
  i : integer;
begin
  for i := List.Count - 1 downto 0 do
    if AClass.InheritsFrom(List[i].Key) then
      begin
        Result := TBaseBsonSerializerClass(List[i].Value).Create;
        exit;
      end;
  raise EBsonSerializer.CreateFmt(SCouldNotFindClass, [AClass.ClassName]);
end;

function CreateSerializer(AClass : TClass): TBaseBsonSerializer;
begin
  Result := CreateClassFromKey(Serializers, AClass) as TBaseBsonSerializer;
end;

procedure RegisterClassDeserializer(AClass: TClass; ADeserializer:
    TBaseBsonDeserializerClass);
begin
  Deserializers.Add(TClassPair.Create(AClass, ADeserializer));
end;

procedure UnRegisterClassDeserializer(AClass: TClass; ADeserializer:
    TBaseBsonDeserializerClass);
begin
  RemoveRegisteredClassPairFromList(Deserializers, AClass, ADeserializer);
end;

function CreateDeserializer(AClass : TClass): TBaseBsonDeserializer;
begin
  Result := CreateClassFromKey(Deserializers, AClass) as TBaseBsonDeserializer;
end;

function GetAndCheckTypeData(AClass : TClass) : PTypeData;
begin
  Result := GetTypeData(AClass.ClassInfo);
  if Result = nil then
    raise EBsonDeserializer.Create(SFailedObtainingTypeDataOfObject);
  if Result.PropCount <= 0 then
    raise EBsonDeserializer.Create(SObjectHasNotPublishedProperties);
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
  TypeData := GetAndCheckTypeData(Source.ClassType);
  GetMem(PropList, TypeData.PropCount * sizeof(PPropInfo));
  try
    GetPropInfos(Source.ClassInfo, PropList);
    if PropList = nil then
      raise EBsonSerializer.Create(SFailedObtainingListOfPublishedProperties);
    for i := 0 to TypeData.PropCount - 1 do
      SerializePropInfo(PropList[i]);
  finally
    FreeMem(PropList);
  end;
end;

procedure TPrimitivesBsonSerializer.SerializePropInfo(APropInfo: PPropInfo);
var
  ADate : TDateTime;
begin
  case APropInfo.PropType^.Kind of
    tkInteger : Target.append(APropInfo.Name, GetOrdProp(Source, APropInfo));
    tkInt64 : Target.append(APropInfo.Name, GetInt64Prop(Source, APropInfo));
    tkChar : Target.append(APropInfo.Name, UTF8String(AnsiChar(GetOrdProp(Source, APropInfo))));
    {$IFDEF DELPHIXE}
    tkWChar : Target.append(APropInfo.Name, UTF8String(Char(GetOrdProp(Source, APropInfo))));
    {$ELSE}
    tkWChar : Target.append(APropInfo.Name, UTF8Encode(WideChar(GetOrdProp(Source, APropInfo))));
    {$ENDIF}
    tkEnumeration :
      {$IFDEF DELPHIXE}
      if GetTypeData(TypeInfo(Boolean)) = APropInfo^.PropType^.TypeData then
      {$ELSE}
      if APropInfo^.PropType^.Name = 'Boolean' then
      {$ENDIF}
        Target.append(APropInfo.Name, GetEnumProp(Source, APropInfo) = 'True')
      else Target.append(APropInfo.Name, UTF8String(GetEnumProp(Source, APropInfo)));
    tkFloat :
      {$IFDEF DELPHIXE}
      if GetTypeData(TypeInfo(TDateTime)) = APropInfo^.PropType^.TypeData then
      {$ELSE}
      if APropInfo^.PropType^.Name = 'TDateTime' then
      {$ENDIF}
      begin
        ADate := GetFloatProp(Source, APropInfo);
        Target.append(APropInfo.Name, ADate);
      end
      else Target.append(APropInfo.Name, GetFloatProp(Source, APropInfo));
    {$IFDEF DELPHIXE} tkUString, {$ENDIF}
    tkLString, tkString : Target.append(APropInfo.Name, GetStrProp(Source, APropInfo));
    {$IFDEF DELPHIXE}
    tkWString : Target.append(APropInfo.Name, UTF8String(GetWideStrProp(Source, APropInfo)));
    {$ELSE}
    tkWString : Target.append(APropInfo.Name, UTF8Encode(GetWideStrProp(Source, APropInfo)));
    {$ENDIF}
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
    {$IFDEF DELPHIXE} varUString, {$ENDIF}
    varOleStr, varString: Target.append(AName, UTF8String(String(v)));
    varBoolean: Target.append(AName, Boolean(v));
    {$IFDEF DELPHIXE} varUInt64, {$ENDIF}
    varInt64: Target.append(AName, TVarData(v).VInt64);
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

{ TBaseBsonDeserializer }

constructor TBaseBsonDeserializer.Create;
begin
  inherited Create;
end;

{ TPrimitivesBsonDeserializer }

procedure TPrimitivesBsonDeserializer.Deserialize;
var
  PropList : PPropList;
  TypeData : PTypeData;
  i : integer;
begin
  TypeData := GetAndCheckTypeData(Target.ClassType);
  PropInfos := TPropInfosDictionary.Create;
  try
    GetMem(PropList, TypeData.PropCount * sizeof(PPropInfo));
    try
      GetPropInfos(Target.ClassInfo, PropList);
      for i := 0 to TypeData.PropCount - 1 do
        {$IFDEF DELPHIXE}
        PropInfos.Add(PropList[i].Name, PropList[i]);
        {$ELSE}
        PropInfos.Add(PropList[i].Name, TObject(PropList[i]));
        {$ENDIF}
      DeserializeIterator;
    finally
      FreeMem(PropList);
    end;
  finally
    PropInfos.Free;
  end;
end;

procedure TPrimitivesBsonDeserializer.DeserializeIterator;
var
  p : PPropInfo;
begin
  while Source.next do
    begin
      case Source.Kind of
        bsonINT : if PropInfos.TryGetValue(Source.key, p) then
          if p^.PropType^.Kind = tkVariant then
            SetVariantProp(Target, p, Source.value)
          else SetOrdProp(Target, p, Source.value);
        bsonBOOL : if PropInfos.TryGetValue(Source.key, p) then
          if p^.PropType^.Kind = tkVariant then
            SetVariantProp(Target, p, Source.value)
          else if Boolean(Source.value) then
            SetEnumProp(Target, p, 'True')
          else SetEnumProp(Target, p, 'False');
        bsonLONG : if PropInfos.TryGetValue(Source.key, p) then
          if p^.PropType^.Kind = tkVariant then
            SetVariantProp(Target, p, Source.AsInt64)
          else SetInt64Prop(Target, p, Source.AsInt64);
        bsonSTRING, bsonSYMBOL : if PropInfos.TryGetValue(Source.key, p) then
          case p^.PropType^.Kind of
            tkVariant : SetVariantProp(Target, p, Source.value);
            tkEnumeration : SetEnumProp(Target, p, Source.value);
            tkWString :
            {$IFDEF DELPHIXE}
            SetWideStrProp(Target, p, WideString(Source.AsUTF8String));
            {$ELSE}
            SetWideStrProp(Target, p, UTF8Decode(Source.AsUTF8String));
            {$ENDIF}
            {$IFDEF DELPHIXE}
            tkUString,
            {$ENDIF}
            tkString, tkLString : SetStrProp(Target, p, Source.Value);
            tkChar : if length(Source.value) > 0 then
              SetOrdProp(Target, p, NativeInt(UTF8String(Source.value)[1]));
            {$IFDEF DELPHIXE}
            tkWChar : if length(Source.value) > 0 then
              SetOrdProp(Target, p, NativeInt(string(Source.value)[1]));
            {$ELSE}
            tkWChar : if length(Source.value) > 0 then
              SetOrdProp(Target, p, NativeInt(UTF8Decode(Source.value)[1]));
            {$ENDIF}
          end;
        bsonDOUBLE, bsonDATE : if PropInfos.TryGetValue(Source.key, p) then
          if p^.PropType^.Kind = tkVariant then
            SetVariantProp(Target, p, Source.value)
          else SetFloatProp (Target, p, Source.Value);
        bsonARRAY : if PropInfos.TryGetValue(Source.key, p) then
          case p^.PropType^.Kind of
            tkSet : DeserializeSet(p);
            tkVariant : DeserializeVariantArray(p);
            tkClass : DeserializeObject(p);
          end;
        bsonOBJECT, bsonBINDATA : if PropInfos.TryGetValue(Source.key, p) and (p^.PropType^.Kind = tkClass) then
          DeserializeObject(p);
      end;
    end;
end;

procedure TPrimitivesBsonDeserializer.DeserializeObject(p: PPropInfo);
var
  Deserializer : TBaseBsonDeserializer;
  Obj : TObject;
begin
  Obj := GetObjectProp(Target, p);
  Deserializer := CreateDeserializer(Obj.ClassType);
  try
    if Source.Kind in [bsonOBJECT, bsonARRAY] then
      Deserializer.Source := Source.subiterator
    else Deserializer.Source := Source; // for bindata we need original BsonIterator to obtain binary handler
    Deserializer.Target := Obj;
    Deserializer.Deserialize;
  finally
    Deserializer.Free;
  end;
end;

procedure TPrimitivesBsonDeserializer.DeserializeSet(p: PPropInfo);
var
  subIt : IBsonIterator;
  setValue : string;
begin
  setValue := '[';
  subIt := Source.subiterator;
  // this is not efficient, but typically sets are going to be small entities
  while subIt.next do
    setValue := setValue + subIt.value + ',';
  if setValue[length(setValue)] = ',' then
    setValue[length(setValue)] := ']'
  else setValue := setValue + ']';
  SetSetProp(Target, p, setValue);
end;

procedure TPrimitivesBsonDeserializer.DeserializeVariantArray(p: PPropInfo);
var
  subIt : IBsonIterator;
  v : Variant;
  i : integer;
begin
  subIt := Source.subiterator;
  v := VarArrayCreate([0, 0], varVariant); // Types can vary in BSON. We will use Variant for our array
  i := 0;
  while subIt.next do
    begin
      if i >= VarArrayHighBound(v, 1) - VarArrayLowBound(v, 1) + 1 then
        VarArrayRedim(v, (VarArrayHighBound(v, 1) + 1) * 2);
      v[i] := subIt.value;
      inc(i);
    end;
  VarArrayRedim(v, i - 1);
  SetVariantProp(Target, p, v);
end;

{ TStringsBsonDeserializer }

procedure TStringsBsonDeserializer.Deserialize;
var
  AStrings : TStrings;
begin
  AStrings := Target as TStrings;
  while Source.next do
    AStrings.Add(Source.value);
end;

{ TPropInfosDictionary }

{$IFNDEF DELPHIXE}
function TPropInfosDictionary.TryGetValue(const key: string; var APropInfo:
    PPropInfo): Boolean;
begin
  Result := Find(key, TObject(APropInfo));
end;
{$ENDIF}

{ TStreamBsonSerializer }

procedure TStreamBsonSerializer.Serialize(const AName: String);
var
  Stream : TStream;
  Data : Pointer;
begin
  Stream := Source as TStream;
  if Stream.Size > 0 then
    GetMem(Data, Stream.Size)
  else Data := nil;
  try
    if Data <> nil then
      begin
        Stream.Position := 0;
        Stream.Read(Data^, Stream.Size);
      end;
    Target.appendBinary(AName, 0, Data, Stream.Size);
  finally
    if Data <> nil then
      FreeMem(Data);
  end;
end;

{ TStreamBsonDeserializer }

procedure TStreamBsonDeserializer.Deserialize;
var
  binData : IBsonBinary;
  Stream : TStream;
begin
  binData := Source.getBinary;
  Stream := Target as TStream;
  Stream.Size := binData.Len;
  Stream.Position := 0;
  if binData.Len > 0 then
    Stream.Write(binData.Data^, binData.Len);
end;

{ TObjectAsStringListBsonSerializer }

procedure TObjectAsStringListBsonSerializer.Serialize(const AName: String);
var
  i : integer;
  AList : TStrings;
begin
  Target.startObject(AName);
  AList := Source as TStringList;
  for i := 0 to AList.Count - 1 do
   begin
     Target.append(AList.Names[i], AList.ValueFromIndex[i]);
   end;
  Target.finishObject;
end;

{ TObjectAsStringListBsonDeserializer }

procedure TObjectAsStringListBsonDeserializer.Deserialize;
var
  AStrings : TStrings;
begin
  AStrings := Target as TStrings;
  while Source.next do
    AStrings.Add(Source.key + '=' + Source.value);
end;

initialization
  Serializers := TClassPairList.Create;
  Deserializers := TClassPairList.Create;
  RegisterClassSerializer(TObject, TDefaultObjectBsonSerializer);
  RegisterClassSerializer(TStrings, TStringsBsonSerializer);
  RegisterClassSerializer(TStream, TStreamBsonSerializer);
  RegisterClassSerializer(TObjectAsStringList, TObjectAsStringListBsonSerializer);
  RegisterClassDeserializer(TObject, TPrimitivesBsonDeserializer);
  RegisterClassDeserializer(TStrings, TStringsBsonDeserializer);
  RegisterClassDeserializer(TStream, TStreamBsonDeserializer);
  RegisterClassDeserializer(TObjectAsStringList, TObjectAsStringListBsonDeserializer);
finalization
  UnRegisterClassDeserializer(TStream, TStreamBsonDeserializer);
  UnRegisterClassDeserializer(TObject, TPrimitivesBsonDeserializer);
  UnRegisterClassDeserializer(TStrings, TStringsBsonDeserializer);
  UnRegisterClassDeserializer(TObjectAsStringList, TObjectAsStringListBsonDeserializer);
  UnRegisterClassSerializer(TStream, TStreamBsonSerializer);
  UnRegisterClassSerializer(TStrings, TStringsBsonSerializer);
  UnRegisterClassSerializer(TObject, TDefaultObjectBsonSerializer);
  UnRegisterClassSerializer(TObjectAsStringList, TObjectAsStringListBsonSerializer);
  Deserializers.Free;
  Serializers.Free;
end.
