unit CPortTypes;
(******************************************************
 * ComPort Library ver. 4.0                           *
 *   for Delphi 3, 4, 5, 6, 7, 2007-2010,XE  and      *
 *   C++ Builder 3, 4, 5, 6                           *
 * written by Dejan Crnila, 1998 - 2002               *
 * maintained by Lars B. Dybdahl, 2003                *
 *  and Warren Postma, 2008                           *
 *                                                    *
 * Fixed up for Delphi 2009 by W.Postma.  Oct 2008    *
 * More like completely rewritten, actually.
 *                                                    *
 * Brian Gochnauer Oct 2010                           *
 *     Removed ansi references for backward compat    *
 *     Made unicode ready                             *
 *****************************************************)

 { Data Type Declarations used in various CPort code units }

interface

uses   Windows, Messages, Classes, SysUtils, IniFiles, Registry;

type

  TCharBuf = Array of Char;
  PCharBuf = ^TCharBuf;
  TPort = string;
  TBaudRate = (brCustom, br110, br300, br600, br1200, br2400, br4800, br9600, br14400,
                br19200, br38400, br56000, br57600, br115200, br128000, br256000);
  TStopBits = (sbOneStopBit, sbOne5StopBits, sbTwoStopBits);
  TDataBits = (dbFive, dbSix, dbSeven, dbEight);
  TParityBits = (prNone, prOdd, prEven, prMark, prSpace);
  TDTRFlowControl = (dtrDisable, dtrEnable, dtrHandshake);
  TRTSFlowControl = (rtsDisable, rtsEnable, rtsHandshake, rtsToggle);
  TFlowControl = (fcHardware, fcSoftware, fcNone, fcCustom);
  TComEvent = (evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR,
                 evError, evRLSD, evRx80Full);
  TComEvents = set of TComEvent;
  TComSignal = (csCTS, csDSR, csRing, csRLSD);
  TComSignals = set of TComSignal;
  TComError = (ceFrame, ceRxParity, ceOverrun, ceBreak, ceIO, ceMode, ceRxOver, ceTxFull);
  TComErrors = set of TComError;
  TSyncMethod = (smThreadSync, smWindowSync, smNone, smDisableEvents);
  TStoreType = (stRegistry, stIniFile);
  TStoredProp = (spBasic, spFlowControl, spBuffer, spTimeouts, spParity, spOthers);
  TStoredProps = set of TStoredProp;
  TComLinkEvent = (leConn, leCTS, leDSR, leRLSD, leRing, leRx, leTx, leTxEmpty, leRxFlag);
  TRxCharEvent = procedure(Sender: TObject; Count: Integer) of object;
  TRxBufEvent = procedure(Sender: TObject; const Buffer:PCharBuf; var Count: Integer) of object;
  TComErrorEvent = procedure(Sender: TObject; Errors: TComErrors) of object;
  TComSignalEvent = procedure(Sender: TObject; OnOff: Boolean) of object;

  // types for asynchronous calls
  TOperationKind = (okWrite, okRead);
  TCPortAsync = record
    Overlapped: TOverlapped;
    Kind: TOperationKind;
    Data: PAnsiChar; //ReadSync reads into this structure
    Size: Integer;
  end;
  PCPortAsync = ^TCPortAsync;


function ComErrorsToStr(Errors:TComErrors):String;

implementation

function ComErrorsToStr(Errors:TComErrors):String;
  procedure e(msg:String);
  begin
     if result='' then
        result := msg
     else
        result := result+','+msg;
  end;
begin
   result := '';
   if ceFrame    in Errors then e('Frame');
   if ceRxParity in Errors then e('Parity');
   if ceOverrun  in Errors then e('Overrun');
   if ceBreak    in Errors then e('Break');
   if ceIO       in Errors then e('IO');
   if ceMode     in Errors then e('Mode');
   if ceRxOver   in Errors then e('RxOver');
   if ceTxFull   in Errors then e('TxFull');
   if result = '' then
      result := '<Ok>'
   else
      result := '<ComError:'+result+'>';
end;

end.
