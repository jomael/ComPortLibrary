(******************************************************
 * ComPort Library ver. 4.0                           *
 *   for Delphi  7, 2007, 2009 and                    *
 *   C++ Builder 3, 4, 5, 6                           *
 * written by Dejan Crnila, 1998 - 2002               *
 * maintained by Lars B. Dybdahl, 2003                *
 *  and Warren Postma, 2008                           *
 *                                                    *
 * Fixed up for Delphi 2009 by W.Postma.  Oct 2008    *
 * More like completely rewritten, actually.          *
 *****************************************************)

 { Terminal Emulation Escape Code Helper Objects }

unit CPortEsc;

{$I CPort.inc}

interface

uses
  Classes;

const
   cportLetters = ['A'..'Z', 'a'..'z'];
type
  // terminal Character result
  TEscapeResult = (erChar, erCode, erNothing);
  // terminal escape codes
  TEscapeCode = (ecUnknown, ecNotCompleted, ecCursorUp, ecCursorDown,
    ecCursorLeft, ecCursorRight, ecCursorHome, ecCursorMove, ecReverseLineFeed,
    ecAppCursorLeft, ecAppCursorRight, ecAppCursorUp, ecAppCursorDown,
    ecEraseLineFrom, ecEraseScreenFrom, ecEraseLine, ecEraseScreen,
    ecSetTab, ecClearTab, ecClearAllTabs,
    ecIdentify, ecIdentResponse, ecQueryDevice, ecReportDeviceOK,
    ecReportDeviceFailure, ecQueryCursorPos, ecReportCursorPos,
    ecAttributes, ecSetMode, ecResetMode, ecReset,
    ecSaveCaretAndAttr, ecRestoreCaretAndAttr, ecSaveCaret, ecRestoreCaret,
    ecTest);

  // terminal escape codes processor
  TEscapeCodes = class
  private
    FCharacter: Char;  { spelling mistake fixed. }
    FCode: TEscapeCode;
    FData: string;
    FParams: TStrings;
  public
    constructor Create;
    destructor Destroy; override;
    function ProcessChar(Ch: Char): TEscapeResult; virtual; abstract;
    function EscCodeToStr(Code: TEscapeCode; AParams: TStrings): AnsiString; virtual; abstract;
    function GetParam(Num: Integer; AParams: TStrings): Integer;
    property Data: string read FData;
    property Code: TEscapeCode read FCode;
    property Character: Char read FCharacter; { spelling mistake fixed. }
    property Params: TStrings read FParams;
  end;

  // VT52 escape codes
  TEscapeCodesVT52 = class(TEscapeCodes)
  private
    FInSequence: Boolean;
    function DetectCode(Str: string): TEscapeCode;
  public
    function ProcessChar(Ch: Char): TEscapeResult; override;
    function EscCodeToStr(Code: TEscapeCode; AParams: TStrings): AnsiString; override;
  end;

  // ANSI/VT100 escape codes
  TEscapeCodesVT100 = class(TEscapeCodes)
  private
    FInSequence: Boolean;
    FInExtSequence: Boolean;
    function DetectCode(Str: string): TEscapeCode;
    function DetectExtCode(Str: string): TEscapeCode;
  public
    function ProcessChar(Ch: Char): TEscapeResult; override;
    function EscCodeToStr(Code: TEscapeCode; AParams: TStrings): AnsiString; override;
  end;

implementation

uses
  SysUtils;

(*****************************************
 * TEscapeCodes class                    *
 *****************************************)

constructor TEscapeCodes.Create;
begin
  inherited Create;
  FParams := TStringList.Create;
end;

destructor TEscapeCodes.Destroy;
begin
  FParams.Free;
  inherited Destroy;
end;

function TEscapeCodes.GetParam(Num: Integer; AParams: TStrings): Integer;
begin
  if (AParams = nil) or (AParams.Count < Num) then
    Result := 1
  else
    try
      Result := StrToInt(AParams[Num - 1]);
    except
      Result := 1;
    end;
end;

(*****************************************
 * TEscapeCodesVT52 class                *
 *****************************************)

// process Character
function TEscapeCodesVT52.ProcessChar(Ch: Char): TEscapeResult;
var
  TempCode: TEscapeCode;
begin
  Result := erNothing;
  if not FInSequence then
  begin
    if Ch = #27 then
    begin
      FData := '';
      FInSequence := True;
    end
    else begin
      FCharacter := Ch;
      Result := erChar;
    end;
  end else
  begin
    FData := FData + Ch;
    TempCode := DetectCode(FData);
    if TempCode <> ecNotCompleted then
    begin
      FCode := TempCode;
      FInSequence := False;
      Result := erCode;
    end;
  end;
end;

// escape code to string
function TEscapeCodesVT52.EscCodeToStr(Code: TEscapeCode; AParams: TStrings): AnsiString;
begin
  case Code of
    ecCursorUp: Result := #27'A';
    ecCursorDown: Result := #27'B';
    ecCursorRight: Result := #27'C';
    ecCursorLeft: Result := #27'D';
    ecCursorHome: Result := #27'H';
    ecReverseLineFeed: Result := #27'I';
    ecEraseScreenFrom: Result := #27'J';
    ecEraseLineFrom: Result := #27'K';
    ecIdentify: Result := #27'Z';
    ecIdentResponse: Result := #27'/Z';
    ecCursorMove: Result := AnsiString( #27'Y' +
      Chr(GetParam(1, AParams) + 31) + Chr(GetParam(2, AParams) + 31));
  else
    Result := '';
  end;
end;

// get escape code from string
function TEscapeCodesVT52.DetectCode(Str: string): TEscapeCode;
begin
  Result := ecUnknown;
  case Str[1] of
    'A': Result := ecCursorUp;
    'B': Result := ecCursorDown;
    'C': Result := ecCursorRight;
    'D': Result := ecCursorLeft;
    'H': Result := ecCursorHome;
    'I': Result := ecReverseLineFeed;
    'J': Result := ecEraseScreenFrom;
    'K': Result := ecEraseLineFrom;
    'Z': Result := ecIdentify;
    '/': begin
           if Length(Str) = 1 then
             Result := ecNotCompleted
           else
             if (Length(Str) = 2) and (Str = '/Z') then
               Result := ecIdentResponse;
         end;
    'Y': begin
           if Length(Str) < 3 then
             Result := ecNotCompleted
           else
           begin
             Result := ecCursorMove;
             FParams.Add(IntToStr(Ord(Str[3]) - 31));
             FParams.Add(IntToStr(Ord(Str[2]) - 31));
           end;
         end;
  end;
end;

(*****************************************
 * TEscapeCodesVT100class                *
 *****************************************)

// process Character
function TEscapeCodesVT100.ProcessChar(Ch: Char): TEscapeResult;
var
  TempCode: TEscapeCode;
begin
  Result := erNothing;
  if not FInSequence then
  begin
    if Ch = #27 then
    begin
      FData := '';
      FInSequence := True;
    end
    else begin
      FCharacter := Ch;
      Result := erChar;
    end;
  end else
  begin
    FData := FData + Ch;
    TempCode := ecNotCompleted;
    if FInExtSequence then
      TempCode := DetectExtCode(FData)
    else
      // Character [ after ESC defines extended escape code
      if FData[1] = '[' then
        FInExtSequence := True
      else
        TempCode := DetectCode(FData);
    if TempCode <> ecNotCompleted then
    begin
      FCode := TempCode;
      FInSequence := False;
      FInExtSequence := False;
      Result := erCode;
    end;
  end;
end;

// escape code to string conversion
function TEscapeCodesVT100.EscCodeToStr(Code: TEscapeCode;
  AParams: TStrings): AnsiString;
var
 s:String;
begin
  case Code of
    ecIdentify: s := #27'[c';
    ecIdentResponse: s := Format(#27'[?1;%dc', [GetParam(1, AParams)]);
    ecQueryCursorPos: s := #27'[6n';
    ecReportCursorPos: s := Format(#27'[%d;%dR', [GetParam(1, AParams), GetParam(2, AParams)]);
    ecQueryDevice: s := #27'[5n';
    ecReportDeviceOK: s := #27'[0n';
    ecReportDeviceFailure: s := #27'[3n';
    ecCursorUp: s := #27'[A';
    ecCursorDown: s := #27'[B';
    ecCursorRight: s := #27'[C';
    ecAppCursorLeft: s := #27'OD';
    ecAppCursorUp: s := #27'OA';
    ecAppCursorDown: s := #27'OB';
    ecAppCursorRight: s := #27'OC';
    ecCursorLeft: s := #27'[D';
    ecCursorHome: s := #27'[H';
    ecCursorMove: s := Format(#27'[%d;%df', [GetParam(1, AParams), GetParam(2, AParams)]);
    ecEraseScreenFrom: s := #27'[J';
    ecEraseLineFrom: s := #27'[K';
    ecEraseScreen: s := #27'[2J';
    ecEraseLine: s := #27'[2K';
    ecSetTab: s := #27'H';
    ecClearTab: s := #27'[g';
    ecClearAllTabs: s := #27'[3g';
    ecAttributes: s := #27'[m'; // popravi
    ecSetMode: s := #27'[h';
    ecResetMode: s := #27'[l';
    ecReset: s := #27'c';
    ecSaveCaret: s := #27'[s';
    ecRestoreCaret: s := #27'[u';
    ecSaveCaretAndAttr: s := #27'7';
    ecRestoreCaretAndAttr: s := #27'8';
    ecTest: s := #27'#8';
  else
    s := '';
  end;
  result := AnsiString(s);
end;

// get vt100 escape code from string
function TEscapeCodesVT100.DetectCode(Str: string): TEscapeCode;
begin
  if Length(Str) = 1 then
    case Str[1] of
      'H': Result := ecSetTab;
      'c': Result := ecReset;
      '7': Result := ecSaveCaretAndAttr;
      '8': Result := ecRestoreCaretAndAttr;
      '#': Result := ecNotCompleted;
      'O': Result := ecNotCompleted;
    else
      Result := ecUnknown;
    end
  else
  begin
    Result := ecUnknown;
    if Str = '#8' then
      Result := ecTest;
    if Str[1] = 'O' then
      case Str[2] of
        'A': Result := ecAppCursorUp;
        'B': Result := ecAppCursorDown;
        'C': Result := ecAppCursorRight;
        'D': Result := ecAppCursorLeft;
      end;
  end;
end;

// get extended vt100 escape code from string
function TEscapeCodesVT100.DetectExtCode(Str: string): TEscapeCode;
var
  LastCh: Char;
  TempParams: TStrings;

  procedure ParseParams(Str: string);
  var
    I: Integer;
    TempStr: string;
  begin
    I := 1;
    TempStr := '';
    while I <= Length(Str) do
    begin
      if (Str[I] = ';') and (TempStr <> '') then
      begin
        TempParams.Add(TempStr);
        TempStr := '';
      end
      else
        TempStr := TempStr + Str[I];
      Inc(I);
    end;
    if (TempStr <> '') then
      TempParams.Add(TempStr);
  end;

  function CodeEraseScreen: TEscapeCode;
  var
    Str: string;
  begin
    if TempParams.Count = 0 then
      Result := ecEraseScreenFrom
    else
    begin
      Str := TempParams[0];
      case Str[1] of
        '0': Result := ecEraseScreenFrom;
        '2': Result := ecEraseScreen;
      else
        Result := ecUnknown;
      end;
    end;
    TempParams.Clear;
  end;

  function CodeEraseLine: TEscapeCode;
  var
    Str: string;
  begin
    if TempParams.Count = 0 then
      Result := ecEraseLineFrom
    else
    begin
      Str := TempParams[0];
      case Str[1] of
        '0': Result := ecEraseLineFrom;
        '2': Result := ecEraseLine;
      else
        Result := ecUnknown;
      end;
    end;
    TempParams.Clear;
  end;

  function CodeTab: TEscapeCode;
  var
    Str: string;
  begin
    if TempParams.Count = 0 then
      Result := ecClearTab
    else
    begin
      Str := TempParams[0];
      case Str[1] of
        '0': Result := ecClearTab;
        '3': Result := ecClearAllTabs;
      else
        Result := ecUnknown;
      end;
    end;
    TempParams.Clear;
  end;

  function CodeDevice: TEscapeCode;
  var
    Str: string;
  begin
    if TempParams.Count = 0 then
      Result := ecUnknown
    else
    begin
      Str := TempParams[0];
      case Str[1] of
        '5': Result := ecQueryDevice;
        '0': Result := ecReportDeviceOK;
        '3': Result := ecReportDeviceFailure;
        '6': Result := ecQueryCursorPos;
      else
        Result := ecUnknown;
      end;
    end;
    TempParams.Clear;
  end;

  function CodeIdentify: TEscapeCode;
  begin
    if (TempParams.Count = 0) or
      ((TempParams.Count = 1) and (TempParams[0] = '0'))
    then
      Result := ecIdentify
    else
      if (TempParams.Count = 2) and (TempParams[1] = '?1') then
        Result := ecIdentResponse
      else
        Result := ecUnknown;
  end;

begin
  Result := ecNotCompleted;
  LastCh := Str[Length(Str)];
{$IFDEF DELPHI_UNICODE}
  if not SysUtils.CharInSet( LastCH, cportLetters) then
      exit;
{$ELSE}
  if not (LastCh in cportLetters) then
    Exit;
{$ENDIF}
  TempParams := TStringList.Create;
  try
    ParseParams(Copy(Str, 2, Length(Str) - 2));
    case LastCh of
      'A': Result := ecCursorUp;
      'B': Result := ecCursorDown;
      'C': Result := ecCursorRight;
      'D': Result := ecCursorLeft;
      'H': Result := ecCursorHome;
      'f': Result := ecCursorMove;
      'J': Result := CodeEraseScreen;
      'K': Result := CodeEraseLine;
      'g': Result := CodeTab;
      'm': Result := ecAttributes;
      'h': Result := ecSetMode;
      'l': Result := ecResetMode;
      's': Result := ecSaveCaret;
      'u': Result := ecRestoreCaret;
      'n': Result := CodeDevice;
      'c': Result := CodeIdentify;
      'R': Result := ecReportCursorPos;
    else
      Result := ecUnknown;
    end;
    FParams.Assign(TempParams);
  finally
    TempParams.Free;
  end;
end;

end.
