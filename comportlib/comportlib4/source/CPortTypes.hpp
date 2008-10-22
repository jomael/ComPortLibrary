// CodeGear C++Builder
// Copyright (c) 1995, 2007 by CodeGear
// All rights reserved

// (DO NOT EDIT: machine generated header) 'Cporttypes.pas' rev: 11.00

#ifndef CporttypesHPP
#define CporttypesHPP

#pragma delphiheader begin
#pragma option push
#pragma option -w-      // All warnings off
#pragma option -Vx      // Zero-length empty class member functions
#pragma pack(push,8)
#include <System.hpp>	// Pascal unit
#include <Sysinit.hpp>	// Pascal unit
#include <Windows.hpp>	// Pascal unit
#include <Messages.hpp>	// Pascal unit
#include <Classes.hpp>	// Pascal unit
#include <Sysutils.hpp>	// Pascal unit
#include <Inifiles.hpp>	// Pascal unit
#include <Registry.hpp>	// Pascal unit

//-- user supplied -----------------------------------------------------------

namespace Cporttypes
{
//-- type declarations -------------------------------------------------------
typedef char *TCPortBytes;

typedef char TCPortChar;

typedef AnsiString TPort;

#pragma option push -b-
enum TBaudRate { brCustom, br110, br300, br600, br1200, br2400, br4800, br9600, br14400, br19200, br38400, br56000, br57600, br115200, br128000, br256000 };
#pragma option pop

#pragma option push -b-
enum TStopBits { sbOneStopBit, sbOne5StopBits, sbTwoStopBits };
#pragma option pop

#pragma option push -b-
enum TDataBits { dbFive, dbSix, dbSeven, dbEight };
#pragma option pop

#pragma option push -b-
enum TParityBits { prNone, prOdd, prEven, prMark, prSpace };
#pragma option pop

#pragma option push -b-
enum TDTRFlowControl { dtrDisable, dtrEnable, dtrHandshake };
#pragma option pop

#pragma option push -b-
enum TRTSFlowControl { rtsDisable, rtsEnable, rtsHandshake, rtsToggle };
#pragma option pop

#pragma option push -b-
enum TFlowControl { fcHardware, fcSoftware, fcNone, fcCustom };
#pragma option pop

#pragma option push -b-
enum TComEvent { evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full };
#pragma option pop

typedef Set<TComEvent, evRxChar, evRx80Full>  TComEvents;

#pragma option push -b-
enum TComSignal { csCTS, csDSR, csRing, csRLSD };
#pragma option pop

typedef Set<TComSignal, csCTS, csRLSD>  TComSignals;

#pragma option push -b-
enum TComError { ceFrame, ceRxParity, ceOverrun, ceBreak, ceIO, ceMode, ceRxOver, ceTxFull };
#pragma option pop

typedef Set<TComError, ceFrame, ceTxFull>  TComErrors;

#pragma option push -b-
enum TSyncMethod { smThreadSync, smWindowSync, smNone, smDisableEvents };
#pragma option pop

#pragma option push -b-
enum TStoreType { stRegistry, stIniFile };
#pragma option pop

#pragma option push -b-
enum TStoredProp { spBasic, spFlowControl, spBuffer, spTimeouts, spParity, spOthers };
#pragma option pop

typedef Set<TStoredProp, spBasic, spOthers>  TStoredProps;

#pragma option push -b-
enum TComLinkEvent { leConn, leCTS, leDSR, leRLSD, leRing, leRx, leTx, leTxEmpty, leRxFlag };
#pragma option pop

typedef void __fastcall (__closure *TRxCharEvent)(System::TObject* Sender, int Count);

typedef void __fastcall (__closure *TRxBufEvent)(System::TObject* Sender, const char * Buffer, int Count);

typedef void __fastcall (__closure *TComErrorEvent)(System::TObject* Sender, TComErrors Errors);

typedef void __fastcall (__closure *TComSignalEvent)(System::TObject* Sender, bool OnOff);

#pragma option push -b-
enum TOperationKind { okWrite, okRead };
#pragma option pop

#pragma pack(push,4)
struct TCPortAsync
{
	
public:
	_OVERLAPPED Overlapped;
	TOperationKind Kind;
	char *Data;
	int Size;
} ;
#pragma pack(pop)

typedef TCPortAsync *PCPortAsync;

//-- var, const, procedure ---------------------------------------------------
extern PACKAGE AnsiString __fastcall ComErrorsToStr(TComErrors Errors);

}	/* namespace Cporttypes */
using namespace Cporttypes;
#pragma pack(pop)
#pragma option pop

#pragma delphiheader end.
//-- end unit ----------------------------------------------------------------
#endif	// Cporttypes
