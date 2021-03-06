unit RC4Engine;

interface

uses
  Windows;

type
  TRC4Engine = class
  private
    perm: array [0 .. 255] of Byte;
    index1, index2: Byte;
    Initialized: Boolean;
  public
    
    constructor Create(const keybytes: Pointer; keylen: Cardinal); overload;
    constructor Create(); overload;
    destructor Destroy(); override;
    
    procedure Setup(const keybytes: Pointer; const keylen: Cardinal);
    
    procedure Process(const input: Pointer; const output: Pointer;
      len: Cardinal);
  end;
  
procedure ReverseBytes(lpt: Pointer; Length: Cardinal); inline;

implementation

procedure ReverseBytes(lpt: Pointer; Length: Cardinal); inline;
var
  Temp: Pointer;
  i: Cardinal;
begin
  Temp := AllocMem(Length);
  CopyMemory(Temp, lpt, Length);

  for i := 0 to Length - 1 do
    PByte(lpt)[i] := PByte(Temp)[Length - i - 1];

  FreeMem(Temp);
end;

constructor TRC4Engine.Create(const keybytes: Pointer; keylen: Cardinal);
begin
  Setup(keybytes, keylen);
end;

constructor TRC4Engine.Create;
begin
  Initialized := False;
end;

destructor TRC4Engine.Destroy;
begin
  inherited;
end;

procedure TRC4Engine.Process(const input, output: Pointer; len: Cardinal);
var
  i: Cardinal;
  j, k: Byte;
begin
  for i := 0 to len - 1 do
  begin
    Inc(index1);
    Inc(index2, perm[index1]);

    k := perm[index1];
    perm[index1] := perm[index2];
    perm[index2] := k;

    j := perm[index1] + perm[index2];

    PByte(output)[i] := PByte(input)[i] xor perm[j];
  end;
end;

procedure TRC4Engine.Setup(const keybytes: Pointer; const keylen: Cardinal);
var
  i: Cardinal;
  j, k: Byte;
begin
  
  for i := 0 to 255 do
    perm[i] := i;
  
  index1 := 0;
  index2 := 0;
  
  j := 0;
  for i := 0 to 255 do
  begin
    Inc(j, perm[i] + PByte(keybytes)[i mod keylen]);
    k := perm[i];
    perm[i] := perm[j];
    perm[j] := k;
  end;
  Initialized := True;
end;

end.
 