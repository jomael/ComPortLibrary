//----------------------------------------------------------------------------
// Modbus.pas
//
//  TModbusMaster Component
//
//  Rev 5.0 (Aug 25, 2004) by Warren Postma
// (C) 2003,2004 Warren Postma.
// Based partly on an original version by Dennis Forbes, with
// contributions from Matthew Skelton.
//
//
// Version 5.0 Changes:
//     - Removed Window Handle and PostMessage functionality,
//       and implemeneted using TThread.Synchronize instead.
//
//     - Got rid of ancient 'PacketID' (WORD) return values in
//       Read(...) and Write(...) methods, which now just return true/false.
//       The packet ids were not unique (only 65536 unique packet ids), and
//       this caused some bizarre problems. We find packets now either by
//       their user code, or by directly keeping around a pointer
//       to the TModbusPacket object itself.  The end user is supposed to
//       use user codes (not manipulate TModbusPacket objects) in most cases.
//
//     - Win32 Serial Communications change: now uses COMMTIMEOUTS
//       and avoids calling ClearCommError (via TComPort.InputCount)
//       because of USB-to-serial convertor driver bugs. The FTDI
//       chipset (used by Sealevel SeaPORT, and many OEM USB to serial
//       convertors) or the FTDI.SYS driver has problems supporting
//       the barrage of Win32 ClearCommError calls this component
//       formerly generated.
//
//----------------------------------------------------------------------------
// Modbus RTU Communications Component. This component supports
// Modicon 984 PLCs and any compatible third party device that can
// act as a Modbus Slave, and can support these industry standard
// Modbus protocol commands:
//
//    01        read coil (0xxxx)
//    02        read input (1xxxx)
//    03        read holding register (4xxxx)
//    04        read input register (3xxxx)
//    05        write single coil (0xxxx)
//    06        write single register (4xxxx)
//    15        write multiple coils (0xxxx)
//    16        write multiple registers (4xxxx)
//
//
// NOTE:
//   Relies on CPort com port component.
//
//
//
//*************************************************************************
//
// See ModbusThread.pas for the actual communications which happen in
// the background.
//
//*************************************************************************
//
//  Because of the background nature of the communications, you have
// a choice of non-blocking (event driven) or blocking read/write operations.
//
// The methods TModbusMaster.Read() and TModbusMaster.Write() are non-blocking
// which means they return immediately, and an event fires when the data
// comes in, or the communications fails.
//
// The TModbusMaster.BlockingRead and TModbusMaster.BlockingWrite methods
// however will not return until the communications have either completed,
// or have failed.  No events are fired when using Blocking calls.
//
// This allows you to write synchronous or asynchronous code.
//
//--------------------------------------------------------------------------
//
// History:
//  2004-02-25 13:11:55 - nullstr - Added Result initialisation to TModbusMasterCustomCommandSequence to avoid compiler warning
//  2004-03-26 15:11:34 - nullstr - Replaced Application.OnMessage / Owner.WindowMessage logic with our own internal Window message handling
//
//  2004-04-19 11:11:22 - wpostma - Cleanup. nullstr fixes integrated and checked into my own CVS.
//
//                                 NEW: DebugPacketOk debug code is only compiled in
//                                 if MODBUS_DEBUG is defined. This code is intended only to be
//                                 compiled in if you are having a thread-related corruption problem
//                                 caused by threading/concurrency issues. The purpose is to have
//                                 corrupt packet data cause an exception as SOON as possible to
//                                 aid in debugging the system. You shouldn't ship the software with
//                                 this mode enabled.  Note that I haven't had problems with recent
//                                 delphi versions (D6 or later), but that with D5 or earlier, I have
//                                 had threading/concurrency problems!!!



unit CportModbus;

interface

{$R-}
{$Q-}
{$WARN SYMBOL_DEPRECATED OFF} // We call AllocateHWnd and DeallocateHWnd.


// {$R Modbus.dcr}


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    syncobjs, extctrls, CportModbusThread, CportModbusPacket, CPort {TComPort};


type
  //? @@@ - nullstr - 2004-03-31 14:19:12 - Cross-reference TModbusPacket here to avoid errors when using component in IDE
  //TModbusPacket = ModbusPacket.TModbusPacket;
  //? @@@ - end

{ EVENT HANDLER TYPES}

  //TModbusMasterSuccessfulRead = procedure (Sender : TObject; Packet : TModbusPacket) of object;
  //TModbusMasterSuccessfulWrite = procedure (Sender : TObject; Packet : TModbusPacket) of object;

  TComPortModbusMasterPacketFailedEvent = procedure(Sender : TObject; Packet:TModbusPacket ) of object; // Failure or Exceptions handling.
  TComPortModbusMasterTraceEvent = procedure(Sender:TObject;TraceMessage:String) of object;
  TComPortModbusMasterStateEvent = procedure(Sender:TObject; Packet:TModbusPacket) of object;

{ COMPONENT }

  // TModbusMaster - This is the actual component that instantiates a TComPortModbusMasterThread when active.
  TComPortModbusMaster = class(TComponent)
  private
     procedure InitializeSettings;
     procedure SetActiveState(FNewState : Boolean);  // Active property write.
     procedure SetNewComPort(FNewComPort : TComPort); // ComPort property write.
     procedure SetPacketTimeoutMS(FNewPacketTimeoutMS : Word); // PacketTimeoutMS property write.
     procedure SetNoResponsePacketTimeoutMS(FNewNoResponsePacketTimeoutMS : Word);
     procedure SetPacketRetryCount(FNewPacketRetryCount : Word); // PacketRetryCount property write.
     procedure SinglePacketMessageHandler(PacketPointer : pointer);

     function GetTotalCRCErrors : Cardinal; // TotalCRCErrors property read.
     procedure SetTotalCRCErrors(TotalCRCErrors : Cardinal); // TotalCRCErrors property write.
     function GetTotalTimeoutErrors : Cardinal; // TotalTimeoutErrors property read.
     procedure SetTotalTimeoutErrors(TotalTimeoutErrors : Cardinal); // TotalTimeoutErrors property write.
//     procedure SetRealConnectionSpeed(NewRealConnectionSpeed : Cardinal); // RealConnectionSpeedOverride property write.
     function GetTotalBytesReceived : Cardinal;
     function GetTotalBytesSent : Cardinal;
     function GetExceptions:Integer;

  protected


    { Getters/Setters for Modbus Thread's Logging options }
     FTxLogging,FRxLogging:Boolean;
     function GetTXLogging:Boolean;
     function GetRXLogging:Boolean;
     procedure SetTXLogging(newValue:Boolean);
     procedure SetRXLogging(newValue:Boolean);


  private

    FActive : Boolean;

    
    FOldWindowProc : TWndMethod;
    FNoParentWindow : Boolean;
    FComPort: TComPort;  // The delphi com port object.
    FModbusMasterThread : TComPortModbusMasterThread;     // The Packet Queue and the actual protocol logic are in here.

    FInTimer : Boolean;
    FBlocking : Boolean;
//    FRealConnectionSpeed : Cardinal;
    FCriticalSection :
        {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
            TModCriticalSection;
        {$else}
            TCriticalSection;
        {$endif}

    FWritePriorityBoost:Integer;
    FSleepTime:Integer;//NEW!
    FShuttingDown :Boolean;
    FPacketTimeoutMS : Word;
    FNoResponsePacketTimeoutMS : Word;
    FPacketRetryCount : Word;
    FTotalCRCErrors : Cardinal;
    FTotalTimeoutErrors : Cardinal;
    FMaxTimeouts :Integer; // passed to each packet as it's created as a default value.

    // Timing parameters passed to modbus thread when it is created:
    FTimeoutRecovery:Integer; // millseconds to sleep for after every timeout.
    FInitialGuardTime:Integer;
    FMaxGuardTime:Integer;




    // events:
    FOnActiveStateChange : TNotifyEvent;

    // General success notification events (happen only if
    // a packet specific callback was not given in the
    // call to Read/Write).
    FOnSuccessfulRead    : TModbusSuccessNotification;
    FOnSuccessfulWrite   : TModbusSuccessNotification;

    FOnPacketFailedEvent : TComPortModbusMasterPacketFailedEvent;
    FOnCustomResponse    : TModbusSuccessNotification;
    FOnTraceEvent        : TComPortModbusMasterTraceEvent;
    FOnTxEvent           : TComPortModbusMasterStateEvent;


  private { private methods }
     function _BlockingCall(var Packet : TModbusPacket;
                            UserCode : Word; WriteFlag:Boolean;
                            SlaveAddress : Byte; StartAddress:Word;
                            ReadCount:Word;
                            FunctionCode : Byte;
                            Data : PChar;
                            DataLength:Integer;
                            MaximumWaitMS : Word;
                            DebugId:String ) : TModbusResult;


//    procedure ApplicationMessageHandler(var Msg: TMsg; var Handled: Boolean);



    function GetTimingTraceEnable:Boolean;
    procedure SetTimingTraceEnable(en:Boolean);

    procedure Trace(msg:String);

  public

    // constructor/destructor
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function PacketWatchdog:Boolean;

    procedure _ThreadTrace; // A TThread.Synchronize method to be invoked by the Modbus Thread only!
    procedure _ThreadTxEvent; // A TThread.Synchronize method to be invoked by the Modbus Thread only!
    procedure _ThreadPacketWaitingEvent; // A TThread.Synchronize method to be invoked by the Modbus Thread only!




//    procedure _DebugCheckPacketUserCodesSequencing; {!!!!debughelper!!!!}

    function Offline(SlaveAddress:Integer;setOffline:Boolean):Integer;


    procedure StopReading; // stops all polling activity. (invokes thread object's polling stopper but thread keeps running, sleeping in background, no communications }

    procedure StopReadingByUserCode( UserCode:Integer ); // Stop packets matching UserCode.
    function  IsUserCodeActive( UserCode:Integer ):Boolean;




    function CustomCommand(UserCode:Word; Command:String; AppendCrc:Boolean; PacketTimeoutMS:DWORD; TraceFlag:Boolean ) : Boolean;

    function CustomCommandSequence(var UserCode:Word; Commands:TStrings; AppendCrc:Boolean; PacketTimeoutMS:DWORD; TraceFlag:Boolean ) :Boolean;

{$IFDEF MODBUS_DEBUG}
    procedure DebugPacketOk;
{$endif}
    // Blocking Functions



    // NEW BlockingRead signature (has new optional final parameter DebugId, giving us the
    // ability to pass a debug id string to help with diagnostics/tracing). Pass in
    // an empty string ('') if you aren't using the debugid.
    function BlockingRead(
                           SlaveAddress : byte;
                           StartingAddress : Word;
                           ReadCount : Word;
                           var Values : Array of Word;
                           MaximumWaitMS : Word;
                           DebugId : String
                           ) : Boolean;



    // New API (with DebugId. You can pass in '' if you aren't using the debugid feature).
    function BlockingWrite(
                                SlaveAddress : Byte;
                                StartingAddress : Word;
                                WriteCount : Word;
                                Values : Array of Word;
                                MaximumWaitMS : Word;
                                DebugId:String ) : Boolean;


    // Event Driven functions. Returns immediately with a valid user code
    // or 0 if failed.  If you provide an OnReadOk/OnWriteOk callback it is invoked
    // when finished, or if not, then the component's event
    // is fired instead.
    function Read( UserCode : Word; DebugId:String; SlaveAddress : Byte; StartingAddress : Word; ReadCount : Word; PollingRate:DWORD; Timeouts:Integer; TraceFlag:Boolean;
                                    OnReadOk:TModbusSuccessNotification=nil ) : Boolean; {ok=true, failed=false}

    function Write( UserCode:Word; DebugId:String; SlaveAddress : Byte; StartingAddress : Word; WriteCount : Word; Timeouts:Integer; TraceFlag:Boolean; Values:Array of Word;
                                    OnWriteOk:TModbusSuccessNotification=nil ) : Boolean; {ok=true, failed=false}


    // Other component methods

    procedure TerminateThread; // Force thread to stop (to be done at earliest convience during orderly app shutdown)

   { runtime properties }
    property TotalCRCErrors : Cardinal read GetTotalCRCErrors write SetTotalCRCErrors;
    property TotalTimeoutErrors : Cardinal read GetTotalTimeoutErrors write SetTotalTimeoutErrors;


    property CriticalSection :
        {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
            TModCriticalSection
        {$else}
            TCriticalSection
        {$endif}
            read FCriticalSection;

//    function  Hold:Integer;
    procedure BeginHold;
    procedure EndHold;

        { Begin a batch of blocking writes. Holds all other polling activities during this time. }
    procedure BeginBlockingCallBatch;
    { End a batch of blocking writes. Resumes normal modbus activity. }
    procedure EndBlockingCallBatch;


    { runtime Extra-verbose-debug-trace-information enabler: }
    property TimingTraceEnable:Boolean read GetTimingTraceEnable write SetTimingTraceEnable;
    property _Thread : TComPortModbusMasterThread read FModbusMasterThread;



        
  published
    property  Active : Boolean read FActive write SetActiveState;
    property  ComPort : TComPort read FComPort write SetNewComPort;
    property  MaxTimeouts : Integer read FMaxTimeouts write FMaxTimeouts;

    property  EnableTXLogging:Boolean read GetTXLogging write SetTXLogging;
    property  EnableRXLogging:Boolean read GetRXLogging write SetRXLogging;
    property  PacketTimeoutMS : Word read FPacketTimeoutMS write SetPacketTimeoutMS;
    property  NoResponsePacketTimeoutMS : Word read FNoResponsePacketTimeoutMS write SetNoResponsePacketTimeoutMS;
    property  PacketRetryCount : Word read FPacketRetryCount write SetPacketRetryCount;
//    property  RealConnectionSpeedOverride : Cardinal read FRealConnectionSpeed write SetRealConnectionSpeed;
    property  TotalBytesSent : Cardinal read GetTotalBytesSent;
    property  TotalBytesReceived : Cardinal read GetTotalBytesReceived;

    property Exceptions:Integer read GetExceptions;

    // events
    property OnActiveStateChange : TNotifyEvent read FOnActivestateChange write FOnActiveStateChange;
    property OnSuccessfulRead:  TModbusSuccessNotification read FOnSuccessfulRead write FOnSuccessfulRead;
    property OnCustomResponse : TModbusSuccessNotification read FOnCustomResponse write FOnCustomResponse;
    property OnSuccessfulWrite : TModbusSuccessNotification read FOnSuccessfulWrite write FOnSuccessfulWrite;

    property OnPacketFailed : TComPortModbusMasterPacketFailedEvent read FOnPacketFailedEvent write FOnPacketFailedEvent;
    property OnTraceEvent : TComPortModbusMasterTraceEvent read FOnTraceEvent write FOnTraceEvent;
    property OnTxEvent    : TComPortModbusMasterStateEvent read FOnTxEvent    write FOnTxEvent;

    // Timing parameters (must set before setting Modbus ACTIVE).
    // WARNING: Any change while modbus thread is running has no effect.
    property TimeoutRecovery:Integer read FTimeoutRecovery write FTimeoutRecovery;
    property InitialGuardTime:Integer read FInitialGuardTime write FInitialGuardTime default 1;
    property MaxGuardTime:Integer read FMaxGuardTime write FMaxGuardTime default 10;
    property WritePriorityBoost : Integer read FWritePriorityBoost write FWritePriorityBoost default 1000;
    property SleepTime:Integer read FSleepTime write FSleepTime default 5;

    property ShuttingDown :Boolean read FShuttingDown;

    
  end;


procedure Register;

implementation

uses CportTimerUtils, CportModbusUtils; // Modbus Checksum Routines

var
  BlockingDebugFlag:Integer;

(*function TModbusMaster.Hold:Integer;
begin
 if Assigned(FModbusMasterThread) then
    result := FModbusMasterThread.Hold
 else
    result := -1;
end;*)

function TComPortModbusMaster.GetTimingTraceEnable:Boolean;
begin
 if Assigned(FModbusMasterThread) then begin
      result := FModbusMasterThread.TimingTraceEnable
 end else
      result := false;
end;

procedure TComPortModbusMaster.SetTimingTraceEnable(en:Boolean);
begin
 if Assigned(FModbusMasterThread) then begin
      FModbusMasterThread.TimingTraceEnable := en;
 end;
end;


procedure TComPortModbusMaster.BeginHold;
begin
 if Assigned(FModbusMasterThread) then begin
    FModbusMasterThread.BeginHold;
 end;
end;
procedure TComPortModbusMaster.EndHold;
begin
 if Assigned(FModbusMasterThread) then begin
    FModbusMasterThread.EndHold;
 end;
end;

        { Begin a batch of blocking writes. Holds all other polling activities during this time. }
procedure TComPortModbusMaster.BeginBlockingCallBatch;
begin
 if Assigned(FModbusMasterThread) then begin
    FModbusMasterThread.BeginBlockingCallBatch;
 end;
end;

    { End a batch of blocking writes. Resumes normal modbus activity. }
procedure TComPortModbusMaster.EndBlockingCallBatch;
begin
 if Assigned(FModbusMasterThread) then begin
    FModbusMasterThread.EndBlockingCallBatch;
 end;
end;





  { Move all packets offline temporarily to speed performance while equipment
    is powered off. It is up to the application to periodically check all offline
    equipment, or manually bring it back online.
    Returns number of packets taken offline.
    }
function TComPortModbusMaster.Offline(SlaveAddress:Integer;setOffline:Boolean):Integer;
begin
 result := 0;
 if Assigned(FModbusMasterThread) then begin
    result := FModbusMasterThread.SlaveIdSetOffline(SlaveAddress, setOffline);
 end;
end;

{$IFDEF MODBUS_DEBUG}
procedure TComPortModbusMaster.DebugPacketOk;
begin
 if Assigned(FModbusMasterThread) then begin
  FModbusMasterThread.DebugPacketOk;
 end;
end;
{$endif}


constructor TComPortModbusMaster.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
  FInitialGuardTime := 1;
  FMaxGuardTime := 10;
  FSleepTime := 5;

   InitializeSettings;
   FCriticalSection :=
        {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
            TModCriticalSection.Create;
        {$else}
            TCriticalSection.Create;
        {$endif}


  FWritePriorityBoost := 1000;

   FInTimer := FALSE;
   FBlocking := FALSE;



   // XXX: REMOVED: Override the Window Proc so that we might capture the events.
   //? @@@ - nullstr - 2004-03-26 14:57:08 - Use our own internal WindowProc instead

end;

destructor TComPortModbusMaster.Destroy;
begin
   Active := FALSE; // Note that this goes through the property handler which is what we want.
   if (not Assigned(Owner)) then exit;
   if (FNoParentWindow = FALSE) then begin
      if (Assigned(FOldWindowProc) and (Owner.InheritsFrom(TWinControl))) then begin
         TWinControl(Owner).WindowProc := FOldWindowProc;
      end;
   end;
   if Assigned(FModbusMasterThread) then begin
     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(1);
     {$else}
          FCriticalSection.Enter;
     {$endif}

      try
        FModbusMasterThread.Terminate;
        FModbusMasterThread.ModbusMaster := nil;
      finally
        FCriticalSection.Leave;
      end;
      FModbusMasterThread.Free;
      FModbusMasterThread := Nil;
   end;

   FCriticalSection.Free;
   inherited;
end;



(*procedure TModbusMaster.ApplicationMessageHandler(var Msg: TMsg; var Handled: Boolean);
begin
   Handled := TRUE;
   case Msg.message of

      MESSAGE_MODBUS_PACKET_WAITING:
           SinglePacketMessageHandler(Pointer(Msg.LParam));

      MESSAGE_MODBUS_TRACE:
           ThreadTraceHandler(PChar(Pointer(Msg.LParam)));

   else
      Handled := FALSE;
   end;
end;*)

procedure TComPortModbusMaster.InitializeSettings;
begin
   FComPort := Nil;
//   FOriginalComPort := Nil;
   FActive := FALSE;
   FModbusMasterThread := Nil;

   FTotalCRCErrors := 0;
   FTotalTimeoutErrors := 0;
   PacketTimeoutMS := 1750;
   NoResponsePacketTimeoutMS := 300;
   PacketRetryCount := 3;
end;

procedure TComPortModbusMaster.SetNewComPort(FNewComPort : TComPort);
begin
   SetActiveState(FALSE);
   FComPort := FNewComPort;
end;

// SetActiveState is called whenever the active state of the component is changed.
procedure TComPortModbusMaster.SetActiveState(FNewState : Boolean);
var
Timeout:Integer;
begin
   FShuttingDown := not FNewState;

   if FNewState and (not Assigned(FComPort)) then begin
        raise Exception.Create('ComPort not assigned!');
   end;
   if (FNewState <> FActive) then begin
      if ((FNewState = TRUE) and (Assigned(FComPort)=FALSE)) then begin
         // we can't activate when there is no com port.
         exit;
      end;
      FActive := FNewState;
      if (Assigned(FOnActiveStateChange)) then begin
         FOnActiveStateChange(Self);
      end;
      if (FNewState) then begin
         // we are activating...take over the events captain!

         if not Assigned(FModbusMasterThread) then begin
           FModbusMasterThread := TComPortModbusMasterThread.Create(TRUE);
           FModbusMasterThread.FTXLogging := FTXLogging;
           FModbusMasterThread.FRXLogging := FRXLogging;
          end;
         try

            FModbusMasterThread.ModbusMaster := Self;
            FModbusMasterThread.TimeoutRecovery := TimeoutRecovery;
            FModbusMasterThread.InitialGuardTime := InitialGuardTime;
            FModbusMasterThread.SleepTime := SleepTime;
            if (FWritePriorityBoost>=0) then
              FModbusMasterThread.WritePriorityBoost := FWritePriorityBoost;
            FModbusMasterThread.MaxGuardTime     := MaxGuardTime;

            //FModbusMasterThread.Priority := tpLower; // XXX Not recommended!



            FModbusMasterThread.Resume;
         except
     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(2);
     {$else}
          FCriticalSection.Enter;
     {$endif}

            try
              FreeAndNil(FModbusMasterThread);
            finally
              FCriticalSection.Leave; 
            end;
            FActive := FALSE;
         end;
      end else begin
         // we are deactivating...set the events to the way they were.
         if (Assigned(FModbusMasterThread)) then begin


(*     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(10);
     {$else}
          FCriticalSection.Enter;
     {$endif} *)
      FShuttingDown := true;
//      FCriticalSection.Leave;
      Application.ProcessMessages; // WITHOUT THIS, THE THREAD DOESN'T SHUT DOWN!

            FModbusMasterThread.StopReading; // Sets all packets INACTIVE.

      Application.ProcessMessages; // WITHOUT THIS, THE THREAD DOESN'T SHUT DOWN!



            FModbusMasterThread.Terminate;
            Timeout := 0;
            while (FModbusMasterThread.Executing ) do begin
              { loop until thread exits }
               Sleep(100);
               Application.ProcessMessages; // WITHOUT THIS, THE THREAD DOESN'T SHUT DOWN!
               Inc(Timeout);
               if (Timeout > 10) then begin
{$ifdef DEBUG_ASSERTIONS}
                  raise Exception.Create('Modbus.pas: Failed to stop thread.');
{$else}
{$ifdef DEBUGINFO_ON}
                  Trace('Modbus.pas: Failed to stop thread.');
{$endif}
{$endif}
                  break;
               end;
              end;
            end;

            //DeallocateHWnd(FWindow);
            //FWindow:=HWND(0);


     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(3);
     {$else}
          FCriticalSection.Enter;
     {$endif}

            try
              FreeAndNil(FModbusMasterThread);
            finally
              FCriticalSection.Leave;
            end;
            FreeAndNil(FCriticalSection);
            // Create a new one!
            FCriticalSection :=
        {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
            TModCriticalSection.Create;
        {$else}
            TCriticalSection.Create;
        {$endif}


      end;
   end;
end;

{procedure TModbusMaster.SetModbusMode(FNewModbusMode : TModbusMode);
begin
   if (FActive) then begin
      // Although I've debated back and forth, there is no reasonable reason that I am aware of
      // that we would need to change modbus modes "on the fly".
      exit;
   end;
   FModbusMode := FNewModbusMode;
end;}

procedure TComPortModbusMaster.SetPacketTimeoutMS(FNewPacketTimeoutMS : Word);
begin
   if (FNewPacketTimeoutMS < 30) then FNewPacketTimeoutMS := 30;
   FPacketTimeoutMS := FNewPacketTimeoutMS;
   if (Active) then begin
      if (Assigned(FModbusMasterThread)) then begin
         FModbusMasterThread.PacketTimeoutMS := FNewPacketTimeoutMS;
      end;
   end;
end;

procedure TComPortModbusMaster.SetNoResponsePacketTimeoutMS(FNewNoResponsePacketTimeoutMS : Word);
begin
   if (FNewNoResponsePacketTimeoutMS < 100) then FNewNoResponsePacketTimeoutMS := 100;
   FNoResponsePacketTimeoutMS := FNewNoResponsePacketTimeoutMS;
   if (Active) then begin
      if (Assigned(FModbusMasterThread)) then begin
         FModbusMasterThread.NoResponsePacketTimeoutMS := FNoResponsePacketTimeoutMS;
      end;
   end;
end;

procedure TComPortModbusMaster.SetPacketRetryCount(FNewPacketRetryCount : Word);
begin
   FPacketRetryCount := FNewPacketRetryCount;
   if (Active) then begin
      if (Assigned(FModbusMasterThread)) then begin
         FModbusMasterThread.PacketRetryCount := FPacketRetryCount;
      end;
   end;
end;


function TComPortModbusMaster.BlockingRead(
                           SlaveAddress : byte;
                           StartingAddress : Word;
                           ReadCount : Word;
                           var Values : Array of Word;
                           MaximumWaitMS : Word;
                           DebugID : String
                           ) : Boolean;
var
   CharArray : array [0..6] of Byte;
   rawAddress : Word;
   Packet : TModbusPacket;
   ModbusResult : TModbusResult;
   t:Integer;
begin
   result := false;
   Packet := nil;
   if (Active = FALSE) then begin
      exit;
   end;
   if (FShuttingDown) then exit;

   if ((SlaveAddress = 0) or (StartingAddress = 0)) then begin
      exit;
   end;

   {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}

   CharArray[0] := SlaveAddress;
   if ((StartingAddress >= 1) and (StartingAddress < 9999)) then begin
     rawAddress:= StartingAddress- 1;        // Digital Input Coils 0xxxx
     CharArray[1] := constReadCoilStatus;
   end else if ((StartingAddress >= 10001)and(StartingAddress <= 19999)) then begin
     rawAddress:= StartingAddress - 10001; // Discrete Input Status 1xxxx
     CharArray[1] := constReadInputStatus;
   end else if ((StartingAddress >= 30001)and(StartingAddress <= 39999)) then begin
     rawAddress:= StartingAddress - 30001; // Input (Analog) Registers 3xxxx
     CharArray[1] := constReadInputRegisters;
   end else if ((StartingAddress >= 40001)and(StartingAddress <= 49999)) then begin
     rawAddress := StartingAddress- 40001;  // Holding Registers 4xxxxx
     CharArray[1] := constReadHoldingRegisters;
   end else begin
      exit;
   end;

   CharArray[2] := Byte(rawAddress shr 8);
   CharArray[3] := Byte(rawAddress and 255);

   CharArray[4] := Byte(ReadCount shr 8);
   CharArray[5] := (ReadCount and 255);

   {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}

   ModbusResult := _BlockingCall(  Packet, {VAR param: returns actual Packet object here}
                                   {UserCode} 0,
                                   False, {write flag }
                                   SlaveAddress,
                                   StartingAddress,
                                   ReadCount,
                                   CharArray[1], { function code}
                                   PChar(@CharArray[0]),
                                   6, { Length of Standard Read Operations not including CRC bytes}
                                   MaximumWaitMS,
                                   DebugId );

   {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}

   if (ModbusResult = modbusGood) and Assigned(Packet) then begin
      Result := true;


      if (Packet.Status = modbusGood) then begin
          Packet.Interpret;
          result := (Packet.Status = modbusGood);
          // Copy out the values.
          if result then for t := 0 to ReadCount-1 do begin
               Values[t] := Packet.Values[t];
          end;
      end;
      {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}
       // REMOVE FROM LIST AND FREE THIS PACKET.
       if not FModbusMasterThread.RemovePacket(Packet) then begin
            Packet.Free; // DeallocatePacket(FPacket);
            Trace('Modbus.pas: XXX _BlockingCall unable to remove packet from queue');
       end;
      {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}
   end else begin
      Trace('Modbus.pas: BlockingRead failed.');
   end;

  {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}
end;





// BlockingWrite
//
//  Write one or many of any particular modbus type.
//
function TComPortModbusMaster.BlockingWrite(
                                SlaveAddress : Byte;
                                StartingAddress : Word;
                                WriteCount : Word;
                                Values : Array of Word;
                                MaximumWaitMS : Word;
                                DebugId:String ) : Boolean;
var
   CharArray : array [0..255] of Byte;
   Packet    : TModbusPacket;
   ModbusResult : TModbusResult;
   rawAddress:Word;
   Counter:Word;
   RegDataLen,SendDataLength:Integer;
begin
  result := False;
  Packet := nil;

  if (Active = FALSE) then exit;
  if (FShuttingDown) then exit;

  if (StartingAddress>= 40001) and (StartingAddress<= 49999) then begin
     rawAddress := StartingAddress - 40001;
     if WriteCount = 1 then begin
          { Preset Single 4xxxx register }
         CharArray[0] := SlaveAddress;
         CharArray[1] := constPresetSingleRegister;
         CharArray[2] := Byte(rawAddress shr 8);
         CharArray[3] := Byte(rawAddress and 255);
         CharArray[4] := Byte(Values[0] shr 8);
         CharArray[5] := Byte(Values[0] and 255);
         SendDataLength := 6;
     end else begin
          { Preset Multiple 4xxxx register }
         RegDataLen  := WriteCount * 2; {FByteLength}
         CharArray[0] := SlaveAddress;
         CharArray[1] := constPresetMultipleRegisters;
         CharArray[2] := Byte(rawAddress shr 8);
         CharArray[3] := Byte(rawAddress and 255);
         CharArray[4] := Byte(WriteCount shr 8);
         CharArray[5] := Byte(WriteCount and 255);
         CharArray[6] := RegDataLen;
         SendDataLength := 7;
         for Counter := 0 to WriteCount-1 do begin
            CharArray[SendDataLength] := Byte(Values[Counter] shr 8);
            CharArray[SendDataLength+1] := Byte(Values[Counter] and 255);
            SendDataLength := SendDataLength + 2;
            if (SendDataLength>250) then
                exit; // Failed.
         end;


     end;
   end else begin
         raise Exception.Create('BlockingWrite: Support for that memory range not implemented yet.');
   end;

   Assert(SendDataLength<255);
   ModbusResult := _BlockingCall( Packet,
                                   0 {UserCode},
                                   true, {Write Flag}
                                   SlaveAddress,
                                   StartingAddress,
                                   WriteCount, // # of points
                                   CharArray[1], // Command
                                   @CharArray[0], // Buffer
                                   SendDataLength,
                                   MaximumWaitMS,
                                   DebugId );
  if (Active = FALSE) then exit;
  if (FShuttingDown) then exit;

   if (ModbusResult = modbusGood) and Assigned(Packet) then begin
      if (SlaveAddress = 0) then exit; // we're done here...no response is validated.

      {$ifdef MODBUS_DEBUG}Packet.DebugPacketOk; {$endif}

      
      if (Packet.Status = modbusGood) then begin
         // Make sure the Slave ID and Function type come back as expected.
           Packet.Interpret;
           result := (Packet.Status = modbusGood); // Interpretation might CHANGE FPackate status!
      end;
      {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}
      // REMOVE FROM LIST AND FREE THIS PACKET.
      if not FModbusMasterThread.RemovePacket(Packet) then begin
            Packet.Free; // DeallocatePacket(FPacket);

      Trace('Modbus.pas: XXX _BlockingCall unable to remove packet from queue');

      end;

   end;
end;


// _BlockingCall is the foundation of allowing
// the user process to do a call as a blocking
// call rather than a queued event driven call.
function TComPortModbusMaster._BlockingCall( var Packet : TModbusPacket;
                                     UserCode : Word;
                                     WriteFlag:Boolean;
                                     SlaveAddress : Byte;
                                     StartAddress : Word;
                                     ReadCount    : Word;
                                     FunctionCode : Byte;
                                     Data  : PChar;
                                     DataLength :Integer;
                                     MaximumWaitMS : Word;
                                     DebugId       : String
                                   ) : TModbusResult;
var
   WaitTimeoutCount:Integer;
   WaitValue : Cardinal;
   Safety:Integer;
{$ifdef BLOCKINGCALL_DEBUGINFO_ON}
   msgTime,Tick1,Tick2:DWORD;
{$endif}

begin
   Result := modbusNotActive;
   Packet := nil;
{$ifdef BLOCKINGCALL_DEBUGINFO_ON}
   OutputDebugString( PChar('TModbusMaster._BlockingCall: DebugId='+DebugId));
{$endif}

   if (Active = FALSE) then exit;
   if (FShuttingDown) then exit;

   
   {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}

   if (FBlocking) or Assigned(FModbusMasterThread.BlockingPacket) then begin
      Result := modbusBusy;
      exit;
   end;
   FBlocking := TRUE;


   Result := modbusFailed;
   if (FShuttingDown) then exit;


   BlockingDebugFlag :=1;

     // ADDED JUL 9, APPARAENTLY Adding new uninitialized elements to the queue is a bad idea.
     // We don't want modbus thread to fetch the packet while it's still garbage.
    // Always Creates a new packet, adds it to the queue:
     {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}



  {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(2027);
  {$else}
        FCriticalSection.Enter;
  {$endif}



    Packet := FModbusMasterThread.ModifyPacket(0,True, {HighPriority:}True);

    if Length(DebugId)>0 then
        Packet.DebugId := DebugId;

    Packet.Timeout := FModbusMasterThread.PacketTimeoutMS;
    Packet.MaxTimeouts := MaxTimeouts;
    if Packet.BlockingHandle=THandle(nil) then
      Packet.BlockingHandle := CreateEvent(Nil,false,false,Nil);
{$ifdef MODBUS_BLOCKING_DEBUG}
    Packet.DebugFlag := true;
{$endif}

  if MaxTimeouts>1 then
     Packet.Timeout := MaximumWaitMS div MaxTimeouts
  else
     Packet.Timeout := MaximumWaitMS;

  if Packet.Timeout < PacketTimeoutMS then begin
        Packet.Timeout := PacketTimeoutMS;
  end;

    Packet.WriteFlag := WriteFlag;
    Packet.FunctionCode := FunctionCode; // bugfix.
    Packet.PollingInterval := 0;
    Packet.PollingNextTime := GetTickCount; // NOW.
    Packet.SlaveAddress := SlaveAddress;
    Packet.StartingAddress := StartAddress;
    Packet.ReadLength := ReadCount;
    Packet.SetSendData( Data,DataLength, true {crc append} ); // calculates CRC
    //XXX Packet.Active := true; // DON'T SET ACTIVE, THIS WOULD CAUSE POLLING!

    if (FShuttingDown) then exit;

        // when the thread sees that FBlocking is true, it sets

     // Only one can be here!
    {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}
    FModbusMasterThread.BlockingPacket := Packet;


    // NEW: Wait for completion of current activity:


    {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}

     FCriticalSection.Leave;


     { now we put the foreground thread to sleep, awaiting the background thread to complete. }

     Sleep(FSleepTime);  { ensure foreground goes to sleep for a bit. }
     
     
      WaitValue := $FFFFFFFF;
      Safety := 0; 
      WaitTimeoutCount := 0;
      while (TRUE) do begin

         {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}


         WaitValue := WaitForSingleObject(  Packet.BlockingHandle,
                                           {dwMilliseconds=} (MaximumWaitMS div 10) );


         if (WaitValue = $FFFFFFFF) then
              break;  // Error waiting.

         if (WaitValue = WAIT_TIMEOUT) then begin
               Inc(WaitTimeoutCount);
{$ifdef BLOCKINGCALL_DEBUGINFO_ON}
               OutputDebugString( PChar('Application.ProcessMessages called '+IntToStr(WaitTimeoutCount)+' times.' ) );
               Tick1 := GetTickCount;
{$endif}


               Application.ProcessMessages; // If you don't call this, you can deadlock, if you call this, you can deadlock. Nice eh?
{$ifdef BLOCKINGCALL_DEBUGINFO_ON}
               Tick2 := GetTickCount;
               msgTime := TimerElapsed(Tick1,Tick2);
               if msgTime>100 then begin
                 OutputDebugString( PChar('TModbusMaster._BlockingCall Application.ProcessMessages took '+IntToStr(msgTime)+' ms') );
               end;
{$endif}

               if (WaitTimeoutCount>=10) then
                    break;  // failed.
         end;
         if (WaitValue = WAIT_OBJECT_0) then
                  break; // Semaphore means that the thread signalled we're done

         //if WaitValue = (WAIT_OBJECT_0+1) then
         //     Trace('_BlockingCall: XXX MsgWaitForMultipleObjects returned unexpected WAIT_OBJECT_0+1');

         // XXX EVIL NASTINESS: COULD IT BE THIS?
         {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}
          //Application.ProcessMessages;
         {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}
         Inc(Safety);
         if (Safety>1000) then begin
            Trace('_BlockingCall: XXX endless-looping-safety limit reached. Severe fault?');
            break;
         end;

      end;

   {$ifdef MODBUS_DEBUG}Packet.DebugPacketOk; {$endif}

    if  (WaitValue = WAIT_OBJECT_0) then begin
       Result := modbusGood; // Note that this ONLY applies to the fact that we successfully sent the packet!
    end else begin
    {$ifdef BLOCKINGCALL_DEBUGINFO_ON}
       OutputDebugString('Modbus.pas: Timeout waiting for _BlockingCall completion. Serious Fault!');
    {$endif}
     Result := modbusTimeout;
    end;

   FBlocking := FALSE;
   BlockingDebugFlag :=0;

   {$ifdef MODBUS_DEBUG}DebugPacketOk; {$endif}

end;

{ non blocking (event driven) read for all register types, returns userid }
function TComPortModbusMaster.Read(
            UserCode : Word;
            DebugId  : String; {NEW!}
            SlaveAddress : byte;
            StartingAddress : Word;
            ReadCount : Word;
            PollingRate: DWORD;
            Timeouts:Integer;            
            TraceFlag:Boolean;
            OnReadOk:TModbusSuccessNotification = nil
          ) : Boolean; {ok=true, failed=false}
var
   CharArray : array [1..6] of Byte;
   rawAddress : Word;
   Packet    : TModbusPacket;
begin
   Result := false; // modbusNotActive;
   if (Active = FALSE) then begin
      raise Exception.Create('Modbus not active. Can''t read. Set TModbusMaster.Active = true first.');
      exit;
   end;
   if (FShuttingDown) then exit;

   if ((SlaveAddress = 0) or (UserCode = 0) or (StartingAddress = 0)) then begin
      exit;
   end;
   
   CharArray[1] := SlaveAddress;
   if ((StartingAddress >= 1) and (StartingAddress < 9999)) then begin
     rawAddress:= StartingAddress- 1;        // Digital Input Coils 0xxxx
     CharArray[2] := constReadCoilStatus;
   end else if ((StartingAddress >= 10001)and(StartingAddress <= 19999)) then begin
     rawAddress:= StartingAddress - 10001; // Discrete Input Status 1xxxx
     CharArray[2] := constReadInputStatus;
   end else if ((StartingAddress >= 30001)and(StartingAddress <= 39999)) then begin
     rawAddress:= StartingAddress - 30001; // Input (Analog) Registers 3xxxx
     CharArray[2] := constReadInputRegisters;
   end else if ((StartingAddress >= 40001)and(StartingAddress <= 49999)) then begin
     rawAddress := StartingAddress- 40001;  // Holding Registers 4xxxxx
     CharArray[2] := constReadHoldingRegisters;
   end else begin
      exit;
   end;

   CharArray[3] := Byte(rawAddress shr 8);
   CharArray[4] := Byte(rawAddress and 255);
   CharArray[5] := Byte(ReadCount shr 8);
   CharArray[6] := (ReadCount and 255);



     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(7);
     {$else}
          FCriticalSection.Enter;
     {$endif}

   try

    Packet := FModbusMasterThread.ModifyPacket(UserCode,True, {HighPriority=}False);

    if Length(DebugId)>0 then
        Packet.DebugId := DebugId;
      Packet.Timeout := FModbusMasterThread.PacketTimeoutMS;
      Packet.MaxTimeouts := Timeouts; // CUSTOM PARAMETER.
      Packet.WriteFlag := false;
      Packet.BlockingHandle := 0;
      Packet.FunctionCode := CharArray[2];
      Packet.PollingInterval := PollingRate;
      Packet.PollingNextTime := GetTickCount;
      Packet.SlaveAddress := SlaveAddress;
      Packet.StartingAddress := StartingAddress;
      Packet.ReadLength := ReadCount;
      Packet.OnSuccessfulRead := OnReadOk;
      Packet.SetSendData(@(CharArray[1]),6, true {appends crc} );
      
      //FPacket.Values[0] := Value;
      Packet.Active := true; // this must be LAST because it lets the background

   finally
    FCriticalSection.Leave;
   end;

   result := true;



end;



(*procedure TModbusMaster._DebugCheckPacketUserCodesSequencing;
begin
  FModbusMasterThread._DebugCheckPacketUserCodesSequencing;
end;*)


function TComPortModbusMaster.CustomCommandSequence(var UserCode:Word; Commands:TStrings; AppendCrc:Boolean; PacketTimeoutMS:DWORD; TraceFlag:Boolean ) :Boolean;
var
 t:Integer;

begin
  result := false;
  for t := 0 to Commands.Count-1 do begin
       (*if Length(Commands[t]) <> 8 then begin
          Trace('Modbus.pas: unusual command in TModbusMaster.CustomCommandSequence');
       end;*)
      result := CustomCommand(UserCode, Commands[t], AppendCrc,PacketTimeoutMS,TraceFlag );
      if (not result) then begin
          Trace('CustomCommandSequence : Failure on command '+IntToStr(t+1)+' of '+IntToStr(Commands.Count));
          break;
      end;
      Inc(UserCode);
  end;
end;

function TComPortModbusMaster.CustomCommand(UserCode:Word; Command:String; AppendCrc:Boolean; PacketTimeoutMS:DWORD; TraceFlag:Boolean ) :Boolean;
var
   SendData : array of Byte;
   t:Integer;
//   rawAddress,Value :Word;
   Packet:TModbusPacket;
   SendDataLength:Integer;
begin
   Result := false;
   if (Active = FALSE) then begin
       exit;
   end;

   if (UserCode = 0) then begin
      exit;
   end;
   SendDataLength := Length(Command);

   SetLength(SendData,SendDataLength+1);
   for t := 0 to SendDataLength-1 do begin
      SendData[t] := Ord(Command[t+1]);
   end;
   SendData[SendDataLength] := $FF; // MARKER.

     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(8);
     {$else}
          FCriticalSection.Enter;
     {$endif}

    Packet := FModbusMasterThread.ModifyPacket( UserCode,True, {HighPriority=}True);

      Packet.Timeout := PacketTimeoutMS;
      Packet.MaxTimeouts := MaxTimeouts;
      Packet.WriteFlag := false; // NOTE: Custom commands might actually be a write, but they aren't handled internally the same way as builtin writes.
      Packet.BlockingHandle := 0;
      Packet.CustomFlag := true; // NEW. Means, ignore error, ignore no-response, ignore timeout, just continue.
      Packet.FunctionCode := SendData[1];
      Packet.PollingInterval := 0;
      Packet.PollingNextTime := GetTickCount;
      Packet.SlaveAddress := SendData[0];
      Packet.StartingAddress := 0; // NONE.
      Packet.ReadLength := 0; // NO RESPONSE EXPECTED OR REQUIRED.
      Packet.TraceFlag := TraceFlag; // Output trace messages for this packet so we can debug it?
      Packet.SetSendData( @SendData[0], SendDataLength, AppendCrc );

      // Confirm write of values by storing expected values in Values:

      Packet.Active := true; // this must be LAST because it lets the background run!
      // restart scanning:
      //FModbusMasterThread.PendingHighPriority := FModbusMasterThread.PendingHighPriority+1;
    FCriticalSection.Leave;
    
    result := true;
end;


// formerly PresetSingleRegister now Write.
// Note that the values in the Values array must be in valid WORD range ($0000..$FFFF)
function TComPortModbusMaster.Write(   UserCode : Word;
                                DebugId  : String; {NEW!}
                                SlaveAddress : Byte;
                                StartingAddress : Word;
                                WriteCount : Word;
                                Timeouts:Integer;
                                TraceFlag:Boolean;
                                Values:Array of Word;
                                OnWriteOk:TModbusSuccessNotification=nil
                                 ): Boolean;
var
   SendData : array of Byte;
   rawAddress,Value :Word;
   Packet:TModbusPacket;
   BitCount,ByteOffset,Counter,SendDataLength,RegDataLen :Integer;
begin
   Result := false;
   if (Active = FALSE) then begin
      exit;
   end;

   if (UserCode = 0) then begin
      exit;
   end;
   if (     (StartingAddress>= 40001)
        and (StartingAddress <= 49999)
      )
       then begin
           rawAddress := StartingAddress - 40001;
       if (WriteCount=1) then begin
          { Preset Single 4xxxx register }
              Value := Values[0];
              SetLength(SendData,6);
              SendData[0] := SlaveAddress;
              SendData[1] := constPresetSingleRegister;
              SendData[2] := Byte( rawAddress shr 8);
              SendData[3] := ( rawAddress  and 255);
              SendData[4] := Byte(Value shr 8);
              SendData[5] := (Value and 255);
              SendDataLength := 6;
       end else begin
          { Preset Multiple 4xxxx register }
                 RegDataLen  := WriteCount * 2; {FByteLength}
                 SetLength(SendData,RegDataLen  + 7);
                 SendData[0] := SlaveAddress;
                 SendData[1] := constPresetMultipleRegisters;
                 SendData[2] := Byte(rawAddress shr 8);
                 SendData[3] := Byte(rawAddress and 255);
                 SendData[4] := Byte(WriteCount shr 8);
                 SendData[5] := Byte(WriteCount and 255);
                 SendData[6] := RegDataLen;
                 SendDataLength := 7;
                 for Counter := 0 to WriteCount-1 do begin
                    SendData[SendDataLength] := Byte(Values[Counter] shr 8);
                    SendData[SendDataLength+1] := Byte(Values[Counter] and 255);
                    SendDataLength := SendDataLength + 2;
                 end;
       end;
     end else if ((StartingAddress >=1 ) and (StartingAddress < 9999)) then begin
           rawAddress := StartingAddress - 1;
       if (WriteCount=1) then begin
          { Preset Single 0xxxx Coil  }
              Value := Values[0];
              SetLength(SendData,6);
              SendData[0] := SlaveAddress;
              SendData[1] := constForceSingleCoil;
              SendData[2] := Byte( rawAddress shr 8);
              SendData[3] := ( rawAddress  and 255);
              if (Value>0) then // is Value logically True?
                SendData[4] := $FF
              else // or false:
                SendData[4] := 0;
              SendData[5] := 0;
              SendDataLength := 6;

       end else begin
                 { Force Multiple 0xxxx Coils }
                 RegDataLen  := (WriteCount+7) div 8; // Number of bytes to hold this many bits.
                 SetLength(SendData,RegDataLen  + 7);
                 SendData[0] := SlaveAddress;
                 SendData[1] := constForceMultipleCoils;
                 SendData[2] := Byte(rawAddress shr 8);
                 SendData[3] := Byte(rawAddress and 255);
                 SendData[4] := Byte(WriteCount shr 8);
                 SendData[5] := Byte(WriteCount and 255);
                 SendData[6] := RegDataLen;
                 SendDataLength := 7+RegDataLen;
                 for Counter := 7 to SendDataLength-1 do begin
                    SendData[Counter] := 0;
                 end;
                 // now set the bits that are true:
                 BitCount := 0;
                 ByteOffset := 7;
                 for Counter := 0 to WriteCount-1 do begin
                    if (Values[Counter]>0) then begin
                       SendData[ByteOffset] := SendData[ByteOffset] or (1 shl BitCount);
                    end;
                    Inc(BitCount);
                    if (BitCount = 8) then begin
                       Inc(ByteOffset);
                       BitCount := 0;
                    end;
                 end;
       end;
     end else begin
         raise ERangeError.Create('Invalid modbus address range in Write');
     end;

     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(9);
     {$else}
          FCriticalSection.Enter;
     {$endif}

    try
      Packet := FModbusMasterThread.ModifyPacket( UserCode,True, {HighPriority=}True);

      if Length(DebugId)>0 then
        Packet.DebugId := DebugId;
        
      Packet.Timeout := FModbusMasterThread.PacketTimeoutMS;
      Packet.MaxTimeouts := Timeouts;
      Packet.WriteFlag := true;
      Packet.SetSendData( @SendData[0], SendDataLength, true {appends crc} );
      Packet.BlockingHandle := 0;
      Packet.FunctionCode := SendData[1];
      Packet.PollingInterval := 0;
      Packet.PollingNextTime := GetTickCount; // NOW.
      Packet.SlaveAddress := SlaveAddress;
      Packet.StartingAddress := StartingAddress; // NEW.
      Packet.ReadLength := WriteCount;
      // Confirm write of values by storing expected values in Values:
      for Counter := 0 to WriteCount-1 do begin
         Packet.Values[Counter] := Values[Counter];
      end;
      Packet.OnSuccessfulWrite := OnWriteOk;
    Packet.Active := true; // this must be LAST because it lets the background
    //FModbusMasterThread.PendingHighPriority := FModbusMasterThread.PendingHighPriority+1;
    finally
       FCriticalSection.Leave;
    end;
    result := true;

end;


// statistical stuff:

function TComPortModbusMaster.GetTotalCRCErrors : Cardinal;
begin
   Result := FTotalCRCErrors;
end;

procedure TComPortModbusMaster.SetTotalCRCErrors(TotalCRCErrors : Cardinal);
begin
   FTotalCRCErrors := TotalCRCErrors;
end;

function TComPortModbusMaster.GetExceptions:Integer;
begin
  if Assigned(FModbusMasterThread) then
      result := FModbusMasterThread.Exceptions
  else
      result := 0;
end;
function TComPortModbusMaster.GetTotalTimeoutErrors : Cardinal;
begin
   Result := FTotalTimeoutErrors;
end;

procedure TComPortModbusMaster.SetTotalTimeoutErrors(TotalTimeoutErrors : Cardinal);
begin
   FTotalTimeoutErrors := TotalTimeoutErrors;
end;

(*procedure TModbusMaster.SetRealConnectionSpeed(NewRealConnectionSpeed : Cardinal);
begin
   if (Active = FALSE) then begin
      FRealConnectionSpeed := NewRealConnectionSpeed;
   end;
end;*)

function TComPortModbusMaster.GetTotalBytesReceived : Cardinal;
begin
   Result := 0;
   if (Active = TRUE) then begin
      if (Assigned(FModbusMasterThread)) then begin
         Result := FModbusMasterThread.TotalBytesReceived;
      end;
   end;
end;

function TComPortModbusMaster.GetTotalBytesSent : Cardinal;
begin
   Result := 0;
   if (Active = TRUE) then begin
      if (Assigned(FModbusMasterThread)) then begin
         Result := FModbusMasterThread.TotalBytesSent;
      end;
   end;
end;


// trace handling


// SinglePacketMessageHandler
//
// message receive handler:
//    incoming messages from thread.
//
procedure TComPortModbusMaster.SinglePacketMessageHandler(PacketPointer : pointer);
label timer_handler_again, crc_error_again;
var
   FPacket : TModbusPacket;
begin
   if not FActive then exit;

   if (not Assigned(PacketPointer)) then begin
      raise Exception.Create('Invalid Message received in SinglePacketMessageHandler');
      exit;
   end;
   FPacket := TModbusPacket(PacketPointer);
   if ((FPacket.StartingAddress < 1) or (FPacket.StartingAddress > 49999)) then begin
      if not (FPacket.CustomFlag and (FPacket.StartingAddress=0))then
         raise Exception.Create('Invalid Message received in SinglePacketMessageHandler');
   end;


   if (FPacket.Status <> modbusGood) then begin
      if (Assigned(OnPacketFailed)) then begin
            // Previously was only notifying ONCE to avoid lots of noise.
            // Changed.
           //if not FPacket.FailNotifyFlag then begin
             //FPacket.FailNotifyFlag  := true;
             OnPacketFailed(Self,FPacket);
           //end;
      end;
   end else begin
      if FPacket.CustomFlag then begin
           if Assigned(OnCustomResponse) then begin
               OnCustomResponse(Self,FPacket);
           end;
      end else if FPacket.Interpret then begin
            if FPacket.IsReadResponse then begin
            if Assigned(FPacket.OnSuccessfulRead) then begin
                FPacket.OnSuccessfulRead(Self,FPacket);
            end else if (Assigned(OnSuccessfulRead)) then begin
               //FPacket.FailNotifyFlag  := false;
               OnSuccessfulRead(Self,FPacket);
            end;
            end else begin
            if Assigned(FPacket.OnSuccessfulWrite) then begin
                FPacket.OnSuccessfulWrite(Self,FPacket);
            end else if (Assigned(OnSuccessfulWrite)) then begin
               //FPacket.FailNotifyFlag  := false;
               OnSuccessfulWrite(Self,FPacket);
            end;

            end;

      end else begin
              if (Assigned(FOnPacketFailedEvent)) then begin
                 //if not FPacket.FailNotifyFlag then begin
                   //FPacket.FailNotifyFlag  := true;
                   OnPacketFailed(Self,FPacket);
                 //end;
              end;
      end;

   end;
   FPacket.NotificationPending := false;
   //DeallocatePacket(FPacket);
end;

procedure TComPortModbusMaster.StopReading; // stops all polling activity.
begin
 if Assigned(FOnTraceEvent) then begin
      FOnTraceEvent(Self, 'ModbusMaster.StopReading');
 end;
 if FActive then
  SetActiveState(false);
end;

// Stop polling on one item (by user code)
procedure TComPortModbusMaster.StopReadingByUserCode( UserCode:Integer );
begin
    if Assigned(FModbusMasterThread) then
      FModbusMasterThread.StopReadingByUserCode(UserCode);
end;

function TComPortModbusMaster.IsUserCodeActive( UserCode:Integer ):Boolean;
begin
    if Assigned(FModbusMasterThread) then
      result := FModbusMasterThread.IsUserCodeActive( UserCode)
    else
      result := false;
end;


procedure TComPortModbusMaster.TerminateThread;
begin
  FModbusMasterThread.Terminate;
end;


// Logging is a property of the thread, so this
// next bit abstracts it so it can be a
// design time property of the modbus component: 

function TComPortModbusMaster.GetTXLogging:Boolean;
begin
  if Assigned(FModbusMasterThread) then
    result := FModbusMasterThread.FTXLogging
  else
    result := FTXLogging;
end;

function TComPortModbusMaster.GetRXLogging:Boolean;
begin
  if Assigned(FModbusMasterThread) then
    result := FModbusMasterThread.FRXLogging
  else
    result := FRXLogging;
end;

procedure TComPortModbusMaster.SetTXLogging(newValue:Boolean);
begin
  if Assigned(FModbusMasterThread) then
    FModbusMasterThread.FTXLogging := newValue;

   FTxLogging := newValue;
end;

procedure TComPortModbusMaster.SetRXLogging(newValue:Boolean);
begin
  if Assigned(FModbusMasterThread) then
     FModbusMasterThread.FRxLogging := newValue;

   FRxLogging := newValue;
end;


// Register:
//
// Design Time Component Registration:
// Register this component so it appears in the
// Component pallete, on the 'CPortLib' tab.
//
procedure Register;
begin
  RegisterComponents('CPortLib', [TComPortModbusMaster]);
end;



procedure TComPortModbusMaster.Trace(msg:String);
begin
   if Assigned(FOnTraceEvent) then begin
        FOnTraceEvent(Self, msg );
   end;
{$ifdef MODBUS_DEBUGINFO_ON}
    OutputDebugString( PChar('modbus: '+msg) );
{$endif}
end;

// A TThread.Synchronize method to be invoked by the Modbus Thread only!
// June 04 - (XXX Testing without Synchronize)
procedure TComPortModbusMaster._ThreadTrace;
begin
  Assert(Assigned(Self));
  if not Assigned(FModbusMasterThread) then begin
      Trace('Modbus.pas: TModbusMaster._ThreadTrace: FModbusMasterThread=nil');
      exit;
  end;

   if Assigned(FOnTraceEvent) then begin
        FOnTraceEvent(Self, FModbusMasterThread.TraceMsg );
   end;
end;

procedure TComPortModbusMaster._ThreadTxEvent;
begin
  Assert(Assigned(Self));
  Assert(Assigned(FModbusMasterThread));
   if Assigned(FOnTxEvent) then begin
       FOnTxEvent(Self, FModbusMasterThread.ActivePacket );
   end;
end;

procedure TComPortModbusMaster._ThreadPacketWaitingEvent;
begin
  Assert(Assigned(Self));
  Assert(Assigned(FModbusMasterThread));
    SinglePacketMessageHandler(FModbusMasterThread.ActivePacket);
end;


{Diagnostic/Debug feature - PacketWatchdog checks if packets are being sent.}
function TComPortModbusMaster.PacketWatchdog:Boolean;
var
 t:Integer;
 pkt:TModbusPacket;
 elapse,tick:DWORD;
begin
  Assert(Assigned(FModbusMasterThread));
  Assert(Assigned(FModbusMasterThread.PacketList)); 
     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(20);
     {$else}
          FCriticalSection.Enter;
     {$endif}
     try
    result := true;
    tick := GetTickCount;
     for t := 0 to FModbusMasterThread.PacketList.Count-1 do begin
        pkt := FModbusMasterThread.PacketList[t];
        if pkt.PollingInterval>0 then begin
          elapse := TimerElapsed( pkt.PollingOkLast, tick );
          if ( elapse > (50 *pkt.PollingInterval ) ) then begin
              pkt.ExceptionCount := pkt.ExceptionCount +1;
              pkt.PollingOkLast := tick;
              result := false;
          end;
        end;
    end;

    finally
    FCriticalSection.Leave;
    end;
end;

initialization
  BlockingDebugFlag := 0;

end.
