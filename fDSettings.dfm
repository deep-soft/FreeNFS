object DSettings: TDSettings
  Left = 685
  Top = 141
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'FreeNFS Settings'
  ClientHeight = 450
  ClientWidth = 479
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PopupMenu = IconMenu
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 8
    Top = 8
    Width = 465
    Height = 401
    ActivePage = TSBasics
    TabOrder = 0
    object TSBasics: TTabSheet
      Caption = 'Shares'
      object GBasics: TGroupBox
        Left = 8
        Top = 8
        Width = 267
        Height = 105
        Caption = 'Root Folder'
        TabOrder = 0
        object FLFolder: TLabel
          Left = 8
          Top = 24
          Width = 25
          Height = 13
          Caption = 'Path:'
        end
        object FL2Root: TLabel
          Left = 8
          Top = 64
          Width = 249
          Height = 41
          AutoSize = False
          Caption = 
            'This folder will be shared via NFS. Mounted folders will be hand' +
            'led relative to this folder. '
          WordWrap = True
        end
        object FRoot: TEdit
          Left = 8
          Top = 40
          Width = 249
          Height = 21
          TabOrder = 0
          OnChange = FBOkEnabledCheck
        end
      end
    end
    object TSClients: TTabSheet
      Caption = 'Clients'
      ImageIndex = 1
      object GClients: TGroupBox
        Left = 8
        Top = 8
        Width = 267
        Height = 105
        Caption = 'Incomming Connections'
        TabOrder = 0
        object FLHost: TLabel
          Left = 8
          Top = 24
          Width = 65
          Height = 13
          Caption = 'Allowed Host:'
        end
        object FL2Host: TLabel
          Left = 8
          Top = 64
          Width = 249
          Height = 41
          AutoSize = False
          Caption = 
            'When no host is defined, all hosts will be accepted. To define m' +
            'ultiple host a space is the separator. eg.192.168.0.1 192.168.50'
          WordWrap = True
        end
        object FHost: TEdit
          Left = 8
          Top = 40
          Width = 249
          Height = 21
          TabOrder = 0
          OnChange = FBOkEnabledCheck
        end
      end
    end
    object TSFilenames: TTabSheet
      Caption = 'Code Page'
      ImageIndex = 2
      object GCodepage: TGroupBox
        Left = 8
        Top = 8
        Width = 267
        Height = 105
        Caption = 'Encoding'
        TabOrder = 0
        object FLCodepage: TLabel
          Left = 8
          Top = 24
          Width = 52
          Height = 13
          Caption = 'Codepage:'
        end
        object Label1: TLabel
          Left = 8
          Top = 64
          Width = 249
          Height = 33
          AutoSize = False
          Caption = 
            'Filenames will be encoded by this Codepage. Use the same codepag' +
            'e while mounting.'
          WordWrap = True
        end
        object FCodepages: TComboBox
          Left = 8
          Top = 40
          Width = 249
          Height = 21
          Style = csDropDownList
          ItemHeight = 0
          TabOrder = 0
          OnChange = FBOkEnabledCheck
        end
      end
    end
    object TabSheet1: TTabSheet
      Caption = 'Memory'
      ImageIndex = 3
    end
    object TabSheet2: TTabSheet
      Caption = 'Usage'
      ImageIndex = 4
      object StaticText1: TStaticText
        Left = 16
        Top = 16
        Width = 84
        Height = 17
        Caption = 'Data Transfered:'
        TabOrder = 0
      end
      object StaticText2: TStaticText
        Left = 16
        Top = 32
        Width = 79
        Height = 17
        Caption = 'Data Received:'
        TabOrder = 1
      end
    end
  end
  object FBOk: TButton
    Left = 160
    Top = 416
    Width = 75
    Height = 25
    Caption = 'Ok'
    Default = True
    TabOrder = 1
    OnClick = FBOkClick
  end
  object FBCancel: TButton
    Left = 280
    Top = 416
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
    OnClick = FBCancelClick
  end
  object IconMenu: TPopupMenu
    Left = 72
    Top = 416
    object pmSettings: TMenuItem
      Caption = 'Settings...'
      OnClick = pmSettingsClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object pmQuit: TMenuItem
      Caption = 'Quit'
      OnClick = pmQuitClick
    end
  end
end
