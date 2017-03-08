unit FileIO;

interface

uses Classes;

function ReadInt(S:TFileStream):LongWord;
function ReadWord(S:TFileStream):Word;
procedure ReadBin(S:TFileStream;p:Pointer;cnt:Integer);

implementation

function ReadInt(S:TFileStream):LongWord;
begin
  S.ReadBuffer(Result,SizeOf(Result));
end;

Function ReadWord(S:TFileStream):Word;
begin
  S.ReadBuffer(Result,SizeOf(Result));
end;

Procedure ReadBin(S:TFileStream;p:Pointer;cnt:Integer);
Begin
  S.ReadBuffer(P^,Cnt);
end;

End.
