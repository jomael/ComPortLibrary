unit CportModbusPacket;
{$R-}
{$Q-}
(*  Modbus Packet Type and Defines used by TModbusMaster component
    Written by Warren Postma. (C) 2003 Tekran Inc.
    wp@tekran.com
 *)


interface

uses
  SysUtils, Windows, Classes, CportModbusUtils;

const
constModbusDebugIdLength=32; // new! Packet debug id is up to 32 characters of text!

constIncomingBlockSize = 4096;
constManualPacket = 0; // Not a modbus command.
constReadCoilStatus = 1;
constReadInputStatus = 2;
constReadHoldingRegisters = 3;
constReadInputRegisters = 4;
constForceSingleCoil = 5;
constPresetSingleRegister = 6;
constReadExceptionStatus = 7;
constFetchCommEventCounter = $0B; // 11
constFetchCommEventLog = $0C; // 12
constForceMultipleCoils = $0F; // 15
constPresetMultipleRegisters = $10; // 16
constReportSlaveID = $11; // 17
constResetCommLink = $13; // 19
constMaskWrite4xRegister = $16;  //  22
constReadFIFOQueue = $18;   // 24
constSpecialFunction = $7E;
constSubFunctionReadRegisters = $23; // sub function $7E.
constSubFunctionReadCoils = $27; // sub function $7E.
constMaxModbusPacketLength = 255;
constPacketSentinel = $FAEF7D1;

type
  TModbusResult = ( modbusNoResultYet, // A Null Result. Means nothing.
                    modbusGood,
                    modbusPending, // Has been sent, no error yet.
                    modbusFailed, // general error, no specific error found.
                    modbusBusy,
//                    modbusQueueFull,
                    modbusTimeout,
                    modbusNotActive,
                    modbusBadParameters,
                    modbusBadReplyPacket, // Checksum or other invalidly formed packet.
                    modbusException );


  TModbusPacket = class;
                      
  // Used by ModbusPacket, as well as TModbusMaster!
  TModbusSuccessNotification = procedure (Sender : TObject; Packet : TModbusPacket) of object;

  // A "packet" is represented by a TPacket.
  TModbusPacket = class
     protected
       FSentinel1:DWORD; //== constPacketSentinel = $FAEF7D1;
       FDebugId  : Array[0..constModbusDebugIdLength] of Char; // a debugging helper.

       FUserCode : Word;


       FWriteFlag:Boolean; // If true, this is a write command, if false, it's a read command.
       FTraceFlag:Boolean;
       FHighPriority:Boolean; // High priority packet flag can only be set on one-time reads or writes.
       FCustomFlag:Boolean;
       FOffline:Boolean; // If offline, then this unit is faulted.
       FActive : Boolean; // if not active, then the Execute method won't send it right now.
       FPacketID : DWORD;
       FSendData : Array[0..constMaxModbusPacketLength+1] of Char;
       FSendLength : Cardinal;      // This is the length of the SendData packet
       FResponseData : Array[0.. constMaxModbusPacketLength+1] of Char;      // ResponsePointer holds the data that was received as a reply.
       FResponseLength : Cardinal;     // ResponseLength tells how many bytes were received as a reply.
       FMaxTimeouts:Integer; // Maximum timeouts for this packet, before abandoning it or placing it temporarily offline, as the case may be.
       FDebugFlag:Boolean; // Are we debugging a problem with this packet? Enables extra debugging features.

       // Modbus packet read parameters:
       FSlaveAddress : Byte;
       FFunctionCode : Byte;
       FStartingAddress : Word; { the original Modbus address in form 0xxxx,1xxxx,2xxxx,3xxxx,4xxxx, etc }
       FReadLength : Word; { number of elements to read. Minimum 1!}

       // Blocking handle is 0 if blocking is not being used and a semaphore handle if blocking is used.
       FBlockingHandle : THandle;
       // Retry count indicates how many times this packet was retried.  Only useful after this packet goes in
       // the response list.
       FRetryCount : Word; // This retry counter applies only to retries on invalid responses.
       FRetryErrors : Word; // Cumulative number of retries on this packet. Helpful for Statistical analysis of reliability of link. 
       
       // CRCErrrors tracks the number of CRC errors this packet encountered.
       FCRCErrors : Word;
       // Timeout errors indicates the number of timeout errors this packet got trying to get a reply.
       FTimeout :     DWORD; // Milliseconds until packet response timeout. {default to ModbusMasterThread.FPacketTimeoutMS}
       FTimeoutsSinceLastValidPacket:Word; // Timeout counter that resets to zero on every valid packet. This is used to know whether a device is currently OFFLINE.
       FRetriesExhaustedErrors: Word;  // Cumulative number of times all retries were exhausted for this packet.
       FExceptionCode : Integer; // Holds last exception code received.
       FExceptionCount : Integer; // Holds number of exceptions received.
       // NEW POLLING FEATURE
       FPollingOkLast:DWORD; // When was last Okay read of this?
       FPollingInterval:DWORD; // 00=no polling (one shot) (configuration value, not actual value)

       FPollingIntervalActual:DWORD; // Actual polling interval (calculated at runtime)
       FPollingNextTime:DWORD; // Millisecond value for next time we poll (added to current system's timer tick value)
       FPollingOkCount:DWORD; // statistical stuff only.
       FSchedulerCount:DWORD; // Used for fairly scheduling the packet.
       FNoiseBytesCounter:DWORD; // statistical importance only
//       FFailNotifyFlag:Boolean; // Has FAILURE event notification happened?
       FBitFlag : Boolean; // True if results are in bit format.
                           // Otherwise values are
       // Results
       FIsReadResponse:Boolean; // Last response was a read response!
       FValues: Array of Word; // All results are here
       FStatus : TModbusResult; // if Ok then Status=modbusGood else, error message.
       FNotificationPending :Boolean; // Currently this packet is busy in main thread (notification callback)

       // New: Packet-specific event callbacks:
       FOnSuccessfulRead    : TModbusSuccessNotification;
       FOnSuccessfulWrite   : TModbusSuccessNotification;

       FSentinel2:DWORD; //== constPacketSentinel = $FAEF7D1;
       
         {internal methods}
     protected
       function GetValue(index:Integer):Word;
       procedure SetValue(index:Integer;newValue:Word);
       function GetValueAsStr(index:Integer):String;
       function GetSendData:PChar;
       procedure SetPollingRate(aPollingRate:DWORD);
       procedure SetReadLength(aReadLength:Word);
       procedure SetActive(newActive:Boolean);

       procedure  SetDebugId(debugId:String); // New: Give the packet a name, this really helps with troubleshooting.
       function   GetDebugId:String;

     public


      function Interpret : Boolean; // interpret anything

       { specific read interpreters }
      procedure InterpretCoils;
      procedure InterpretRegisters;
      { write interpreters }
      procedure InterpretPresetSingleRegister;
      procedure InterpretPresetMultipleRegisters;
      procedure InterpretForceSingleCoil;
      procedure InterpretForceMultipleCoils;


      //procedure InterpretSlaveInformation;
      //procedure InterpretCommEventInformation;
      //procedure InterpretCommLogInformation;
      //procedure InterpretFIFOQueue;
      //procedure InterpretReadMultipleRegisters;
      //procedure InterpretReadMultipleCoils;

      function AllValuesStr:String; { get everything as one string, good for debugging }

      function GetUserCode:Word;
      procedure SetUserCode(code:Word);

      procedure _SetHighPriority(flag:Boolean); // TO BE CALLED ONLY BY ModbusThread.ModifyPacket!

     public
       constructor Create;  
       destructor  Destroy; override;

{$ifdef MODBUS_DEBUG}procedure DebugPacketOk; {$endif}

       //  destructor Destroy; virtual;

       procedure SetSendData(sendData:Pchar; sendLength:Integer; appendCrc:Boolean);


       // new: return amount of time overdue (0..n) or -1 if not ready yet.
       function PollingCheck(tickCount:DWORD):Integer;
       // NEW: Formerly PollingTimeUpdate happened INSIDE PollingCheck:
       procedure PollingTimeUpdate;



       function CheckMaxTimeouts:Boolean;


       // packet state handlers for various driver
       // states, which
       // updates internal values, as per various events
       // that have occurred.
       procedure OnNoiseBytes(count:Integer);
       procedure OnTimeout;
       procedure OnRetry;
       function  OnException(exceptionMsg:PChar;exceptionLength:Integer):Boolean;

       procedure OnReadyToSend;
       procedure OnReceivedOk;
       procedure OnResponseData( Data:Pchar; DataLength:Integer);






       // properties
       property UserCode : Word read GetUserCode write SetUserCode;
       property Active : Boolean read FActive write SetActive;
       property Offline:Boolean read FOffline write FOffline;
       property WriteFlag:Boolean read FWriteFlag write FWriteFlag;
       property HighPriority:Boolean read FHighPriority;
       property CustomFlag:Boolean read FCustomFlag write FCustomFlag; // NEW NOV 2003. Custom command sequence.

       property Status : TModbusResult read FStatus write FStatus;

       //property PacketID : DWORD read FPacketId write FPacketId;

       property SendData : PChar read GetSendData;
       property SendLength : Cardinal read FSendLength write FSendLength;
       //property ResponseData : String
       //property ResponseLength : Cardinal;
       // Modbus Read Request parameters:
       property SlaveAddress : Byte read FSlaveAddress write FSlaveAddress;
       property FunctionCode : Byte read FFunctionCode write FFunctionCode;
       property StartingAddress : Word read FStartingAddress  write FStartingAddress;
       property ReadLength : Word  read FReadLength write SetReadLength;
       property RetryCount : Word read FRetryCount;
       property RetryErrors : Word read FRetryErrors; // cumulative retry errors.

       property CRCErrors : Word read FCRCErrors;
       property Timeout :     DWORD read FTimeout write FTimeout; // Milliseconds until packet response timeout. {default to ModbusMasterThread.FPacketTimeoutMS}

       // Cumulative number of times we gave up after N retries, without
       // success. This is a very serious thing  and shouldn't happen on
       // a well behaved system.  Individual retries are a normal part of modbus
       // communications, but after 2 or 3 attempts the probability of
       // inability to communicate should be nearly zero, unless the
       // device or communications cables, or the host system (your PC) has
       // some serious fault. How serious this is in your case, depends on
       // your particular application.    
       property RetriesExhaustedErrors: Word read FRetriesExhaustedErrors;



       property TimeoutsSinceLastValidPacket : Word read FTimeoutsSinceLastValidPacket write FTimeoutsSinceLastValidPacket;
       property ExceptionCode : Integer read FExceptionCode;
       property ExceptionCount : Integer read FExceptionCount write FExceptionCount;
       // NEW POLLING FEATURE
       property PollingInterval:DWORD read FPollingInterval write SetPollingRate; // desired polling interval
       property PollingIntervalActual:DWORD read FPollingIntervalActual; // actual observed polling interval
       property PollingNextTime:DWORD read FPollingNextTime write FPollingNextTime; // Millisecond value for next time we poll (added to current system's timer tick value)


       property PollingOkCount:DWORD read FPollingOkCount;
       property PollingOkLast:DWORD read FPollingOkLast write FPollingOkLast;
       property NoiseBytesCounter:DWORD read FNoiseBytesCounter;
       // blocking
       property BlockingHandle : THandle read FBlockingHandle write FBlockingHandle;
       // event flag
       property NotificationPending :Boolean read FNotificationPending write FNotificationPending; // Currently this packet is busy in main thread (notification callback)

       // Scheduler Properties
       property SchedulerCount:DWORD read FSchedulerCount write FSchedulerCount; // Used for fairly scheduling the packet.


       // Runtime properties: Data values:

       property Values[index:Integer]:Word read GetValue write SetValue;
       property ValuesAsStr[index:Integer]:String read GetValueAsStr;
        // This is how we know if a packet was a read or a write packet:
       property IsReadResponse:Boolean read FIsReadResponse;// Last Response Type (true = Read Response, false = Write Response)
       property TraceFlag:Boolean read FTraceFlag write FTraceFlag; // Allow us to debug communications on just the packets we WANT to see.
       property MaxTimeouts:Integer read FMaxTimeouts write FMaxTimeouts; // Maximum timeouts for this packet, before abandoning it or placing it temporarily offline, as the case may be.
       property DebugFlag:Boolean read FDebugFlag write FDebugFlag; // Are we debugging a problem with this packet? Enables extra debugging features.

       property DebugId:String read GetDebugId write SetDebugId;
       
       // New: Packet-specific event callbacks:
       property OnSuccessfulRead    : TModbusSuccessNotification read FOnSuccessfulRead   write FOnSuccessfulRead ;
       property OnSuccessfulWrite   : TModbusSuccessNotification read FOnSuccessfulWrite  write FOnSuccessfulWrite;



  end;


var
  ModbusPacketDestroyCounter,
  ModbusPacketAllocCounter,
  ModbusPacketActiveCounter:Integer;
  ModbusLastBadPacket:TModbusPacket;

implementation

uses CportTimerUtils; {timer function: TimerHasReachedSetpoint}

procedure TModbusPacket._SetHighPriority(flag:Boolean); // TO BE CALLED ONLY BY ModbusThread.ModifyPacket!
begin
  FHighPriority := flag;
end;

//-----------------------------------------------
// Corrupt Packet Debug Code:
//
// Every packet has a marker (FSentinel1/FSentinel2)
// to help detect memory corruption, and the
// sentinels are destroyed in the destructor,
// so use of a freed packet instance, or other
// similar errors, including memory overwrites
// of the beginning or end of the packet object
// could be detected earlier rather than later.
//
// While it is safe to leave this on, if no memory
// corruption is suspected, it is better to turn
// this off in release versions of your code. If
// you ever suspect corruption, turn it back on
// to find out.  Because the component operates
// between background and foreground threads,
// it is particularly tricky to test and
// debug this component, so this is just a helper
// to make it a little easier.
//-----------------------------------------------
{$ifdef MODBUS_DEBUG}
procedure TModbusPacket.DebugPacketOk;
begin
  if not Assigned(Self) then begin
     raise Exception.Create('Nil Packet');
  end;

  if    (FSentinel1 <> constPacketSentinel)
     or (FSentinel2  <> constPacketSentinel)
     or (FSlaveAddress=0) or (FSlaveAddress>250)
     or (FRetryCount > 200)
     or (FMaxTimeouts > 200)
    then begin
    ModbusLastBadPacket := Self;
    raise Exception.Create('TModbusPacket.DebugPacketOk: detected invalid packet.');
   end;
end;
{$endif}

function TModbusPacket.GetUserCode:Word;
begin
  //{$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  result := FUserCode;

end;
procedure TModbusPacket.SetUserCode(code:Word);
begin
  //{$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  FUserCode := code;

end;

{ Stores the data into the packet, and sets the CRC,
  sendLength is the modbus length BEFORE the checksum!  }
procedure TModbusPacket.SetSendData(sendData:Pchar; sendLength:Integer; appendCrc:Boolean);
var
  CalculatedCRC : Word;
  x:Integer;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  Assert(Assigned(SendData));
  Assert(SendLength>0);
  Assert(SendLength<255);

   for x := 0 to sendLength-1 do begin
         FSendData[x] := Char( sendData[x] );
   end;

   if appendCrc then begin        // Append CRC
       FSendLength := sendLength+2;
       CalculatedCRC := CalculateRTUCRC( sendData, sendLength);
       x := sendLength;
       FSendData[x] := Char(CalculatedCRC shr 8);
       Inc(x);
       FSendData[x] := Char(CalculatedCRC and 255);
   end else begin
       FSendLength := sendLength;
   end;
end;


constructor TModbusPacket.Create;
begin
 FSentinel1 :=  constPacketSentinel; // $FAEF7D1;
 FSentinel2 :=  constPacketSentinel; // $FAEF7D1;
 FPollingOkLast := GetTickCount;
 Inc(ModbusPacketAllocCounter);
 Inc(ModbusPacketActiveCounter);
 FDebugId[0] := Chr(0);
end;


destructor TModbusPacket.Destroy;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
 FSentinel1 :=  $7F7F7F7F; // Deleted packet
 FSentinel2 :=  $7F7F7F7F; // Deleted packet


 if FBlockingHandle<>THandle(nil) then
    CloseHandle(FBlockingHandle);

 if (FNoiseBytesCounter > 0) then
{$ifdef DEBUGINFO_ON}
    OutputDebugString('ModbusPacket.pas: FNoiseBytesCounter > 0');
{$endif}



   FStartingAddress := $FFFF; // Invalid Address Flag
   FSlaveAddress := $FF;
   FSendData[0] := Chr($FF);
   FBlockingHandle := INVALID_HANDLE_VALUE;
   Inc(ModbusPacketDestroyCounter);
   Dec(ModbusPacketActiveCounter);
end;

function TModbusPacket.GetSendData:PChar;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}

  result := @FSendData[0];
end;


procedure TModbusPacket.OnNoiseBytes(count:Integer);
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}

  if count>0 then begin
    Inc(FNoiseBytesCounter,count);
    //Inc(FTimeoutErrors);
  end;
  
end;

// This means data is coming in, and it's good:
procedure TModbusPacket.OnResponseData( Data:Pchar; DataLength:Integer);
var
  x:Integer;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  if (DataLength > constMaxModbusPacketLength) then begin
      // Ignore Floods, count as noise!
      OnNoiseBytes(DataLength);
      exit;
  end;

  if DataLength<0 then begin
          FResponseData[0] := Chr(0);
          FResponseLength := 0;
          FStatus := modbusFailed; // general catch-all error indication.
  end else begin
     try
      for x := 0 to DataLength-1  do begin { don't copy the CRC in }
          FResponseData[x] := Data[x];
      end;
     except
        on E:ERangeError do begin
            OutputDebugString('ModbusPacket.pas: Range error in OnResponseData');
        end;
     end;
      FStatus := modbusGood; // No error yet, in progress.
      FResponseLength := DataLength;
  end;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;


procedure TModbusPacket.OnRetry;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}

{$ifdef DEBUGINFO_ON}
  if (FRetryCount=0) then
   OutputDebugString(PChar('TModbusPacket: '+DebugId+' FIRST OnRetry'));
{$endif}

   Inc(FRetryCount);
   // NEW: Count retries in our statistics: (Aug 2004)
   Inc(FRetryErrors);
end;

function TModbusPacket.OnException(exceptionMsg:PChar;exceptionLength:Integer):Boolean;
var
    b:Byte;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   result := false;
   if exceptionLength = 4 then begin
       b := CalculateASCIILRC(exceptionMsg,4);
       result := (Ord(b) = Ord(exceptionMsg[4]) ); // last byte equals good lrc?
   end else if exceptionLength = 5 then // weird PLC exception format, not LRC?
        result := true;

     if (result) then begin
         FExceptionCode := Ord(exceptionMsg[2]);
         Inc(FExceptionCount);
         FStatus := modbusException;
         { slow down polling to 2 seconds if we get an exception. XXX Make this variable! }
         if (FPollingInterval>0) and (FPollingInterval<2000) then
                FPollingNextTime := GetTickCount + 2000; // Don't retry until 2 seconds later
     end;
end;

procedure TModbusPacket.OnReadyToSend;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
        FRetryCount := 0;
        FStatus := modbusPending;
end;

procedure TModbusPacket.OnReceivedOk;
var
 tick:DWORD;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
        Inc(FPollingOkCount);
        tick := GetTickCount;
        FPollingIntervalActual := TimerElapsed(FPollingOkLast,tick);
        FPollingOkLast := tick;
        FTimeoutsSinceLastValidPacket := 0;
        FStatus := modbusGood;
end;

procedure TModbusPacket.OnTimeout;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   FStatus := modbusTimeout;
   //Inc(FTimeoutErrors);
   Inc(FRetriesExhaustedErrors);

   Inc(FTimeoutsSinceLastValidPacket);
   // slow down polling after timeouts:

   (* This sort of cleverness always comes back to bite me in the buttocks.
      I'm leaving it here as an example of what-not-to-do when debugging
      modbus communications problems.  A better description of the code
      below might be "when things are bad, introduce more variables into
      the equation, that just might mess everything up even worse than
      before.".

     if (FPollingOkCount>0) or (FRetriesExhaustedErrors>3) then begin
     { Once we've read from something more than once, we don't need to retry so fast }
       if (FPollingInterval>0) and (FPollingInterval<2000) then
          FPollingNextTime := GetTickCount + 2000; // Don't retry until 2 seconds later
   end else begin
      { If we've never read from it, it's important to get an initial value, so we retry
        a few times, after timeouts. }
     FPollingNextTime := GetTickCount + 1000; // Don't retry until 2 seconds later
   end;
   
   *)
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;

function TModbusPacket.GetValue(index:Integer):Word;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  if (index<0) or (index>FReadLength-1) then
        raise ERangeError.Create('TModbusPacket.GetValue - index out of range');
  result := FValues[index];
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;

procedure TModbusPacket.SetValue(index:Integer;newValue:Word);
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  if (index<0) or (index>FReadLength-1) then
        raise ERangeError.Create('TModbusPacket.SetValue - index out of range');
  try
   FValues[index] := newValue;
  except
     on E:Exception do begin
     {$ifdef DEBUGINFO_ON}
       OutputDebugString(PChar('ModbusPacket.pas:TModbusPacket.SetValue exception '+E.Message));
     {$endif}
     end;
  end;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;

function TModbusPacket.GetValueAsStr(index:Integer):String;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  if (index<0) or (index>FReadLength-1) then
        raise ERangeError.Create('TModbusPacket.GetValueAsStr - index out of range');

  result := IntToStr( FValues[index] );
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;

{ get everything as one string, good for debugging }
function TModbusPacket.AllValuesStr:String;
var
  index:Integer;
  s:String;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  for index := 0 to FReadLength-1 do begin
     if (index = 0) then
        s := IntToStr(FValues[index])
     else
        s := s + ', '+IntToStr(FValues[index]);
  end;
  result := s;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;


{ InterpretCoils: Decode bit by bit and store into Results }
procedure TModbusPacket.InterpretCoils;
var
  MaximumBytes : Word;
   ByteOffset : Word;
   CurrentBit : Byte;
   CurrentCoil : Word;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   if ((Byte(FResponseData[1]) = (FunctionCode or $80))) then begin
      //   DecodeException(Byte(FResponseData[2]));
      FStatus :=modbusException;
      exit;
   end;
{   if (FResponseData = Nil) then begin
      FStatus := modbusFailed;
      exit;
   end;}

   FIsReadResponse:= true; // Last response was a read response!

   MaximumBytes := Byte(FResponseData[2]);
   CurrentCoil := FStartingAddress;
   CurrentBit := 0;
   FStatus := modbusGood;
   ByteOffset := 0;
   while (CurrentCoil < (FReadLength+FStartingAddress)) do begin
      if (Word(ByteOffset + 3)> FResponseLength) then begin
         FStatus := modbusBadReplyPacket;
         break; // too big.
      end;
      Values[CurrentCoil-FStartingAddress]:= ((Byte(FResponseData[ByteOffset+3]) shr CurrentBit) and 1);
      Inc(CurrentCoil);
      Inc(CurrentBit);
      if (CurrentBit = 8) then begin
         CurrentBit := 0;
         Inc(ByteOffset);
      end;
      if (ByteOffset > FResponseLength) or (ByteOffset>MaximumBytes) then begin
         FStatus := modbusBadReplyPacket;
         break; // too many..
      end;
   end;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;

{ InterpretRegisters: Decode word by word (16 bits at a time) and store into Results }
procedure TModbusPacket.InterpretRegisters;
var
   ByteOffset : Word;
   CurrentRegister : Word;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   if ((Byte(FResponseData[1]) = (FunctionCode or $80))) then begin
      FStatus := modbusException;//DecodeException(Byte(FResponseData[2]));
      exit;
   end;
   {if (FResponseData = Nil) then begin
      FStatus := modbusFailed;
      exit;
   end;}

    FIsReadResponse:= true; // Last response was a read response!

   CurrentRegister := FStartingAddress;
   ByteOffset := 3;
   FStatus := modbusGood;
   while (CurrentRegister < (FReadLength + FStartingAddress)) do begin
      if (ByteOffset >= FResponseLength) then begin {was >= }
         FStatus := modbusBadReplyPacket;
{$ifdef DEBUGINFO_ON}
         OutputDebugString('ModbusPacket.pas: MODBUS REPLY TOO SHORT');
{$endif}
         break;
      end;
      Values[CurrentRegister-FStartingAddress] := ((Word(FResponseData[ByteOffset]) shl 8) or Byte(FResponseData[ByteOffset+1]));
      Inc(CurrentRegister);
      ByteOffset := ByteOffset + 2;
   end;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;

{
function TModbusPacket.InterpretSlaveInformation(PacketID, UserCode : Word;FunctionCode : Byte;FResponseData : PChar;FResponseLength : Word;var SlaveInformation : TSlaveInformation) : TModbusResult;
var
   FCount : Word;
   ByteOffset : Word;
begin
   if ((Byte(FResponseData[1]) = (FunctionCode or $80))) then begin
      Result:=ModbusException;//DecodeException(Byte(FResponseData[2]));
      exit;
   end;
   if (FResponseData = Nil) then begin
      FStatus := modbusFailed;
      exit;
   end;
   SlaveInformation.PacketID := PacketID;
   SlaveInformation.UserCode := UserCode;
   SlaveInformation.SlaveAddress := Byte(FResponseData[0]);
   SlaveInformation.SlaveID := Byte(FResponseData[3]);
   //SetLength(SlaveInformation.AdditionalData,Byte(FResponseData[2])-2);
   ByteOffset := 5;
   FStatus := modbusGood;
   for FCount := 0 to (Byte(FResponseData[2])-2) do begin
      SlaveInformation.AdditionalData[FCount]:=Byte(FResponseData[ByteOffset]);
      Inc(ByteOffset);
      if (ByteOffset >= FResponseLength) then begin
         break;
         FStatus := modbusBadReplyPacket;
      end;
   end;
end;  }

{
function TModbusPacket.InterpretCommEventInformation(PacketID, UserCode : Word;FunctionCode : Byte;FResponseData : PChar;FResponseLength : Word;var CommEventInformation : TCommEventInformation) : TModbusResult;
begin
   if ((Byte(FResponseData[1]) = (FunctionCode or $80))) then begin
      Result:=ModbusException;//DecodeException(Byte(FResponseData[2]));
      exit;
   end;
   if (FResponseData = Nil) then begin
      FStatus := modbusFailed;
      exit;
   end;
   CommEventInformation.PacketID := PacketID;
   CommEventInformation.UserCode := UserCode;
   CommEventInformation.SlaveAddress := Byte(FResponseData[0]);
   if (FResponseLength >= 6) then begin
      if (Byte(FResponseData[2])=$FF) then begin
         CommEventInformation.Status := TRUE;
      end else begin
         CommEventInformation.Status := FALSE;
      end;
      CommEventInformation.EventCount := (Word(FResponseData[4]) shl 8) or (Word(FResponseData[5]));
      FStatus := modbusGood;
   end else begin
      FStatus := modbusBadReplyPacket;
   end;
 end;
}

{
function TModbusPacket.InterpretCommLogInformation(PacketID, UserCode : Word;FunctionCode : Byte;FResponseData : PChar;Blocksize : Word;var CommEventLogInformation : TCommEventLogInformation) : TModbusResult;
var
   FByteCount : Byte;
   FCount : Integer;
begin
   if ((Byte(FResponseData[1]) = (FunctionCode or $80))) then begin
      Result:=modbusException;//DecodeException(Byte(FResponseData[2]));
      exit;
   end;
   if (FResponseData = Nil) then begin
      FStatus := modbusFailed;
      exit;
   end;
   CommEventLogInformation.PacketID := PacketID;
   CommEventLogInformation.UserCode := UserCode;
   CommEventLogInformation.SlaveAddress := Byte(FResponseData[0]);
   if (FResponseLength >= 9) then begin
      FStatus := modbusGood;
      FByteCount := Byte(FResponseData[2]);
      if (FByteCount > (FResponseLength -3)) then begin
         FByteCount := FResponseLength - 3;
      end;
      if (Byte(FResponseData[3])=$FF) then begin
         CommEventLogInformation.Status := TRUE;
      end else begin
         CommEventLogInformation.Status := FALSE;
      end;
      CommEventLogInformation.EventCount := (Word(FResponseData[5]) shl 8) or (Word(FResponseData[6]));
      CommEventLogInformation.MessageCount := (Word(FResponseData[7]) shl 8) or (Word(FResponseData[8]));
      //SetLength(CommEventLogInformation.EventLog,FByteCount-6);
      for FCount := 0 to FByteCount-7 do begin
         CommEventLogInformation.EventLog[FCount] := Byte(FResponseData[10 + FCount]);
      end;
   end else begin
      FStatus := modbusBadReplyPacket;
   end;
end;
}

{
function TModbusPacket.InterpretFIFOQueue(PacketID, UserCode : Word;FunctionCode : Byte;FResponseData : PChar;FResponseLength : Word;var FIFOQueueResults : TFIFOQueueResults) : TModbusResult;
var
   Counter : Integer;
   FFIFOQueueCount : Word;
   FByteCount : Word;
   ByteOffset : Word;
begin
   if ((Byte(FResponseData[1]) = (FunctionCode or $80))) then begin
      Result:=ModbusException;//DecodeException(Byte(FResponseData[2]));
      exit;
   end;

   FStatus := modbusFailed;
   if (FResponseData = Nil) then begin
      exit;
   end;
   FIFOQueueResults.PacketID := PacketID;
   FIFOQueueResults.UserCode := UserCode;
   FIFOQueueResults.SlaveAddress := Byte(FResponseData[0]);
   if (FResponseLength >= 6) then begin
      // interpret the packet captain!
      FByteCount :=(Word(FResponseData[2]) shl 8) + Byte(FResponseData);
      FFIFOQueueCount :=(Word(FResponseData[4]) shl 8) + Byte(FResponseData[5]);
      if (FByteCount > (FResponseLength+4)) then begin
         FByteCount := FResponseLength-4;
      end;
      // make sure the FIFO count deal is correct.
      if (FFIFOQueueCount > ((FByteCount-2) shr 1)) then begin
         FFIFOQueueCount := ((FByteCount-2) shr 1);
      end;
      //SetLength(FIFOQueueValues,FFIFOQueueCount);
      ByteOffset := 6;
      for Counter := 0 to FFIFOQueueCount do begin
          FIFOQueueValues[Counter] :=(Word(FResponseData[ByteOffset]) shl 8) + Byte(FResponseData[ByteOffset +1]);
          ByteOffset := ByteOffset + 2;
      end;
   end else begin
      FStatus := modbusBadReplyPacket;
   end;
end;
}

{
procedure TModbusPacket.InterpretReadMultipleRegisters;
//(PacketID, UserCode : Word; FunctionCode : Byte;FResponseData : PChar;FResponseLength : Word;var ReadMultipleRegistersInformation : TReadMultipleRegistersInformation) : TModbusResult;
var
   Counter : Word;
   FReadLength : Word;
   Offset : Integer;
begin
   // check that the basics are correct...
   if (FResponseLength < 4) then begin
      FStatus := modbusBadReplyPacket;
      exit;
   end;
   if (FResponseData[1] <> Char(FunctionCode)) then begin
      FStatus := modbusBadReplyPacket;
      exit;
   end;
   if ((Byte(FResponseData[1]) = (FunctionCode or $80))) then begin
      FStatus := modbusException;//DecodeException(Byte(FResponseData[2]));
      exit;
   end;
   if (Byte(FResponseData[3]) = (constSubFunctionReadRegisters or $80)) then begin
      FStatus := modbusException;//DecodeException(Byte(FResponseData[4]));
      exit;
   end;
   Counter := Integer(FResponseData[2]) - 2;
   // ensure that the block is REALLY as long as it's supposed to be.
   if (FResponseLength < (Counter + 5)) then begin
      FStatus := modbusBadReplyPacket;
      exit;
   end;
   FReadLength := Trunc((Counter) / 5);
   //SetLength(ReadMultipleRegistersInformation.RegisterValueList,FReadLength);
   // read in the values.
   Offset := 5;
   for Counter := Low(ReadMultipleRegistersInformation.RegisterValueList) to High(ReadMultipleRegistersInformation.RegisterValueList) do begin
      ReadMultipleRegistersInformation.RegisterValueList[Counter].Series := Byte(FResponseData[Offset]);
      ReadMultipleRegistersInformation.RegisterValueList[Counter].RegisterIndex := Integer(Integer(FResponseData[Offset+1]) shl 8) or Integer(Integer(FResponseData[Offset+2]) and 255);
      ReadMultipleRegistersInformation.RegisterValueList[Counter].RegisterValue := Integer(Integer(FResponseData[Offset+3]) shl 8) or Integer(Integer(FResponseData[Offset+4]) and 255);
      Offset := Offset + 5;
   end;
   FStatus := modbusGood;
end;
}


{procedure TModbusPacket.InterpretReadMultipleCoils;
var
   Counter : Word;
   CoilCount : Word;
   Offset : Integer;
begin
   // check that the basics are correct...
   if (FResponseLength < 4) then begin
      FStatus := modbusBadReplyPacket;
      exit;
   end;
   if ((Byte(FResponseData[1]) = (FunctionCode or $80))) then begin
      Result:=modbusException;//DecodeException(Byte(FResponseData[2]));
      exit;
   end;
   if (Byte(FResponseData[3]) = (constSubFunctionReadRegisters or $80)) then begin
      Result:=modbusException;//DecodeException(Byte(FResponseData[4]));
      exit;
   end;
   // store the values.
   Counter := Integer(FResponseData[2]) - 2;
   // ensure that the block is REALLY as long as it's supposed to be.
   if (FResponseLength < (Counter + 5)) then begin
      FStatus := modbusBadReplyPacket;
      exit;
   end;
   CoilCount := Trunc((Counter) / 4);
   //SetLength(ReadMultipleCoilsInformation.CoilValueList,CoilCount);
   // read in the values.
   Offset := 5;
   for Counter := Low(ReadMultipleCoilsInformation.CoilValueList) to High(ReadMultipleCoilsInformation.CoilValueList) do begin
      ReadMultipleCoilsInformation.CoilValueList[Counter].Series := Byte(FResponseData[Offset]);
      ReadMultipleCoilsInformation.CoilValueList[Counter].CoilIndex := Integer(Integer(FResponseData[Offset+1]) shl 8) or Integer(Integer(FResponseData[Offset+2]) and 255);
      ReadMultipleCoilsInformation.CoilValueList[Counter].CoilValue := Integer(FResponseData[Offset+3]);
      Offset := Offset + 4;
   end;
   FStatus := modbusGood;
end;}


function TModbusPacket.Interpret:Boolean;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   // Determine what the type was and act accordingly.
   if (FResponseLength = 0) then begin
         FStatus := modbusTimeout;
{$ifdef DEBUGINFO_ON}
         OutputDebugString('ModbusPacket.pas: MODBUS TIMEOUT');
{$endif}
         result := false;
         exit;
   end;
   // If anything at all is received allow the individual functions to deal
   // with it:
   FStatus := modbusGood;
   case (FFunctionCode) of

        { read functions }
      constReadCoilStatus :
        InterpretCoils;

      constReadInputStatus :
        InterpretCoils;

      constReadHoldingRegisters :
        InterpretRegisters;

      constReadInputRegisters :
        InterpretRegisters;

         { write functions }
      constPresetSingleRegister:
        InterpretPresetSingleRegister;//( FValues[0] );

      constPresetMultipleRegisters:
        InterpretPresetMultipleRegisters;

      constForceSingleCoil:
        InterpretForceSingleCoil;

      constForceMultipleCoils:
        InterpretForceMultipleCoils;


   else
        FStatus := modbusFailed
   end;
   if FStatus = modbusGood
     then result := true
   else
        result := false;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;

{---Other Interpret Code snippet stuff

      constForceSingleCoil : begin
         if (ResponseLength < 6) then begin
            FStatus := modbusBadReplyPacket;
         end else begin
            if ((Byte(ResponseData[0]) <> SlaveAddress) or (Byte(ResponseData[1]) <> FunctionCode)) then begin
               if (Byte(ResponseData[1])=Byte(FunctionCode or $80)) then begin
                  FStatus := modbusException;//DecodeException(Byte(ResponseData[2]));
               end else begin
                  FStatus := modbusBadReplyPacket;
               end;
            end else begin
               // Looks good captain.
               FStatus := modbusGood;
               FOffsetAddress := (Word(ResponseData[2]) shl 8) + Byte(ResponseData[3]);
               Inc(FOffsetAddress);
               if (ResponseData[4] = Char($FF)) then begin
                  FBooleanValue := TRUE;
               end else begin
                  FBooleanValue := FALSE;
               end;
               if (Assigned(OnSuccessfulForceSingleCoil)) then begin
                  OnSuccessfulForceSingleCoil(Self,PacketID,UserCode,FOffsetAddress,FBooleanValue);
               end;
            end;
         end
      end;
      constPresetSingleRegister : begin
         if (ResponseLength < 6) then begin
            FStatus := modbusBadReplyPacket;
         end else begin
            if ((Byte(ResponseData[0]) <> SlaveAddress) or (Byte(ResponseData[1]) <> FunctionCode)) then begin
               if (Byte(ResponseData[1])=Byte(FunctionCode or $80)) then begin
                  FStatus := modbusException;//DecodeException(Byte(ResponseData[2]));
               end else begin
                  FStatus := modbusBadReplyPacket;
               end;
            end else begin
               FStatus := modbusGood;
               // Looks good captain.
               FOffsetAddress := (Word(ResponseData[2]) shl 8) + Byte(ResponseData[3]);
               Inc(FOffsetAddress);
               FWordValue := (Word(ResponseData[4]) shl 8) + Byte(ResponseData[5]);
               if (Assigned(OnSuccessfulPresetSingleRegister)) then begin
                  OnSuccessfulPresetSingleRegister(Self,PacketID,UserCode,FOffsetAddress,FWordValue);
               end;
            end;
         end;
      end;
      constReadExceptionStatus : begin
         if (ResponseLength < 3) then begin
            FStatus := modbusBadReplyPacket;
         end else begin
            if ((Byte(ResponseData[0]) <> SlaveAddress) or (Byte(ResponseData[1]) <> FunctionCode)) then begin
               if (Byte(ResponseData[1])=Byte(FunctionCode or $80)) then begin
                  FStatus := modbusException;//DecodeException(Byte(ResponseData[2]));
               end else begin
                  FStatus := modbusBadReplyPacket;
               end;
            end else begin
               FStatus := modbusGood;
               FByteValue := Byte(ResponseData[2]);
               if (Assigned(FOnSuccessfulReadExceptionStatus)) then begin
                  FOnSuccessfulReadExceptionStatus(Self,PacketID,UserCode,FByteValue);
               end;
            end;
         end;
      end;
      constFetchCommEventCounter : begin
         FStatus := InterpretCommEventInformation(
                PacketID,
                UserCode,
                constFetchCommEventCounter,
                PChar(@ResponseData[0]),
                ResponseLength, FCommEventInformation );
                
         if (FStatus =modbusGood) then begin
            if (Assigned(OnSuccessfulFetchCommEventCounter)) then begin
               OnSuccessfulFetchCommEventCounter(Self,FCommEventInformation);
            end;
         end;
      end;
      constFetchCommEventLog : begin
         FStatus := InterpretCommLogInformation(PacketID,
                UserCode,
                constFetchCommEventLog,
                PChar(@ResponseData[0]),
                ResponseLength,
                FCommEventLogInformation);
                
         if (FStatus =modbusGood) then begin
            if (Assigned(OnSuccessfulFetchCommEventLog)) then begin
               OnSuccessfulFetchCommEventLog(Self,FCommEventLogInformation);
            end;
         end;
      end;
      constForceMultipleCoils : begin
         if (ResponseLength < 6) then begin
            FStatus := modbusBadReplyPacket;
         end else begin
            if ((Byte(ResponseData[0]) <> SlaveAddress) or (Byte(ResponseData[1]) <> FunctionCode)) then begin
               if (Byte(ResponseData[1])=Byte(FunctionCode or $80)) then begin
                  FStatus := modbusException;//DecodeException(Byte(ResponseData[2]));
               end else begin
                  FStatus := modbusBadReplyPacket;
               end;
            end else begin
               FStatus := modbusGood;
               FOffsetAddress := (Word(ResponseData[2]) shl 8) + Byte(ResponseData[3]);
               Inc(FOffsetAddress);
               FWordValue := (Word(ResponseData[4]) shl 8) + Byte(ResponseData[5]);
               if (Assigned(OnSuccessfulForceMultipleCoils)) then begin
                  OnSuccessfulForceMultipleCoils(Self,PacketID,UserCode,FOffsetAddress,FWordValue);
               end;
            end;
         end;
      end;
      constPresetMultipleRegisters : begin
         if (ResponseLength < 6) then begin
            FStatus := modbusBadReplyPacket;
         end else begin
            if ((Byte(ResponseData[0]) <> SlaveAddress) or (Byte(ResponseData[1]) <> FunctionCode)) then begin
               if (Byte(ResponseData[1])=Byte(FunctionCode or $80)) then begin
                  FStatus := modbusException;//DecodeException(Byte(ResponseData[2]));
               end else begin
                  FStatus := modbusBadReplyPacket;
               end;
            end else begin
               FStatus := modbusGood;
               FOffsetAddress := (Word(ResponseData[2]) shl 8) + Byte(ResponseData[3]);
               Inc(FOffsetAddress);
               FWordValue := (Word(ResponseData[4]) shl 8) + Byte(ResponseData[5]);
               if (Assigned(OnSuccessfulPresetMultipleRegisters)) then begin
                  OnSuccessfulPresetMultipleRegisters(Self,PacketID,UserCode,FOffsetAddress,FWordValue);
               end;
            end;
         end;
      end;
      constReportSlaveID : begin
         FStatus := InterpretSlaveInformation( PacketID,
                UserCode,
                constReportSlaveID,
                PChar(@ResponseData[0]),
                ResponseLength,
                FSlaveInformation);
                
         if (FStatus =modbusGood) then begin
            // send out the event.
            if (Assigned(OnSuccessfulReportSlaveAddress)) then begin
               OnSuccessfulReportSlaveAddress(Self,FSlaveInformation);
            end;
         end;
      end;
      constMaskWrite4xRegister : begin
         if (ResponseLength < 8) then begin
            FStatus := modbusBadReplyPacket;
         end else begin
            if ((Byte(ResponseData[0]) <> SlaveAddress) or (Byte(ResponseData[1]) <> FunctionCode)) then begin
               if (Byte(ResponseData[1])=Byte(FunctionCode or $80)) then begin
                  FStatus := modbusException;//DecodeException(Byte(ResponseData[2]));
               end else begin
                  FStatus := modbusBadReplyPacket;
               end;
            end else begin
               FStatus := modbusGood;
               FOffsetAddress := (Word(ResponseData[2]) shl 8) + Byte(ResponseData[3]);
               Inc(FOffsetAddress);
               FWordValue := (Word(ResponseData[4]) shl 8) + Byte(ResponseData[5]);
               FWordValue2 := (Word(ResponseData[6]) shl 8) + Byte(ResponseData[7]);
               if (Assigned(OnSuccessfulMaskWriteRegister)) then begin
                  OnSuccessfulMaskWriteRegister(Self,PacketID,UserCode,FOffsetAddress,FWordValue,FWordValue2);
               end;
            end;
         end;
      end;
     constReadFIFOQueue : begin
         FStatus := InterpretFIFOQueue(PacketID,
                        UserCode,
                        FunctionCode,
                        PChar(@ResponseData[0]),
                        ResponseLength,
                        FFIFOQueueResults);
         if (FStatus = modbusGood) then begin
            if (Assigned(FOnSuccessfulReadFIFORegister)) then begin
               FOnSuccessfulReadFIFORegister(Self,FFIFOQueueResults);
            end;
         end;
      end;
      constManualPacket : begin
         if (FStatus = modbusGood) then begin
            SetLength(FByteArray,ResponseLength);
            for FWordValue := 0 to ResponseLength-1 do begin
               FByteArray[FWordValue] := Byte(ResponseData[FWordValue]);
               if (Assigned(OnSuccessfulManualPacket)) then begin
                  OnSuccessfulManualPacket(Self,PacketID,UserCode,FByteArray);
               end;
            end;
         end;
      end;

      constSpecialFunction : begin
         // SpecialFunction is function 7E, which allows us to read multiple registers or coils in a single scan.
         if (Data1 = constSubFunctionReadRegisters) then begin
            if (Assigned(OnSuccessfulReadMultipleRegisters)) then begin
               if (InterpretReadMultipleRegisters(PacketID, UserCode,FunctionCode,
                        PChar(@ResponseData[0]),
                        ResponseLength,
                        FReadMultipleRegistersInformation)=modbusGood) then begin
                  OnSuccessfulReadMultipleRegisters(Self,PacketID,UserCode,
                                FReadMultipleRegistersInformation);
               end;
            end;
         end else if (Data1 = constSubFunctionReadCoils) then begin
            if (Assigned(OnSuccessfulReadMultipleCoils)) then begin
               if (InterpretReadMultipleCoils(PacketID, UserCode,
                        FunctionCode,
                        PChar(@ResponseData[0]),
                        ResponseLength,
                        FReadMultipleCoilsInformation)=modbusGood) then begin
                  OnSuccessfulReadMultipleCoils(Self,PacketID,UserCode,FReadMultipleCoilsInformation);
               end;
            end;
         end;
      end;
      }

procedure TModbusPacket.SetPollingRate(aPollingRate:DWORD);
begin
   if (aPollingRate > 0) then begin
      FPollingInterval := aPollingRate;
      FPollingNextTime := GetTickCount;
      Dec(FPollingNextTime); // Right away, then add PollingRate to PollingNextTime to continue...
   end else begin
      FPollingInterval := 0;
      FPollingNextTime := 0;
   end;

end;

procedure TModbusPacket.SetReadLength(aReadLength:Word);
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
 if (aReadLength <> FReadLength) then begin
   FReadLength := aReadLength;
  // never set array of values to less than 1:
  if (aReadLength<1) then
        aReadLength := 1;
  SetLength(FValues,aReadLength);
 end;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;


// If the user sets Packet.DebugId='MyString' then 'MyString'
// is returned as the debug id whenever the TModbusMasterThread
// is handling this packet and emits a trace message pertaining to that packet. This is
// very helpful for debugging. 
procedure  TModbusPacket.SetDebugId(debugId:String); // New: Give the packet a name, this really helps with troubleshooting.
var
 t,n:Integer;
begin
  n := Length(debugId);
  if n > (constModbusDebugIdLength-1) then begin
      debugId := Copy(debugId,1, (constModbusDebugIdLength-1) );
      n := Length(debugId);
  end;
  // copy it in:
  for t := 1 to n do begin
      FDebugId[t-1] := debugId[t];
  end;
  FDebugId[n] := Chr(0); // ascii-nul (aka Chr(0)) terminates.
end;

// the DebugId property helps us tell which packet
// has a problem when displaying trace messages.
// If none is set, then the userCode is returned.
function TModbusPacket.GetDebugId:String;
begin
 if FDebugId[0]<>Chr(0) then
  result := String(PChar(@FDebugId[0]))
 else
  result := 'UserCode='+IntToStr(FUserCode); // If not identified otherwise, display user code in trace messages.
end;

procedure TModbusPacket.SetActive(newActive:Boolean);
//var
//  dbg:String;
begin

  {$ifdef MODBUS_DEBUG}
      if newActive then
          DebugPacketOk;
  {$endif MODBUS_DEBUG}
  
  if FActive <> newActive then begin
        FActive := newActive;
        if not FActive then
               FTraceFlag := false;

  end;
end;


// Update polling time after we actually select this packet!
procedure TModbusPacket.PollingTimeUpdate;
begin
  if FPollingInterval>0 then begin
      if (FPollingOkCount>0) or (FRetriesExhaustedErrors>3) then begin
         // normal case: Schedule in future, at a certain polling interval:
         FPollingNextTime :=  GetTickCount+FPollingInterval;
      end else begin
         // first time case: first time is right now, this bumps it to near the head of the sending-queue, effectively: 
         FPollingNextTime := GetTickCount;
      end;
  end;
  Inc(FSchedulerCount); // We've been scheduled, update the counter.
end;

function TModbusPacket.PollingCheck(tickCount:DWORD):Integer;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
  result := -1; // not due
  if not Active then exit;

  if (FPollingInterval>0) then begin

        if TimerHasReachedSetpoint(tickCount,FPollingNextTime) then begin
            result := TimerElapsed(FPollingNextTime,tickCount); // return amount of time overdue.
            if (result>45000) then begin
                  OutputDebugString(PChar('ModbusPacket.pas: TModbusPacket.PollingCheck: UserCode='+IntToStr(Self.UserCode)+' Debugging Invalid polled TimerElapsed values: '+IntToStr(result) ) );
            end;
        end;
  end else begin

//        if FStatus=modbusPending then exit;

        result := TimerElapsed( FPollingNextTime,tickCount);
        if (result>60000) then begin
                OutputDebugString( PChar( 'ModbusPacket.pas: TModbusPacket.PollingCheck: UserCode='+IntToStr(Self.UserCode)+' Debugging Invalid one-shot TimerElapsed values: '+IntToStr(result) ) );
        end;
        
        if (result<0) then
            result := 0;
        Inc(result,1000); // Give an edge to the one shot stuff.

  end;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;

function TModbusPacket.CheckMaxTimeouts:Boolean;
begin
  if MaxTimeouts< 3 then // SANITY LIMIT!
      MaxTimeouts := 3;
      
  result := TimeoutsSinceLastValidPacket >= MaxTimeouts;
end;


{ write response interpreter:
  interprets response to preset single register (write 4xxxx )
  command, to see if the write was successful or an exception. }
procedure TModbusPacket.InterpretPresetSingleRegister;
begin
  FIsReadResponse:= false; // Last response was a Write response!
  
  if (FResponseLength<1) then begin
        FStatus := modbusTimeout;
        exit;
  end;
  // an exception has occurred...
  if (Byte(FResponseData[1])=Byte(FFunctionCode or $80)) then begin
     FStatus := modbusException;//DecodeException(Byte(FPacket^.ResponseData[2]));
  end else if ((FSendLength-2)<>FResponseLength) then begin
     FStatus := modbusBadReplyPacket;
  end else begin
      if not CompareMem( @FSendData, @FResponseData, FResponseLength) then
          FStatus := modbusBadReplyPacket;
  end;

end;


procedure TModbusPacket.InterpretPresetMultipleRegisters;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   FIsReadResponse:= false; // Last response was a Write response!
        // header check?
   if (FResponseLength=0) then begin
        FStatus := modbusTimeout;
        exit;
   end;

   if ((Byte(FResponseData[0]) <> FSlaveAddress) or (Byte(FResponseData[1]) <> FFunctionCode)) then begin
            // an exception has occurred?
            if (Byte(FResponseData[1])=Byte(FFunctionCode or $80)) then begin
               FStatus := modbusException;//DecodeException(Byte(FPacket^.ResponseData[2]));
            end else begin
               FStatus := modbusBadReplyPacket;
            end;
   end else begin
        // header check was okay, now do contents check.
            if   (     ( FResponseLength >= 6)
                   //  The response is slightly invalid on the DL06 PLC:
                   //and ( FResponseData[2] = Char( (FStartingAddress-40001)shr 8)   )
                   //and ( FResponseData[3] = Char( (FStartingAddress-40001)and 255) )
                   and ( FResponseData[4] = Char( FReadLength shr 8   )   )
                   and ( FResponseData[5] = Char( FReadLength and 255 ) )
                  )
                 then begin
                   FStatus := modbusGood;
                 end else begin
                   FStatus := modbusBadReplyPacket;
                 end;
   end;

  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;



procedure TModbusPacket.InterpretForceSingleCoil;
begin
     {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   FIsReadResponse:= false; // Last response was a Write response!
        // header check?
   if (FResponseLength=0) then begin
        FStatus := modbusTimeout;
        exit;
   end;

   if ((Byte(FResponseData[0]) <> FSlaveAddress) or (Byte(FResponseData[1]) <> FFunctionCode)) then begin
            // an exception has occurred?
            if (Byte(FResponseData[1])=Byte(FFunctionCode or $80)) then begin
               FStatus := modbusException;//DecodeException(Byte(FPacket^.ResponseData[2]));
            end else begin
               FStatus := modbusBadReplyPacket;
            end;
   end else begin
        // header check was okay, now do contents check.
            if   (     ( FResponseLength = 6)
                   and ( FResponseData[2] = Char( (FStartingAddress-1)shr 8)   )
                   and ( FResponseData[3] = Char( (FStartingAddress-1)and 255) )
                  )
                 then begin
                   FStatus := modbusGood;
                 end else begin
                   FStatus := modbusBadReplyPacket;
                 end;
   end;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
end;


procedure TModbusPacket.InterpretForceMultipleCoils;
begin
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   FIsReadResponse:= false; // Last response was a Write response!
        // header check?
   if (FResponseLength=0) then begin
        FStatus := modbusTimeout;
        exit;
   end;

   if ((Byte(FResponseData[0]) <> FSlaveAddress) or (Byte(FResponseData[1]) <> FFunctionCode)) then begin
            // an exception has occurred?
            if (Byte(FResponseData[1])=Byte(FFunctionCode or $80)) then begin
               FStatus := modbusException;//DecodeException(Byte(FPacket^.ResponseData[2]));
            end else begin
               FStatus := modbusBadReplyPacket;
            end;
   end else begin
        // header check was okay, now do contents check.
            if   (     ( FResponseLength = 6)
                   and ( FResponseData[2] = Char( (FStartingAddress-1)shr 8)   )
                   and ( FResponseData[3] = Char( (FStartingAddress-1)and 255) )
                   and ( FResponseData[4] = Char( FReadLength shr 8)   )
                   and ( FResponseData[5] = Char( FReadLength and 255) )
                  )
                 then begin
                   FStatus := modbusGood;
                 end else begin
                   FStatus := modbusBadReplyPacket;
                 end;
   end;
  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif MODBUS_DEBUG}
   
end;


initialization
  ModbusPacketDestroyCounter := 0;
  ModbusPacketAllocCounter := 0;
  ModbusPacketActiveCounter := 0;
  ModbusLastBadPacket := nil;
end.
