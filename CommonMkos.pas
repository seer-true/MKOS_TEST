unit CommonMkos;

interface

uses
  WinApi.Windows,
  System.Classes,
  System.SysUtils,
  TasksFunc;

type
  TSearchResult = record
    Pattern: string;
    Positions: TArray<Int64>;
  end;

  TSearchResults = TArray<Int64>;

  ///<summary>
  ///Тип функции поска файлов в DLL
  ///</summary>
  TSearchFilesFunc = function(Masks: PChar; StartDir: PChar; var FileCount: Integer; var FileList: WideString): Boolean; stdcall;
  TSearchPattern = function(FileName: PChar; Pattern: PChar; var Results: TSearchResults; var TotalMatches: Int64): Boolean; stdcall;
  TSearchCallback = procedure(Msg: PChar) of object; stdcall;

//TLogCallback = procedure(Msg: PChar) of object; stdcall;
  TArchiveFolderFunc = function(FolderPath, ArchiveName: PChar; LogCallback: Pointer (* TLogCallback *) ): Boolean; stdcall;
  TStopArchivingProc = procedure; stdcall;

  ///<summary>
  ///Имена экспортируемый функций из DLL
  ///</summary>
procedure ShowDllExports(const hDll: THandle; OutputList: TStringList);

const
  RealTasks: array [0 .. 3] of string = ('SearchFiles', 'SearchPattern', (* 'SearchPattern2', *) 'ArchiveFolder', 'ArchiveFolderAPI');

var
  FSearchDLL: THandle;
  FZIPDLL: THandle;
  SevenZipPath: String = 'C:\Program Files\7-Zip\7z.exe'; //Стандартный путь, можно изменить


implementation

procedure ShowDllExports(const hDll: THandle; OutputList: TStringList);
var
  pExportDir: PImageExportDirectory;
  pNameRVAs: PDWORD;
  pName: PAnsiChar;
  i: Cardinal; //Integer;
  ExportName: string;
  //ExportOrdinal: Word;
  DllBase: Pointer;
  DosHeader: PImageDosHeader;
  NTHeader: PImageNtHeaders;
begin
  DllBase := Pointer(hDll);
  DosHeader := DllBase;
  if DosHeader^.e_magic <> IMAGE_DOS_SIGNATURE then
    raise Exception.Create('Неверный формат PE-файла');
  NTHeader := PImageNtHeaders(PByte(DllBase) + DosHeader^._lfanew);
  if NTHeader^.Signature <> IMAGE_NT_SIGNATURE then
    raise Exception.Create('Неверная сигнатура PE-файла');

  pExportDir := PImageExportDirectory(PByte(DllBase) + NTHeader^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress);
  if Assigned(pExportDir) then begin
    pNameRVAs := PDWORD(PByte(DllBase) + pExportDir^.AddressOfNames);
    for i := 0 to pExportDir^.NumberOfNames - 1 do begin
      pName := PAnsiChar(PByte(DllBase) + pNameRVAs^);
      ExportName := string(pName);
      //ExportOrdinal := pExportDir^.Base + i;
      OutputList.Add(ExportName);
      Inc(pNameRVAs);
    end;
  end;
end;

end.
