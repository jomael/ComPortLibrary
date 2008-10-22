unit MTMainForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  CPort, StdCtrls, CPortCtl, ExtCtrls, Menus,IniFiles;

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
    PopupMenu1: TPopupMenu;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    Button1: TButton;
    procedure ConnButtonClick(Sender: TObject);
    procedure ComPortAfterOpen(Sender: TObject);
    procedure ComPortAfterClose(Sender: TObject);
    procedure PortButtonClick(Sender: TObject);
    procedure TermButtonClick(Sender: TObject);
    procedure FontButtonClick(Sender: TObject);
    procedure Paste1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FInitFlag:Boolean;
    FIni:TMemIniFile;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}

uses Clipbrd;
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

procedure TMainForm.Paste1Click(Sender: TObject);
var
 clipboardStr:String;
begin
  clipboardStr := Clipboard.AsText;
//  ComTerminal.WriteStr(clipboardStr);
  ComPort.WriteStr( AnsiString(clipboardStr) );
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

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   if Assigned(FIni) then begin
     FIni.WriteString('ComPort', 'ComPort', ComPort.Port );
     FIni.WriteString('ComPort','BaudRate', BaudRateToStr( ComPort.BaudRate ) );
     FIni.WriteString('ComPort','FlowControl', FlowControlToStr(ComPort.FlowControl.FlowControl ));
     FIni.UpdateFile;
     FIni.Free;
   end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
 if not FInitFlag then begin
   FInitFlag := true;

   FIni := TMemIniFile.Create( ExtractFilePath(Application.ExeName)+'terminal.ini');
   ComPort.Port := FIni.ReadString('ComPort', 'ComPort',ComPort.Port);
   ComPort.BaudRate := StrToBaudRate( FIni.ReadString('ComPort','BaudRate', '19200'));
   ComPort.FlowControl.FlowControl := StrToFlowControl( FIni.ReadString('ComPort','FlowControl', 'Hardware'));
   ConnButtonClick(Sender);

 end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
var
  s:AnsiString;
begin
  { This test shows how to work with a TComPort without any visual controls
   attached, and without any background event thread or Win32 overlapped I/O.
   This mode might be useful for some people who want a simpler Com Port wrapper
   component that does not use asynchronous/overlapped Win32 apis.  Many things
   stop working in this approach, and it is not recommended for new or
   inexperienced users. }
   ComPort.Connected := false;
   ComTerminal.Connected := false;
   Application.ProcessMessages;
   ComPort.Overlapped := false;
   ComPort.Connected := true;
   ComPort.WriteStr('AT'+CHR(13));  {Send modem Command}
   Sleep(5);
   ComPort.ReadStr(S,80); {Get modem response.}
   if Pos('OK',s)>0 then
        Application.MessageBox( PChar('Modem is responding normally on '+ComPort.Port),
                                'Non-Overlapped Test', MB_OK)
        else
        Application.MessageBox( PChar('No modem responding on '+ComPort.Port),
                                'Non-Overlapped Test', MB_OK);

   ComPort.Connected := false;
   ComPort.Overlapped := true;


end;

end.
