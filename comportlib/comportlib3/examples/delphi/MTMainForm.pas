unit MTMainForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  CPort, StdCtrls, CPortCtl, ExtCtrls;

type
  TMainForm = class(TForm)
    Panel: TPanel;
    ComTerminal: TComTerminal;
    ConnButton: TButton;
    ComPort: TComPort;
    PortButton: TButton;
    TermButton: TButton;
    FontButton: TButton;
    TerminalReady: TComLed;
    Label1: TLabel;
    Label2: TLabel;
    ComLed1: TComLed;
    procedure ConnButtonClick(Sender: TObject);
    procedure ComPortAfterOpen(Sender: TObject);
    procedure ComPortAfterClose(Sender: TObject);
    procedure PortButtonClick(Sender: TObject);
    procedure TermButtonClick(Sender: TObject);
    procedure FontButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

procedure TMainForm.ConnButtonClick(Sender: TObject);
begin
  ComTerminal.Connected := not ComTerminal.Connected;
end;

procedure TMainForm.ComPortAfterOpen(Sender: TObject);
begin
  ConnButton.Caption := 'Disconnect';
end;

procedure TMainForm.ComPortAfterClose(Sender: TObject);
begin
  ConnButton.Caption := 'Connect';
end;

procedure TMainForm.PortButtonClick(Sender: TObject);
begin
  ComPort.ShowSetupDialog;
end;

procedure TMainForm.TermButtonClick(Sender: TObject);
begin
  ComTerminal.ShowSetupDialog;
end;

procedure TMainForm.FontButtonClick(Sender: TObject);
begin
  ComTerminal.SelectFont;
end;

end.
