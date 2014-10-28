{
     Copyright 2009-2011 10gen Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
}

{ Use define OnDemandMongoCLoad if you want the MongoC.dll library to be loaded dynamically
  upon InitMongoDBLibrary call }

{ This unit implements BSON, a binary JSON-like document format.
  It is used to represent documents in MongoDB and also for network traffic.
  See http://www.mongodb.org/display/DOCS/BSON }

unit MongoBson;

{$I MongoC_defines.inc}

interface

uses
  uPrimitiveAllocator, SysUtils, Windows, uDelphi5;

const
  E_WasNotExpectingCloseOfObjectOper    = 90100;
  E_DefMustContainAMinimumOfTwoElements = 90101;
  E_DatatypeNotSupportedToBuildBSON     = 90102;
  E_ExpectedDefElementShouldBeAString   = 90103;
  E_IteratorHandleIsNil                 = 90104;  // deprecated
  E_TBsonHandleIsNil                    = 90105;  // deprecated
  {$IFNDEF DELPHI2007}
  E_CanTAccessAnInt64UsingAVariantOn    = 90106;
  {$ENDIF}
  E_DatatypeNotSupported                = 90107;
  E_ExpectedA24DigitHexString           = 90108;
  E_NotSupportedByTBsonIteratorValue    = 90109;
  E_IteratorDoesNotPointToAnArray       = 90110;
  E_ArrayComponentIsNotAnInteger        = 90111;
  E_ArrayComponentIsNotADouble          = 90112;
  E_ArrayComponentIsNotAString          = 90113;
  E_ArrayComponentIsNotABoolean         = 90114;
  E_BsonBufferAlreadyFinished           = 90115;  // deprecated
  E_TBsonAppendVariantTypeNotSupport    = 90116;
  E_ErrorCallingIteratorAtEnd           = 90117;  // deprecated
  E_WasNotExpectingCloseOfArrayOperator = 90118;
  E_BSONUnexpected                      = 90119;
  E_BSONExpectedValueFor                = 90120;
  E_BSONOpenSubobject                   = 90121;
  E_NilInterfacePointerNotSupported     = 90122;
  E_BSONArrayDefinitionFinishedTooEarly = 90123;
  E_FAILED_TO_INIT_BSON_FROM_DATA = 90124;

type
  IBsonIterator = interface;
  IBson = interface;
  TIntegerArray = array of Integer;
  TDoubleArray  = array of Double;
  TBooleanArray = array of Boolean;
  TStringArray  = array of UTF8String;
  TVarRecArray = array of TVarRec;

  TBsonType = (BSON_TYPE_EOD,
   BSON_TYPE_DOUBLE,
   BSON_TYPE_UTF8,
   BSON_TYPE_DOCUMENT,
   BSON_TYPE_ARRAY,
   BSON_TYPE_BINARY,
   BSON_TYPE_UNDEFINED,
   BSON_TYPE_OID,
   BSON_TYPE_BOOL,
   BSON_TYPE_DATE_TIME,
   BSON_TYPE_NULL,
   BSON_TYPE_REGEX,
   BSON_TYPE_DBPOINTER,
   BSON_TYPE_CODE,
   BSON_TYPE_SYMBOL,
   BSON_TYPE_CODEWSCOPE,
   BSON_TYPE_INT32,
   BSON_TYPE_TIMESTAMP,
   BSON_TYPE_INT64,
   BSON_TYPE_MAXKEY,
   BSON_TYPE_MINKEY);

   PBsonSubtype = ^TBsonSubtype;
   TBsonSubtype = (BSON_SUBTYPE_BINARY,
     BSON_SUBTYPE_FUNCTION,
     BSON_SUBTYPE_BINARY_DEPRECATED,
     BSON_SUBTYPE_UUID_DEPRECATED,
     BSON_SUBTYPE_UUID,
     BSON_SUBTYPE_MD5,
     BSON_SUBTYPE_USER
   );

  EBson = class(Exception)
  private
    FErrorCode: Integer;
  public
    constructor Create(const AMsg: string; ACode: Integer); overload;
    constructor Create(const AMsg, AStrParam: string; ACode: Integer); overload;
    property ErrorCode: Integer read FErrorCode;
  end;

  TBsonOIDBytes = array[0..11] of Byte;
  PBsonOIDBytes = ^TBsonOIDBytes;
  TBsonOIDString = array[0..24] of AnsiChar;
  { A TBsonOID is used to store BSON Object IDs.
    See http://www.mongodb.org/display/DOCS/Object+IDs }
  IBsonOID = interface
    ['{9DFE3466-DCB0-421F-92A9-F7C4209161C9}']
    procedure setValue(const AValue: PBsonOIDBytes);
    function getValue: PBsonOIDBytes;
    { Convert this Object ID to a 24-digit hex string }
    function asString: UTF8String;
    { the oid data }
    property Value : PBsonOIDBytes read getValue write setValue;
  end;

  IOidGenerator = interface
    ['{2422BA01-8210-4547-BE66-1EB42CA71F4A}']
    function getHandle : Pointer; // This could return nil if no DLL provided generator
    procedure gen(oid : IBsonOID);
    property Handle : Pointer read getHandle;
  end;

  { A TBsonCodeWScope is used to hold javascript code and its associated scope.
    See TBsonIterator.getCodeWScope() }
  IBsonCodeWScope = interface
    ['{4AD5B260-B47D-4F05-AB12-8FB8A11D604F}']
    function getCode: UTF8String;
    function getScope: IBson;
    procedure setCode(const ACode: UTF8String);
    procedure setScope(AScope: IBson);
    property Code : UTF8String read getCode write setCode;
    property Scope : IBson read getScope write setScope;
  end;

  { A TBsonRegex is used to hold a regular expression string and its options.
    See TBsonIterator.getRegex(). }
  IBsonRegex = interface
    ['{2EA7E5BB-66F0-4FCA-B3BD-87FD2738C23C}']
    function getPattern: UTF8String;
    function getOptions: UTF8String;
    procedure setPattern(const APattern: UTF8String);
    procedure setOptions(const AOptions: UTF8String);
    property Pattern : UTF8String read getPattern write setPattern;
    property Options : UTF8String read getOptions write setOptions;
  end;

  { A TBsonTimestamp is used to hold a TDateTime and an increment value.
    See http://www.mongodb.org/display/DOCS/Timestamp+data+type and
    TBsonIterator.getTimestamp() }
  IBsonTimestamp = interface
    ['{06802587-D513-4797-9613-08F66E2692EA}']
    function getTime: LongWord;
    function getIncrement: LongWord;
    procedure setTime(ATime: LongWord);
    procedure setIncrement(AIncrement: LongWord);
    property Time : LongWord read getTime write setTime;
    property Increment : LongWord read getIncrement write setIncrement;
  end;

  { A TBsonBinary is used to hold the contents of BINDATA fields.
    See TBsonIterator.getBinary() }
  IBsonBinary = interface
    ['{16F18439-48F8-426F-AF06-B4229DC9041A}']
    function getData: PByte;
    function getLen: LongWord;
    function getKind: TBsonSubtype;
    procedure setData(AData: PByte; ALen: LongWord);
    procedure setKind(AKind: TBsonSubtype);
    { Pointer to the data }
    property Data : PByte read getData;
    { The length of the data in bytes }
    property Len : LongWord read getLen;
    { The subtype of the BINDATA (usually 0) }
    property Kind : TBsonSubtype read getKind write setKind;
  end;

  { A TBsonBuffer is used to build a BSON document by appending the
    names and values of fields.  Call finish() when done to convert
    the buffer to a TBson which can be used in database operations.
    Example: @longcode(#
      var
        bb : TBsonBuffer;
        b  : TBson;
      begin
        bb := TBsonBuffer.Create();
        bb.append('name', 'Joe');
        bb.append('age', 33);
        bb.append('city', 'Boston');
        b := bb.finish();
      end;
    #) }
  IBsonBuffer = interface
    ['{9137CDF4-36DA-4D0D-A6F2-7F7620A49894}']
    { append a string (UTF8String) to the buffer }
    {$IFDEF DELPHI2009}
    function append(const Name, Value: UTF8String): Boolean; overload;
    {$ENDIF}
    function appendStr(const Name, Value: UTF8String): Boolean;
    { append an Integer to the buffer }
    function append(const Name: UTF8String; Value: LongInt): Boolean; overload;
    { append an Int64 to the buffer }
    function append(const Name: UTF8String; Value: Int64): Boolean; overload;
    { append a Double to the buffer }
    function append(const Name: UTF8String; Value: Double): Boolean; overload;
    { append a TDateTime to the buffer; converted to 64-bit POSIX time }
    {$IFDEF DELPHI2009}
    function append(const Name: UTF8String; Value: TDateTime): Boolean; overload;
    {$ENDIF}
    function appendDate(const Name: UTF8String; Value: TDateTime): Boolean;
    { append a Boolean to the buffer }
    function append(const Name: UTF8String; Value: Boolean): Boolean; overload;
    { append an Object ID to the buffer }
    function append(const Name: UTF8String; Value: IBsonOID): Boolean; overload;
    { append a CODEWSCOPE to the buffer }
    function append(const Name: UTF8String; Value: IBsonCodeWScope): Boolean;
        overload;
    { append a REGEX to the buffer }
    function append(const Name: UTF8String; Value: IBsonRegex): Boolean; overload;
    { append a TIMESTAMP to the buffer }
    function append(const Name: UTF8String; Value: IBsonTimestamp): Boolean;
        overload;
    { append BINDATA to the buffer }
    function append(const Name: UTF8String; Value: IBsonBinary): Boolean; overload;
    { append a TBson document as a subobject }
    function append(const Name: UTF8String; Value: IBson): Boolean; overload;
    { Generic version of append.  Calls one of the other append functions
      if the type contained in the variant is supported. }
    {$IFDEF DELPHI2007}
    function append(const Name: UTF8String; const Value: Variant): Boolean;
        overload;
    {$ENDIF}
    function appendVariant(const Name: UTF8String; const Value: Variant): Boolean;
    { append an array of Integers }
    function appendArray(const Name: UTF8String; const Value: TIntegerArray):
        Boolean; overload;
    { append an array of Double }
    function appendArray(const Name: UTF8String; const Value: TDoubleArray):
        Boolean; overload;
    { append an array of Booleans }
    function appendArray(const Name: UTF8String; const Value: TBooleanArray):
        Boolean; overload;
    { append an array of strings }
    function appendArray(const Name: UTF8String; const Value: TStringArray):
        Boolean; overload;
    { append a NULL field to the buffer }
    function appendNull(const Name: UTF8String): Boolean;
    { append an UNDEFINED field to the buffer }
    function appendUndefined(const Name: UTF8String): Boolean;
    { append javascript code to the buffer }
    function appendCode(const Name, Value: UTF8String): Boolean;
    function appendCodeWithScope(const Name, Value: UTF8String; const scope: IBson): Boolean;
     { append a SYMBOL to the buffer }
    function appendSymbol(const Name, Value: UTF8String): Boolean;
    { Alternate way to append BINDATA directly without first creating a
      TBsonBinary value }
    function appendBinary(const Name: UTF8String; Kind: TBsonSubtype; const Data: PByte;
      Length: LongWord): Boolean;
    { append javascript code to the buffer from PChar Value up to Len chars }
    function appendCode_n(const Name, Value: UTF8String; Len: Cardinal): Boolean;
    { Appends a string up to Len chars }
    function appendStr_n(const Name, Value: UTF8String; Len: Cardinal): Boolean;
    { append a SYMBOL to the buffer up to Len chars }
    function appendSymbol_n(const Name, Value: UTF8String; Len: Cardinal): Boolean;
    { Indicate that you will be appending more fields as a subobject }
    function startObject(const Name: UTF8String): Boolean;
    { Indicate that a subobject or array is done. }
    function finishObject: Boolean;
    { Indicate that you will be appending more fields as an array }
    function startArray(const Name: UTF8String): Boolean;
    { Indicate that a subobject or array is done. }
    function finishArray: Boolean;
    { Appends elements defined as an array of TVarRec }
    function appendElementsAsArray(const def : TVarRecArray): boolean; overload;
    { Appends elements defined as an array of const }
    function appendElementsAsArray(const def: array of const): boolean; overload;
    { Appends an object defined as an array of TVarRec }
    function appendObjectAsArray(const ObjectName: UTF8String; const def:
        TVarRecArray): boolean;
    { Return the current size of the BSON document you are building }
    function size: LongWord;
    { Call this when finished appending fields to the buffer to turn it into
      a TBson for network transport. }
    function finish: IBson;
  end;

  { TBsonIterators are used to step through the fields of a TBson document. }
  IBsonIterator = interface
    ['{BB81B815-9B18-43B7-A894-2FBE4F9B7562}']
    function getHandle: Pointer;
    function key: UTF8String;
    function Kind: TBsonType;
    function Find(const Name: UTF8String): Boolean;
    { Step to the first or next field of a TBson document.  Returns True
    if there is a next field; otherwise, returns false at the end of the
    document (or subobject).
    Example: @longcode(#
      iter := b.iterator;
      while i.next() do
         if i.kind = bsonNULL then
            WriteLn(i.key, ' is a NULL field.');
    #) }
    function next: Boolean;
    { Get an TBsonIterator pointing to the first field of a subobject or array.
      kind() must be bsonOBJECT or bsonARRAY. }
    function subiterator: IBsonIterator;

    function GetAsInt64: Int64;
    function GetAsUTF8String : UTF8String;
    function GetAsInteger: LongInt;
    function GetAsDouble: Double;
    function GetAsDateTime: TDateTime;
    function GetAsBoolean: Boolean;
    function GetAsCode: UTF8String;
    function GetAsCodeWScope: IBsonCodeWScope;
    function GetAsSymbol: UTF8String;
    function GetAsBinary: IBsonBinary;
    function GetAsOID: IBsonOID;
    function GetAsRegex: IBsonRegex;
    function GetAsTimestamp: IBsonTimestamp;
    { Get the value of the field pointed to by this iterator.  This function
      does not support all BSON field types and will throw an exception for
      those it does not.  Use one of the 'get' functions to extract one of these
      special types. }
    function GetAsVariant: Variant;

    function AsBooleanArray: TBooleanArray;
    function AsDoubleArray: TDoubleArray;
    function AsIntegerArray: TIntegerArray;
    function AsStringArray: TStringArray;

    { Pointer to externally managed data. }
    property Handle : Pointer read getHandle;

    property AsInt64: Int64 read GetAsInt64;
    property AsUTF8String : UTF8String read GetAsUTF8String;
    property AsInteger: LongInt read GetAsInteger;
    property AsDouble: Double read GetAsDouble;
    property AsDateTime: TDateTime read GetAsDateTime;
    property AsBoolean: Boolean read GetAsBoolean;
    property AsCode: UTF8String read GetAsCode;
    property AsCodeWScope: IBsonCodeWScope read GetAsCodeWScope;
    property AsSymbol: UTF8String read GetAsSymbol;
    property AsBinary: IBsonBinary read GetAsBinary;
    property AsOID: IBsonOID read GetAsOID;
    property AsRegex: IBsonRegex read GetAsRegex;
    property AsTimestamp: IBsonTimestamp read GetAsTimestamp;
    property Value: Variant read GetAsVariant;
  end;

  { A TBson holds a BSON document.  BSON is a binary, JSON-like document format.
    It is used to represent documents in MongoDB and also for network traffic.
    See http://www.mongodb.org/display/DOCS/BSON   }
  IBson = interface
    ['{797F38B2-7659-46C7-9FD7-0F7EF81063CE}']
    { Get a TBsonIterator that points to the field with the given name.
      If name is not found, nil is returned. }
    function find(const Name: UTF8String): IBsonIterator;
    { Get a TBsonIterator that points to the first field of this BSON }
    function iterator: IBsonIterator;
    { Return the size of this BSON document in bytes }
    function size: LongWord;
    { Get the value of a field given its name.  This function does not support
      all BSON field types.  Use find() and one of the 'get' functions of
      TBsonIterator to retrieve special values. }
    function value(const Name: UTF8String): Variant;
    function valueAsInt64(const Name: UTF8String): Int64;
    function asJson : UTF8String;
    function getData: PByte;
    { Pointer to bson data }
    property Data : PByte read getData;
  end;

function MkIntArray(const Arr : array of Integer): TIntegerArray;
function MkDoubleArray(const Arr : array of Double): TDoubleArray;
function MkBoolArray(const Arr : array of Boolean): TBooleanArray;
function MkStrArray(const Arr : array of UTF8String): TStringArray;
function MkVarRecArray(const Arr : array of const): TVarRecArray;

// IMPORTANT: When using MkBSONVarRecArrayFromVarArray developer MUST USE CleanVarRecArray to deallocate dynamically allocated string types
function MkBSONVarRecArrayFromVarArray(const Arr : array of Variant; Allocator : IPrimitiveAllocator) : TVarRecArray;
procedure CleanVarRecArray(const Arr: TVarRecArray);

procedure AppendToIntArray(const Arr : array of Integer; var TargetArray : TIntegerArray; FromIndex : Cardinal = 0);
procedure AppendToDoubleArray(const Arr : array of Double; var TargetArray : TDoubleArray; FromIndex : Cardinal = 0);
procedure AppendToBoolArray(const Arr : array of Boolean; var TargetArray : TBooleanArray; FromIndex : Cardinal = 0);
procedure AppendToStrArray(const Arr : array of UTF8String; var TargetArray : TStringArray; FromIndex : Cardinal = 0);
procedure AppendToVarRecArray(const Arr : array of const; var TargetArray : TVarRecArray; FromIndex : Cardinal = 0);

(* The idea for this shorthand way to build a BSON
   document from an array of variants came from Stijn Sanders
   and his TMongoWire, located here:
   https://github.com/stijnsanders/TMongoWire

   Subobjects are started with '{' and ended with '}'

   Example: @longcode(#
     var b : TBson;
     begin
       b := BSON(['name', 'Albert', 'age', 64,
                   'address', '{',
                      'street', '109 Vine Street',
                      'city', 'New Haven',
                      '}' ]);
#) *)

function BSON(const x: array of Variant): IBson;

{ Create an empty TBsonBuffer ready to have fields appended }
function NewBsonBuffer: IBsonBuffer;

{ Create a TBsonBinary from a pointer and a length.  The data
  is copied to the heap.  kind is initialized to 0 }
function NewBsonBinary(p: Pointer; Length: Integer): IBsonBinary; overload;
{ Create a TBsonBinary from a TBsonIterator pointing to a BINDATA
  field. }
function NewBsonBinary(i: IBsonIterator): IBsonBinary; overload;

{ Create a TBsonCodeWScope from a javascript string and a TBson scope }
function NewBsonCodeWScope(const acode: UTF8String; ascope: IBson): IBsonCodeWScope; overload;
{ Create a TBsonCodeWScope from a TBSonIterator pointing to a
  CODEWSCOPE field. }
function NewBsonCodeWScope(i: IBsonIterator): IBsonCodeWScope; overload;

{ Generate an Object ID. }
function NewBsonOID: IBsonOID; overload;
{ Create an ObjectID from a 24-digit hex string }
function NewBsonOID(const s : UTF8String): IBsonOID; overload;
{ Create an Object ID from a TBsonIterator pointing to an oid field }
function NewBsonOID(i : IBsonIterator): IBsonOID; overload;
{ Create a Bson OID as a copy }
function NewBsonOID(oid : IBsonOID): IBsonOID; overload;

{ Create a TBsonRegex from reqular expression and options strings }
function NewBsonRegex(const apattern, aoptions: UTF8String): IBsonRegex; overload;
{ Create a TBsonRegex from a TBsonIterator pointing to a REGEX field }
function NewBsonRegex(i : IBsonIterator): IBsonRegex; overload;

{ Create a TBsonTimestamp from a TDateTime and an increment }
function NewBsonTimestamp(atime, aincrement: LongWord): IBsonTimestamp; overload;
{ Create a TBSonTimestamp from a TBsonIterator pointing to a TIMESTAMP
  field. }
function NewBsonTimestamp(i : IBsonIterator): IBsonTimestamp; overload;

function NewBson(const json: UTF8String): IBson; overload;
function NewBson(const AData: PByte; len: Cardinal): IBson; overload;
function NewBsonCopy(const b: IBson): IBson;

{$IFDEF DELPHIXE2}
function Pos(const SubStr, Str: UTF8String): Integer;
function IntToStr(i : integer) : UTF8String;
{$ENDIF}

{ Convert a byte to a 2-digit hex string }
function ByteToHex(InByte: Byte): UTF8String;
function bsonEmpty: IBson;

function Start_Object: TObject;
function End_Object: TObject;
function Start_Array: TObject;
function End_Array: TObject;
function Null_Element : TObject;

implementation

uses
  {$IFNDEF VER130}Variants,{$ENDIF}
  LibBsonApi, uStack, Contnrs, Dialogs, DateUtils;

// START resource string wizard section
resourcestring
  SFailedCreatingBSONFromJSON = 'Failed creating BSON from JSON. Message: [%s], Domain: (%d), ErrorCode: (%d)';
  SBSONArrayDefinitionFinishedTooEarly = 'BSON array definition finished too early';
  SDatatypeNotSupportedCallingMkVarRecArrayVarArray = 'Datatype not supported calling MkVarRecArrayFromVarArray (D%d)';
  SNilInterfacePointerNotSupported = 'Nil interface pointer not supported (D%d)';
  SWasNotExpectingCloseOfArrayOperator = 'Was not expecting close of array operator (D%d)';
  SErrorCallingIteratorAtEnd = 'Error calling %s. Iterator at end (D%d)';
  SWasNotExpectingCloseOfObjectOper = 'Was not expecting close of object operator (D%d)';
  SDefMustContainAMinimumOfTwoElements = 'def must contain a minimum of two entries (D%d)';
  SDatatypeNotSupportedToBuildBSON = 'Datatype not supported to build BSON definition (D%d)';
  SExpectedDefElementShouldBeAString = 'Expected def element should be a string (D%d)';
  SIteratorHandleIsNil = 'Iterator Handle is nil (D%d)';
  STBsonHandleIsNil = 'TBson handle is nil (D%d)';
  {$IFNDEF DELPHI2007}
  SCanTAccessAnInt64UsingAVariantOn = 'Can''t access an Int64 using a variant on old version of Delphi. Use AsInt64 instead (D%d)';
  {$ENDIF}
  SDatatypeNotSupported = 'Datatype not supported calling IterateAndFillArray (D%d)';
  SExpectedA24DigitHexString = 'Expected a 24 digit hex string (D%d)';
  SNotSupportedByTBsonIteratorValue = 'BsonType (%s) not supported by TBsonIterator.value (D%d)';
  SIteratorDoesNotPointToAnArray = 'Iterator does not point to an array (D%d)';
  SArrayComponentIsNotAnInteger = 'Array component is not an Integer (D%d)';
  SArrayComponentIsNotADouble = 'Array component is not a Double (D%d)';
  SArrayComponentIsNotAString = 'Array component is not a string (D%d)';
  SArrayComponentIsNotABoolean = 'Array component is not a Boolean (D%d)';
  STBsonAppendVariantTypeNotSupport = 'TBson.append(variant): type not supported (%s) (D%d)';
  SUNDEFINED = 'UNDEFINED';
  SNULL = 'NULL';
  SCODEWSCOPE = 'CODEWSCOPE ';
  SBINARY = 'BINARY (';
  SUNKNOWN = 'UNKNOWN';
  SNilBSON = 'nil BSON';
  S_FAILED_TO_INIT_BSON_FROM_DATA = 'Failed to init bson from data buffer, seems it''s invalid';
// END resource string wizard section

type
  {$IFNDEF DELPHI2007}
  IInterface = IUnknown;
  {$ENDIF}

  TBsonOID = class(TInterfacedObject, IBsonOID)
  private
    FValue: TBsonOIDBytes;
    function getValue: PBsonOIDBytes;
    procedure setValue(const AValue: PBsonOIDBytes);
  public
    constructor Create; overload;
    constructor Create(const s: UTF8String); overload;
    constructor Create(i: IBsonIterator); overload;
    constructor Create(oid: IBsonOID); overload;
    function asString: UTF8String;
  end;

  TBsonBinary = class(TInterfacedObject, IBsonBinary)
  private
    Data: PByte;
    Len: LongWord;
    Kind: TBsonSubtype;
  public
    constructor Create(p: PByte; Length: LongWord); overload;
    constructor Create(i: IBsonIterator); overload;
    destructor Destroy; override;
    function getData: PByte;
    function getKind: TBsonSubtype;
    function getLen: LongWord;
    procedure setData(AData: PByte; ALen: LongWord);
    procedure setKind(AKind: TBsonSubtype);
  end;

  TBsonIterator = class(TInterfacedObject, IBsonIterator)
  private
    FNativeIter: bson_iter_t;
    procedure iterateAndFillArray(i: IBsonIterator; var Result; var j: Integer;
        BSonType: TBsonType);
    procedure prepareArrayIterator(var i: IBsonIterator; var j, count: Integer;
        BSonType: TBsonType; const ATypeErrorMsg: UTF8String);
  public
    constructor Create(const it: bson_iter_t);
    function Find(const Name: UTF8String): Boolean;
    function getHandle: Pointer;
    function kind: TBsonType;
    function key: UTF8String;
    function next: Boolean;
    function GetAsVariant: Variant;
    function subiterator: IBsonIterator;
    function getAsInt64: Int64;
    function GetAsUTF8String: UTF8String;
    function GetAsInteger: LongInt;
    function GetAsDouble: Double;
    function GetAsDateTime: TDateTime;
    function GetAsBoolean: Boolean;
    function GetAsCode: UTF8String;
    function GetAsSymbol: UTF8String;
    function GetAsOID: IBsonOID;
    function GetAsCodeWScope: IBsonCodeWScope;
    function GetAsRegex: IBsonRegex;
    function GetAsTimestamp: IBsonTimestamp;
    function GetAsBinary: IBsonBinary;
    function AsIntegerArray: TIntegerArray;
    function AsDoubleArray: TDoubleArray;
    function AsStringArray: TStringArray;
    function AsBooleanArray: TBooleanArray;
  end;

  TBsonCodeWScope = class(TInterfacedObject, IBsonCodeWScope)
  private
    code: UTF8String;
    scope: IBson;
  public
    constructor Create(const acode: UTF8String; ascope: IBson); overload;
    constructor Create(i: IBsonIterator); overload;
    function getCode: UTF8String;
    function getScope: IBson;
    procedure setCode(const ACode: UTF8String);
    procedure setScope(AScope: IBson);
  end;

  TBsonRegex = class(TInterfacedObject, IBsonRegex)
  private
    pattern: UTF8String;
    options: UTF8String;
  public
    constructor Create(const apattern, aoptions: UTF8String); overload;
    constructor Create(i: IBsonIterator); overload;
    function getOptions: UTF8String;
    function getPattern: UTF8String;
    procedure setOptions(const AOptions: UTF8String);
    procedure setPattern(const APattern: UTF8String);
  end;

  TBsonTimestamp = class(TInterfacedObject, IBsonTimestamp)
  private
    FTimestamp, FIncrement: LongWord;
  public
    constructor Create(atimestamp, aincrement: LongWord); overload;
    constructor Create(i: IBsonIterator); overload;
    function getIncrement: LongWord;
    function getTime: LongWord;
    procedure setIncrement(AIncrement: LongWord);
    procedure setTime(ATime: LongWord);
  end;

  TBsonBuffer = class(TInterfacedObject, IBsonBuffer)
  private
    FNativeBson: bson_t;
    FSubNativeBson: TStack; // we keep here subdocuments and arrays
    function appendIntCallback(i: Integer; const Arr): Boolean;
    function appendDoubleCallback(i: Integer; const Arr): Boolean;
    function appendBooleanCallback(i: Integer; const Arr): Boolean;
    function appendStringCallback(i: Integer; const Arr): Boolean;
    function internalAppendArray(const Name: UTF8String; const Arr; Len: Integer;
        AppendElementCallback: Pointer): Boolean;
    class function UTF8StringFromTVarRec(const AVarRec: TVarRec): UTF8String;
    function GetCurrNativeBson: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    {$IFDEF DELPHI2009}
    function append(const Name, Value: UTF8String): Boolean; overload;
    {$EndIf}
    function appendStr(const Name, Value: UTF8String): Boolean;
    function append(const Name: UTF8String; Value: LongInt): Boolean; overload;
    function append(const Name: UTF8String; Value: Int64): Boolean; overload;
    function append(const Name: UTF8String; Value: Double): Boolean; overload;
    {$IFDEF DELPHI2009}
    function append(const Name: UTF8String; Value: TDateTime): Boolean; overload;
    {$ENDIF}
    function appendDate(const Name: UTF8String; Value: TDateTime): Boolean;
    function append(const Name: UTF8String; Value: Boolean): Boolean; overload;
    function append(const Name: UTF8String; Value: IBsonOID): Boolean; overload;
    function append(const Name: UTF8String; Value: IBsonCodeWScope): Boolean;
        overload;
    function append(const Name: UTF8String; Value: IBsonRegex): Boolean; overload;
    function append(const Name: UTF8String; Value: IBsonTimestamp): Boolean;
        overload;
    function append(const Name: UTF8String; Value: IBsonBinary): Boolean; overload;
    function append(const Name: UTF8String; Value: IBson): Boolean; overload;
    {$IFDEF DELPHI2007}
    function append(const Name: UTF8String; const Value: Variant): Boolean;
        overload;
    {$ENDIF}
    function appendVariant(const Name: UTF8String; const Value: Variant): Boolean;
    function appendArray(const Name: UTF8String; const Value: TIntegerArray):
        Boolean; overload;
    function appendArray(const Name: UTF8String; const Value: TDoubleArray):
        Boolean; overload;
    function appendArray(const Name: UTF8String; const Value: TBooleanArray):
        Boolean; overload;
    function appendArray(const Name: UTF8String; const Value: TStringArray):
        Boolean; overload;
    function appendNull(const Name: UTF8String): Boolean;
    function appendUndefined(const Name: UTF8String): Boolean;
    function appendCode(const Name, Value: UTF8String): Boolean;
    function appendCodeWithScope(const Name, Value: UTF8String; const scope: IBson): Boolean;
    function appendSymbol(const Name, Value: UTF8String): Boolean;
    function appendBinary(const Name: UTF8String; Kind: TBsonSubtype; const Data: PByte; Length: LongWord): Boolean;
    function startObject(const Name: UTF8String): Boolean;
    function finishObject: Boolean;
    function startArray(const Name: UTF8String): Boolean;
    function finishArray: Boolean;
    function size: LongWord;
    function finish: IBson;
    function appendObjectAsArray(const ObjectNAme: UTF8String; const def:
        TVarRecArray): boolean;
    function appendElementsAsArray(const def : TVarRecArray): boolean; overload;
    function appendCode_n(const Name, Value: UTF8String; Len: Cardinal): Boolean;
    function appendElementsAsArray(const def: array of const): boolean; overload;
    function appendStr_n(const Name, Value: UTF8String; Len: Cardinal): Boolean;
    function appendSymbol_n(const Name, Value: UTF8String; Len: Cardinal): Boolean;
  end;

  TBson = class(TInterfacedObject, IBson)
  private
    FNativeBson: bson_t;
  public
    constructor Create(const bson: bson_t); overload;
    constructor Create(const AData: PByte; len: Cardinal); overload;
    constructor Create(json: UTF8String); overload;
    constructor Create(const b: IBson); overload;
    destructor Destroy; override;
    function getData: PByte;
    function size: LongWord;
    function iterator: IBsonIterator;
    function find(const Name: UTF8String): IBsonIterator;
    function value(const Name: UTF8String): Variant;
    function valueAsInt64(const Name: UTF8String): Int64;
    function asJson: UTF8String;
  end;

var
  AStart_Object : TObject;
  AEnd_Object : TObject;
  AStart_Array : TObject;
  AEnd_Array : TObject;
  ANull_Element : TObject;
  ADefaultOidGenerator : IOidGenerator;

{$IFDEF DELPHIXE2}
function Pos(const SubStr, Str: UTF8String): Integer;
begin
  Result := System.Pos(String(SubStr), String(Str));
end;

function IntToStr(i : integer) : UTF8String;
begin
  Result := UTF8String(SysUtils.IntToStr(i));
end;
{$ENDIF}

{ EBson }

constructor EBson.Create(const AMsg: string; ACode: Integer);
begin
  inherited CreateFmt(AMsg, [ACode]);
  FErrorCode := ACode;
end;

constructor EBson.Create(const AMsg, AStrParam: string; ACode: Integer);
begin
  inherited CreateFmt(AMsg, [AStrParam, ACode]);
  FErrorCode := ACode;
end;

{ TBsonOID }

constructor TBsonOID.Create;
begin
  inherited Create;
  bson_oid_init(@FValue, nil);
end;

constructor TBsonOID.Create(const s: UTF8String);
begin
  inherited Create;
  if Length(s) <> 24 then
    raise Exception.Create(SExpectedA24DigitHexString);
  bson_oid_init_from_string(@FValue, PAnsiChar(s));
end;

constructor TBsonOID.Create(i: IBsonIterator);
begin
  inherited Create;
  FValue := TBsonOIDBytes(bson_iter_oid(i.getHandle)^);
end;

constructor TBsonOID.Create(oid: IBsonOID);
begin
  inherited Create;
  FValue := oid.Value^;
end;

function TBsonOID.asString: UTF8String;
var
  buf: TBsonOIDString;
begin
  bson_oid_to_string(PBsonOIDBytes(@FValue), @buf);
  Result := UTF8String(buf);
end;

function TBsonOID.getValue: PBsonOIDBytes;
begin
  Result := @FValue;
end;

procedure TBsonOID.setValue(const AValue: PBsonOIDBytes);
begin
  FValue := AValue^;
end;

{ TBsonIterator }

constructor TBsonIterator.Create(const it: bson_iter_t);
begin
  inherited Create;
  FNativeIter := it;
end;

function TBsonIterator.Find(const Name: UTF8String): Boolean;
begin
  while next do
    if key = Name then
    begin
      Result := true;
      Exit;
    end;
  Result := false;
end;

function TBsonIterator.getAsInt64: Int64;
begin
  Result := bson_iter_int64(@FNativeIter);
end;

function TBsonIterator.GetAsUTF8String: UTF8String;
begin
  Result := UTF8String(bson_iter_utf8(@FNativeIter, 0));
end;

function TBsonIterator.GetAsInteger: LongInt;
begin
  Result := bson_iter_int32(@FNativeIter);
end;

function TBsonIterator.GetAsDouble: Double;
begin
  Result := bson_iter_double(@FNativeIter);
end;

function TBsonIterator.GetAsDateTime: TDateTime;
begin
  Result := UnixToDateTime(bson_iter_date_time(@FNativeIter))
end;

function TBsonIterator.GetAsBoolean: Boolean;
begin
  Result := bson_iter_bool(@FNativeIter);
end;

function TBsonIterator.GetAsCode: UTF8String;
begin
  Result := UTF8String(bson_iter_code(@FNativeIter, nil));
end;

function TBsonIterator.GetAsSymbol: UTF8String;
begin
  Result := UTF8String(bson_iter_symbol(@FNativeIter, nil));
end;

function TBsonIterator.kind: TBsonType;
begin
  Result := TBsonType(bson_iter_type(@FNativeIter));
end;

function TBsonIterator.next: Boolean;
begin
  Result := bson_iter_next(@FNativeIter);
end;

function TBsonIterator.key: UTF8String;
begin
  Result := UTF8String(bson_iter_key(@FNativeIter));
end;

function TBsonIterator.GetAsVariant: Variant;
begin
  case kind of
    BSON_TYPE_EOD, BSON_TYPE_NULL:
      Result := Null;
    BSON_TYPE_UNDEFINED : VarClear(Result);
    BSON_TYPE_DOUBLE:
      Result := GetAsDouble;
    BSON_TYPE_CODE:
      Result := GetAsCode;
    BSON_TYPE_SYMBOL:
      Result := GetAsSymbol;
    BSON_TYPE_UTF8:
      Result := GetAsUTF8String;
    BSON_TYPE_INT32:
      Result := GetAsInteger;
    BSON_TYPE_BOOL:
      Result := GetAsBoolean;
    BSON_TYPE_DATE_TIME:
      Result := GetAsDateTime;
    BSON_TYPE_INT64:
{$IFNDEF DELPHI2007}
      raise Exception.Create(SCanTAccessAnInt64UsingAVariantOn);
{$ELSE}
      Result := getAsInt64;
{$ENDIF}
    else
      raise EBson.Create(SNotSupportedByTBsonIteratorValue, IntToStr(Ord(kind)), E_NotSupportedByTBsonIteratorValue);
  end;
end;

function TBsonIterator.getAsOID: IBsonOID;
begin
  Result := NewBsonOID(Self);
end;

function TBsonIterator.getAsCodeWScope: IBsonCodeWScope;
begin
  Result := NewBsonCodeWScope(Self);
end;

function TBsonIterator.getAsRegex: IBsonRegex;
begin
  Result := NewBsonRegex(Self);
end;

function TBsonIterator.getAsTimestamp: IBsonTimestamp;
begin
  Result := NewBsonTimestamp(Self);
end;

function TBsonIterator.getAsBinary: IBsonBinary;
begin
  Result := NewBsonBinary(Self);
end;

function TBsonIterator.subiterator: IBsonIterator;
var
  it: bson_iter_t;
begin
  if not bson_iter_recurse(@FNativeIter, @it) then
    raise EBson.Create('bson_iter_recurse failed');
  Result := TBsonIterator.Create(it);
end;

function TBsonIterator.AsIntegerArray: TIntegerArray;
var
  i: IBsonIterator;
  j, Count: Integer;
begin
  prepareArrayIterator(i, j, count, BSON_TYPE_INT32, UTF8String(SArrayComponentIsNotAnInteger));
  SetLength(Result, Count);
  iterateAndFillArray(i, Result, j, BSON_TYPE_INT32);
end;

function TBsonIterator.AsDoubleArray: TDoubleArray;
var
  i: IBsonIterator;
  j, Count: Integer;
begin
  prepareArrayIterator(i, j, count, BSON_TYPE_DOUBLE, UTF8String(SArrayComponentIsNotADouble));
  SetLength(Result, Count);
  iterateAndFillArray(i, Result, j, BSON_TYPE_DOUBLE);
end;

function TBsonIterator.AsStringArray: TStringArray;
var
  i: IBsonIterator;
  j, Count: Integer;
begin
  prepareArrayIterator(i, j, count, BSON_TYPE_UTF8, UTF8String(SArrayComponentIsNotAString));
  SetLength(Result, Count);
  iterateAndFillArray(i, Result, j, BSON_TYPE_UTF8);
end;

function TBsonIterator.AsBooleanArray: TBooleanArray;
var
  i: IBsonIterator;
  j, Count: Integer;
begin
  prepareArrayIterator(i, j, count, BSON_TYPE_BOOL, UTF8String(SArrayComponentIsNotABoolean));
  SetLength(Result, Count);
  iterateAndFillArray(i, Result, j, BSON_TYPE_BOOL);
end;

function TBsonIterator.getHandle: Pointer;
begin
  Result := @FNativeIter;
end;

procedure TBsonIterator.iterateAndFillArray(i: IBsonIterator; var Result; var
    j: Integer; BSonType: TBsonType);
begin
  while i.next() do
  begin
    case BSonType of
      BSON_TYPE_DOUBLE : TDoubleArray(Result)[j] := i.value;
      BSON_TYPE_UTF8 : TStringArray(Result)[j] := UTF8String(i.value);
      BSON_TYPE_BOOL : TBooleanArray(Result)[j] := i.value;
      BSON_TYPE_INT32 : TIntegerArray(Result)[j] := i.value;
      else raise Exception.Create(SDatatypeNotSupported);
    end;
    Inc(j);
  end;
end;

procedure TBsonIterator.prepareArrayIterator(var i: IBsonIterator; var j,
    count: Integer; BSonType: TBsonType; const ATypeErrorMsg: UTF8String);
begin
  if kind <> BSON_TYPE_ARRAY then
    raise Exception.Create(SIteratorDoesNotPointToAnArray);
  i := subiterator;
  Count := 0;
  while i.next do
  begin
    if i.kind <> BSonType then
      raise Exception.Create(ATypeErrorMsg);
    Inc(Count);
  end;
  i := subiterator;
  j := 0;
end;

{ TBsonBuffer }

constructor TBsonBuffer.Create;
begin
  inherited Create;
  bson_init(@FNativeBson);
  FSubNativeBson := TStack.Create;
end;

destructor TBsonBuffer.Destroy;
begin
  FSubNativeBson.Free;
  bson_destroy(@FNativeBson);
  inherited Destroy;
end;

function TBsonBuffer.GetCurrNativeBson: Pointer;
begin
  if  FSubNativeBson.Count > 0 then
    Result := FSubNativeBson.Peek
  else
    Result := @FNativeBson;
end;

{$IFDEF DELPHI2009}
function TBsonBuffer.append(const Name, Value: UTF8String): Boolean;
begin
  Result := appendStr(Name, Value);
end;
{$EndIf}

function TBsonBuffer.appendStr(const Name, Value: UTF8String): Boolean;
begin
  Result := bson_append_utf8(GetCurrNativeBson, PAnsiChar(Name), -1, PAnsiChar(Value), -1);
end;

function TBsonBuffer.appendCode(const Name, Value: UTF8String): Boolean;
begin
  Result := bson_append_code(GetCurrNativeBson, PAnsiChar(Name), -1, PAnsiChar(Value));
end;

function TBsonBuffer.appendCodeWithScope(const Name, Value: UTF8String; const scope: IBson): Boolean;
var
  b: bson_t;
begin
  bson_init_static(@b, scope.Data, scope.size);
  Result := bson_append_code_with_scope(GetCurrNativeBson, PAnsiChar(Name), -1, PAnsiChar(Value), @b);
  bson_destroy(@b);
end;

function TBsonBuffer.appendSymbol(const Name, Value: UTF8String): Boolean;
begin
  Result := bson_append_symbol(GetCurrNativeBson, PAnsiChar(Name), -1, PAnsiChar(Value), -1);
end;

function TBsonBuffer.append(const Name: UTF8String; Value: LongInt): Boolean;
begin
  Result := bson_append_int32(GetCurrNativeBson, PAnsiChar(Name), -1, Value);
end;

function TBsonBuffer.append(const Name: UTF8String; Value: Int64): Boolean;
begin
  Result := bson_append_int64(GetCurrNativeBson, PAnsiChar(Name), -1, Value);
end;

function TBsonBuffer.append(const Name: UTF8String; Value: Double): Boolean;
begin
  Result := bson_append_double(GetCurrNativeBson, PAnsiChar(Name), -1, Value);
end;

{$IFDEF DELPHI2009}
function TBsonBuffer.append(const Name: UTF8String; Value: TDateTime): Boolean;
begin
  Result := AppendDate(Name, Value);
end;
{$ENDIF}

function TBsonBuffer.appendDate(const Name: UTF8String; Value: TDateTime):
    Boolean;
begin
  Result := bson_append_date_time(GetCurrNativeBson, PAnsiChar(Name), -1, DateTimeToUnix(Value));
end;

function TBsonBuffer.append(const Name: UTF8String; Value: Boolean): Boolean;
begin
  Result := bson_append_bool(GetCurrNativeBson, PAnsiChar(Name), -1, Value);
end;

function TBsonBuffer.append(const Name: UTF8String; Value: IBsonOID): Boolean;
begin
  Result := bson_append_oid(GetCurrNativeBson, PAnsiChar(Name), -1, Value.Value);
end;

function TBsonBuffer.append(const Name: UTF8String; Value: IBsonCodeWScope):
    Boolean;
var
  b: bson_t;
begin
  bson_init_static(@b, Value.getScope.Data, Value.getScope.size);
  Result := bson_append_code_with_scope(GetCurrNativeBson, PAnsiChar(Name), -1,
    PAnsiChar(Value.getCode), @b);
  bson_destroy(@b);
end;

function TBsonBuffer.append(const Name: UTF8String; Value: IBsonRegex): Boolean;
begin
  Result := bson_append_regex(GetCurrNativeBson, PAnsiChar(Name), -1, PAnsiChar(Value.getPattern), PAnsiChar(Value.getOptions));
end;

function TBsonBuffer.append(const Name: UTF8String; Value: IBsonTimestamp):
    Boolean;
begin
  Result := bson_append_timestamp(GetCurrNativeBson, PAnsiChar(Name), -1,
    Value.Time, Value.Increment);
end;

function TBsonBuffer.append(const Name: UTF8String; Value: IBsonBinary):
    Boolean;
begin
  Result := bson_append_binary(GetCurrNativeBson, PAnsiChar(Name), -1, Value.getKind,
    Value.getData, Value.getLen);
end;

{$IFDEF DELPHI2007}
function TBsonBuffer.append(const Name: UTF8String; const Value: Variant):
    Boolean;
begin
  Result := appendVariant(Name, Value);
end;
{$ENDIF}

function TBsonBuffer.appendVariant(const Name: UTF8String; const Value:
    Variant): Boolean;
var
  d: Double;
  {$IFDEF DELPHI2007}
  {$IFNDEF DELPHI2009}
  vint64 : Int64;
  {$ENDIF}
  {$ENDIF}
begin
  case VarType(Value) of
    varNull:
      Result := appendNull(Name);
    varByte, varInteger, varSmallint {$IFDEF DELPHI2007}, varWord, varShortInt {$ENDIF}:
      Result := append(Name, Integer(Value));
    varSingle, varDouble, varCurrency:
      begin
        d := Value;
        Result := append(Name, d);
      end;
    varDate:
      Result := appendDate(Name, TDateTime(Value));
    {$IFDEF DELPHI2007}
    varInt64, varLongWord:
      begin
        {$IFDEF DELPHI2009}
        Result := append(Name, Int64(Value));
        {$ELSE}
        vint64 := Value;
        Result := append(Name, vint64);
        {$ENDIF}
      end;
    {$ENDIF}
    varBoolean:
      Result := append(Name, Boolean(Value));
    varString, varOleStr {$IFDEF DELPHI2009}, varUString {$ENDIF}:
      // Need to cast Variant to string to don't lose Unicode encoding. Implicit cast does first Ansi
      // and Unicode chars are lost resulting on string with ????
      Result := appendStr(Name, UTF8String(String(Value)));
    varVariant : Result := appendVariant(Name, Value);
    else
      raise Exception.Create(STBsonAppendVariantTypeNotSupport +
        IntToStr(VarType(Value)) + ')');
  end;
end;

function TBsonBuffer.appendNull(const Name: UTF8String): Boolean;
begin
  Result := bson_append_null(GetCurrNativeBson, PAnsiChar(Name), -1);
end;

function TBsonBuffer.appendUndefined(const Name: UTF8String): Boolean;
begin
  Result := bson_append_undefined(GetCurrNativeBson, PAnsiChar(Name), -1);
end;

function TBsonBuffer.appendBinary(const Name: UTF8String; Kind: TBsonSubtype; const Data:
    PByte; Length: LongWord): Boolean;
begin
  if Data = nil then
    Result := false
  else
    Result := bson_append_binary(GetCurrNativeBson, PAnsiChar(Name), -1, Kind, Data, Length);
end;

function TBsonBuffer.append(const Name: UTF8String; Value: IBson): Boolean;
var
  b: bson_t;
begin
  bson_init_static(@b, Value.Data, Value.size);
  Result := bson_append_document(GetCurrNativeBson, PAnsiChar(Name), -1, @b);
  bson_destroy(@b);
end;

type
  TAppendElementCallback = function (i: Integer; const Arr): Boolean of object;

function TBsonBuffer.appendIntCallback(i: Integer; const Arr): Boolean;
begin
  Result := bson_append_int32(FSubNativeBson.Peek, PAnsiChar(IntToStr(i)), -1, TIntegerArray(Arr)[i]);
end;

function TBsonBuffer.appendDoubleCallback(i: Integer; const Arr): Boolean;
begin
  Result := bson_append_double(FSubNativeBson.Peek, PAnsiChar(IntToStr(i)), -1, TDoubleArray(Arr)[i]);
end;

function TBsonBuffer.appendBooleanCallback(i: Integer; const Arr): Boolean;
begin
  Result := bson_append_bool(FSubNativeBson.Peek, PAnsiChar(IntToStr(i)), -1, TBooleanArray(Arr)[i]);
end;

function TBsonBuffer.appendStringCallback(i: Integer; const Arr): Boolean;
begin
  Result := bson_append_utf8(FSubNativeBson.Peek, PAnsiChar(IntToStr(i)), -1, PAnsiChar(TStringArray(Arr)[i]), -1);
end;

function TBsonBuffer.internalAppendArray(const Name: UTF8String; const Arr;
    Len: Integer; AppendElementCallback: Pointer): Boolean;
var
  success: Boolean;
  i : Integer;
  AppendElementMethod : TAppendElementCallback;
begin
  success := startArray(Name);
  i := 0;
  TMethod(AppendElementMethod).Data := Self;
  TMethod(AppendElementMethod).Code := AppendElementCallback;
  while success and (i < Len) do
  begin
    success := AppendElementMethod(i, Arr);
    Inc(i);
  end;
  if success then
    success := finishArray;
  Result := success;
end;

function TBsonBuffer.appendArray(const Name: UTF8String; const Value:
    TIntegerArray): Boolean;
begin
  Result := internalAppendArray(Name, Value, length(Value), @TBsonBuffer.appendIntCallback);
end;

function TBsonBuffer.appendArray(const Name: UTF8String; const Value:
    TDoubleArray): Boolean;
begin
  Result := internalAppendArray(Name, Value, length(Value), @TBsonBuffer.appendDoubleCallback);
end;

function TBsonBuffer.appendArray(const Name: UTF8String; const Value:
    TBooleanArray): Boolean;
begin
  Result := internalAppendArray(Name, Value, length(Value), @TBsonBuffer.appendBooleanCallback);
end;

function TBsonBuffer.appendArray(const Name: UTF8String; const Value:
    TStringArray): Boolean;
begin
  Result := internalAppendArray(Name, Value, length(Value), @TBsonBuffer.appendStringCallback);
end;

function TBsonBuffer.appendCode_n(const Name, Value: UTF8String; Len:
    Cardinal): Boolean;
var
  s: UTF8String;
begin
  s := Copy(Value, 1, Len);
  Result := bson_append_code(GetCurrNativeBson, PAnsiChar(Name), -1, PAnsiChar(s));
end;

function TBsonBuffer.appendElementsAsArray(const def : TVarRecArray): boolean;
var
  Fld : UTF8String;
  i, CurArrayIndex : integer;
  OperStack, ArrayIndexStack : IStack;
  ProcessingArray : boolean;
  i_bsonobj : IUnknown;
  procedure BackupStack(BsonType : TBsonType);
  begin
    if BsonType = BSON_TYPE_ARRAY then
      ArrayIndexStack.Push(CurArrayIndex);
    OperStack.Push(BsonType);
  end;
  function RestoreStack : TBsonType;
  begin
    Fld := '';
    if (not OperStack.Empty) and (OperStack.Peek = BSON_TYPE_ARRAY) then
      CurArrayIndex := ArrayIndexStack.Pop;
    Result := TBsonType(integer(OperStack.Pop));
  end;
  function PeekIfNextElementIsArrayOrObject : Boolean;
  begin
    Result := False;
    if (not OperStack.Empty) and (OperStack.Peek = BSON_TYPE_ARRAY) then
      begin
        // Let's take a peek if next operator is a start of object or array before
        // we add the element as an attribute
        Result := (i + 1 <= High(def)) and (def[i + 1].VType = vtObject) and ((def[i + 1].VObject = Start_Object) or (def[i + 1].VObject = Start_Array));
      end;
  end;
  function AppendString(const Val : Variant) : Boolean;
  begin
    if PeekIfNextElementIsArrayOrObject then
      begin
        Fld := Val; // The value passed as parameter is really the name of an array of object
        Result := True;
        dec(CurArrayIndex); // CurArrayIndex will be incremented when this function returns and we didn't add anything
      end
    else  Result := appendVariant(Fld, Val);
  end;
  function AppendElement : Boolean;
  begin
    case def[i].VType of
      vtInteger    : Result := append(Fld, def[i].VInteger);
      vtBoolean    : Result := append(Fld, def[i].VBoolean);
      vtExtended   : Result := append(Fld, def[i].VExtended^);
      vtCurrency   : Result := append(Fld, def[i].VCurrency^);
      vtVariant    : Result := appendVariant(Fld, def[i].VVariant^);
      vtInt64      : Result := append(Fld, def[i].VInt64^);
      vtObject     : if def[i].VObject = Start_Object then
        begin
          BackupStack(BSON_TYPE_DOCUMENT);
          Result := startObject(Fld);
        end
      else if def[i].VObject = Start_Array then
        begin
          BackupStack(BSON_TYPE_ARRAY);
          Result := startArray(Fld);
          CurArrayIndex := -1; // CurArrayIndex will be incremented when this function returns
        end
      else if def[i].VObject = End_Array then
        begin
          if RestoreStack <> BSON_TYPE_ARRAY then
            raise EBson.Create(SWasNotExpectingCloseOfArrayOperator, E_WasNotExpectingCloseOfArrayOperator);
          Result := finishArray;
        end
      else if def[i].VObject = Null_Element then
        Result := AppendNull(Fld)
      else raise EBson.Create(SDatatypeNotSupportedToBuildBSON, E_DatatypeNotSupportedToBuildBSON);
      vtInterface  :
        if def[i].VInterface <> nil then
          if IInterface(def[i].VInterface).QueryInterface(IBsonOID, i_bsonobj) = S_OK then
            Result := append(Fld, IBsonOID(i_bsonobj))
          else if IInterface(def[i].VInterface).QueryInterface(IBsonBinary, i_bsonobj) = S_OK then
            Result := append(Fld, IBsonBinary(i_bsonobj))
          else if IInterface(def[i].VInterface).QueryInterface(IBsonCodeWScope, i_bsonobj) = S_OK then
            Result := append(Fld, IBsonCodeWScope(i_bsonobj))
          else if IInterface(def[i].VInterface).QueryInterface(IBsonRegex, i_bsonobj) = S_OK then
            Result := append(Fld, IBsonRegex(i_bsonobj))
          else if IInterface(def[i].VInterface).QueryInterface(IBsonTimestamp, i_bsonobj) = S_OK then
            Result := append(Fld, IBsonTimestamp(i_bsonobj))
          else raise EBson.Create(SDatatypeNotSupportedToBuildBSON, E_DatatypeNotSupportedToBuildBSON)
        else raise EBson.Create(SNilInterfacePointerNotSupported, E_NilInterfacePointerNotSupported);
      vtChar, vtPChar, vtWideChar, vtPWideChar, vtAnsiString, vtString,
      vtWideString {$IFDEF DELPHI2009}, vtUnicodeString {$ENDIF} : Result := AppendString(UTF8StringFromTVarRec(def[i]));
      else raise EBson.Create(SDatatypeNotSupportedToBuildBSON, E_DatatypeNotSupportedToBuildBSON);
    end;
  end;
begin
  OperStack := NewStack;
  ArrayIndexStack := NewStack;
  Result := True;
  if length(def) < 2 then
    raise EBson.Create(SDefMustContainAMinimumOfTwoElements, E_DefMustContainAMinimumOfTwoElements);
  i := low(def);
  while i <= High(def) do
    begin
      if not Result then
        break;
      if (OperStack.Empty) or (OperStack.Peek = BSON_TYPE_DOCUMENT) then
        begin
          if (def[i].VType = vtObject) and (def[i].VObject = End_Object) then
            begin
              if RestoreStack <> BSON_TYPE_DOCUMENT then
                raise EBson.Create(SWasNotExpectingCloseOfObjectOper, E_WasNotExpectingCloseOfObjectOper);
              Result := finishObject;
              inc(i);
              continue;
            end
          else Fld := UTF8StringFromTVarRec(def[i]);
          if Fld = '' then
            raise EBson.Create(SExpectedDefElementShouldBeAString, E_ExpectedDefElementShouldBeAString);
          inc(i);
        end;
      if i > High(def) then
        raise EBson.Create(SBSONArrayDefinitionFinishedTooEarly, E_BSONArrayDefinitionFinishedTooEarly);
      ProcessingArray := (not OperStack.Empty) and (OperStack.Peek = BSON_TYPE_ARRAY);
      if ProcessingArray then
        Fld := IntToStr(CurArrayIndex);
      Result := AppendElement;
      if ProcessingArray then
        inc(CurArrayIndex);
      inc(i);
    end;
end;

function TBsonBuffer.appendElementsAsArray(const def: array of const): boolean;
begin
  Result := appendElementsAsArray(MkVarRecArray(def));
end;

function TBsonBuffer.appendObjectAsArray(const ObjectNAme: UTF8String; const
    def: TVarRecArray): boolean;
begin
  Result := startObject(ObjectName);
  if Result then
    Result := appendElementsAsArray(def);
  if Result then
    Result := finishObject;
end;

function TBsonBuffer.appendStr_n(const Name, Value: UTF8String; Len: Cardinal):
    Boolean;
begin
  Result := bson_append_utf8(GetCurrNativeBson, PAnsiChar(Name), -1, PAnsiChar(Value), Len);
end;

function TBsonBuffer.appendSymbol_n(const Name, Value: UTF8String; Len:
    Cardinal): Boolean;
begin
  Result := bson_append_symbol(GetCurrNativeBson, PAnsiChar(Name), -1, PAnsiChar(Value), Len);
end;

function TBsonBuffer.startObject(const Name: UTF8String): Boolean;
var
  child: Pointer;
begin
  child := bson_new;
  Result := bson_append_document_begin(GetCurrNativeBson, PAnsiChar(Name), -1, child);
  FSubNativeBson.Push(child);
end;

function TBsonBuffer.finishObject: Boolean;
var
  child: Pointer;
begin
  child := FSubNativeBson.Pop;
  Result := bson_append_document_end(GetCurrNativeBson, child);
  bson_destroy(child);
end;

function TBsonBuffer.startArray(const Name: UTF8String): Boolean;
var
  child: Pointer;
begin
  child := bson_new;
  Result := bson_append_array_begin(GetCurrNativeBson, PAnsiChar(Name), -1, child);
  FSubNativeBson.Push(child);
end;

function TBsonBuffer.finishArray: Boolean;
var
  child: Pointer;
begin
  child := FSubNativeBson.Pop;
  Result := bson_append_array_end(GetCurrNativeBson, child);
  bson_destroy(child);
end;

function TBsonBuffer.size: LongWord;
begin
  Result := FNativeBson.len;
end;

function TBsonBuffer.finish: IBson;
begin
  Result := TBson.Create(FNativeBson);
end;

class function TBsonBuffer.UTF8StringFromTVarRec(const AVarRec: TVarRec):
    UTF8String;
begin
  case AVarRec.VType of
    vtAnsiString    : Result := UTF8String(AVarRec.VAnsiString);
    vtWideString    : Result := UTF8String(WideString(AVarRec.VWideString));
    vtString        : Result := AVarRec.VString^;
    vtChar          : Result := AVarRec.VChar;
    vtWideChar      : Result := AnsiChar(AVarRec.VWideChar);
    vtPChar         : Result := UTF8String(AVarRec.VPChar);
    vtPWideChar     : Result := UTF8String(AVarRec.VPWideChar);
    {$IFDEF DELPHI2009}
    vtUnicodeString : Result := UTF8String(UnicodeString(AVarRec.VUnicodeString));
    {$ENDIF}
    else Result := '';
  end;
end;

{ TBson }

constructor TBson.Create(const bson: bson_t);
begin
  inherited Create;
  bson_copy_to(@bson, @FNativeBson);
end;

constructor TBson.Create(const AData: PByte; len: Cardinal);
var
  p: Pointer;
begin
  inherited Create;
  p := bson_new_from_data(AData, len);
  if p = nil then
    raise EBson.Create(S_FAILED_TO_INIT_BSON_FROM_DATA, E_FAILED_TO_INIT_BSON_FROM_DATA);
  bson_copy_to(p, @FNativeBson);
  bson_destroy(p);
end;

constructor TBson.Create(json: UTF8String);
var
  err: bson_error_t;
begin
  inherited Create;
  if not bson_init_from_json(@FNativeBson, PAnsiChar(json), length(json), @err) then
    raise EBson.CreateFmt(SFailedCreatingBSONFromJSON, [UTF8String(err.message), err.domain, err.code]);
end;

constructor TBson.Create(const b: IBson);
var
  p: Pointer;
begin
  p := bson_new_from_data(b.Data, b.size);
  bson_copy_to(p, @FNativeBson);
  bson_destroy(p);
end;

destructor TBson.Destroy();
begin
  bson_destroy(@FNativeBson);
  inherited Destroy;
end;

function TBson.getData: PByte;
begin
  Result := bson_get_data(@FNativeBson);
end;

function TBson.value(const Name: UTF8String): Variant;
var
  i: IBsonIterator;
begin
  i := find(Name);
  if i = nil then
    Result := Null
  else
    Result := i.value;
end;

function TBson.iterator: IBsonIterator;
var
  it: bson_iter_t;
begin
  if not bson_iter_init(@it, @FNativeBson) then
    raise EBson.Create('bson_iter_init Failed');
  Result := TBsonIterator.Create(it);
end;

function TBson.size: LongWord;
begin
  Result := FNativeBson.len;
end;

function TBson.find(const Name: UTF8String): IBsonIterator;
var
  it: bson_iter_t;
begin
  if not bson_iter_init_find(@it, @FNativeBson, PAnsiChar(Name)) then
    Result := nil
  else
    Result := TBsonIterator.Create(it);
end;

function TBson.asJson: UTF8String;
var
  p: PAnsiChar;
begin
  p := bson_as_json(@FNativeBson, nil);
  Result := UTF8String(p);
  bson_free(p);
end;

function TBson.valueAsInt64(const Name: UTF8String): Int64;
var
  i: IBsonIterator;
begin
  i := find(Name);
  if i = nil then
    Result := 0
  else
    Result := i.AsInt64;
end;

{ TBsonCodeWScope }

constructor TBsonCodeWScope.Create(const acode: UTF8String; ascope: IBson);
begin
  inherited Create;
  code := acode;
  scope := ascope;
end;

constructor TBsonCodeWScope.Create(i: IBsonIterator);
var
  p : PByte;
  len, scope_len: LongWord;
begin
  inherited Create;
  code := UTF8String(bson_iter_codewscope(i.getHandle, @len, @scope_len, @p));
  scope := TBson.Create(p, scope_len);
end;

function TBsonCodeWScope.getCode: UTF8String;
begin
  Result := Code;
end;

function TBsonCodeWScope.getScope: IBson;
begin
  Result := Scope;
end;

procedure TBsonCodeWScope.setCode(const ACode: UTF8String);
begin
  Code := ACode;
end;

procedure TBsonCodeWScope.setScope(AScope: IBson);
begin
  Scope := AScope;
end;

{ TBsonRegex }

constructor TBsonRegex.Create(const apattern, aoptions: UTF8String);
begin
  inherited Create;
  pattern := apattern;
  options := aoptions;
end;

constructor TBsonRegex.Create(i: IBsonIterator);
var
  p: PAnsiChar;
begin
  inherited Create;
  pattern := UTF8String(bson_iter_regex(i.getHandle, @p));
  options := UTF8String(p);
end;

function TBsonRegex.getOptions: UTF8String;
begin
  Result := Options;
end;

function TBsonRegex.getPattern: UTF8String;
begin
  Result := Pattern;
end;

procedure TBsonRegex.setOptions(const AOptions: UTF8String);
begin
  Options := AOptions;
end;

procedure TBsonRegex.setPattern(const APattern: UTF8String);
begin
  Pattern := APattern;
end;

{ TBsonTimestamp }

constructor TBsonTimestamp.Create(atimestamp, aincrement: LongWord);
begin
  inherited Create;
  FTimestamp := atimestamp;
  FIncrement := aincrement;
end;

constructor TBsonTimestamp.Create(i: IBsonIterator);
begin
  inherited Create;
  bson_iter_timestamp(i.getHandle, @FTimestamp, @FIncrement);
end;

function TBsonTimestamp.getIncrement: LongWord;
begin
  Result := FIncrement;
end;

function TBsonTimestamp.getTime: LongWord;
begin
  Result := FTimestamp;
end;

procedure TBsonTimestamp.setIncrement(AIncrement: LongWord);
begin
  FIncrement := AIncrement;
end;

procedure TBsonTimestamp.setTime(ATime: LongWord);
begin
  FTimestamp := ATime;
end;

{ TBsonBinary }

constructor TBsonBinary.Create(p: PByte; Length: LongWord);
begin
  inherited Create;
  GetMem(Data, Length);
  Move(p^, Data^, Length);
  Kind := BSON_SUBTYPE_BINARY;
  Len := Length;
end;

constructor TBsonBinary.Create(i: IBsonIterator);
var
  p: PByte;
begin
  inherited Create;
  bson_iter_binary(i.getHandle, @Kind, @Len, @p);
  GetMem(Data, Len);
  Move(p^, Data^, Len);
end;

destructor TBsonBinary.Destroy;
begin
  if Data <> nil then
    begin
      FreeMem(Data);
      Data := nil;
      Len := 0;
    end;
  inherited;
end;

function TBsonBinary.getData: PByte;
begin
  Result := Data;
end;

function TBsonBinary.getKind: TBsonSubtype;
begin
  Result := Kind;
end;

function TBsonBinary.getLen: LongWord;
begin
  Result := Len;
end;

procedure TBsonBinary.setData(AData: PByte; ALen: LongWord);
begin
  if ALen > Len then
    ReallocMem(Data, ALen);
  Move(AData^, Data^, ALen);
  Len := ALen;
end;

procedure TBsonBinary.setKind(AKind: TBsonSubtype);
begin
  Kind := AKind;
end;

function ByteToHex(InByte: Byte): UTF8String;
const
  digits: array[0..15] of AnsiChar = '0123456789ABCDEF';
begin
  Result := digits[InByte shr 4] + digits[InByte and $0F];
end;

{ BSON object builder function }

function BSON(const x: array of Variant): IBson;
var
  bb: IBsonBuffer;
  VarRecArr : TVarRecArray;
begin
  VarRecArr := nil;
  bb := NewBsonBuffer;
  if length(x) > 0 then
  begin
     VarRecArr := MkBSONVarRecArrayFromVarArray(x, NewPrimitiveAllocator);
     try
       bb.appendElementsAsArray(VarRecArr);
     finally
       CleanVarRecArray(VarRecArr);
     end;
  end;
  Result := bb.finish;
end;

{ Factory functions }

function NewBsonBinary(p: Pointer; Length: Integer): IBsonBinary; overload;
begin
  Result := TBsonBinary.Create(p, Length);
end;

function NewBsonBinary(i: IBsonIterator): IBsonBinary; overload;
begin
  Result := TBsonBinary.Create(i);
end;

function NewBsonCodeWScope(const acode: UTF8String; ascope: IBson): IBsonCodeWScope;
begin
  Result := TBsonCodeWScope.Create(acode, ascope);
end;

function NewBsonCodeWScope(i: IBsonIterator): IBsonCodeWScope; overload;
begin
  Result := TBsonCodeWScope.Create(i);
end;

function NewBsonOID(oid : IBsonOID): IBsonOID; overload;
begin
  Result := TBsonOID.Create(oid);
end;

function NewBsonOID: IBsonOID; overload;
begin
  Result := TBsonOID.Create;
end;

function NewBsonOID(const s : UTF8String): IBsonOID; overload;
begin
  Result := TBsonOID.Create(s);
end;

function NewBsonOID(i : IBsonIterator): IBsonOID; overload;
begin
  Result := TBsonOID.Create(i);
end;

function NewBsonRegex(const apattern, aoptions: UTF8String): IBsonRegex; overload;
begin
  Result := TBsonRegex.Create(apattern, aoptions);
end;

function NewBsonRegex(i : IBsonIterator): IBsonRegex; overload;
begin
  Result := TBsonRegex.Create(i);
end;

function NewBsonTimestamp(i : IBsonIterator): IBsonTimestamp; overload;
begin
  Result := TBsonTimestamp.Create(i);
end;

function NewBsonTimestamp(atime, aincrement: LongWord):
    IBsonTimestamp; overload;
begin
  Result := TBsonTimestamp.Create(atime, aincrement);
end;

function NewBsonBuffer: IBsonBuffer;
begin
  Result := TBsonBuffer.Create;
end;

function NewBson(const json: UTF8String): IBson;
begin
  Result := TBson.Create(json);
end;

function NewBson(const AData: PByte; len: Cardinal): IBson;
begin
  Result := TBson.Create(AData, len);
end;

var
  { An empty BSON document }
  absonEmpty: IBson;

function bsonEmpty: IBson;
begin
  if absonEmpty = nil then
    absonEmpty := BSON([]);
  Result := absonEmpty;
end;

function NewBsonCopy(const b: IBson): IBson;
begin
  Result := TBson.Create(b);
end;

function End_Object: TObject;
begin
  Result := AEnd_Object;
end;

function End_Array: TObject;
begin
  Result := AEnd_Array;
end;

function Start_Array: TObject;
begin
  Result := AStart_Array;
end;

function Start_Object: TObject;
begin
  Result := AStart_Object;
end;

function Null_Element : TObject;
begin
  Result := ANull_Element;
end;

{ Utility functions to create Dynamic Arrays from Open Array parameters }

function MkVarRecArray(const Arr : array of const): TVarRecArray;
{$i MongoBsonArrayBuilder.inc}

function MkIntArray(const Arr : array of Integer): TIntegerArray;
{$i MongoBsonArrayBuilder.inc}

function MkDoubleArray(const Arr : array of Double): TDoubleArray;
{$i MongoBsonArrayBuilder.inc}

function MkBoolArray(const Arr : array of Boolean): TBooleanArray;
{$i MongoBsonArrayBuilder.inc}

function MkStrArray(const Arr : array of UTF8String): TStringArray;
{$i MongoBsonArrayBuilder.inc}

procedure AppendToIntArray(const Arr : array of Integer; var TargetArray : TIntegerArray; FromIndex : Cardinal = 0);
{$i MongoBsonArrayAppender.inc}

procedure AppendToDoubleArray(const Arr : array of Double; var TargetArray : TDoubleArray; FromIndex : Cardinal = 0);
{$i MongoBsonArrayAppender.inc}

procedure AppendToBoolArray(const Arr : array of Boolean; var TargetArray : TBooleanArray; FromIndex : Cardinal = 0);
{$i MongoBsonArrayAppender.inc}

procedure AppendToStrArray(const Arr : array of UTF8String; var TargetArray : TStringArray; FromIndex : Cardinal = 0);
{$i MongoBsonArrayAppender.inc}

procedure AppendToVarRecArray(const Arr : array of const; var TargetArray : TVarRecArray; FromIndex : Cardinal = 0);
{$i MongoBsonArrayAppender.inc}


procedure CleanVarRecArray(const Arr: TVarRecArray);
var
  i : integer;
begin
  for I := Low(Arr) to High(Arr) do
    case Arr[i].VType of
      {$IFDEF DELPHI2009}
      vtUnicodeString : UnicodeString(Arr[i].VUnicodeString) := '';
      {$ENDIF}
      vtAnsiString : AnsiString(Arr[i].VAnsiString) := '';
      vtWideString : Widestring(Arr[i].VWideString) := '';
    end;
end;

function MkBSONVarRecArrayFromVarArray(const Arr : array of Variant; Allocator : IPrimitiveAllocator) : TVarRecArray;
var
  i : integer;
  RootResult : TVarRecArray absolute Result;
  function CheckOperatorString(const s : AnsiString) : Boolean;
  begin
    if s <> '' then
      if s[1] in ['{', '}', '[', ']'] then
        begin
          case s[1] of
            '{' : RootResult[i].VObject := Start_Object;
            '}' : RootResult[i].VObject := End_Object;
            '[' : RootResult[i].VObject := Start_Array;
            ']' : RootResult[i].VObject := End_Array;
          end;
          RootResult[i].VType := vtObject;
          Result := True;
        end
      else Result := False
    else Result := False;
  end;
begin
  SetLength(Result, length(Arr));
  for i := Low(Arr) to High(Arr) do
    case VarType(Arr[i]) of
      {$IFDEF DELPHI2007} varLongWord, varWord, varShortInt, {$ENDIF} varByte, varInteger, varSmallInt:
        begin
          Result[i].VType := vtInteger;
          Result[i].VInteger := Arr[i];
        end;
      varSingle, varDouble {$IFNDEF DELPHI2009}, varCurrency {$ENDIF} :
        begin
          Result[i].VType := vtExtended;
          Result[i].VExtended := Allocator.New(Extended(Arr[i]));
        end;
      {$IFDEF DELPHI2009}
      varCurrency :
        begin
          Result[i].VType := vtCurrency;
          Result[i].VCurrency := Allocator.New(Currency(Arr[i]));
        end;
      {$ENDIF}
      varDate :
        begin
          Result[i].VType := vtExtended;
          Result[i].VExtended := Allocator.New(TDateTime(Arr[i]));
        end;
      {$IFDEF DELPHI2007}
      varOleStr :
        begin
          if CheckOperatorString(AnsiString(Arr[i])) then
            continue;
          Result[i].VType := vtWideString;
          WideString(Result[i].VWideString) := Allocator.New(WideString(Arr[i]))^;
        end;
      {$ENDIF}  
      varBoolean :
        begin
          Result[i].VType := vtBoolean;
          Result[i].VBoolean := Arr[i];
        end;
      {$IFDEF DELPHI2009}
      varInt64, varUInt64 :
        begin
          Result[i].VType := vtInt64;
          Result[i].VInt64 := Allocator.New(Int64(Arr[i]));
        end;
      {$ENDIF}
      varString :
        begin
          if CheckOperatorString(AnsiString(Arr[i])) then
            continue;
          Result[i].VType := vtAnsiString;
          AnsiString(Result[i].VAnsiString) := Allocator.New(AnsiString(Arr[i]))^;
        end;
      {$IFDEF DELPHI2009}
      varUString :
        begin
          if CheckOperatorString(AnsiString(Arr[i])) then
            continue;
          Result[i].VType := vtUnicodeString;
          UnicodeString(Result[i].VUnicodeString) := Allocator.New(UnicodeString(Arr[i]))^;
        end;
      {$ENDIF}  
      varNull :
        begin
          Result[i].VType := vtObject;
          Result[i].VObject := Null_Element;
        end
      else raise EBson.Create(SDatatypeNotSupportedCallingMkVarRecArrayVarArray, E_DatatypeNotSupported);
   end;
end;

initialization
  AStart_Object := TObject.Create;
  AEnd_Object := TObject.Create;
  AStart_Array := TObject.Create;
  AEnd_Array := TObject.Create;
  ANull_Element := TObject.Create;
finalization
  ADefaultOidGenerator := nil;
  absonEmpty := nil;
  ANull_Element.Free;
  AStart_Object.Free;
  AEnd_Object.Free;
  AStart_Array.Free;
  AEnd_Array.Free;
end.


