object Form1: TForm1
  Left = 191
  Top = 107
  Caption = 'ComPort Library example'
  ClientHeight = 363
  ClientWidth = 558
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  PixelsPerInch = 96
  TextHeight = 13
  object Memo: TMemo
    Left = 0
    Top = 0
    Width = 433
    Height = 297
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Button_Open: TButton
    Left = 456
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 1
    OnClick = Button_OpenClick
  end
  object Button_Settings: TButton
    Left = 456
    Top = 40
    Width = 75
    Height = 25
    Caption = 'Settings'
    TabOrder = 2
    OnClick = Button_SettingsClick
  end
  object Edit_Data: TEdit
    Left = 440
    Top = 80
    Width = 113
    Height = 21
    TabOrder = 3
    Text = 'ATI4'
  end
  object Button_Send: TButton
    Left = 456
    Top = 104
    Width = 75
    Height = 25
    Caption = 'Send'
    Default = True
    TabOrder = 4
    OnClick = Button_SendClick
  end
  object NewLine_CB: TCheckBox
    Left = 448
    Top = 136
    Width = 89
    Height = 17
    Caption = 'Send new line'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
  object Panel1: TPanel
    Left = 0
    Top = 304
    Width = 433
    Height = 57
    BevelInner = bvRaised
    BevelOuter = bvLowered
    TabOrder = 6
    object ComLed1: TComLed
      Left = 112
      Top = 8
      Width = 25
      Height = 25
      ComPort = ComPort
      LedSignal = lsCTS
      Kind = lkPurpleLight
      RingDuration = 0
    end
    object ComLed2: TComLed
      Left = 144
      Top = 8
      Width = 25
      Height = 25
      ComPort = ComPort
      LedSignal = lsDSR
      Kind = lkPurpleLight
      RingDuration = 0
    end
    object ComLed3: TComLed
      Left = 176
      Top = 8
      Width = 25
      Height = 25
      ComPort = ComPort
      LedSignal = lsRLSD
      Kind = lkPurpleLight
      RingDuration = 0
    end
    object ComLed4: TComLed
      Left = 256
      Top = 8
      Width = 25
      Height = 25
      ComPort = ComPort
      LedSignal = lsRing
      Kind = lkYellowLight
      RingDuration = 0
    end
    object Label2: TLabel
      Left = 112
      Top = 32
      Width = 21
      Height = 13
      Caption = 'CTS'
    end
    object Label3: TLabel
      Left = 144
      Top = 32
      Width = 23
      Height = 13
      Caption = 'DSR'
    end
    object Label4: TLabel
      Left = 176
      Top = 32
      Width = 29
      Height = 13
      Caption = 'RLSD'
    end
    object Label5: TLabel
      Left = 256
      Top = 32
      Width = 22
      Height = 13
      Caption = 'Ring'
    end
    object ComLed5: TComLed
      Left = 344
      Top = 8
      Width = 25
      Height = 25
      ComPort = ComPort
      LedSignal = lsTx
      Kind = lkRedLight
      RingDuration = 0
    end
    object ComLed6: TComLed
      Left = 376
      Top = 8
      Width = 25
      Height = 25
      ComPort = ComPort
      LedSignal = lsRx
      Kind = lkRedLight
      RingDuration = 0
    end
    object Label1: TLabel
      Left = 350
      Top = 32
      Width = 12
      Height = 13
      Caption = 'Tx'
    end
    object Label6: TLabel
      Left = 382
      Top = 32
      Width = 13
      Height = 13
      Caption = 'Rx'
    end
  end
  object Bt_Store: TButton
    Left = 456
    Top = 256
    Width = 75
    Height = 25
    Caption = 'Store'
    TabOrder = 7
    OnClick = Bt_StoreClick
  end
  object Bt_Load: TButton
    Left = 456
    Top = 296
    Width = 75
    Height = 25
    Caption = 'Load'
    TabOrder = 8
    OnClick = Bt_LoadClick
  end
  object ComPort: TComPort
    BaudRate = br1200
    Port = 'COM1'
    Parity.Bits = prNone
    StopBits = sbOneStopBit
    DataBits = dbEight
    DiscardNull = True
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrEnable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    OnAfterOpen = ComPortOpen
    OnAfterClose = ComPortClose
    OnBeforeOpen = ComPortBeforeOpen
    OnRxChar = ComPortRxChar
    Left = 384
    Top = 8
  end
end
