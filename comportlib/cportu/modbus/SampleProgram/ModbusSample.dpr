program ModbusSample;
  { MOdbus Master sample : Requires TComPort component and TComPortModbusMaster }

uses
  Forms,
  SampleMainFm in 'SampleMainFm.pas' {SampleMainForm};
  

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Modbus Sample';
  Application.CreateForm(TSampleMainForm, SampleMainForm);
  Application.Run;
end.
