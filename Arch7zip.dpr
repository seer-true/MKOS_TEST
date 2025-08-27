library Arch7zip;

uses
{$IFDEF DEBUG}
  //FastMM4 in '..\FastMM4\FastMM4.pas'
{$ENDIF }
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  Winapi.Windows,
  CommonMkos in 'CommonMkos.pas';
{$R *.res}

//тип callback-функции
type
  TLogCallback = procedure(Msg: PChar); stdcall;

(* const
  SevenZipPath = 'C:\Program Files\7-Zip\7z.exe'; //Стандартный путь, можно изменить *)

var
  ArchStopEvent: THandle = 0;

function InitArchiving: Boolean; stdcall;
begin
  ArchStopEvent := CreateEvent(//именованное событие для остановки
    nil, //атрибуты безопасности (по умолчанию)
    True, //ручной сброс (Manual Reset)
    False, //начальное состояние (не сигнализировано)
    'Global\7zArchiverStopEvent'//имя Global - для всех сессий)
    );
  Result := (ArchStopEvent <> 0);
end;

//Основная функция архивации
function ArchiveFolder(FolderPath, ArchiveName: PChar; Callback: TLogCallback): Boolean; stdcall;
var
  CmdLine: string;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  SecAttr: TSecurityAttributes;
  hReadPipe, hWritePipe: THandle;
  Buffer: array [0 .. 255] of AnsiChar;
  BytesRead: DWORD;
  Output: string;
  LastFile: string;
  ProcStop: Boolean;
begin
  Result := False;
  ProcStop := False;
  if not Assigned(Callback) then
    Exit;
  if not FileExists(SevenZipPath) then
  begin
    Callback(PChar('Ошибка: 7-Zip не найден по пути ' + SevenZipPath));
    Exit;
  end;

  if ArchStopEvent <> 0 then //сброс или создание события остановки
    ResetEvent(ArchStopEvent)
  else
  begin
    if not InitArchiving then begin
      Callback('Ошибка: Не удалось создать событие остановки');
      Exit;
    end;
  end;

  //канал для чтения вывода
  SecAttr.nLength := SizeOf(SecAttr);
  SecAttr.lpSecurityDescriptor := nil;
  SecAttr.bInheritHandle := True;
  if not CreatePipe(hReadPipe, hWritePipe, @SecAttr, 0) then
  begin
    Callback(PChar('Ошибка создания канала'));
    Exit;
  end;
  try
//-bsp1 для вывода информации о прогрессе
    CmdLine := Format('"%s" a -tzip -bb3 "%s" "%s\*"', [SevenZipPath, string(ArchiveName), string(FolderPath)]);
//CmdLine := Format('a -tzip -bb3 "%s" "%s\*"', [string(ArchiveName), string(FolderPath)]);
    FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
    StartupInfo.cb := SizeOf(TStartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdOutput := hWritePipe;
    StartupInfo.hStdError := hWritePipe;
    if CreateProcess(PChar(SevenZipPath), //имя исполняемого модуля
      PChar(CmdLine), //командная строка
      nil, //защита процесса
      nil, //защита потока
      True, //признак наследования дескриптора
      CREATE_NO_WINDOW, //флаги создания процесса
      nil, //блок новой среды окружения
      nil, //текущий каталог const
      StartupInfo, //вид главного окна
      ProcessInfo//информация о процессе
      ) then
    begin
      try
        CloseHandle(hWritePipe);
        while True do begin
          if WaitForSingleObject(ArchStopEvent, 100) = WAIT_OBJECT_0 then begin //проверяем событие остановки
            Callback('Получен сигнал остановки...');
            if not TerminateProcess(ProcessInfo.hProcess, 0) then
              Callback(PChar('Ошибка завершения процесса: ' + SysErrorMessage(GetLastError)))
            else begin
              ProcStop := True;
              Callback('Процесс принудительно завершён');
            end;
            Break;
          end;

          if not ReadFile(hReadPipe, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) or (BytesRead = 0) then
          begin
            if WaitForSingleObject(ProcessInfo.hProcess, 100) <> WAIT_TIMEOUT then
              Break;
            Continue;
          end;

       //анализируем вывод для определения текущего файла
          Buffer[BytesRead] := #0;
          Output := string(AnsiString(Buffer));
          if Pos('+', Output) = 1 then //Строка начинается с "+ " - это информация о файле
          begin //как показала практика 7z просает свой вывод пачками и это не работает
            LastFile := Trim(Copy(Output, 3, MaxInt));
            Callback(PChar('Обработка файла: ' + LastFile));
          end
          else
            if Trim(Output) <> '' then
            begin
              Callback(PChar(Output));
            end;
        end;

        if FileExists(ArchiveName) then begin
          if ProcStop then
            Callback('Процесс прерван принудительно. Вероятно архив поврежден.');
          Callback(PChar(Format('Процесс завершен. Файл "%s" создан.', [string(ArchiveName)])));
        end
        else
          Callback(PChar(Format('Процесс завершен. Файл "%s" не создан.', [string(ArchiveName)])));

        Result := True;
      finally
        CloseHandle(ProcessInfo.hThread);
        CloseHandle(ProcessInfo.hProcess);
      end;
    end
    else
    begin
      Callback(PChar('Ошибка запуска 7-Zip: ' + SysErrorMessage(GetLastError)));
    end;
  finally
    CloseHandle(hReadPipe);
  end;
end;

procedure StopArchiving; stdcall;
begin
  if ArchStopEvent <> 0 then
    SetEvent(ArchStopEvent); //Сигнализируем о необходимости остановки
end;



exports
//InitArchiving,
  ArchiveFolder,
  StopArchiving
//  , ArchiveFolderAPI
  ;

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True; //отслеживание утечек памяти
{$ENDIF}

end.
