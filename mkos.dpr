program mkos;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  CommonMkos in 'CommonMkos.pas',
  TasksFunc in 'TasksFunc.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
{$IFDEF DEBUG}
//  ReportMemoryLeaksOnShutdown := true; // отслеживание утечек памяти
{$ENDIF}
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
