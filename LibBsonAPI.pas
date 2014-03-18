unit LibBsonAPI;

interface

{$I MongoC_defines.inc}

uses
  SysUtils;

{$IFNDEF DELPHI2009}
type
  NativeUInt = Cardinal;
  PNativeUInt = ^NativeUInt;
{$ENDIF}

const
  LibBson_DllVersion = '0-6-0'; (* PLEASE!!! maintain this constant in sync with the dll driver version this code operates with *)

  CPUType = {$IFDEF WIN64} '64' {$ELSE} '32' {$ENDIF};
  ConfigType = {$IFDEF DEBUG} 'd' {$ELSE} 'r' {$ENDIF};
  LibBson_DLL = 'libbson_' + ConfigType + CPUType + '_v' + LibBson_DllVersion + '.dll';

type
  ELibBson = class(Exception);
  { IMPORTANT: Keep this structure sync with C code }
  bson_error_p = ^bson_error_t;
  bson_error_t = packed record
    domain : Cardinal;
    code : Cardinal;
    message : array [0..503] of AnsiChar;
  end;

{ LibBson DLL imports }

function libbson_bson_new_from_data (data : Pointer; length : Cardinal) : Pointer; cdecl; external LibBson_DLL name 'bson_new_from_data';
procedure libbson_bson_destroy (bson : Pointer); cdecl; external LibBson_DLL name 'bson_destroy';
function libbson_bson_new_from_json (data : pointer; len : NativeUInt; error : bson_error_p) : pointer; cdecl; external LibBson_DLL name 'bson_new_from_json';

function libbson_bson_get_data (bson : Pointer) : Pointer; cdecl; external LibBson_DLL name 'bson_get_data';

function libbson_bson_as_json (bson : Pointer; length : PNativeUInt) : PAnsiChar; cdecl; external LibBson_DLL name 'bson_as_json';
procedure libbson_bson_free (mem : Pointer); cdecl; external LibBson_DLL name 'bson_free';

implementation

end.
