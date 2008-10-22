// CodeGear C++Builder
// Copyright (c) 1995, 2007 by CodeGear
// All rights reserved

// (DO NOT EDIT: machine generated header) 'Cportctl.pas' rev: 11.00

#ifndef CportctlHPP
#define CportctlHPP

#pragma delphiheader begin
#pragma option push
#pragma option -w-      // All warnings off
#pragma option -Vx      // Zero-length empty class member functions
#pragma pack(push,8)
#include <System.hpp>	// Pascal unit
#include <Sysinit.hpp>	// Pascal unit
#include <Classes.hpp>	// Pascal unit
#include <Sysutils.hpp>	// Pascal unit
#include <Controls.hpp>	// Pascal unit
#include <Stdctrls.hpp>	// Pascal unit
#include <Extctrls.hpp>	// Pascal unit
#include <Forms.hpp>	// Pascal unit
#include <Messages.hpp>	// Pascal unit
#include <Graphics.hpp>	// Pascal unit
#include <Windows.hpp>	// Pascal unit
#include <Cport.hpp>	// Pascal unit
#include <Cportesc.hpp>	// Pascal unit
#include <Cporttypes.hpp>	// Pascal unit
#include <Menus.hpp>	// Pascal unit

//-- user supplied -----------------------------------------------------------

namespace Cportctl
{
//-- type declarations -------------------------------------------------------
#pragma option push -b-
enum TComProperty { cpNone, cpPort, cpBaudRate, cpDataBits, cpStopBits, cpParity, cpFlowControl };
#pragma option pop

class DELPHICLASS TComSelect;
class PASCALIMPLEMENTATION TComSelect : public System::TObject 
{
	typedef System::TObject inherited;
	
private:
	AnsiString FPort;
	Cporttypes::TBaudRate FBaudRate;
	Cporttypes::TDataBits FDataBits;
	Cporttypes::TStopBits FStopBits;
	Cporttypes::TParityBits FParity;
	Cporttypes::TFlowControl FFlowControl;
	Classes::TStrings* FItems;
	TComProperty FComProperty;
	Cport::TCustomComPort* FComPort;
	bool FAutoApply;
	void __fastcall SetComProperty(const TComProperty Value);
	
public:
	void __fastcall SelectPort(void);
	void __fastcall SelectBaudRate(void);
	void __fastcall SelectParity(void);
	void __fastcall SelectStopBits(void);
	void __fastcall SelectDataBits(void);
	void __fastcall SelectFlowControl(void);
	void __fastcall Change(const AnsiString Text);
	void __fastcall UpdateSettings(int &ItemIndex);
	void __fastcall ApplySettings(void);
	__property Classes::TStrings* Items = {read=FItems, write=FItems};
	__property TComProperty ComProperty = {read=FComProperty, write=SetComProperty, nodefault};
	__property Cport::TCustomComPort* ComPort = {read=FComPort, write=FComPort};
	__property bool AutoApply = {read=FAutoApply, write=FAutoApply, nodefault};
public:
	#pragma option push -w-inl
	/* TObject.Create */ inline __fastcall TComSelect(void) : System::TObject() { }
	#pragma option pop
	#pragma option push -w-inl
	/* TObject.Destroy */ inline __fastcall virtual ~TComSelect(void) { }
	#pragma option pop
	
};


class DELPHICLASS TComComboBox;
class PASCALIMPLEMENTATION TComComboBox : public Stdctrls::TCustomComboBox 
{
	typedef Stdctrls::TCustomComboBox inherited;
	
private:
	TComSelect* FComSelect;
	bool __fastcall GetAutoApply(void);
	Cport::TCustomComPort* __fastcall GetComPort(void);
	TComProperty __fastcall GetComProperty(void);
	HIDESBASE AnsiString __fastcall GetText();
	void __fastcall SetAutoApply(const bool Value);
	void __fastcall SetComPort(const Cport::TCustomComPort* Value);
	void __fastcall SetComProperty(const TComProperty Value);
	HIDESBASE void __fastcall SetText(const AnsiString Value);
	
protected:
	virtual void __fastcall Notification(Classes::TComponent* AComponent, Classes::TOperation Operation);
	DYNAMIC void __fastcall Change(void);
	
public:
	__fastcall virtual TComComboBox(Classes::TComponent* AOwner);
	__fastcall virtual ~TComComboBox(void);
	void __fastcall ApplySettings(void);
	void __fastcall UpdateSettings(void);
	
__published:
	__property Cport::TCustomComPort* ComPort = {read=GetComPort, write=SetComPort};
	__property TComProperty ComProperty = {read=GetComProperty, write=SetComProperty, default=0};
	__property bool AutoApply = {read=GetAutoApply, write=SetAutoApply, default=0};
	__property AnsiString Text = {read=GetText, write=SetText};
	__property Style  = {default=0};
	__property Color  = {default=-16777211};
	__property Ctl3D ;
	__property DragCursor  = {default=-12};
	__property DragMode  = {default=0};
	__property DropDownCount  = {default=8};
	__property Enabled  = {default=1};
	__property Font ;
	__property ImeMode  = {default=3};
	__property ImeName ;
	__property ItemHeight ;
	__property ItemIndex ;
	__property ParentColor  = {default=0};
	__property ParentCtl3D  = {default=1};
	__property ParentFont  = {default=1};
	__property ParentShowHint  = {default=1};
	__property PopupMenu ;
	__property ShowHint ;
	__property TabOrder  = {default=-1};
	__property TabStop  = {default=1};
	__property Visible  = {default=1};
	__property Anchors  = {default=3};
	__property BiDiMode ;
	__property CharCase  = {default=0};
	__property Constraints ;
	__property DragKind  = {default=0};
	__property ParentBiDiMode  = {default=1};
	__property OnChange ;
	__property OnClick ;
	__property OnDblClick ;
	__property OnDragDrop ;
	__property OnDragOver ;
	__property OnDrawItem ;
	__property OnDropDown ;
	__property OnEndDrag ;
	__property OnEnter ;
	__property OnExit ;
	__property OnKeyDown ;
	__property OnKeyPress ;
	__property OnKeyUp ;
	__property OnMeasureItem ;
	__property OnStartDrag ;
	__property OnEndDock ;
	__property OnStartDock ;
	__property OnContextPopup ;
public:
	#pragma option push -w-inl
	/* TWinControl.CreateParented */ inline __fastcall TComComboBox(HWND ParentWindow) : Stdctrls::TCustomComboBox(ParentWindow) { }
	#pragma option pop
	
};


class DELPHICLASS TComRadioGroup;
class PASCALIMPLEMENTATION TComRadioGroup : public Extctrls::TCustomRadioGroup 
{
	typedef Extctrls::TCustomRadioGroup inherited;
	
private:
	TComSelect* FComSelect;
	int FOldIndex;
	bool __fastcall GetAutoApply(void);
	Cport::TCustomComPort* __fastcall GetComPort(void);
	TComProperty __fastcall GetComProperty(void);
	void __fastcall SetAutoApply(const bool Value);
	void __fastcall SetComPort(const Cport::TCustomComPort* Value);
	void __fastcall SetComProperty(const TComProperty Value);
	
protected:
	virtual void __fastcall Notification(Classes::TComponent* AComponent, Classes::TOperation Operation);
	DYNAMIC void __fastcall Click(void);
	
public:
	__fastcall virtual TComRadioGroup(Classes::TComponent* AOwner);
	__fastcall virtual ~TComRadioGroup(void);
	void __fastcall ApplySettings(void);
	void __fastcall UpdateSettings(void);
	
__published:
	__property Cport::TCustomComPort* ComPort = {read=GetComPort, write=SetComPort};
	__property TComProperty ComProperty = {read=GetComProperty, write=SetComProperty, default=0};
	__property bool AutoApply = {read=GetAutoApply, write=SetAutoApply, default=0};
	__property Align  = {default=0};
	__property Caption ;
	__property Color  = {default=-16777211};
	__property Ctl3D ;
	__property DragCursor  = {default=-12};
	__property DragMode  = {default=0};
	__property Enabled  = {default=1};
	__property Font ;
	__property ItemIndex  = {default=-1};
	__property ParentColor  = {default=1};
	__property ParentCtl3D  = {default=1};
	__property ParentFont  = {default=1};
	__property ParentShowHint  = {default=1};
	__property PopupMenu ;
	__property ShowHint ;
	__property TabOrder  = {default=-1};
	__property TabStop  = {default=0};
	__property Visible  = {default=1};
	__property Anchors  = {default=3};
	__property BiDiMode ;
	__property Constraints ;
	__property DockSite  = {default=0};
	__property DragKind  = {default=0};
	__property ParentBiDiMode  = {default=1};
	__property OnClick ;
	__property OnDblClick ;
	__property OnDragDrop ;
	__property OnDragOver ;
	__property OnEndDrag ;
	__property OnStartDrag ;
	__property OnEnter ;
	__property OnExit ;
	__property OnMouseMove ;
	__property OnMouseUp ;
	__property OnMouseDown ;
	__property OnEndDock ;
	__property OnStartDock ;
	__property OnGetSiteInfo ;
	__property OnDockDrop ;
	__property OnDockOver ;
	__property OnUnDock ;
	__property OnContextPopup ;
public:
	#pragma option push -w-inl
	/* TWinControl.CreateParented */ inline __fastcall TComRadioGroup(HWND ParentWindow) : Extctrls::TCustomRadioGroup(ParentWindow) { }
	#pragma option pop
	
};


#pragma option push -b-
enum TLedKind { lkRedLight, lkGreenLight, lkBlueLight, lkYellowLight, lkPurpleLight, lkBulb, lkCustom };
#pragma option pop

#pragma option push -b-
enum TComLedSignal { lsConn, lsCTS, lsDSR, lsRLSD, lsRing, lsRx, lsTx };
#pragma option pop

#pragma option push -b-
enum TLedState { lsOff, lsOn };
#pragma option pop

typedef void __fastcall (__closure *TLedStateEvent)(System::TObject* Sender, TLedState AState);

class DELPHICLASS TLedBitmap;
class PASCALIMPLEMENTATION TLedBitmap : public Graphics::TBitmap 
{
	typedef Graphics::TBitmap inherited;
	
public:
	#pragma option push -w-inl
	/* TBitmap.Create */ inline __fastcall virtual TLedBitmap(void) : Graphics::TBitmap() { }
	#pragma option pop
	#pragma option push -w-inl
	/* TBitmap.Destroy */ inline __fastcall virtual ~TLedBitmap(void) { }
	#pragma option pop
	
};


typedef TLedBitmap* TComLedGlyphs[2];

class DELPHICLASS TComLed;
class PASCALIMPLEMENTATION TComLed : public Controls::TGraphicControl 
{
	typedef Controls::TGraphicControl inherited;
	
private:
	Cport::TComPort* FComPort;
	TComLedSignal FLedSignal;
	TLedKind FKind;
	TLedState FState;
	TLedState FPendingState;
	TLedStateEvent FOnChange;
	TLedBitmap* FGlyphs[2];
	Cport::TComLink* FComLink;
	int FRingDuration;
	Extctrls::TTimer* FTimer;
	bool FPendingInvalidate;
	TLedBitmap* __fastcall GetGlyph(const int Index);
	void __fastcall SetComPort(const Cport::TComPort* Value);
	void __fastcall SetKind(const TLedKind Value);
	void __fastcall SetState(const TLedState Value);
	void __fastcall SetLedSignal(const TComLedSignal Value);
	void __fastcall SetGlyph(const int Index, const TLedBitmap* Value);
	bool __fastcall StoredGlyph(const int Index);
	void __fastcall SelectLedBitmap(const TLedKind LedKind);
	void __fastcall SetStateInternal(const TLedState Value);
	Types::TPoint __fastcall CalcBitmapPos();
	TLedBitmap* __fastcall BitmapToDraw(void);
	void __fastcall BitmapNeeded(void);
	void __fastcall SignalChange(System::TObject* Sender, bool OnOff);
	void __fastcall RingDetect(System::TObject* Sender);
	void __fastcall DoTimer(System::TObject* Sender);
	bool __fastcall IsStateOn(void);
	
protected:
	virtual void __fastcall Paint(void);
	virtual void __fastcall Notification(Classes::TComponent* AComponent, Classes::TOperation Operation);
	DYNAMIC void __fastcall DoChange(TLedState AState);
	HIDESBASE MESSAGE void __fastcall CMEnabledChanged(Messages::TMessage &Message);
	
public:
	__fastcall virtual TComLed(Classes::TComponent* AOwner);
	__fastcall virtual ~TComLed(void);
	
__published:
	__property Cport::TComPort* ComPort = {read=FComPort, write=SetComPort};
	__property TComLedSignal LedSignal = {read=FLedSignal, write=SetLedSignal, nodefault};
	__property TLedKind Kind = {read=FKind, write=SetKind, nodefault};
	__property TLedBitmap* GlyphOn = {read=GetGlyph, write=SetGlyph, stored=StoredGlyph, index=0};
	__property TLedBitmap* GlyphOff = {read=GetGlyph, write=SetGlyph, stored=StoredGlyph, index=1};
	__property TLedState State = {read=FState, write=SetState, default=0};
	__property int RingDuration = {read=FRingDuration, write=FRingDuration, default=1000};
	__property Align  = {default=0};
	__property DragCursor  = {default=-12};
	__property DragMode  = {default=0};
	__property Enabled  = {default=1};
	__property ParentShowHint  = {default=1};
	__property PopupMenu ;
	__property ShowHint ;
	__property Visible  = {default=1};
	__property Anchors  = {default=3};
	__property Constraints ;
	__property DragKind  = {default=0};
	__property ParentBiDiMode  = {default=1};
	__property TLedStateEvent OnChange = {read=FOnChange, write=FOnChange};
	__property OnClick ;
	__property OnDblClick ;
	__property OnDragDrop ;
	__property OnDragOver ;
	__property OnEndDrag ;
	__property OnMouseDown ;
	__property OnMouseMove ;
	__property OnMouseUp ;
	__property OnStartDrag ;
	__property OnEndDock ;
	__property OnResize ;
	__property OnStartDock ;
	__property OnContextPopup ;
};


#pragma pack(push,4)
struct TComTermChar
{
	
public:
	char Ch;
	Graphics::TColor FrontColor;
	Graphics::TColor BackColor;
	bool Underline;
} ;
#pragma pack(pop)

class DELPHICLASS TComTermBuffer;
class DELPHICLASS TCustomComTerminal;
#pragma option push -b-
enum TArrowKeys { akTerminal, akWindows };
#pragma option pop

#pragma option push -b-
enum TTermEmulation { teVT100orANSI, teVT52, teNone };
#pragma option pop

#pragma option push -b-
enum TTermCaret { tcBlock, tcUnderline, tcNone };
#pragma option pop

#pragma pack(push,4)
struct TTermAttributes
{
	
public:
	Graphics::TColor FrontColor;
	Graphics::TColor BackColor;
	bool Invert;
	bool AltIntensity;
	bool Underline;
} ;
#pragma pack(pop)

#pragma pack(push,1)
struct TTermMode
{
	
public:
	TArrowKeys Keys;
} ;
#pragma pack(pop)

typedef void __fastcall (__closure *TChScreenEvent)(System::TObject* Sender, char Ch);

typedef void __fastcall (__closure *TEscapeEvent)(System::TObject* Sender, Cportesc::TEscapeCodes* &EscapeCodes);

typedef void __fastcall (__closure *TUnhandledEvent)(System::TObject* Sender, Cportesc::TEscapeCode Code, AnsiString Data);

typedef void __fastcall (__closure *TStrRecvEvent)(System::TObject* Sender, AnsiString &Str);

#pragma option push -b-
enum TAdvanceCaret { acChar, acReturn, acLineFeed, acReverseLineFeed, acTab, acBackspace };
#pragma option pop

class PASCALIMPLEMENTATION TCustomComTerminal : public Controls::TCustomControl 
{
	typedef Controls::TCustomControl inherited;
	
private:
	Cport::TComLink* FComLink;
	Cport::TCustomComPort* FComPort;
	Forms::TFormBorderStyle FBorderStyle;
	Stdctrls::TScrollStyle FScrollBars;
	TArrowKeys FArrowKeys;
	bool FWantTab;
	int FColumns;
	int FRows;
	Graphics::TColor FAltColor;
	bool FLocalEcho;
	bool FSendLF;
	bool FAppendLF;
	bool FForce7Bit;
	bool FWrapLines;
	bool FSmoothScroll;
	int FFontHeight;
	int FFontWidth;
	TTermEmulation FEmulation;
	TTermCaret FCaret;
	Types::TPoint FCaretPos;
	Types::TPoint FSaveCaret;
	bool FCaretCreated;
	Types::TPoint FTopLeft;
	int FCaretHeight;
	TTermAttributes FSaveAttr;
	TComTermBuffer* FBuffer;
	Cportesc::TEscapeCodes* FEscapeCodes;
	TTermAttributes FTermAttr;
	TTermMode FTermMode;
	TChScreenEvent FOnChar;
	TEscapeEvent FOnGetEscapeCodes;
	TUnhandledEvent FOnUnhandledCode;
	TStrRecvEvent FOnStrRecieved;
	void __fastcall AdvanceCaret(TAdvanceCaret Kind);
	bool __fastcall CalculateMetrics(void);
	void __fastcall CreateEscapeCodes(void);
	void __fastcall CreateTerminalCaret(void);
	void __fastcall DrawChar(int AColumn, int ARow, const TComTermChar &Ch);
	TComTermChar __fastcall GetCharAttr();
	bool __fastcall GetConnected(void);
	void __fastcall HideCaret(void);
	void __fastcall InitCaret(void);
	void __fastcall InvalidatePortion(const Types::TRect &ARect);
	void __fastcall ModifyScrollBar(int ScrollBar, int ScrollCode, int Pos);
	void __fastcall SetAltColor(const Graphics::TColor Value);
	void __fastcall SetBorderStyle(const Forms::TBorderStyle Value);
	void __fastcall SetColumns(const int Value);
	void __fastcall SetComPort(const Cport::TCustomComPort* Value);
	void __fastcall SetConnected(const bool Value);
	void __fastcall SetEmulation(const TTermEmulation Value);
	void __fastcall SetRows(const int Value);
	void __fastcall SetScrollBars(const Stdctrls::TScrollStyle Value);
	void __fastcall SetCaret(const TTermCaret Value);
	void __fastcall SetAttributes(Classes::TStrings* AParams);
	void __fastcall SetMode(Classes::TStrings* AParams, bool OnOff);
	void __fastcall ShowCaret(void);
	void __fastcall StringReceived(AnsiString Str);
	void __fastcall PaintTerminal(const Types::TRect &Rect);
	void __fastcall PaintDesign(void);
	void __fastcall PutChar(char Ch);
	bool __fastcall PutEscapeCode(Cportesc::TEscapeCode ACode, Classes::TStrings* AParams);
	void __fastcall RestoreAttr(void);
	void __fastcall RestoreCaretPos(void);
	void __fastcall RxBuf(System::TObject* Sender, const char * Buffer, int Count);
	void __fastcall SaveAttr(void);
	void __fastcall SaveCaretPos(void);
	void __fastcall SendChar(char Ch);
	void __fastcall SendCode(Cportesc::TEscapeCode Code, Classes::TStrings* AParams);
	void __fastcall SendCodeNoEcho(Cportesc::TEscapeCode Code, Classes::TStrings* AParams);
	void __fastcall PerformTest(char ACh);
	void __fastcall UpdateScrollPos(void);
	void __fastcall UpdateScrollRange(void);
	
protected:
	HIDESBASE MESSAGE void __fastcall CMCtl3DChanged(Messages::TMessage &Message);
	HIDESBASE MESSAGE void __fastcall CMFontChanged(Messages::TMessage &Message);
	HIDESBASE MESSAGE void __fastcall CMColorChanged(Messages::TMessage &Message);
	MESSAGE void __fastcall WMGetDlgCode(Messages::TWMNoParams &Message);
	HIDESBASE MESSAGE void __fastcall WMHScroll(Messages::TWMScroll &Message);
	HIDESBASE MESSAGE void __fastcall WMKillFocus(Messages::TWMSetFocus &Message);
	HIDESBASE MESSAGE void __fastcall WMLButtonDown(Messages::TWMMouse &Message);
	HIDESBASE MESSAGE void __fastcall WMSetFocus(Messages::TWMSetFocus &Message);
	HIDESBASE MESSAGE void __fastcall WMSize(Messages::TWMSize &Msg);
	HIDESBASE MESSAGE void __fastcall WMVScroll(Messages::TWMScroll &Message);
	virtual bool __fastcall CanAutoSize(int &NewWidth, int &NewHeight);
	virtual void __fastcall CreateParams(Controls::TCreateParams &Params);
	DYNAMIC void __fastcall KeyDown(Word &Key, Classes::TShiftState Shift);
	DYNAMIC void __fastcall KeyPress(char &Key);
	virtual void __fastcall Loaded(void);
	virtual void __fastcall Notification(Classes::TComponent* AComponent, Classes::TOperation Operation);
	virtual void __fastcall Paint(void);
	DYNAMIC void __fastcall DoChar(char Ch);
	DYNAMIC void __fastcall DoGetEscapeCodes(Cportesc::TEscapeCodes* &EscapeCodes);
	DYNAMIC void __fastcall DoStrRecieved(AnsiString &Str);
	DYNAMIC void __fastcall DoUnhandledCode(Cportesc::TEscapeCode Code, AnsiString Data);
	
public:
	void __fastcall SetTermAttrColors(Graphics::TColor FrontColor, Graphics::TColor BackColor, bool AltIntensity, bool Invert);
	__fastcall virtual TCustomComTerminal(Classes::TComponent* AOwner);
	__fastcall virtual ~TCustomComTerminal(void);
	void __fastcall ClearScreen(void);
	void __fastcall MoveCaret(int AColumn, int ARow);
	void __fastcall Write(const char * Buffer, int Size);
	void __fastcall WriteStr(const AnsiString Str);
	void __fastcall WriteEscCode(Cportesc::TEscapeCode ACode, Classes::TStrings* AParams);
	void __fastcall LoadFromStream(Classes::TStream* Stream);
	void __fastcall SaveToStream(Classes::TStream* Stream);
	void __fastcall SelectFont(void);
	void __fastcall ShowSetupDialog(void);
	__property Types::TPoint CaretPos = {read=FCaretPos};
	__property Graphics::TColor AltColor = {read=FAltColor, write=SetAltColor, default=10921638};
	__property bool AppendLF = {read=FAppendLF, write=FAppendLF, default=0};
	__property TArrowKeys ArrowKeys = {read=FArrowKeys, write=FArrowKeys, default=0};
	__property Forms::TBorderStyle BorderStyle = {read=FBorderStyle, write=SetBorderStyle, default=1};
	__property TTermCaret Caret = {read=FCaret, write=SetCaret, default=0};
	__property bool Connected = {read=GetConnected, write=SetConnected, stored=false, nodefault};
	__property Cport::TCustomComPort* ComPort = {read=FComPort, write=SetComPort};
	__property int Columns = {read=FColumns, write=SetColumns, default=80};
	__property TTermEmulation Emulation = {read=FEmulation, write=SetEmulation, nodefault};
	__property Cportesc::TEscapeCodes* EscapeCodes = {read=FEscapeCodes};
	__property bool Force7Bit = {read=FForce7Bit, write=FForce7Bit, default=0};
	__property bool LocalEcho = {read=FLocalEcho, write=FLocalEcho, default=0};
	__property bool SendLF = {read=FSendLF, write=FSendLF, default=0};
	__property Stdctrls::TScrollStyle ScrollBars = {read=FScrollBars, write=SetScrollBars, nodefault};
	__property bool SmoothScroll = {read=FSmoothScroll, write=FSmoothScroll, default=0};
	__property int Rows = {read=FRows, write=SetRows, default=24};
	__property bool WantTab = {read=FWantTab, write=FWantTab, default=0};
	__property bool WrapLines = {read=FWrapLines, write=FWrapLines, default=0};
	__property TChScreenEvent OnChar = {read=FOnChar, write=FOnChar};
	__property TEscapeEvent OnGetEscapeCodes = {read=FOnGetEscapeCodes, write=FOnGetEscapeCodes};
	__property TStrRecvEvent OnStrRecieved = {read=FOnStrRecieved, write=FOnStrRecieved};
	__property TUnhandledEvent OnUnhandledCode = {read=FOnUnhandledCode, write=FOnUnhandledCode};
public:
	#pragma option push -w-inl
	/* TWinControl.CreateParented */ inline __fastcall TCustomComTerminal(HWND ParentWindow) : Controls::TCustomControl(ParentWindow) { }
	#pragma option pop
	
};


class PASCALIMPLEMENTATION TComTermBuffer : public System::TObject 
{
	typedef System::TObject inherited;
	
private:
	void *FBuffer;
	void *FTabs;
	TCustomComTerminal* FOwner;
	
public:
	__fastcall TComTermBuffer(TCustomComTerminal* AOwner);
	__fastcall virtual ~TComTermBuffer(void);
	void __fastcall Init(void);
	void __fastcall SetChar(int Column, int Row, const TComTermChar &TermChar);
	TComTermChar __fastcall GetChar(int Column, int Row);
	void __fastcall SetTab(int Column, bool Put);
	bool __fastcall GetTab(int Column);
	int __fastcall NextTab(int Column);
	void __fastcall ClearAllTabs(void);
	void __fastcall ScrollDown(void);
	void __fastcall ScrollUp(void);
	void __fastcall EraseScreen(int Column, int Row);
	void __fastcall EraseLine(int Column, int Row);
	int __fastcall GetLineLength(int Line);
	int __fastcall GetLastLine(void);
};


class DELPHICLASS TComTerminal;
class PASCALIMPLEMENTATION TComTerminal : public TCustomComTerminal 
{
	typedef TCustomComTerminal inherited;
	
__published:
	__property Align  = {default=0};
	__property AltColor  = {default=10921638};
	__property AppendLF  = {default=0};
	__property ArrowKeys  = {default=0};
	__property BorderStyle  = {default=1};
	__property Color  = {default=-16777211};
	__property Columns  = {default=80};
	__property ComPort ;
	__property Connected ;
	__property Ctl3D ;
	__property DragCursor  = {default=-12};
	__property DragMode  = {default=0};
	__property Emulation ;
	__property Enabled  = {default=1};
	__property Font ;
	__property Force7Bit  = {default=0};
	__property Hint ;
	__property ImeMode  = {default=3};
	__property ImeName ;
	__property LocalEcho  = {default=0};
	__property ParentCtl3D  = {default=1};
	__property ParentShowHint  = {default=1};
	__property PopupMenu ;
	__property Rows  = {default=24};
	__property ScrollBars ;
	__property SendLF  = {default=0};
	__property ShowHint ;
	__property SmoothScroll  = {default=0};
	__property TabOrder  = {default=-1};
	__property TabStop  = {default=1};
	__property Caret  = {default=0};
	__property Visible  = {default=1};
	__property WantTab  = {default=0};
	__property WrapLines  = {default=0};
	__property Anchors  = {default=3};
	__property AutoSize  = {default=0};
	__property Constraints ;
	__property DragKind  = {default=0};
	__property OnChar ;
	__property OnClick ;
	__property OnDblClick ;
	__property OnDragDrop ;
	__property OnDragOver ;
	__property OnEndDrag ;
	__property OnEnter ;
	__property OnExit ;
	__property OnGetEscapeCodes ;
	__property OnKeyDown ;
	__property OnKeyPress ;
	__property OnKeyUp ;
	__property OnMouseDown ;
	__property OnMouseMove ;
	__property OnMouseUp ;
	__property OnStartDrag ;
	__property OnStrRecieved ;
	__property OnUnhandledCode ;
	__property OnCanResize ;
	__property OnConstrainedResize ;
	__property OnDockDrop ;
	__property OnEndDock ;
	__property OnMouseWheel ;
	__property OnMouseWheelDown ;
	__property OnMouseWheelUp ;
	__property OnResize ;
	__property OnStartDock ;
	__property OnUnDock ;
	__property OnContextPopup ;
public:
	#pragma option push -w-inl
	/* TCustomComTerminal.Create */ inline __fastcall virtual TComTerminal(Classes::TComponent* AOwner) : TCustomComTerminal(AOwner) { }
	#pragma option pop
	#pragma option push -w-inl
	/* TCustomComTerminal.Destroy */ inline __fastcall virtual ~TComTerminal(void) { }
	#pragma option pop
	
public:
	#pragma option push -w-inl
	/* TWinControl.CreateParented */ inline __fastcall TComTerminal(HWND ParentWindow) : TCustomComTerminal(ParentWindow) { }
	#pragma option pop
	
};


//-- var, const, procedure ---------------------------------------------------
static const Word RxSanityLimit = 0x400;
extern PACKAGE Graphics::TFont* ComTerminalFont;

}	/* namespace Cportctl */
using namespace Cportctl;
#pragma pack(pop)
#pragma option pop

#pragma delphiheader end.
//-- end unit ----------------------------------------------------------------
#endif	// Cportctl
