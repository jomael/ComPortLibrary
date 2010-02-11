(******************************************************
 * ComPort Library ver. 4.0                           *
 *   for Delphi 3, 4, 5, 6, 7 and                     *
 *   C++ Builder 3, 4, 5, 6                           *
 * written by Dejan Crnila, 1998 - 2002               *
 * maintained by Lars B. Dybdahl, 2003                *
 * Homepage: http://comport.sf.net/                   *
 *                                                    *
 * Fixed up for Delphi 2009 by W.Postma.  Oct 2008    *
 * Many significant internal changes.                 *
 *                                                    *
 * Supports Overlapped and non-Overlapped Win32 IO    *
 *****************************************************)

 { The main TComPort component is defined in this unit. }

unit CPort;

{$I CPort.inc}
{$R-}
{$Q-}

interface

uses
  Windows, Messages, Classes, SysUtils, IniFiles, Registry, CPortTypes;

type

  // TComPort component and asistant classes

  TCustomComPort = class; // forward declaration

  // class that links TCustomComPort events to other components
  TComLink = class
  private
    FOnConn: TComSignalEvent;
    FOnRxBuf: TRxBufEvent;
    FOnTxBuf: TRxBufEvent;
    FOnTxEmpty: TNotifyEvent;
    FOnRxFlag: TNotifyEvent;
    FOnCTSChange: TComSignalEvent;
    FOnDSRChange: TComSignalEvent;
    FOnRLSDChange: TComSignalEvent;
    FOnRing: TNotifyEvent;
    FOnTx: TComSignalEvent;
    FOnRx: TComSignalEvent;
  public
    property OnConn: TComSignalEvent read FOnConn write FOnConn;
    property OnRxBuf: TRxBufEvent read FOnRxBuf write FOnRxBuf;
    property OnTxBuf: TRxBufEvent read FOnTxBuf write FOnTxBuf;
    property OnTxEmpty: TNotifyEvent read FOnTxEmpty write FOnTxEmpty;
    property OnRxFlag: TNotifyEvent read FOnRxFlag write FOnRxFlag;
    property OnCTSChange: TComSignalEvent read FOnCTSChange write FOnCTSChange;
    property OnDSRChange: TComSignalEvent read FOnDSRChange write FOnDSRChange;
    property OnRLSDChange: TComSignalEvent
      read FOnRLSDChange write FOnRLSDChange;
    property OnRing: TNotifyEvent read FOnRing write FOnRing;
    property OnTx: TComSignalEvent read FOnTx write FOnTx;
    property OnRx: TComSignalEvent read FOnRx write FOnRx;
  end;

  // thread for background monitoring of port events
  TComThread = class(TThread)
  private
    FComPort: TCustomComPort;
    FStopEvent: THandle;
    FEvents: TComEvents;
  protected
    procedure DispatchComMsg;
    procedure DoEvents;
    procedure Execute; override;
    procedure SendEvents;
    procedure Stop;
  public
    constructor Create(AComPort: TCustomComPort);
    destructor Destroy; override;
  end;

  // timoeout properties for read/write operations
  TComTimeouts = class(TPersistent)
  private
    FComPort: TCustomComPort;
    FReadInterval: Integer;
    FReadTotalM: Integer;
    FReadTotalC: Integer;
    FWriteTotalM: Integer;
    FWriteTotalC: Integer;
    procedure SetComPort(const AComPort: TCustomComPort);
    procedure SetReadInterval(const Value: Integer);
    procedure SetReadTotalM(const Value: Integer);
    procedure SetReadTotalC(const Value: Integer);
    procedure SetWriteTotalM(const Value: Integer);
    procedure SetWriteTotalC(const Value: Integer);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    property ComPort: TCustomComPort read FComPort;
  published
    property ReadInterval: Integer read FReadInterval write SetReadInterval default -1;
    property ReadTotalMultiplier: Integer read FReadTotalM write SetReadTotalM default 0;
    property ReadTotalConstant: Integer read FReadTotalC write SetReadTotalC default 0;
    property WriteTotalMultiplier: Integer
      read FWriteTotalM write SetWriteTotalM default 100;
    property WriteTotalConstant: Integer
      read FWriteTotalC write SetWriteTotalC default 1000;
  end;

  // flow control settings
  TComFlowControl = class(TPersistent)
  private
    FComPort: TCustomComPort;
    FOutCTSFlow: Boolean;
    FOutDSRFlow: Boolean;
    FControlDTR: TDTRFlowControl;
    FControlRTS: TRTSFlowControl;
    FXonXoffOut: Boolean;
    FXonXoffIn:  Boolean;
    FDSRSensitivity: Boolean;
    FTxContinueOnXoff: Boolean;
    FXonChar: TCPortChar;
    FXoffChar: TCPortChar;
    procedure SetComPort(const AComPort: TCustomComPort);
    procedure SetOutCTSFlow(const Value: Boolean);
    procedure SetOutDSRFlow(const Value: Boolean);
    procedure SetControlDTR(const Value: TDTRFlowControl);
    procedure SetControlRTS(const Value: TRTSFlowControl);
    procedure SetXonXoffOut(const Value: Boolean);
    procedure SetXonXoffIn(const Value: Boolean);
    procedure SetDSRSensitivity(const Value: Boolean);
    procedure SetTxContinueOnXoff(const Value: Boolean);
    procedure SetXonChar(const Value: TCPortChar);
    procedure SetXoffChar(const Value: TCPortChar);
    procedure SetFlowControl(const Value: TFlowControl);
    function GetFlowControl: TFlowControl;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    property ComPort: TCustomComPort read FComPort;
  published
    property FlowControl: TFlowControl read GetFlowControl write SetFlowControl stored False;
    property OutCTSFlow: Boolean read FOutCTSFlow write SetOutCTSFlow;
    property OutDSRFlow: Boolean read FOutDSRFlow write SetOutDSRFlow;
    property ControlDTR: TDTRFlowControl read FControlDTR write SetControlDTR;
    property ControlRTS: TRTSFlowControl read FControlRTS write SetControlRTS;
    property XonXoffOut: Boolean read FXonXoffOut write SetXonXoffOut;
    property XonXoffIn:  Boolean read FXonXoffIn write SetXonXoffIn;
    property DSRSensitivity: Boolean
      read FDSRSensitivity write SetDSRSensitivity default False;
    property TxContinueOnXoff: Boolean
      read FTxContinueOnXoff write SetTxContinueOnXoff default False;
    property XonChar: TCPortChar read FXonChar write SetXonChar default #17;
    property XoffChar: TCPortChar read FXoffChar write SetXoffChar default #19;
  end;

  // parity settings
  TComParity = class(TPersistent)
  private
    FComPort: TCustomComPort;
    FBits: TParityBits;
    FCheck: Boolean;
    FReplace: Boolean;
    FReplaceChar: TCPortChar;
    procedure SetComPort(const AComPort: TCustomComPort);
    procedure SetBits(const Value: TParityBits);
    procedure SetCheck(const Value: Boolean);
    procedure SetReplace(const Value: Boolean);
    procedure SetReplaceChar(const Value: TCPortChar);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    property ComPort: TCustomComPort read FComPort;
  published
    property Bits: TParityBits read FBits write SetBits;
    property Check: Boolean read FCheck write SetCheck default False;
    property Replace: Boolean read FReplace write SetReplace default False;
    property ReplaceChar: TCPortChar read FReplaceChar write SetReplaceChar default #0;
  end;

  // buffer size settings
  TComBuffer = class(TPersistent)
  private
    FComPort: TCustomComPort;
    FInputSize: Integer;
    FOutputSize: Integer;
    procedure SetComPort(const AComPort: TCustomComPort);
    procedure SetInputSize(const Value: Integer);
    procedure SetOutputSize(const Value: Integer);
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    property ComPort: TCustomComPort read FComPort;
  published
    property InputSize: Integer read FInputSize write SetInputSize default 1024;
    property OutputSize: Integer read FOutputSize write SetOutputSize default 1024;
  end;

  // main component
  TCustomComPort = class(TComponent)
  private
    FInputCountNotSupported :Boolean; // Special flag added by Warren to help debug a USB serial convertor problem.
    FEventThread: TComThread;
    FThreadCreated: Boolean;
    FHandle: THandle;
    FWindow: THandle;
    FUpdateCount: Integer;
    FLinks: TList;
    FTriggersOnRxChar: Boolean;
    FEventThreadPriority: TThreadPriority;
    FHasLink: Boolean;
    FConnected: Boolean;
    FBaudRate: TBaudRate;
    FCustomBaudRate: Integer;
    FPort: TPort;
    FStopBits: TStopBits;
    FDataBits: TDataBits;
    FDiscardNull: Boolean;
    FEventChar: TCPortChar;
    FEvents: TComEvents;
    FBuffer: TComBuffer;
    FParity: TComParity;
    FTimeouts: TComTimeouts;
    FFlowControl: TComFlowControl;
    FSyncMethod: TSyncMethod;
    FStoredProps: TStoredProps;
    FOnRxChar: TRxCharEvent;
    FOnRxBuf: TRxBufEvent;
    FOnTxEmpty: TNotifyEvent;
    FOnBreak: TNotifyEvent;
    FOnRing: TNotifyEvent;
    FOnCTSChange: TComSignalEvent;
    FOnDSRChange: TComSignalEvent;
    FOnRLSDChange: TComSignalEvent;
    FOnError: TComErrorEvent;
    FOnRxFlag: TNotifyEvent;
    FOnAfterOpen: TNotifyEvent;
    FOnAfterClose: TNotifyEvent;
    FOnBeforeOpen: TNotifyEvent;
    FOnBeforeClose: TNotifyEvent;
    FOnRx80Full: TNotifyEvent;
    // Warren added March 2005:
    FReadAsyncExceptionsEnabled:Boolean;
    FReadAsyncErrorCount:Integer;
    FReadAsyncLastError:DWORD;
    FSyncWriteErrors : Integer; // Error counter for Synchronous Writing (October 2008)
    FOverlapped  :Boolean; // True=classic mode, Write=simplified-non-overlapped-Win32-functionality
    FReadAsyncPtr: PCPortAsync;
    FWriteAsyncPtr: PCPortAsync;



    function GetTriggersOnRxChar: Boolean;
    procedure SetTriggersOnRxChar(const Value: Boolean);
    procedure SetConnected(const Value: Boolean);
    procedure SetBaudRate(const Value: TBaudRate);
    procedure SetCustomBaudRate(const Value: Integer);
    procedure SetPort(const Value: TPort);
    procedure SetStopBits(const Value: TStopBits);
    procedure SetDataBits(const Value: TDataBits);
    procedure SetDiscardNull(const Value: Boolean);
    procedure SetEventChar(const Value: TCPortChar);
    procedure SetSyncMethod(const Value: TSyncMethod);
    procedure SetEventThreadPriority(const Value: TThreadPriority);
    procedure SetParity(const Value: TComParity);
    procedure SetTimeouts(const Value: TComTimeouts);
    procedure SetBuffer(const Value: TComBuffer);
    procedure SetFlowControl(const Value: TComFlowControl);
    function HasLink: Boolean;
    procedure TxNotifyLink(const Buffer:PCPortAnsiChar; Count: Integer);
    procedure NotifyLink(FLinkEvent: TComLinkEvent);
    procedure SendSignalToLink(Signal: TComLinkEvent; OnOff: Boolean);
    procedure CheckSignals(Open: Boolean);
    procedure WindowMethod(var Message: TMessage);
    procedure CallAfterOpen;
    procedure CallAfterClose;
    procedure CallBeforeOpen;
    procedure CallBeforeClose;
    procedure CallRxChar;
    procedure CallTxEmpty;
    procedure CallBreak;
    procedure CallRing;
    procedure CallRxFlag;
    procedure CallCTSChange;
    procedure CallDSRChange;
    procedure CallError;
    procedure CallRLSDChange;
    procedure CallRx80Full;
    procedure SetOverlapped(const Value: Boolean);
  protected
    procedure Loaded; override;
    procedure DoAfterClose; dynamic;
    procedure DoAfterOpen; dynamic;
    procedure DoBeforeClose; dynamic;
    procedure DoBeforeOpen; dynamic;
    procedure DoRxChar(Count: Integer); dynamic;
    procedure DoRxBuf(const mBuffer:PCPortAnsiChar; Count: Integer); dynamic;
    procedure DoTxEmpty; dynamic;
    procedure DoBreak; dynamic;
    procedure DoRing; dynamic;
    procedure DoRxFlag; dynamic;
    procedure DoCTSChange(OnOff: Boolean); dynamic;
    procedure DoDSRChange(OnOff: Boolean); dynamic;
    procedure DoError(Errors: TComErrors); dynamic;
    procedure DoRLSDChange(OnOff: Boolean); dynamic;
    procedure DoRx80Full; dynamic;
    procedure StoreRegistry(Reg: TRegistry); virtual;
    procedure StoreIniFile(IniFile: TIniFile); virtual;
    procedure LoadRegistry(Reg: TRegistry); virtual;
    procedure LoadIniFile(IniFile: TIniFile); virtual;
    procedure CreateHandle; virtual;
    procedure DestroyHandle; virtual;
    procedure ApplyDCB; dynamic;
    procedure ApplyTimeouts; dynamic;
    procedure ApplyBuffer; dynamic;
    procedure SetupComPort; virtual;

    function _WriteStrWrapper(const Str: AnsiString): Integer; // perform synchronous write operation via Win32 overlapped IO API
    function _WriteAsyncWrapper(const mBuffer:PCPortAnsiChar; Count: Integer): Integer; // perform synchronous write operation using Win32 overlapped IO API

    function _SyncRead(Data: PAnsiChar; var aCount: Cardinal):Boolean; { Simple Synchronous Read Wrapper.   Overlapped must be false. }
    function _SyncWrite(Data: PAnsiChar; size: dword):Boolean;      { Simple Synchronous Write Wrapper. Overlapped must be false.  }



  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure StoreSettings(StoreType: TStoreType; StoreTo: string);
    procedure LoadSettings(StoreType: TStoreType; LoadFrom: string);
    procedure Open;
    procedure Close;
    procedure ShowSetupDialog;
    function InputCount: Integer;
    function OutputCount: Integer;
    function Signals: TComSignals;
    function StateFlags: TComStateFlags;
    procedure SetDTR(OnOff: Boolean);
    procedure SetRTS(OnOff: Boolean);
    procedure SetXonXoff(OnOff: Boolean);
    procedure SetBreak(OnOff: Boolean);
    procedure ClearBuffer(Input, Output: Boolean);
    function LastErrors: TComErrors;


    function Write(const mBuffer:PCPortAnsiChar; Count: Integer): Integer;

    function WriteStr(const Str: AnsiString): Integer;
    function Read(mBuffer:PCPortAnsiChar; Count: Integer): Integer;
    function ReadStr(var Str: AnsiString; Count: Integer): Integer;

    function WriteAsync(const Buffer:PCPortAnsiChar; Count: Integer;
      var AsyncPtr: PCPortAsync): Integer;
    function WriteStrAsync(const Str: AnsiString; var AsyncPtr: PCPortAsync): Integer;



    function ReadAsync(mBuffer:PCPortAnsiChar; Count: Integer;
      var AsyncPtr: PCPortAsync): Integer;

    function ReadStrAsync(var Str: AnsiString; Count: Integer; var AsyncPtr: PCPortAsync): Integer;

    function WaitForAsync(var AsyncPtr: PCPortAsync): Integer;
    function IsAsyncCompleted(AsyncPtr: PCPortAsync): Boolean;
    procedure WaitForEvent(var Events: TComEvents; StopEvent: THandle;
      Timeout: Integer);
    procedure AbortAllAsync;
    procedure TransmitChar(Ch: TCPortChar);
    procedure RegisterLink(AComLink: TComLink);
    procedure UnRegisterLink(AComLink: TComLink);
    property Handle: THandle read FHandle;
    property TriggersOnRxChar: Boolean
      read GetTriggersOnRxChar write SetTriggersOnRxChar;
    property EventThreadPriority: TThreadPriority
      read FEventThreadPriority write SetEventThreadPriority;
    property StoredProps: TStoredProps read FStoredProps write FStoredProps;
    property Connected: Boolean read FConnected write SetConnected default False;
    property BaudRate: TBaudRate read FBaudRate write SetBaudRate;
    property CustomBaudRate: Integer
      read FCustomBaudRate write SetCustomBaudRate;
    property Port: TPort read FPort write SetPort;
    property Parity: TComParity read FParity write SetParity;
    property StopBits: TStopBits read FStopBits write SetStopBits;
    property DataBits: TDataBits read FDataBits write SetDataBits;
    property DiscardNull: Boolean read FDiscardNull write SetDiscardNull default False;
    property EventChar: TCPortChar read FEventChar write SetEventChar default #0;
    property Events: TComEvents read FEvents write FEvents;
    property Buffer: TComBuffer read FBuffer write SetBuffer;
    property FlowControl: TComFlowControl
      read FFlowControl write SetFlowControl;
    property Timeouts: TComTimeouts read FTimeouts write SetTimeouts;
    property SyncMethod: TSyncMethod
      read FSyncMethod write SetSyncMethod default smThreadSync;

    property InputCountNotSupported : Boolean read FInputCountNotSupported write FInputCountNotSupported; // Special flag added by Warren to help debug a USB serial convertor problem.

    property OnAfterOpen: TNotifyEvent read FOnAfterOpen write FOnAfterOpen;
    property OnAfterClose: TNotifyEvent read FOnAfterClose write FOnAfterClose;
    property OnBeforeOpen: TNotifyEvent read FOnBeforeOpen write FOnBeforeOpen;
    property OnBeforeClose: TNotifyEvent
      read FOnBeforeClose write FOnBeforeClose;
    property OnRxChar: TRxCharEvent read FOnRxChar write FOnRxChar;
    property OnRxBuf: TRxBufEvent read FOnRxBuf write FOnRxBuf;
    property OnTxEmpty: TNotifyEvent read FOnTxEmpty write FOnTxEmpty;
    property OnBreak: TNotifyEvent read FOnBreak write FOnBreak;
    property OnRing: TNotifyEvent read FOnRing write FOnRing;
    property OnCTSChange: TComSignalEvent read FOnCTSChange write FOnCTSChange;
    property OnDSRChange: TComSignalEvent read FOnDSRChange write FOnDSRChange;
    property OnRLSDChange: TComSignalEvent
      read FOnRLSDChange write FOnRLSDChange;
    property OnRxFlag: TNotifyEvent read FOnRxFlag write FOnRxFlag;
    property OnError: TComErrorEvent read FOnError write FOnError;
    property OnRx80Full: TNotifyEvent read FOnRx80Full write FOnRx80Full;

    // Warren added March 2005:
    property ReadAsyncExceptionsEnabled:Boolean read FReadAsyncExceptionsEnabled write FReadAsyncExceptionsEnabled;
    property ReadAsyncErrorCount:Integer read FReadAsyncErrorCount write FReadAsyncErrorCount;
    property ReadAsyncLastError:DWORD read FReadAsyncLastError write FReadAsyncLastError;

    property Overlapped  :Boolean read FOverlapped  write SetOverlapped; // True=classic mode, Write=simplified-non-overlapped-Win32-functionality (October 2008)

    property SyncWriteErrors : Integer read FSyncWriteErrors; // Error counter for Synchronous Writing (October 2008)

  end;

  // publish the properties
  TComPort = class(TCustomComPort)
    property Connected;
    property BaudRate;
    property Port;
    property Parity;
    property StopBits;
    property DataBits;
    property DiscardNull;
    property EventChar;
    property Events;
    property Buffer;
    property FlowControl;
    property Timeouts;
    property SyncMethod;
    property OnAfterOpen;
    property OnAfterClose;
    property OnBeforeOpen;
    property OnBeforeClose;
    property OnRxChar;
    property OnRxBuf;
    property OnTxEmpty;
    property OnBreak;
    property OnRing;
    property OnCTSChange;
    property OnDSRChange;
    property OnRLSDChange;
    property OnRxFlag;
    property OnError;
    property OnRx80Full;
  end;

  TComStrEvent = procedure(Sender: TObject; const Str: string) of object;
  TCustPacketEvent = procedure(Sender: TObject; const Str: string;
    var Pos: Integer) of object;

  // component for reading data in packets
  TComDataPacket = class(TComponent)
  private
    FComLink: TComLink;
    FComPort: TCustomComPort;
    FStartString: string;
    FStopString: string;
    FMaxBufferSize: Integer;
    FSize: Integer;
    FIncludeStrings: Boolean;
    FCaseInsensitive: Boolean;
    FInPacket: Boolean;
    FBuffer: AnsiString;
    FOnPacket: TComStrEvent;
    FOnDiscard: TComStrEvent;
    FOnCustomStart: TCustPacketEvent;
    FOnCustomStop: TCustPacketEvent;
    procedure SetComPort(const Value: TCustomComPort);
    procedure SetCaseInsensitive(const Value: Boolean);
    procedure SetSize(const Value: Integer);
    procedure SetStartString(const Value: string);
    procedure SetStopString(const Value: string);
    procedure RxBuf(Sender: TObject; const Buffer:PCPortAnsiChar; Count: Integer);
    procedure CheckIncludeStrings(var Str: AnsiString);
    function Upper(const Str: string): string;
    procedure EmptyBuffer;
    function ValidStop: Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoDiscard(const Str: string); dynamic;
    procedure DoPacket(const Str: string); dynamic;
    procedure DoCustomStart(const Str: string; var Pos: Integer); dynamic;
    procedure DoCustomStop(const Str: string; var Pos: Integer); dynamic;
    procedure HandleBuffer; virtual;
    property Buffer: AnsiString read FBuffer write FBuffer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddData(const Str: AnsiString);
  published
    property ComPort: TCustomComPort read FComPort write SetComPort;
    property CaseInsensitive: Boolean
      read FCaseInsensitive write SetCaseInsensitive default False;
    property IncludeStrings: Boolean read FIncludeStrings write FIncludeStrings default False;
    property MaxBufferSize: Integer read FMaxBufferSize write FMaxBufferSize default 1024;
    property StartString: string read FStartString write SetStartString;
    property StopString: string read FStopString write SetStopString;
    property Size: Integer read FSize write SetSize default 0;
    property OnDiscard: TComStrEvent read FOnDiscard write FOnDiscard;
    property OnPacket: TComStrEvent read FOnPacket write FOnPacket;
    property OnCustomStart: TCustPacketEvent
      read FOnCustomStart write FOnCustomStart;
    property OnCustomStop: TCustPacketEvent
      read FOnCustomStop write FOnCustomStop;
  end;

  // com port stream
  TComStream = class(TStream)
  private
    FComPort: TCustomComPort;
  public
    constructor Create(AComPort: TCustomComPort);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
  end;

  // exception class for ComPort Library errors
  EComPort = class(Exception)
  private
    FWinCode: Integer;
    FCode: Integer;
  public
    constructor Create(ACode: Integer; AWinCode: Integer; port:String);
    constructor CreateNoWinCode(ACode: Integer);
    property WinCode: Integer read FWinCode write FWinCode;
    property Code: Integer read FCode write FCode;
  end;

// aditional procedures
procedure CportInitAsync(var AsyncPtr: PCPortAsync);
procedure CportCleanupAsync(var AsyncPtr: PCPortAsync);
procedure EnumComPorts(Ports: TStrings);

// conversion functions
function StrToBaudRate(Str: string): TBaudRate;
function StrToStopBits(Str: string): TStopBits;
function StrToDataBits(Str: string): TDataBits;
function StrToParity(Str: string): TParityBits;
function StrToFlowControl(Str: string): TFlowControl;
function BaudRateToStr(BaudRate: TBaudRate): string;
function BaudRateToInt(BaudRate: TBaudRate): Integer;
function StopBitsToStr(StopBits: TStopBits): string;
function DataBitsToStr(DataBits: TDataBits): string;
function ParityToStr(Parity: TParityBits): string;
function FlowControlToStr(FlowControl: TFlowControl): string;

const
  // infinite wait
  WaitInfinite = Integer(INFINITE);

  // error codes
  CError_OpenFailed      = 1;
  CError_WriteFailed     = 2;
  CError_ReadFailed      = 3;
  CError_InvalidAsync    = 4;
  CError_PurgeFailed     = 5;
  CError_AsyncCheck      = 6;
  CError_SetStateFailed  = 7;
  CError_TimeoutsFailed  = 8;
  CError_SetupComFailed  = 9;
  CError_ClearComFailed  = 10;
  CError_ModemStatFailed = 11;
  CError_EscapeComFailed = 12;
  CError_TransmitFailed  = 13;
  CError_ConnChangeProp  = 14;
  CError_EnumPortsFailed = 15;
  CError_StoreFailed     = 16;
  CError_LoadFailed      = 17;
  CError_RegFailed       = 18;
  CError_LedStateFailed  = 19;
  CError_ThreadCreated   = 20;
  CError_WaitFailed      = 21;
  CError_HasLink         = 22;
  CError_RegError        = 23;

function ComErrorMessage(index:Integer):String;

implementation

uses
  CPortSetup, Controls, Forms, WinSpool;

  //gnugettext;

//var
  // error messages
//  ComErrorMessages: array[1..23] of widestring;

const
  // auxilary constants used not defined in windows.pas
  dcb_Binary           = $00000001;
  dcb_Parity           = $00000002;
  dcb_OutxCTSFlow      = $00000004;
  dcb_OutxDSRFlow      = $00000008;
  dcb_DTRControl       = $00000030;
  dcb_DSRSensivity     = $00000040;
  dcb_TxContinueOnXoff = $00000080;
  dcb_OutX             = $00000100;
  dcb_InX              = $00000200;
  dcb_ErrorChar        = $00000400;
  dcb_Null             = $00000800;
  dcb_RTSControl       = $00003000;
  dcb_AbortOnError     = $00004000;

  // com port window message
  CM_COMPORT           = WM_USER + 1;

(*****************************************
 * auxilary functions and procedures     *
 *****************************************)

function ComErrorMessage(index:Integer):String;
begin
 case index of 
  1: result := 'Unable to open com port';
  2: result := 'WriteFile function failed';
  3: result := 'ReadFile function failed';
  4: result := 'Invalid Async parameter';
  5: result := 'PurgeComm function failed';
  6: result := 'Unable to get async status';
  7: result := 'SetCommState function failed';
  8: result := 'SetCommTimeouts failed';
  9: result := 'SetupComm function failed';
  10: result := 'ClearCommError function failed';
  11: result := 'GetCommModemStatus function failed';
  12: result := 'EscapeCommFunction function failed';
  13: result := 'TransmitCommChar function failed';
  14: result := 'Cannot set property while connected';
  15: result := 'EnumPorts function failed';
  16: result := 'Failed to store settings';
  17: result := 'Failed to load settings';
  18: result := 'Link (un)registration failed';
  19: result := 'Cannot change led state if ComPort is selected';
  20: result := 'Cannot wait for event if event thread is created';
  21: result := 'WaitForEvent method failed';
  22: result := 'A component is linked to OnRxBuf event';
  23: result := 'Registry error';
  else
    result := 'Unknown Error #'+IntToStr(index)
  end;
end;


{$ifdef CPORT_CALLTRACE}
 {$O-}
// Return elapsed ticks between tick1 and tick2.
function TimerElapsed(tick1,tick2:DWORD):DWORD;
begin
  if ((tick2-tick1) < $80000000) then { timer roll-over check }
      result := (tick2 - tick1) { normal }
  else
      result := (not tick1)+tick2; {rollover calculation}
end;
{$endif}


// converts TComEvents type to Integer
function EventsToInt(const Events: TComEvents): Integer;
begin
  Result := 0;
  if evRxChar in Events then
    Result := Result or EV_RXCHAR;
  if evRxFlag in Events then
    Result := Result or EV_RXFLAG;
  if evTxEmpty in Events then
    Result := Result or EV_TXEMPTY;
  if evRing in Events then
    Result := Result or EV_RING;
  if evCTS in Events then
    Result := Result or EV_CTS;
  if evDSR in Events then
    Result := Result or EV_DSR;
  if evRLSD in Events then
    Result := Result or EV_RLSD;
  if evError in Events then
    Result := Result or EV_ERR;
  if evBreak in Events then
    Result := Result or EV_BREAK;
  if evRx80Full in Events then
    Result := Result or EV_RX80FULL;
end;

function IntToEvents(Mask: Integer): TComEvents;
begin
  Result := [];
  if (EV_RXCHAR and Mask) <> 0 then
    Result := Result + [evRxChar];
  if (EV_TXEMPTY and Mask) <> 0 then
    Result := Result + [evTxEmpty];
  if (EV_BREAK and Mask) <> 0 then
    Result := Result + [evBreak];
  if (EV_RING and Mask) <> 0 then
    Result := Result + [evRing];
  if (EV_CTS and Mask) <> 0 then
    Result := Result + [evCTS];
  if (EV_DSR and Mask) <> 0 then
    Result := Result + [evDSR];
  if (EV_RXFLAG and Mask) <> 0 then
    Result := Result + [evRxFlag];
  if (EV_RLSD and Mask) <> 0 then
    Result := Result + [evRLSD];
  if (EV_ERR and Mask) <> 0 then
    Result := Result + [evError];
  if (EV_RX80FULL and Mask) <> 0 then
    Result := Result + [evRx80Full];
end;




(*****************************************
 * other procedures/functions            *
 *****************************************)

// initialization of PCPortAsync variables used in asynchronous calls
procedure CportInitAsync(var AsyncPtr: PCPortAsync);
begin
 if not Assigned(AsyncPtr) then begin
  New(AsyncPtr);
  with AsyncPtr^ do
  begin
    FillChar(Overlapped, SizeOf(TOverlapped), 0);
    Overlapped.hEvent := CreateEvent(nil, True, True, nil);
    Data := nil;
    Size := 0;
  end;
 end;
end;



// clean-up of PCPortAsync variable
procedure CportCleanupAsync(var AsyncPtr: PCPortAsync);
begin
  if Assigned(AsyncPtr) then begin
    with AsyncPtr^ do
    begin
      CloseHandle(Overlapped.hEvent);
      if Data <> nil then
        FreeMem(Data);
    end;
    Dispose(AsyncPtr);
    AsyncPtr := nil;
  end;
end;


// prepare PCPortAsync variable for read/write operation
procedure CPortPrepareAsync(AKind: TOperationKind; const Buffer:PCPortAnsiChar;
  Count: Integer; AsyncPtr: PCPortAsync);
begin
 Assert(Assigned(AsyncPtr));

  with AsyncPtr^ do
  begin
    Kind := AKind;
    if Data <> nil then
      FreeMem(Data);
    GetMem(Data, Count);
    if Assigned(Buffer) then
        Move(Buffer^, Data^, Count);
    Size := Count;
  end;
end;


procedure EnumComPorts(Ports: TStrings);
var
  KeyHandle: HKEY;
  ErrCode, Index: Integer;
  ValueName, Data: string;
  ValueLen, DataLen, ValueType: DWORD;
  TmpPorts: TStringList;
begin
  ErrCode := RegOpenKeyEx(
    HKEY_LOCAL_MACHINE,
    'HARDWARE\DEVICEMAP\SERIALCOMM',
    0,
    KEY_READ,
    KeyHandle);

  if ErrCode <> ERROR_SUCCESS then
    raise EComPort.Create(CError_RegError, ErrCode, 'registry read');

  TmpPorts := TStringList.Create;
  try
    Index := 0;
    repeat
      ValueLen := 256;
      DataLen := 256;
      SetLength(ValueName, ValueLen);
      SetLength(Data, DataLen);
      ErrCode := RegEnumValue(
        KeyHandle,
        Index,
        PChar(ValueName),
{$IFDEF DELPHI_4_OR_HIGHER}
        Cardinal(ValueLen),
{$ELSE}
        ValueLen,
{$ENDIF}
        nil,
        @ValueType,
        PByte(PChar(Data)),
        @DataLen);

      if ErrCode = ERROR_SUCCESS then
      begin
        SetLength(Data, DataLen);
        TmpPorts.Add(Data);
        Inc(Index);
      end
      else
        if ErrCode <> ERROR_NO_MORE_ITEMS then
          raise EComPort.Create(CError_RegError, ErrCode, 'registry read');

    until (ErrCode <> ERROR_SUCCESS) ;

    TmpPorts.Sort;
    Ports.Assign(TmpPorts);
  finally
    RegCloseKey(KeyHandle);
    TmpPorts.Free;
  end;

end;

// string to baud rate
function StrToBaudRate(Str: string): TBaudRate;
var
  I: TBaudRate;
begin
  I := Low(TBaudRate);
  while (I <= High(TBaudRate)) do
  begin
    if UpperCase(Str) = UpperCase(BaudRateToStr(TBaudRate(I))) then
      Break;
    I := Succ(I);
  end;
  if I > High(TBaudRate) then
    Result := br9600
  else
    Result := I;
end;

// string to stop bits
function StrToStopBits(Str: string): TStopBits;
var
  I: TStopBits;
begin
  I := Low(TStopBits);
  while (I <= High(TStopBits)) do
  begin
    if UpperCase(Str) = UpperCase(StopBitsToStr(TStopBits(I))) then
      Break;
    I := Succ(I);
  end;
  if I > High(TStopBits) then
    Result := sbOneStopBit
  else
    Result := I;
end;

// string to data bits
function StrToDataBits(Str: string): TDataBits;
var
  I: TDataBits;
begin
  I := Low(TDataBits);
  while (I <= High(TDataBits)) do
  begin
    if UpperCase(Str) = UpperCase(DataBitsToStr(I)) then
      Break;
    I := Succ(I);
  end;
  if I > High(TDataBits) then
    Result := dbEight
  else
    Result := I;
end;

// string to parity
function StrToParity(Str: string): TParityBits;
var
  I: TParityBits;
begin
  I := Low(TParityBits);
  while (I <= High(TParityBits)) do
  begin
    if UpperCase(Str) = UpperCase(ParityToStr(I)) then
      Break;
    I := Succ(I);
  end;
  if I > High(TParityBits) then
    Result := prNone
  else
    Result := I;
end;

// string to flow control
function StrToFlowControl(Str: string): TFlowControl;
var
  I: TFlowControl;
begin
  I := Low(TFlowControl);
  while (I <= High(TFlowControl)) do
  begin
    if UpperCase(Str) = UpperCase(FlowControlToStr(I)) then
      Break;
    I := Succ(I);
  end;
  if I > High(TFlowControl) then
    Result := fcCustom
  else
    Result := I;
end;

// baud rate to string
function BaudRateToStr(BaudRate: TBaudRate): string;
const
  BaudRateStrings: array[TBaudRate] of string = ('Custom', '110', '300', '600',
    '1200', '2400', '4800', '9600', '14400', '19200', '38400', '56000', '57600',
    '115200', '128000', '256000');
begin
  Result := BaudRateStrings[BaudRate];
end;


function BaudRateToInt(BaudRate: TBaudRate): Integer;
const
  BaudRateInts: array[TBaudRate] of Integer = (0, 110, 300, 600,
    1200, 2400, 4800, 9600, 14400, 19200, 38400, 56000, 57600,
    115200, 128000, 256000 );
begin
  Result := BaudRateInts[BaudRate];
end;


// stop bits to string
function StopBitsToStr(StopBits: TStopBits): string;
const
  StopBitsStrings: array[TStopBits] of string = ('1', '1.5', '2');
begin
  Result := StopBitsStrings[StopBits];
end;

// data bits to string
function DataBitsToStr(DataBits: TDataBits): string;
const
  DataBitsStrings: array[TDataBits] of string = ('5', '6', '7', '8');
begin
  Result := DataBitsStrings[DataBits];
end;

// parity to string
function ParityToStr(Parity: TParityBits): string;
const
  ParityBitsStrings: array[TParityBits] of string = ('None', 'Odd', 'Even',
    'Mark', 'Space');
begin
  Result := ParityBitsStrings[Parity];
end;

// flow control to string
function FlowControlToStr(FlowControl: TFlowControl): string;
const
  FlowControlStrings: array[TFlowControl] of string = ('Hardware',
    'Software', 'None', 'Custom');
begin
  Result := FlowControlStrings[FlowControl];
end;

{initialization
  AddDomainForResourceString('cport');
  ComErrorMessages[1]:=_('Unable to open com port');
  ComErrorMessages[2]:=_('WriteFile function failed');
  ComErrorMessages[3]:=_('ReadFile function failed');
  ComErrorMessages[4]:=_('Invalid Async parameter');
  ComErrorMessages[5]:=_('PurgeComm function failed');
  ComErrorMessages[6]:=_('Unable to get async status');
  ComErrorMessages[7]:=_('SetCommState function failed');
  ComErrorMessages[8]:=_('SetCommTimeouts failed');
  ComErrorMessages[9]:=_('SetupComm function failed');
  ComErrorMessages[10]:=_('ClearCommError function failed');
  ComErrorMessages[11]:=_('GetCommModemStatus function failed');
  ComErrorMessages[12]:=_('EscapeCommFunction function failed');
  ComErrorMessages[13]:=_('TransmitCommChar function failed');
  ComErrorMessages[14]:=_('Cannot set property while connected');
  ComErrorMessages[15]:=_('EnumPorts function failed');
  ComErrorMessages[16]:=_('Failed to store settings');
  ComErrorMessages[17]:=_('Failed to load settings');
  ComErrorMessages[18]:=_('Link (un)registration failed');
  ComErrorMessages[19]:=_('Cannot change led state if ComPort is selected');
  ComErrorMessages[20]:=_('Cannot wait for event if event thread is created');
  ComErrorMessages[21]:=_('WaitForEvent method failed');
  ComErrorMessages[22]:=_('A component is linked to OnRxBuf event');
  ComErrorMessages[23]:=_('Registry error');
}


(*****************************************
 * TComThread class                      *
 *****************************************)

// create thread
constructor TComThread.Create(AComPort: TCustomComPort);
begin
// On delphi 2009 and up, we just create it without suspending, since it doesn't actually
// run until after Create is finished.
  inherited Create({$ifdef UNICODE}false{$else}True{$endif});
  FStopEvent := CreateEvent(nil, True, False, nil);
  FComPort := AComPort;
  // set thread priority
  Priority := FComPort.EventThreadPriority;
  // select which events are monitored
  SetCommMask(FComPort.Handle, EventsToInt(FComPort.Events));

  // we can use Resume to start the thread now in non-unicode versions, but
  // to avoid compiler warnings we are avoiding this method in the unicode
  // delphi versions. Thus the constructor above is called Create(false) to
  // avoid the need for this resume.  TTHread is an wart-covered piece of crap, but
  // it's all we have.
{$ifndef UNICODE}
  Resume;
{$endif}
end;

// destroy thread
destructor TComThread.Destroy;
begin
  Stop;
  inherited Destroy;
end;

// thread action
procedure TComThread.Execute;
var
  EventHandles: array[0..1] of THandle;
  Overlapped: TOverlapped;
  Signaled, BytesTrans, Mask: DWORD;
begin

  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, True, nil);
  EventHandles[0] := FStopEvent;
  EventHandles[1] := Overlapped.hEvent;
  repeat
    // wait for event to occur on serial port
    WaitCommEvent(FComPort.Handle, Mask, @Overlapped);
    Signaled := WaitForMultipleObjects(2, @EventHandles, False, INFINITE);
    // if event occurs, dispatch it
    if (Signaled = WAIT_OBJECT_0 + 1)
      and GetOverlappedResult(FComPort.Handle, Overlapped, BytesTrans, False)
    then
    begin
      FEvents := IntToEvents(Mask);
      DispatchComMsg;
    end;
  until Signaled <> (WAIT_OBJECT_0 + 1);
  // clear buffers
  SetCommMask(FComPort.Handle, 0);
  PurgeComm(FComPort.Handle, PURGE_TXCLEAR or PURGE_RXCLEAR);
  CloseHandle(Overlapped.hEvent);
  CloseHandle(FStopEvent);
end;

// stop thread
procedure TComThread.Stop;
begin
  SetEvent(FStopEvent);
  Sleep(0);
end;

// dispatch events
procedure TComThread.DispatchComMsg;
begin
  case FComPort.SyncMethod of
    smThreadSync:
          begin
                    Synchronize(DoEvents); // call events in main thread
          end;
    smWindowSync: SendEvents; // call events in thread that opened the port
    smNone:       DoEvents; // call events inside monitoring thread
    smDisableEvents:  // do nothing.

  end;
end;

// send events to TCustomComPort component using window message
procedure TComThread.SendEvents;
begin
  if evError in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_ERR, 0);
  if evRxChar in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_RXCHAR, 0);
  if evTxEmpty in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_TXEMPTY, 0);
  if evBreak in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_BREAK, 0);
  if evRing in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_RING, 0);
  if evCTS in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_CTS, 0);
  if evDSR in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_DSR, 0);
  if evRxFlag in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_RXFLAG, 0);
  if evRing in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_RLSD, 0);
  if evRx80Full in FEvents then
    SendMessage(FComPort.FWindow, CM_COMPORT, EV_RX80FULL, 0);
end;

// call events
procedure TComThread.DoEvents;
begin
  if evError in FEvents then
    FComPort.CallError;
  if evRxChar in FEvents then
    FComPort.CallRxChar;
  if evTxEmpty in FEvents then
    FComPort.CallTxEmpty;
  if evBreak in FEvents then
    FComPort.CallBreak;
  if evRing in FEvents then
    FComPort.CallRing;
  if evCTS in FEvents then
    FComPort.CallCTSChange;
  if evDSR in FEvents then
    FComPort.CallDSRChange;
  if evRxFlag in FEvents then
    FComPort.CallRxFlag;
  if evRLSD in FEvents then
    FComPort.CallRLSDChange;
  if evRx80Full in FEvents then
    FComPort.CallRx80Full;
end;

(*****************************************
 * TComTimeouts class                    *
 *****************************************)

// create class
constructor TComTimeouts.Create;
begin
  inherited Create;
  FReadInterval := -1;
  FWriteTotalM := 100;
  FWriteTotalC := 1000;
end;

// copy properties to other class
procedure TComTimeouts.AssignTo(Dest: TPersistent);
begin
  if Dest is TComTimeouts then
  begin
    with TComTimeouts(Dest) do
    begin
      FReadInterval := Self.ReadInterval;
      FReadTotalM   := Self.ReadTotalMultiplier;
      FReadTotalC   := Self.ReadTotalConstant;
      FWriteTotalM  := Self.WriteTotalMultiplier;
      FWriteTotalC  := Self.WriteTotalConstant;
    end
  end
  else
    inherited AssignTo(Dest);
end;

// select TCustomComPort to own this class
procedure TComTimeouts.SetComPort(const AComPort: TCustomComPort);
begin
  FComPort := AComPort;
end;

// set read interval
procedure TComTimeouts.SetReadInterval(const Value: Integer);
begin
  if Value <> FReadInterval then
  begin
    FReadInterval := Value;
    // if possible, apply the changes
    if FComPort <> nil then
      FComPort.ApplyTimeouts;
  end;
end;

// set read total constant
procedure TComTimeouts.SetReadTotalC(const Value: Integer);
begin
  if Value <> FReadTotalC then
  begin
    FReadTotalC := Value;
    if FComPort <> nil then
      FComPort.ApplyTimeouts;
  end;
end;

// set read total multiplier
procedure TComTimeouts.SetReadTotalM(const Value: Integer);
begin
  if Value <> FReadTotalM then
  begin
    FReadTotalM := Value;
    if FComPort <> nil then
      FComPort.ApplyTimeouts;
  end;
end;

// set write total constant
procedure TComTimeouts.SetWriteTotalC(const Value: Integer);
begin
  if Value <> FWriteTotalC then
  begin
    FWriteTotalC := Value;
    if FComPort <> nil then
      FComPort.ApplyTimeouts;
  end;
end;

// set write total multiplier
procedure TComTimeouts.SetWriteTotalM(const Value: Integer);
begin
  if Value <> FWriteTotalM then
  begin
    FWriteTotalM := Value;
    if FComPort <> nil then
      FComPort.ApplyTimeouts;
  end;
end;

(*****************************************
 * TComFlowControl class                 *
 *****************************************)

// create class
constructor TComFlowControl.Create;
begin
  inherited Create;
  FXonChar := #17;
  FXoffChar := #19;
end;

// copy properties to other class
procedure TComFlowControl.AssignTo(Dest: TPersistent);
begin
  if Dest is TComFlowControl then
  begin
    with TComFlowControl(Dest) do
    begin
      FOutCTSFlow       := Self.OutCTSFlow;
      FOutDSRFlow       := Self.OutDSRFlow;
      FControlDTR       := Self.ControlDTR;
      FControlRTS       := Self.ControlRTS;
      FXonXoffOut       := Self.XonXoffOut;
      FXonXoffIn        := Self.XonXoffIn;
      FTxContinueOnXoff := Self.TxContinueOnXoff;
      FDSRSensitivity   := Self.DSRSensitivity;
      FXonChar          := Self.XonChar;
      FXoffChar         := Self.XoffChar;
    end
  end
  else
    inherited AssignTo(Dest);
end;

// select TCustomComPort to own this class
procedure TComFlowControl.SetComPort(const AComPort: TCustomComPort);
begin
  FComPort := AComPort;
end;

// set input flow control for DTR (data-terminal-ready)
procedure TComFlowControl.SetControlDTR(const Value: TDTRFlowControl);
begin
  if Value <> FControlDTR then
  begin
    FControlDTR := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set input flow control for RTS (request-to-send)
procedure TComFlowControl.SetControlRTS(const Value: TRTSFlowControl);
begin
  if Value <> FControlRTS then
  begin
    FControlRTS := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set ouput flow control for CTS (clear-to-send)
procedure TComFlowControl.SetOutCTSFlow(const Value: Boolean);
begin
  if Value <> FOutCTSFlow then
  begin
    FOutCTSFlow := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set output flow control for DSR (data-set-ready)
procedure TComFlowControl.SetOutDSRFlow(const Value: Boolean);
begin
  if Value <> FOutDSRFlow then
  begin
    FOutDSRFlow := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set software input flow control
procedure TComFlowControl.SetXonXoffIn(const Value: Boolean);
begin
  if Value <> FXonXoffIn then
  begin
    FXonXoffIn := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set software ouput flow control
procedure TComFlowControl.SetXonXoffOut(const Value: Boolean);
begin
  if Value <> FXonXoffOut then
  begin
    FXonXoffOut := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set DSR sensitivity
procedure TComFlowControl.SetDSRSensitivity(const Value: Boolean);
begin
  if Value <> FDSRSensitivity then
  begin
    FDSRSensitivity := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set transfer continue when Xoff is sent
procedure TComFlowControl.SetTxContinueOnXoff(const Value: Boolean);
begin
  if Value <> FTxContinueOnXoff then
  begin
    FTxContinueOnXoff := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set Xon char
procedure TComFlowControl.SetXonChar(const Value: TCPortChar);
begin
  if Value <> FXonChar then
  begin
    FXonChar := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set Xoff char
procedure TComFlowControl.SetXoffChar(const Value: TCPortChar);
begin
  if Value <> FXoffChar then
  begin
    FXoffChar := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// get common flow control
function TComFlowControl.GetFlowControl: TFlowControl;
begin
  if (FControlRTS = rtsHandshake) and (FOutCTSFlow)
    and (not FXonXoffIn) and (not FXonXoffOut)
  then
    Result := fcHardware
  else
    if (FControlRTS = rtsDisable) and (not FOutCTSFlow)
      and (FXonXoffIn) and (FXonXoffOut)
    then
      Result := fcSoftware
    else
      if (FControlRTS = rtsDisable) and (not FOutCTSFlow)
        and (not FXonXoffIn) and (not FXonXoffOut)
      then
        Result := fcNone
      else
        Result := fcCustom;
end;

// set common flow control
procedure TComFlowControl.SetFlowControl(const Value: TFlowControl);
begin
  if Value <> fcCustom then
  begin
    FControlRTS := rtsDisable;
    FOutCTSFlow := False;
    FXonXoffIn := False;
    FXonXoffOut := False;
    case Value of
      fcHardware:
      begin
        FControlRTS := rtsHandshake;
        FOutCTSFlow := True;
      end;
      fcSoftware:
      begin
        FXonXoffIn := True;
        FXonXoffOut := True;
      end;
    end;
  end;
  if FComPort <> nil then
    FComPort.ApplyDCB;
end;

(*****************************************
 * TComParity class                      *
 *****************************************)

// create class
constructor TComParity.Create;
begin
  inherited Create;
  FBits := prNone;
end;

// copy properties to other class
procedure TComParity.AssignTo(Dest: TPersistent);
begin
  if Dest is TComParity then
  begin
    with TComParity(Dest) do
    begin
      FBits        := Self.Bits;
      FCheck       := Self.Check;
      FReplace     := Self.Replace;
      FReplaceChar := Self.ReplaceChar;
    end
  end
  else
    inherited AssignTo(Dest);
end;

// select TCustomComPort to own this class
procedure TComParity.SetComPort(const AComPort: TCustomComPort);
begin
  FComPort := AComPort;
end;

// set parity bits
procedure TComParity.SetBits(const Value: TParityBits);
begin
  if Value <> FBits then
  begin
    FBits := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set check parity
procedure TComParity.SetCheck(const Value: Boolean);
begin
  if Value <> FCheck then
  begin
    FCheck := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set replace on parity error
procedure TComParity.SetReplace(const Value: Boolean);
begin
  if Value <> FReplace then
  begin
    FReplace := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

// set replace char
procedure TComParity.SetReplaceChar(const Value: TCPortChar);
begin
  if Value <> FReplaceChar then
  begin
    FReplaceChar := Value;
    if FComPort <> nil then
      FComPort.ApplyDCB;
  end;
end;

(*****************************************
 * TComBuffer class                      *
 *****************************************)

// create class
constructor TComBuffer.Create;
begin
  inherited Create;
  FInputSize := 1024;
  FOutputSize := 1024;
end;

// copy properties to other class
procedure TComBuffer.AssignTo(Dest: TPersistent);
begin
  if Dest is TComBuffer then
  begin
    with TComBuffer(Dest) do
    begin
      FOutputSize  := Self.OutputSize;
      FInputSize   := Self.InputSize;
    end
  end
  else
    inherited AssignTo(Dest);
end;

// select TCustomComPort to own this class
procedure TComBuffer.SetComPort(const AComPort: TCustomComPort);
begin
  FComPort := AComPort;
end;

// set input size
procedure TComBuffer.SetInputSize(const Value: Integer);
begin
  if Value <> FInputSize then
  begin
    FInputSize := Value;
    if (FInputSize mod 2) = 1 then
      Dec(FInputSize);
    if FComPort <> nil then
      FComPort.ApplyBuffer;
  end;
end;

// set ouput size
procedure TComBuffer.SetOutputSize(const Value: Integer);
begin
  if Value <> FOutputSize then
  begin
    FOutputSize := Value;
    if (FOutputSize mod 2) = 1 then
      Dec(FOutputSize);
    if FComPort <> nil then
      FComPort.ApplyBuffer;
  end;
end;

(*****************************************
 * TCustomComPort component              *
 *****************************************)

// create component
constructor TCustomComPort.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // component cannot reside on inheritable forms
  FOverlapped  := true; // default value

  FComponentStyle := FComponentStyle - [csInheritable];
  FLinks := TList.Create;
  FTriggersOnRxChar := True;
  FEventThreadPriority := tpNormal;
  FBaudRate := br9600;
  FCustomBaudRate := 9600;
  FPort := 'COM1';
  FStopBits := sbOneStopBit;
  FDataBits := dbEight;
  FEvents := [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak,
             evCTS, evDSR, evError, evRLSD, evRx80Full];
  FHandle := INVALID_HANDLE_VALUE;
  FStoredProps := [spBasic];
  FParity := TComParity.Create;
  FParity.SetComPort(Self);
  FFlowControl := TComFlowControl.Create;
  FFlowControl.SetComPort(Self);
  FTimeouts := TComTimeouts.Create;
  FTimeouts.SetComPort(Self);
  FBuffer := TComBuffer.Create;
  FBuffer.SetComPort(Self);
end;

// destroy component
destructor TCustomComPort.Destroy;
begin
  Close;
  CportCleanupAsync(FReadAsyncPtr);
  CportCleanupAsync(FWriteAsyncPtr);
  FBuffer.Free;
  FFlowControl.Free;
  FTimeouts.Free;
  FParity.Free;
  FLinks.Free; // why was this AFTER destroy?
  inherited Destroy;

end;

// create handle to serial port
procedure TCustomComPort.CreateHandle;
var
 dev:String;
 flags:Cardinal;
begin
  dev :='\\.\' + FPort;

  if FOverlapped then  { This is a big change from classic TComPort }
      flags := FILE_FLAG_OVERLAPPED
  else
      flags := 0;

  FHandle := CreateFile(
    PChar(dev),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    flags,
    0);

  if FHandle = INVALID_HANDLE_VALUE then begin
    {$ifdef CPORT_CALLTRACE}
    OutputDebugString( PChar('CreateHandle: CreateFile '+dev));
    {$endif}
    raise EComPort.Create(CError_OpenFailed, GetLastError,FPort);
  end;
end;

// destroy serial port handle
procedure TCustomComPort.DestroyHandle;
begin
  if FHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FHandle);
end;

procedure TCustomComPort.Loaded;
begin
  inherited Loaded;
  // open port if Connected is True at design-time
  if FConnected and not (csDesigning in ComponentState) then
  begin
    FConnected := False;
    try
      Open;
    except
      Application.HandleException(Self);
    end;
  end;
end;

// call events which have been dispatch using window message
procedure TCustomComPort.WindowMethod(var Message: TMessage);
begin
  with Message do
    if Msg = CM_COMPORT then
      try
        if InSendMessage then
          ReplyMessage(0);
        if FConnected then
          case wParam of
            EV_RXCHAR:   CallRxChar;
            EV_TXEMPTY:  CallTxEmpty;
            EV_BREAK:    CallBreak;
            EV_RING:     CallRing;
            EV_CTS:      CallCTSChange;
            EV_DSR:      CallDSRChange;
            EV_RXFLAG:   CallRxFlag;
            EV_RLSD:     CallRLSDChange;
            EV_ERR:      CallError;
            EV_RX80FULL: CallRx80Full;
          end
      except
        Application.HandleException(Self);
      end
    else
      Result := DefWindowProc(FWindow, Msg, wParam, lParam);
end;

// prevent from applying changes at runtime
procedure TCustomComPort.BeginUpdate;
begin
  FUpdateCount := FUpdateCount + 1;
end;

// apply the changes made since BeginUpdate call
procedure TCustomComPort.EndUpdate;
begin
  if FUpdateCount > 0 then
  begin
    FUpdateCount := FUpdateCount - 1;
    if FUpdateCount = 0 then
      SetupComPort;
  end;
end;

// open port
procedure TCustomComPort.Open;
begin
  // if already connected, do nothing
  if not FConnected and not (csDesigning in ComponentState) then
  begin
    CallBeforeOpen;
    // open port
    CreateHandle;
    FConnected := True;
    try
      // initialize port
      SetupComPort;
    except
      // error occured during initialization, destroy handle
      DestroyHandle;
      FConnected := False;
      raise;
    end;
    // if at least one event is set, create special thread to monitor port
    if (FEvents = []) then
      FThreadCreated := False
    else
    begin
      if (FSyncMethod = smWindowSync) then
{$IFDEF DELPHI_6_OR_HIGHER}
  {$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}
        FWindow := AllocateHWnd(WindowMethod);
{$IFDEF DELPHI_6_OR_HIGHER}
  {$WARN SYMBOL_DEPRECATED ON}
{$ENDIF}
      if FOverlapped then begin
        FEventThread := TComThread.Create(Self); { thread is now optional! major change! }
        FThreadCreated := True;
      end;
    end;
    // port is succesfully opened, do any additional initialization
    CallAfterOpen;
  end;
end;

// close port
procedure TCustomComPort.Close;
begin
  // if already closed, do nothing
  if FConnected and not (csDesigning in ComponentState) then
  begin
    CallBeforeClose;
    // abort all pending operations
    AbortAllAsync;
    // stop monitoring for events
    if FThreadCreated then
    begin
      FEventThread.Free;
      FThreadCreated := False;
      if FSyncMethod = smWindowSync then
{$IFDEF DELPHI_6_OR_HIGHER}
  {$WARN SYMBOL_DEPRECATED OFF}
{$ENDIF}
        DeallocateHWnd(FWindow);
{$IFDEF DELPHI_6_OR_HIGHER}
  {$WARN SYMBOL_DEPRECATED ON}
{$ENDIF}
    end;
    // close port
    DestroyHandle;
    FConnected := False;
    // port is closed, do any additional finalization
    CallAfterClose;
  end;
end;

// apply port properties
procedure TCustomComPort.ApplyDCB;
const
  CParityBits: array[TParityBits] of Integer =
    (NOPARITY, ODDPARITY, EVENPARITY, MARKPARITY, SPACEPARITY);
  CStopBits: array[TStopBits] of Integer =
    (ONESTOPBIT, ONE5STOPBITS, TWOSTOPBITS);
  CBaudRate: array[TBaudRate] of Integer =
    (0, CBR_110, CBR_300, CBR_600, CBR_1200, CBR_2400, CBR_4800, CBR_9600,
     CBR_14400, CBR_19200, CBR_38400, CBR_56000, CBR_57600, CBR_115200,
     CBR_128000, CBR_256000);
  CDataBits: array[TDataBits] of Integer = (5, 6, 7, 8);
  CControlRTS: array[TRTSFlowControl] of Integer =
    (RTS_CONTROL_DISABLE shl 12,
     RTS_CONTROL_ENABLE shl 12,
     RTS_CONTROL_HANDSHAKE shl 12,
     RTS_CONTROL_TOGGLE shl 12);
  CControlDTR: array[TDTRFlowControl] of Integer =
    (DTR_CONTROL_DISABLE shl 4,
     DTR_CONTROL_ENABLE shl 4,
     DTR_CONTROL_HANDSHAKE shl 4);

var
  DCB: TDCB;

begin
  // if not connected or inside BeginUpdate/EndUpdate block, do nothing
  if FConnected and (FUpdateCount = 0) and
    not ((csDesigning in ComponentState) or (csLoading in ComponentState)) then
  begin
    DCB.DCBlength := SizeOf(TDCB);
    DCB.XonLim := FBuffer.InputSize div 4;
    DCB.XoffLim := DCB.XonLim;
    DCB.EvtChar := TCPortChar(FEventChar);

    DCB.Flags := dcb_Binary;
    if FDiscardNull then
      DCB.Flags := DCB.Flags or dcb_Null;

    with FFlowControl do
    begin
      DCB.XonChar := XonChar;
      DCB.XoffChar := XoffChar;
      if OutCTSFlow then
        DCB.Flags := DCB.Flags or dcb_OutxCTSFlow;
      if OutDSRFlow then
        DCB.Flags := DCB.Flags or dcb_OutxDSRFlow;
      DCB.Flags := DCB.Flags or CControlDTR[ControlDTR]
        or CControlRTS[ControlRTS];
      if XonXoffOut then
        DCB.Flags := DCB.Flags or dcb_OutX;
      if XonXoffIn then
        DCB.Flags := DCB.Flags or dcb_InX;
      if DSRSensitivity then
        DCB.Flags := DCB.Flags or dcb_DSRSensivity;
      if TxContinueOnXoff then
        DCB.Flags := DCB.Flags or dcb_TxContinueOnXoff;
    end;

    DCB.Parity := CParityBits[FParity.Bits];
    DCB.StopBits := CStopBits[FStopBits];
    if FBaudRate <> brCustom then
      DCB.BaudRate := CBaudRate[FBaudRate]
    else
      DCB.BaudRate := FCustomBaudRate;
    DCB.ByteSize := CDataBits[FDataBits];

    if FParity.Check then
    begin
      DCB.Flags := DCB.Flags or dcb_Parity;
      if FParity.Replace then
      begin
        DCB.Flags := DCB.Flags or dcb_ErrorChar;
        DCB.ErrorChar := TCPortChar(FParity.ReplaceChar);
      end;
    end;

    // apply settings
    if not SetCommState(FHandle, DCB) then
      raise EComPort.Create(CError_SetStateFailed, GetLastError,FPort);
  end;
end;

// apply timeout properties
procedure TCustomComPort.ApplyTimeouts;
var
  Timeouts: TCommTimeouts;

  function GetTOValue(const Value: Integer): DWORD;
  begin
    if Value = -1 then
      Result := MAXDWORD
    else
      Result := Value;
  end;

begin
  // if not connected or inside BeginUpdate/EndUpdate block, do nothing
  if FConnected and (FUpdateCount = 0) and
    not ((csDesigning in ComponentState) or (csLoading in ComponentState)) then
  begin
    Timeouts.ReadIntervalTimeout := GetTOValue(FTimeouts.ReadInterval);
    Timeouts.ReadTotalTimeoutMultiplier := GetTOValue(FTimeouts.ReadTotalMultiplier);
    Timeouts.ReadTotalTimeoutConstant := GetTOValue(FTimeouts.ReadTotalConstant);
    Timeouts.WriteTotalTimeoutMultiplier := GetTOValue(FTimeouts.WriteTotalMultiplier);
    Timeouts.WriteTotalTimeoutConstant := GetTOValue(FTimeouts.WriteTotalConstant);

    // apply settings
    if not SetCommTimeouts(FHandle, Timeouts) then
      raise EComPort.Create(CError_TimeoutsFailed, GetLastError, FPort);
  end;
end;

// apply buffers
procedure TCustomComPort.ApplyBuffer;
begin
  // if not connected or inside BeginUpdate/EndUpdate block, do nothing
  if FConnected and (FUpdateCount = 0) and
      not ((csDesigning in ComponentState) or (csLoading in ComponentState))
  then
    //apply settings
    if not SetupComm(FHandle, FBuffer.InputSize, FBuffer.OutputSize) then
      raise EComPort.Create(CError_SetupComFailed, GetLastError, FPort);
end;

// initialize port
procedure TCustomComPort.SetupComPort;
begin
  ApplyBuffer;
  ApplyDCB;
  ApplyTimeouts;
end;

// get number of bytes in input buffer
function TCustomComPort.InputCount: Integer;
var
  Errors: DWORD;
  ComStat: TComStat;
begin
  if FInputCountNotSupported then begin
      result := 0;
      exit;
  end;

  if not ClearCommError(FHandle, Errors, @ComStat) then
    raise EComPort.Create(CError_ClearComFailed, GetLastError, FPort);
  Result := ComStat.cbInQue;
end;

// get number of bytes in output buffer
function TCustomComPort.OutputCount: Integer;
var
  Errors: DWORD;
  ComStat: TComStat;
begin
  if not ClearCommError(FHandle, Errors, @ComStat) then
    raise EComPort.Create(CError_ClearComFailed, GetLastError, FPort);
  Result := ComStat.cbOutQue;
end;

// get signals which are in high state
function TCustomComPort.Signals: TComSignals;
var
  Status: DWORD;
begin
  if not FOverlapped then exit; { cannot read signals in non-overlapped mode }
  if not GetCommModemStatus(FHandle, Status) then
    raise EComPort.Create(CError_ModemStatFailed, GetLastError, FPort);
  Result := [];

  if (MS_CTS_ON and Status) <> 0 then
    Result := Result + [csCTS];
  if (MS_DSR_ON and Status) <> 0 then
    Result := Result + [csDSR];
  if (MS_RING_ON and Status) <> 0 then
    Result := Result + [csRing];
  if (MS_RLSD_ON and Status) <> 0 then
    Result := Result + [csRLSD];
end;

// get port state flags
function TCustomComPort.StateFlags: TComStateFlags;
var
  Errors: DWORD;
  ComStat: TComStat;
begin
  if not ClearCommError(FHandle, Errors, @ComStat) then
    raise EComPort.Create(CError_ClearComFailed, GetLastError,FPort);
  Result := ComStat.Flags;
end;

// set hardware line break
procedure TCustomComPort.SetBreak(OnOff: Boolean);
var
  Act: Integer;
begin
  if OnOff then
    Act := Windows.SETBREAK
  else
    Act := Windows.CLRBREAK;

  if not EscapeCommFunction(FHandle, Act) then
    raise EComPort.Create(CError_EscapeComFailed, GetLastError,FPort);
end;

// set DTR signal
procedure TCustomComPort.SetDTR(OnOff: Boolean);
var
  Act: DWORD;
begin
  if OnOff then
    Act := Windows.SETDTR
  else
    Act := Windows.CLRDTR;

  if not EscapeCommFunction(FHandle, Act) then
    raise EComPort.Create(CError_EscapeComFailed, GetLastError,FPort);
end;

// set RTS signals
procedure TCustomComPort.SetRTS(OnOff: Boolean);
var
  Act: DWORD;
begin
  if OnOff then
    Act := Windows.SETRTS
  else
    Act := Windows.CLRRTS;

  if not EscapeCommFunction(FHandle, Act) then
    raise EComPort.Create(CError_EscapeComFailed, GetLastError,FPort);
end;

// set XonXoff state
procedure TCustomComPort.SetXonXoff(OnOff: Boolean);
var
  Act: DWORD;
begin
  if OnOff then
    Act := Windows.SETXON
  else
    Act := Windows.SETXOFF;

  if not EscapeCommFunction(FHandle, Act) then
    raise EComPort.Create(CError_EscapeComFailed, GetLastError,FPort);
end;

// clear input and/or output buffer
procedure TCustomComPort.ClearBuffer(Input, Output: Boolean);
var
  Flag: DWORD;
begin
  Flag := 0;
  if Input then
    Flag := PURGE_RXCLEAR;
  if Output then
    Flag := Flag or PURGE_TXCLEAR;

  if not PurgeComm(FHandle, Flag) then
    raise EComPort.Create(CError_PurgeFailed, GetLastError,FPort);
end;

// return last errors on port
function TCustomComPort.LastErrors: TComErrors;
var
  Errors: DWORD;
  ComStat: TComStat;
begin
  if not ClearCommError(FHandle, Errors, @ComStat) then
    raise EComPort.Create(CError_ClearComFailed, GetLastError,FPort);
  Result := [];

  if (CE_FRAME and Errors) <> 0 then
    Result := Result + [ceFrame];
  if ((CE_RXPARITY and Errors) <> 0) and FParity.Check then // get around a bug
    Result := Result + [ceRxParity];
  if (CE_OVERRUN and Errors) <> 0 then
    Result := Result + [ceOverrun];
  if (CE_RXOVER and Errors) <> 0 then
    Result := Result + [ceRxOver];
  if (CE_TXFULL and Errors) <> 0 then
    Result := Result + [ceTxFull];
  if (CE_BREAK and Errors) <> 0 then
    Result := Result + [ceBreak];
  if (CE_IOE and Errors) <> 0 then
    Result := Result + [ceIO];
  if (CE_MODE and Errors) <> 0 then
    Result := Result + [ceMode];
end;

{ Simple Synchronous Read Wrapper }
function TCustomComPort._SyncRead(Data: PAnsiChar; var aCount: Cardinal):Boolean;
// In: aCount is the max size that can be handled by the caller.
// Out: aCount is the number of bytes written to Data.
begin
  if not FConnected then begin
      aCount := 0;
      result := false;
      exit;
  end;
  result := ReadFile(FHandle,Data^,aCount,aCount,nil);
end;

{ Simple Synchronous Write Wrapper }
function TCustomComPort._SyncWrite(Data: PAnsiChar; size: dword):Boolean;
var
  BytesWritten: DWord;
begin
  result := false;
  if not FConnected then exit;
  // Note the position of the caret (^). It compiles fine but doesn't work without "Buffer^"  
  result := WriteFile(FHandle,Data^,Size,BytesWritten,nil);
  if (not result) then
      Inc(FSyncWriteErrors);
end;


// perform asynchronous write operation
function TCustomComPort.WriteAsync(const Buffer:PCPortAnsiChar; Count: Integer; var AsyncPtr: PCPortAsync): Integer;
var
  Success : Boolean;
  Pending : Boolean;
  BytesTrans: DWORD;
begin
  if AsyncPtr = nil then
    raise EComPort.CreateNoWinCode(CError_InvalidAsync);
  CPortPrepareAsync(okWrite, Buffer, Count, AsyncPtr);

  Success := WriteFile(FHandle, Buffer^, Count, BytesTrans, @AsyncPtr^.Overlapped);
  Pending := (GetLastError = ERROR_IO_PENDING);

  if not (Success or Pending) then
    raise EComPort.Create(CError_WriteFailed, GetLastError,FPort);

  SendSignalToLink(leTx, True);
  Result := BytesTrans;
end;



// perform synchronous write operation using overlapped IO API.
function TCustomComPort._WriteAsyncWrapper(const mBuffer:PCPortAnsiChar; Count: Integer): Integer;
{$ifdef CPORT_CALLTRACE}
var
  Elapse,Tick1,Tick2:DWORD;
{$endif}
begin
{$ifdef CPORT_CALLTRACE}
  Tick1 := GetTickCount;
{$endif}

  CportInitAsync(FWriteAsyncPtr);

  WriteAsync(mBuffer, Count, FWriteAsyncPtr);
  Result := WaitForAsync(FWriteAsyncPtr);

{$ifdef CPORT_CALLTRACE}
  Tick2 := GetTickCount;
  Elapse := TimerElapsed(Tick1,Tick2);
  if Elapse>1000 then begin
    OutputDebugString( PChar('TCustomComPort.Write Elapse='+IntToStr(Elapse)+' ms') );
  end;
{$endif}
end;



// perform asynchronous write operation
function TCustomComPort.WriteStrAsync(const Str: AnsiString; var AsyncPtr: PCPortAsync): Integer;
begin
  if Length(Str) > 0 then
    Result := WriteAsync(  PCPortAnsiChar(Str) { @Str[1] }, Length(Str), AsyncPtr)
  else
    Result := 0;
end;

function TCustomComPort.WriteStr(const Str: AnsiString): Integer;
begin
  if FOverlapped then
      result := _WriteStrWrapper(Str)
  else begin
    result := 0;
    if _SyncWrite(PAnsiChar(Str),Length(Str)) then
        result := Length(Str);
  end;
end;

// perform synchronous write operation
function TCustomComPort._WriteStrWrapper(const Str: AnsiString): Integer;
begin
{$ifdef CPORT_CALLTRACE}
  OutputDebugString('TCustomComPort.WriteStr');
{$endif}

  CportInitAsync(FWriteAsyncPtr);
  WriteStrAsync(Str, FWriteAsyncPtr);
  Result := WaitForAsync(FWriteAsyncPtr);

end;


// perform asynchronous read operation
function TCustomComPort.ReadAsync( mBuffer:PCPortAnsiChar; Count: Integer; var AsyncPtr: PCPortAsync): Integer;
var
  Success: Boolean;
  BytesTrans: DWORD;
  lastErr:DWORD;
begin
  if AsyncPtr = nil then
    raise EComPort.CreateNoWinCode(CError_InvalidAsync);
  AsyncPtr^.Kind := okRead;
  BytesTrans := 0;
 // Success := false;
  //SetLength(Buffer,Count+1);
  mBuffer[0] := AnsiChar(0);


  // Note the non existent position of the caret (^) after Buffer. :-)
  //  It compiles either way.  Dunno why.
  Success := ReadFile( FHandle, {type:PAnsiChar}mBuffer^, Count, BytesTrans, @AsyncPtr^.Overlapped)
    or (GetLastError = ERROR_IO_PENDING);

  if not Success then begin
      lastErr := GetLastError;
      if FReadAsyncExceptionsEnabled then begin
          raise EComPort.Create(CError_ReadFailed, lastErr,FPort);
      end else begin
          Inc(FReadAsyncErrorCount);
          FReadAsyncLastError := lastErr;
          result := 0;
          exit;
      end;
  end;

  Result := BytesTrans;
end;

// perform pseudo-synchronous read operation using async layer underneath:
function TCustomComPort.Read(mBuffer:PCPortAnsiChar; Count: Integer): Integer;
begin
{$ifdef CPORT_CALLTRACE}
  OutputDebugString('TCustomComPort.Read');
{$endif}
 CportInitAsync( FReadAsyncPtr);
 ReadAsync( mBuffer, Count, FReadAsyncPtr);
 Result := WaitForAsync( FReadAsyncPtr);
end;

// DEPRECATED:
function TCustomComPort.ReadStrAsync(var Str: AnsiString; Count: Integer; var AsyncPtr: PCPortAsync): Integer;
begin
  SetLength(Str, Count);
  if Count > 0 then
    Result := ReadAsync( PCPortAnsiChar(Str), Count, AsyncPtr)
  else
    Result := 0;
end;
// perform pseudo-synchronous read operation using async underlying layer.
function TCustomComPort.ReadStr(var Str: AnsiString; Count: Integer): Integer;
begin
{$ifdef CPORT_CALLTRACE}
  OutputDebugString('TCustomComPort.ReadStr');
{$endif}

  CportInitAsync(FReadAsyncPtr);

  CPortPrepareAsync( okRead,nil,Count,FReadAsyncPtr);
//  try
    //ReadStrAsync(Str, Count, FReadAsyncPtr);
{    Result := }
    ReadAsync( FReadAsyncPtr.Data, Count, FReadAsyncPtr);



    Result := WaitForAsync(FReadAsyncPtr);
    //SetLength(Str, Result); { why is this happening duplicated? }

    if (Result>0) then
        SetString(Str, FReadAsyncPtr.Data, Result)
    else
        Str := '';

end;

function ErrorCode(AsyncPtr: PCPortAsync): Integer;
begin
  Result := 0;
  case AsyncPtr^.Kind of
    okWrite: Result := CError_WriteFailed;
    okRead:  Result := CError_ReadFailed;
  end;
end;

// wait for asynchronous operation to end
function TCustomComPort.WaitForAsync(var AsyncPtr: PCPortAsync): Integer;
var
  BytesTrans, Signaled: DWORD;
  Success: Boolean;
begin
  if AsyncPtr = nil then
    raise EComPort.CreateNoWinCode(CError_InvalidAsync);

  {$ifdef CPORT_CALLTRACE}
   OutputDebugString(PChar('TCustomComPort.WaitForAsync WaitForSingleObject '+      IntToHex(Integer(AsyncPtr^.Overlapped.hEvent),8)) );
  {$endif}

  Signaled := WaitForSingleObject(AsyncPtr^.Overlapped.hEvent, INFINITE);

  {$ifdef CPORT_CALLTRACE}
   OutputDebugString( PChar('TCustomComPort.WaitForAsync Signaled='+IntToStr(Signaled)) );
  {$endif}

  Success := (Signaled = WAIT_OBJECT_0) and
      (GetOverlappedResult(FHandle, AsyncPtr^.Overlapped, BytesTrans, False));

  if not Success then
    raise EComPort.Create(ErrorCode(AsyncPtr), GetLastError, FPort);

  if not FInputCountNotSupported then begin

    if (AsyncPtr^.Kind = okRead) and (InputCount = 0) then begin
    {$ifdef CPORT_CALLTRACE}
     OutputDebugString('TCustomComPort.WaitForAsync SendSignalToLink');
    {$endif}
      SendSignalToLink(leRx, False)
    end else
      if AsyncPtr^.Data <> nil then begin
        {$ifdef CPORT_CALLTRACE}
         OutputDebugString('TCustomComPort.WaitForAsync TxNotifyLink');
        {$endif}
        TxNotifyLink( PCPortAnsiChar( AsyncPtr^.Data), AsyncPtr^.Size);
      end;
      
  end;

  {$ifdef CPORT_CALLTRACE}
   OutputDebugString( PChar('TCustomComPort.WaitForAsync BytesTrans='+IntToStr(BytesTrans)) );
  {$endif}
  Result := BytesTrans;
end;

// abort all asynchronous operations
procedure TCustomComPort.AbortAllAsync;
begin
 if FOverlapped then
  if not PurgeComm(FHandle, PURGE_TXABORT or PURGE_RXABORT) then
    raise EComPort.Create(CError_PurgeFailed, GetLastError, FPort);
end;

// detect whether asynchronous operation is completed
function TCustomComPort.IsAsyncCompleted(AsyncPtr: PCPortAsync): Boolean;
var
  BytesTrans: DWORD;
begin
  if AsyncPtr = nil then
    raise EComPort.CreateNoWinCode(CError_InvalidAsync);

  Result := GetOverlappedResult(FHandle, AsyncPtr^.Overlapped, BytesTrans, False);
  if not Result then
    if (GetLastError <> ERROR_IO_PENDING) and (GetLastError <> ERROR_IO_INCOMPLETE) then
      raise EComPort.Create(CError_AsyncCheck, GetLastError, FPort);
end;

// waits for event to occur on serial port
procedure TCustomComPort.WaitForEvent(var Events: TComEvents;
  StopEvent: THandle; Timeout: Integer);
var
  Overlapped: TOverlapped;
  Mask: DWORD;
  Success: Boolean;
  Signaled, EventHandleCount: Integer;
  EventHandles: array[0..1] of THandle;
begin
  // cannot call method if event thread is running
  if FThreadCreated then
    raise EComPort.CreateNoWinCode(CError_ThreadCreated);

  FillChar(Overlapped, SizeOf(TOverlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, False, nil);
  EventHandles[0] := Overlapped.hEvent;
  if StopEvent <> 0 then
  begin
    EventHandles[1] := StopEvent;
    EventHandleCount := 2;
  end
  else
    EventHandleCount := 1;

  try
    SetCommMask(FHandle, EventsToInt(Events));
    // let's wait for event or timeout
    Success := WaitCommEvent(FHandle, Mask, @Overlapped);

    if (Success) or (GetLastError = ERROR_IO_PENDING) then
    begin
      Signaled := WaitForMultipleObjects(EventHandleCount, @EventHandles,
        False, Timeout);
      Success := (Signaled = WAIT_OBJECT_0)
        or (Signaled = WAIT_OBJECT_0 + 1) or (Signaled = WAIT_TIMEOUT);
      SetCommMask(FHandle, 0);
    end;

    if not Success then
      raise EComPort.Create(CError_WaitFailed, GetLastError, FPort);

    Events := IntToEvents(Mask);
  finally
    CloseHandle(Overlapped.hEvent);
  end;
end;

// transmit char ahead of any pending data in ouput buffer
procedure TCustomComPort.TransmitChar(Ch: TCPortChar);
begin
  if not TransmitCommChar(FHandle, Ch) then
    raise EComPort.Create(CError_TransmitFailed, GetLastError, FPort);
end;

// show port setup dialog
procedure TCustomComPort.ShowSetupDialog;
begin
  EditComPort(Self);
end;

// some conversion routines
function BoolToStr(const Value: Boolean): string;
begin
  if Value then
    Result := 'Yes'
  else
    Result := 'No';
end;

function StrToBool(const Value: string): Boolean;
begin
  if UpperCase(Value) = 'YES' then
    Result := True
  else
    Result := False;
end;

function DTRToStr(DTRFlowControl: TDTRFlowControl): string;
const
  DTRStrings: array[TDTRFlowControl] of string = ('Disable', 'Enable',
    'Handshake');
begin
  Result := DTRStrings[DTRFlowControl];
end;

function RTSToStr(RTSFlowControl: TRTSFlowControl): string;
const
  RTSStrings: array[TRTSFlowControl] of string = ('Disable', 'Enable',
    'Handshake', 'Toggle');
begin
  Result := RTSStrings[RTSFlowControl];
end;

function StrToRTS(Str: string): TRTSFlowControl;
var
  I: TRTSFlowControl;
begin
  I := Low(TRTSFlowControl);
  while (I <= High(TRTSFlowControl)) do
  begin
    if UpperCase(Str) = UpperCase(RTSToStr(I)) then
      Break;
    I := Succ(I);
  end;
  if I > High(TRTSFlowControl) then
    Result := rtsDisable
  else
    Result := I;
end;

function StrToDTR(Str: string): TDTRFlowControl;
var
  I: TDTRFlowControl;
begin
  I := Low(TDTRFlowControl);
  while (I <= High(TDTRFlowControl)) do
  begin
    if UpperCase(Str) = UpperCase(DTRToStr(I)) then
      Break;
    I := Succ(I);
  end;
  if I > High(TDTRFlowControl) then
    Result := dtrDisable
  else
    Result := I;
end;

function CPortStrToChar(Str: string): TCPortChar;
var
  A: Integer;
begin
  if Length(Str) > 0 then
  begin
    if (Str[1] = '#') and (Length(Str) > 1) then
    begin
      try
        A := StrToInt(Copy(Str, 2, Length(Str) - 1));
      except
        A := 0;
      end;
      Result := TCPortChar( Chr(Byte(A)) );
    end
    else
      Result := TCPortChar( Str[1] );
  end
  else
    Result := #0;
end;

function CPortCharToStr(Ch: TCPortChar): string;
begin
  if Ch in [#33..#127] then
    Result := String( Ch )
  else
    Result := String( '#' + IntToStr(Ord(Ch)) );
end;

// store settings to ini file
procedure TCustomComPort.StoreIniFile(IniFile: TIniFile);
begin
  if spBasic in FStoredProps then
  begin
    IniFile.WriteString(Name, 'Port', Port);
    IniFile.WriteString(Name, 'BaudRate', BaudRateToStr(BaudRate));
    if BaudRate = brCustom then
      IniFile.WriteInteger(Name, 'CustomBaudRate', CustomBaudRate);
    IniFile.WriteString(Name, 'StopBits', StopBitsToStr(StopBits));
    IniFile.WriteString(Name, 'DataBits', DataBitsToStr(DataBits));
    IniFile.WriteString(Name, 'Parity', ParityToStr(Parity.Bits));
    IniFile.WriteString(Name, 'FlowControl', FlowControlToStr(FlowControl.FlowControl));
  end;
  if spOthers in FStoredProps then
  begin
    IniFile.WriteString(Name, 'EventChar', CPortCharToStr(EventChar));
    IniFile.WriteString(Name, 'DiscardNull', BoolToStr(DiscardNull));
  end;
  if spParity in FStoredProps then
  begin
    IniFile.WriteString(Name, 'Parity.Check', BoolToStr(Parity.Check));
    IniFile.WriteString(Name, 'Parity.Replace', BoolToStr(Parity.Replace));
    IniFile.WriteString(Name, 'Parity.ReplaceChar', CPortCharToStr(Parity.ReplaceChar));
  end;
  if spBuffer in FStoredProps then
  begin
    IniFile.WriteInteger(Name, 'Buffer.OutputSize', Buffer.OutputSize);
    IniFile.WriteInteger(Name, 'Buffer.InputSize', Buffer.InputSize);
  end;
  if spTimeouts in FStoredProps then
  begin
    IniFile.WriteInteger(Name, 'Timeouts.ReadInterval', Timeouts.ReadInterval);
    IniFile.WriteInteger(Name, 'Timeouts.ReadTotalConstant', Timeouts.ReadTotalConstant);
    IniFile.WriteInteger(Name, 'Timeouts.ReadTotalMultiplier', Timeouts.ReadTotalMultiplier);
    IniFile.WriteInteger(Name, 'Timeouts.WriteTotalConstant', Timeouts.WriteTotalConstant);
    IniFile.WriteInteger(Name, 'Timeouts.WriteTotalMultiplier', Timeouts.WriteTotalMultiplier);
  end;
  if spFlowControl in FStoredProps then
  begin
    IniFile.WriteString(Name, 'FlowControl.ControlRTS', RTSToStr(FlowControl.ControlRTS));
    IniFile.WriteString(Name, 'FlowControl.ControlDTR', DTRToStr(FlowControl.ControlDTR));
    IniFile.WriteString(Name, 'FlowControl.DSRSensitivity', BoolToStr(FlowControl.DSRSensitivity));
    IniFile.WriteString(Name, 'FlowControl.OutCTSFlow', BoolToStr(FlowControl.OutCTSFlow));
    IniFile.WriteString(Name, 'FlowControl.OutDSRFlow', BoolToStr(FlowControl.OutDSRFlow));
    IniFile.WriteString(Name, 'FlowControl.TxContinueOnXoff', BoolToStr(FlowControl.TxContinueOnXoff));
    IniFile.WriteString(Name, 'FlowControl.XonXoffIn', BoolToStr(FlowControl.XonXoffIn));
    IniFile.WriteString(Name, 'FlowControl.XonXoffOut', BoolToStr(FlowControl.XonXoffOut));
    IniFile.WriteString(Name, 'FlowControl.XoffChar', CPortCharToStr(FlowControl.XoffChar));
    IniFile.WriteString(Name, 'FlowControl.XonChar', CPortCharToStr(FlowControl.XonChar));
  end;
end;

// store settings to registry
procedure TCustomComPort.StoreRegistry(Reg: TRegistry);
begin
  if spBasic in FStoredProps then
  begin
    Reg.WriteString('Port', Port);
    Reg.WriteString('BaudRate', BaudRateToStr(BaudRate));
    if BaudRate = brCustom then
      Reg.WriteInteger('CustomBaudRate', CustomBaudRate);
    Reg.WriteString('StopBits', StopBitsToStr(StopBits));
    Reg.WriteString('DataBits', DataBitsToStr(DataBits));
    Reg.WriteString('Parity', ParityToStr(Parity.Bits));
    Reg.WriteString('FlowControl', FlowControlToStr(FlowControl.FlowControl));
  end;
  if spOthers in FStoredProps then
  begin
    Reg.WriteString('EventChar', CPortCharToStr(EventChar));
    Reg.WriteString('DiscardNull', BoolToStr(DiscardNull));
  end;
  if spParity in FStoredProps then
  begin
    Reg.WriteString('Parity.Check', BoolToStr(Parity.Check));
    Reg.WriteString('Parity.Replace', BoolToStr(Parity.Replace));
    Reg.WriteString('Parity.ReplaceChar', CPortCharToStr(Parity.ReplaceChar));
  end;
  if spBuffer in FStoredProps then
  begin
    Reg.WriteInteger('Buffer.OutputSize', Buffer.OutputSize);
    Reg.WriteInteger('Buffer.InputSize', Buffer.InputSize);
  end;
  if spTimeouts in FStoredProps then
  begin
    Reg.WriteInteger('Timeouts.ReadInterval', Timeouts.ReadInterval);
    Reg.WriteInteger('Timeouts.ReadTotalConstant', Timeouts.ReadTotalConstant);
    Reg.WriteInteger('Timeouts.ReadTotalMultiplier', Timeouts.ReadTotalMultiplier);
    Reg.WriteInteger('Timeouts.WriteTotalConstant', Timeouts.WriteTotalConstant);
    Reg.WriteInteger('Timeouts.WriteTotalMultiplier', Timeouts.WriteTotalMultiplier);
  end;
  if spFlowControl in FStoredProps then
  begin
    Reg.WriteString('FlowControl.ControlRTS', RTSToStr(FlowControl.ControlRTS));
    Reg.WriteString('FlowControl.ControlDTR', DTRToStr(FlowControl.ControlDTR));
    Reg.WriteString('FlowControl.DSRSensitivity', BoolToStr(FlowControl.DSRSensitivity));
    Reg.WriteString('FlowControl.OutCTSFlow', BoolToStr(FlowControl.OutCTSFlow));
    Reg.WriteString('FlowControl.OutDSRFlow', BoolToStr(FlowControl.OutDSRFlow));
    Reg.WriteString('FlowControl.TxContinueOnXoff', BoolToStr(FlowControl.TxContinueOnXoff));
    Reg.WriteString('FlowControl.XonXoffIn', BoolToStr(FlowControl.XonXoffIn));
    Reg.WriteString('FlowControl.XonXoffOut', BoolToStr(FlowControl.XonXoffOut));
    Reg.WriteString('FlowControl.XoffChar', CPortCharToStr(FlowControl.XoffChar));
    Reg.WriteString('FlowControl.XonChar', CPortCharToStr(FlowControl.XonChar));
  end;
end;

// load settings from ini file
procedure TCustomComPort.LoadIniFile(IniFile: TIniFile);
begin
  if spBasic in FStoredProps then
  begin
    Port := IniFile.ReadString(Name, 'Port', Port);
    BaudRate := StrToBaudRate(IniFile.ReadString(Name, 'BaudRate', BaudRateToStr(BaudRate)));
    if BaudRate = brCustom then
      CustomBaudRate := IniFile.ReadInteger(Name, 'CustomBaudRate', 9600);
    StopBits := StrToStopBits(IniFile.ReadString(Name, 'StopBits', StopBitsToStr(StopBits)));
    DataBits := StrToDataBits(IniFile.ReadString(Name, 'DataBits', DataBitsToStr(DataBits)));
    Parity.Bits := StrToParity(IniFile.ReadString(Name, 'Parity', ParityToStr(Parity.Bits)));
    FlowControl.FlowControl := StrToFlowControl(
      IniFile.ReadString(Name, 'FlowControl', FlowControlToStr(FlowControl.FlowControl)));
  end;
  if spOthers in FStoredProps then
  begin
    EventChar := CPortStrToChar(IniFile.ReadString(Name, 'EventChar', CPortCharToStr(EventChar)));
    DiscardNull := StrToBool(IniFile.ReadString(Name, 'DiscardNull', BoolToStr(DiscardNull)));
  end;
  if spParity in FStoredProps then
  begin
    Parity.Check := StrToBool(IniFile.ReadString(Name, 'Parity.Check', BoolToStr(Parity.Check)));
    Parity.Replace := StrToBool(IniFile.ReadString(Name, 'Parity.Replace', BoolToStr(Parity.Replace)));
    Parity.ReplaceChar := CPortStrToChar(IniFile.ReadString(Name, 'Parity.ReplaceChar', CPortCharToStr(Parity.ReplaceChar)));
  end;
  if spBuffer in FStoredProps then
  begin
    Buffer.OutputSize := IniFile.ReadInteger(Name, 'Buffer.OutputSize', Buffer.OutputSize);
    Buffer.InputSize := IniFile.ReadInteger(Name, 'Buffer.InputSize', Buffer.InputSize);
  end;
  if spTimeouts in FStoredProps then
  begin
    Timeouts.ReadInterval := IniFile.ReadInteger(Name, 'Timeouts.ReadInterval', Timeouts.ReadInterval);
    Timeouts.ReadTotalConstant := IniFile.ReadInteger(Name, 'Timeouts.ReadTotalConstant', Timeouts.ReadTotalConstant);
    Timeouts.ReadTotalMultiplier := IniFile.ReadInteger(Name, 'Timeouts.ReadTotalMultiplier', Timeouts.ReadTotalMultiplier);
    Timeouts.WriteTotalConstant := IniFile.ReadInteger(Name, 'Timeouts.WriteTotalConstant', Timeouts.WriteTotalConstant);
    Timeouts.WriteTotalMultiplier := IniFile.ReadInteger(Name, 'Timeouts.WriteTotalMultiplier', Timeouts.WriteTotalMultiplier);
  end;
  if spFlowControl in FStoredProps then
  begin
    FlowControl.ControlRTS := StrToRTS(IniFile.ReadString(Name, 'FlowControl.ControlRTS', RTSToStr(FlowControl.ControlRTS)));
    FlowControl.ControlDTR := StrToDTR(IniFile.ReadString(Name, 'FlowControl.ControlDTR', DTRToStr(FlowControl.ControlDTR)));
    FlowControl.DSRSensitivity := StrToBool(IniFile.ReadString(Name, 'FlowControl.DSRSensitivity', BoolToStr(FlowControl.DSRSensitivity)));
    FlowControl.OutCTSFlow := StrToBool(IniFile.ReadString(Name, 'FlowControl.OutCTSFlow', BoolToStr(FlowControl.OutCTSFlow)));
    FlowControl.OutDSRFlow := StrToBool(IniFile.ReadString(Name, 'FlowControl.OutDSRFlow', BoolToStr(FlowControl.OutCTSFlow)));
    FlowControl.TxContinueOnXoff := StrToBool(IniFile.ReadString(Name, 'FlowControl.TxContinueOnXoff', BoolToStr(FlowControl.TxContinueOnXoff)));
    FlowControl.XonXoffIn := StrToBool(IniFile.ReadString(Name, 'FlowControl.XonXoffIn', BoolToStr(FlowControl.XonXoffIn)));
    FlowControl.XonXoffOut := StrToBool(IniFile.ReadString(Name, 'FlowControl.XonXoffOut', BoolToStr(FlowControl.XonXoffOut)));
    FlowControl.XoffChar := CPortStrToChar(IniFile.ReadString(Name, 'FlowControl.XoffChar', CPortCharToStr(FlowControl.XoffChar)));
    FlowControl.XonChar := CPortStrToChar(IniFile.ReadString(Name, 'FlowControl.XonChar', CPortCharToStr(FlowControl.XonChar)));
  end;
end;

// load settings from registry
procedure TCustomComPort.LoadRegistry(Reg: TRegistry);
begin
  if spBasic in FStoredProps then
  begin
    Port := Reg.ReadString('Port');
    BaudRate := StrToBaudRate(Reg.ReadString('BaudRate'));
    if BaudRate = brCustom then
      CustomBaudRate := Reg.ReadInteger('CustomBaudRate');
    StopBits := StrToStopBits(Reg.ReadString('StopBits'));
    DataBits := StrToDataBits(Reg.ReadString('DataBits'));
    Parity.Bits := StrToParity(Reg.ReadString('Parity'));
    FlowControl.FlowControl := StrToFlowControl(Reg.ReadString('FlowControl'));
  end;
  if spOthers in FStoredProps then
  begin
    EventChar := CPortStrToChar(Reg.ReadString('EventChar'));
    DiscardNull := StrToBool(Reg.ReadString('DiscardNull'));
  end;
  if spParity in FStoredProps then
  begin
    Parity.Check := StrToBool(Reg.ReadString('Parity.Check'));
    Parity.Replace := StrToBool(Reg.ReadString('Parity.Replace'));
    Parity.ReplaceChar := CPortStrToChar(Reg.ReadString('Parity.ReplaceChar'));
  end;
  if spBuffer in FStoredProps then
  begin
    Buffer.OutputSize := Reg.ReadInteger('Buffer.OutputSize');
    Buffer.InputSize := Reg.ReadInteger('Buffer.InputSize');
  end;
  if spTimeouts in FStoredProps then
  begin
    Timeouts.ReadInterval := Reg.ReadInteger('Timeouts.ReadInterval');
    Timeouts.ReadTotalConstant := Reg.ReadInteger('Timeouts.ReadTotalConstant');
    Timeouts.ReadTotalMultiplier := Reg.ReadInteger('Timeouts.ReadTotalMultiplier');
    Timeouts.WriteTotalConstant := Reg.ReadInteger('Timeouts.WriteTotalConstant');
    Timeouts.WriteTotalMultiplier := Reg.ReadInteger('Timeouts.WriteTotalMultiplier');
  end;
  if spFlowControl in FStoredProps then
  begin
    FlowControl.ControlRTS := StrToRTS(Reg.ReadString('FlowControl.ControlRTS'));
    FlowControl.ControlDTR := StrToDTR(Reg.ReadString('FlowControl.ControlDTR'));
    FlowControl.DSRSensitivity := StrToBool(Reg.ReadString('FlowControl.DSRSensitivity'));
    FlowControl.OutCTSFlow := StrToBool(Reg.ReadString('FlowControl.OutCTSFlow'));
    FlowControl.OutDSRFlow := StrToBool(Reg.ReadString('FlowControl.OutDSRFlow'));
    FlowControl.TxContinueOnXoff := StrToBool(Reg.ReadString('FlowControl.TxContinueOnXoff'));
    FlowControl.XonXoffIn := StrToBool(Reg.ReadString('FlowControl.XonXoffIn'));
    FlowControl.XonXoffOut := StrToBool(Reg.ReadString('FlowControl.XonXoffOut'));
    FlowControl.XoffChar := CPortStrToChar(Reg.ReadString('FlowControl.XoffChar'));
    FlowControl.XonChar := CPortStrToChar(Reg.ReadString('FlowControl.XonChar'));
  end;
end;

// initialize registry
procedure SetRegistry(Reg: TRegistry; Key: string; Name: string);
var
  I: Integer;
  Temp: string;
begin
  I := Pos('\', Key);
  if I > 0 then
  begin
    Temp := Copy(Key, 1, I - 1);
    if UpperCase(Temp) = 'HKEY_LOCAL_MACHINE' then
      Reg.RootKey := HKEY_LOCAL_MACHINE
    else
      if UpperCase(Temp) = 'HKEY_CURRENT_USER' then
        Reg.RootKey := HKEY_CURRENT_USER;
    Key := Copy(Key, I + 1, Length(Key) - I);
    if Key[Length(Key)] <> '\' then
      Key := Key + '\';
    Key := Key + Name;
    Reg.OpenKey(Key, True);
  end;
end;

// store settings
procedure TCustomComPort.StoreSettings(StoreType: TStoreType; StoreTo: string);
var
  IniFile: TIniFile;
  Reg: TRegistry;
begin
  try
    if StoreType = stRegistry then
    begin
      Reg := TRegistry.Create;
      try
        SetRegistry(Reg, StoreTo, Name);
        StoreRegistry(Reg);
      finally
        Reg.Free;
      end
    end else
    begin
      IniFile := TIniFile.Create(StoreTo);
      try
        StoreIniFile(IniFile);
      finally
        IniFile.Free;
      end
    end;
  except
    raise EComPort.CreateNoWinCode(CError_StoreFailed);
  end;
end;

// load settings
procedure TCustomComPort.LoadSettings(StoreType: TStoreType; LoadFrom: string);
var
  IniFile: TIniFile;
  Reg: TRegistry;
begin
  BeginUpdate;
  try
    try
      if StoreType = stRegistry then
      begin
        Reg := TRegistry.Create;
        try
          SetRegistry(Reg, LoadFrom, Name);
          LoadRegistry(Reg);
        finally
          Reg.Free;
        end
      end else
      begin
        IniFile := TIniFile.Create(LoadFrom);
        try
          LoadIniFile(IniFile);
        finally
          IniFile.Free;
        end
      end;
    finally
      EndUpdate;
    end;
  except
    raise EComPort.CreateNoWinCode(CError_LoadFailed);
  end;
end;

// register link from other component to TCustomComPort
procedure TCustomComPort.RegisterLink(AComLink: TComLink);
begin
  if FLinks.IndexOf(Pointer(AComLink)) > -1 then
    raise EComPort.CreateNoWinCode(CError_RegFailed)
  else
    FLinks.Add(Pointer(AComLink));
  FHasLink := HasLink;
end;

// unregister link from other component to TCustomComPort
procedure TCustomComPort.UnRegisterLink(AComLink: TComLink);
begin
  if FLinks.IndexOf(Pointer(AComLink)) = -1 then
    raise EComPort.CreateNoWinCode(CError_RegFailed)
  else
    FLinks.Remove(Pointer(AComLink));
  FHasLink := HasLink;
end;

// default actions on port events

procedure TCustomComPort.DoBeforeClose;
begin
  if Assigned(FOnBeforeClose) then
    FOnBeforeClose(Self);
end;

procedure TCustomComPort.DoBeforeOpen;
begin
  if Assigned(FOnBeforeOpen) then
    FOnBeforeOpen(Self);
end;

procedure TCustomComPort.DoAfterOpen;
begin
  if Assigned(FOnAfterOpen) then
    FOnAfterOpen(Self);
end;

procedure TCustomComPort.DoAfterClose;
begin
  if Assigned(FOnAfterClose) then
    FOnAfterClose(Self);
end;

procedure TCustomComPort.DoRxChar(Count: Integer);
begin
  if Assigned(FOnRxChar) then
    FOnRxChar(Self, Count);
end;

procedure TCustomComPort.DoRxBuf(const mBuffer:PCPortAnsiChar; Count: Integer);
begin
  if Assigned(FOnRxBuf) then
    FOnRxBuf(Self, mBuffer, Count);
end;

procedure TCustomComPort.DoBreak;
begin
  if Assigned(FOnBreak) then
    FOnBreak(Self);
end;

procedure TCustomComPort.DoTxEmpty;
begin
  if Assigned(FOnTxEmpty)
    then FOnTxEmpty(Self);
end;

procedure TCustomComPort.DoRing;
begin
  if Assigned(FOnRing) then
    FOnRing(Self);
end;

procedure TCustomComPort.DoCTSChange(OnOff: Boolean);
begin
  if Assigned(FOnCTSChange) then
    FOnCTSChange(Self, OnOff);
end;

procedure TCustomComPort.DoDSRChange(OnOff: Boolean);
begin
  if Assigned(FOnDSRChange) then
    FOnDSRChange(Self, OnOff);
end;

procedure TCustomComPort.DoRLSDChange(OnOff: Boolean);
begin
  if Assigned(FOnRLSDChange) then
    FOnRLSDChange(Self, OnOff);
end;

procedure TCustomComPort.DoError(Errors: TComErrors);
begin
  if Assigned(FOnError) then
    FOnError(Self, Errors);
end;

procedure TCustomComPort.DoRxFlag;
begin
  if Assigned(FOnRxFlag) then
    FOnRxFlag(Self);
end;

procedure TCustomComPort.DoRx80Full;
begin
  if Assigned(FOnRx80Full) then
    FOnRx80Full(Self);
end;

// set signals to false on close, and to proper value on open,
// because OnXChange events are not called automatically
procedure TCustomComPort.CheckSignals(Open: Boolean);
begin
  if Open then
  begin
    CallCTSChange;
    CallDSRChange;
    CallRLSDChange;
  end else
  begin
    SendSignalToLink(leCTS, False);
    SendSignalToLink(leDSR, False);
    SendSignalToLink(leRLSD, False);
    DoCTSChange(False);
    DoDSRChange(False);
    DoRLSDChange(False);
  end;
end;

// called in response to EV_X events, except CallXClose, CallXOpen

procedure TCustomComPort.CallAfterClose;
begin
  SendSignalToLink(leConn, False);
  DoAfterClose;
end;

procedure TCustomComPort.CallAfterOpen;
begin
  SendSignalToLink(leConn, True);
  DoAfterOpen;
  CheckSignals(True);
end;

procedure TCustomComPort.CallBeforeClose;
begin
  // shutdown com signals manually
  CheckSignals(False);
  DoBeforeClose;
end;

procedure TCustomComPort.CallBeforeOpen;
begin
  DoBeforeOpen;
end;

procedure TCustomComPort.CallBreak;
begin
  DoBreak;
end;

procedure TCustomComPort.CallCTSChange;
var
  OnOff: Boolean;
begin
  OnOff := csCTS in Signals;
  // check for linked components
  SendSignalToLink(leCTS, OnOff);
  DoCTSChange(OnOff);
end;

procedure TCustomComPort.CallDSRChange;
var
  OnOff: Boolean;
begin
  OnOff := csDSR in Signals;
  // check for linked components
  SendSignalToLink(leDSR, OnOff);
  DoDSRChange(OnOff);
end;

procedure TCustomComPort.CallRLSDChange;
var
  OnOff: Boolean;
begin
  OnOff := csRLSD in Signals;
  // check for linked components
  SendSignalToLink(leRLSD, OnOff);
  DoRLSDChange(OnOff);
end;

procedure TCustomComPort.CallError;
var
  Errors: TComErrors;
begin
  Errors := LastErrors;
  if Errors <> [] then
    DoError(Errors);
end;

procedure TCustomComPort.CallRing;
begin
  NotifyLink(leRing);
  DoRing;
end;

procedure TCustomComPort.CallRx80Full;
begin
  DoRx80Full;
end;

procedure TCustomComPort.CallRxChar;
var
  Count: Integer;

  // read from input buffer
  procedure PerformRead(var aDebugMe: PCPortAnsiChar); { Pass in a Var PAnsiChar, get memory, get data }
  begin
    GetMem(aDebugMe, Count);
    Read(aDebugMe, Count);
    // call OnRxBuf event
    DoRxBuf(aDebugMe, Count);
  end;

  // check if any component is linked, to OnRxChar event
  procedure CheckLinks;
  {$WARNINGS OFF}
  var
    I: Integer;
    DebugMe: Pointer; //PCPortAnsiChar;{Pointer}
    ComLink: TComLink;
    ReadFromBuffer: Boolean;
  begin
    DebugMe := nil;
    // examine links
    if (Count > 0) and (not TriggersOnRxChar) then
    begin
      ReadFromBuffer := False;
      try
        // cycle through links
        for I := 0 to FLinks.Count - 1 do
        begin
          ComLink := TComLink(FLinks[I]);
          if Assigned(ComLink.OnRxBuf) then
          begin
            // link to OnRxChar event found
            if not ReadFromBuffer then
            begin
              // TCustomComPort must read from comport, so OnRxChar event is
              // not triggered
              ReadFromBuffer := True;
              PerformRead( PCPortAnsiChar(DebugMe) );
            end;
            // send data to linked component
            ComLink.OnRxBuf(Self, DebugMe, Count);
          end
        end;
        if (not ReadFromBuffer) and (not FTriggersOnRxChar) then
        begin
          ReadFromBuffer := True;
          PerformRead( PCPortAnsiChar(DebugMe) );
        end;
      finally
        if ReadFromBuffer then
        begin
          FreeMem(DebugMe);
          // data is already out of buffer, prevent from OnRxChar event to occur
          Count := 0;
        end;
      end;
    end;
  end;

begin
  if FInputCountNotSupported then exit;
  
  Count := InputCount;
  if Count > 0 then
    SendSignalToLink(leRx, True);
  CheckLinks;
  if Count > 0 then
    DoRxChar(Count);
end;

procedure TCustomComPort.CallRxFlag;
begin
  NotifyLink(leRxFlag);
  DoRxFlag;
end;

procedure TCustomComPort.CallTxEmpty;
begin
  SendSignalToLink(leTx, False);
  NotifyLink(leTxEmpty);
  DoTxEmpty;
end;

// returns true if it has least one component linked to OnRxBuf event
function TCustomComPort.HasLink: Boolean;
var
  I: Integer;
  ComLink: TComLink;
begin
  Result := False;
  // examine links
  if FLinks.Count > 0 then
    for I := 0 to FLinks.Count - 1 do
    begin
      ComLink := TComLink(FLinks[I]);
      if Assigned(ComLink.OnRxBuf) then
        Result := True;
    end;
end;

// send TxBuf notify to link
procedure TCustomComPort.TxNotifyLink(const Buffer:PCPortAnsiChar; Count: Integer);
var
  I: Integer;
  ComLink: TComLink;
begin
  if (FLinks.Count > 0) then
    for I := 0 to FLinks.Count - 1 do
    begin
      ComLink := TComLink(FLinks[I]);
      if Assigned(ComLink.OnTxBuf) then
        ComLink.OnTxBuf(Self, Buffer, Count);
    end;
end;

// send event notification to link
procedure TCustomComPort.NotifyLink(FLinkEvent: TComLinkEvent);
var
  I: Integer;
  ComLink: TComLink;
  Event: TNotifyEvent;
begin
  if (FLinks.Count > 0) then
    for I := 0 to FLinks.Count - 1 do
    begin
      ComLink := TComLink(FLinks[I]);
      Event := nil;
      case FLinkEvent of
        leRing: Event := ComLink.OnRing;
        leTxEmpty: Event := ComLink.OnTxEmpty;
        leRxFlag: Event := ComLink.OnRxFlag;
      end;
      if Assigned(Event) then
        Event(Self);
    end;
end;

// send signal to linked components
procedure TCustomComPort.SendSignalToLink(Signal: TComLinkEvent; OnOff: Boolean);
var
  I: Integer;
  ComLink: TComLink;
  SignalEvent: TComSignalEvent;
begin
  if (FLinks.Count > 0) then
    // cycle through links
    for I := 0 to FLinks.Count - 1 do
    begin
      ComLink := TComLink(FLinks[I]);
      SignalEvent := nil;
      case Signal of
        leCTS: SignalEvent := ComLink.OnCTSChange;
        leDSR: SignalEvent := ComLink.OnDSRChange;
        leRLSD: SignalEvent := ComLink.OnRLSDChange;
        leTx: SignalEvent := ComLink.OnTx;
        leRx: SignalEvent := ComLink.OnRx;
        leConn: SignalEvent := ComLink.OnConn;
      end;
      // if linked, trigger event
      if Assigned(SignalEvent) then
        SignalEvent(Self, OnOff);
    end;
end;

// Set Connected property, same as Open/Close methods, opens Com Port.
procedure TCustomComPort.SetConnected(const Value: Boolean);
begin
  if not ((csDesigning in ComponentState) or (csLoading in ComponentState)) then
  begin
    if Value <> FConnected then
      if Value then
        Open
      else
        Close;
  end
  else
    FConnected := Value;
end;

// Set one of the normal Baud Rates (BPS Rates)
procedure TCustomComPort.SetBaudRate(const Value: TBaudRate);
begin
  if Value <> FBaudRate then
  begin
    FBaudRate := Value;
    // if possible, apply settings
    ApplyDCB;
  end;
end;

// Set custom baud rate (BPS Rate)
procedure TCustomComPort.SetCustomBaudRate(const Value: Integer);
begin
  if Value <> FCustomBaudRate then
  begin
    FCustomBaudRate := Value;
    ApplyDCB;
  end;
end;

// Set Data Bits (Serial Word Length)
procedure TCustomComPort.SetDataBits(const Value: TDataBits);
begin
  if Value <> FDataBits then
  begin
    FDataBits := Value;
    ApplyDCB;
  end;
end;

// Set discard null Characters
procedure TCustomComPort.SetDiscardNull(const Value: Boolean);
begin
  if Value <> FDiscardNull then
  begin
    FDiscardNull := Value;
    ApplyDCB;
  end;
end;

// Set event Characters
procedure TCustomComPort.SetEventChar(const Value: TCPortChar);
begin
  if Value <> FEventChar then
  begin
    FEventChar := Value;
    ApplyDCB;
  end;
end;

// set port
procedure TCustomComPort.SetPort(const Value: TPort);
begin
  // 11.1.2001 Ch. Kaufmann; removed function ComString, because there can be com ports
  // with names other than COMn.
  if Value <> FPort then
  begin
    FPort := Value;
    if FConnected and not ((csDesigning in ComponentState) or
      (csLoading in ComponentState)) then
    begin
      Close;
      Open;
    end;
  end;
end;

// set stop bits
procedure TCustomComPort.SetStopBits(const Value: TStopBits);
begin
  if Value <> FStopBits then
  begin
    FStopBits := Value;
    ApplyDCB;
  end;
end;

// set event synchronization method
procedure TCustomComPort.SetSyncMethod(const Value: TSyncMethod);
begin
  if Value <> FSyncMethod then
  begin
    if FConnected and not ((csDesigning in ComponentState) or
      (csLoading in ComponentState))
    then
      raise EComPort.CreateNoWinCode(CError_ConnChangeProp)
    else
      FSyncMethod := Value;
  end;
end;

// sets RxChar triggering
procedure TCustomComPort.SetTriggersOnRxChar(const Value: Boolean);
begin
  if FHasLink then
    raise EComPort.CreateNoWinCode(CError_HasLink);
  FTriggersOnRxChar := Value;
end;

// sets event thread priority
procedure TCustomComPort.SetEventThreadPriority(const Value: TThreadPriority);
begin
  if Value <> FEventThreadPriority then
  begin
    if FConnected and not ((csDesigning in ComponentState) or
      (csLoading in ComponentState))
    then
      raise EComPort.CreateNoWinCode(CError_ConnChangeProp)
    else
      FEventThreadPriority := Value;
  end;
end;

// returns true if RxChar is triggered when data arrives input buffer
function TCustomComPort.GetTriggersOnRxChar: Boolean;
begin
  Result := FTriggersOnRxChar and (not FHasLink);
end;

// set flow control
procedure TCustomComPort.SetFlowControl(const Value: TComFlowControl);
begin
  FFlowControl.Assign(Value);
  ApplyDCB;
end;

// set parity
procedure TCustomComPort.SetParity(const Value: TComParity);
begin
  FParity.Assign(Value);
  ApplyDCB;
end;

// set timeouts
procedure TCustomComPort.SetTimeouts(const Value: TComTimeouts);
begin
  FTimeouts.Assign(Value);
  ApplyTimeouts;
end;

// set buffer
procedure TCustomComPort.SetBuffer(const Value: TComBuffer);
begin
  FBuffer.Assign(Value);
  ApplyBuffer;
end;

(*****************************************
 * TComDataPacket component              *
 *****************************************)

// create component
constructor TComDataPacket.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FComLink := TComLink.Create;
  FComLink.OnRxBuf := RxBuf;
  FMaxBufferSize := 1024;
end;

// destroy component
destructor TComDataPacket.Destroy;
begin
  ComPort := nil;
  FComLink.Free;
  inherited Destroy;
end;

// add custom data to packet buffer
procedure TComDataPacket.AddData(const Str: AnsiString);
begin
  if ValidStop then
  begin
    Buffer := Buffer + Str;
    HandleBuffer;
  end
  else
    DoPacket(Str);
end;

// remove ComPort property if being destroyed
procedure TComDataPacket.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FComPort) and (Operation = opRemove) then
    ComPort := nil;
end;

// call OnDiscard
procedure TComDataPacket.DoDiscard(const Str: string);
begin
  if Assigned(FOnDiscard) then
    FOnDiscard(Self, Str);
end;

// call OnPacket
procedure TComDataPacket.DoPacket(const Str: string);
begin
  if Assigned(FOnPacket) then
    FOnPacket(Self, Str);
end;

// call OnCustomStart
procedure TComDataPacket.DoCustomStart(const Str: string;
  var Pos: Integer);
begin
  if Assigned(FOnCustomStart) then
    FOnCustomStart(Self, Str, Pos);
end;

// call OnCustomStop
procedure TComDataPacket.DoCustomStop(const Str: string; var Pos: Integer);
begin
  if Assigned(FOnCustomStop) then
    FOnCustomStop(Self, Str, Pos);
end;

// discard start and stop strings
procedure TComDataPacket.CheckIncludeStrings(var Str: AnsiString);
var
  LenStart, LenStop: Integer;
begin
  if FIncludeStrings then
    Exit;
  LenStart := Length(FStartString);
  LenStop := Length(FStopString);
  // remove start string
  if Pos(Upper(FStartString), Upper(Str)) = 1 then
    Str := Copy(Str, LenStart + 1, Length(Str) - LenStart);
  // remove stop string
  if Pos(Upper(FStopString), Upper(Str)) = (Length(Str) - LenStop + 1) then
    Str := Copy(Str, 1, Length(Str) - LenStop);
end;

// upper case
function TComDataPacket.Upper(const Str: string): string;
begin
  if FCaseInsensitive then
    Result := UpperCase(Str)
  else
    Result := Str;
end;

// split buffer in packets
procedure TComDataPacket.HandleBuffer;

  procedure DiscardPacketToPos(Pos: Integer);
  var
    Str: AnsiString;
  begin
    FInPacket := True;
    if Pos > 1 then
    begin
      Str := Copy(Buffer, 1, Pos - 1); // some discarded data
      Buffer := Copy(Buffer, Pos, Length(Buffer) - Pos + 1);
      DoDiscard(Str);
    end;
  end;

  procedure FormPacket(CutSize: Integer);
  var
    Str: AnsiString;
  begin
    Str := Copy(Buffer, 1, CutSize);
    Buffer := Copy(Buffer, CutSize + 1, Length(Buffer) - CutSize);
    CheckIncludeStrings(Str);
    DoPacket(Str);
  end;

  procedure StartPacket;
  var
    Found: Integer;
  begin
    // check for custom start condition
    Found := -1;
    DoCustomStart(Buffer, Found);
    if Found > 0 then
      DiscardPacketToPos(Found);
    if Found = -1 then
    begin
      if Length(FStartString) > 0 then // start string valid
      begin
        Found := Pos(Upper(FStartString), Upper(Buffer));
        if Found > 0 then
          DiscardPacketToPos(Found);
      end
      else
        FInPacket := True;
    end;
  end;

  procedure EndPacket;
  var
    Found, CutSize, Len: Integer;
  begin
    // check for custom stop condition
    Found := -1;
    DoCustomStop(Buffer, Found);
    if Found > 0 then
    begin
      // custom stop condition detected
      CutSize := Found;
      FInPacket := False;
    end
    else
      if Found = -1 then
      begin
        Len := Length(Buffer);
        if (FSize > 0) and (Len >= FSize) then
        begin
          // size stop condition detected
          FInPacket := False;
          CutSize := FSize;
        end
        else
        begin
          Len := Length(FStartString);
          Found := Pos(Upper(FStopString),
            Upper(Copy(Buffer, Len + 1, Length(Buffer) - Len)));
          if Found > 0 then
          begin
            // stop string stop condition detected
            CutSize := Found + Length(FStopString) + Len - 1;
            FInPacket := False;
          end;
        end;
      end;
    if not FInPacket then
      FormPacket(CutSize); // create packet
  end;

  function IsBufferTooLarge: Boolean;
  begin
    Result := (Length(Buffer) >= FMaxBufferSize) and (FMaxBufferSize > 0);
  end;

begin
  try
    if not FInPacket then
      StartPacket;
    if FInPacket then
    begin
      EndPacket;
      if not FInPacket then
        HandleBuffer;
    end;
  finally
    if IsBufferTooLarge then
      EmptyBuffer;
  end;
end;

// is stop condition valid?
function TComDataPacket.ValidStop: Boolean;
begin
  Result := (FSize > 0) or (Length(FStopString) > 0)
    or (Assigned(FOnCustomStop));
end;

// receive data
procedure TComDataPacket.RxBuf(Sender: TObject; const Buffer:PCPortAnsiChar; Count: Integer);
var
  Str: AnsiString;

begin
  SetLength(Str, Count); // FRACKBAR.
  Move(Buffer^, PAnsiChar(Str)^, Count);

  AddData(Str);
end;

// empty buffer
procedure TComDataPacket.EmptyBuffer;
begin
  if Buffer <> '' then
  begin
    try
      DoDiscard(Buffer);
    finally
      Buffer := '';
      FInPacket := False;
    end;
  end;
end;

// set com port
procedure TComDataPacket.SetComPort(const Value: TCustomComPort);
begin
  if Value <> FComPort then
  begin
    if FComPort <> nil then
      FComPort.UnRegisterLink(FComLink);
    FComPort := Value;
    if FComPort <> nil then
    begin
      FComPort.FreeNotification(Self);
      FComPort.RegisterLink(FComLink);
    end;
  end;
end;

// set case sensitivity
procedure TComDataPacket.SetCaseInsensitive(const Value: Boolean);
begin
  if FCaseInsensitive <> Value then
  begin
    FCaseInsensitive := Value;
    if not (csLoading in ComponentState) then
      EmptyBuffer;
  end;
end;

// set packet size
procedure TComDataPacket.SetSize(const Value: Integer);
begin
  if FSize <> Value then
  begin
    FSize := Value;
    if not (csLoading in ComponentState) then
      EmptyBuffer;
  end;
end;

// set start string
procedure TComDataPacket.SetStartString(const Value: string);
begin
  if FStartString <> Value then
  begin
    FStartString := Value;
    if not (csLoading in ComponentState) then
      EmptyBuffer;
  end;
end;

// set stop string
procedure TComDataPacket.SetStopString(const Value: string);
begin
  if FStopString <> Value then
  begin
    FStopString := Value;
    if not (csLoading in ComponentState) then
      EmptyBuffer;
  end;
end;

(*****************************************
 * EComPort exception                    *
 *****************************************)

// create stream
constructor TComStream.Create(AComPort: TCustomComPort);
begin
  inherited Create;
  FComPort := AComPort;
end;

// read from stream
function TComStream.Read(var Buffer; Count: Integer): Longint;
begin
  FComPort.Read( PCPortAnsiChar(Buffer), Count);
end;

// write to stream
function TComStream.Write(const Buffer; Count: Integer): Longint;
begin
  FComPort.Write(PCPortAnsiChar(@Buffer), Count);
end;

// seek always to 0
function TComStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  Result := 0;
end;

(*****************************************
 * EComPort exception                    *
 *****************************************)

// create exception with windows error code
constructor EComPort.Create(ACode: Integer; AWinCode: Integer; port:String);
begin
  FWinCode := AWinCode;
  FCode := ACode;
//  inherited CreateFmt(ComErrorMessages[ACode] + {_(}' (win error code: %d)'{)}, [AWinCode]);
  inherited Create('COM Port Error: '+ComErrorMessage(AWinCode)+' on '+port);
end;

// create exception
constructor EComPort.CreateNoWinCode(ACode: Integer);
begin
  FWinCode := -1;
  FCode := ACode;
  inherited Create('COM Port Error: '+ComErrorMessage(ACode) );
end;



function TCustomComPort.Write(const mBuffer: PCPortAnsiChar;
  Count: Integer): Integer;
begin
 if FOverlapped then begin
    result := _WriteAsyncWrapper(mBuffer,Count); // Do a synchronous write using overlapped APIs.
 end else begin
   result := 0;
   if _SyncWrite(mBuffer,Count) then
      result := Count;
 end;
end;

procedure TCustomComPort.SetOverlapped(const Value: Boolean);
begin
  if FConnected then exit;
  FOverlapped := Value;
end;

end.
