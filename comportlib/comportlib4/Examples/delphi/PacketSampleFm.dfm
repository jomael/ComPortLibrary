object Form7: TForm7
  Left = 0
  Top = 0
  Caption = 'Packet Sample'
  ClientHeight = 337
  ClientWidth = 527
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 32
    Top = 88
    Width = 67
    Height = 13
    Caption = 'received This:'
  end
  object Label2: TLabel
    Left = 32
    Top = 51
    Width = 77
    Height = 13
    Caption = 'packet end char'
  end
  object Button1: TButton
    Left = 16
    Top = 8
    Width = 75
    Height = 25
    Caption = 'send this:'
    TabOrder = 0
    OnClick = Button1Click
  end
  object showResp: TEdit
    Left = 132
    Top = 85
    Width = 325
    Height = 21
    Color = 16777151
    ReadOnly = True
    TabOrder = 1
  end
  object SpinEdit1: TSpinEdit
    Left = 132
    Top = 48
    Width = 121
    Height = 22
    MaxValue = 255
    MinValue = 0
    TabOrder = 2
    Value = 13
  end
  object editSend: TEdit
    Left = 132
    Top = 8
    Width = 185
    Height = 21
    Color = 13369071
    TabOrder = 3
    Text = 'HELLO'
  end
  object CheckBox1: TCheckBox
    Left = 332
    Top = 12
    Width = 125
    Height = 17
    Caption = 'Append CR (#13)'
    TabOrder = 4
  end
  object ComPort1: TComPort
    BaudRate = br19200
    Port = 'COM4'
    Parity.Bits = prNone
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    Left = 348
    Top = 44
  end
  object ComDataPacket1: TComDataPacket
    ComPort = ComPort1
    OnPacket = ComDataPacket1Packet
    Left = 416
    Top = 44
  end
end
