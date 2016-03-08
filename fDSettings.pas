{******************************************************************************}
{*                         Network File System  3.0.2                         *}
{* Updated Coding and comments by Lawrence E. Smith, Jacksonville, MO USA and *}
{*                     Original Coding by Unknown Author                      *}
{*     Contact:  larry_e_smith at that gmail.com  660-775-2282 USA Phone      *}
{*                                                                            *}
{*                                                                            *}
{*                                                                            *}
{* This is free and unencumbered software released into the public domain.    *}
{*                                                                            *}
{* Anyone is free to copy, modify, publish, use, compile, sell, or            *}
{* distribute this software, either in source code form or as a compiled      *}
{* binary, for any purpose, commercial or non-commercial, and by any          *}
{* means.                                                                     *}
{*                                                                            *}
{* In jurisdictions that recognize copyright laws, the author or authors      *}
{* of this software dedicate any and all copyright interest in the            *}
{* software to the public domain. We make this dedication for the benefit     *}
{* of the public at large and to the detriment of our heirs and               *}
{* successors. We intend this dedication to be an overt act of                *}
{* relinquishment in perpetuity of all present and future rights to this      *}
{* software under copyright law.                                              *}
{*                                                                            *}
{* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,            *}
{* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF         *}
{* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.     *}
{* IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR          *}
{* OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,      *}
{* ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR      *}
{* OTHER DEALINGS IN THE SOFTWARE.                                            *}
{*                                                                            *}
{******************************************************************************}

Unit fDSettings;

Interface {********************************************************************}

Uses
  Windows,
  ShlObj,
  ShellAPI,
  Messages,
  Registry,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  ComCtrls,
  Menus,
  fDaemon, Mask, ExtCtrls;

Type
  TDSettings = class(TForm)
    PageControl : TPageControl;
    TSBasics    : TTabSheet;
    FBOk        : TButton;
    FBCancel    : TButton;
    FLFolder    : TLabel;
    FRoot       : TEdit;
    GBasics     : TGroupBox;
    IconMenu    : TPopupMenu;
    pmQuit      : TMenuItem;
    N1          : TMenuItem;
    pmSettings  : TMenuItem;
    TSClients   : TTabSheet;
    GClients    : TGroupBox;
    FLHost      : TLabel;
    FHost       : TEdit;
    FL2Host     : TLabel;
    FL2Root     : TLabel;
    TSFilenames : TTabSheet;
    GCodePage   : TGroupBox;
    FLCodePage  : TLabel;
    Label1      : TLabel;
    FCodePages  : TComboBox;
    TabSheet1   : TTabSheet;
    TabSheet2   : TTabSheet;
    StaticText1 : TStaticText;
    StaticText2 : TStaticText;

    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FBOkEnabledCheck(Sender: TObject);
    procedure FBOkClick(Sender: TObject);
    procedure FBCancelClick(Sender: TObject);
    procedure pmQuitClick(Sender: TObject);
    procedure pmSettingsClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
    private
       CodePage: Integer;
       Host    : String;
       Root    : String;
       procedure CMNotifyIcon(var Message: TMessage); message WM_USER;
       procedure StartDaemon(const Root: AnsiString; const ACodePage: Cardinal);
    end;

var
  DSettings: TDSettings;

implementation {***************************************************************}

uses
  SHFolder,
  Math;

{$R *.dfm}

const
  RegistryKey = '\SOFTWARE\FreeNFS';
  FilePath = '\FreeNFS';

type
  _cpinfoex = record
    MaxCharSize        : UINT; { max length (bytes) of a char }
    DefaultChar        : array[0..MAX_DEFAULTCHAR - 1] of Byte; { default character }
    LeadByte           : array[0..MAX_LEADBYTES - 1] of Byte; { lead byte ranges }
    UnicodeDefaultChar : WCHAR;
    CodePage           : UINT;
    CodePageName       : array[0..MAX_PATH] of char;
  end;
  TCPInfoEx = _cpinfoex;
  {$EXTERNALSYM CPINFOEX}
  CPINFOEX = _cpinfoex;
  {$EXTERNALSYM GetCPInfoEx}

function GetCPInfoEx(CodePage: UINT; dwFlags : DWORD; var lpCPInfoEx: TCPInfoEx): BOOL; stdcall; external 'kernel32' name 'GetCPInfoExA';

var
  CodePages: array of record Caption: String[64]; CodePage: Integer; end;

function EnumCodePagesProc(CodePageString: PAnsiChar): Cardinal; stdcall;
var
  CodePage: Integer;
  CPInfoEx: TCPInfoEx;
begin
  if (TryStrToInt(StrPas(CodePageString), CodePage) and GetCPInfoEx(CodePage, 0, CPInfoEx)) then
  begin
    SetLength(CodePages, Length(CodePages) + 1);
    CodePages[Length(CodePages) - 1].Caption := StrPas(@CPInfoEx.CodePageName);
    CodePages[Length(CodePages) - 1].CodePage := CodePage;
  end;

  Result := 1;
end;

function CodePageSortCompare(List: TStringList; Index1, Index2: Integer): Integer;
var
  CodePage1, CodePage2: Integer;
  Error: Integer;
begin
  Val(List[Index1], CodePage1, Error);
  Val(List[Index2], CodePage2, Error);
  Result := Sign(CodePage1 - CodePage2);
end;

{ TDControlPanel **************************************************************}

procedure TDSettings.FormCreate(Sender: TObject);
var
  NotifyIconData: TNotifyIconData;
  Foldername: array [0..MAX_PATH] of PChar;
  Reg: TRegistry;
begin
  ZeroMemory(@NotifyIconData, SizeOf(NotifyIconData));
  NotifyIconData.cbSize := SizeOf(NotifyIconData);
  NotifyIconData.Wnd := Handle;
  NotifyIconData.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
  NotifyIconData.uCallbackMessage := WM_USER;
  NotifyIconData.hIcon := Application.Icon.Handle;
  StrLCopy(@NotifyIconData.szTip, PChar(Application.Title), Length(NotifyIconData.szTip) - 1);
  Shell_NotifyIcon(NIM_ADD, @NotifyIconData);


  if (SHGetFolderPath(0, CSIDL_PERSONAL, 0, 0, @Foldername) = S_OK) then
    Root := StrPas(@Foldername) + FilePath
  else
    Root := GetCurrentDir() + FilePath;
  Host := '';
  CodePage := GetACP();

  Reg := TRegistry.Create(KEY_READ);
  if (Reg.OpenKey(RegistryKey, False)) then
  begin
    if (Reg.ValueExists('Root') and (Reg.ReadString('Root') <> '')) then
      Root := Reg.ReadString('Root');
    if (Reg.ValueExists('Host')) then
      Host := Reg.ReadString('Host');
    if (Reg.ValueExists('CodePage')) then
      CodePage := Reg.ReadInteger('CodePage');
    Reg.CloseKey();
  end;
  Reg.Free();


  if (ForceDirectories(Root)) then
    StartDaemon(Root, CodePage);
end;

procedure TDSettings.FormShow(Sender: TObject);
var
  I: Integer;
  StringList: TStringList;
begin
  pmSettings.Visible := False;

  SetLength(CodePages, 0);
  EnumSystemCodePages(@EnumCodePagesProc, CP_SUPPORTED);
  FCodePages.Items.Clear();

  StringList := TStringList.Create();
  for I := 0 to Length(CodePages) - 1 do
    StringList.Add(CodePages[I].Caption);
  StringList.CustomSort(@CodePageSortCompare);
  for I := 0 to StringList.Count - 1 do
    FCodePages.Items.Add(StringList[I]);
  StringList.Free();


  PageControl.ActivePage := TSBasics;
  FRoot.Text := Root;
  FHost.Text := Host;
  FCodePages.ItemIndex := -1;
  for I := 0 to Length(CodePages) - 1 do
    if (CodePages[I].CodePage = CodePage) then
      FCodePages.ItemIndex := FCodePages.Items.IndexOf(CodePages[I].Caption);

  FBOk.Enabled := False;

  ActiveControl := FRoot;
end;

procedure TDSettings.FormHide(Sender: TObject);
begin
  SetLength(CodePages, 0);

  pmSettings.Visible := True;
end;

procedure TDSettings.FormDestroy(Sender: TObject);
var
  NotifyIconData: TNotifyIconData;
begin
  ZeroMemory(@NotifyIconData, SizeOf(NotifyIconData));
  NotifyIconData.cbSize := SizeOf(NotifyIconData);
  NotifyIconData.Wnd := Handle;
  Shell_NotifyIcon(NIM_DELETE, @NotifyIconData);

  StopDaemon();
end;

procedure TDSettings.FBOkEnabledCheck(Sender: TObject);
begin
  FBOk.Enabled := DirectoryExists(FRoot.Text);
end;

procedure TDSettings.FBOkClick(Sender: TObject);
var
  Reg: TRegistry;
  I: Integer;
begin
  StopDaemon();

  Reg := TRegistry.Create();
  if (Reg.OpenKey(RegistryKey, True)) then
  begin
    if ((FRoot.Text <> Root) and (DirectoryExists(FRoot.Text))) then
    begin
      Root := FRoot.Text;
      Reg.WriteString('Root', Root);
    end;
    if (FHost.Text <> Host) then
    begin
      Host := FHost.Text;
      if (FHost.Text <> '') then
        Reg.WriteString('Host', Host)
      else if (Reg.ValueExists('Host')) then
        Reg.DeleteValue('Host');
    end;

    for I := 0 to Length(CodePages) - 1 do
      if ((CodePages[I].Caption = FCodePages.Text) and (CodePages[I].CodePage <> CodePage)) then
      begin
        CodePage := CodePages[I].CodePage;
        if (CodePage <> 0) then
          Reg.WriteInteger('CodePage', CodePage)
        else if (Reg.ValueExists('CodePage')) then
          Reg.DeleteValue('CodePage');
      end;
    Reg.CloseKey();
  end;

  Reg.Free();

  StartDaemon(Root, CodePage);

  FBOk.Enabled := False;

  Hide();
end;

procedure TDSettings.FBCancelClick(Sender: TObject);
begin
  Hide();
end;

procedure TDSettings.CMNotifyIcon(var Message: TMessage);
var
  CursorPos: TPoint;
begin
  case (Message.LParamLo) of
    WM_RBUTTONUP:
      if (GetCursorPos(CursorPos)) then
        IconMenu.Popup(CursorPos.X, CursorPos.Y);
  end;
end;

procedure TDSettings.pmSettingsClick(Sender: TObject);
begin
  Show();
end;

procedure TDSettings.pmQuitClick(Sender: TObject);
begin
  Close();
end;

procedure TDSettings.StartDaemon(const Root: AnsiString; const ACodePage: Cardinal);
var
  S: String;
begin
  if (not Assigned(Daemon)) then
  begin
    Daemon := TDaemon.Create(Root, ACodePage);
    S := Host;
    while (S <> '') do
      if (Pos(' ', S) = 0) then
      begin
        Daemon.AddHost(S);
        S := '';
      end
      else
      begin
        Daemon.AddHost(Copy(S, 1, Pos(' ', S) - 1));
        Delete(S, 1, Pos(' ', S));
      end;
    if (Daemon.ErrorMsg <> '') then
    begin
      raise Exception.Create(Daemon.ErrorMsg);
      FreeAndNil(Daemon);
    end
    else
      Daemon.Resume();
  end;
end;

end.
