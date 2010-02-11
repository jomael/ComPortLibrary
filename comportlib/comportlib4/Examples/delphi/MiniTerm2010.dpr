program MiniTerm2010;

uses
  Forms,
  MTMainForm in 'MTMainForm.pas' {MainForm},
  CPort in '..\..\source\CPort.pas',
  CPortCtl in '..\..\source\CPortCtl.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Mini Terminal';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
