unit PE;

interface

uses Types,Classes;

const
  IMAGE_NUMBEROF_DIRECTORY_ENTRIES        = 16;
  IMAGE_SIZEOF_SHORT_NAME                  = 8;

type
  DWORD = Types.DWORD;
  PDWORD = ^DWORD;
  LCID = DWORD;

  PImageDosHeader = ^TImageDosHeader;
  _IMAGE_DOS_HEADER = packed record      { DOS .EXE header                  }
      e_magic: Word;                     { Magic number                     }
      e_cblp: Word;                      { Bytes on last page of file       }
      e_cp: Word;                        { Pages in file                    }
      e_crlc: Word;                      { Relocations                      }
      e_cparhdr: Word;                   { Size of header in paragraphs     }
      e_minalloc: Word;                  { Minimum extra paragraphs needed  }
      e_maxalloc: Word;                  { Maximum extra paragraphs needed  }
      e_ss: Word;                        { Initial (relative) SS value      }
      e_sp: Word;                        { Initial SP value                 }
      e_csum: Word;                      { Checksum                         }
      e_ip: Word;                        { Initial IP value                 }
      e_cs: Word;                        { Initial (relative) CS value      }
      e_lfarlc: Word;                    { File address of relocation table }
      e_ovno: Word;                      { Overlay number                   }
      e_res: array [0..3] of Word;       { Reserved words                   }
      e_oemid: Word;                     { OEM identifier (for e_oeminfo)   }
      e_oeminfo: Word;                   { OEM information; e_oemid specific}
      e_res2: array [0..9] of Word;      { Reserved words                   }
      e_lfanew: LongInt;                  { File address of new exe header   }
  end;
  TImageDosHeader = _IMAGE_DOS_HEADER;
  IMAGE_DOS_HEADER = _IMAGE_DOS_HEADER;

  PImageFileHeader = ^TImageFileHeader;
  _IMAGE_FILE_HEADER = packed record
    Machine: Word;
    NumberOfSections: Word;
    TimeDateStamp: DWORD;
    PointerToSymbolTable: DWORD;
    NumberOfSymbols: DWORD;
    SizeOfOptionalHeader: Word;
    Characteristics: Word;
  end;
  TImageFileHeader = _IMAGE_FILE_HEADER;
  IMAGE_FILE_HEADER = _IMAGE_FILE_HEADER;

  PImageDataDirectory = ^TImageDataDirectory;
  _IMAGE_DATA_DIRECTORY = record
    VirtualAddress: DWORD;
    Size: DWORD;
  end;
  TImageDataDirectory = _IMAGE_DATA_DIRECTORY;
  IMAGE_DATA_DIRECTORY = _IMAGE_DATA_DIRECTORY;

  PImageOptionalHeader = ^TImageOptionalHeader;
  _IMAGE_OPTIONAL_HEADER = packed record
    { Standard fields. }
    Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    SizeOfCode: DWORD;
    SizeOfInitializedData: DWORD;
    SizeOfUninitializedData: DWORD;
    AddressOfEntryPoint: DWORD;
    BaseOfCode: DWORD;
    BaseOfData: DWORD;
    { NT additional fields. }
    ImageBase: DWORD;
    SectionAlignment: DWORD;
    FileAlignment: DWORD;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: DWORD;
    SizeOfImage: DWORD;
    SizeOfHeaders: DWORD;
    CheckSum: DWORD;
    Subsystem: Word;
    DllCharacteristics: Word;
    SizeOfStackReserve: DWORD;
    SizeOfStackCommit: DWORD;
    SizeOfHeapReserve: DWORD;
    SizeOfHeapCommit: DWORD;
    LoaderFlags: DWORD;
    NumberOfRvaAndSizes: DWORD;
    DataDirectoryCount:Integer;
    DataDirectory: packed array[0..IMAGE_NUMBEROF_DIRECTORY_ENTRIES-1] of TImageDataDirectory;
  end;
  TImageOptionalHeader = _IMAGE_OPTIONAL_HEADER;
  IMAGE_OPTIONAL_HEADER = _IMAGE_OPTIONAL_HEADER;

  TISHMisc = packed record
    case Integer of
      0: (PhysicalAddress: DWORD);
      1: (VirtualSize: DWORD);
  end;

  PImageSectionHeader = ^TImageSectionHeader;
  _IMAGE_SECTION_HEADER = packed record
    Name: packed array[0..IMAGE_SIZEOF_SHORT_NAME-1] of Byte;
    Misc: TISHMisc;
    VirtualAddress: DWORD;
    SizeOfRawData: DWORD;
    PointerToRawData: DWORD;
    PointerToRelocations: DWORD;
    PointerToLinenumbers: DWORD;
    NumberOfRelocations: Word;
    NumberOfLinenumbers: Word;
    Characteristics: DWORD;
  end;
  TImageSectionHeader = _IMAGE_SECTION_HEADER;
  IMAGE_SECTION_HEADER = _IMAGE_SECTION_HEADER;

  PVSFixedFileInfo = ^TVSFixedFileInfo;
  tagVS_FIXEDFILEINFO = packed record
    dwSignature: DWORD;        { e.g. $feef04bd }
    dwStrucVersion: DWORD;     { e.g. $00000042 = "0.42" }
    dwFileVersionMS: DWORD;    { e.g. $00030075 = "3.75" }
    dwFileVersionLS: DWORD;    { e.g. $00000031 = "0.31" }
    dwProductVersionMS: DWORD; { e.g. $00030010 = "3.10" }
    dwProductVersionLS: DWORD; { e.g. $00000031 = "0.31" }
    dwFileFlagsMask: DWORD;    { = $3F for version "0.42" }
    dwFileFlags: DWORD;        { e.g. VFF_DEBUG | VFF_PRERELEASE }
    dwFileOS: DWORD;           { e.g. VOS_DOS_WINDOWS16 }
    dwFileType: DWORD;         { e.g. VFT_DRIVER }
    dwFileSubtype: DWORD;      { e.g. VFT2_DRV_KEYBOARD }
    dwFileDateMS: DWORD;       { e.g. 0 }
    dwFileDateLS: DWORD;       { e.g. 0 }
  end;
  TVSFixedFileInfo = tagVS_FIXEDFILEINFO;
  VS_FIXEDFILEINFO = tagVS_FIXEDFILEINFO;

procedure read_dos_header(S:TFileStream;var Header:TImageDosHeader);
procedure read_image_file_header(S:TFileStream;var Header:TImageFileHeader);
procedure read_image_optional_header(S:TFileStream;var Header:TImageOptionalHeader;HdrSize:Integer);
procedure read_section_header(S:TFileStream;var Header:TImageSectionHeader);
procedure read_fixed_ver(S:TFileStream;var FixVer:TVSFixedFileInfo);

implementation

uses FileIO;

function read_unicode(F:TFileStream;Adres:Cardinal;S:PAnsiChar;max_chars:Integer):Integer;
var
  marker:Int64;
  t,len:Integer;
  ch:Char;
begin
  marker:=F.Position;
  F.Seek(Adres,soFromBeginning);
  t:=0;
  len:=ReadWord(F);
  while t<len do
  Begin
    F.ReadBuffer(ch,1);
    F.ReadBuffer(ch,1);
    if ch=#0 then break;
    s[t]:=ch;
    Inc(t);
    if t=max_chars-1 then break;
  end;
  s[t]:=#0;
  F.Seek(marker,soFromBeginning);
  Result:=t;
end;

procedure read_dos_header(S:TFileStream;var Header:TImageDosHeader);
begin
  S.ReadBuffer(Header,SizeOf(Header));
end;

procedure read_image_file_header(S:TFileStream;var Header:TImageFileHeader);
begin
  S.ReadBuffer(Header,SizeOf(Header));
end;

procedure read_image_optional_header(S:TFileStream;var Header:TImageOptionalHeader;HdrSize:Integer);
Var
  i:Integer;
begin
  S.ReadBuffer(Header,28);
  if HdrSize<=28 then Exit;
  S.ReadBuffer(Header.ImageBase,Cardinal(@Header.DataDirectoryCount)-Cardinal(@Header.ImageBase));
  if HdrSize>96 then
  begin
    Header.DataDirectoryCount:=(HdrSize-96) Div SizeOf(TImageDataDirectory);
    for i:=0 to Header.DataDirectoryCount-1 do
      S.ReadBuffer(Header.DataDirectory[i],SizeOf(TImageDataDirectory));
  end;
end;

procedure read_section_header(S:TFileStream;var Header:TImageSectionHeader);
begin
  S.ReadBuffer(Header,SizeOf(Header));
end;

procedure read_fixed_ver(S:TFileStream;var FixVer:TVSFixedFileInfo);
begin
  S.ReadBuffer(FixVer,SizeOf(FixVer));
end;

end.