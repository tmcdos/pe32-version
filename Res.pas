unit Res;

interface

uses Classes,FileIO,PE;

const
  RT_VERSION = 16;
{
Resource Types:
1: Cursor
2: Bitmap
3: Icon
4: Menu
5: Dialog
6: String
7: Fontdir
8: Font
9: Accelerator
10: RCData
11: MessageTable
16: Version
17: dlginclude
19: plugplay
20: vxd
21: anicursor
22: aniicon
23: html
}

Type
  TResourceDir = packed record
    characteristics : DWORD; // Resource flags, reserved for future use; currently set to zero.
    timeDateStamp : DWORD;   // Time the resource data was created by the resource compiler.
    versionMajor : WORD;     // Major version number, set by the user.
    versionMinor : WORD;     // Minor version number.
    cNameEntries : WORD;     // Number of directory entries, immediately following the table, that use strings to identify Type, Name, or Language (depending on the level of the table).
    cIDEntries : WORD;       // Number of directory entries, immediately following the Name entries, that use numeric identifiers for Type, Name, or Language.
  end;
  PResourceDir = ^TResourceDir;

  TResourceDirEntry = packed record
    name : DWORD;         // RVA Address of integer or string that gives the Type, Name, or Language identifier, depending on level of table.
    RVA : DWORD;          // RVA High bit 0. Address of a Resource Data Entry (a leaf).
                          // RVA High bit 1. Lower 31 bits are the address of another Resource Directory Table (the next level down).
  end;
  PResourceDirEntry = ^TResourceDirEntry;

  TResourceEntry = packed record
    OffsetToData : DWORD;
    Size : DWORD;
    CodePage : DWORD;
    Reserved : DWORD
  end;
  PResourceEntry = ^TResourceEntry;

procedure parse_resource_dir(F:TFileStream;var Header:TImageSectionHeader; Ofs:Cardinal; Level,ResType:Integer);
  
Implementation

uses SysUtils;

procedure parse_version_info(F:TFileStream;Ofs,Size:Cardinal);
var
  marker:Int64;
  len:Integer;
  v1,v2,v3,v4:Word;
  // VS_VERSION_INFO
  wLength:Word;
  wValueLength:Word;
  wType:Word; // 1 = Text data, 0 = binary data (USUALLY 0)
  szKey:Array[1..16] of WideChar; // UNICODE "VS_VERSION_INFO" with trailing 0
  fix_ver:TVSFixedFileInfo;
begin
// StringFileInfo
// unsigned short int wLength - with Children
// unsigned short int wValueLength = 0
// unsigned short int wType (1 = Text data, 0 = binary data)
// WCHAR szKey[] = "StringFileInfo" in UNICODE
// padding to 8 byte boundary
// Children - 0 or 1 struct StringTable, followed by 0 or 1 struct VarFileInfo

// StringTable
// wLength - with Children
// wValueLength = 0
// wType (1 = Text data, 0 = binary data)
// WCHAR szKey[] - 8 digit hexadecimal as UNICODE string (MSB - Lang, LBS - Codepage)
// padding to 8 byte boundary
// struct String Children[]

// String
// wLength
// wValueLength - length of Value
// wType
// WHCAR szKey[] - UNICODE name (Comments, CompanyName, FileDescription, FileVersion, InternalName, LegalCopyright, LegalTrademarks, OriginalFilename, PrivateBuild - only if VS_FF_PRIVATEBUILD, ProductName, ProductVersion, SpecialBuild - if VS_FF_SPECIALBUILD)
// padding to 8 byte boundary
// WCHAR Value[]

// VarFileInfo
// wLength - with Children
// wValueLength = 0
// wType
// WCHAR szKey[] = "VarFileInfo" in UNICODE
// padding to 8 byte boundary
// struct Var Children[]

// Var
// wLength
// wValueLength - length of Value
// wType
// WCHAR szKey[] = "Translation" in UNICODE
// padding to 8 byte boundary
// DWORD Value[] - 1 or more (Lang,CodePage) pairs

  marker:=F.Position;
  F.Seek(Ofs,soFromBeginning);

  wLength:=ReadWord(F);
  wValueLength:=ReadWord(F);
  wType:=ReadWord(F);
  ReadBin(F,@szKey,Sizeof(szKey));

  // Padding1 - several words to 4 byte boundary
  while F.Position Mod 4 <>0 do
    len:=ReadWord(F);
  if wValueLength<>0 then
  begin
  	// should read wValueLength bytes in theory
	  read_fixed_ver(F,fix_ver);
	  if fix_ver.dwSignature = $FEEF04BD then
	  begin
	  	v1 := fix_ver.dwFileVersionMS shr 16;
	  	v2 := fix_ver.dwFileVersionMS and $ffff;
	  	v3 := fix_ver.dwFileVersionLS shr 16;
	  	v4 := fix_ver.dwFileVersionLS and $ffff;
	  	WriteLn(Format('%u.%u.%u.%u',[v1,v2,v3,v4]));
	  end
	  else WriteLn(Format('FileVer signature: %x',[fix_ver.dwSignature]));
	end;
  F.Seek(marker,soFromBeginning);
end;

procedure read_resource_dir(F:TFileStream; Adres:Cardinal;var ResDir:TResourceDir);
var
  marker:Int64;
begin
  marker:=F.Position;
  F.Seek(Adres,soFromBeginning);
  F.ReadBuffer(ResDir,SizeOf(ResDir));
  F.Seek(marker,soFromBeginning);
end;

procedure read_resource_dir_entry(F:TFileStream; Adres:Cardinal;var DirEntry:TResourceDirEntry; Ofs:Cardinal);
var
  marker:Int64;
begin
  marker:=F.Position;
  f.Seek(Adres+Ofs,soFromBeginning);
  DirEntry.Name:=ReadInt(F);
  DirEntry.RVA:=ReadInt(F);
  f.Seek(marker,soFromBeginning);
end;

procedure read_resource_data(F:TFileStream; Adres:Cardinal;var ResData:TResourceEntry; Ofs:Cardinal);
var
  marker:Int64;
begin
  marker:=F.Position;
  F.Seek(Adres+Ofs,soFromBeginning);
  F.ReadBuffer(ResData,SizeOf(ResData));
  F.Seek(marker,soFromBeginning);
end;

procedure parse_resource_dir(F:TFileStream;var Header:TImageSectionHeader; Ofs:Cardinal; Level,ResType:Integer);
var
  ResDir:TResourceDir;
  DirEntry:TResourceDirEntry;
  ResData:TResourceEntry;
  count,t:Integer;
begin
  read_resource_dir(F,Header.PointerToRawData+Ofs,ResDir);
  Inc(Ofs,SizeOf(Resdir));
  count:=ResDir.cNameEntries+ResDir.cIDEntries;
  if count=0 then
  begin
    Writeln(Format('Zero entries in resource section %s',[PAnsiChar(Header.Name[0])]));
    Exit;
  End;
  for t:=0 To count-1 do
  begin
    read_resource_dir_entry(F,Header.PointerToRawData,DirEntry,Ofs);
    if ((Level=0) and (DirEntry.name = RT_VERSION)) or (Level>0) then
    begin
      if (DirEntry.RVA and $80000000)=0 then
      begin
        read_resource_data(F,Header.PointerToRawData,ResData,DirEntry.RVA);
        if ResType=RT_VERSION then
          parse_version_info(F,Header.PointerToRawData+(ResData.OffsetToData-Header.VirtualAddress),ResData.Size);
      end
      else
      begin
        if level=0 then parse_resource_dir(F,Header,DirEntry.RVA and $7fffffff,level+1,DirEntry.Name)
          else parse_resource_dir(F,Header,DirEntry.RVA and $7fffffff,level+1,ResType);
      end;
    End;
    Inc(Ofs,SizeOf(DirEntry));
  end;
end;

end.
