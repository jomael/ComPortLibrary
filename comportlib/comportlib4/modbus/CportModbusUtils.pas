unit CportModbusUtils;
{$R-}
{$Q-} // Overflow Checking Off
// Modbus Checksum Routines

interface

uses Windows,Classes,SysUtils, CportTimerUtils;

const
// MODBUS_CRC precalculated array for quicker
// calculations.
constHighValue : array [0..255] of Byte =
($00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0,
$80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$00, $C1, $81, $40, $01, $C0, $80, $41, $00, $C1,
$81, $40, $01, $C0, $80, $41, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $00, $C1,
$81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
$01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1,
$81, $40, $01, $C0, $80, $41, $00, $C1, $81, $40,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
$01, $C0, $80, $41, $00, $C1, $81, $40, $01, $C0,
$80, $41, $01, $C0, $80, $41, $00, $C1, $81, $40,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $00, $C1, $81, $40, $01, $C0,
$80, $41, $00, $C1, $81, $40, $01, $C0, $80, $41,
$01, $C0, $80, $41, $00, $C1, $81, $40, $01, $C0,
$80, $41, $00, $C1, $81, $40, $00, $C1, $81, $40,
$01, $C0, $80, $41, $01, $C0, $80, $41, $00, $C1,
$81, $40, $00, $C1, $81, $40, $01, $C0, $80, $41,
$00, $C1, $81, $40, $01, $C0, $80, $41, $01, $C0,
$80, $41, $00, $C1, $81, $40);

constLowValue : array [0..255] of Byte =
($00, $C0, $C1, $01, $C3, $03, $02, $C2, $C6, $06,
$07, $C7, $05, $C5, $C4, $04, $CC, $0C, $0D, $CD,
$0F, $CF, $CE, $0E, $0A, $CA, $CB, $0B, $C9, $09,
$08, $C8, $D8, $18, $19, $D9, $1B, $DB, $DA, $1A,
$1E, $DE, $DF, $1F, $DD, $1D, $1C, $DC, $14, $D4,
$D5, $15, $D7, $17, $16, $D6, $D2, $12, $13, $D3,
$11, $D1, $D0, $10, $F0, $30, $31, $F1, $33, $F3,
$F2, $32, $36, $F6, $F7, $37, $F5, $35, $34, $F4,
$3C, $FC, $FD, $3D, $FF, $3F, $3E, $FE, $FA, $3A,
$3B, $FB, $39, $F9, $F8, $38, $28, $E8, $E9, $29,
$EB, $2B, $2A, $EA, $EE, $2E, $2F, $EF, $2D, $ED,
$EC, $2C, $E4, $24, $25, $E5, $27, $E7, $E6, $26,
$22, $E2, $E3, $23, $E1, $21, $20, $E0, $A0, $60,
$61, $A1, $63, $A3, $A2, $62, $66, $A6, $A7, $67,
$A5, $65, $64, $A4, $6C, $AC, $AD, $6D, $AF, $6F,
$6E, $AE, $AA, $6A, $6B, $AB, $69, $A9, $A8, $68,
$78, $B8, $B9, $79, $BB, $7B, $7A, $BA, $BE, $7E,
$7F, $BF, $7D, $BD, $BC, $7C, $B4, $74, $75, $B5,
$77, $B7, $B6, $76, $72, $B2, $B3, $73, $B1, $71,
$70, $B0, $50, $90, $91, $51, $93, $53, $52, $92,
$96, $56, $57, $97, $55, $95, $94, $54, $9C, $5C,
$5D, $9D, $5F, $9F, $9E, $5E, $5A, $9A, $9B, $5B,
$99, $59, $58, $98, $88, $48, $49, $89, $4B, $8B,
$8A, $4A, $4E, $8E, $8F, $4F, $8D, $4D, $4C, $8C,
$44, $84, $85, $45, $87, $47, $46, $86, $82, $42,
$43, $83, $41, $81, $80, $40);


{ Functions (no classes or objects), used directly in the reading
   and writing of Modbus packets, calculation of Modbus CRCs, and
   in the operation of the Modbus component itself, not expected
   to be generally useful except if you are reading/writing modbus
   packets.
}



// Passed a TPacket pointer deallocate packet ensures that subpointers are properly freed as well.
//procedure DeallocatePacket(Packet : pointer);

// CalculateASCIILRC is used for calculating the LRC of ASCII blocks.
function CalculateASCIILRC(FASCIIString : PChar; FASCIILength: Integer) : Byte;
// Calculate RTU CRC is used to calculate the 16-bit CRC for RTU blocks.
function CalculateRTUCRC(PacketPointer : PChar;PacketLength : Integer) : Word;

// !!!NEW!!!
// Create one custom command:
function ModbusCustomString(SlaveAddress:Integer; PatternStr:String):String;
// Create an entire sequence of custom commands:
function ModbusCustomSequence(SlaveAddress:Integer; PatternStrList:String; Sequence:TStrings):Boolean;



implementation

{ Private function needed by ModbusCustomSequence }
function _StrSplitTStrings( const inString:String; const splitChar,quoteChar:Char; OutStrings:TStrings):Integer;
var
  t,Len,SplitCounter:Integer;
  Ch:Char;
  inQuotes:Boolean;
  Line:String;
begin
   inQuotes := false;
   Len := Length(inString);
   SplitCounter := 0;
   for t := 1 to Len do begin
        Ch := inString[t];
        if (Ch = splitChar) and (not inQuotes) then begin
                Inc(SplitCounter);
                OutStrings.Add(Line);
                Line := '';
        end else begin
                Line := Line + ch;
                if (Ord(QuoteChar)>0) and (ch = quoteChar) then
                    inQuotes := not inQuotes;
        end;
   end;
   Inc(SplitCounter);
   OutStrings.Add(Line);
   Line := '';
   result := SplitCounter; 
end;


// Given a comma separated list of ModbusCustomStrings, we create an entire sequence.
function ModbusCustomSequence(SlaveAddress:Integer; PatternStrList:String; Sequence:TStrings):Boolean;
var
  t:Integer;
  foo:String;
begin
  result := false;
  _StrSplitTStrings(PatternStrList,',',Chr(0),Sequence);
  for t := 0 to Sequence.Count-1 do begin
    //OutputDebugString(PChar('ModbusCustomSequence: Sequence['+IntToStr(t)+'] = '+Sequence[t]));
    foo := ModbusCustomString(SlaveAddress, Sequence[t]); // Let ModbusCustomString do the translation internally!
    if Length(foo)<>8 then begin
{$ifdef DEBUGINFO_ON}
        OutputDebugString('ModbusThread.pas: ModbusCustomSequence: Unusual result from ModbusCustomString');
{$endif}
        foo := ModbusCustomString(SlaveAddress, Sequence[t]); // Let ModbusCustomString do the translation internally!
    end;
    Sequence[t] := foo;
  end;
  if Sequence.Count>0 then
      result := true;
end;

//-----------------------------------------------------------------------------
// ModbusCustomString {NEW}
// Given a string like '{id}0615000000{crc}', replace {id} with SlaveAddress,
// and {crc} with a valid crc.
// Used to make custom guard strings for the CAL 3300 and other similar
// devices, in the unlikely event we ever have one. :-)
//-----------------------------------------------------------------------------
function ModbusCustomString(SlaveAddress:Integer; PatternStr:String):String;
var
   TempStr:String;
   t,EndPos:Integer;
   CrcFlag:Boolean;
   Crc:Word;
begin
   result := '';
   TempStr := StringReplace( PatternStr,'{id}',IntToHex(SlaveAddress,2),[] );
   EndPos := Pos('{crc}',TempStr);
   CrcFlag  := false;
   if EndPos>0 then begin
      TempStr := Copy(TempStr, 1,EndPos-1);
      CrcFlag := true;
   end;
   EndPos := Length(TempStr);
   // Hex Decode:
   for t := 0 to ((EndPos-1) div 2)  do begin
      result := result + Chr( StrToIntDef( '$'+Copy(TempStr,1+(t*2),2), 0 ) );
   end;
   if CrcFlag then begin
      Crc := CalculateRTUCRC( PChar(result), Length(result) );
      result := result +Chr(crc div $100); // high crc byte first
      result := result +Chr(crc and $0FF); // low crc byte last

   end;
end;


// Used to calculate the LRC value for receiving or sending in ASCII mode.
// Passed as a block it returns a byte.
function CalculateASCIILRC(FASCIIString : PChar; FASCIILength: Integer) : Byte;
var
   FLRCValue : Byte;
   FCounter : Integer;
begin
   FLRCValue := 0;
   for FCounter := 0 to (FASCIILength-1) do begin
      FLRCValue := FLRCValue + Byte(FASCIIString[FCounter]);
   end;
   FLRCValue := FLRCValue xor 255;
   FLRCValue := FLRCValue + 1;

   Result := FLRCValue;
end;

// Used to calculate the CRC value for receiving or sending in RTU mode.
// Passed a block it returns a 16-bit word which contains a two-byte crc-16
function CalculateRTUCRC(PacketPointer : PChar;PacketLength : Integer) : Word;
var
   FCounter : Integer;
   FIndex : Byte;
   FLowCRC, FHighCRC : Byte;
   FString : string;
begin
   Result := 0;
   if (PacketPointer = Nil) then exit;
   if (PacketLength = 0) then exit;

   FLowCRC := 255;
   FHighCRC := 255;

   FCounter := 0;
   while (FCounter <= PacketLength-1) do begin
      FString := FString + IntToHex(Integer(PacketPointer[FCounter]),2);
      FIndex := FHighCRC xor Byte(PacketPointer[FCounter]);
      FHighCRC := FLowCRC xor constHighValue[FIndex];
      FLowCRC := constLowValue[FIndex];
      Inc(FCounter);
   end;
   Result := (FHighCRC shl 8) or FLowCRC;
end;



end.
