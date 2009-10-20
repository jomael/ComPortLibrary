program CPortUTest_Delphi2010;

uses
  Forms,
  CPortUTestMainFm in 'CPortUTestMainFm.pas' {CPortUTestMainForm},
  CPort in '..\source\CPort.pas',
  CPortCtl in '..\source\CPortCtl.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TCPortUTestMainForm, CPortUTestMainForm);
  Application.Run;
end.
