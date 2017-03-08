program pe_version;

{$APPTYPE CONSOLE}

uses
  SysUtils,Classes,PE,FileIO,Res;

var
  F:TFileStream;
  DOS_header:TImageDosHeader;
  ImageHeader: TImageFileHeader;
  OptHeader: TImageOptionalHeader;
  SectHeader: TImageSectionHeader;
  Signature: Array[1..4] of Char;
  t:Integer;

// Needs "yum install ld-linux.so.2" on 64-bit FEDORA

begin
  if ParamCount=0 then
  begin
    WriteLn('Usage: '+ExtractFileName(ParamStr(0))+' <input file>');
    Halt(1);
  end;
  F:=TFileStream.Create(ParamStr(1),fmOpenRead);
  Try
    read_dos_header(F,dos_header);
    F.Seek(DOS_header.e_lfanew,soFromBeginning);
    ReadBin(F,@signature,4);
    if signature<>'PE'#0#0 then
    begin
      WriteLn('This file is not a Microsoft PE format');
      Halt(3);
    end;

    read_image_file_header(F,ImageHeader);
    if ImageHeader.SizeOfOptionalHeader<>0 then
      read_image_optional_header(F,OptHeader,ImageHeader.SizeOfOptionalHeader);
    for t:=0 to ImageHeader.NumberOfSections-1 do
    begin
      read_section_header(F,SectHeader);
      if StrComp(@SectHeader.Name[0],'.rsrc')=0 then
      begin
        parse_resource_dir(F,SectHeader,0,0,0);
        Halt(0);
      end;
    end;
    WriteLn('This file has no resources');
    Halt(4);
  Finally
    F.Free;
  end;
end.
