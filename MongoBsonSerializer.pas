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
  public
    constructor Create; virtual;
    procedure Deserialize(var ATarget: TObject); virtual; abstract;
    property Source: IBsonIterator read FSource write FSource;
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
    procedure DeserializeIterator(var ATarget: TObject);
    procedure DeserializeObject(p: PPropInfo; var ATarget: TObject);
    procedure DeserializeSet(p: PPropInfo; var ATarget: TObject);
    procedure DeserializeVariantArray(p: PPropInfo; var v: Variant);
    function GetArrayDimension(it: IBsonIterator) : Integer;
  public
    procedure Deserialize(var ATarget: TObject); override;
  end;

procedure RegisterClassSerializer(AClass : TClass; ASerializer : TBaseBsonSerializerClass);
procedure UnRegisterClassSerializer(AClass: TClass; ASerializer : TBaseBsonSerializerClass);
function CreateSerializer(AClass : TClass): TBaseBsonSerializer;

procedure RegisterClassDeserializer(AClass: TClass; ADeserializer: TBaseBsonDeserializerClass);
procedure UnRegisterClassDeserializer(AClass: TClass; ADeserializer: TBaseBsonDeserializerClass);
function CreateDeserializer(AClass : TClass): TBaseBsonDeserializer;

implementation

uses
  MongoApi{$IFNDEF VER130}, Variants{$ELSE}{$IFDEF Enterprise}, Variants{$ENDIF}{$ENDIF};

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
    procedure Deserialize(var ATarget: TObject); override;
  end;

  TStreamBsonDeserializer = class(TBaseBsonDeserializer)
  public
    procedure Deserialize(var ATarget: TObject); override;
  end;

  TObjectAsStringListBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String); override;
  end;

  TObjectAsStringListBsonDeserializer = class(TBaseBsonDeserializer)
  public
    procedure Deserialize(var ATarget: TObject); override;
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
    tkDynArray :
      SerializeVariant(nil, APropInfo.Name, GetPropValue(Source, APropInfo));
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
  v, tmp : Variant;
  i, j : integer;
  dim : integer;
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
        dim := VarArrayDimCount(v);
        Target.startArray(AName);
        for i := 1 to dim do
        begin
          if dim > 1 then
            Target.startArray('');
          for j := VarArrayLowBound(v, i) to VarArrayHighBound(v, i) do
          begin
            if dim > 1 then
              tmp := VarArrayGet(v, [i - 1, j])
            else
              tmp := v[j];
            SerializeVariant(nil, '', tmp);
          end;
          if dim > 1 then
            Target.finishObject;
        end;
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

procedure TPrimitivesBsonDeserializer.Deserialize(var ATarget: TObject);
var
  PropList : PPropList;
  TypeData : PTypeData;
  i : integer;
begin
  TypeData := GetAndCheckTypeData(ATarget.ClassType);
  PropInfos := TPropInfosDictionary.Create;
  try
    GetMem(PropList, TypeData.PropCount * sizeof(PPropInfo));
    try
      GetPropInfos(ATarget.ClassInfo, PropList);
      for i := 0 to TypeData.PropCount - 1 do
        {$IFDEF DELPHIXE}
        PropInfos.Add(PropList[i].Name, PropList[i]);
        {$ELSE}
        PropInfos.Add(PropList[i].Name, TObject(PropList[i]));
        {$ENDIF}
      DeserializeIterator(ATarget);
    finally
      FreeMem(PropList);
    end;
  finally
    PropInfos.Free;
  end;
end;

procedure TPrimitivesBsonDeserializer.DeserializeIterator(var ATarget: TObject);
var
  p : PPropInfo;
  po : Pointer;
  v : Variant;
begin
  while Source.next do
    begin
      if not PropInfos.TryGetValue(Source.key, p) then
        continue;
      if (p^.PropType^.Kind = tkVariant) and not (Source.Kind in [bsonARRAY])  then
        SetVariantProp(ATarget, p, Source.value)
      else case Source.Kind of
        bsonINT : SetOrdProp(ATarget, p, Source.AsInteger);
        bsonBOOL : if Source.AsBoolean then
            SetEnumProp(ATarget, p, 'True')
          else SetEnumProp(ATarget, p, 'False');
        bsonLONG : SetInt64Prop(ATarget, p, Source.AsInt64);
        bsonSTRING, bsonSYMBOL : if PropInfos.TryGetValue(Source.key, p) then
          case p^.PropType^.Kind of
            tkEnumeration : SetEnumProp(ATarget, p, Source.AsUTF8String);
            tkWString :
            {$IFDEF DELPHIXE}
            SetWideStrProp(ATarget, p, WideString(Source.AsUTF8String));
            {$ELSE}
            SetWideStrProp(ATarget, p, UTF8Decode(Source.AsUTF8String));
            {$ENDIF}
            {$IFDEF DELPHIXE}
            tkUString,
            {$ENDIF}
            tkString, tkLString : SetStrProp(ATarget, p, Source.AsUTF8String);
            tkChar : if length(Source.AsUTF8String) > 0 then
              SetOrdProp(ATarget, p, NativeInt(Source.AsUTF8String[1]));
            {$IFDEF DELPHIXE}
            tkWChar : if length(Source.value) > 0 then
              SetOrdProp(ATarget, p, NativeInt(string(Source.value)[1]));
            {$ELSE}
            tkWChar : if length(Source.value) > 0 then
              SetOrdProp(ATarget, p, NativeInt(UTF8Decode(Source.value)[1]));
            {$ENDIF}
          end;
        bsonDOUBLE : SetFloatProp (ATarget, p, Source.AsDouble);
        bsonDATE : SetFloatProp (ATarget, p, Source.AsDateTime);
        bsonARRAY : case p^.PropType^.Kind of
            tkSet : DeserializeSet(p, ATarget);
            tkVariant :
            begin
              v := GetVariantProp(ATarget, p);
              DeserializeVariantArray(p, v);
              SetVariantProp(ATarget, p, v);
            end;
            tkDynArray :
            begin
              po := GetDynArrayProp(ATarget, p^.Name);
              if DynArrayDim(PDynArrayTypeInfo(p^.PropType^)) = 1 then
              begin
                DeserializeVariantArray(p, v);
                DynArrayFromVariant(po, v, p^.PropType^);
                SetDynArrayProp(ATarget, p, po);
              end
              else
              begin
                DynArrayToVariant(v, po, p^.PropType^);
                DeserializeVariantArray(p, v);
                DynArrayFromVariant(po, v, p^.PropType^);
                SetDynArrayProp(ATarget, p, po);
              end;
            end;
            tkClass : DeserializeObject(p, ATarget);
          end;
        bsonOBJECT, bsonBINDATA : if p^.PropType^.Kind = tkClass then
          DeserializeObject(p, ATarget);
      end;
    end;
end;

procedure TPrimitivesBsonDeserializer.DeserializeObject(p: PPropInfo; var
    ATarget: TObject);
var
  Deserializer : TBaseBsonDeserializer;
  Obj : TObject;
begin
  Obj := GetObjectProp(ATarget, p);
  Deserializer := CreateDeserializer(Obj.ClassType);
  try
    if Source.Kind in [bsonOBJECT, bsonARRAY] then
      Deserializer.Source := Source.subiterator
    else Deserializer.Source := Source; // for bindata we need original BsonIterator to obtain binary handler
    Deserializer.Deserialize(Obj);
  finally
    Deserializer.Free;
  end;
end;

procedure TPrimitivesBsonDeserializer.DeserializeSet(p: PPropInfo; var ATarget:
    TObject);
var
  subIt : IBsonIterator;
  setValue : string;
begin
  setValue := '[';
  subIt := Source.subiterator;
  // this is not efficient, but typically sets are going to be small entities
  while subIt.next do
    setValue := setValue + subIt.AsUTF8String + ',';
  if setValue[length(setValue)] = ',' then
    setValue[length(setValue)] := ']'
  else setValue := setValue + ']';
  SetSetProp(ATarget, p, setValue);
end;

procedure TPrimitivesBsonDeserializer.DeserializeVariantArray(p: PPropInfo; var v: Variant);
var
  subIt, currIt : IBsonIterator;
  i, j, dim : integer;
begin
  dim := GetArrayDimension(Source);
  j := 0;

  if dim > 1 then
  begin
    if dim <> VarArrayDimCount(v) then
      exit;
  end
  else
    v := VarArrayCreate([0, 256], varVariant);

  subIt := Source.subiterator;
  for i := 0 to dim - 1 do
  begin
    if dim > 1 then
    begin
      subit.next;
      currIt := subit.subiterator;
    end
    else
      currIt := subit;
    for j := VarArrayLowBound(v, dim) to VarArrayHighBound(v, dim) do
    begin
      if not currIt.next then
        break;
      if (dim = 1) and (j >= VarArrayHighBound(v, dim) - VarArrayLowBound(v, dim) + 1) then
        VarArrayRedim(v, (VarArrayHighBound(v, dim) + 1) * 2);
      if dim > 1 then
        v[i, j] := currIt.value
      else
        v[j] := currIt.value;
    end;
  end;
  if dim = 1 then
    VarArrayRedim(v, j - 1);
end;

function TPrimitivesBsonDeserializer.GetArrayDimension(it: IBsonIterator) : Integer;
begin
  Result := 0;
  while it.Kind = bsonARRAY do
  begin
    Inc(Result);
    it := it.subiterator;
  end;
end;

{ TStringsBsonDeserializer }

procedure TStringsBsonDeserializer.Deserialize(var ATarget: TObject);
var
  AStrings : TStrings;
begin
  AStrings := ATarget as TStrings;
  while Source.next do
    AStrings.Add(Source.AsUTF8String);
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

procedure TStreamBsonDeserializer.Deserialize(var ATarget: TObject);
var
  binData : IBsonBinary;
  Stream : TStream;
begin
  binData := Source.getBinary;
  Stream := ATarget as TStream;
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

procedure TObjectAsStringListBsonDeserializer.Deserialize(var ATarget: TObject);
var
  AStrings : TStrings;
begin
  AStrings := ATarget as TStrings;
  while Source.next do
    AStrings.Add(Source.key + '=' + Source.AsUTF8String);
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
