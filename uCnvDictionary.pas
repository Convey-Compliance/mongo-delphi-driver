unit uCnvDictionary;

interface

{$IF CompilerVersion >= 21.0}
  {$DEFINE HAS_GENERICS}
{$IFEND}

uses
  {$IFDEF HAS_GENERICS}System.Generics.Collections{$ELSE}HashTrie{$ENDIF};

type

  TCnvStringDictionary = class
  private
    FDic: {$IFDEF HAS_GENERICS}TDictionary<string, TObject>{$ELSE}TStringHashTrie{$ENDIF};
  public
    constructor Create(AAutoFreeObjects: Boolean = false);
    destructor Destroy; override;
    procedure AddOrSetValue(const AKey: string; const AValue: TObject);
    procedure Remove(const AKey: string);
    function TryGetValue(const AKey: string; out AValue: TObject): Boolean;
    function ContainsKey(const AKey: string): Boolean;
    procedure Clear;
  end;

  TCnvIntegerDictionary = class
  private
    FDic: {$IFDEF HAS_GENERICS}TDictionary<Integer, TObject>{$ELSE}TIntegerHashTrie{$ENDIF};
  public
    constructor Create(AAutoFreeObjects: Boolean = false);
    destructor Destroy; override;
    procedure AddOrSetValue(const AKey: Integer; const AValue: TObject);
    procedure Remove(const AKey: Integer);
    function TryGetValue(const AKey: Integer; out AValue: TObject): Boolean;
    function ContainsKey(const AKey: Integer): Boolean;
    procedure Clear;
  end;

implementation

{ TCnvStringDictionary }

constructor TCnvStringDictionary.Create(AAutoFreeObjects: Boolean);
{$IFDEF HAS_GENERICS}
var
  ownerships: TDictionaryOwnerships;
{$ENDIF}
begin
{$IFDEF HAS_GENERICS}
  if AAutoFreeObjects then
    ownerships := [doOwnsValues]
  else
    ownerships := [];
  FDic := TObjectDictionary<string, TObject>.Create(ownerships);
{$ELSE}
  FDic := TStringHashTrie.Create;
  FDic.AutoFreeObjects := AAutoFreeObjects;
{$ENDIF}
end;

destructor TCnvStringDictionary.Destroy;
begin
  FDic.Free;
  inherited;
end;

procedure TCnvStringDictionary.AddOrSetValue(const AKey: string;
  const AValue: TObject);
begin
{$IFDEF HAS_GENERICS}
  FDic.AddOrSetValue(AKey, AValue);
{$ELSE}
  FDic.Add(AKey, AValue);
{$ENDIF}
end;

procedure TCnvStringDictionary.Clear;
begin
  FDic.Clear;
end;

function TCnvStringDictionary.ContainsKey(const AKey: string): Boolean;
{$IFNDEF HAS_GENERICS}
var
  stub: TObject;
{$ENDIF}
begin
{$IFDEF HAS_GENERICS}
  Result := FDic.ContainsKey(AKey);
{$ELSE}
  Result := FDic.Find(AKey, stub);
{$ENDIF}
end;

procedure TCnvStringDictionary.Remove(const AKey: string);
begin
{$IFDEF HAS_GENERICS}
  FDic.Remove(AKey);
{$ELSE}
  FDic.Delete(AKey);
{$ENDIF}
end;

function TCnvStringDictionary.TryGetValue(const AKey: string;
  out AValue: TObject): Boolean;
begin
{$IFDEF HAS_GENERICS}
  Result := FDic.TryGetValue(AKey, AValue);
{$ELSE}
  Result := FDic.Find(AKey, AValue);
{$ENDIF}
end;

{ TCnvIntegerDictionary }

procedure TCnvIntegerDictionary.AddOrSetValue(const AKey: Integer;
  const AValue: TObject);
begin
{$IFDEF HAS_GENERICS}
  FDic.AddOrSetValue(AKey, AValue);
{$ELSE}
  FDic.Add(AKey, AValue);
{$ENDIF}
end;

procedure TCnvIntegerDictionary.Clear;
begin
  FDic.Clear;
end;

function TCnvIntegerDictionary.ContainsKey(const AKey: Integer): Boolean;
{$IFNDEF HAS_GENERICS}
var
  stub: TObject;
{$ENDIF}
begin
{$IFDEF HAS_GENERICS}
  Result := FDic.ContainsKey(AKey);
{$ELSE}
  Result := FDic.Find(AKey, stub);
{$ENDIF}
end;

constructor TCnvIntegerDictionary.Create(AAutoFreeObjects: Boolean);
{$IFDEF HAS_GENERICS}
var
  ownerships: TDictionaryOwnerships;
{$ENDIF}
begin
{$IFDEF HAS_GENERICS}
  if AAutoFreeObjects then
    ownerships := [doOwnsValues]
  else
    ownerships := [];
  FDic := TObjectDictionary<Integer, TObject>.Create(ownerships);
{$ELSE}
  FDic := TIntegerHashTrie.Create;
  FDic.AutoFreeObjects := AAutoFreeObjects;
{$ENDIF}
end;

destructor TCnvIntegerDictionary.Destroy;
begin
  FDic.Free;
  inherited;
end;

procedure TCnvIntegerDictionary.Remove(const AKey: Integer);
begin
{$IFDEF HAS_GENERICS}
  FDic.Remove(AKey);
{$ELSE}
  FDic.Delete(AKey);
{$ENDIF}
end;

function TCnvIntegerDictionary.TryGetValue(const AKey: Integer;
  out AValue: TObject): Boolean;
begin
{$IFDEF HAS_GENERICS}
  Result := FDic.TryGetValue(AKey, AValue);
{$ELSE}
  Result := FDic.Find(AKey, AValue);
{$ENDIF}
end;

end.