unit TasksFunc;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  System.StrUtils,
  System.Threading,
  System.Math,
  Winapi.Windows,
  Winapi.Messages;

type
  TStringEvent = procedure(const S: string) of object;
  TStatusTask = procedure(const TaskIdx: Integer; const Status: TTaskStatus) of object;

  ///<summary>
  ///Базовый класс для вызова потоков
  ///</summary>
  TBaseThread = class(TThread)
  private
    FTerminateEvent: TEvent;
    FNameFunc: string;
    FAddMess: string;

    FAddrFunc: Pointer;
  protected
    procedure TerminatedSet; override;
    //procedure AddResult();

  public
    OnStringReceived: TStringEvent;
    OnStatusTask: TStatusTask;

    TaskID: Integer; //индекс задачи в FTasks

    constructor Create(ACreateSuspended: Boolean);
    destructor Destroy; override;
    procedure LoadFunc(hDll: THandle; NameFunc: string);
    procedure Stop;
  end;

  TThFindFiles = class(TBaseThread)//поиск файлов
  protected
    procedure Execute; override;
  public
    StartFolder, Masks: String;
  end;

  TThSearchPattern = class(TBaseThread)//поиск в файле
  protected
    procedure Execute; override;
  public
    TargetFile, Patterns: String;
    Matches: Int64;
  end;

implementation

uses
  CommonMkos;

{ TBaseThread }
constructor TBaseThread.Create(ACreateSuspended: Boolean);
begin
  inherited Create(ACreateSuspended);
  FTerminateEvent := TEvent.Create(nil, True, False, '');
  FNameFunc := '';
  FAddMess := '';
  FAddrFunc := nil;
end;

destructor TBaseThread.Destroy;
begin
  FTerminateEvent.Free;
  inherited;
end;

procedure TBaseThread.LoadFunc(hDll: THandle; NameFunc: string);
begin
  //ищем функции в DLL
  if hDll = 0 then
    raise Exception.Create('Для функции "' + NameFunc + '" Dll не загружена.');
  if NameFunc.IsEmpty then
    raise Exception.Create('Имя функции не определено (пусто)');

  FAddrFunc := GetProcAddress(hDll, PChar(NameFunc));
  if Assigned(FAddrFunc) then
    FNameFunc := NameFunc
  else
    raise Exception.Create('Функция "' + NameFunc + '" не найдена в DLL');
end;

procedure TBaseThread.Stop;
begin
  if not Terminated then
  begin
    FAddMess := 'Попытка остановить задачу..';
    //if Assigned(OnStringReceived) then // лучше где-то в одном месте в базовом классе
    Synchronize(
      procedure
      begin
        OnStringReceived(FAddMess);
      end);

    Terminate;
    FTerminateEvent.SetEvent;
  end;
end;

procedure TBaseThread.TerminatedSet;
begin
  inherited;
  FTerminateEvent.SetEvent;
end;

{ TThFindFiles }
procedure TThFindFiles.Execute;
var
  SearchFunc: TSearchFilesFunc;
  FileList: WideString;
  MaskArray: TArray<string>;
  Mask: string;
  Res: Boolean;
  FileCount: Integer;
begin
  inherited;

  FileList := '';

  Synchronize(
    procedure
    begin
      OnStatusTask(TaskID, System.Threading.TTaskStatus.Running);
    end);

  SearchFunc := FAddrFunc;

  MaskArray := Masks.Split([';'], TStringSplitOptions.ExcludeEmpty);

  for Mask in MaskArray do begin //для каждой маски
    if not Terminated then
    begin
      Res := SearchFunc(PChar(Mask), PChar(StartFolder), FileCount, FileList); //ызов
      if Res then
      begin
        FAddMess := Format('Найдено %d файлов %s:%s%s%s', [FileCount, Mask, sLineBreak, FileList, sLineBreak]);
        Synchronize(
          procedure
          begin
            OnStringReceived(FAddMess);
          end);
      end;
      FTerminateEvent.WaitFor(500);
    end
    else
    begin
      FAddMess := 'Задача остановлена пользователем.';
      Synchronize(
        procedure
        begin
          OnStatusTask(TaskID, System.Threading.TTaskStatus.Canceled);
          OnStringReceived(FAddMess);
        end);
      break;
    end;
  end;

  if not Terminated then
  begin
    Synchronize(
      procedure
      begin
        OnStatusTask(TaskID, System.Threading.TTaskStatus.Completed);
      end);
    Terminate;
  end
end;

{ TThSearchPattern }
procedure TThSearchPattern.Execute;
var
  SearchPattern: TSearchPattern;
  PatternsArray: TArray<string>;
  Res: Boolean;
  Results: TSearchResults;
  TotalMatches: Int64;
  Pattern: string;
begin
  inherited;

  SetLength(Results, 0);

  Synchronize(
    procedure
    begin
      OnStatusTask(TaskID, System.Threading.TTaskStatus.Running);
    end);

  SearchPattern := FAddrFunc;
  try
    PatternsArray := Patterns.Split([';'], TStringSplitOptions.ExcludeEmpty);

    for Pattern in PatternsArray do begin
      if not Terminated then begin
        SetLength(Results, Matches + 1);
        TotalMatches := Matches;
        Res := SearchPattern(PChar(TargetFile), PChar(Pattern), Results, TotalMatches);

        if Res then begin
          SetLength(Results, IfThen(TotalMatches > Matches, Matches, TotalMatches)); //уточним
          FAddMess := Format('Найдено %s%d вхождений "%s"', [IfThen(Matches < TotalMatches, 'более ', ''), IfThen(Matches < TotalMatches, Matches,
            TotalMatches), Pattern]);
          Synchronize(
            procedure
            begin
              OnStringReceived(FAddMess);
            end);

          FAddMess := '';
          for var j := 0 to Length(Results) - 1 do
            FAddMess := FAddMess + Format('%d. %d %s', [j + 1, Results[j], sLineBreak]);
          Synchronize(
            procedure
            begin
              OnStringReceived(FAddMess);
            end);
        end;
      end
      else
      begin
        FAddMess := 'Задача остановлена пользователем.';
        Synchronize(
          procedure
          begin
            OnStringReceived(FAddMess);
            OnStatusTask(TaskID, System.Threading.TTaskStatus.Canceled);
          end);

        break;
      end;

    end;
  finally
    SetLength(Results, 0);
  end;

  if not Terminated then
  begin
    Synchronize(
      procedure
      begin
        OnStatusTask(TaskID, System.Threading.TTaskStatus.Completed);
      end);
    Terminate;
  end;
end;

end.
