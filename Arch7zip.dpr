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

//��� callback-�������
type
  TLogCallback = procedure(Msg: PChar); stdcall;

(* const
  SevenZipPath = 'C:\Program Files\7-Zip\7z.exe'; //����������� ����, ����� �������� *)

var
  ArchStopEvent: THandle = 0;

function InitArchiving: Boolean; stdcall;
begin
  ArchStopEvent := CreateEvent(//����������� ������� ��� ���������
    nil, //�������� ������������ (�� ���������)
    True, //������ ����� (Manual Reset)
    False, //��������� ��������� (�� ���������������)
    'Global\7zArchiverStopEvent'//��� Global - ��� ���� ������)
    );
  Result := (ArchStopEvent <> 0);
end;

//�������� ������� ���������
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
    Callback(PChar('������: 7-Zip �� ������ �� ���� ' + SevenZipPath));
    Exit;
  end;

  if ArchStopEvent <> 0 then //����� ��� �������� ������� ���������
    ResetEvent(ArchStopEvent)
  else
  begin
    if not InitArchiving then begin
      Callback('������: �� ������� ������� ������� ���������');
      Exit;
    end;
  end;

  //����� ��� ������ ������
  SecAttr.nLength := SizeOf(SecAttr);
  SecAttr.lpSecurityDescriptor := nil;
  SecAttr.bInheritHandle := True;
  if not CreatePipe(hReadPipe, hWritePipe, @SecAttr, 0) then
  begin
    Callback(PChar('������ �������� ������'));
    Exit;
  end;
  try
//-bsp1 ��� ������ ���������� � ���������
    CmdLine := Format('"%s" a -tzip -bb3 "%s" "%s\*"', [SevenZipPath, string(ArchiveName), string(FolderPath)]);
//CmdLine := Format('a -tzip -bb3 "%s" "%s\*"', [string(ArchiveName), string(FolderPath)]);
    FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
    StartupInfo.cb := SizeOf(TStartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdOutput := hWritePipe;
    StartupInfo.hStdError := hWritePipe;
    if CreateProcess(PChar(SevenZipPath), //��� ������������ ������
      PChar(CmdLine), //��������� ������
      nil, //������ ��������
      nil, //������ ������
      True, //������� ������������ �����������
      CREATE_NO_WINDOW, //����� �������� ��������
      nil, //���� ����� ����� ���������
      nil, //������� ������� const
      StartupInfo, //��� �������� ����
      ProcessInfo//���������� � ��������
      ) then
    begin
      try
        CloseHandle(hWritePipe);
        while True do begin
          if WaitForSingleObject(ArchStopEvent, 100) = WAIT_OBJECT_0 then begin //��������� ������� ���������
            Callback('������� ������ ���������...');
            if not TerminateProcess(ProcessInfo.hProcess, 0) then
              Callback(PChar('������ ���������� ��������: ' + SysErrorMessage(GetLastError)))
            else begin
              ProcStop := True;
              Callback('������� ������������� ��������');
            end;
            Break;
          end;

          if not ReadFile(hReadPipe, Buffer, SizeOf(Buffer) - 1, BytesRead, nil) or (BytesRead = 0) then
          begin
            if WaitForSingleObject(ProcessInfo.hProcess, 100) <> WAIT_TIMEOUT then
              Break;
            Continue;
          end;

       //����������� ����� ��� ����������� �������� �����
          Buffer[BytesRead] := #0;
          Output := string(AnsiString(Buffer));
          if Pos('+', Output) = 1 then //������ ���������� � "+ " - ��� ���������� � �����
          begin //��� �������� �������� 7z ������� ���� ����� ������� � ��� �� ��������
            LastFile := Trim(Copy(Output, 3, MaxInt));
            Callback(PChar('��������� �����: ' + LastFile));
          end
          else
            if Trim(Output) <> '' then
            begin
              Callback(PChar(Output));
            end;
        end;

        if FileExists(ArchiveName) then begin
          if ProcStop then
            Callback('������� ������� �������������. �������� ����� ���������.');
          Callback(PChar(Format('������� ��������. ���� "%s" ������.', [string(ArchiveName)])));
        end
        else
          Callback(PChar(Format('������� ��������. ���� "%s" �� ������.', [string(ArchiveName)])));

        Result := True;
      finally
        CloseHandle(ProcessInfo.hThread);
        CloseHandle(ProcessInfo.hProcess);
      end;
    end
    else
    begin
      Callback(PChar('������ ������� 7-Zip: ' + SysErrorMessage(GetLastError)));
    end;
  finally
    CloseHandle(hReadPipe);
  end;
end;

procedure StopArchiving; stdcall;
begin
  if ArchStopEvent <> 0 then
    SetEvent(ArchStopEvent); //������������� � ������������� ���������
end;



exports
//InitArchiving,
  ArchiveFolder,
  StopArchiving
//  , ArchiveFolderAPI
  ;

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True; //������������ ������ ������
{$ENDIF}

end.
