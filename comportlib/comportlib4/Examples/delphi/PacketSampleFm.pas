unit PacketSampleFm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdThreadComponent, StdCtrls, Spin, CPort;

type
  TForm7 = class(TForm)
    ComPort1: TComPort;
    ComDataPacket1: TComDataPacket;
    Button1: TButton;
    Label1: TLabel;
    showResp: TEdit;
    Label2: TLabel;
    SpinEdit1: TSpinEdit;
    editSend: TEdit;
    CheckBox1: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure ComDataPacket1Packet(Sender: TObject; const Str: string);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form7: TForm7;

implementation

{$R *.dfm}

procedure TForm7.Button1Click(Sender: TObject);
Var
 s:AnsiString;
begin
 s := AnsiString(editSend.Text);
 if CheckBox1.Checked then
    s := s + AnsiChar(13);


 ComDataPacket1.StopString := AnsiChar(SpinEdit1.Value);

ComPort1.Connected := true;
ComPort1.WriteStr(S);




end;

procedure TForm7.ComDataPacket1Packet(Sender: TObject; const Str: string);
begin
 showResp.Text := Trim(Str);
end;

end.
