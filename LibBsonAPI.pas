unit LibBsonAPI;

interface

{$I MongoC_defines.inc}

uses
  SysUtils, MongoBson, Windows, uDelphi5;

const
  (* PLEASE!!! maintain this constant in sync with the dll driver version this code operates with *)
  LibBson_DllVersion = '1-0-1';

  CPUType = {$IFDEF WIN64} '64' {$ELSE} '32' {$ENDIF};
  ConfigType = {$IFDEF DEBUG} 'd' {$ELSE} 'r' {$ENDIF};
  LibBson_DLL = 'libbson_' + ConfigType + CPUType + '_v' + LibBson_DllVersion + '.dll';

type
  { IMPORTANT: Keep this structures sync with C code }
  bson_error_p = ^bson_error_t;
  bson_error_t = packed record
    domain, code: LongWord;
    message: array [0..503] of AnsiChar;
  end;

  // we don't care about details, we just know bson_iter_t aligned to 128
  bson_iter_p = ^bson_iter_t;
  bson_iter_t = array[0..127] of Byte;

  bson_p = ^bson_t;
  bson_pp = ^bson_p;
  bson_t = packed record
    flags, len: LongWord;
    padding: array[0..119] of Byte;
  end;

  PPbyte = ^PByte;

{ LibBson DLL imports }
procedure bson_free(mem : PAnsiChar); cdecl; external LibBson_DLL;

function bson_new : bson_p; cdecl; external LibBson_DLL;
function bson_new_from_data(const data : PByte; length : Cardinal) : bson_p; cdecl; external LibBson_DLL;
function bson_new_from_json(const data : PByte; length : Integer; error : bson_error_p) : bson_p; cdecl; external LibBson_DLL;
function bson_copy(const bson : bson_p) : Pointer; cdecl; external LibBson_DLL;
procedure bson_copy_to(const src : bson_p; dst : bson_p); cdecl; external LibBson_DLL;
procedure bson_init(bson : bson_p); cdecl; external LibBson_DLL;
function bson_init_from_json(bson : bson_p; const json: PAnsiChar; len : Integer; error : bson_error_p) : Boolean;
  cdecl; external LibBson_DLL;
function bson_init_static(bson : bson_p; const data : PByte; length : Cardinal) : Boolean;
  cdecl; external LibBson_DLL;
procedure bson_destroy(bson : bson_p); cdecl; external LibBson_DLL;
function bson_concat(dst : bson_p; const src : bson_p) : Boolean; cdecl; external LibBson_DLL;
function bson_get_data(const bson : bson_p) : PByte; cdecl; external LibBson_DLL;
function bson_as_json(const bson : bson_p; length : PCardinal) : PAnsiChar; cdecl; external LibBson_DLL;
function bson_append_utf8(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  const value : PAnsiChar; length : Integer) : Boolean; cdecl; external LibBson_DLL;
function bson_append_code(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  const javascript : PAnsiChar) : Boolean; cdecl; external LibBson_DLL;
function bson_append_symbol(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  const value : PAnsiChar; length : Integer) : Boolean; cdecl; external LibBson_DLL;
function bson_append_int32(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  value : LongInt) : Boolean; cdecl; external LibBson_DLL;
function bson_append_int64(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  value : Int64) : Boolean; cdecl; external LibBson_DLL;
function bson_append_double(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  value : Double) : Boolean; cdecl; external LibBson_DLL;
function bson_append_date_time(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  value : Int64) : Boolean; cdecl; external LibBson_DLL;
function bson_append_bool(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  value : Boolean) : Boolean; cdecl; external LibBson_DLL;
function bson_append_oid(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  const value : PBsonOIDBytes) : Boolean; cdecl; external LibBson_DLL;
function bson_append_code_with_scope(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  const javascript : PAnsiChar; const scope : Pointer) : Boolean; cdecl; external LibBson_DLL;
function bson_append_regex(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  const regex : PAnsiChar; const options : PAnsiChar) : Boolean; cdecl; external LibBson_DLL;
function bson_append_timestamp(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  timestamp : LongWord; increment : LongWord) : Boolean; cdecl; external LibBson_DLL;
function bson_append_binary(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  subtype : TBsonSubtype; const binary : PByte; length : LongWord) : Boolean; cdecl; external LibBson_DLL;
function bson_append_null(bson : bson_p; const key : PAnsiChar; key_length : Integer) : Boolean;
  cdecl; external LibBson_DLL;
function bson_append_undefined(bson : bson_p; const key : PAnsiChar; key_length : Integer) : Boolean;
  cdecl; external LibBson_DLL;
function bson_append_document(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  const value: bson_p) : Boolean; cdecl; external LibBson_DLL;
function bson_append_document_begin(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  child: bson_p) : Boolean; cdecl; external LibBson_DLL;
function bson_append_document_end(bson, child : bson_p) : Boolean; cdecl; external LibBson_DLL;
function bson_append_array_begin(bson : bson_p; const key : PAnsiChar; key_length : Integer;
  child: Pointer) : Boolean; cdecl; external LibBson_DLL;
function bson_append_array_end(bson, child : bson_p) : Boolean; cdecl; external LibBson_DLL;

procedure bson_oid_init(oid : PBsonOIDBytes; context : Pointer); cdecl; external LibBson_DLL;
procedure bson_oid_init_from_string(oid : PBsonOIDBytes; const str : PAnsiChar); cdecl; external LibBson_DLL;
procedure bson_oid_to_string(oid : PBsonOIDBytes; str : PAnsiChar); cdecl; external LibBson_DLL;

function bson_iter_init(iter : bson_iter_p; const bson : bson_p) : Boolean; cdecl; external LibBson_DLL;
function bson_iter_init_find(iter : bson_iter_p; const bson : bson_p; const key : PAnsiChar) : Boolean;
  cdecl; external LibBson_DLL;
function bson_iter_type(const iter : bson_iter_p) : TBsonType; cdecl; external LibBson_DLL;
function bson_iter_next(iter : bson_iter_p) : Boolean; cdecl; external LibBson_DLL;
function bson_iter_key(const iter : bson_iter_p) : PAnsiChar; cdecl; external LibBson_DLL;
function bson_iter_recurse(const iter : bson_iter_p; child : bson_iter_p) : Boolean; cdecl; external LibBson_DLL;

function bson_iter_oid(const iter : bson_iter_p) : PBsonOIDBytes; cdecl; external LibBson_DLL;
function bson_iter_int32(const iter : bson_iter_p) : LongInt; cdecl; external LibBson_DLL;
function bson_iter_int64(const iter : bson_iter_p) : Int64; cdecl; external LibBson_DLL;
function bson_iter_double(const iter : bson_iter_p) : Double; cdecl; external LibBson_DLL;
function bson_iter_utf8(const iter : bson_iter_p; length : LongWord) : PAnsiChar; cdecl; external LibBson_DLL;
function bson_iter_date_time(const iter : bson_iter_p) : Int64; cdecl; external LibBson_DLL;
function bson_iter_bool(const iter : bson_iter_p) : Boolean; cdecl; external LibBson_DLL;
function bson_iter_code(const iter : bson_iter_p; length : PLongWord) : PAnsiChar; cdecl; external LibBson_DLL;
function bson_iter_symbol(const iter : bson_iter_p; length : PLongWord) : PAnsiChar; cdecl; external LibBson_DLL;
function bson_iter_codewscope(const iter : bson_iter_p; length, scope_len : PLongWord;
  scope : PPByte) : PAnsiChar; cdecl; external LibBson_DLL;
function bson_iter_regex(const iter : bson_iter_p; options : PPAnsiChar) : PAnsiChar; cdecl; external LibBson_DLL;
procedure bson_iter_timestamp(const iter : bson_iter_p; timestamp, increment : PLongWord); cdecl; external LibBson_DLL;
procedure bson_iter_binary(const iter : bson_iter_p; subtype : PBsonSubtype; binary_len : PLongWord;
  binary : PPByte); cdecl; external LibBson_DLL;


implementation

initialization
  Assert(sizeof(bson_t) = 128, 'Keep structure synced with libbson bson_t');
  Assert(sizeof(bson_iter_t) = 128, 'Keep structure synced with libbson bson_iter_t');
  Assert(sizeof(bson_error_t) = 512, 'Keep structure synced with libbson bson_error_t');

end.
