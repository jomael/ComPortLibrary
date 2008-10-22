unit SampleMainFm;

{ Modbus Sample program written by Warren Postma. 
  Demo for TComPortModbusMaster }
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, 
  ExtCtrls, 
  CPort,
  CPortCtl,
  CportModbus, 
  CportModbusPacket;


type
  TSampleMainForm = class(TForm)
    ModbusMaster1: TComPortModbusMaster;
    Label4: TLabel;
    EditPoll: TEdit;
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    Label5: TLabel;
    Edit5: TEdit;
    Button3: TButton;
    CheckBox1: TCheckBox;
    Bevel2: TBevel;
    Bevel3: TBevel;
    ComPort1: TComPort;
    Label6: TLabel;
    EditComPort: TEdit;
    EditBaudRate: TEdit;
    LabelBps: TLabel;
    EditParity: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    EditStopBits: TEdit;
    GroupBox1: TGroupBox;
    CheckBox2: TCheckBox;
    Label9: TLabel;
    EditRaw: TEdit;
    Label10: TLabel;
    Edit9: TEdit;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    EditSlave: TEdit;
    Label2: TLabel;
    EditAddr: TEdit;
    Label3: TLabel;
    EditCount: TEdit;
    Label11: TLabel;
    Bevel1: TBevel;
    LabelPoll: TLabel;
    ComLed1: TComLed;
    ComLed2: TComLed;
    Label12: TLabel;
    Label13: TLabel;
    Timer1: TTimer;
    CheckBoxDTR: TCheckBox;
    CheckBoxRTS: TCheckBox;
    ButtonTxTest: TButton;
    ButtonRxTest: TButton;
    procedure ButtonTxTestClick(Sender: TObject);
    procedure ButtonRxTestClick(Sender: TObject);
    procedure CheckBoxRTSClick(Sender: TObject);
    procedure CheckBoxDTRClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ModbusMaster1SuccessfulRead(Sender: TObject;  Packet: TModbusPacket);

    procedure ModbusMaster1PacketFailed(Sender: TObject;
      Packet: TModbusPacket);
    procedure ModbusMaster1TraceEvent(Sender: TObject;
      TraceMessage: String);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ModbusMaster1SuccessfulWrite(Sender: TObject;
      Packet: TModbusPacket);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ModbusMaster1TxEvent(Sender: TObject; Packet: TModbusPacket);
    procedure Timer1Timer(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }

    procedure BlockingReadBug;

    function GetValues( var OutValues:Array of Word;MaxSplit:Integer):Integer;

    procedure ApplyComSettings;

  public
    { Public declarations }
    procedure Log(msg:String);
  end;

var
  SampleMainForm: TSampleMainForm;

implementation

{$R *.dfm}

procedure TSampleMainForm.Log(msg:String);
begin
  Memo1.Lines.BeginUpdate;
    Memo1.Lines.Add(msg);
    if Memo1.Lines.Count>1000 then
        Memo1.Lines.Delete(0);
  Memo1.Lines.EndUpdate;
end;

{ split a string into an array of words, separated by a character }
function TSampleMainForm.GetValues( var OutValues:Array of Word;MaxSplit:Integer):Integer;
var
  t,Len,SplitCounter:Integer;
  Ch:Char;
  s:String;
  val1:Integer;
  splitChar:Char;
  inString:String;
begin
   inString:= Edit5.Text; { get values to write } 
   splitChar := ',';
   Len := Length(inString);
   for t := Low(OutValues)  to High(OutValues) do begin // clear array that is passed in!
        OutValues[t] := 0;
   end;
try
   SplitCounter := 0; // ALWAYS ASSUME THAT ZERO IS VALID IN THE OUTGOING ARRAY.
   for t := 1 to Len do begin
        Ch := inString[t];
        if (Ch = splitChar) then begin
                val1 := StrToInt(s);
                s := '';
                if (val1 <0) or (val1>65535) then
                        raise EConvertError.Create('Out of range');
                OutValues[SplitCounter] := val1;
                Inc(SplitCounter);
                if SplitCounter>MaxSplit then begin
                        result := -1; // Error!
                        exit;
                end;
        end else
              s := s + ch;
   end;
   val1 := StrToInt(s);
   if (val1 <0) or (val1>65535) then
                        raise EConvertError.Create('Out of range');
   OutValues[SplitCounter] := val1;
   Inc(SplitCounter);
   result := SplitCounter;
except
   on E:EConvertError do begin
        Application.MessageBox('Invalid data. Expect values in range 0..65535 decimal, separated by commas if there are more than one!','Error',MB_OK);
        result := 0; // no data
   end;
end;
end;


procedure TSampleMainForm.ApplyComSettings;
begin

  ComPort1.Connected := false;
  ComPort1.Port := 'COM'+EditComPort.Text;
  ComPort1.BaudRate := StrToBaudRate( EditBaudRate.Text );
  ComPort1.Parity.Bits := StrToParity( EditParity.Text );
  ComPort1.StopBits := StrToStopBits( EditStopBits.Text );

  
end;

procedure TSampleMainForm.Button1Click(Sender: TObject);
//var
// Success : Boolean;
begin
  Button1.Enabled := false;
  Button2.Enabled := true;

  ApplyComSettings;

  //ComLed1.ComPort := ComPort1;
  //ComLed2.ComPort := ComPort1;

   if not ComPort1.Connected {Open} then begin
      ComPort1.Connected := true;
   end;
   if not ModbusMaster1.Active then begin
      ModbusMaster1.Active := true;
   end;


  {  Success := } ModbusMaster1.Read
                       ( 1, {user code: Use this to identify your results when the read finishes!}

                        {NEW: The DebugId string is entirely up to you, you
                           can leave it blank ('') or pass in something that
                           makes sense in your application. it is  used in
                          trace messages, to help you diagnose problems that
                          only occur when you are doing thousands of modbus
                          reads a minute, and you want to see which
                          reads/writes fail, and give them a name instead
                          of just a user code. }
                          {DEBUGID:}'Slave'+EditSlave.text+'.Reg'+EditAddr.text,

                          { the modbus read parameters:}

                        StrToIntDef(EditSlave.text,1), { slave id }
                        StrToIntDef(EditAddr.text,40001), { address }
                        StrToIntDef(EditCount.text,10),  { count }
                        StrToIntDef(EditPoll.text,200), { polling rate }

                        {Timeouts} 3,

                        {Traceflag} False

                      );
  (* if not Success then begin
         Handle Internal failure!?
     end;
  *)



end;

procedure TSampleMainForm.ModbusMaster1SuccessfulRead(Sender: TObject;
  Packet: TModbusPacket);
var
//  t:Integer;
//  s:String;
  msg:String;
begin
   ComLed1.State := lsOff;
   ComLed2.State := lsOn;
   Timer1.Enabled := true; // turns ComLed2 back off
   ComLed1.Refresh;
   ComLed2.Refresh;

msg :=  'Read '+Packet.AllValuesStr+ '. Counter:'+IntToStr(Packet.PollingOkCount);

//Log(msg);
LabelPoll.Caption := msg;
//  s := Packet.

end;

procedure TSampleMainForm.ModbusMaster1PacketFailed(Sender: TObject;
  Packet: TModbusPacket);
begin
  ComLed1.State := lsOff;
  ComLed2.State := lsOff;  
         ComLed1.Refresh;
         ComLed2.Refresh;
  
  OutputDebugString('SampleMainForm: Failed');
  if Packet.Status = modbusTimeout then
        Log('Timeout (No Response Received).')
  else if Packet.Status = modbusException then
        Log('Exception Response Received.')
  else begin
        Log('Modbus Communications Failure.')
  end;
end;

procedure TSampleMainForm.ModbusMaster1TraceEvent(Sender: TObject;
  TraceMessage: String);
begin
  Log('Trace: '+TraceMessage );
end;

procedure TSampleMainForm.Button2Click(Sender: TObject);
begin

         Button2.Enabled := false;
         Button1.Enabled := true;
         ModbusMaster1.Active := false;

         ComLed1.ComPort := nil;
         ComLed2.ComPort := nil;
         ComLed1.State := lsOff;
         ComLed2.State := lsOff;
         ComLed1.Refresh;
         ComLed2.Refresh;

end;

procedure TSampleMainForm.Button3Click(Sender: TObject);
var
// Success     : Boolean;
 Values      : Array of Word;
 Len, Actual : Integer;
begin
   if not ComPort1.Connected then begin
      ComPort1.Connected := true;
   end;
   if not ModbusMaster1.Active then begin
      ModbusMaster1.Active := true;
   end;

   Len := StrToIntDef(EditCount.text,1);
   SetLength(Values,Len);
   Actual := GetValues(Values,Len);
   if (Actual < Len) then begin
        Len := Actual;
   end;
   
   {Success  := } ModbusMaster1.Write
                      ( 2, { User Code 2 }
                        {NEW DEBUGID:}'S'+EditSlave.text+'.Reg'+EditAddr.text,
                        StrToIntDef(EditSlave.text,1), { slave id }
                        StrToIntDef(EditAddr.text,40001), { address }
                        Len,  { number of values to be written  }
                        {timeouts}  3,
                        {traceflag}  false,
                        Values { the data to be written }
                       );

end;

procedure TSampleMainForm.ModbusMaster1SuccessfulWrite(Sender: TObject;
  Packet: TModbusPacket);
begin
  ComLed1.State := lsOff;
  ComLed2.State := lsOn;
  Timer1.Enabled := true; // turns ComLed2 back off
  ComLed1.Refresh;
  ComLed2.Refresh;

  OutputDebugString('SampleMainForm: Write Ok!');
  Log('Write Ok!');
end;

procedure TSampleMainForm.CheckBox1Click(Sender: TObject);
begin
        ModbusMaster1.EnableRXLogging :=  CheckBox1.Checked;
        ModbusMaster1.EnableTXLogging :=  CheckBox1.Checked;
end;


procedure TSampleMainForm.BlockingReadBug;
var
 t:Integer;
 Addr:Integer;
 Values:Array [0..200] of Word;
 FileChecksum:Word;
 fsize, WordCount:Integer;
 SysTime:TSystemTime;
 WriteCounter,readResult:Integer;
 SlaveId:Integer;

begin

  SlaveId:= StrToIntDef(EditSlave.Text,0);

  if not ComPort1.Connected then exit;


  if not ModbusMaster1.Active then
     ModbusMaster1.Active := true;


  if (SlaveId<1) then exit;



  ModbusMaster1.BeginBlockingCallBatch;

   //FillMemory( @(Values[0]),200,0);
   //ComPort1.Write( Values,100);

  try
   Addr := 40001 +  6144 + 4; // writing to a particular location inside my PLC.
   FileChecksum := 0;
   WriteCounter := 0;
    for t:= 1 to 3 do begin
        FillMemory( @(Values[0]),200,0);
        WordCount := 100;

        ComPort1.Write( Values,209);

        ModbusMaster1.BlockingWrite( {SlaveAddress}    SlaveId,
                                            {StartingAddress} Addr,
                                            {WriteCount}      WordCount,
                                            {Values array}    Values,
                                            {MaximumWaitMsec} 1000,
                                            {debugID}         'ProbePlc.R'+IntToStr(Addr)
                                          );
        if readResult<240 then
            break;
        Inc(Addr,WordCount);

        // Evil Timing Hacks:
        //Application.ProcessMessages;
        //Sleep(200);

    end;

   finally
       ModbusMaster1.EndBlockingCallBatch;
  end;
end;

procedure TSampleMainForm.Button4Click(Sender: TObject);
begin
  if not ComPort1.Connected then begin
    ApplyComSettings;
    ComPort1.Connected  := true;
  end;

   BlockingReadBug;
end;

(*
begin TSampleMainForm.SimpleBlockingReadSample;
var
  Values:Array[0..6] of Word;
begin


  if not ComPort1.Connected then begin
    ApplyComSettings;
    ComPort1.Connected  := true;
  end;
  if not ModbusMaster1.Active then
    ModbusMaster1.Active := true;


  if not ModbusMaster1.BlockingRead( 10, 43843, 6, Values, 1000, {debugid}'BlockRead.Reg43843') then
      Application.MessageBox('Test Failed','Block Read Fail', MB_OK or MB_ICONERROR )
  else
      Application.MessageBox('Test Ok','Blocking Read Ok',MB_OK);
end;
*)

procedure TSampleMainForm.ModbusMaster1TxEvent(Sender: TObject;
  Packet: TModbusPacket);
begin
  ComLed2.State := lsOff;
  ComLed1.State := lsOn;
  ComLed1.Refresh;
  ComLed2.Refresh;

  Timer1.Enabled := true;
  
end;

procedure TSampleMainForm.Timer1Timer(Sender: TObject);
begin
 ComLed2.State := lsOff;
 ComLed2.Refresh;
 ComLed1.State := lsOff;
 ComLed1.Refresh;

 Timer1.Enabled := false; 
end;

procedure TSampleMainForm.Button5Click(Sender: TObject);
begin
   if not ComPort1.Connected then begin
        ApplyComSettings;

       if not ComPort1.Connected then
          ComPort1.Open;
       if ModbusMaster1.Active then
          ModbusMaster1.Active := false;

       ComPort1.WriteStr('THIS IS A TEST!  THIS IS A TEST! THIS IS A TEST! THIS IS A TEST! THIS IS A TEST! THIS IS A TEST! ');

       if not ModbusMaster1.Active then
          ModbusMaster1.Active := true;
   end;

   ComPort1.WriteStr('THIS IS A TEST!  THIS IS A TEST! THIS IS A TEST! THIS IS A TEST! THIS IS A TEST! THIS IS A TEST! ');

   
end;

procedure TSampleMainForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
    ModbusMaster1.Active := false; // This is important, or you can crash the system!
end;

procedure TSampleMainForm.CheckBoxDTRClick(Sender: TObject);
begin
   ComPort1.SetDtr( CheckBoxDTR.Checked );
end;

procedure TSampleMainForm.CheckBoxRTSClick(Sender: TObject);
begin
  ComPort1.SetRTS( CheckBoxRTS.Checked );

end;

procedure TSampleMainForm.ButtonRxTestClick(Sender: TObject);
var
    aStr:String;
begin

   if not ComPort1.Connected {Open} then begin
      ApplyComSettings;
      ComPort1.Connected := true;
   end;
   ComPort1.ReadStr(aStr,80);
   Log( 'Received:'+aStr);

end;

procedure TSampleMainForm.ButtonTxTestClick(Sender: TObject);
var
 aStr:String;
begin
    if not ComPort1.Connected {Open} then begin
      ApplyComSettings;
      ComPort1.Connected := true;
   end;
   aStr := 'Testing Testing 123! ';
   ComPort1.WriteStr(aStr);
   Log( 'Sent:'+aStr);

end;

end.
