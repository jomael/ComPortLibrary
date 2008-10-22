unit CportModbusThread;
{$R-}
{$Q-}
//----------------------------------------------------------------------------
// ModbusThread.pas
//
//  TComPortModbusMasterThread object.
//
//  Rev 4.1 (May 25, 2004) by Warren Postma
// (C) 2003,2004 Warren Postma.
// Based partly on an original version by Dennis Forbes, with
// contributions from Matthew Skelton.
//
//
// Version 4.1 Changes:
//     Removed Window Handle and PostMessage functionality,
//     and implmeneted using TThread.Synchronize instead.
//
//----------------------------------------------------------------------------
//
//
// The Modbus master serial communications happens
// in this background thread (TComPortModbusMasterThread.Execute method).
//
// The interface between this thread and the component uses a queue of
// packets waiting to be sent, and some custom window messages posted
// from the queue to the foreground.
//
// See ModbusPacket.pas for the packet object.
//
// RS232/RS485 Serial Communications feature relies
// on CPORT
//----------------------------------------------------------------------------

interface

uses Windows,Messages, Classes,SysUtils, SyncObjs, CportModbusPacket, CPort;



const

    

        MAX_MODBUS_READ_BLOCK=255;
{ User Defined Win32 API WM_* Message Types }
//MESSAGE_MODBUS_PACKET_WAITING = WM_APP + $1027; // Could be Ok or Error. Check contents within!
//MESSAGE_MODBUS_MASTER_CRC_ERROR =MESSAGE_MODBUS_PACKET_WAITING+1;
//MESSAGE_MODBUS_MASTER_TIMEOUT_ERROR = MESSAGE_MODBUS_MASTER_CRC_ERROR + 1;
//MESSAGE_MODBUS_TRACE = MESSAGE_MODBUS_PACKET_WAITING +1;
//MESSAGE_MODBUS_TX = MESSAGE_MODBUS_PACKET_WAITING +2;

MAX_MODBUS_QUEUE_SIZE = 32768; // Sanity limit on packets in the queue
MAX_CRC_ERROR_LIST_ITEMS = 500;
MAX_TIMEOUT_ERROR_LIST_ITEMS = 500;


type

  TComPortModbusMasterThreadException = class (Exception);


  TTracePacketRec = record
      Ticks:LongWord;
      msg:String;
  end;

{$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
   TModCriticalSection = class
         FSection:TCriticalSection;
         FEntrycode,FLastEntryCode : Integer;
         //NEW:
         FLastLeaving : Array[0..8] of Integer;
         FLastLeavingIndex:Integer;
    public
      constructor Create;
      destructor Destroy; override;
      procedure SafeEnter(entrycode:Integer); {Enter}
      procedure Leave;
      property EntryCode :Integer read FEntryCode;
      property LastEntryCode:Integer read FLastEntryCode;
   end;
{$endif}



  // TComPortModbusMasterThread is the worker thread that communicates with
  // the PLC in a thread.  This thread is handled by the TModbusMaster
  // class.  The thread is created when the component is activated and it
  // is destroyed when the component is deactivated.
  TComPortModbusMasterThread = class(TThread)
protected { these variables are used in the interface with the owner object }
    { Private declarations }
{$ifdef DEBUGINFO_ON}
    FIdleThreadStateCounter : Integer;
{$endif}

    FAssertNoSync : Boolean; // Deadlock protection - Can't call synchronize
                             // when main thread is blocking waiting
                             // for the background thread!
                             // If set to false, calls to
                             //  Assert(FAssertNoSync) before
                             // calling TThread.Synchronize will raise
                             // a debugging-exception, helping us
                             // to debug deadlock conditions.

    FSleepTime:Integer; // Thread sleep-while-waiting time
                        // Tweak to balance thread responsiveness
                        // versus CPU usage.

    FExecuting:Boolean; // Set true if the function Execute is running, false if not.
    FTraceMsg:String;

    FBlockingPacket:TModbusPacket; // Main object will request that we send a packet right now!


    FPacketListValid : Boolean; // Is the main thread allowed to FPacketList
    FExceptions:Integer; // com port exceptions
    FTimingTraceEnable :Boolean; // Timing trace messages. Very verbose, helps with obscure problems only!
    FCriticalSection :
        {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
            TModCriticalSection;
        {$else}
            TCriticalSection;
        {$endif}

    FPacketRetryCount : Word; // How many retries per packet. FPacketRetryCount
    FPacketTimeoutMS : Word; // How long to let a packet wait.
    FNoResponsePacketTimeoutMS : Word; // How long with absolutely no response to let a packet wait.

    FTimeoutRecovery:Integer;
    //FZeroStr:String;
    //FPendingHighPriority:Integer; // when high priorioty items are activated in the list, we increment this.

    FInitialGuardTime : Integer; // what is the initial value for guard time?
    FMaxGuardTime : Integer; // what is the highest value for guard time?
    //FWaitForSingleObjectTimeouts:DWORD;

    {timing debug helpers}
    FLastTxTimer,FLastRxTimer:DWORD;
    FLastTxUserCode,FLastRxUserCode:DWORD;

    FModbusMaster : TObject; // Reverse reference to the owning TModbusMaster object.
    FComPort : TComPort;
//    FComPortDataAvailableEvent: THandle; // {XXX NEW CUSTOM FEATURE I ADDED TO ASYNC PRO OBJECTS XXX}
    //FModbusMode : TModbusMode;

    FPacketCounter : Word;
    FActivePacketTimerTick : DWORD; // BLAH BLAH. I hate this.
    FOutgoingPacketQueue : Integer; // Used to track the number of packets to send.

    FConnectionSpeed : Cardinal; // July 5th, 1999


    // FUserCodePacketFlush is used, like the preceeding flush, to indicate to the thread if it should
    // dispose of a particular user code.  Useful when the user flushes out all of a particular user code.
    FUserCodePacketFlush : Word;
    

    FTotalBytesSent : LongWord;
    FTotalBytesReceived : LongWord;

    // These lists are the most important aspect of this component.  They are the method by which
    // the holding component holds this thread component.
    FPacketList : TList;
//    FPacketTurboList : TList; // Packets which must be polled more than once per

    FPacketSchedule: Array of TModbusPacket; 


      // A small delay is inserted before transmissions to
      // nodes that have had timeouts before. This is a self-tuning mechanism
      // that ensures a certain amount of line dead-time before the next communications
      // attempt.
    FGuardTime:Array[0..255] of DWORD;

    FWritePriorityBoost:Integer;

    // These are variables are NOT to be accessed by anything other than the thread main loop:
  private
     FTickNow      : DWORD;
     FActivePacket : TModbusPacket; // Current packet in use.
     FReceiveBuffer : Array [0..constIncomingBlockSize] of Char;
     FWaitingForPacket : Boolean;
     FSuccessfullyReceivedPacket : Boolean;
     FCalculatedCRC : Word;
     FBytesRead : Integer; // Number of bytes read by last call to TComPort.ReadXxx
     FSendStrPtr: PChar; // formerly FValue which was duplicated.
     //FOldSemaphoreCount : Integer;

  private

    FHold : Integer; // Allows main thread to put this thread temporarily on hold in order to set up a sequence without
                    // creating race conditions.

    FBlockingCallBatch : Integer; // When writing a bunch of blocking writes, we must pause all background activity or we'll have problems.                    

// function InputCount:Integer; // WARNING: This is unstable. DO NOT CALL TComPort.InputCount, if you use USB-to-serial adaptor devices. -- WPOSTMA.

        { Execute Helper Methods }
        procedure InitThreadVars;
        procedure CleanupThreadVars; // undo whatever we did in InitTHreadVars.
        procedure IdleThreadState;
        function  _RetrievePacket:Boolean;
        function  HoldThenRetrievePacket:Boolean;

        procedure SendPacketState;
        procedure ReadResponseState;
        procedure TimeoutHandler;
        function  RtuExceptionCheck:Boolean;
        function  RtuExpectedLengthCheck:Boolean; // Enough bytes received? 
        function  RtuResponseCheck:Boolean;
        function  RtuCrcCheck:Boolean;

        procedure Flush;

        { internal queue management helper functions }
        function AddPacket(aPacket:TModbusPacket): Boolean;
        function AddHighPriorityPacket(aPacket:TModbusPacket): Boolean;

        procedure TimingTrace(msg:String);

        procedure TracePacketCircularBufferSetLength( bufferLength :Integer );
        function  TracePacketCircularBufferGetLength:Integer;

  public
    ThreadFault    : Boolean;
    ThreadFaultStr : String;

    FTracePackets  :Array of TTracePacketRec;
    FTracePacketIndex:Integer;
    FTracePacketPendingDump:Integer;
        // If FTracePacketPendingDump>0 then a dump of the circular buffer is
        // pending. If you set FTracePacketPendingDump to 2 and the
        // circular buffer length is 10 ( Length(FTracePackets) ) then you
        // would get 8 prior and next two 2, trace messages, giving you
        // some context to work with when debugging the problem.

    FTxEventEnable :Boolean; // Do we bother doing a Synchronize to the main thread just to tell them of each TX?
    FTXLogging,FRXLogging:Boolean;
    

    procedure BeginHold; { totally pause ALL communications (blocking and non-blocking) }
    procedure EndHold;

    { Begin a batch of blocking writes. Holds all other polling activities during this time. }
    procedure BeginBlockingCallBatch;
    { End a batch of blocking writes. Resumes normal modbus activity. }
    procedure EndBlockingCallBatch;


    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    constructor Create(CreateSuspended: Boolean);
    destructor Destroy;  override;

    function SlaveIdSetOffline(SlaveAddress:Integer;setOffline:Boolean):Integer;{returns count}

    function QueryUserCodeCount(UserCode : Word) : Word;

    function RemovePacket(Packet : TModbusPacket) : Boolean; // called by _BlockingCall

    procedure TracePacket( prefix:String; Data:PChar; DataLength:Word); // debug routine.

    procedure TracePacketCircularBufferDump; // debug routine.

    procedure Trace( msg:String); // diagnostic output sender. WARNING: Never call this INSIDE a critical section!


    // new use ModifyPacket instead of UpdatePacket, then set packet.Active := true
    // to start the background thread using it!
    function ModifyPacket(UserCode:Word;Deactivate,HighPriority:Boolean):TModbusPacket;

    procedure SetModbusMaster(master:TObject);


    //---DEBUG Property:
    property Exceptions:Integer read FExceptions write FExceptions; // com port exceptions?


    procedure StopReading; // stops all polling activity.

    procedure StopReadingByUserCode(UserCode:Integer);
    function IsUserCodeActive( UserCode:Integer ):Boolean;


    //DEBUG CODE:
    {$ifdef MODBUS_DEBUG}procedure DebugPacketOk;{$endif}

    property TraceMsg:String read FTraceMsg;
    property ActivePacket : TModbusPacket read FActivePacket; // Current packet in use.

    // TModbusThread._BlockingCall sets this:
    property BlockingPacket:TModbusPacket read FBlockingPacket write FBlockingPacket; // We are requesting control so we can process a blocking call in the thread.
    property AssertNoSync : Boolean read FAssertNoSync write FAssertNoSync; // Deadlock protection - Can't call synchronize when main thread is blocking waiting for background thread!


  protected
    procedure SetComPort(aComPort:TComPort);

    procedure Timeouts;    // NEW! Setup Win32 SDK COMMTIMEOUTS:

    procedure Execute; override;


  published


    property Executing : Boolean read FExecuting;

    property ModbusMaster : TObject read FModbusMaster write SetModbusMaster;
    property ApdComPort : TComPort read FComPort write SetComPort;

    property TotalBytesSent : LongWord read FTotalBytesSent;
    property TotalBytesReceived : LongWord read FTotalBytesReceived;

//    property SerialTransmissionMode : TModbusMode read FModbusMode write FModbusMode;
    property PacketRetryCount : Word read FPacketRetryCount write FPacketRetryCount;
    property PacketTimeoutMS : Word read FPacketTimeoutMS write FPacketTimeoutMS;
    property NoResponsePacketTimeoutMS : Word read FNoResponsePacketTimeoutMS write FNoResponsePacketTimeoutMS;

    property ConnectionSpeed : Cardinal read FConnectionSpeed write FConnectionSpeed;

    property PacketList : TList read FPacketList write FPacketList;
    //property PendingHighPriority:Integer read FPendingHighPriority write FPendingHighPriority;

    property TimeoutRecovery:Integer read FTimeoutRecovery write FTimeoutRecovery;


    property TimingTraceEnable:Boolean read FTimingTraceEnable write FTimingTraceEnable;
    property InitialGuardTime : Integer read FInitialGuardTime  write FInitialGuardTime; // what is the initial value for guard time?
    property MaxGuardTime : Integer read FMaxGuardTime write FMaxGuardTime; // HIgh limit for guard time.

    property WritePriorityBoost : Integer read FWritePriorityBoost write FWritePriorityBoost;

    property SleepTime:Integer read FSleepTime write FSleepTime default 5;

    {NEW: Circular buffer of previous tx/rx activity, so we can go back and do
          a context dump of communications during, before, and after a fault. } 
    property TracePacketCircularBufferLength:Integer read TracePacketCircularBufferGetLength write TracePacketCircularBufferSetLength;

  end;



implementation

uses CportModbus,
     CportTimerUtils, {timer function: TimerElapsed, TimerHasReachedSetpoint}
     CportModbusUtils; {ModbusUtils-CRC etc.}

procedure TComPortModbusMasterThread.TimingTrace(msg:String);
var
 s:String;
begin
  Assert(Assigned(FModbusMaster));


  if FTimingTraceEnable then begin
      s := FormatDateTime('hh:nn:ss.zzz',now)+' '+msg;
{$ifdef TIMINGTRACE_DEBUGINFO_ON}
      OutputDebugString(Pchar('ModbusThread.pas: '+s));
{$endif}
      Trace(s);
  end;
end;

// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
// XX  WARNING: This is unstable. DO NOT CALL TComPort.InputCount, if you use XX
// XX           USB-to-serial adaptor devices. -- WPOSTMA.                    XX
// XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
(*function TComPortModbusMasterThread.InputCount:Integer;
begin
    Assert(Assigned(FComPort));
    try
        if not FComPort.Connected then
            result := 0
        else
        // TComPort.InputCount in turn calls Win32 ClearComErrors api which is
        // unstable on USB serial convertor device drivers.
            result := FComPort.InputCount;

    except
        on E:EComPort do begin

            Trace('ModbusThread.pas: TComPortModbusMasterThread.InputCount EXCEPTION '+E.Message);

            Inc(FExceptions);
            result := 0;
        end;
    end
end;*)

constructor TComPortModbusMasterThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FAssertNoSync := true; // If set to false, calls to Assert(FAssertNoSync) before
                         // calling TThread.Synchronize will raise a debugging-exception, helping us to debug deadlock conditions.
  FPacketListValid  := true;
  FInitialGuardTime  := 1;
  FMaxGuardTime := 10;
  FSleepTime := 5;

end;

destructor TComPortModbusMasterThread.Destroy;
begin
 SetLength(FTracePackets,0); // free circular buffer.
 inherited Destroy;
end;



procedure TComPortModbusMasterThread.SetModbusMaster(master:TObject);
var
  ModbusMaster:TComPortModbusMaster;
begin
  if not Assigned(master) then begin
      FModbusMaster := nil;
      exit;
  end;
  if master is TComPortModbusMaster then begin
     FModbusMaster := master;
     ModbusMaster := FModbusMaster as TComPortModbusMaster;
     SetComPort( ModbusMaster.ComPort ); // Hook Com Port

     // Other Shared Properties
     FCriticalSection           := ModbusMaster.CriticalSection;
     FPacketRetryCount          := ModbusMaster.PacketRetryCount;
     FPacketTimeoutMS           := ModbusMaster.PacketTimeoutMS;
     FNoResponsePacketTimeoutMS := ModbusMaster.NoResponsePacketTimeoutMS;


  end else
     raise TComPortModbusMasterThreadException.Create('TComPortModbusMasterThread.SetModbusMaster - object is not a TModbusMaster');
end;




{ A hold pauses the modbus queue completely }
procedure TComPortModbusMasterThread.BeginHold;
begin
 try

     {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(100);
     {$else}
          FCriticalSection.Enter;
     {$endif}

   Inc(FHold);
 finally
   FCriticalSection.Leave;
 end;
end;



procedure TComPortModbusMasterThread.EndHold;
begin
 try

    {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(101);
     {$else}
          FCriticalSection.Enter;
     {$endif}

   Dec(FHold);
   if (FHold<0) then
       raise Exception.Create('TModbusMaster.EndHold - Illegal condition: Hold < 0');
 finally
   FCriticalSection.Leave;
 end;
end;



{ Begin a batch of blocking writes. HOlds all other modbus activity during this time. }
procedure TComPortModbusMasterThread.BeginBlockingCallBatch;
begin
   Inc(FBlockingCallBatch);
end;

{ End a batch of blocking writes. Resumes normal modbus activity. }
procedure TComPortModbusMasterThread.EndBlockingCallBatch;
begin
   Dec(FBlockingCallBatch);
end;

procedure TComPortModbusMasterThread.SetComPort(aComPort:TComPort);
begin
   FComPort := aComPort;
   if Assigned(aComPort) then begin
     { Get Dispatcher event for available data. This is a custom hack to
      the base comport object, which makes me think, I shouldn't be using
      Async Professional at all for this job. }
      //FComPortDataAvailableEvent := aComPort.Dispatcher._ThreadNotifyAvail;
   end;
end;


function TComPortModbusMasterThread.TracePacketCircularBufferGetLength:Integer;
begin
  result := Length(FTracePackets);
end;

procedure TComPortModbusMasterThread.TracePacketCircularBufferSetLength( bufferLength :Integer );
var
 t:Integer;
begin
  Assert( bufferLength > 0);
  SetLength(FTracePackets,bufferLength);
  for t := 0 to bufferLength-1 do begin
      FTracePackets[t].Ticks := 0;
      FTracePackets[t].msg := '';
  end;
end;

procedure TComPortModbusMasterThread.TracePacket( prefix:String;Data:PChar; DataLength:Word);
var
  s:String;
  t:Integer;
begin
   s :=  Format('%03d', [ (GetTickCount mod 1000) ] )+' '+prefix+' ';
   for t := 0 to (DataLength-1) do begin
        s := s + IntToHex(  Ord(Data[t] ), 2{digits} ) + ' ';
        if Length(s)>80 then begin
            s := s + ' ...'; // trim long packets.
            break;
        end;
  end;
  (* send to end user's tracing log only if flagged *) 
  //if FTimingTraceEnable then
  //TimingTrace(s);

   if FTxLogging then
       Trace(s)
   else if Length(FTracePackets)>0 then begin
      { NEW: INTERNAL CIRCULAR BUFFER FOR TRANSMIT/RECEIVE QUEUE. This
         gives us the luxury of internally tracking communications activity
         preceding, during, and after, some fault condition we are
         investigating. We actually emit trace events only when a fault occurs }

      if FTracePacketIndex>= Length(FTracePackets) then
       FTracePacketIndex := 0;

      FTracePackets[FTracePacketIndex].Ticks := GetTickCount;
      FTracePackets[FTracePacketIndex].msg := s;

      Inc(FTracePacketIndex);
      if FTracePacketIndex>= Length(FTracePackets) then
       FTracePacketIndex := 0;

       if FTracePacketPendingDump>0 then begin
          Dec(FTracePacketPendingDump);
          if FTracePacketPendingDump=0 then begin
                TracePacketCircularBufferDump;
          end;
       end;
  end;

end;

procedure TComPortModbusMasterThread.TracePacketCircularBufferDump; // debug routine.
var
 // s:String;
  count,idx,len:Integer;
  elapsed,tick1,tick2:LongWord;
  function MsecStr(msec:LongWord):String;
  begin
      result := IntToStr(msec);
      // pad with zeros:
      while Length(result)<6 do begin
          result := '0'+result;
      end;
  end;
begin
  idx     := FTracePacketIndex;
  len     := Length(FTracePackets);
  if (len=0)or(idx>=len)or(idx<0) then exit;
//  elapsed := 0;


  tick1   := FTracePackets[idx].Ticks;
  for count := 0 to len-1 do begin
      // print non-blank entry:
      if Length(FTracePackets[idx].msg)>0 then begin
          tick2   := FTracePackets[idx].Ticks;
          elapsed := TimerElapsed(tick1,tick2);
          tick1   := tick2;
          Trace( '{'+MsecStr(elapsed)+'ms} '+ FTracePackets[idx].msg );
      end;
      // advance circular buffer index:
      Inc(idx);
      if idx >= len then
         idx  := 0;
  end;




end;


//---------------------------------------------------------------------
// ModifyPacket
//
// This function either creates a new packet object,
// or pulls an existing packet out of the queue so you
// can modify it. To be safe, if you plan to modify
// the packet, you must set parameter Deactivate to True,
// which sets the Active property false, and prevents
// the background thread from accessing this packet,
// until you finish updating it.
//
// To update, we get the packet handle, change it, then reset Active to true!
//
// Code Sample:
//
//    aPacket := ModbusMasterThread.ModifyPacket(UserCode);
//    aPacket.SetSendData( Data, DataLength );
//    aPacket.BlockingHandle := BlockingHandle; // CreateEvent() handle.
//    aPacket.FunctionCode := FunctionCode;
//    aPacket.PollingInterval := PollingRate;
//    aPacket.SlaveAddress := SlaveAddress;
//    aPacket.ReadLength := ReadCount;
//    // this actually lets the changes fly:
//    aPacket.Active := true;
//---------------------------------------------------------------------
function TComPortModbusMasterThread.ModifyPacket(UserCode:Word;Deactivate,HighPriority:Boolean):TModbusPacket;
var
   t : Integer;
   Packet : TModbusPacket;
   NewFlag:Boolean;
begin
  Packet := nil;

   NewFlag := True; // Create new packet! (this flag is turned off if existing userCode is found! }
   if (UserCode >0) then begin
     for t := 0 to FPacketList.Count-1 do begin
               Packet := FPacketList.Items[t];
               if Assigned(Packet) then
                if Packet.UserCode = UserCode then begin
                        NewFlag := false;
                        break;
                end;
     end;
   end;
    if NewFlag then begin
       Packet := TModbusPacket.Create;
       Packet.UserCode := UserCode; // 0=special-no-user-code,1..n=valid user codes.
    end;

   if (Deactivate or NewFlag) and Assigned(Packet) then 
      Packet.Active := false; // deactivated on changing


   if NewFlag then begin
      Assert(Assigned(Packet));
      Packet._SetHighPriority(HighPriority);
      if HighPriority then begin
          // XXX Access violation here on July 5, 2004. WP.
          //First chance exception at $77E73887. Exception class EAccessViolation with message 'Access violation at address CD64FFE2. Read of address CD64FFE2'.
          // [foreground thread called via _BlockingWrite.]
         AddHighPriorityPacket(Packet);// head of queue, in user code order, reset scan pointer to head.
      end else if not AddPacket(Packet) then begin
         Packet.Free; //DeallocatePacket(Packet);
         raise TComPortModbusMasterThreadException.Create('ModbusThread.ModifyPacket - FAILURE - Unable to add packet to ModbusThread object');
         exit;
     end;
   end;

   result := Packet;
end;



{ This sends a block of allocated memory to the main thread,
  which is a Trace Message
  string to be disposed of in the main thread. Memory leaks would ensue
  if the main thread did not receive these messages.  XXX Perhaps a Pipe would
  be better than all this GetMem/FreeMem crap. }
procedure TComPortModbusMasterThread.Trace( msg:String);
var
 master: TComPortModbusMaster;
begin
  if Terminated then exit;

{$ifdef MODBUSTHREAD_DEBUGINFO_ON}
      OutputDebugString(PChar('ModbusThread.pas: '+msg));
{$endif}

  Assert(Assigned(FModbusMaster));
  master := FModbusMaster as TComPortModbusMaster;

  Assert(Assigned(master._Thread));
  FTraceMsg := msg;
  master._ThreadTrace; // XXX TEST WITHOUT SYNCHRONIZE! master._ThreadTrace must be thread-safe!

  //Assert(FAssertNoSync);// Synchronization-deadlock protection!
  //Synchronize( master._ThreadTrace );
end;


procedure TComPortModbusMasterThread.AfterConstruction;
begin
//    FCriticalSection := TCriticalSection.Create;;

   FCriticalSection  := Nil;

    FModbusMaster := Nil;
    FComPort := Nil;
    FPacketList := TList.Create;
    FPacketList := TList.Create;

    FPacketRetryCount := 4;
    FPacketTimeoutMS := 1750;
    FNoResponsePacketTimeoutMS := 300;

    FPacketCounter := 0;
    FOutgoingPacketQueue := 0;


    FTotalBytesSent := 0;
    FTotalBytesReceived := 0;

    FUserCodePacketFlush := 0; // We don't want to immediately start flush flush flushing...
end;

procedure TComPortModbusMasterThread.BeforeDestruction;
var
   aPacket : TModbusPacket;
  // Timeout : Integer;
   ModbusMaster:TComPortModbusMaster;

begin

    if Assigned(FModbusMaster) then begin
     ModbusMaster := FModbusMaster as TComPortModbusMaster;
     if (ModbusMaster.Active) then
        raise TComPortModbusMasterThreadException.Create('TComPortModbusMasterThread.BeforeDestruction - ModbusMaster still active!');
    end else
        raise TComPortModbusMasterThreadException.Create('ModbusMaster not assigned. TComPortModbusMasterThread.BeforeDestruction error.');

{$ifdef DEBUGINFO_ON}
    if FExecuting then
        OutputDebugString('ModbusThread.pas: TComPortModbusMasterThread.BeforeDestruction - Executing thread still!');
{$endif}

   //Timeout := 0;
   while (FPacketList.Count > 0) do begin
      aPacket := FPacketList.Items[FPacketList.Count - 1];
      if not aPacket.NotificationPending then
          aPacket.Free // This creates a memory leak in certain circumstances, but is considered better than crashing!
      else
          TimingTrace('ModbusMasterThread.BeforeDestruction: Notification pending, skipped Free of memory for Packet at address $'+IntToHex(Int64(Pointer(aPacket)),8));
      FPacketList.Delete(FPacketList.Count - 1);
      //Timeout := 0;

   end;
   FPacketList.Free;

//if Assigned(FCriticalSection) then
//   FCriticalSection.SafeEnter(102);
//
//if Assigned(FCriticalSection) then
//  FCriticalSection.Leave;

end;



// Add packet to head of queue, before non high priority writes,
// and reset scan pointer so that we are sure that the high priority items
// get processed as soon as possible.
function TComPortModbusMasterThread.AddHighPriorityPacket(aPacket : TModbusPacket) : Boolean;
var
  t:Integer;
  Inserted:Boolean;
  CheckIt:TModbusPacket;
begin
   result := false;
   if not Assigned(aPacket) then exit;
   aPacket.Status := modbusPending; // No error yet, in progress.
   if (FPacketList.Count > MAX_MODBUS_QUEUE_SIZE) then begin
{$ifdef DEBUGINFO_ON}
         OutputDebugString('ModbusThread.pas: SERIOUS ERROR: MODBUS MASTER THREAD AT QUEUE SIZE LIMIT');
{$endif}
        exit;
   end;
   // Insert at the head of the list, but
   // after any other high priority writes, with lower user code.
   // ( Avoids case where where the first
   //   high priority write would never be sent
   //   if the second kept being sent
   //   repeatedly. )
   Inserted := false;
   for t := 0 to (FPacketList.Count-1) do begin
          CheckIt := TModbusPacket(FPacketList[t]);
          if (not Assigned(CheckIt)) then raise Exception.Create('TComPortModbusMasterThread: Nil pointer found in packet list');

          if (not CheckIt.HighPriority) or
            ((aPacket.PollingInterval>CheckIt.PollingInterval) and // !!!NEW!!!
             (aPacket.UserCode>CheckIt.UserCode))
             then begin
                 FPacketList.Insert(t,Pointer(aPacket));
                 Inserted := true;
                 break;
             end;
   end;
   if not Inserted then begin
            FPacketList.Add(aPacket); // Add to head of empty list.
   end;
   // Reset scan pointer:
   //FPacketScanIndex :=0; // This will be scanned NEXT!
   //Inc(FPendingHighPriority);
   FOutgoingPacketQueue := FPacketList.Count;
   result := true;
end;

// Add packet to tail of queue, increase queue length indicator, etc.
function TComPortModbusMasterThread.AddPacket(aPacket : TModbusPacket) : Boolean;
var
  t:Integer;
  Inserted:Boolean;
  CheckIt:TModbusPacket;
begin
   result := false;
   if not Assigned(aPacket) then exit;
   aPacket.Status := modbusPending; // No error yet, in progress.
   if (FPacketList.Count > MAX_MODBUS_QUEUE_SIZE) then begin
{$ifdef DEBUGINFO_ON}
         OutputDebugString('ModbusThread.pas: SERIOUS ERROR: MODBUS MASTER THREAD AT QUEUE SIZE LIMIT');
{$endif}
        exit;
   end;
 // Insert at the head of the list, but
   // after any other high priority writes, with lower user code.
   // ( Avoids case where where the first
   //   high priority write would never be sent
   //   if the second kept being sent
   //   repeatedly. )
   Inserted := false;
   for t := 0 to (FPacketList.Count-1) do begin
          CheckIt := TModbusPacket(FPacketList[t]);
          if (not Assigned(CheckIt)) then raise Exception.Create('TComPortModbusMasterThread: Nil pointer found in packet list');

          if (not CheckIt.HighPriority) and 
            ((aPacket.PollingInterval>CheckIt.PollingInterval) and // !!!NEW!!!
             (aPacket.UserCode>CheckIt.UserCode))
             then begin
                 FPacketList.Insert(t,Pointer(aPacket));
                 Inserted := true;
                 break;
             end;
   end;
   if not Inserted then begin
            FPacketList.Add(aPacket); // Add to head of empty list.
   end;
//   FPacketList.Add(Pointer(aPacket));
   FOutgoingPacketQueue := FPacketList.Count;
   result := true;
end;


function TComPortModbusMasterThread.QueryUserCodeCount(UserCode : Word) : Word;
var
   FCounter : Integer;
   FUserCodeCounter : Integer;
   Packet : TModbusPacket;
begin
   FUserCodeCounter := 0;
    {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(103);
     {$else}
          FCriticalSection.Enter;
     {$endif}

   for FCounter := 0 to FPacketList.Count-1 do begin
      Packet := FPacketList.Items[FCounter];
      if (Packet.UserCode = UserCode) then Inc(FUserCodeCounter);
   end;
   FCriticalSection.Leave;
   Result := FUserCodeCounter;
end;

// called directly by _BlockingCall:
function TComPortModbusMasterThread.RemovePacket(Packet:TModbusPacket) : Boolean;
var
   Counter : Integer;
   findPacket :  TModbusPacket;
begin
    {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(104);
     {$else}
          FCriticalSection.Enter;
     {$endif}

   Result := FALSE;
   for Counter := 0 to FPacketList.Count-1 do begin
      findPacket := FPacketList.Items[Counter];
      if (findPacket = Packet) then begin
         Dec(FOutGoingPacketQueue); // out queue is one smaller now that one is "in the loop".
         FPacketList.Delete(Counter);
         Packet.Free;//DeallocatePacket(Packet);
         Result := TRUE;
         break;
      end;
   end;
   if not Result then begin
      OutputDebugString('TComPortModbusMasterThread.RemovePacket failure.');
   end;
   FCriticalSection.Leave;
end;



function TComPortModbusMasterThread.IsUserCodeActive( UserCode:Integer ):Boolean;
var
   Packet : TModbusPacket;
   Counter:Integer;
begin
  result := false;
   for Counter := 0 to FPacketList.Count-1 do begin
      Packet := TModbusPacket(FPacketList.Items[Counter]);
      if Packet.UserCode = UserCode then
            if Packet.Active then begin
                result := true;
                exit;
            end;
   end;
end;

procedure TComPortModbusMasterThread.StopReadingByUserCode(UserCode:Integer);
var
   Counter : Integer;
   Packet : TModbusPacket;
{$ifdef DEBUGINFO_ON}
   Found:Boolean;
{$endif}
begin
{$ifdef DEBUGINFO_ON}
Found := false;
{$endif}
    {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(135);
     {$else}
          FCriticalSection.Enter;
     {$endif}
try
   for Counter := 0 to FPacketList.Count-1 do begin
      Packet := TModbusPacket(FPacketList.Items[Counter]);
      if Packet.UserCode = UserCode then begin
            Packet.Active := false;
{$ifdef DEBUGINFO_ON}
            Found := true;
{$endif}
      end;
   end;

{$ifdef DEBUGINFO_ON}
   if not Found then begin
      OutputDebugString(PChar(  'ModbusThread.pas: UserCode Not found: '+IntToStr(UserCode)));
   end;
{$endif}

finally
  FCriticalSection.Leave;
end;

end;

procedure TComPortModbusMasterThread.StopReading; // stops all polling activity.
var
   Counter : Integer;
   Packet : TModbusPacket;
begin

    {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(105);
     {$else}
          FCriticalSection.Enter;
     {$endif}
try

   FPacketListValid  := false;

   for Counter := 0 to FPacketList.Count-1 do begin
      Packet := TModbusPacket(FPacketList.Items[Counter]);
      Packet.Active := false;
   end;
   
finally
  FCriticalSection.Leave;
end


end;



procedure TComPortModbusMasterThread.Flush;
var
 safety,count:Integer;
 dummy:String;
begin
  // XXX Read then discard all existing data in the incoming buffer.

  for safety := 0 to 10 do begin
    count := FComPort.ReadStr(dummy,512);
    if (count<512) then
        break;
  end;
end;

  {idle state called by Execute}
procedure TComPortModbusMasterThread.IdleThreadState;
begin
{$ifdef BLOCKINGCALL_DEBUGINFO_ON}
  Inc(FIdleThreadStateCounter);
  OutputDebugString(PChar('ModbusThread.pas: IdleThreadState. IdleThreadStateCounter='+IntToStr(FIdleThreadStateCounter)) );//XXX noisy. remove me.
{$endif}

    Assert(FSleepTime>0);
    Assert(FSleepTime<1000);

    
    FActivePacket := Nil;

    if not Terminated then
             SleepEx(FSleepTime,true); // got all the way around with nothing to do, stop hogging the CPU!
end;

   {initial state called by Execute}
procedure TComPortModbusMasterThread.InitThreadVars;
begin
           FExecuting := true;

           while ((FModbusMaster = Nil) or (FComPort = Nil)) do begin
              if (Terminated) then exit;
              //SleepEx(FSleepTime,TRUE); XXX WHY WAS THIS HERE?
           end;
           FReceiveBuffer[0] := Chr(0);

           //FPacketScanIndex := FPacketList.Count+1; // scans loop continuously, this is the scan index.
           //FComPort.FlushOutBuffer;
           //FComPort.FlushInBuffer;
           Flush;
           FActivePacket := Nil; // This compiler is whacked.  Either the value is "never used" or it is "possibly undefined".  Blah.
end;

procedure TComPortModbusMasterThread.CleanupThreadVars; // undo whatever we did in InitTHreadVars.
        begin
           //FreeMem(FBlockBuffer);
           FReceiveBuffer[0] := Chr(0);
           FExecuting := false;
        end;

{$ifdef MODBUS_DEBUG}
procedure TComPortModbusMasterThread.DebugPacketOk;
var
  t:Integer;
begin
for t := 0 to FPacketList.Count-1 do begin
    TModbusPacket(FPacketList.Items[t]).DebugPacketOk;
end;
end;
{$endif}

function TComPortModbusMasterThread.SlaveIdSetOffline(SlaveAddress:Integer;setOffline:Boolean):Integer;
var
  Packet :TModbusPacket;
  t:Integer;
  tick,count:Integer;
begin
//   result := 0;
   count := 0;

{$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
    FCriticalSection.SafeEnter(106);
{$else}
    FCriticalSection.Enter;
{$endif}

    tick := GetTickCount;

  try
     for t := 0 to FPacketList.Count-1 do begin
               Packet := FPacketList.Items[t];
               if Assigned(Packet) then
                if (SlaveAddress = -1{ALL}) or (Packet.SlaveAddress = SlaveAddress) then begin
                        if (Packet.Offline <> setOffline) then begin
                          Packet.Offline := setOffline;
                          //if not Packet.Offline then begin
                          Packet.PollingNextTime := tick;
                          //end;
                          Inc(count);
                          if setOffline then
                             TimingTrace(Packet.DebugId+': packet offline. ' )
                          else
                             TimingTrace(Packet.DebugId+': packet back online. ') ;
                        end;
                end;
     end;
  finally
    FCriticalSection.Leave;
  end;

  result := count;

end;

function TComPortModbusMasterThread._RetrievePacket:Boolean;
var
 t:Integer;
 CurrentScore   : Integer;
 BestScore      : Integer; // Highest Score wins. A score < 0 means not ready to send yet and will never win.
 BestScoreIndex : Integer;
 {$ifdef MODBUS_WRITE_STARVATION_DEBUG}
 BestWriteScore : Integer;
 BestWriteScoreIndex:Integer;
 {$endif}
 pkt            : TModbusPacket;
begin
  result := false;
  // Best packet to send right now:
    BestScoreIndex := -1; // Default: Not found.
    BestScore      := -1; // Default: Don't send yet.
  // Best write packet to send right now:
 {$ifdef MODBUS_WRITE_STARVATION_DEBUG}
    BestWriteScoreIndex := -1; // Default: Not found.
    BestWriteScore      := -1; // Default: Don't send yet.
 {$endif}





  {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
    FCriticalSection.SafeEnter(107);
  {$else}
    FCriticalSection.Enter;
  {$endif}


  if Assigned(FBlockingPacket) then begin

      FActivePacket := FBlockingPacket;
      FActivePacket.Active := true; // this is done in the background, not in the foreground!
      Assert(FActivePacket.SlaveAddress>0);
      Assert(FActivePacket.SlaveAddress<250);
      FBlockingPacket := nil;
      result := true;
      FCriticalSection.Leave;
      {$ifdef MODBUS_DEBUG}FActivePacket.DebugPacketOk;{$endif}
      exit;
  end;


  { No blocking packet is waiting, so process queue normally }

  try  

    FActivePacket := nil;
    FTickNow  := GetTickCount;

    if FBlockingCallBatch<=0 then // Don't scan queue during batches of blocking-calls
  for t := 0 to FPacketList.Count-1 do begin
        //CurrentScore   := -1;
        pkt  := TModbusPacket( FPacketList.Items[t] );
        Assert(Assigned(pkt));
        if (pkt.Offline) or (not pkt.Active) then
            continue;

        CurrentScore := pkt.PollingCheck(FTickNow);// Get polling time overdue.

{$ifdef MODBUS_WRITE_STARVATION_DEBUG}
        if (pkt.WriteFlag) and (CurrentScore>=0) then begin
            if FWritePriorityBoost>0 then
             Inc(CurrentScore,FWritePriorityBoost); // Write starvation avoidance by boosting write priority.
            if CurrentScore>BestWriteScore then begin
                BestWriteScore := CurrentScore;
                BestWriteScoreIndex := t;
            end;
        end;
{$endif}
        if CurrentScore>BestScore then begin
            BestScore := CurrentScore;
            BestScoreIndex := t;
        end;
  end;

{$ifdef MODBUS_WRITE_STARVATION_DEBUG}
  { some debug stuff}
  
  if (BestWriteScoreIndex>=0) and (BestScoreIndex<>BestWriteScoreIndex) then begin
      if (BestScore>30000) then begin
          Trace('XXX Write Starvation debug: Rediculously High Score Debug: '+TModbusPacket(FPacketList.Items[BestScoreIndex]).DebugId +' BestScore='+IntToStr(BestScore));
      end else begin
          Trace('XXX Write Starvation debug:  Write score lost: BestScore='+IntToStr(BestScore)+' BestWriteScore='+IntToStr(BestWriteScore));
          // Experimental write-is-right test:
          BestScoreIndex := BestWriteScoreIndex;

      end;
  end;
{$endif}

  // Prioritization Queue: Return packet with highest score:   
  if (BestScoreIndex >= 0) then begin

      FActivePacket := FPacketList.Items[BestScoreIndex];
      FActivePacket.PollingTimeUpdate; // We reschedule packet for later, whether it works or times out.
      if (FActivePacket.DebugFlag) then begin
           Trace('XXX Packet Debug: Packet with debug flag is being sent!');
      end;
      result := true;
  end;

  finally
      FCriticalSection.Leave;

  end;

  


end;



   { retrieve packet which is in a ready-to-send state, called by main thread  }
function TComPortModbusMasterThread.HoldThenRetrievePacket:Boolean;
var
    DeadlockDebugFlag:Boolean;
    DeadlockDebugCount:Integer;
begin

  DeadlockDebugFlag := false;
  DeadlockDebugCount := 0;
  result := false;
  FActivePacket := nil; // none yet!
  if Terminated then exit;

  { -- DO PACKET HOLDING STATE! -- }
  { We need this so we can send a sequence in order, and pause temporarily
    the sending/scanning so we can set up the sequence }
  while FHold>0 do begin
      // Five Seconds (50*100) before deadlock timeout!
        if (DeadlockDebugCount > 50) and (not DeadlockDebugFlag) then begin
           DeadlockDebugFlag := true;
{$ifdef DEBUGINFO_ON}
           OutputDebugString('ModbusThread.pas: TComPortModbusMasterThread.RetrievePacket: ?DEADLOCK? TComPortModbusMasterThread.Hold is on for a long time.');
{$endif}
           //FHold := 0; // See what happens if we do this. VERY EVIL.
        end;
{$ifdef DEBUGINFO_ON}
        if DeadlockDebugCount>20 then
            OutputDebugString('ModbusThread.pas: RetrievePacket HOLDING');
{$endif}
        Sleep(100);
        Inc(DeadlockDebugCount);

        if Terminated then exit;
  end;

  if not FPacketListValid  then exit;
  if not Assigned(FPacketList) then exit;


  try
      result := _RetrievePacket;
  except
      on E:Exception do begin
          Trace('Exception in _RetrievePacket - '+E.ClassName+':'+E.Message);
      end;
  end;


end;

    { send packet state, called by Execute }
procedure TComPortModbusMasterThread.SendPacketState;
var
    Elapse:DWORD;
{$ifdef BLOCKINGCALL_DEBUGINFO_ON}
    BeforeTx,AfterTx,EnterCrit:DWORD;
{$endif}
    GuardTime:Integer;
begin

      if Terminated then exit;




      {$ifdef MODBUS_DEBUG}FActivePacket.DebugPacketOk;{$endif}

      try { except }

                 // XXX ---- SEND PACKET ---- XXX



        FReceiveBuffer[0] := Chr(0); //erase old response
        if     Assigned(FActivePacket)
           and (FActivePacket.Active)
           and (not FActivePacket.Offline)
           and (FActivePacket.SendLength > 5)
           and (FActivePacket.SendLength < 255)
            then begin
         FSendStrPtr := FActivePacket.SendData;
         if Assigned(FSendStrPtr) then begin
           FActivePacket.Status := modbusPending;
           if (FActivePacket.Timeout<100) then
              FActivePacket.Timeout := 100; // control minimum value.

           FLastTxTimer := GetTickCount;

           // insert a small delay in between last response, and next request, so the slaves don't
           // get confused?
           Elapse := TimerElapsed(FLastRxTimer,FLastTxTimer);
           GuardTime := FGuardTime[FActivePacket.SlaveAddress];
           if Elapse <= DWORD(GuardTime) then begin
                Assert(GuardTime<500);
                SleepEx( GuardTime, true); // 2-20 ms, or so.
                FLastTxTimer := GetTickCount;
           end;
           if Elapse>1000 then begin
              Trace('TX Gap ('+IntToStr(Elapse)+' ms)');
           end;

           if  FGuardTime[FActivePacket.SlaveAddress]>0 then




{$ifdef BLOCKINGCALL_DEBUGINFO_ON}
           BeforeTx := GetTickCount;
{$endif}

           Assert(FActivePacket.SendLength>0);
           Assert(FActivePacket.SendLength<255);
           Assert(Assigned(FSendStrPtr));
           //OutputDebugString('ModbusThread.pas: SendPacketState FComPort.Write');
           FComPort.Write(FSendStrPtr^,FActivePacket.SendLength);

           
         end;{if}
        end;

      except
{$ifdef DEBUGINFO_ON}
          OutputDebugString('ModbusThread.pas: Failed to write to com port. Exception in ModbusThread.Execute');
{$endif}
          TracePacket('TX-FAIL', FSendStrPtr,FActivePacket.SendLength);
          Inc(FExceptions);
          exit;
      end;


      if (not Self.Terminated) and FTxEventEnable then begin
          Assert(FAssertNoSync);// Synchronization-deadlock protection!
          Synchronize( (FModbusMaster as TComPortModbusMaster)._ThreadTxEvent );
      end;

      FLastTxUserCode := FActivePacket.UserCode;

      {$ifdef MODBUS_DEBUG}FActivePacket.DebugPacketOk;{$endif}

{$ifdef BLOCKINGCALL_DEBUGINFO_ON}
      AfterTx := GetTickCount;
      Elapse := TimerElapsed(BeforeTx,AfterTx);
      if Elapse<FSleepTime then
{$endif}
          SleepEx(FSleepTime,True);// wait a little before we check what data is ready to read.
          
      FTotalBytesSent := FTotalBytesSent + FActivePacket.SendLength;
           //QueryPerformanceCounter(FHighPerFActivePacketSendTime);
      if FTxLogging or FActivePacket.TraceFlag or (Length(FTracePackets)>0) then
       TracePacket( FActivePacket.DebugId+' TX', FSendStrPtr, FActivePacket.SendLength);


end;



        { read response state, called by Execute }
procedure TComPortModbusMasterThread.ReadResponseState;
var
   Safety,ReadCount,IgnoreCount,t:Integer;
   TimeoutFlag:Boolean;
   ReceiveStrPtr:PChar;
   Elapsed,Tick1,Tick2:DWORD;
begin
  if Terminated then exit;
  TimeoutFlag := false;
  FBytesRead := 0;
  elapsed := 0;
//  SingleReadFlag:= false;




       //FComPort.GetBlock(FReceiveStrPtr^,FBytesRead);
       SleepEx(FSleepTime,true);
//       ReadCount := -1; // not yet read.
       Safety := 0;
       // This assumes that the COMMTIMEOUTS have been set properly, as detailed
       // in the help for COMMTIMEOUTS in the Microsoft Platform SDK.  If this code
       // freezes or takes too long to return, probably the timeouts are not set
       // properly. See TComPortModbusMasterThread.Timeouts;

  try
             // XXX --- AWAIT RESPONSE: --- XXX
    {$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
          FCriticalSection.SafeEnter(201);
     {$else}
          FCriticalSection.Enter;
     {$endif}


      Tick1 := GetTickCount;
      FActivePacketTimerTick := Tick1+(FActivePacket.Timeout)+10; // When we reach this setpoint, we have timed out!
     

       while true do begin

         ReceiveStrPtr := @FReceiveBuffer[FBytesRead];
         ReadCount := FComPort.Read(ReceiveStrPtr^,MAX_MODBUS_READ_BLOCK);

          Tick2 := GetTickCount;
          Elapsed := TimerElapsed(Tick1,Tick2);
         

         if Terminated then begin
         {$ifdef DEBUGINFO_ON}
             OutputDebugString('Modbus Thread Terminated during read-response');
         {$endif}
              break;
         end;

         if ReadCount>0 then begin
            Inc(FBytesRead,ReadCount);
            if RtuExpectedLengthCheck then begin
                Assert(FBytesRead>=5);
                    break; // Don't have to wait full time, if the response is valid!
            end;

         end;


         if (Elapsed>FActivePacket.Timeout) then begin
         {$ifdef DEBUGINFO_ON}
            OutputDebugString('Modbus Thread ReadResponseState: TIMEOUT');
         {$endif}


             TimeoutFlag := true; // Can't trace inside critical section! Set this flag so we can trace after leaving it!
             break;
         end;

         if (FBytesRead>=constIncomingBlockSize-1) then begin
         {$ifdef DEBUGINFO_ON}
            OutputDebugString('Modbus Thread ReadResponseState: too much data received.');
         {$endif}
            break;
         end;
         Inc(Safety);
         if (Safety>120) then begin// maximum of 10*FSleepTime milliseconds total elapsed time.
         {$ifdef DEBUGINFO_ON}
            OutputDebugString('Modbus Read Response Safety abort');
         {$endif}
            break;
         end;
       end;

     finally
        FCriticalSection.Leave;
     end;


    if Terminated then
              exit;

    // Now that we are OUT of the critical section, post any trace messages:
    if TimeoutFlag then begin
       Trace( FActivePacket.DebugId +' TIMEOUT. (Elapsed='+IntToStr(elapsed)+')' );
    end;
    if (Safety>3000) then begin // tell user that something bad happened!
       Trace( FActivePacket.DebugId +' SAFETY LIMIT REACHED.');
    end;


       //FBlockCounter := FBlockCounter + FBytesRead;
       FLastRxTimer := GetTickCount;
       FLastRxUserCode := FActivePacket.UserCode;

       FTotalBytesReceived := FTotalBytesReceived + LongWord(FBytesRead);
(*        if (FBlockCounter >= constIncomingBlockSize) then begin
            // Received a huge amount of data? Ie 4K?
            Trace('MODBUS RX OVERFLOW '+IntToStr(FBlockCounter)+' BYTES IGNORED');
            FActivePacket.OnNoiseBytes(FBlockCounter);
            //FComPort.FlushInBuffer;
            //FComPort.FlushOutBuffer;
            Flush;
            FWaitingForPacket:=FALSE;
        end; *)

        { ignore any leading character that is not the slave ID,
          or an exception flag + slave id (0x80 OR with Slave ID) }
       IgnoreCount := 0;
        while  ( Ord(FReceiveBuffer[0]) <> FActivePacket.SlaveAddress)
             and (FBytesRead>0) do begin
                  {$ifdef MODBUS_DEBUG}DebugPacketOk;{$endif}
                  Trace( 'RX Expecting '+
                              IntToHex(FActivePacket.SlaveAddress,2)+
                              ', Ignored '+IntToHex(Ord(FReceiveBuffer[0]),2) );
                  Inc(IgnoreCount);
                  FActivePacket.OnNoiseBytes(1);//Inc(FActivePacket.NoiseBytesCounter);
                  // Eat first character, look for next one to contain slave address:
                  for t := 1 to FBytesRead-1 do
                          FReceiveBuffer[t-1] := FReceiveBuffer[t];
                  Dec(FBytesRead);
        end;
       if (IgnoreCount>0) and (FBytesRead=0) then begin
          // In my experience, if this is happening to you regularly , something is very wrong
          // and while debugging the application, it's a good idea not to let this pass silently by.
          // In a production application, if this happens more than once a month, find out why
          // and fix it. -WPostma.
           // sample debug code:  raise Exception.Create( 'ModbusThread.ReadResponseState: IGNORED ENTIRE RESPONSE! ('+IntToStr(IgnoreCount)+' Chars)');

          // At the very least, log it in the trace log:           
          Trace( 'ModbusThread.ReadResponseState: IGNORED ENTIRE RESPONSE! ('+IntToStr(IgnoreCount)+' Chars) XXX');
          FActivePacket.Status := modbusBadReplyPacket; // Malformed packet!
          SleepEx(FSleepTime,true);
       end;


end;



        { timeout handler state, called by execute }
procedure TComPortModbusMasterThread.TimeoutHandler;
var
    incrementBy:Integer;
begin
    FActivePacket.OnTimeout;
    FSuccessfullyReceivedPacket := FALSE;
    FWaitingForPacket := FALSE;
     {Timing}Trace( FActivePacket.DebugId+': MODBUS RetryAttemptsExhaustedFaults='+
          IntToStr(FActivePacket.RetriesExhaustedErrors)+
          ', Slave='+IntToStr(FActivePacket.SlaveAddress)+
          ', Address='+IntToStr( FActivePacket.StartingAddress)+
          ', GuardTime='+IntToStr(FGuardTime[FActivePacket.SlaveAddress])
          );
    (* if FActivePacket.SlaveAddress=10 then begin
        OutputDebugString('ModbusThread.pas: TimeoutHandler on Slave Address 10');
     end;*)
     
   if FMaxGuardTime>FInitialGuardTime then
    if  FGuardTime[FActivePacket.SlaveAddress]< DWORD(FMaxGuardTime) then begin
      incrementBy := (FMaxGuardTime-FInitialGuardTime) div 5;
      if incrementBy < 1 then
        incrementBy := 1;
      Inc( FGuardTime[FActivePacket.SlaveAddress], incrementBy);
      if FGuardTime[FActivePacket.SlaveAddress]>DWORD(FMaxGuardTime) then
            FGuardTime[FActivePacket.SlaveAddress] := FMaxGuardTime;
    end;
    //SleepEx(FTimeoutRecovery,True); // XXX What to do here?
    //Flush; 
end;

           { In RTU mode, check if we have received a valid 4 byte Exception Message, called by Execute }
function TComPortModbusMasterThread.RtuExceptionCheck:Boolean;
begin
  result := false;
  if    (  Ord(FReceiveBuffer[0])  = FActivePacket.SlaveAddress )
    and ( FBytesRead   >= 4 ) and ( FBytesRead   <= 5 )  { exception messages are 4 or 5 bytes long }
    and ( ( Ord(FReceiveBuffer[1]) and $80 ) >0 ) { high bit set in function code }
    then begin { slave id found }
       // returns true if lrc byte is correct.
        result := FActivePacket.OnException(FReceiveBuffer,FBytesRead);
        if (FRxLogging or FActivePacket.TraceFlag) then
           Trace('EXCEPTION $'+ IntToHex(FActivePacket.ExceptionCode,2) );

    end;
end;

{ Helper function to check if an RTU CRC is valid }
function TComPortModbusMasterThread.RtuCrcCheck:Boolean;
var
 ReceivedCrc:Word;
begin
  result := false; {default: not a CRC match }
  // Use the tables in ModbusUtils.pas to calculate the
  // checksum:
  FCalculatedCRC := CalculateRTUCRC(FReceiveBuffer,FBytesRead-2);

  ReceivedCrc :=  Byte ( FReceiveBuffer[FBytesRead-1] )+
                  (Byte ( FReceiveBuffer[FBytesRead-2] )*256);

  // Check last two bytes of packet against our calculated CRC
  // Note that the modbus CRC does not use the same polynomial as
  // an XModem CRC.
(*  if (    ( Byte ( FReceiveBuffer[FBytesRead-1] ) = (FCalculatedCRC and 255 ) )
      and ( Byte ( FReceiveBuffer[FBytesRead-2] ) = (FCalculatedCRC shr   8 ) )
     ) *)
  if ReceivedCrc = FCalculatedCrc
     then begin
              result := true; { CRC MATCH }
              FActivePacket.Status := modbusGood;
     end else begin
          if FActivePacket.WriteFlag then
           Trace(FActivePacket.DebugId+' CRC-ERROR on Write: Expected $'+IntToHex(FCalculatedCRC,4)+', received $'+IntToHex(ReceivedCrc,4) )
          else
           Trace(FActivePacket.DebugId+' CRC-ERROR on Read: Expected $'+IntToHex(FCalculatedCRC,4)+', received $'+IntToHex(ReceivedCrc,4) );

           FActivePacket.Status := modbusBadReplyPacket; // CRC or other Failure.

           //-----------------------------------------------------------
           // Debug Code:
           // TracePacketPendingDump: PENDING DUMP OF CIRCULAR BUFFER.
           //  Will dump this packet, and a few before/after it, after
           // 2 more calls to TracePacket.
           //-----------------------------------------------------------
           FTracePacketPendingDump := 2;
     end;
end;

function  TComPortModbusMasterThread.RtuExpectedLengthCheck:Boolean; // Enough bytes received?
var
    expectLen:Integer;
begin
  if FBytesRead>80 then begin
      OutputDebugString('RtuExpectedLengthCheck');
  end;
    if ( FBytesRead   >= 4 ) { real messages are at least 5 bytes long }
      then begin
           case Ord(FReceiveBuffer[1]) of
                  { Standard reads }
              1,2,3,4,12,17,20,21,23:  expectLen := 5+Ord(FReceiveBuffer[2]); { standard read type }
                  { Standard acknowledgements of writes }
                              5,6,15:
                                    expectLen := 8;
                              16:
                                  expectLen := 8; //: BUGFIX:Forgot case of 0x10 (Write Multiple Registers)!
                  { special case: command 7 }
                                   7:  expectLen := 5;
                  { special case: commands 11, 8 }
                                11,8:  expectLen :=8;

              else
                  { Default or Custom packet types : minimum of 5 bytes: }
                         expectLen := 5;
          end;
        result := FBytesRead>= expectLen;
      end else begin
          result := false;
      end;
end;

{ Awaiting a valid response, so check if it is an RTU packet, called by Execute }
function TComPortModbusMasterThread.RtuResponseCheck:Boolean;
begin

    if    (  Ord(FReceiveBuffer[0] )  = FActivePacket.SlaveAddress )
    and  ( ( Ord(FReceiveBuffer[1]) and $80 ) = 0 ) { high bit set in function code would mean exception! }
    then begin
      // First check if it's all there!?
       result := RtuExpectedLengthCheck;
       // next check the CRC:
      if ( result ) then begin
                   result := RtuCrcCheck;
       end;
    end else begin
        // Invalid first byte!
        Assert(Assigned(FActivePacket));
        OutputDebugString(PChar('ModbusMasterThread.pas: '+FActivePacket.DebugId+': invalid first byte in response '));
        result := false;
    end;
end;





   // Setup Win32 SDK COMMTIMEOUTS:
   //
   // SOME SDK NOTES REGARDING THE LINES BELOW MARKED 'BOGO MODE 1':
   // According to the Windows PLATFORM SDK, if we use overlapped I/O, and
   // we set COMMTIMEOUTS.ReadTotalTimeoutMultiplier and
   // COMMTIMEOUTS.ReadIntervalTimeout to MAXDWORD ($FFFFFFFF) then the
   // behaviour of ReadFile is as follows:
   //   - if there are any characters in the input buffer, ReadFile returns immediately
   //     with the characters in the buffer.
   //   - if there are no characters in the input buffer, it waits for one character and
   //     returns. (this is suboptimal for us, so we handle it by repeating calls to readfile
   //     until nothing is returned.)
   //   - if none arrive, it times out and returns nothing.
   //
procedure TComPortModbusMasterThread.Timeouts;
var
 ReadConstant:Integer;
begin

  Assert(Assigned(FComPort));
  // BOGO MODE 1
  //FComPort.Timeouts.ReadTotalMultiplier := -1; // equivalent signed value for MAXDWORD
  //FComPort.Timeouts.ReadInterval := -1; // equivalent signed value for MAXDWORD
  //FComPort.Timeouts.ReadTotalConstant := FSleepTime; // With modbus at 9600 bps, we would use a value around 5 milliseconds.

  (*FComPort.Timeouts.WriteTotalMultiplier := -1;

  if (FComPort.BaudRate < br19200) then
       FComPort.Timeouts.WriteTotalConstant := 5000
     else
       FComPort.Timeouts.WriteTotalConstant := 1000;*)
       

  // Total timeout is 2x FSleepTime, maximum character timeout is FSleepTime.
   FComPort.Timeouts.ReadTotalMultiplier := 0;
   FComPort.Timeouts.ReadInterval := FSleepTime;

   { Ensure ensuring we wait at least 15 msec for a read, at 19200 bps and up,
     and at least 30 msec at 9600 bps or below, at least 60 msec at 4800 bps
     and below that, tweak FSleepTime yourself, please. }
   ReadConstant := FSleepTime * 3;
   if ReadConstant<15 then
      ReadConstant := 15;
   if (FComPort.BaudRate < br19200) then
      ReadConstant := ReadConstant * 2;
   if (FComPort.BaudRate < br2400) then
      ReadConstant := ReadConstant * 2;

   FComPort.Timeouts.ReadTotalConstant := ReadConstant;
end;



//---------------------------------------------------------
//  Main Thread Function for TComPortModbusMasterThread.
//
//  Runs until signalled to shut down.
//
//---------------------------------------------------------
procedure TComPortModbusMasterThread.Execute;
var
   Temp : Integer; { temporary local variables only }
//   TicksNow:DWORD;
   Master : TComPortModbusMaster;
begin
  ThreadFault    := false;
  ThreadFaultStr := 'Ok';

{$ifdef MODBUS_ENABLE_TXRXCIRCULARBUFFER}
 // You can also set TModbusMaster._Thread.TracePacketCircularBufferLength := 10; in your own application code
 // to enable this feature dynamically at runtime!
  TracePacketCircularBufferSetLength(10);
{$endif}

  try

{$ifdef DEBUGINFO_ON}
   OutputDebugString(PChar('ModbusThread.pas: TComPortModbusMasterThread.Execute begins. ThreadID='+IntToStr(ThreadID)) );
{$endif}

   InitThreadVars;  { INITIALIZE THE THREAD'S LOCAL VARIABLES }

   for Temp := 0 to 255 do begin
       FGuardTime[Temp] := FInitialGuardTime; // Initial value of delay between master command transmits
   end;
   FLastTxTimer := GetTickCount;
   FLastRxTimer := GetTickCount;
//   FPacketQueueTimeLast := GetTickCount; // When did we last complete one scan of all packets?

//   if (Terminated) then exit;  { QUICK WAY OUT }
   Assert(Assigned(FModbusMaster));
   Master :=     FModbusMaster as TComPortModbusMaster;
   Assert(Assigned(Master));
   Assert(Assigned(FComPort));

   //XXX If we ever determine one FComPort.SyncMethod or the other works better,
   //XXX we should check it here, and raise an exception if it is set wrong:
  // XXX Assert( FComPort.SyncMethod = smThreadSync, 'TComPortModbusMasterThread requires ComPort.SyncMethod to be smThreadSync');

   FTxEventEnable  := Assigned(Master.OnTxEvent); // Only do the Synchronize call if we really need to!

   Timeouts; // Setup Win32 SDK COMMTIMEOUTS.


   while (Terminated = FALSE) and (not Master.ShuttingDown) do begin { Main Thread Loop! }

        HoldThenRetrievePacket;    // This is where we select the item, after any holds are finished.

        if (Terminated)or(Master.ShuttingDown) then begin
       {$ifdef DEBUGINFO_ON}
            OutputDebugString('ModbusThread.pas: Thread Terminated');
       {$endif}
            break;
        end;
        
        if not Assigned(FActivePacket) then begin // if queue was empty or nothing ready to go just yet, Idle.
            //FCriticalSection.Leave; // now we have selected an item, or else we exited without a packet
            IdleThreadState;
            continue;
        end;


        { Get Ready to Send the Packet }

        FUserCodePacketFlush := 0;

        FSuccessfullyReceivedPacket := False;


       FActivePacket.OnReadyToSend;         //Sets FRetryCount := 0 and FStatus := modbusPending

        // The Send-Retries loop:
       while (FActivePacket.RetryCount < FPacketRetryCount) // wait X number of retries,
             and (FActivePacket.Status <> modbusTimeout) // or one timeout.
             and (not FSuccessfullyReceivedPacket) // or we get a packet!
             and (not Terminated) // or the thread is shutting down.
           do begin

      {$ifdef MODBUS_DEBUG}FActivePacket.DebugPacketOk;{$endif}

           SendPacketState;    {Send Packet Once. Can't be inside critical section }

           if (Terminated) then begin
               //XYZ FCriticalSection.Leave; // now we have selected an item, or else we exited without a packet
               break;
           end;

           FBytesRead := 0;
           FWaitingForPacket := TRUE;
           FSuccessfullyReceivedPacket := FALSE;

           ReadResponseState;  // read entire response from the com port, appends to anything already read.
           if Terminated then
               break;

               { If this is an exception response, we can check it when we have all four bytes: }
               if (FBytesRead >= 4) and (FActivePacket.CustomFlag) then begin
                    if RtuResponseCheck then begin
                      FSuccessfullyReceivedPacket := true;
                      FActivePacket.OnReceivedOk;
                    end else if RtuExceptionCheck then begin
                      TimingTrace('Exception Code $'+IntToHex(Ord(FReceiveBuffer[2]),2)+' Received on Custom Command.');
                      FSuccessfullyReceivedPacket := true;
                    end;
                    break;
                end else if RtuExceptionCheck then begin
                    TimingTrace('Exception Code $'+IntToHex(Ord(FReceiveBuffer[2]),2)+' Received.');
                    FSuccessfullyReceivedPacket := true;
                    break;
                end else if RtuResponseCheck  then begin
                    FSuccessfullyReceivedPacket := true;
                    FActivePacket.OnReceivedOk; // Inc(FActivePacket.PollingOkCount);
                    break;
                end else begin
                    // DEFAULT CONDITION: TIMEOUT on single packet, retry, then do failure (timeout) handler.
                    if FBytesRead>0 then begin

                    // XXX Debug code:
                            (*if RtuResponseCheck  then begin
                                  FSuccessfullyReceivedPacket := true;
                                  FActivePacket.OnReceivedOk; // Inc(FActivePacket.PollingOkCount);
                            end;*)

                            TracePacket( FActivePacket.DebugId+': RX NOISE', PChar(@FReceiveBuffer[0]), FBytesRead);
                            FActivePacket.OnNoiseBytes(FBytesRead);//partial response.
                            // clear other junk.
                            Flush;
                    end;
                    FActivePacket.OnRetry;
                    Trace(FActivePacket.DebugId+': RX RETRY (RetryCount='+IntToStr(FActivePacket.RetryCount)+')' );

                end;


                if (FBytesRead>0) then begin
                    if (FRxLogging or FActivePacket.TraceFlag) or (Length(FTracePackets)>0) then
                      TracePacket(FActivePacket.DebugId+' RX '+IntToStr(FBytesRead)+'bytes', PChar(@FReceiveBuffer[0]), FBytesRead);
                end;

      end; { LOOP until received or retries exhausted }

      { Now the retries are over }
     if (FActivePacket.PollingInterval = 0) then begin // no longer active.
        FActivePacket.Active := false; // reset active flag so it won't be re-sent!
     end;

     if (not FSuccessfullyReceivedPacket) then begin
           TimeoutHandler; // After retries, do Failure handler
     end;

       // Copy the data in the the response field of the packet.
     if (FSuccessfullyReceivedPacket) and (FBytesRead>0) and (FBytesRead<=255) then begin
            FActivePacket.OnResponseData(FReceiveBuffer,FBytesRead-2);
     end else begin
          { here we may only be copying in an exception message, with LRC }
          if FBytesRead>0 then begin
           FActivePacket.OnResponseData(FReceiveBuffer,FBytesRead);
          end;
     end;
        { Now we notify whoever needs notifying! }
     if (FActivePacket.BlockingHandle <> 0) then begin // This was a Blocking call.
          SetEvent(FActivePacket.BlockingHandle);
     end else if not Terminated then begin
             FActivePacket.NotificationPending := true;
             //PostMessage(FOwnerWindow,MESSAGE_MODBUS_PACKET_WAITING,0,LPARAM(Pointer(FActivePacket)));
             Assert(Assigned(FModbusMaster));
             // New: Synchronized! This handles success and failure cases, and
             // blocks our background thread (very handy side-effect) until
             // the user has finished processing the results of the modbus activity.
             Assert(FAssertNoSync);// Synchronization-deadlock protection!
             Synchronize( (FModbusMaster as TComPortModbusMaster)._ThreadPacketWaitingEvent );

     end;
end; //End While Not Terminated Loop!


  CleanupThreadVars;
{$ifdef DEBUGINFO_ON}
  OutputDebugString(PChar('ModbusThread.pas: TComPortModbusMasterThread.Execute ends '+IntToStr(ThreadID)));
{$endif}
  except
   on E:Exception do begin
      ThreadFault    := true;
      ThreadFaultStr := E.Message;
      //PostMessage(FOwnerWindow, MESSAGE_MODBUS_TX, 0, 0); {FAULT}
      Trace('ModbusMasterThread exception: '+E.Message);
   end;
  end;
end;


{$ifdef MODBUS_DEBUG_CRITICAL_SECTION}
constructor TModCriticalSection.Create;
begin
  inherited;
  FSection := TCriticalSection.Create;
end;

destructor TModCriticalSection.Destroy;
begin
  FreeAndNil(FSection);
  inherited;
end;

procedure TModCriticalSection.SafeEnter(entrycode:Integer);
var
  timeout:Integer;
  msg:String;
begin
    if (FEntrycode <> 0) then begin
        OutputDebugString(PChar('SafeEnter('+IntToStr(entrycode)+') blocking.'));//XXX
        timeout := 0;
        // Debug Code
        (*if (FEntryCode=107) then begin
            OutputDebugString(PChar( 'ModbusThread.pas: TModCriticalSection.SafeEnter('+IntToStr(FEntryCode)+')' ) );
        end;*)
        
        while (timeout < 2000) do begin
            inc(Timeout);
            Sleep(1);
            if FEntryCode = 0 then break;
        end;
        if (timeout >= 2000) then begin
           msg := 'TModCriticalSection.SafeEnter('+IntToStr(entryCode)+') blocking for > 1 Seconds. Slowpoke is SafeEnter('+IntToStr(Self.FEntryCode)+')';
           //{$ifdef DEBUG_ASSERTIONS}
              raise Exception.Create(msg);
           //{$else}
           //   OutputDebugString(PChar('ModbusThread.pas: '+msg));
           //{$endif}
           //break;
        end;
    end;
    //inherited Enter;
    FSection.Enter;
    OutputDebugString(PChar('SafeEnter('+IntToStr(entrycode)+') ok.'));  //XXX
    FEntrycode := entrycode;

end;

procedure TModCriticalSection.Leave;
begin
  Inc(FLastLeavingIndex);
  if (FLastLeavingIndex>=8) then
      FLastLeavingIndex := 0;
  FLastLeaving[FLastLeavingIndex] := FEntryCode;

 if (FEntryCode=0) then
    raise TComPortModbusMasterThreadException.Create('Critical section warning: Unexpected leave of critical section!');

  FLastEntryCode := FEntryCode;

  OutputDebugString(PChar('Leave('+IntToStr(FEntryCode)+') ok.')); //XXX
  FEntryCode := 0;
  FSection.Leave;


end;
{$endif}

end.
