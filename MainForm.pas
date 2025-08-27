/// <remarks>
/// <para>
/// Убийство потока <see href="https://stackoverflow.com/questions/14033894/how-do-i-stop-a-thread-before-its-finished-running" /><br />
/// Пример <see href="https://www.kansoftware.ru/?tid=13951" />
/// </para>
/// <para>
/// <see href="https://www.gunsmoker.ru/2009/01/blog-post.html" /><br /><see href="https://www.gunsmoker.ru/2019/06/developing-DLL-API" />
/// </para>
/// </remarks>
unit MainForm;

interface

uses Winapi.Windows, Winapi.Messages, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ExtDlgs,
  System.SysUtils,
  System.Classes,
  System.Types,
  System.IOUtils,
  System.StrUtils,
  System.Variants,
  System.Threading,
  Data.DB, Vcl.Grids,
  Vcl.DBGrids, Datasnap.DBClient, Vcl.Buttons,
  CommonMkos, TasksFunc;

type
  TfrmMain = class(TForm)
    mResults: TMemo;
    OpenDialog: TFileOpenDialog;
    pLower: TPanel;
    btnViewResults: TButton;
    pTasks: TPanel;
    bStartTask: TButton;
    bStopTask: TButton;
    cdsTasks: TClientDataSet;
    cdsTasksID: TIntegerField;
    cdsTasksTask: TStringField;
    cdsTasksStatus: TSmallintField;
    cdsTasksTimeStart: TDateTimeField;
    cdsTasksTimeEnd: TDateTimeField;
    dsTask: TDataSource;
    dbgTasks: TDBGrid;
    cdsTasksSStatus: TStringField;
    cdsTasksFThread: TLargeintField;
    FileOpenDialog: TOpenTextFileDialog;
    grpFindFiles: TGroupBox;
    lblMasks: TLabel;
    bSelectFolder: TSpeedButton;
    eFolder: TEdit;
    eMasks: TEdit;
    grpSearchInFile: TGroupBox;
    lblSearchInFile: TLabel;
    bSelectFile: TSpeedButton;
    eSearchPatterns: TEdit;
    cbMatches: TComboBox;
    eFile: TEdit;
    e7zName: TEdit;
    bSelect7z: TSpeedButton;

    procedure FormCreate(Sender: TObject);
    procedure btnViewResultsClick(Sender: TObject);
    procedure bStartTaskClick(Sender: TObject);
    procedure bStopTaskClick(Sender: TObject);
    procedure lvTasksDblClick(Sender: TObject);
    procedure cdsTasksCalcFields(DataSet: TDataSet);
    procedure cbMatchesKeyPress(Sender: TObject; var Key: Char);
    procedure bSelectFolderClick(Sender: TObject);
    procedure bSelectFileClick(Sender: TObject);
    procedure bSelect7zClick(Sender: TObject);
  private
    procedure StringReceived(const S: string);
    procedure StatusTask(const TaskIdx: integer; const Status: TTaskStatus = System.Threading.TTaskStatus.Created);

    procedure LoadSevenZipDLL;
    procedure UnloadSevenZipDLL;
    procedure LoadSearchDLL;
    procedure UnloadSearchDLL;
  public
    ThFindFiles: TThFindFiles;
    ThSearchPattern: TThSearchPattern;

    ArchTask: ITask;
    ArchiveFunc: TArchiveFolderFunc;
    StopArchiving: TStopArchivingProc;

    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

uses System.SyncObjs;

{$R *.dfm}

procedure FileProgressCallback(Msg: PChar); stdcall;
begin
  TThread.Queue(nil,
    procedure
    begin
      frmMain.mResults.Lines.Add(string(Msg)); // Или выводим в спец. поле
    end);
end;

procedure ArchiveLogCallback(Msg: PChar); stdcall;
begin
  TThread.Queue(nil,
    procedure
    begin
      frmMain.StringReceived(string(Msg));
    end);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  ListTasks: TStringList;
begin
  LoadSearchDLL;
  LoadSevenZipDLL;
  e7zName.Text := SevenZipPath;
  ListTasks := TStringList.Create;
  // cdsTasks.CreateDataSet;
  cdsTasks.Open;
  try
    // поисковая DLL
    ShowDllExports(FSearchDLL, ListTasks);
    for var i := 0 to Length(RealTasks) - 1 do
    begin
      if ListTasks.IndexOf(RealTasks[i]) >= 0 then
      begin
        cdsTasks.InsertRecord([i, RealTasks[i], 0, null, null]);
      end;
    end;
    ListTasks.Clear;
    // архивирующая DLL
    ShowDllExports(FZipDLL, ListTasks);
    for var i := 0 to Length(RealTasks) - 1 do
    begin
      if ListTasks.IndexOf(RealTasks[i]) >= 0 then
      begin
        cdsTasks.InsertRecord([i, RealTasks[i], 0, null, null]);
      end;
    end;

    eFolder.Text := GetCurrentDir;
  finally
    ListTasks.Free;
  end;
  cdsTasks.First;
end;

destructor TfrmMain.Destroy;
begin
  UnloadSearchDLL;
  UnloadSevenZipDLL;
end;

procedure TfrmMain.LoadSearchDLL;
begin
  FSearchDLL := SafeLoadLibrary('SearchFile.dll');
  if FSearchDLL = 0 then
    ShowMessage('Не удалось загрузить SearchFile.dll');
end;

procedure TfrmMain.UnloadSearchDLL;
begin
  if FSearchDLL <> 0 then
  begin
    FreeLibrary(FSearchDLL);
    FSearchDLL := 0;
  end;
end;

procedure TfrmMain.StatusTask(const TaskIdx: integer; const Status: TTaskStatus (* = System.Threading.TTaskStatus.Created *) );
begin
  if cdsTasks.Locate('ID', Ord(TaskIdx), []) then
  begin
    cdsTasks.Edit;
    cdsTasksStatus.Value := Ord(Status);
    cdsTasks.Post;
  end
end;

procedure TfrmMain.bSelect7zClick(Sender: TObject);
begin
  FileOpenDialog.FileName := e7zName.Text;
  if FileOpenDialog.Execute then
  begin
    e7zName.Text := FileOpenDialog.FileName;
    SevenZipPath := e7zName.Text;
  end;
end;

procedure TfrmMain.bSelectFileClick(Sender: TObject);
begin
  FileOpenDialog.FileName := eFile.Text;
  if FileOpenDialog.Execute then
    eFile.Text := FileOpenDialog.FileName;
end;

procedure TfrmMain.bSelectFolderClick(Sender: TObject);
begin
  OpenDialog.DefaultFolder := eFolder.Text;
  if OpenDialog.Execute then
    eFolder.Text := OpenDialog.FileName;
end;

procedure TfrmMain.bStartTaskClick(Sender: TObject);
var
  TaskNum: integer;
  ArchiveName: string;
  // P: Pointer;
begin
  TaskNum := IndexStr(cdsTasksTask.AsString, RealTasks);
  if TaskNum = cdsTasksID.AsInteger then
  begin
    cdsTasks.Edit;
    cdsTasksTimeStart.AsString := '';
    cdsTasksTimeEnd.AsString := '';
    case TaskNum of
      0:
        begin // поиск файлов
          if not DirectoryExists(eFolder.Text) then
            raise Exception.Create('Каталог "' + eFolder.Text + '" отсуствует.');
          if Trim(eMasks.Text) = '' then
            raise Exception.Create('Укажите маски для поиска.');

          mResults.Lines.Add('=== Старт поиска файлов ===');

          ThFindFiles := TThFindFiles.Create(True); // создаем поток

          ThFindFiles.TaskID := cdsTasksID.AsInteger;
          cdsTasksFThread.AsLargeInt := integer(ThFindFiles);

          ThFindFiles.TaskID := cdsTasksID.AsInteger;

          // eFolder.Text := 'D:\Insures\insures5ase\bin\'; // для тестов
          // eFile_s.Text := 'C:\DataBase\';

          with ThFindFiles do
          begin
            OnStringReceived := StringReceived;
            OnStatusTask := StatusTask;

            StartFolder := eFolder.Text;
            Masks := eMasks.Text;

            FreeOnTerminate := True;

            LoadFunc(FSearchDLL, cdsTasksTask.AsString);

            Start; // запускаем поток
          end;
        end;
      1:
        begin // поиск в файле
          if not FileExists(eFile.Text) then
            raise Exception.Create('Файл "' + eFile.Text + '" отсуствует.');
          if Trim(eSearchPatterns.Text) = '' then
            raise Exception.Create('Укажите наблоны для поиска.');

          mResults.Lines.Add('=== Старт поиска шаблонов ===');

          ThSearchPattern := TThSearchPattern.Create(True); // создаем поток

          ThSearchPattern.TaskID := cdsTasksID.AsInteger;
          cdsTasksFThread.AsLargeInt := integer(ThSearchPattern);

          // eFile.Text := 'D:\tmp\35645\load_wds_contract.sql';//'D:\Insures\insures5ase\bin\iRefBooks.rsm'; // для тестов
          // eFile_s.Text := 'C:\DevelopXE\Declension.7z';

          with ThSearchPattern do
          begin
            OnStringReceived := StringReceived;
            OnStatusTask := StatusTask;

            TargetFile := eFile.Text;
            Patterns := eSearchPatterns.Text;
            Matches := StrToUInt(cbMatches.Text);

            FreeOnTerminate := True;

            LoadFunc(FSearchDLL, cdsTasksTask.AsString);

            Start; // запускаем поток
          end;
        end;
      2:
        begin // архивирование 7Z
          if Trim(eFolder.Text) = '' then
            raise Exception.Create('Укажите папку для архивирования');

          ArchiveName := IncludeTrailingPathDelimiter(eFolder.Text) + 'archive_' + FormatDateTime('yyyymmdd_hhnnss', now) + '.zip';

          mResults.Lines.Add('=== Начало архивирования ===');
          mResults.Lines.Add('Папка: ' + eFolder.Text);
          mResults.Lines.Add('Архив: ' + ArchiveName);
          // mResults.Lines.Add('----------------------------');

          ArchTask := TTask.Create(
            procedure
            var
              Res: Boolean;
              FolderPath, ArchivePath: PChar;
              FTerminateEvent: TEvent;
            begin
              FTerminateEvent := TEvent.Create(nil, True, False, 'FTerminateEvent');
              // FTerminateEvent.WaitFor(100);

              TThread.Synchronize(TThread.Current,
                procedure
                begin
                  StatusTask(TaskNum, System.Threading.TTaskStatus.Running);
                end);
              try

                // функцию из DLL
                ArchiveFunc := GetProcAddress(FZipDLL, PChar(cdsTasksTask.AsString) (* 'ArchiveFolder' *) );
                StopArchiving := GetProcAddress(FZipDLL, 'StopArchiving');

                if not Assigned(ArchiveFunc) then
                  raise Exception.Create('Функция ' + cdsTasksTask.AsString + ' не найдена в DLL');
                // параметры
                FolderPath := StrAlloc(Length(eFolder.Text) + 1);
                ArchivePath := StrAlloc(Length(ArchiveName) + 1);
                try
                  StrPCopy(FolderPath, eFolder.Text);
                  StrPCopy(ArchivePath, ArchiveName);
                  // Вызов функцию архивации с callback'ом
                  Res := ArchiveFunc(FolderPath, ArchivePath, @ArchiveLogCallback);
                  if Res then
                  begin
                    if TThread.CheckTerminated then
                    begin
                      TThread.Synchronize(TThread.Current,
                        procedure
                        begin
                          StatusTask(TaskNum, System.Threading.TTaskStatus.Canceled);
                        end);
                    end
                    else
                    begin
                      TThread.Synchronize(nil,
                        procedure
                        begin
                          StatusTask(TaskNum, System.Threading.TTaskStatus.Completed);
                        end);
                    end
                  end
                  else
                  begin
                    TThread.Synchronize(nil,
                      procedure
                      begin
                        StatusTask(TaskNum, System.Threading.TTaskStatus.Exception);
                      end);
                  end;
                finally
                  StrDispose(FolderPath);
                  StrDispose(ArchivePath);
                end;
              except
                on E: Exception do
                begin
                  TThread.Synchronize(nil,
                    procedure
                    begin
                      StringReceived('Ошибка: ' + E.Message);
                    end);
                end;
              end;
            end);
          ArchTask.Start;
        end;
    else
      ShowMessage(Format('Отсутствует обработка функции: "%s"', [cdsTasksTask.AsString]));
    end;
    cdsTasks.Post;
  end
  else
    ShowMessage(Format('Код задачи "%s" не соотвествует функции в DLL.', [cdsTasksTask.AsString]));
end;

procedure TfrmMain.bStopTaskClick(Sender: TObject);
begin
  case cdsTasksID.AsInteger of
    0:
      if Assigned(ThFindFiles) then
        ThFindFiles.Stop;
    1:
      if Assigned(ThSearchPattern) then
        ThSearchPattern.Stop;
    2:
      if Assigned(ArchTask) then
        if ArchTask.Status = TTaskStatus.Running then
        begin
          StopArchiving;
          ArchTask.Cancel;
        end;
  end;
end;

procedure TfrmMain.btnViewResultsClick(Sender: TObject);
begin
  mResults.Clear;
end;

procedure TfrmMain.cbMatchesKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['1' .. '9', #8]) then
    Key := #0;
end;

procedure TfrmMain.cdsTasksCalcFields(DataSet: TDataSet);
begin
  // (Created, WaitingToRun, Running, Completed, WaitingForChildren, Canceled, Exception);
  if cdsTasks.Active then
    case cdsTasksStatus.AsInteger of
      0, 1, 4:
        begin
          cdsTasksSStatus.Value := 'Ожидание';
        end;
      2:
        begin
          cdsTasksSStatus.Value := 'Выполняется';
          if cdsTasksTimeStart.AsFloat < 1 then
            cdsTasksTimeStart.Value := now();
        end;
      3:
        begin
          cdsTasksSStatus.Value := 'Завершено';
          if cdsTasksTimeEnd.AsFloat < 1 then
            cdsTasksTimeEnd.Value := now();
        end;
      5:
        begin
          cdsTasksSStatus.Value := 'Отменено';
        end;
      6:
        begin
          cdsTasksSStatus.Value := 'Ошибка';
        end;
    else
      cdsTasksSStatus.Value := '???';
    end
end;

procedure TfrmMain.LoadSevenZipDLL;
begin
  FZipDLL := SafeLoadLibrary('Arch7zip.dll');
  if FZipDLL = 0 then
    ShowMessage('Не удалось загрузить Arch7zip.dll');
  // raise Exception.Create('Не удалось загрузить Arch7zip.dll');
end;

procedure TfrmMain.lvTasksDblClick(Sender: TObject);
begin
  bStartTaskClick(Sender);
end;

procedure TfrmMain.UnloadSevenZipDLL;
begin
  if FZipDLL <> 0 then
  begin
    FreeLibrary(FZipDLL);
    FZipDLL := 0;
  end;
end;

procedure TfrmMain.StringReceived(const S: string);
begin
  mResults.Lines.Add(S);
end;

end.
