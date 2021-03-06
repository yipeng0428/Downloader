unit UnitCompress;

interface

uses
  SysUtils, Classes, ZLib;

procedure CompressFile(Source, Target: String); stdcall;
procedure DecompressFile(Source, Target: String); stdcall;

procedure CompressToStream(FileName: String; Stream: TStream); stdcall;
procedure DecompressToStream(FileName: String; Stream: TStream); stdcall;

procedure CompressStream(InStream, OutStream: TStream); stdcall;
procedure DecompressStream(InStream, OutStream: TStream); stdcall;

implementation

const
  COMPRESS_ERROR = '压缩文件时出现内部错误:';
  DECOMPRESS_ERROR = '解压文件时出现内部错误:';
  COMPRESS_STRM_ERROR = '压缩流时出现内部错误:';
  DECOMPRESS_STRM_ERROR = '解压流时出现内部错误:';
  BufSize = $4096;
  
procedure CompressFile(Source, Target: String);
var
  i: Integer;
  Buf: array [0 .. BufSize] of byte;
  ComStream: TCompressionStream;
  InStream, OutStream: TFileStream;
begin
  if not FileExists(Source) then
    Exit;
  InStream := Nil;
  OutStream := nil;
  ComStream := nil;
  try
    
    InStream := TFileStream.Create(Source, fmOpenRead OR fmShareDenyNone);
    OutStream := TFileStream.Create(Target, fmCreate OR fmShareDenyWrite);
    ComStream := TCompressionStream.Create(clMax, OutStream);
    
    for i := 1 to (InStream.Size div BufSize) do
    begin
      InStream.ReadBuffer(Buf, BufSize);
      ComStream.Write(Buf, BufSize);
    end;

    i := InStream.Size mod BufSize;
    if (i > 0) then
    begin
      InStream.ReadBuffer(Buf, i);
      ComStream.Write(Buf, i);
    End;

    InStream.Free;
    InStream := nil;
    
    ComStream.Free;
    ComStream := nil;

    OutStream.Free;
    OutStream := nil;
  except
    on E: Exception do
    begin
      if (InStream <> nil) then
        InStream.Free;
      if (OutStream <> nil) then
        OutStream.Free;
      if (ComStream <> nil) then
        ComStream.Free;
      
    end;
  end;
end;

procedure DecompressFile(Source, Target: String);
var
  i: Integer;
  Buf: array [0 .. BufSize] of byte;
  DecomStream: TDecompressionStream;
  MemStream: TMemoryStream;
  OutStream: TFileStream;
begin
  if not FileExists(Source) then
    Exit;

  MemStream := Nil;
  OutStream := nil;
  DecomStream := nil;
  try
    
    MemStream := TMemoryStream.Create;
    MemStream.LoadFromFile(Source);

    OutStream := TFileStream.Create(Target, fmCreate or fmShareDenyWrite);
    DecomStream := TDecompressionStream.Create(MemStream);
    
    repeat
      i := DecomStream.Read(Buf, BufSize);
      OutStream.WriteBuffer(Buf, i);
    until (i = 0);
    
    OutStream.Free;
    OutStream := nil;

    DecomStream.Free;
    DecomStream := nil;

    MemStream.Free;
    MemStream := Nil;
  except
    on E: Exception do
    begin
      if (MemStream <> nil) then
        MemStream.Free;
      if (OutStream <> nil) then
        OutStream.Free;
      if (DecomStream <> nil) then
        DecomStream.Free;
      
    end;
  end;
end;

procedure CompressToStream(FileName: String; Stream: TStream);
var
  i: Integer;
  Buf: array [0 .. BufSize] of byte;
  ComStream: TCompressionStream;
  InStream: TFileStream;
begin
  if not FileExists(FileName) then
    Exit;
  InStream := Nil;
  ComStream := nil;
  try
    
    InStream := TFileStream.Create(FileName, fmOpenRead OR fmShareDenyNone);
    ComStream := TCompressionStream.Create(clMax, Stream);
    
    for i := 1 to (InStream.Size div BufSize) do
    begin
      InStream.ReadBuffer(Buf, BufSize);
      ComStream.Write(Buf, BufSize);
    end;

    i := InStream.Size mod BufSize;
    if (i > 0) then
    begin
      InStream.ReadBuffer(Buf, i);
      ComStream.Write(Buf, i);
    End;

    InStream.Free;
    InStream := nil;

    ComStream.Free;
    ComStream := nil;
    
  except
    on E: Exception do
    begin
      if (InStream <> nil) then
        InStream.Free;
      if (ComStream <> nil) then
        ComStream.Free;
      
    end;
  end;
end;

procedure DecompressToStream(FileName: String; Stream: TStream);
var
  i: Integer;
  Buf: array [0 .. BufSize] of byte;
  DecomStream: TDecompressionStream;
  MemStream: TMemoryStream;
begin
  if not FileExists(FileName) then
    Exit;
  MemStream := Nil;
  DecomStream := nil;
  try
    
    MemStream := TMemoryStream.Create;
    MemStream.LoadFromFile(FileName);

    DecomStream := TDecompressionStream.Create(MemStream);
    
    repeat
      i := DecomStream.Read(Buf, BufSize);
      Stream.WriteBuffer(Buf, i);
    until (i = 0);
    Stream.Position := 0;

    DecomStream.Free;
    DecomStream := nil;

    MemStream.Free;
    MemStream := Nil;
  except
    on E: Exception do
    begin
      if (MemStream <> nil) then
        MemStream.Free;
      if (DecomStream <> nil) then
        DecomStream.Free;
      
    end;
  end;
end;

procedure CompressStream(InStream, OutStream: TStream);
var
  i: Integer;
  Buf: array [0 .. BufSize] of byte;
  ComStream: TCompressionStream;
begin
  ComStream := Nil;
  try
    InStream.Position := 0;
    ComStream := TCompressionStream.Create(clMax, OutStream);

    for i := 1 to (InStream.Size div BufSize) do
    begin
      InStream.ReadBuffer(Buf, BufSize);
      ComStream.Write(Buf, BufSize);
    end;

    i := InStream.Size mod BufSize;
    if (i > 0) then
    begin
      InStream.ReadBuffer(Buf, i);
      ComStream.Write(Buf, i);
    End;

    ComStream.Free;
    ComStream := nil;
    
  except
    on E: Exception do
    begin
      if (ComStream <> nil) then
        ComStream.Free;
      
    end;
  end;
end;

procedure DecompressStream(InStream, OutStream: TStream);
var
  i: Integer;
  Buf: array [0 .. BufSize] of byte;
  DecomStream: TDecompressionStream;
begin
  DecomStream := nil;
  try
    
    DecomStream := TDecompressionStream.Create(InStream);

    repeat
      i := DecomStream.Read(Buf, BufSize);
      OutStream.WriteBuffer(Buf, i);
    until (i = 0);
    OutStream.Position := 0;

    DecomStream.Free;
    DecomStream := nil;
  except
    on E: Exception do
    begin
      if (DecomStream <> nil) then
        DecomStream.Free;
      
    end;
  end;
end;

end.
 