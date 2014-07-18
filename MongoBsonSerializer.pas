unit MongoBsonSerializer;

interface

{$i DelphiVersion_defines.inc}

uses
  Classes, MongoBson, SysUtils,
  MongoBsonSerializableClasses,
  {$IFDEF DELPHIXE} System.Generics.Collections, {$ELSE} HashTrie, {$ENDIF} TypInfo;

const
  SERIALIZED_ATTRIBUTE_ACTUALTYPE = '_type';

type
  TObjectBuilderFunction = function(const AClassName : string; AContext : Pointer) : TObject;
  EBsonSerializationException = class(Exception);

  {$IFDEF DELPHIXE}
  TPropInfosDictionary = class(TDictionary<string, PPropInfo>)
  {$ELSE}
  TPropInfosDictionary = class(TStringHashTrie)
  {$ENDIF}
  private
    FPropList : PPropList;
  public
    constructor Create(APropList : PPropList); {$IFNDEF DELPHIXE} reintroduce; {$ENDIF}
    destructor Destroy; override;
    {$IFNDEF DELPHIXE}
    function TryGetValue(const key: string; var APropInfo: PPropInfo): Boolean;
    {$ENDIF}
    property PropList : PPropList read FPropList;
  end;

  EBsonSerializer = class(Exception);
  TBaseBsonSerializerClass = class of TBaseBsonSerializer;
  TBaseBsonSerializer = class
  private
    FTarget: IBsonBuffer;
  protected
    procedure Serialize_type(ASource: TObject);
  public
    constructor Create; virtual;
    procedure Serialize(const AName: String; ASource: TObject); virtual; abstract;
    property Target: IBsonBuffer read FTarget write FTarget;
  end;

  EBsonDeserializer = class(Exception);
  TBaseBsonDeserializerClass = class of TBaseBsonDeserializer;
  TBaseBsonDeserializer = class
  private
    FSource: IBsonIterator;
  public
    constructor Create; virtual;
    procedure Deserialize(var ATarget: TObject; AContext: Pointer); virtual; abstract;
    property Source: IBsonIterator read FSource write FSource;
  end;

  TPrimitivesBsonSerializer = class(TBaseBsonSerializer)
  private
    procedure SerializeObject(APropInfo: PPropInfo; ASource: TObject);
    procedure SerializePropInfo(APropInfo: PPropInfo; ASource: TObject);
    procedure SerializeSet(APropInfo: PPropInfo; ASource: TObject);
    procedure SerializeVariant(APropInfo: PPropInfo; const AName: String; const AVariant: Variant; ASource: TObject);
    procedure SerializeDynamicArrayOfObjects(APropInfo: PPropInfo; ASource: TObject);
  public
    procedure Serialize(const AName: String; ASource: TObject); override;
  end;

  TPrimitivesBsonDeserializer = class(TBaseBsonDeserializer)
  private
    function BuildObject(const _Type: string; AContext : Pointer): TObject;
    procedure DeserializeIterator(var ATarget: TObject; AContext : Pointer);
    procedure DeserializeObject(p: PPropInfo; ATarget: TObject; AContext: Pointer); overload;
    procedure DeserializeObject(AObjClass: TClass; var AObj: TObject;
                                ASource: IBsonIterator; AContext: Pointer); overload;
    procedure DeserializeSet(p: PPropInfo; var ATarget: TObject);
    procedure DeserializeVariantArray(p: PPropInfo; var v: Variant);
    procedure DeserializeDynamicArrayOfObjects(p: PPropInfo; var ATarget: TObject; AContext : Pointer);
    function GetArrayDimension(it: IBsonIterator) : Integer;
  public
    procedure Deserialize(var ATarget: TObject; AContext : Pointer); override;
  end;

{ ****** IMPORTANT *******
  The following registration functions are NOT threadsafe with their corresponding lookup functions
  They are meant to be used during application initialization only. Don't attempt to register new serializers or buildable
  serializable classes during normal course of execution. If you do so, you will get nasty errors due to concurrent access
  to the structures holding objects registered by the following routines }
procedure RegisterClassSerializer(AClass : TClass; ASerializer : TBaseBsonSerializerClass);
procedure UnRegisterClassSerializer(AClass: TClass; ASerializer : TBaseBsonSerializerClass);
function CreateSerializer(AClass : TClass): TBaseBsonSerializer;

procedure RegisterClassDeserializer(AClass: TClass; ADeserializer: TBaseBsonDeserializerClass);
procedure UnRegisterClassDeserializer(AClass: TClass; ADeserializer: TBaseBsonDeserializerClass);
function CreateDeserializer(AClass : TClass): TBaseBsonDeserializer;

procedure RegisterBuildableSerializableClass(const AClassName : string; ABuilderFunction : TObjectBuilderFunction);
procedure UnregisterBuildableSerializableClass(const AClassName : string);

{ Use Strip_T_FormClassName() when comparing a regular Delphi ClassName with a serialized _type attribute
  coming from service-bus passed as parameter to object builder function }
function Strip_T_FormClassName(const AClassName : string): string;

implementation

uses
  SyncObjs, MongoApi, uLinkedListDefaultImplementor, uScope
  {$IFNDEF VER130}, Variants{$ELSE}{$IFDEF Enterprise}, Variants{$ENDIF}{$ENDIF};

const
  SBoolean = 'Boolean';
  STrue = 'True';
  STDateTime = 'TDateTime';
  SFalse = 'False';

resourcestring
  SSuitableBuilderNotFoundForClass = 'Suitable builder not found for class <%s>';
  SCanTBuildPropInfoListOfANilObjec = 'Can''t build PropInfo list of a nil object';
  SObjectHasNotPublishedProperties = 'Object has not published properties. review your logic';
  SFailedObtainingTypeDataOfObject = 'Failed obtaining TypeData of object';
  SCouldNotFindClass = 'Could not find target for class %s';

type
  TObjectDynArray = array of TObject;
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

  {$IFDEF DELPHIXE}
  TClassPropInfoDictionaryDictionary = TDictionary<TClass, TPropInfosDictionary>;
  {$ELSE}
  TClassPropInfoDictionaryDictionary = class(TIntegerHashTrie)
  public
    function TryGetValue(key: TClass; var APropInfoDictionary: TPropInfosDictionary): Boolean;
  end;
  {$ENDIF}

  TDefaultObjectBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String; ASource: TObject); override;
  end;

  TStringsBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String; ASource: TObject); override;
  end;

  TStreamBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String; ASource: TObject); override;
  end;

  TStringsBsonDeserializer = class(TBaseBsonDeserializer)
  public
    procedure Deserialize(var ATarget: TObject; AContext : Pointer); override;
  end;

  TStreamBsonDeserializer = class(TBaseBsonDeserializer)
  public
    procedure Deserialize(var ATarget: TObject; AContext : Pointer); override;
  end;

  TObjectAsStringListBsonSerializer = class(TBaseBsonSerializer)
  public
    procedure Serialize(const AName: String; ASource: TObject); override;
  end;

  TObjectAsStringListBsonDeserializer = class(TBaseBsonDeserializer)
  public
    procedure Deserialize(var ATarget: TObject; AContext: Pointer); override;
  end;

  {$IFDEF DELPHIXE}
  TBuilderFunctionsDictionary = TDictionary<string, TObjectBuilderFunction>;
  {$ELSE}
  TBuilderFunctionsDictionary = class(TStringHashTrie)
  public
    function TryGetValue(const key: string; var ABuilderFunction: TObjectBuilderFunction): Boolean;
  end;
  {$ENDIF}

var
  Serializers : TClassPairList;
  Deserializers : TClassPairList;
  BuilderFunctions : TBuilderFunctionsDictionary;
  PropInfosDictionaryCacheTrackingListLock : TSynchroObject;
  PropInfosDictionaryCacheTrackingList : TList;

threadvar
  // To reduce contention maintaining cache of PropInfosDictionary we will keep one cache per thread using a threadvar (TLS)
  PropInfosDictionaryDictionary : TClassPropInfoDictionaryDictionary;

function Strip_T_FormClassName(const AClassName : string): string;
begin
  Result := AClassName;
  if (Result <> '') and (UpCase(Result[1]) = 'T') then
    system.Delete(Result, 1, 1);
end;

function GetPropInfosDictionaryDictionary : TClassPropInfoDictionaryDictionary;
begin
  if PropInfosDictionaryDictionary = nil then
    begin
      PropInfosDictionaryDictionary := TClassPropInfoDictionaryDictionary.Create;
      try
        {$IFNDEF DELPHIXE}
        PropInfosDictionaryDictionary.AutoFreeObjects := True;
        {$ENDIF}
        PropInfosDictionaryCacheTrackingListLock.Acquire;
        try
          PropInfosDictionaryCacheTrackingList.Add(PropInfosDictionaryDictionary);
        finally
          PropInfosDictionaryCacheTrackingListLock.Release;
        end;
      except
        PropInfosDictionaryDictionary.Free;
        PropInfosDictionaryDictionary := nil;
        raise;
      end;
    end;
  Result := PropInfosDictionaryDictionary;
end;

function GetSerializableObjectBuilderFunction(const AClassName : string):
    TObjectBuilderFunction;
begin
  BuilderFunctions.TryGetValue(AClassName, Result);
end;

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
    raise EBsonSerializationException.Create(SFailedObtainingTypeDataOfObject);
  if Result.PropCount <= 0 then
    raise EBsonSerializationException.Create(SObjectHasNotPublishedProperties);
end;

function GetPropInfosDictionary(AObj: TObject): TPropInfosDictionary;
var
  PropList : PPropList;
  TypeData : PTypeData;
  i : integer;
begin
  if AObj = nil then
    raise EBsonSerializationException.Create(SCanTBuildPropInfoListOfANilObjec);
  if GetPropInfosDictionaryDictionary.TryGetValue(AObj.ClassType, Result) then
    exit;
  TypeData := GetAndCheckTypeData(AObj.ClassType);
  GetMem(PropList, TypeData.PropCount * sizeof(PPropInfo));
  try
    Result := TPropInfosDictionary.Create(PropList); // Result takes ownership of PropList
    try
      GetPropInfos(AObj.ClassInfo, PropList);
      for i := 0 to TypeData.PropCount - 1 do
        Result.Add(PropList[i].Name, {$IFNDEF DELPHIXE}TObject({$ENDIF}PropList[i]{$IFNDEF DELPHIXE}){$ENDIF});
      GetPropInfosDictionaryDictionary.Add({$IFNDEF DELPHIXE}integer({$ENDIF}AObj.ClassType{$IFNDEF DELPHIXE}){$ENDIF}, Result);
    except
      Result.Free;
      raise;
    end;
  except
    if Result = nil then
      FreeMem(PropList);
    Result := nil;
    raise;
  end;
end;

{ TBaseBsonSerializer }

constructor TBaseBsonSerializer.Create;
begin
  inherited Create;
end;

procedure TBaseBsonSerializer.Serialize_type(ASource: TObject);
begin
  Target.append(SERIALIZED_ATTRIBUTE_ACTUALTYPE, Strip_T_FormClassName(ASource.ClassName));
end;

{ TPrimitivesBsonSerializer }

procedure TPrimitivesBsonSerializer.Serialize(const AName: String; ASource:
    TObject);
var
  TypeData : PTypeData;
  i : integer;
  PropInfosDictionary : TPropInfosDictionary;
begin
  TypeData := GetAndCheckTypeData(ASource.ClassType);
  PropInfosDictionary := GetPropInfosDictionary(ASource);
  for i := 0 to TypeData.PropCount - 1 do
    SerializePropInfo(PropInfosDictionary.PropList[i], ASource);
end;

procedure TPrimitivesBsonSerializer.SerializePropInfo(APropInfo: PPropInfo;
    ASource: TObject);
var
  ADate : TDateTime;
  dynArrayElementInfo: PPTypeInfo;
begin
  case APropInfo.PropType^.Kind of
    tkInteger : Target.append(APropInfo.Name, GetOrdProp(ASource, APropInfo));
    tkInt64 : Target.append(APropInfo.Name, GetInt64Prop(ASource, APropInfo));
    tkChar : Target.append(APropInfo.Name, UTF8String(AnsiChar(GetOrdProp(ASource, APropInfo))));
    {$IFDEF DELPHIXE}
    tkWChar : Target.append(APropInfo.Name, UTF8String(Char(GetOrdProp(ASource, APropInfo))));
    {$ELSE}
    tkWChar : Target.append(APropInfo.Name, UTF8Encode(WideChar(GetOrdProp(ASource, APropInfo))));
    {$ENDIF}
    tkEnumeration :
      {$IFDEF DELPHIXE}
      if GetTypeData(TypeInfo(Boolean)) = APropInfo^.PropType^.TypeData then
      {$ELSE}
      if APropInfo^.PropType^.Name = SBoolean then
      {$ENDIF}
        Target.append(APropInfo.Name, GetEnumProp(ASource, APropInfo) = STrue)
      else Target.append(APropInfo.Name, UTF8String(GetEnumProp(ASource, APropInfo)));
    tkFloat :
      {$IFDEF DELPHIXE}
      if GetTypeData(TypeInfo(TDateTime)) = APropInfo^.PropType^.TypeData then
      {$ELSE}
      if APropInfo^.PropType^.Name = STDateTime then
      {$ENDIF}
      begin
        ADate := GetFloatProp(ASource, APropInfo);
        Target.append(APropInfo.Name, ADate);
      end
      else Target.append(APropInfo.Name, GetFloatProp(ASource, APropInfo));
    {$IFDEF DELPHIXE} tkUString, {$ENDIF}
    tkLString, tkString : Target.append(APropInfo.Name, GetStrProp(ASource, APropInfo));
    {$IFDEF DELPHIXE}
    tkWString : Target.append(APropInfo.Name, UTF8String(GetWideStrProp(ASource, APropInfo)));
    {$ELSE}
    tkWString : Target.append(APropInfo.Name, UTF8Encode(GetWideStrProp(ASource, APropInfo)));
    {$ENDIF}
    tkSet :
      begin
        Target.startArray(APropInfo.Name);
        SerializeSet(APropInfo, ASource);
        Target.finishObject;
      end;
    tkClass : SerializeObject(APropInfo, ASource);
    tkVariant : SerializeVariant(APropInfo, APropInfo.Name, Null, ASource);
    tkDynArray :
    begin
      dynArrayElementInfo := GetTypeData(APropInfo.PropType^)^.elType2;
      if (dynArrayElementInfo <> nil) and (dynArrayElementInfo^.Kind = tkClass) then
        SerializeDynamicArrayOfObjects(APropInfo, ASource) // its array of objects
      else // its array of primitives
        SerializeVariant(nil, APropInfo.Name, GetPropValue(ASource, APropInfo), ASource);
    end;

  end;   
end;

procedure TPrimitivesBsonSerializer.SerializeSet(APropInfo: PPropInfo; ASource:
    TObject);
var
  S : TIntegerSet;
  i : Integer;
  TypeInfo : PTypeInfo;
begin
  Integer(S) := GetOrdProp(ASource, APropInfo);
  TypeInfo := GetTypeData(APropInfo.PropType^)^.CompType^;
  for i := 0 to SizeOf(Integer) * 8 - 1 do
    if i in S then
      Target.append('', GetEnumName(TypeInfo, i));
end;

procedure TPrimitivesBsonSerializer.SerializeObject(APropInfo: PPropInfo;
    ASource: TObject);
var
  SubSerializer : TBaseBsonSerializer;
  SubObject : TObject;
begin
  SubObject := GetObjectProp(ASource, APropInfo);
  SubSerializer := CreateSerializer(SubObject.ClassType);
  try
    SubSerializer.Target := Target;
    SubSerializer.Serialize(APropInfo.Name, SubObject);
  finally
    SubSerializer.Free;
  end;
end;

procedure TPrimitivesBsonSerializer.SerializeVariant(APropInfo: PPropInfo;
    const AName: String; const AVariant: Variant; ASource: TObject);
var
  v, tmp : Variant;
  i, j : integer;
  dim : integer;
begin
  if APropInfo <> nil then
    v := GetVariantProp(ASource, APropInfo)
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
            SerializeVariant(nil, '', tmp, ASource);
          end;
          if dim > 1 then
            Target.finishObject;
        end;
        Target.finishObject;
      end;
  end;
end;

procedure TPrimitivesBsonSerializer.SerializeDynamicArrayOfObjects(
  APropInfo: PPropInfo; ASource: TObject);
var
  dynArrOfObjs: TObjectDynArray;
  I: Integer;
  SubSerializer : TBaseBsonSerializer;
  scope: IScope;
begin
  scope := NewScope;
  Target.startArray(APropInfo.Name);
  dynArrOfObjs := TObjectDynArray(GetDynArrayProp(ASource, APropInfo));
  for I := Low(dynArrOfObjs) to High(dynArrOfObjs) do
  begin
    SubSerializer := scope.add(CreateSerializer(dynArrOfObjs[0].ClassType));
    SubSerializer.Target := Target;
    SubSerializer.Serialize(IntToStr(I), dynArrOfObjs[I]);
  end;
  Target.finishObject;
end;

{ TStringsBsonSerializer }

procedure TStringsBsonSerializer.Serialize(const AName: String; ASource:
    TObject);
var
  i : integer;
  AList : TStrings;
begin
  Target.startArray(AName);
  AList := ASource as TStrings;
  for i := 0 to AList.Count - 1 do
    Target.append('', AList[i]);
  Target.finishObject;
end;

{ TDefaultObjectBsonSerializer }

procedure TDefaultObjectBsonSerializer.Serialize(const AName: String; ASource:
    TObject);
var
  PrimitivesSerializer : TPrimitivesBsonSerializer;
begin
  if AName <> '' then
    Target.startObject(AName);
  PrimitivesSerializer := TPrimitivesBsonSerializer.Create;
  try
    PrimitivesSerializer.Target := Target;
    Serialize_type(ASource); // We will always serialize _type for root object
    PrimitivesSerializer.Serialize('', ASource);
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

function TPrimitivesBsonDeserializer.BuildObject(const _Type: string; AContext: Pointer): TObject;
var
  BuilderFn : TObjectBuilderFunction;
begin
  BuilderFn := GetSerializableObjectBuilderFunction(_Type);
  if @BuilderFn = nil then
    raise EBsonDeserializer.CreateFmt(SSuitableBuilderNotFoundForClass, [_Type]);
  Result := BuilderFn(_Type, AContext);
end;

{ TPrimitivesBsonDeserializer }

procedure TPrimitivesBsonDeserializer.Deserialize(var ATarget: TObject;
    AContext : Pointer);
begin
  DeserializeIterator(ATarget, AContext);
end;

procedure TPrimitivesBsonDeserializer.DeserializeIterator(var ATarget: TObject;
    AContext : Pointer);
var
  dynArrayElementInfo: PPTypeInfo;
  p : PPropInfo;
  po : Pointer;
  v : Variant;
  PropInfosDictionary : TPropInfosDictionary;
  (* We need this safe function because if variant Av param represents a zero size array
     the call to DynArrayFromVariant() will fail rather than assigning nil to Apo parameter *)
  procedure SafeDynArrayFromVariant(var Apo : Pointer; const Av : Variant; ATypeInfo: Pointer);
  begin
    if VarArrayHighBound(Av, 1) - VarArrayLowBound(Av, 1) >= 0 then
      DynArrayFromVariant(Apo, Av, ATypeInfo)
    else Apo := nil;
  end;
begin
  while Source.next do
    begin
      if (ATarget = nil) and (Source.key = SERIALIZED_ATTRIBUTE_ACTUALTYPE) then
        ATarget := BuildObject(Source.value, AContext);
      PropInfosDictionary := GetPropInfosDictionary(ATarget);
      if not PropInfosDictionary.TryGetValue(Source.key, p) then
        continue;
      if (p^.PropType^.Kind = tkVariant) and not (Source.Kind in [bsonARRAY])  then
        SetVariantProp(ATarget, p, Source.value)
      else case Source.Kind of
        bsonINT : SetOrdProp(ATarget, p, Source.AsInteger);
        bsonBOOL : if Source.AsBoolean then
            SetEnumProp(ATarget, p, STrue)
          else SetEnumProp(ATarget, p, SFalse);
        bsonLONG : SetInt64Prop(ATarget, p, Source.AsInt64);
        bsonSTRING, bsonSYMBOL : if PropInfosDictionary.TryGetValue(Source.key, p) then
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
              dynArrayElementInfo := GetTypeData(p.PropType^)^.elType2;
              //ClassType
              if (dynArrayElementInfo <> nil) and (dynArrayElementInfo^.Kind = tkClass) then
                DeserializeDynamicArrayOfObjects(p, ATarget, AContext) // it's array of objects
              else
              begin
                // it's array of primitives
                po := GetDynArrayProp(ATarget, p^.Name);
                if DynArrayDim(PDynArrayTypeInfo(p^.PropType^)) = 1 then
                begin
                  DeserializeVariantArray(p, v);
                  SafeDynArrayFromVariant(po, v, p^.PropType^);
                  SetDynArrayProp(ATarget, p, po);
                end
                else
                begin
                  DynArrayToVariant(v, po, p^.PropType^);
                  DeserializeVariantArray(p, v);
                  SafeDynArrayFromVariant(po, v, p^.PropType^);
                  SetDynArrayProp(ATarget, p, po);
                end;
              end;
            end;
            tkClass : DeserializeObject(p, ATarget, AContext);
          end;
        bsonOBJECT, bsonBINDATA : if p^.PropType^.Kind = tkClass then
          DeserializeObject(p, ATarget, AContext);
      end;
    end;
end;

procedure TPrimitivesBsonDeserializer.DeserializeObject(p: PPropInfo; ATarget: TObject; AContext:
    Pointer);
var
  c: TClass;
  o: TObject;
  MustAssignObjectProperty : boolean;
begin
  {$IFNDEF DELPHI2009}
  c := GetTypeData(p.PropType^)^.ClassType;
  {$ELSE}
  c := p.PropType^.TypeData.ClassType;
  {$ENDIF}
  o := GetObjectProp(ATarget, p);
  MustAssignObjectProperty := o = nil;
  DeserializeObject(c, o, Source, AContext);
  if MustAssignObjectProperty then
    SetObjectProp(ATarget, p, o);
end;

procedure TPrimitivesBsonDeserializer.DeserializeObject(AObjClass: TClass; var AObj: TObject;
  ASource: IBsonIterator; AContext: Pointer);
var
  Deserializer : TBaseBsonDeserializer;
  _Type : string;
begin
  Deserializer := CreateDeserializer(AObjClass);
  try
    if Source.Kind in [bsonOBJECT, bsonARRAY] then
      Deserializer.Source := ASource.subiterator
    else
      Deserializer.Source := ASource; // for bindata we need original BsonIterator to obtain binary handler
    if AObj = nil then
    begin
      if Source.key = SERIALIZED_ATTRIBUTE_ACTUALTYPE then
        begin
          _Type := Source.value;
          Source.next;
        end
        else
          _Type := Strip_T_FormClassName(AObjClass.ClassName);
      AObj := BuildObject(_Type, AContext);
    end;
    Deserializer.Deserialize(AObj, AContext);
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

procedure TPrimitivesBsonDeserializer.DeserializeDynamicArrayOfObjects(
  p: PPropInfo; var ATarget: TObject; AContext : Pointer);
var
  dynArrayElementInfo: PPTypeInfo;
  dynArrOfObjs: TObjectDynArray;
  I: Integer;
  it: IBsonIterator;
begin
  if Source.Kind <> bsonARRAY then
    Exit;

  dynArrayElementInfo := GetTypeData(p.PropType^)^.elType2;
  dynArrOfObjs := TObjectDynArray(GetDynArrayProp(ATarget, p));
  SetLength(dynArrOfObjs, 256);
  I := 0;
  it := Source.subiterator;
  while it.next and (it.Kind = bsonOBJECT) do
  begin
    if I > Length(dynArrOfObjs) then
      SetLength(dynArrOfObjs, I * 2);
    dynArrOfObjs[I] := GetTypeData(dynArrayElementInfo^)^.ClassType.Create;
    DeserializeObject(GetTypeData(dynArrayElementInfo^)^.ClassType,
                      dynArrOfObjs[I], it, AContext);
    Inc(I);
  end;
  SetLength(dynArrOfObjs, I);
  SetDynArrayProp(ATarget, p, dynArrOfObjs);
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

procedure TStringsBsonDeserializer.Deserialize(var ATarget: TObject; AContext: Pointer);
var
  AStrings : TStrings;
begin
  AStrings := ATarget as TStrings;
  while Source.next do
    AStrings.Add(Source.AsUTF8String);
end;

{ TPropInfosDictionary }

constructor TPropInfosDictionary.Create(APropList: PPropList);
begin
  inherited Create;
  FPropList := APropList;
end;

destructor TPropInfosDictionary.Destroy;
begin
  FreeMem(FPropList);
  inherited;
end;

{$IFNDEF DELPHIXE}
function TPropInfosDictionary.TryGetValue(const key: string; var APropInfo:
    PPropInfo): Boolean;
begin
  Result := Find(key, TObject(APropInfo));
end;
{$ENDIF}

{ TStreamBsonSerializer }

procedure TStreamBsonSerializer.Serialize(const AName: String; ASource:
    TObject);
var
  Stream : TStream;
  Data : Pointer;
begin
  Stream := ASource as TStream;
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

procedure TStreamBsonDeserializer.Deserialize(var ATarget: TObject; AContext: Pointer);
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

procedure TObjectAsStringListBsonSerializer.Serialize(const AName: String;
    ASource: TObject);
var
  i : integer;
  AList : TStrings;
begin
  Target.startObject(AName);
  AList := ASource as TStringList;
  for i := 0 to AList.Count - 1 do
    Target.append(AList.Names[i], AList.ValueFromIndex[i]);
  Target.finishObject;
end;

{ TObjectAsStringListBsonDeserializer }

procedure TObjectAsStringListBsonDeserializer.Deserialize(var ATarget: TObject;
    AContext: Pointer);
var
  AStrings : TStrings;
begin
  AStrings := ATarget as TStrings;
  while Source.next do
    AStrings.Add(Source.key + '=' + Source.AsUTF8String);
end;

procedure RegisterBuildableSerializableClass(const AClassName : string;
    ABuilderFunction : TObjectBuilderFunction);
var
  BuilderFunctionAsPointer : pointer absolute ABuilderFunction;
begin
  BuilderFunctions.Add(Strip_T_FormClassName(AClassName), {$IFNDEF DELPHIXE}TObject({$ENDIF}BuilderFunctionAsPointer{$IFNDEF DELPHIXE}){$ENDIF});
end;

procedure UnregisterBuildableSerializableClass(const AClassName : string);
begin
  {$IFNDEF DELPHIXE}
  BuilderFunctions.Delete(Strip_T_FormClassName(AClassName));
  {$ELSE}
  BuilderFunctions.Remove(Strip_T_FormClassName(AClassName));
  {$ENDIF}
end;

{$IFNDEF DELPHIXE}
{ TBuilderFunctionsDictionary }

function TBuilderFunctionsDictionary.TryGetValue(const key: string; var
    ABuilderFunction: TObjectBuilderFunction): Boolean;
var
  ABuilderFunctionAsObject : TObject absolute ABuilderFunction;
begin
  Result := Find(key, ABuilderFunctionAsObject);
end;

{ TClassPropInfoDictionaryDictionary }

function TClassPropInfoDictionaryDictionary.TryGetValue(key: TClass; var
    APropInfoDictionary: TPropInfosDictionary): Boolean;
begin
  Result := Find(integer(key), TObject(APropInfoDictionary));
end;
{$ENDIF}

procedure DestroyPropInfosDictionaryCache;
var
  i : integer;
  {$IFDEF DELPHIXE}
  PropInfosDictionary : TPropInfosDictionary;
  {$ENDIF}
begin
  for i := 0 to PropInfosDictionaryCacheTrackingList.Count - 1 do
    begin
      {$IFDEF DELPHIXE}
      for PropInfosDictionary in TClassPropInfoDictionaryDictionary(PropInfosDictionaryCacheTrackingList[i]).Values do
        PropInfosDictionary.Free;
      {$ENDIF}
      TClassPropInfoDictionaryDictionary(PropInfosDictionaryCacheTrackingList[i]).Free;
    end;
end;

initialization
  PropInfosDictionaryCacheTrackingListLock := TCriticalSection.Create;
  PropInfosDictionaryCacheTrackingList := TList.Create;
  BuilderFunctions := TBuilderFunctionsDictionary.Create;
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
  DestroyPropInfosDictionaryCache;
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
  BuilderFunctions.Free;
  PropInfosDictionaryCacheTrackingList.Free;
  PropInfosDictionaryCacheTrackingListLock.Free;
end.

