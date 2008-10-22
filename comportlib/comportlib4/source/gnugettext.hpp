// CodeGear C++Builder
// Copyright (c) 1995, 2007 by CodeGear
// All rights reserved

// (DO NOT EDIT: machine generated header) 'Gnugettext.pas' rev: 11.00

#ifndef GnugettextHPP
#define GnugettextHPP

#pragma delphiheader begin
#pragma option push
#pragma option -w-      // All warnings off
#pragma option -Vx      // Zero-length empty class member functions
#pragma pack(push,8)
#include <System.hpp>	// Pascal unit
#include <Sysinit.hpp>	// Pascal unit
#include <Classes.hpp>	// Pascal unit
#include <Sysutils.hpp>	// Pascal unit
#include <Typinfo.hpp>	// Pascal unit

//-- user supplied -----------------------------------------------------------

namespace Gnugettext
{
//-- type declarations -------------------------------------------------------
typedef void __fastcall (__closure *TTranslator)(System::TObject* obj);

class DELPHICLASS TExecutable;
class PASCALIMPLEMENTATION TExecutable : public System::TObject 
{
	typedef System::TObject inherited;
	
public:
	virtual void __fastcall Execute(void) = 0 ;
public:
	#pragma option push -w-inl
	/* TObject.Create */ inline __fastcall TExecutable(void) : System::TObject() { }
	#pragma option pop
	#pragma option push -w-inl
	/* TObject.Destroy */ inline __fastcall virtual ~TExecutable(void) { }
	#pragma option pop
	
};


typedef int __fastcall (*TGetPluralForm)(int Number);

class DELPHICLASS TGnuGettextInstance;
class PASCALIMPLEMENTATION TGnuGettextInstance : public System::TObject 
{
	typedef System::TObject inherited;
	
public:
	bool Enabled;
	__fastcall TGnuGettextInstance(void);
	__fastcall virtual ~TGnuGettextInstance(void);
	void __fastcall UseLanguage(AnsiString LanguageCode);
	WideString __fastcall gettext(const WideString szMsgId);
	WideString __fastcall ngettext(const WideString singular, const WideString plural, int Number);
	AnsiString __fastcall GetCurrentLanguage();
	WideString __fastcall GetTranslationProperty(AnsiString Propertyname);
	WideString __fastcall GetTranslatorNameAndEmail();
	void __fastcall TP_Ignore(System::TObject* AnObject, const AnsiString name);
	void __fastcall TP_GlobalIgnoreClass(TMetaClass* IgnClass);
	void __fastcall TP_GlobalIgnoreClassProperty(TMetaClass* IgnClass, AnsiString propertyname);
	void __fastcall TP_GlobalHandleClass(TMetaClass* HClass, TTranslator Handler);
	TExecutable* __fastcall TP_CreateRetranslator(void);
	void __fastcall TranslateProperties(System::TObject* AnObject, AnsiString textdomain = "");
	void __fastcall TranslateComponent(Classes::TComponent* AnObject, AnsiString TextDomain = "");
	WideString __fastcall dgettext(const AnsiString szDomain, const WideString szMsgId);
	WideString __fastcall dngettext(const WideString szDomain, const WideString singular, const WideString plural, int Number);
	void __fastcall textdomain(const AnsiString szDomain);
	AnsiString __fastcall getcurrenttextdomain();
	void __fastcall bindtextdomain(const AnsiString szDomain, const AnsiString szDirectory);
	void __fastcall SaveUntranslatedMsgids(AnsiString filename);
	
protected:
	void __fastcall TranslateStrings(Classes::TStrings* sl, AnsiString TextDomain);
	
private:
	AnsiString curlang;
	TGetPluralForm curGetPluralForm;
	AnsiString curmsgdomain;
	Sysutils::TMultiReadExclusiveWriteSynchronizer* savefileCS;
	TextFile savefile;
	Classes::TStringList* savememory;
	AnsiString DefaultDomainDirectory;
	Classes::TStringList* domainlist;
	Classes::TStringList* TP_IgnoreList;
	Classes::TList* TP_ClassHandling;
	TExecutable* TP_Retranslator;
	void __fastcall SaveCheck(WideString szMsgId);
	void __fastcall TranslateProperty(System::TObject* AnObject, Typinfo::PPropInfo PropInfo, Classes::TStrings* TodoList, AnsiString TextDomain);
};


//-- var, const, procedure ---------------------------------------------------
#define DefaultTextDomain "default"
static const bool RuntimePackageSupportEnabled = false;
extern PACKAGE AnsiString ExecutableFilename;
extern PACKAGE TGnuGettextInstance* DefaultInstance;
extern PACKAGE WideString __fastcall gettext(const WideString szMsgId);
extern PACKAGE WideString __fastcall _(const WideString szMsgId);
extern PACKAGE WideString __fastcall dgettext(const AnsiString szDomain, const WideString szMsgId);
extern PACKAGE WideString __fastcall dngettext(const AnsiString szDomain, const WideString singular, const WideString plural, int Number);
extern PACKAGE WideString __fastcall ngettext(const WideString singular, const WideString plural, int Number);
extern PACKAGE void __fastcall textdomain(const AnsiString szDomain);
extern PACKAGE AnsiString __fastcall getcurrenttextdomain();
extern PACKAGE void __fastcall bindtextdomain(const AnsiString szDomain, const AnsiString szDirectory);
extern PACKAGE void __fastcall TP_Ignore(System::TObject* AnObject, const AnsiString name);
extern PACKAGE void __fastcall TP_GlobalIgnoreClass(TMetaClass* IgnClass);
extern PACKAGE void __fastcall TP_GlobalIgnoreClassProperty(TMetaClass* IgnClass, AnsiString propertyname);
extern PACKAGE void __fastcall TP_GlobalHandleClass(TMetaClass* HClass, TTranslator Handler);
extern PACKAGE void __fastcall TranslateProperties(System::TObject* AnObject, AnsiString TextDomain = "");
extern PACKAGE void __fastcall TranslateComponent(Classes::TComponent* AnObject, AnsiString TextDomain = "");
extern PACKAGE AnsiString __fastcall LoadResStringA(System::PResStringRec ResStringRec);
extern PACKAGE WideString __fastcall GetTranslatorNameAndEmail();
extern PACKAGE void __fastcall UseLanguage(AnsiString LanguageCode);
extern PACKAGE WideString __fastcall LoadResString(System::PResStringRec ResStringRec);
extern PACKAGE WideString __fastcall LoadResStringW(System::PResStringRec ResStringRec);
extern PACKAGE AnsiString __fastcall GetCurrentLanguage();
extern PACKAGE bool __fastcall LoadDLLifPossible(AnsiString dllname = "gnu_gettext.dll");
extern PACKAGE void __fastcall AddDomainForResourceString(AnsiString domain);

}	/* namespace Gnugettext */
using namespace Gnugettext;
#pragma pack(pop)
#pragma option pop

#pragma delphiheader end.
//-- end unit ----------------------------------------------------------------
#endif	// Gnugettext
