object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'MKOS - '#1052#1086#1076#1091#1083#1100#1085#1086#1077' '#1087#1088#1080#1083#1086#1078#1077#1085#1080#1077
  ClientHeight = 592
  ClientWidth = 638
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  ShowHint = True
  OnCreate = FormCreate
  TextHeight = 13
  object mResults: TMemo
    Left = 0
    Top = 341
    Width = 638
    Height = 210
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
    ExplicitWidth = 634
    ExplicitHeight = 209
  end
  object pLower: TPanel
    Left = 0
    Top = 551
    Width = 638
    Height = 41
    Align = alBottom
    TabOrder = 1
    ExplicitTop = 550
    ExplicitWidth = 634
    DesignSize = (
      638
      41)
    object btnViewResults: TButton
      Left = 497
      Top = 6
      Width = 120
      Height = 25
      Anchors = [akTop, akRight]
      Caption = #1054#1095#1080#1089#1090#1080#1090#1100
      TabOrder = 0
      OnClick = btnViewResultsClick
      ExplicitLeft = 493
    end
  end
  object pTasks: TPanel
    Left = 0
    Top = 186
    Width = 638
    Height = 155
    Align = alTop
    TabOrder = 2
    ExplicitWidth = 634
    DesignSize = (
      638
      155)
    object bSelect7z: TSpeedButton
      Left = 606
      Top = 122
      Width = 23
      Height = 23
      Hint = #1053#1072#1081#1090#1080' '#1072#1088#1093#1080#1074#1072#1090#1086#1088' 7z'
      Anchors = [akTop, akRight]
      Caption = '7z'
      OnClick = bSelect7zClick
    end
    object bStartTask: TButton
      Left = 1
      Top = 122
      Width = 119
      Height = 25
      Caption = #1047#1072#1087#1091#1089#1082
      TabOrder = 0
      OnClick = bStartTaskClick
    end
    object bStopTask: TButton
      Left = 134
      Top = 122
      Width = 120
      Height = 25
      Caption = #1057#1090#1086#1087
      TabOrder = 1
      OnClick = bStopTaskClick
    end
    object dbgTasks: TDBGrid
      Left = 1
      Top = 1
      Width = 636
      Height = 115
      Align = alTop
      DataSource = dsTask
      TabOrder = 2
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
    object e7zName: TEdit
      Left = 265
      Top = 124
      Width = 335
      Height = 21
      ReadOnly = True
      TabOrder = 3
      Text = 'C:\Program Files\7-Zip\7z.exe'
    end
  end
  object grpFindFiles: TGroupBox
    Left = 0
    Top = 0
    Width = 638
    Height = 85
    Align = alTop
    Caption = #1055#1086#1080#1089#1082' '#1092#1072#1081#1083#1086#1074
    TabOrder = 3
    ExplicitWidth = 634
    DesignSize = (
      638
      85)
    object lblMasks: TLabel
      Left = 8
      Top = 34
      Width = 76
      Height = 13
      Caption = #1052#1072#1089#1082#1080' '#1092#1072#1081#1083#1086#1074':'
    end
    object bSelectFolder: TSpeedButton
      Left = 607
      Top = 11
      Width = 23
      Height = 23
      Hint = #1042#1099#1073#1088#1072#1090#1100' '#1082#1072#1090#1072#1083#1086#1075'...'
      Anchors = [akTop, akRight]
      Caption = #1050
      OnClick = bSelectFolderClick
      ExplicitLeft = 569
    end
    object eFolder: TEdit
      Left = 8
      Top = 13
      Width = 593
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      TextHint = #1059#1082#1072#1078#1080#1090#1077' '#1082#1072#1090#1072#1083#1086#1075' '#1076#1083#1103' '#1087#1086#1080#1089#1082#1072' '#1092#1072#1081#1083#1086#1074
      ExplicitWidth = 589
    end
    object eMasks: TEdit
      Left = 13
      Top = 53
      Width = 622
      Height = 21
      Hint = #1042#1074#1077#1076#1080#1090#1077' '#1087#1086#1089#1083#1077#1076#1086#1074#1072#1090#1077#1083#1100#1085#1086#1089#1090#1080' '#1095#1077#1088#1077#1079' ";" ('#1085#1072#1087#1088#1080#1084#1077#1088': libsec;binsec)'
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      TextHint = #1042#1074#1077#1076#1080#1090#1077' '#1084#1072#1089#1082#1080' '#1076#1083#1103' '#1087#1088#1089#1080#1082#1072' '#1092#1072#1081#1083#1086#1074' ";" ('#1085#1072#1087#1088#1080#1084#1077#1088': *.dpr;*.txt)'
      ExplicitWidth = 618
    end
  end
  object grpSearchInFile: TGroupBox
    Left = 0
    Top = 85
    Width = 638
    Height = 101
    Align = alTop
    Caption = #1055#1086#1080#1089#1082' '#1074' '#1092#1072#1081#1083#1077
    TabOrder = 4
    ExplicitWidth = 634
    DesignSize = (
      638
      101)
    object lblSearchInFile: TLabel
      Left = 8
      Top = 48
      Width = 216
      Height = 13
      Caption = #1055#1086#1089#1083#1077#1076#1086#1074#1072#1090#1077#1083#1100#1085#1086#1089#1090#1080' '#1076#1083#1103' '#1087#1086#1080#1089#1082#1072' '#1074' '#1092#1072#1081#1083#1077':'
    end
    object bSelectFile: TSpeedButton
      Left = 608
      Top = 20
      Width = 23
      Height = 23
      Hint = #1042#1099#1073#1088#1072#1090#1100' '#1092#1072#1081#1083'...'
      Anchors = [akTop, akRight]
      Caption = #1060
      OnClick = bSelectFileClick
    end
    object eSearchPatterns: TEdit
      Left = 8
      Top = 64
      Width = 551
      Height = 21
      Hint = #1042#1074#1077#1076#1080#1090#1077' '#1087#1086#1089#1083#1077#1076#1086#1074#1072#1090#1077#1083#1100#1085#1086#1089#1090#1080' '#1095#1077#1088#1077#1079' ";" ('#1085#1072#1087#1088#1080#1084#1077#1088': libsec;binsec)'
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      TextHint = #1042#1074#1077#1076#1080#1090#1077' '#1087#1086#1089#1083#1077#1076#1086#1074#1072#1090#1077#1083#1100#1085#1086#1089#1090#1080' '#1095#1077#1088#1077#1079' ";" ('#1085#1072#1087#1088#1080#1084#1077#1088': libsec;binsec)'
      ExplicitWidth = 547
    end
    object cbMatches: TComboBox
      Left = 573
      Top = 64
      Width = 57
      Height = 21
      Hint = #1052#1072#1082#1089#1080#1084#1072#1083#1100#1085#1086#1077' '#1082#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1089#1086#1074#1087#1072#1076#1077#1085#1080#1081
      Anchors = [akTop, akRight]
      ItemIndex = 0
      TabOrder = 1
      Text = '10'
      OnKeyPress = cbMatchesKeyPress
      Items.Strings = (
        '10'
        '50'
        '100'
        '1000')
      ExplicitLeft = 569
    end
    object eFile: TEdit
      Left = 9
      Top = 21
      Width = 593
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 2
      TextHint = #1059#1082#1072#1078#1080#1090#1077' '#1092#1072#1081#1083' '#1076#1083#1103' '#1087#1086#1080#1089#1082#1072' '#1087#1086#1089#1083#1077#1076#1086#1074#1072#1090#1077#1083#1100#1085#1086#1089#1090#1077#1081
      ExplicitWidth = 589
    end
  end
  object OpenDialog: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = #1055#1072#1087#1082#1080
        FileMask = '*.*'
      end>
    Options = [fdoPickFolders]
    Left = 578
    Top = 8
  end
  object cdsTasks: TClientDataSet
    PersistDataPacket.Data = {
      7F0000009619E0BD0100000018000000060000000000030000007F0002494404
      00010000000000045461736B0100490000000100055749445448020002001400
      0653746174757302000100000000000954696D65537461727408000800000000
      000754696D65456E640800080000000000074654687265616408000100000000
      000000}
    Active = True
    Aggregates = <>
    Params = <>
    OnCalcFields = cdsTasksCalcFields
    Left = 480
    Top = 226
    object cdsTasksID: TIntegerField
      DisplayWidth = 10
      FieldName = 'ID'
    end
    object cdsTasksTask: TStringField
      DisplayLabel = #1047#1072#1076#1072#1095#1072
      DisplayWidth = 20
      FieldName = 'Task'
    end
    object cdsTasksStatus: TSmallintField
      FieldName = 'Status'
      Visible = False
    end
    object cdsTasksSStatus: TStringField
      DisplayLabel = #1057#1090#1072#1090#1091#1089
      DisplayWidth = 22
      FieldKind = fkCalculated
      FieldName = 'SStatus'
      Calculated = True
    end
    object cdsTasksTimeStart: TDateTimeField
      DisplayLabel = #1053#1072#1095#1072#1083#1086
      DisplayWidth = 22
      FieldName = 'TimeStart'
      DisplayFormat = 'dd.mm.yy h:n:s.z'
    end
    object cdsTasksTimeEnd: TDateTimeField
      DisplayLabel = #1047#1072#1074#1077#1088#1096#1077#1085#1080#1077
      DisplayWidth = 21
      FieldName = 'TimeEnd'
      DisplayFormat = 'dd.mm.yy h:n:s.z'
    end
    object cdsTasksFThread: TLargeintField
      FieldName = 'FThread'
      Visible = False
    end
  end
  object dsTask: TDataSource
    DataSet = cdsTasks
    Left = 550
    Top = 226
  end
  object FileOpenDialog: TOpenTextFileDialog
    Left = 580
    Top = 105
  end
end
