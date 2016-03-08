{******************************************************************************}
{*                         Network File System  3.02                          *}
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

Unit fDaemon;

Interface

{********************************************************************}

{
  Related informations:
    RFC 1833: Binding Protocols for ONC RPC Version 2
    RFC 1831: Remote Procedure Call Protocol Specification Version 2
    RFC 1813: NFS Version 3 Protocol Specification
    RFC 1014: External Data Representation Standard
}

Uses
  Windows,
  WinSock,
  Classes,
  SysUtils,
  RPCConsts;

Type
  TFilename  = WideString;
  TDirHandle = class;
  TBuffer    = record
    Mem:    PAnsiChar;
    Offset: Cardinal;
    Size:   Cardinal;
    TotalSize: Cardinal;
    SystemMemory: Boolean;
  end;

  PAllowedAddr = ^TAllowedAddr;
  TAllowedAddr = record
    S_addr: u_long;
  end;

  TAllowedAddrs = class(TList)
  private
    function GetItem(Index: Integer): PAllowedAddr;
  public
    property Items[Index: Integer]: PAllowedAddr read GetItem;
    function Add(Item: PAllowedAddr): Integer; reintroduce;
    procedure Clear(); override;
    procedure Delete(Index: Integer); reintroduce; virtual;
  end;

  PMount = ^TMount;
  TMount = record
    name: PWideChar;
    Count: Integer;
    S_addr: u_long;
  end;

  TMounts = class(TList)
  private
    function GetItem(Index: Integer): PMount;
  public
    property Items[Index: Integer]: PMount read GetItem;
    function Add(Item: PMount): Integer; reintroduce;
    procedure Clear(); override;
    procedure Delete(Index: Integer); reintroduce; virtual;
    function IndexOf(const name: PWideChar; const S_addr: u_long): Integer; overload; virtual;
  end;

  PFileHandleData = ^TFileHandleData;
  TFileHandleData = record
    name: PWideChar;
    Path: PWideChar;
  end;

  TObjectHandle = class
  private
    Data: PFileHandleData;
    Fdir: TDirHandle;
  protected
    function Getname(): PWideChar; virtual;
    function GetPath(): TFilename; virtual;
  public
    property dir: TDirHandle read Fdir;
    property name: PWideChar read Getname;
    property Path: TFilename read GetPath;
    constructor Create(const Adir: TDirHandle; const Aname: PWideChar; const APath: TFilename); reintroduce; virtual;
    destructor Destroy(); override;
  end;

  TFileHandle = class(TObjectHandle)
  public
    WriteHandle: THandle;
    WriteTickCount: DWord;
    constructor Create(const Adir: TDirHandle; const Aname: PWideChar; const APath: TFilename); override;
  end;

  TDirHandle = class(TObjectHandle)
  private
    FBytesPerSector: DWord;
    FFileOffsetMask: Int64;
  protected
    function GetPath(): TFilename; override;
  public
    property BytesPerSector: DWord read FBytesPerSector;
    property FileOffsetMask: Int64 read FFileOffsetMask;
    constructor Create(const Adir: TDirHandle; const Aname: PWideChar; const APath: TFilename); override;
  end;

  TObjectHandles = class(TList)
  private
    FRoot: TFilename;
    function GetItem(Index: Integer): TObjectHandle;
  protected
    property Root: TFilename read FRoot;
    procedure CloseWriteHandle(const fhandle: TFileHandle); virtual;
    function GetAttr3(const ohandle: TObjectHandle; var attr3: fattr3): Boolean; overload; virtual;
    function GetAttr3(const ohandle: TObjectHandle; const WinHandle: THandle; var attr3: fattr3): Boolean; overload; virtual;
    function GetObjectHandle(const dir: TDirHandle; const name: PWideChar): TObjectHandle; virtual;
    function IndexOf(const dir: TDirHandle; const name: PWideChar): Integer; overload; virtual;
  public
    property Items[Index: Integer]: TObjectHandle read GetItem;
    function Add(Item: TObjectHandle): Integer; reintroduce;
    procedure Clear(); override;
    constructor Create(const ARoot: TFilename); virtual;
    procedure Delete(Index: Integer); reintroduce; virtual;
  end;

  TReadDirFiles = class(TList)
  private
    function GetItem(Index: Integer): PWIN32FindDataW;
  public
    property Items[Index: Integer]: PWIN32FindDataW read GetItem;
    function Add(Item: PWIN32FindDataW): Integer; reintroduce;
    procedure Clear(); override;
    procedure Delete(const Index: Integer); reintroduce;
  end;

  PReadDirHandle = ^TReadDirHandle;
  TReadDirHandle = record
    dir: TDirHandle;
    Files: TReadDirFiles;
  end;

  TReadDirHandles = class(TList)
  private
    FObjectHandles: TObjectHandles;
    function GetItem(Index: Integer): PReadDirHandle;
  protected
    CriticalSection: TRTLCriticalSection;
    property ObjectHandles: TObjectHandles read FObjectHandles;
    function GetReadDirHandle(const dir: TDirHandle): PReadDirHandle;
  public
    property Items[Index: Integer]: PReadDirHandle read GetItem;
    function Add(Item: PReadDirHandle): Integer; reintroduce;
    procedure Clear(); override;
    constructor Create(const AObjectHandles: TObjectHandles); virtual;
    procedure Delete(Index: Integer); reintroduce;
    destructor Destroy(); override;
    function IndexOfFileHandle(const dir: TDirHandle): Integer; overload; virtual;
  end;

  TDaemonCheckTerminated = function(): Boolean of object;

  TDaemon = class(TThread)
  private
    Mounts: TMounts;
    AllowedAddrs: TAllowedAddrs;
    CheckTerminated: TDaemonCheckTerminated;
    CodePage: Integer;
    DecodingName: array [0..MNTPATHLEN] of WideChar;
    EncodingNameA: array [0..MNTPATHLEN] of AnsiChar;
    FErrorMsg: String;
    FileBuffer: TBuffer;
    MountTCPSocket: TSocket;
    MountUDPSocket: TSocket;
    NFSTCPSocket: TSocket;
    NFSUDPSocket: TSocket;
    ObjectHandles: TObjectHandles;
    PortMapperTCPSocket: TSocket;
    PortMapperUDPSocket: TSocket;
    Protocol: u_long;
    ReadDirHandles: TReadDirHandles;
    ReadBuffer: TBuffer;
    RemoteAddr: sockaddr_in;
    Socket: TSocket;
    WriteBuffer: TBuffer;
    function AddrAccepted(const S_addr: u_long): Boolean;
    function DecodeName(const nameA: PAnsiChar): PWideChar;
    function EncodeName(const name: PWideChar): PAnsiChar;
    function Flush(): Boolean; virtual;
    function GetNFSStatus(const SysError: DWord): NFS_Stat3;
    function ReadNewAttr(out NewAttr: sattr3): Boolean;
    function WriteWCC(const OldAttr, NewAttr: fattr3): Boolean;
  protected
    function AddrAllowed(const S_addr: u_long): Boolean; virtual;
    function Mount3_Null(): Boolean; virtual;
    function Mount3_Mnt(): Boolean; virtual;
    function Mount3_UMnt(): Boolean; virtual;
    function Mount3_UMntAll(): Boolean; virtual;
    function NFS3_Access(): Boolean; virtual;
    function NFS3_Commit(): Boolean; virtual;
    function NFS3_Create(): Boolean; virtual;
    function NFS3_FSInfo(): Boolean; virtual;
    function NFS3_FSStat(): Boolean; virtual;
    function NFS3_GetAttr(): Boolean; virtual;
    function NFS3_Lookup(): Boolean; virtual;
    function NFS3_MkDir(): Boolean; virtual;
    function NFS3_Null(): Boolean; virtual;
    function NFS3_PathConf(): Boolean; virtual;
    function NFS3_Read(): Boolean; virtual;
    function NFS3_ReadDir(): Boolean; virtual;
    function NFS3_ReadDirPlus(): Boolean; virtual;
    function NFS3_Remove(): Boolean; virtual;
    function NFS3_Rename(): Boolean; virtual;
    function NFS3_RmDir(): Boolean; virtual;
    function NFS3_SetAttr(): Boolean; virtual;
    function NFS3_Write(): Boolean; virtual;
    function Read(var Value: Boolean): Boolean; overload; virtual;
    function Read(var Value: ULONG): Boolean; overload; virtual;
    function Read(var Value: LONGLONG): Boolean; overload; virtual;
    function Read(var Data; const BytesToRead: ULONG): Boolean; overload; virtual;
    function PMA2_Dump(): Boolean; virtual;
    function PMA2_GetPort(): Boolean; virtual;
    function PMA2_GetTime(): Boolean; virtual;
    function PMA2_Null(): Boolean; virtual;
    function Write(var Data; const BytesToWrite: ULONG): Boolean; overload; virtual;
    function Write(const Value: Boolean): Boolean; overload; virtual;
    function Write(Value: ULONG): Boolean; overload; virtual;
    function Write(Value: LONGLONG): Boolean; overload; virtual;
  public
    property ErrorMsg: String read FErrorMsg;
    procedure AddHost(const Host: AnsiString); virtual;
    constructor Create(const ARoot: TFilename; const ACodePage: Integer; const ACheckTerminated: TDaemonCheckTerminated = nil); virtual;
    destructor Destroy(); override;
    procedure Execute(); override;
  end;

const
  MountDaemonPort = 635;
  NFSDeamounPort = 2049;

procedure StartDaemon(const Root: TFilename; const ACodePage: Integer = CP_ACP);
procedure StopDaemon();

var
  Daemon: TDaemon;

implementation {***************************************************************}

uses
  Math,
  StrUtils;

type
  ESocketError = class(Exception);

const
  MaxPacketSize = 1048576;
  DefaultPacketSize = 32768;
  MinPacketSize = 1024;

var
  WSAData: WinSock.WSADATA;

// Bug in WinSock.pas: u_long is defined as Longint, instead of Longword
function ntohl(netlong: ULONG): ULONG; stdcall; external 'wsock32.dll' name 'ntohl';
function htonl(hostlong: ULONG): ULONG; stdcall; external 'wsock32.dll' name 'htonl';

function ntohll(netlonglong: LONGLONG): LONGLONG;
begin
  // Needs to be in two lines!!!
  Result := ntohl(netlonglong and $FFFFFFFF);
  Result := Result shl 32 + ntohl((netlonglong shr 32));
end;

function htonll(hostlonglong: LONGLONG): LONGLONG;
begin
  // Needs to be in two lines!!!
  Result := htonl(hostlonglong and $FFFFFFFF);
  Result := Result shl 32 + htonl((hostlonglong shr 32));
end;

function FILETIMETonfstime3(const Time: FILETIME): nfstime3;
var
  I64: Int64;
  TimeZoneInformation: TIME_ZONE_INFORMATION;
begin
  I64 := (Int64(Time) - 116444736000000000);
  case (GetTimeZoneInformation(TimeZoneInformation)) of
    TIME_ZONE_ID_STANDARD:
      Inc(I64, TimeZoneInformation.Bias * 600000);
    TIME_ZONE_ID_DAYLIGHT:
      Inc(I64, (TimeZoneInformation.Bias + TimeZoneInformation.DaylightBias) * 600000);
  end;
  Result.seconds := htonl(I64 div 10000000);
  Result.nseconds := htonl((I64 mod 10000000) * 100);
end;

function ReallocBuffer(var Buffer: TBuffer; const NewTotalSize: Cardinal; const ChunkSize: Cardinal = 1): Boolean;
var
  AllocSize: Cardinal;
  NewMem: Pointer;
begin
  Result := NewTotalSize <= MaxPacketSize;

  if ((NewTotalSize = 0) or (NewTotalSize > Buffer.TotalSize)) then
  begin
    AllocSize := NewTotalSize;
    if (AllocSize mod ChunkSize > 0) then
      Inc(AllocSize, ChunkSize - AllocSize mod ChunkSize);

    if (not Buffer.SystemMemory) then
      try
        ReallocMem(Buffer.Mem, AllocSize);
      except
        on E: EOutOfMemory do
          Buffer.Mem := nil;
      end
    else
    begin
      if (AllocSize = 0) then
        NewMem := nil
      else
      begin
        NewMem := VirtualAlloc(nil, AllocSize, MEM_COMMIT, PAGE_READWRITE or PAGE_NOCACHE);
        if (Assigned(Buffer.Mem) and Assigned(NewMem)) then
          MoveMemory(NewMem, Buffer.Mem, Min(AllocSize, Buffer.Size));
      end;
      if (Assigned(Buffer.Mem)) then
        VirtualFree(Buffer.Mem, Buffer.TotalSize, MEM_RELEASE);
      Buffer.Mem := NewMem;
    end;
    Result := (AllocSize = 0) or Assigned(Buffer.Mem);
    if (not Result) then
      Buffer.TotalSize := 0
    else
      Buffer.TotalSize := AllocSize;
  end;
end;

function WideReplaceStr(const AText, AFromText, AToText: WideString): WideString;
var
  Index: Integer;
begin
  Result := AText;
  while (Pos(AFromText, Result) > 0) do
  begin
    Index := Pos(AFromText, Result);
    Delete(Result, Index, Length(AFromText));
    Insert(AToText, Result, Index);
  end;
end;

procedure StartDaemon(const Root: TFilename; const ACodePage: Integer = CP_ACP);
begin
  if (not Assigned(Daemon)) then
  begin
    Daemon := TDaemon.Create(Root, ACodePage);
    Daemon.Resume();
  end;
end;

procedure StopDaemon();
begin
  if (Assigned(Daemon)) then
  begin
    Daemon.Terminate();
    Daemon.WaitFor();
    Daemon.Free();
    Daemon := nil;
  end;
end;

{ TAllowedAddrs ***************************************************************}

function TAllowedAddrs.Add(Item: PAllowedAddr): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TAllowedAddrs.Clear();
begin
  while (Count > 0) do
    Delete(0);

  inherited Clear();
end;

procedure TAllowedAddrs.Delete(Index: Integer);
begin
  FreeMem(Items[Index]);
  inherited;
end;

function TAllowedAddrs.GetItem(Index: Integer): PAllowedAddr;
begin
  Result := inherited Items[Index];
end;

{ TMounts **************************************************************}

function TMounts.Add(Item: PMount): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TMounts.Clear();
begin
  while (Count > 0) do
    Delete(0);

  inherited Clear();
end;

procedure TMounts.Delete(Index: Integer);
begin
  FreeMem(Items[Index]);
  inherited;
end;

function TMounts.GetItem(Index: Integer): PMount;
begin
  Result := inherited Items[Index];
end;

function TMounts.IndexOf(const name: PWideChar; const S_addr: u_long): Integer;
var
  Index: Integer;
begin
  Result := -1;
  Index := 0;
  while ((Result < 0) and (Index < Count)) do
  begin
    if ((lstrcmpiW(Items[Index]^.name, name) = 0) and (Items[Index]^.S_addr = S_addr)) then
      Result := Index;
    Inc(Index);
  end;
end;

{ TObjectHandle ***************************************************************}

constructor TObjectHandle.Create(const Adir: TDirHandle; const Aname: PWideChar; const APath: TFilename);
var
  Size: Integer;
begin
  Size := SizeOf(Data^) + (lstrlenW(Aname) + 1) * SizeOf(Data^.name[0]) + (Length(APath) + 1) * SizeOf(Data^.name[0]);
  GetMem(Data, Size);
  ZeroMemory(Data, Size);
  Data^.name := @PAnsiChar(Data)[SizeOf(Data^)];
  lstrcpyW(Data^.name, Aname);
  Data^.Path := @PAnsiChar(Data)[SizeOf(Data^) + (lstrlenW(Data^.name) + 1) * SizeOf(Data^.name[0])];
  lstrcpyW(Data^.Path, PWideChar(APath));

  Fdir := Adir;
end;

destructor TObjectHandle.Destroy();
begin
  FreeMem(Data);

  inherited;
end;

function TObjectHandle.Getname(): PWideChar;
begin
  Result := Data^.name;
end;

function TObjectHandle.GetPath(): TFilename;
begin
  if (not Assigned(dir)) then
    Result := Data.Path
  else
    Result := dir.Path + Data.Path;
  if (Self is TDirHandle) then
    Result := Result + '\';
end;

{ TFileHandle *****************************************************************}

constructor TFileHandle.Create(const Adir: TDirHandle; const Aname: PWideChar; const APath: TFilename);
begin
  inherited;

  WriteHandle := INVALID_HANDLE_VALUE;
end;

{ TDirHandle ******************************************************************}

constructor TDirHandle.Create(const Adir: TDirHandle; const Aname: PWideChar; const APath: TFilename);
var
  SectorsPerCluster, NumberOfFreeClusters, TotalNumberOfClusters: DWord;
begin
  inherited;

  if (not GetDiskFreeSpaceW(PWideChar(Path), SectorsPerCluster, FBytesPerSector, NumberOfFreeClusters, TotalNumberOfClusters)) then
    fail;

  FFileOffsetMask := not (BytesPerSector - 1);
end;

function TDirHandle.GetPath(): TFilename;
begin
  Result := inherited GetPath() + '\';
end;

{ TObjectHandles ****************************************************************}

function TObjectHandles.Add(Item: TObjectHandle): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TObjectHandles.Clear();
begin
  while (Count > 0) do
    Delete(0);

  inherited;
end;

procedure TObjectHandles.CloseWriteHandle(const fhandle: TFileHandle);
begin
  if (fhandle.WriteHandle <> INVALID_HANDLE_VALUE) then
  begin
    CloseHandle(fhandle.WriteHandle);
    fhandle.WriteHandle := INVALID_HANDLE_VALUE;
    fhandle.WriteTickCount := 0;
  end;
end;

constructor TObjectHandles.Create(const ARoot: TFilename);
begin
  inherited Create();

  FRoot := WideReplaceStr(ARoot, '/', '\');
  if (RightStr(FRoot, 1) = '\') then
    System.Delete(FRoot, Length(FRoot), 1);

  if (not DirectoryExists(FRoot)) then
    raise Exception.CreateFmt('Can''t open folder "%s"', [FRoot]);
end;

procedure TObjectHandles.Delete(Index: Integer);
begin
  if ((Items[Index] is TFileHandle) and (TFileHandle(Items[Index]).WriteHandle <> INVALID_HANDLE_VALUE)) then
    CloseWriteHandle(TFileHandle(Items[Index]));
  Items[Index].Free();

  inherited Delete(Index);
end;

function TObjectHandles.GetAttr3(const ohandle: TObjectHandle; var Attr3: fattr3): Boolean;
var
  WinHandle: THandle;
  Flags: DWord;
begin
  if (ohandle is TDirHandle) then
    Flags := FILE_FLAG_BACKUP_SEMANTICS
  else
    Flags := 0;

  WinHandle := CreateFileW(PWideChar(ohandle.Path),
                           GENERIC_READ,
                           FILE_SHARE_READ or FILE_SHARE_WRITE,
                           nil, OPEN_EXISTING, Flags, 0);

  if (WinHandle = INVALID_HANDLE_VALUE) then
    Result := False
  else
  begin
    Result := GetAttr3(ohandle, WinHandle, Attr3);
    CloseHandle(WinHandle);
  end;
end;

function TObjectHandles.GetAttr3(const ohandle: TObjectHandle; const WinHandle: THandle; var Attr3: fattr3): Boolean;
var
  FileInformations: BY_HANDLE_FILE_INFORMATION;
  LI: LARGE_INTEGER;
  FindHandle: THandle;
  FindFileData: TWIN32FindDataW;
  AccessTime, WriteTime: FILETIME;
begin
  Result := GetFileInformationByHandle(WinHandle, FileInformations);
  if (Result) then
  begin
    ZeroMemory(@Attr3, SizeOf(Attr3));

    if (FileInformations.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) then
      Attr3.ftype := htonl(ULONG(NF3DIR))
    else
      Attr3.ftype := htonl(ULONG(NF3REG));
    if (FileInformations.dwFileAttributes and FILE_ATTRIBUTE_READONLY <> 0) then
      Attr3.mode := 4
    else
      Attr3.mode := 6;
    Attr3.mode := htonl(Attr3.mode shl 6 + Attr3.mode shl 3 + Attr3.mode);
    Attr3.nlink := htonl(1);
    LI.LowPart := FileInformations.nFileSizeLow; LI.HighPart := FileInformations.nFileSizeHigh;
    Attr3.size := htonll(LI.QuadPart);
    Attr3.used := Attr3.size;
    Attr3.fileid := IndexOf(ohandle);
    if (FileInformations.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) then
    begin
      FindHandle := FindFirstFileW(PWideChar(TFilename(ohandle.name) + '*.*'), FindFileData);
      if (FindHandle = INVALID_HANDLE_VALUE) then
      begin
        Attr3.atime := FILETIMETonfstime3(FileInformations.ftLastAccessTime);
        Attr3.mtime := FILETIMETonfstime3(FileInformations.ftLastWriteTime);
      end
      else
      begin
        Int64(WriteTime) := 0;
        Int64(AccessTime) := 0;
        repeat
          Int64(AccessTime) := Max(Int64(AccessTime), Int64(FindFileData.ftLastWriteTime));
          Int64(WriteTime) := Max(Int64(WriteTime), Int64(FindFileData.ftLastWriteTime));
        until (not FindNextFileW(FindHandle, FindFileData));
        Attr3.atime := FILETIMETonfstime3(AccessTime);
        Attr3.mtime := FILETIMETonfstime3(WriteTime);
      end;
    end
    else
      Attr3.mtime := FILETIMETonfstime3(FileInformations.ftLastWriteTime);
    Attr3.ctime := FILETIMETonfstime3(FileInformations.ftCreationTime);
  end;
end;

function TObjectHandles.GetObjectHandle(const dir: TDirHandle; const name: PWideChar): TObjectHandle;
var
  Index: Integer;
  Path: TFilename;
begin
  if (Assigned(dir)) then
    Path := WideReplaceStr(name, '/', '\')
  else if (Root <> '') then
    Path := Root + WideReplaceStr(name, '/', '\')
  else
    Path := '';

  if (Path = '') then
    Result := nil
  else
  begin
    Index := IndexOf(dir, name);
    if (Index >= 0) then
      Result := Items[Index]
    else
    begin
      if (Path = '') then
        Result := nil
      else if (not Assigned(dir) and DirectoryExists(Path)) then
        Result := TDirHandle.Create(dir, name, Path)
      else if (Assigned(dir) and DirectoryExists(dir.Path + Path)) then
        Result := TDirHandle.Create(dir, name, Path)
      else if (not Assigned(dir) and FileExists(Path)) then
        Result := TFileHandle.Create(dir, name, Path)
      else if (Assigned(dir) and FileExists(dir.Path + Path)) then
        Result := TFileHandle.Create(dir, name, Path)
      else
        Result := nil;

      if (Assigned(Result)) then
        Add(Result);
    end;
  end;
end;

function TObjectHandles.GetItem(Index: Integer): TObjectHandle;
begin
  Result := TObjectHandle(inherited Items[Index]);
end;

function TObjectHandles.IndexOf(const dir: TDirHandle; const name: PWideChar): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if ((Items[I].dir = dir) and (lstrcmpiW(Items[I].name, name) = 0)) then
      Result := I;
end;

{ TReadDirFiles ***************************************************************}

function TReadDirFiles.Add(Item: PWIN32FindDataW): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TReadDirFiles.Clear();
begin
  while (Count > 0) do
    Delete(0);

  inherited Clear();
end;

procedure TReadDirFiles.Delete(const Index: Integer);
begin
  FreeMem(Items[Index]);

  inherited Delete(Index);
end;

function TReadDirFiles.GetItem(Index: Integer): PWIN32FindDataW;
begin
  Result := PWIN32FindDataW(inherited Items[Index]);
end;

{ TReadDirHandles *************************************************************}

function TReadDirHandles.Add(Item: PReadDirHandle): Integer;
begin
  Result := inherited Add(Item);
end;

procedure TReadDirHandles.Clear();
begin
  while (Count > 0) do
    Delete(0);

  inherited;
end;

constructor TReadDirHandles.Create(const AObjectHandles: TObjectHandles);
begin
  inherited Create();

  InitializeCriticalSection(CriticalSection);
  FObjectHandles := AObjectHandles;
end;

procedure TReadDirHandles.Delete(Index: Integer);
begin
  Items[Index]^.Files.Free();
  FreeMem(Items[Index]);

  inherited Delete(Index);
end;

destructor TReadDirHandles.Destroy();
begin
  DeleteCriticalSection(CriticalSection);

  inherited;
end;

function TReadDirHandles.GetReadDirHandle(const dir: TDirHandle): PReadDirHandle;
var
  I: Integer;
  Handle: THandle;
  FindFileData: TWIN32FindDataW;
  FileData: PWIN32FindDataW;
begin
  Handle := FindFirstFileW(PWideChar(dir.Path + '*.*'), FindFileData);
  if (Handle = INVALID_HANDLE_VALUE) then
    Result := nil
  else
  begin
    EnterCriticalSection(CriticalSection);

    Result := nil;
    for I := 0 to Count - 1 do
      if (Items[I]^.dir = dir) then
        Result := Items[I];

    if (Assigned(Result)) then
      Result^.Files.Free()
    else
    begin
      GetMem(Result, SizeOf(Result^));
      Add(Result);
      Result^.dir := dir;
    end;

    Result^.Files := TReadDirFiles.Create();

    repeat
      GetMem(FileData, SizeOf(FileData^));
      MoveMemory(FileData, @FindFileData, SizeOf(FileData^));
      Result^.Files.Add(FileData);
    until (not FindNextFileW(Handle, FindFileData));

    Windows.FindClose(Handle);

    LeaveCriticalSection(CriticalSection);
  end;
end;

function TReadDirHandles.GetItem(Index: Integer): PReadDirHandle;
begin
  Result := PReadDirHandle(inherited Items[Index]);
end;

function TReadDirHandles.IndexOfFileHandle(const dir: TDirHandle): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to Count - 1 do
    if (Items[I]^.dir = dir) then
      Result := I;
end;

{ TDaemon *********************************************************************}

procedure TDaemon.AddHost(const Host: AnsiString);
var
  HostEnt: PHostEnt;
  AllowedAddr: PAllowedAddr;
begin
  if (Host <> '') then
  begin
    GetMem(AllowedAddr, SizeOf(AllowedAddr^));
    ZeroMemory(AllowedAddr, SizeOf(AllowedAddr^));

    AllowedAddr^.S_addr := inet_addr(PChar(Host));
    if (AllowedAddr^.S_addr = INADDR_NONE) then
    begin
      HostEnt := gethostbyname(PChar(Host));
      if (not Assigned(HostEnt)) then
        AllowedAddr^.S_addr := INADDR_NONE
      else
        MoveMemory(@AllowedAddr.S_addr, HostEnt^.h_addr^, SizeOf(AllowedAddr.S_addr));
    end;

    AllowedAddrs.Add(AllowedAddr);
  end;
end;

function TDaemon.AddrAccepted(const S_addr: u_long): Boolean;
var
  I: Integer;
begin
  Result := False;
  I := 0;
  if (S_addr <> INADDR_NONE) then
    while (not Result and (I < Mounts.Count)) do
    begin
      Result := (Mounts.Items[I]^.S_addr = S_addr);
      Inc(I);
    end;
end;

function TDaemon.AddrAllowed(const S_addr: u_long): Boolean;
var
  I: Integer;
begin
  if (S_addr = INADDR_NONE) then
    Result := False
  else if (AllowedAddrs.Count = 0) then
    Result := True
  else
  begin
    Result := False;
    I := 0;
    while (not Result and (I < AllowedAddrs.Count)) do
    begin
      Result := (AllowedAddrs.Items[I]^.S_addr = S_addr);
      Inc(I);
    end;
  end;
end;

constructor TDaemon.Create(const ARoot: TFilename; const ACodePage: Integer; const ACheckTerminated: TDaemonCheckTerminated = nil);
var
  SockAddr: sockaddr_in;
  ReadFDS: TFDSet;
  Time: timeval;
  XID: ULONG;
  DW: ULONG;
  EntryFollow: Boolean;
  Verifier: uint64;
  ProgramId: ULONG;
  ProgramVer: ULONG;
  Protocol: ULONG;
  Port: ULONG;
  BindPortMapperTCP, BindPortMapperUDP: Boolean;
  BindMountTCP, BindMountUDP: Boolean;
  BindNFSTCP, BindNFSUDP: Boolean;
begin
  inherited Create(True);

  CodePage := ACodePage;
  CheckTerminated := ACheckTerminated;

  FErrorMsg := '';
  AllowedAddrs := TAllowedAddrs.Create();
  Mounts := TMounts.Create();
  ObjectHandles := TObjectHandles.Create(ARoot);
  ReadDirHandles := TReadDirHandles.Create(ObjectHandles);


  ZeroMemory(@SockAddr, SizeOf(SockAddr));
  SockAddr.sin_family := AF_INET;
  SockAddr.sin_addr.s_addr := htonl(INADDR_ANY);
  SockAddr.sin_port := htons(RPCB_PORT);

  PortMapperTCPSocket := WinSock.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (PortMapperTCPSocket = INVALID_SOCKET) then
    FErrorMsg := 'Can''t create TPC socket'
  else if (bind(PortMapperTCPSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR) then
  begin
    closesocket(PortMapperTCPSocket);
    PortMapperTCPSocket := INVALID_SOCKET;
  end
  else if (listen(PortMapperTCPSocket, 0) = SOCKET_ERROR) then
  begin
     shutdown(PortMapperTCPSocket, SD_BOTH);
    closesocket(PortMapperTCPSocket);
    PortMapperTCPSocket := INVALID_SOCKET;
  end;

  BindPortMapperTCP := (FErrorMsg = '') and (PortMapperTCPSocket <> INVALID_SOCKET);
  BindPortMapperUDP := True;
  BindMountTCP := True;
  BindMountUDP := True;
  BindNFSTCP := True;
  BindNFSUDP := True;

  if (not BindPortMapperTCP) then
  begin
    ZeroMemory(@SockAddr, SizeOf(SockAddr));
    SockAddr.sin_family := AF_INET;
    SockAddr.sin_addr.s_addr := htonl(INADDR_LOOPBACK);
    SockAddr.sin_port := htons(RPCB_PORT);

    Self.Protocol := IPPROTO_TCP;
    Socket := WinSock.socket(AF_INET, SOCK_STREAM, Self.Protocol);
    if (Socket = INVALID_SOCKET) then
      FErrorMsg := 'Can''t create TCP socket'
    else
    begin
      ZeroMemory(@SockAddr, SizeOf(SockAddr));
      SockAddr.sin_family := AF_INET;
      SockAddr.sin_addr.s_addr := htonl(INADDR_LOOPBACK);
      SockAddr.sin_port := htons(RPCB_PORT);

      if (connect(Socket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR) then
      begin
        closesocket(Socket);
        Socket := INVALID_SOCKET;
        FErrorMsg := 'Can''t connect to local TCP port ' + IntToStr(ntohs(SockAddr.sin_port));
      end
      else
      begin
        WriteBuffer.Offset := 0;
        WriteBuffer.Size := 4; // Fragment Header

        Randomize();
        XID := Random(High(Integer));

        if (not Write(XID)
          or not Write(ULONG(CALL))
          or not Write(ULONG(RPCBVERS))
          or not Write(ULONG(RPCB_PROG))
          or not Write(ULONG(RPCB_VERS))
          or not Write(ULONG(RPCBPROC_DUMP))
          or not Write(LONGLONG(0))
          or not Write(LONGLONG(0))
          or not Flush()) then
          FErrorMsg := 'Unknown usage of local TCP port ' + IntToStr(ntohs(SockAddr.sin_port))
        else
        begin
          FD_ZERO(ReadFDS);
          FD_SET(Socket, ReadFDS);
          Time.tv_sec := 5; Time.tv_usec := Time.tv_sec * 1000;
          if ((select(0, @ReadFDS, nil, nil, @Time) >= 1)) then
          if (Read(DW) and (DW = XID)
            and Read(DW) and (msg_type(DW) = REPLY)
            and Read(DW) and (reply_stat(DW) = MSG_ACCEPTED)
            and Read(Verifier)
            and Read(DW) and (auth_stat(DW) = AUTH_OK)) then
            while (Read(EntryFollow) and EntryFollow
              and Read(ProgramId)
              and Read(ProgramVer)
              and Read(Protocol)
              and Read(Port)) do
              if ((ProgramId = RPCB_PROG) and (ProgramVer = RPCB_VERS) and (Protocol = IPPROTO_UDP)) then
                BindPortMapperUDP := False
              else if ((ProgramId = MOUNT_PROGRAM) and (ProgramVer = MOUNT_V3) and (Protocol = IPPROTO_TCP)) then
                BindMountTCP := False
              else if ((ProgramId = MOUNT_PROGRAM) and (ProgramVer = MOUNT_V3) and (Protocol = IPPROTO_UDP)) then
                BindMountUDP := False
              else if ((ProgramId = NFS_PROGRAM) and (ProgramVer = NFS_V3) and (Protocol = IPPROTO_TCP)) then
                BindNFSTCP := False
              else if ((ProgramId = NFS_PROGRAM) and (ProgramVer = NFS_V3) and (Protocol = IPPROTO_UDP)) then
                BindNFSUDP := False;
        end;

        if (not BindNFSTCP or not BindNFSUDP or not BindMountTCP or not BindMountUDP) then
        begin
          shutdown(Socket, SD_BOTH);
          closesocket(Socket);
          Socket := INVALID_SOCKET;
        end;
      end;
    end;
  end;

  if (FErrorMsg = '') then
    if (not BindNFSTCP or not BindNFSUDP) then
      FErrorMsg := 'A NFS server is still running on this machine'
    else if (not BindMountTCP or not BindMountUDP) then
      FErrorMsg := 'A Mount service is still running on this machine'
    else if (not BindPortMapperTCP or not BindPortMapperUDP) then
      FErrorMsg := 'A Portmapper is still running on local TCP port ' + IntToStr(ntohs(SockAddr.sin_port));

  if ((FErrorMsg = '') and BindPortMapperTCP and BindPortMapperUDP) then
  begin
    PortMapperUDPSocket := WinSock.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (PortMapperUDPSocket = INVALID_SOCKET) then
      FErrorMsg := 'Can''t create UDP socket'
    else if (bind(PortMapperUDPSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR) then
      FErrorMsg := 'Can''t bind socket to local UDP port ' + IntToStr(ntohs(SockAddr.sin_port));
  end;


  ZeroMemory(@SockAddr, SizeOf(SockAddr));
  SockAddr.sin_family := AF_INET;
  SockAddr.sin_addr.s_addr := htonl(INADDR_ANY);
  SockAddr.sin_port := htons(MountDaemonPort);

  if ((FErrorMsg = '') and BindMountTCP) then
  begin
    MountTCPSocket := WinSock.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (MountTCPSocket = INVALID_SOCKET) then
      FErrorMsg := 'Can''t create TCP socket'
    else if (bind(MountTCPSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR) then
      FErrorMsg := 'Can''t bind socket to local TCP port ' + IntToStr(ntohs(SockAddr.sin_port))
    else if (listen(MountTCPSocket, 0) = SOCKET_ERROR) then
      FErrorMsg := 'Can''t listen on local TCP port ' + IntToStr(ntohs(SockAddr.sin_port));
  end;

  if ((FErrorMsg = '') and BindMountUDP) then
  begin
    MountUDPSocket := WinSock.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (MountUDPSocket = INVALID_SOCKET) then
      FErrorMsg := 'Can''t create UDP socket'
    else if (bind(MountUDPSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR) then
      FErrorMsg := 'Can''t bind socket to local UDP port ' + IntToStr(ntohs(SockAddr.sin_port));
  end;


  ZeroMemory(@SockAddr, SizeOf(SockAddr));
  SockAddr.sin_family := AF_INET;
  SockAddr.sin_addr.s_addr := htonl(INADDR_ANY);
  SockAddr.sin_port := htons(NFSDeamounPort);

  if ((FErrorMsg = '') and BindNFSTCP) then
  begin
    NFSTCPSocket := WinSock.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (NFSTCPSocket = INVALID_SOCKET) then
      FErrorMsg := 'Can''t create TCP socket'
    else if (bind(NFSTCPSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR) then
      FErrorMsg := 'Can''t bind socket to local TCP port ' + IntToStr(ntohs(SockAddr.sin_port))
    else if (listen(NFSTCPSocket, 0) = SOCKET_ERROR) then
      FErrorMsg := 'Can''t listen on local TCP port ' + IntToStr(ntohs(SockAddr.sin_port));
  end;

  if ((FErrorMsg = '') and BindNFSUDP) then
  begin
    NFSUDPSocket := WinSock.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (NFSUDPSocket = INVALID_SOCKET) then
      FErrorMsg := 'Can''t create UDP socket'
    else if (bind(NFSUDPSocket, SockAddr, SizeOf(SockAddr)) = SOCKET_ERROR) then
      FErrorMsg := 'Can''t bind socket to local UDP port ' + IntToStr(ntohs(SockAddr.sin_port));
  end;


  ZeroMemory(@ReadBuffer, SizeOf(ReadBuffer));
  ReallocBuffer(ReadBuffer, DefaultPacketSize);

  ZeroMemory(@WriteBuffer, SizeOf(WriteBuffer));
  ReallocBuffer(WriteBuffer, DefaultPacketSize);

  ZeroMemory(@FileBuffer, SizeOf(FileBuffer));
  FileBuffer.SystemMemory := True;
  ReallocBuffer(FileBuffer, 2 * DefaultPacketSize);
end;

function TDaemon.DecodeName(const nameA: PAnsiChar): PWideChar;
begin
  MultiByteToWideChar(CodePage, 0, nameA, -1, @DecodingName, High(DecodingName));
  Result := @DecodingName;
end;

destructor TDaemon.Destroy();
begin
  if (PortMapperTCPSocket <> INVALID_SOCKET) then
  begin
    shutdown(PortMapperTCPSocket, SD_BOTH);
    closesocket(PortMapperTCPSocket);
  end;

  if (PortMapperUDPSocket <> INVALID_SOCKET) then
  begin
    shutdown(PortMapperUDPSocket, SD_BOTH);
    closesocket(PortMapperUDPSocket);
  end;


  if (PortMapperTCPSocket <> INVALID_SOCKET) then
  begin
    shutdown(MountTCPSocket, SD_BOTH);
    closesocket(MountTCPSocket);
  end;

  if (PortMapperTCPSocket <> INVALID_SOCKET) then
  begin
    shutdown(MountUDPSocket, SD_BOTH);
    closesocket(MountUDPSocket);
  end;


  if (PortMapperTCPSocket <> INVALID_SOCKET) then
  begin
    shutdown(NFSTCPSocket, SD_BOTH);
    closesocket(NFSTCPSocket);
  end;

  if (PortMapperTCPSocket <> INVALID_SOCKET) then
  begin
    shutdown(NFSUDPSocket, SD_BOTH);
    closesocket(NFSUDPSocket);
  end;

  ReallocBuffer(ReadBuffer, 0);
  ReallocBuffer(WriteBuffer, 0);
  ReallocBuffer(FileBuffer, 0);


  ReadDirHandles.Free();
  ObjectHandles.Free();
  Mounts.Free();
  AllowedAddrs.Free();


  inherited;
end;

function TDaemon.EncodeName(const name: PWideChar): PAnsiChar;
begin
  WideCharToMultiByte(CodePage, 0, name, -1, @EncodingNameA, High(EncodingNameA), nil, nil);
  Result := @EncodingNameA;
end;

procedure TDaemon.Execute();
var
  ReadFDS: TFDSet;
  Time: timeval;
  XID: ULONG;
  MessageType: msg_type;
  RPCVersion: ULONG;
  ProgramId: ULONG;
  ProgramVer: ULONG;
  ProgramProc: ULONG;
  TCPSockets: TList;
  Size: u_int;
  I: Integer;
  Data: Pointer;
  DW, Len: ULONG;
  Success: Boolean;
  LocalAddr: sockaddr_in;
  LastTickCount: DWord;
begin
  LastTickCount := 0;
  Time.tv_sec := 1; Time.tv_usec := Time.tv_sec * 1000;

  TCPSockets := TList.Create();

  repeat
    FD_ZERO(ReadFDS);
    if (PortMapperTCPSocket <> INVALID_SOCKET) then
      FD_SET(PortMapperTCPSocket, ReadFDS);
    if (PortMapperUDPSocket <> INVALID_SOCKET) then
      FD_SET(PortMapperUDPSocket, ReadFDS);
    FD_SET(MountTCPSocket, ReadFDS);
    FD_SET(MountUDPSocket, ReadFDS);
    FD_SET(NFSTCPSocket, ReadFDS);
    FD_SET(NFSUDPSocket, ReadFDS);
    for I := 0 to TCPSockets.Count - 1 do
      FD_SET(TSocket(TCPSockets.Items[I]), ReadFDS);

    if (select(0, @ReadFDS, nil, nil, @Time) >= 1) then
    begin
      if ((ReadFDS.fd_array[0] = PortMapperTCPSocket) or (ReadFDS.fd_array[0] = MountTCPSocket) or (ReadFDS.fd_array[0] = NFSTCPSocket)) then
      begin
        Socket := accept(ReadFDS.fd_array[0], nil, nil);
        Protocol := IPPROTO_TCP;

        TCPSockets.Add(Pointer(Socket));
      end
      else if ((ReadFDS.fd_array[0] = PortMapperUDPSocket) or (ReadFDS.fd_array[0] = MountUDPSocket) or (ReadFDS.fd_array[0] = NFSUDPSocket)) then
      begin
        Socket := ReadFDS.fd_array[0];
        Protocol := IPPROTO_UDP;
      end
      else // created TCP connection
      begin
        Socket := ReadFDS.fd_array[0];
        Protocol := IPPROTO_TCP;
      end;

      Size := SizeOf(LocalAddr);
      if (getsockname(Socket, LocalAddr, Size) <> SOCKET_ERROR) then
      begin
        ReadBuffer.Offset := 0;
        ReadBuffer.Size := 0;
        if (Protocol = IPPROTO_TCP) then
        begin
          WriteBuffer.Offset := 0;
          WriteBuffer.Size := 4; // Fragment Header
          Size := SizeOf(LocalAddr);
          if (getpeername(Socket, RemoteAddr, Size) = SOCKET_ERROR) then
            ZeroMemory(@RemoteAddr, SizeOf(RemoteAddr));
        end
        else
        begin
          WriteBuffer.Offset := 0;
          WriteBuffer.Size := 0;
        end;

        if (Read(XID)) then
        begin
          Data := nil;

          Success := Read(DW); if (Success) then MessageType := msg_type(DW) else MessageType := CALL;
          Success := Success and Read(RPCVersion);
          Success := Success and Read(ProgramId);
          Success := Success and Read(ProgramVer);
          Success := Success and Read(ProgramProc);

          Success := Success and Read(DW);
          Success := Success and Read(Len);
          if (Success and (Len > 0)) then
          begin
            ReallocMem(Data, Len);
            Success := Success and Read(Data^, Len);
          end;

          Success := Success and Read(DW);
          Success := Success and Read(Len);
          if (Success and (Len > 0)) then
          begin
            ReallocMem(Data, Len);
            Success := Success and Read(Data^, Len);
          end;

          if (Assigned(Data)) then
            FreeMem(Data);

          if (Success) then
          begin
            Success := Write(XID);
            Success := Success and Write(ULONG(REPLY));

            if (Success) then
              if ((RPCVersion <> RPCBVERS) or (MessageType <> CALL)) then
              begin
                Success := Success and Write(ULONG(MSG_DENIED));
                Success := Success and Write(ULONG(RPC_MISMATCH));
                Success := Success and Write(ULONG(RPCBVERS));
                Success := Success and Write(ULONG(RPCBVERS));
              end
              else
              begin
                case (ntohs(LocalAddr.sin_port)) of
                  RPCB_PORT:
                    if (not AddrAllowed(RemoteAddr.sin_addr.S_addr)) then
                    begin
                      Success := Success and Write(ULONG(MSG_DENIED));
                      Success := Success and Write(ULONG(AUTH_ERROR));
                      Success := Success and Write(ULONG(AUTH_TOOWEAK));
                    end
                    else
                    begin
                      Success := Success and Write(ULONG(MSG_ACCEPTED));
                      Success := Success and Write(ULONG(AUTH_OK));
                      Success := Success and Write(ULONG(0));
                      case (ProgramId) of
                        RPCB_PROG:
                          case (ProgramVer) of
                            RPCB_VERS:
                              case (RPCBPROC(ProgramProc)) of
                                RPCBPROC_NULL:        Success := PMA2_Null();
    //                            RPCBPROC_SET:
    //                            RPCBPROC_UNSET:
                                RPCBPROC_GETPORT:     Success := PMA2_GetPort();
                                RPCBPROC_DUMP:        Success := PMA2_Dump();
    //                            RPCBPROC_CALLIT:
                                RPCBPROC_GETTIME:     Success := PMA2_GetTime();
    //                            RPCBPROC_UADDR2TADDR:
    //                            RPCBPROC_TADDR2UADDR:
                                else                  Success := Write(ULONG(PROC_UNAVAIL));
                              end
                            else
                              begin
                                Success := Success and Write(ULONG(PROG_MISMATCH));
                                Success := Success and Write(ULONG(RPCB_VERS));
                                Success := Success and Write(ULONG(RPCB_VERS));
                              end;
                          end;
                        else Success := Write(ULONG(PROG_UNAVAIL));
                      end;
                    end;
                  MountDaemonPort:
                    if (not AddrAllowed(RemoteAddr.sin_addr.S_addr)) then
                    begin
                      Success := Success and Write(ULONG(MSG_DENIED));
                      Success := Success and Write(ULONG(AUTH_ERROR));
                      Success := Success and Write(ULONG(AUTH_TOOWEAK));
                    end
                    else
                    begin
                      Success := Success and Write(ULONG(MSG_ACCEPTED));
                      Success := Success and Write(ULONG(AUTH_OK));
                      Success := Success and Write(ULONG(0));
                      case (ProgramId) of
                        MOUNT_PROGRAM:
                          case (ProgramVer) of
                            MOUNT_V3:
                              case (MOUNTPROC3(ProgramProc)) of
                                MOUNTPROC3_NULL:    Success := Mount3_Null();
                                MOUNTPROC3_MNT:     Success := Mount3_Mnt();
    //                            MOUNTPROC3_DUMP:
                                MOUNTPROC3_UMNT:     Success := Mount3_UMnt();
                                MOUNTPROC3_UMNTALL:  Success := Mount3_UMntAll();
    //                            MOUNTPROC3_EXPORT:
                                else                Success := Write(ULONG(PROC_UNAVAIL));
                              end
                            else
                              begin
                                Success := Success and Write(ULONG(PROG_MISMATCH));
                                Success := Success and Write(ULONG(MOUNT_V3));
                                Success := Success and Write(ULONG(MOUNT_V3));
                              end;
                          end;
                        else Success := Write(ULONG(PROG_UNAVAIL));
                      end;
                    end;
                  NFSDeamounPort:
                    if (not AddrAccepted(RemoteAddr.sin_addr.S_addr)) then
                    begin
                      Success := Success and Write(ULONG(MSG_DENIED));
                      Success := Success and Write(ULONG(AUTH_ERROR));
                      Success := Success and Write(ULONG(AUTH_TOOWEAK));
                    end
                    else
                    begin
                      Success := Success and Write(ULONG(MSG_ACCEPTED));
                      Success := Success and Write(ULONG(AUTH_OK));
                      Success := Success and Write(ULONG(0));
                      case (ProgramId) of
                        NFS_PROGRAM:
                          case (ProgramVer) of
                            NFS_V3:
                              case (NFSPROC3(ProgramProc)) of
                                NFSPROC3_NULL:        Success := NFS3_Null();
                                NFSPROC3_GETATTR:     Success := NFS3_GetAttr();
                                NFSPROC3_SETATTR:     Success := NFS3_SetAttr();
                                NFSPROC3_LOOKUP:      Success := NFS3_Lookup();
                                NFSPROC3_ACCESS:      Success := NFS3_Access();
    //                            NFSPROC3_READLINK:
                                NFSPROC3_READ:        Success := NFS3_Read();
                                NFSPROC3_WRITE:       Success := NFS3_Write();
                                NFSPROC3_CREATE:      Success := NFS3_Create();
                                NFSPROC3_MKDIR:       Success := NFS3_MkDir();
    //                            NFSPROC3_SYMLINK:
    //                            NFSPROC3_MKNOD;
                                NFSPROC3_REMOVE:      Success := NFS3_Remove();
                                NFSPROC3_RMDIR:       Success := NFS3_RmDir();
                                NFSPROC3_RENAME:      Success := NFS3_Rename();
    //                            NFSPROC3_LINK:
                                NFSPROC3_READDIR:     Success := NFS3_ReadDir();
                                NFSPROC3_READDIRPLUS: Success := NFS3_ReadDirPlus();
                                NFSPROC3_FSSTAT:      Success := NFS3_FSStat();
                                NFSPROC3_FSINFO:      Success := NFS3_FSInfo();
                                NFSPROC3_PATHCONF:    Success := NFS3_PathConf();
                                NFSPROC3_COMMIT:      Success := NFS3_Commit();
                                else                  Success := Write(ULONG(PROC_UNAVAIL));
                              end;
                            else
                              begin
                                Success := Success and Write(ULONG(PROG_MISMATCH));
                                Success := Success and Write(ULONG(NFS_V3));
                                Success := Success and Write(ULONG(NFS_V3));
                              end;
                          end;
                        else Success := Write(ULONG(PROG_UNAVAIL));
                      end;
                    end;
                  else Success := False;
                end;
              end;

            if (Success) then Flush();
          end;
        end
        else if (TCPSockets.IndexOf(Pointer(Socket)) >= 0) then
        begin
          TCPSockets.Delete(TCPSockets.IndexOf(Pointer(Socket)));

          shutdown(Socket, SD_BOTH);
          closesocket(Socket);
        end;
      end;
    end
    else if (LastTickCount + 60000 < GetTickCount()) then
    begin
      for I := 0 to ObjectHandles.Count - 1 do
        if ((ObjectHandles.Items[I] is TFileHandle) and (TFileHandle(ObjectHandles.Items[I]).WriteTickCount + 60000 < GetTickCount())) then
          ObjectHandles.CloseWriteHandle(TFileHandle(ObjectHandles.Items[I]));

      LastTickCount := GetTickCount();
    end;

    if (not Suspended and not Terminated and Assigned(CheckTerminated) and CheckTerminated()) then
      Terminate();
  until (Terminated);

  while (TCPSockets.Count > 0) do
  begin
   shutdown(TSocket(TCPSockets.Items[0]), SD_BOTH);
   closesocket(TSocket(TCPSockets.Items[0]));

    TCPSockets.Delete(0);
  end;

  TCPSockets.Free();
end;

function TDaemon.Flush(): Boolean;
var
  PacketSize, SocketSize, Size: u_int;
  FragmentHeader: ULONG;
begin
  if (Protocol = IPPROTO_TCP) then
  begin
    FragmentHeader := htonl($80000000 or (WriteBuffer.Size - (WriteBuffer.Offset + 4)) and $7FFFFFFF);
    MoveMemory(@WriteBuffer.Mem[WriteBuffer.Offset], @FragmentHeader, SizeOf(FragmentHeader));
  end;

  PacketSize := WriteBuffer.Size - WriteBuffer.Offset;

  Size := SizeOf(SocketSize);
  Result := getsockopt(Socket, SOL_SOCKET, SO_SNDBUF, @SocketSize, Size) <> SOCKET_ERROR;
  if (Result and (SocketSize < PacketSize)) then
    Result := setsockopt(Socket, SOL_SOCKET, SO_SNDBUF, @PacketSize, SizeOf(PacketSize)) <> SOCKET_ERROR;

  if (Result) then
    if (Protocol = IPPROTO_TCP) then
      Result := send(Socket, WriteBuffer.Mem[WriteBuffer.Offset], PacketSize, 0) <> SOCKET_ERROR
    else
      Result := sendto(Socket, WriteBuffer.Mem[WriteBuffer.Offset], PacketSize, 0, RemoteAddr, SizeOf(RemoteAddr)) <> SOCKET_ERROR;
end;

function TDaemon.GetNFSStatus(const SysError: DWord): NFS_Stat3;
begin
  case (SysError) of
    ERROR_FILE_NOT_FOUND: Result := NFS3ERR_NOENT;
    ERROR_PATH_NOT_FOUND: Result := NFS3ERR_NOTDIR;
    ERROR_ACCESS_DENIED: Result := NFS3ERR_ACCES;
    ERROR_HANDLE_DISK_FULL: Result := NFS3ERR_NOSPC;
    ERROR_DIR_NOT_EMPTY: Result := NFS3ERR_NOTEMPTY;
    else Result := NFS3ERR_SERVERFAULT;
  end;
end;

function TDaemon.Mount3_Null(): Boolean;
begin
  Result := Write(ULONG(SUCCESS));
end;

function TDaemon.Mount3_Mnt(): Boolean;
var
  len: ULONG;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  status: mountstat3;
  ohandle: TObjectHandle;
  Index: Integer;
  Mount: PMount;
begin
  Result := Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(nameA, len); if (Result) then nameA[len] := #0;

  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not AddrAllowed(RemoteAddr.sin_addr.S_addr)) then
        status := MNT3ERR_ACCES
      else if (len > MAX_PATH) then
        status := MNT3ERR_NAMETOOLONG
      else
      begin
        ohandle := ObjectHandles.GetObjectHandle(nil, DecodeName(nameA));

        if (not Assigned(ohandle)) then
          status := MNT3ERR_NOENT
        else if (not (ohandle is TDirHandle)) then
          status := MNT3ERR_NOTDIR
        else
          status := MNT3_OK;
      end;

      Result := Write(ULONG(status));
      if (status = MNT3_OK) then
      begin
        Result := Result and Write(ULONG(SizeOf(ohandle))); // Size of File Handle
        Result := Result and Write(ohandle, SizeOf(ohandle)); // File Handle
        Result := Result and Write(ULONG(1)); // Flavor count
        Result := Result and Write(ULONG(AUTH_NONE)); // Flavor

        Index := Mounts.IndexOf(DecodeName(nameA), RemoteAddr.sin_addr.S_addr);
        if (Index < 0) then
        begin
          GetMem(Mount, SizeOf(Mount^) + (len + 1) * SizeOf(Mount^.name[0]));
          ZeroMemory(Mount, SizeOf(Mount^));
          Mount^.name := @PAnsiChar(Mount)[SizeOf(Mount^)];
          lstrcpyW(Mount^.name, DecodeName(nameA));
          Mount^.S_addr := RemoteAddr.sin_addr.S_addr;
          Index := Mounts.Add(Mount);
        end;
        Inc(Mounts.Items[Index]^.Count);
      end;
    end;
  end;
end;

function TDaemon.Mount3_UMnt(): Boolean;
var
  len: ULONG;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  Index: Integer;
  status: mountstat3;
begin
  Result := Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(nameA, len); if (Result) then nameA[len] := #0;


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not AddrAccepted(RemoteAddr.sin_addr.S_addr)) then
        status := MNT3ERR_ACCES
      else
        status := MNT3_OK;

      Result := Write(ULONG(status));
      if (status = MNT3_OK) then
      begin
        Index := Mounts.IndexOf(DecodeName(nameA), RemoteAddr.sin_addr.S_addr);
        if (Index >= 0) then
          if (Mounts.Items[Index].Count > 1) then
            Dec(Mounts.Items[Index].Count)
          else
            Mounts.Delete(Index);
      end;
    end;
  end;
end;

function TDaemon.Mount3_UMntAll(): Boolean;
var
  I: Integer;
  status: mountstat3;
begin
  Result := Write(ULONG(SUCCESS));

  if (Result) then
  begin
    if (not AddrAccepted(RemoteAddr.sin_addr.S_addr)) then
      status := MNT3ERR_ACCES
    else
      status := MNT3_OK;

    Result := Write(ULONG(status));
    if (status = MNT3_OK) then
      for I := Mounts.Count - 1 downto 0 do
        if (Mounts.Items[I].S_addr = RemoteAddr.sin_addr.S_addr) then
          Mounts.Delete(I);
  end;
end;

function TDaemon.NFS3_Access(): Boolean;
var
  len: uint32;
  fhandle: TFileHandle;
  FileAccess: uint32;
  status: NFS_Stat3;
  Attr: fattr3;
begin
  Result := Read(len) and (len = SizeOf(fhandle));
  Result := Result and Read(fhandle, len);
  Result := Result and Read(FileAccess);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(fhandle)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(fhandle) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(fhandle, Attr)) then
        status := GetNFSStatus(GetLastError())
      else
        status := NFS3_OK;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
        Result := Result and Write(False) // Attribute follows
      else
      begin
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(Attr, SizeOf(Attr)); // Attribute
        Result := Result and Write(FileAccess); // Access
      end;
    end;
  end;
end;

function TDaemon.NFS3_Commit(): Boolean;
var
  len: uint32;
  fhandle: TFileHandle;
  offset: offset3;
  count: count3;
  status: NFS_Stat3;
  OldAttr, NewAttr: fattr3;
  verf: writeverf3;
begin
  Result := Read(len) and (len = SizeOf(fhandle));
  Result := Result and Read(fhandle, len);
  Result := Result and Read(offset);
  Result := Result and Read(count);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      verf := 0;

      if (not Assigned(fhandle)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(fhandle) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(fhandle, OldAttr)) then
        status := GetNFSStatus(GetLastError())
      else if (fhandle.WriteHandle = INVALID_HANDLE_VALUE) then
        status := NFS3_OK
      else
      begin
        verf := fhandle.WriteHandle;

        ObjectHandles.CloseWriteHandle(fhandle);

        if (not ObjectHandles.GetAttr3(fhandle, NewAttr)) then
          status := GetNFSStatus(GetLastError())
        else
          status := NFS3_OK;
      end;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
      begin
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
      end
      else
      begin
        Result := Result and WriteWCC(OldAttr, NewAttr); // file_wcc
        Result := Result and Write(verf); // verf
      end;
    end;
  end;
end;

function TDaemon.NFS3_Create(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  mode: ULONG;
  ohandle: TObjectHandle;
  sattr: sattr3;
  cookie: createverf3;
  status: NFS_Stat3;
  OldDirAttr, NewDirAttr, FileAttr: fattr3;
  Handle: THandle;
  Attributes: DWord;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);
  Result := Result and Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(nameA, len); if (Result) then nameA[len] := #0;
  Result := Result and Read(mode);
  case (createmode3(mode)) of
    UNCHECKED:
      Result := Result and ReadNewAttr(sattr);
    GUARDED:
      Result := Result and ReadNewAttr(sattr);
    EXCLUSIVE:
      Result := Result and Read(cookie);
  end;


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(dir)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(dir, OldDirAttr)) then
        status := GetNFSStatus(GetLastError())
      else if (Length(dir.Path + DecodeName(nameA)) > MAX_PATH) then
        status := NFS3ERR_NAMETOOLONG
      else
      begin
        ohandle := ObjectHandles.GetObjectHandle(dir, DecodeName(nameA));

        if (Assigned(ohandle)) then
          status := NFS3ERR_EXIST
        else
        begin
          Attributes := 0;
          if (sattr.mode.set_it and (sattr.mode.mode and $80 = 0)) then
            Attributes := Attributes or FILE_ATTRIBUTE_READONLY;
          Handle := CreateFileW(PWideChar(dir.Path + DecodeName(nameA)),
                                GENERIC_WRITE,
                                FILE_SHARE_READ or FILE_SHARE_WRITE,
                                nil, CREATE_NEW, Attributes, 0);
          if (Handle = INVALID_HANDLE_VALUE) then
            status := GetNFSStatus(GetLastError())
          else
          begin
            CloseHandle(Handle);

            ohandle := ObjectHandles.GetObjectHandle(dir, DecodeName(nameA));

            if (not ObjectHandles.GetAttr3(dir, NewDirAttr)) then
              status := GetNFSStatus(GetLastError())
            else if (not ObjectHandles.GetAttr3(ohandle, FileAttr)) then
              status := GetNFSStatus(GetLastError())
            else
              status := NFS3_OK;
          end;
        end;
      end;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
      begin
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
      end
      else
      begin
        Result := Result and Write(True); // File handle follows
        Result := Result and Write(ULONG(SizeOf(ohandle))); // File handle length
        Result := Result and Write(ohandle, SizeOf(ohandle)); // File handle
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(FileAttr, SizeOf(FileAttr)); // Attributes
        Result := Result and WriteWCC(OldDirAttr, NewDirAttr);
      end;
    end;
  end;
end;

function TDaemon.NFS3_FSInfo(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  status: NFS_Stat3;
  Attr: fattr3;
  RecvBufSize: u_long;
  SendBufSize: u_long;
  Size: u_int;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      Size := SizeOf(RecvBufSize);

      if (not Assigned(dir) or not (dir is TDirHandle)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if ((getsockopt(Socket, SOL_SOCKET, SO_RCVBUF, @RecvBufSize, Size) = SOCKET_ERROR) or (getsockopt(Socket, SOL_SOCKET, SO_SNDBUF, @SendBufSize, Size) = SOCKET_ERROR)) then
        status := NFS3ERR_SERVERFAULT
      else if (not ObjectHandles.GetAttr3(dir, Attr)) then
        status := GetNFSStatus(GetLastError())
      else
        status := NFS3_OK;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
        Result := Result and Write(False) // Attribute follows
      else
      begin
        Result := Result and Write(True); // Attribute follow
        Result := Result and Write(Attr, SizeOf(Attr));
        Result := Result and Write(ULONG(MaxPacketSize)); // rtmax
        Result := Result and Write(ULONG(DefaultPacketSize)); // rtpref
        Result := Result and Write(ULONG(dir.BytesPerSector)); // rtmult
        Result := Result and Write(ULONG(MaxPacketSize)); // wtmax
        Result := Result and Write(ULONG(DefaultPacketSize)); // wtpref
        Result := Result and Write(ULONG(dir.BytesPerSector)); // wtmult
        Result := Result and Write(ULONG(DefaultPacketSize)); // dtpref
        Result := Result and Write(LONGLONG(-1)); // maxfilesize
        Result := Result and Write(ULONG(0)); // time_delta seconds
        Result := Result and Write(ULONG(0)); // time_delta nano seconds
        Result := Result and Write(ULONG(FSF_CANSETTIME)); // properties
      end;
    end;
  end;
end;

function TDaemon.NFS3_FSStat(): Boolean;
var
  len: uint32;
  fhandle: TFileHandle;
  status: NFS_Stat3;
  Attr: fattr3;
  FreeAvailable, TotalSpace, TotalFree: TLargeInteger;
begin
  Result := Read(len) and (len = SizeOf(fhandle));
  Result := Result and Read(fhandle, len);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(fhandle)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(fhandle) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(fhandle, Attr) or not GetDiskFreeSpaceExW(PWideChar(fhandle.Path), FreeAvailable, TotalSpace, @TotalFree)) then
        status := GetNFSStatus(GetLastError())
      else
        status := NFS3_OK;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
        Result := Result and Write(False) // Attribute follows
      else
      begin
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(Attr, SizeOf(Attr));
        Result := Result and Write(TotalSpace); // tbytes
        Result := Result and Write(TotalFree); // fbytes
        Result := Result and Write(FreeAvailable); // abytes
        Result := Result and Write(LONGLONG(0)); // tfiles
        Result := Result and Write(LONGLONG(0)); // ffiles
        Result := Result and Write(LONGLONG(0)); // afiles
        Result := Result and Write(ULONG(0)); // invarsec
      end;
    end;
  end;
end;

function TDaemon.NFS3_GetAttr(): Boolean;
var
  len: uint32;
  fhandle: TFileHandle;
  status: NFS_Stat3;
  Attr: fattr3;
begin
  Result := Read(len) and (len = SizeOf(fhandle));
  Result := Result and Read(fhandle, len);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(fhandle)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(fhandle) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(fhandle, Attr)) then
        status := NFS3ERR_SERVERFAULT
      else
        status := NFS3_OK;


      Result := Write(ULONG(status));
      if (status = NFS3_OK) then
      begin
        Result := Result and Write(Attr, SizeOf(Attr));
      end;
    end;
  end;
end;

function TDaemon.NFS3_Lookup(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  status: NFS_Stat3;
  ohandle: TObjectHandle;
  Attr, FileAttr: fattr3;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);
  Result := Result and Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(nameA, len); if (Result) then nameA[len] := #0;


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(dir)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if (Length(dir.Path + DecodeName(nameA)) > MAX_PATH) then
        status := NFS3ERR_NAMETOOLONG
      else if (not ObjectHandles.GetAttr3(dir, Attr)) then
        status := GetNFSStatus(GetLastError())
      else
      begin
        ohandle := ObjectHandles.GetObjectHandle(dir, DecodeName(nameA));

        if (not Assigned(ohandle)) then
          status := NFS3ERR_NOENT
        else if (ObjectHandles.IndexOf(ohandle) < 0) then
          status := NFS3ERR_STALE
        else if (not ObjectHandles.GetAttr3(ohandle, FileAttr)) then
          status := GetNFSStatus(GetLastError())
        else
          status := NFS3_OK;
      end;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
        Result := Result and Write(False) // Attribute follows
      else
      begin
        Result := Result and Write(ULONG(SizeOf(ohandle)));
        Result := Result and Write(ohandle, SizeOf(ohandle));
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(FileAttr, SizeOf(FileAttr));
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(Attr, SizeOf(Attr));
      end;
    end;
  end;
end;

function TDaemon.NFS3_MkDir(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  sattr: sattr3;
  status: NFS_Stat3;
  ohandle: TObjectHandle;
  OldDirAttr, NewDirAttr, FileAttr: fattr3;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);
  Result := Result and Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(nameA, len); if (Result) then nameA[len] := #0;
  Result := Result and ReadNewAttr(sattr);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(dir)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if (Length(dir.Path + DecodeName(nameA)) > MAX_PATH) then
        status := NFS3ERR_NAMETOOLONG
      else if (DirectoryExists(dir.Path + DecodeName(nameA))) then
        status := NFS3ERR_EXIST
      else if (not ObjectHandles.GetAttr3(dir, OldDirAttr)) then
        status := GetNFSStatus(GetLastError())
      else if (not CreateDirectoryW(PWideChar(dir.Path + DecodeName(nameA)), nil)) then
        status := GetNFSStatus(GetLastError())
      else
      begin
        ohandle := ObjectHandles.GetObjectHandle(dir, PWideChar(DecodeName(nameA)));

        if (not ObjectHandles.GetAttr3(dir, NewDirAttr)) then
          status := GetNFSStatus(GetLastError())
        else
          status := NFS3_OK;
      end;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
      begin
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
      end
      else
      begin
        Result := Result and Write(True); // File handle follows
        Result := Result and Write(ULONG(SizeOf(ohandle))); // File handle length
        Result := Result and Write(ohandle, SizeOf(ohandle)); // File handle
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(FileAttr, SizeOf(FileAttr)); // Attributes
        Result := Result and WriteWCC(OldDirAttr, NewDirAttr);
      end;
    end;
  end;
end;

function TDaemon.NFS3_Null(): Boolean;
begin
  Result := Write(ULONG(SUCCESS));
end;

function TDaemon.NFS3_PathConf(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  status: NFS_Stat3;
  Attr: fattr3;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(dir)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(dir, Attr)) then
        status := GetNFSStatus(GetLastError())
      else
        status := NFS3_OK;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
        Result := Result and Write(True) // Attribute follows
      else
      begin
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(Attr, SizeOf(Attr)); // Attributes
        Result := Result and Write(ULONG(0)); // linkmax
        Result := Result and Write(ULONG(MAX_PATH)); // name_max
        Result := Result and Write(True); // no_trunc
        Result := Result and Write(True); // chown_restricted
        Result := Result and Write(True); // case_insensitive
        Result := Result and Write(True); // case_preserving
      end;
    end;
  end;
end;

function TDaemon.NFS3_Read(): Boolean;
var
  len: uint32;
  fhandle: TFileHandle;
  offset: offset3;
  count: count3;
  status: NFS_Stat3;
  Attr: fattr3;
  Handle: THandle;
  FileOffset, FileSize: LARGE_INTEGER;
  BytesToRead, BytesRead: DWord;
begin
  Result := Read(len) and (len = SizeOf(fhandle));
  Result := Result and Read(fhandle, len);
  Result := Result and Read(offset);
  Result := Result and Read(count);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(fhandle)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(fhandle) < 0) then
        status := NFS3ERR_STALE
      else
      begin
        Handle := CreateFileW(PWideChar(fhandle.Path),
                              GENERIC_READ,
                              FILE_SHARE_READ or FILE_SHARE_WRITE,
                              nil, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, 0);
        if (Handle = INVALID_HANDLE_VALUE) then
          status := NFS3ERR_SERVERFAULT
        else if (not ObjectHandles.GetAttr3(fhandle, Handle, Attr)) then
          status := GetNFSStatus(GetLastError())
        else
        begin
          FileSize.LowPart := GetFileSize(Handle, @FileSize.HighPart);

          if (GetLastError() <> 0) then
            status := GetNFSStatus(GetLastError())
          else if (offset >= FileSize.QuadPart) then
            status := NFS3ERR_NXIO
          else
          begin
            FileOffset.LowPart := offset and $FFFFFFFF and fhandle.dir.FileOffsetMask;
            FileOffset.HighPart := offset shr 32;
            FileOffset.LowPart := SetFilePointer(Handle, FileOffset.LowPart, @FileOffset.HighPart, FILE_BEGIN);

            if (GetLastError() <> 0) then
              status := GetNFSStatus(GetLastError())
            else
            begin
              BytesToRead := offset + count - FileOffset.QuadPart;
              if (BytesToRead mod fhandle.dir.BytesPerSector > 0) then
                Inc(BytesToRead, fhandle.dir.BytesPerSector - BytesToRead mod fhandle.dir.BytesPerSector);
              if (BytesToRead > FileBuffer.TotalSize) then
                ReallocBuffer(FileBuffer, BytesToRead, fhandle.dir.BytesPerSector);

              if (Filebuffer.TotalSize < count) then
                status := NFS3ERR_SERVERFAULT
              else if (not ReadFile(Handle, FileBuffer.Mem^, BytesToRead, BytesRead, nil)) then
                status := GetNFSStatus(GetLastError())
              else
              begin
                count := Min(count, BytesRead - (offset - FileOffset.QuadPart));

                status := NFS3_OK;
              end;
            end;
          end;

          CloseHandle(Handle);
        end;
      end;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
        Result := Result and Write(True) // Attribute follows
      else
      begin
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(Attr, SizeOf(Attr)); // Attributes
        Result := Result and Write(count); // Count
        Result := Result and Write(ULONG(Boolean(offset + count = FileSize.QuadPart))); // EOF
        Result := Result and Write(count); // Count
        Result := Result and Write(FileBuffer.Mem[offset - FileOffset.QuadPart], count);
      end;
    end;
  end;
end;

function TDaemon.NFS3_ReadDir(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  cookie: cookie3;
  cookieverf: cookieverf3;
  count: count3;
  status: NFS_Stat3;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  ReadDirHandle: PReadDirHandle;
  Attr: fattr3;
  Index: Integer;
  Size: u_int;
  RecvBufSize: u_long;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);
  Result := Result and Read(cookie);
  Result := Result and Read(cookieverf);
  Result := Result and Read(count);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      EnterCriticalSection(ReadDirHandles.CriticalSection);

      Size := SizeOf(RecvBufSize);
      if (getsockopt(Socket, SOL_SOCKET, SO_RCVBUF, @RecvBufSize, Size) = SOCKET_ERROR) then
        status := NFS3ERR_SERVERFAULT
      else if (not Assigned(dir)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(dir, Attr)) then
        status := GetNFSStatus(GetLastError())
      else if (cookieverf <> 0) then
      begin
        Index := ReadDirHandles.IndexOf(Pointer(cookieverf));
        if (Index = -1) then
          status := NFS3ERR_BAD_COOKIE
        else
        begin
          status := NFS3_OK;
          ReadDirHandle := ReadDirHandles.Items[Index];
        end
      end
      else
      begin
        ReadDirHandle := ReadDirHandles.GetReadDirHandle(dir);

        if (not Assigned(ReadDirHandle)) then
          status := GetNFSStatus(GetLastError())
        else
        begin
          status := NFS3_OK;
          cookieverf := cookieverf3(ReadDirHandle);
        end;
      end;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
        Result := Result and Write(False) // Attribute follows
      else
      begin
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(Attr, SizeOf(Attr)); // Attributes
        Result := Result and Write(cookieverf); // Cookie Verifier

        Index := 0;
        if (cookie + Index >= ReadDirHandle^.Files.Count) then
          Size := 0
        else
        begin
          lstrcpynA(@nameA, EncodeName(ReadDirHandle^.Files.Items[cookie + Index]^.cFileName), SizeOf(nameA));
          Size := lstrlenA(@nameA); if (Size mod 4 > 0) then Inc(Size, 4 - (Size mod 4));
          Size := SizeOf(DWord) + SizeOf(fileid3) + SizeOf(uint32) + Size + SizeOf(cookie3);
        end;
        while (Result and (cookie + Index < ReadDirHandle^.Files.Count) and (Abs(WriteBuffer.Size) + Size + SizeOf(uint32) + SizeOf(uint32) <= Abs(count))) do
        begin
          Result := Result and Write(True); // Entry follows
          Result := Result and Write(fileid3(cookie + Index + 1)); // fileid
          Result := Result and Write(ULONG(lstrlenA(@nameA))); // length
          Result := Result and Write(nameA, lstrlenA(@nameA)); // name
          Result := Result and Write(cookie3(cookie + Index + 1)); // cookie

          Inc(Index);
          if (cookie + Index >= ReadDirHandle^.Files.Count) then
            Size := 0
          else
          begin
            lstrcpynA(@nameA, EncodeName(ReadDirHandle^.Files.Items[cookie + Index]^.cFileName), SizeOf(nameA));
            Size := lstrlenA(@nameA); if (Size mod 4 > 0) then Inc(Size, 4 - (Size mod 4));
            Size := SizeOf(DWord) + SizeOf(fileid3) + SizeOf(uint32) + Size + SizeOf(cookie3);
          end;
        end;
        Result := Result and Write(False); // Entry follows
        Result := Result and Write(cookie + Index = ReadDirHandle^.Files.Count); // EOF
      end;

      LeaveCriticalSection(ReadDirHandles.CriticalSection);
    end;
  end;
end;

function TDaemon.NFS3_ReadDirPlus(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  cookie: cookie3;
  cookieverf: cookieverf3;
  dircount: count3;
  maxcount: count3;
  status: NFS_Stat3;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  ReadDirHandle: PReadDirHandle;
  Attr: fattr3;
  ohandle: TObjectHandle;
  Index: Integer;
  Size, DirSize: u_int;
  RecvBufSize: u_long;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);
  Result := Result and Read(cookie);
  Result := Result and Read(cookieverf);
  Result := Result and Read(dircount);
  Result := Result and Read(maxcount);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      EnterCriticalSection(ReadDirHandles.CriticalSection);

      Size := SizeOf(RecvBufSize);
      if (getsockopt(Socket, SOL_SOCKET, SO_RCVBUF, @RecvBufSize, Size) = SOCKET_ERROR) then
        status := NFS3ERR_SERVERFAULT
      else if (not Assigned(dir)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(dir, Attr)) then
        status := GetNFSStatus(GetLastError())
      else if (cookieverf <> 0) then
      begin
        Index := ReadDirHandles.IndexOf(Pointer(cookieverf));
        if (Index = -1) then
          status := NFS3ERR_BAD_COOKIE
        else
        begin
          status := NFS3_OK;
          ReadDirHandle := ReadDirHandles.Items[Index];
        end
      end
      else
      begin
        ReadDirHandle := ReadDirHandles.GetReadDirHandle(dir);

        if (not Assigned(ReadDirHandle)) then
          status := GetNFSStatus(GetLastError())
        else
        begin
          status := NFS3_OK;
          cookieverf := cookieverf3(ReadDirHandle);
        end;
      end;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
        Result := Result and Write(False) // Attribute follows
      else
      begin
        Result := Result and Write(True); // Attribute follows
        Result := Result and Write(Attr, SizeOf(Attr)); // Attributes
        Result := Result and Write(cookieverf); // Cookie Verifier

        Index := 0; DirSize := 0;
        if (cookie + Index >= ReadDirHandle^.Files.Count) then
          Size := 0
        else
        begin
          lstrcpynA(@nameA, EncodeName(ReadDirHandle^.Files.Items[cookie + Index]^.cFileName), SizeOf(nameA));
          Size := lstrlenA(@nameA); if (Size mod 4 > 0) then Inc(Size, 4 - (Size mod 4));
          Size := SizeOf(uint32) + SizeOf(fileid3) + SizeOf(uint32) + Size + SizeOf(cookie3) + SizeOf(uint32) + SizeOf(Attr) + SizeOf(uint32) + SizeOf(uint32) + SizeOf(ohandle);
        end;
        while (Result and (cookie + Index < ReadDirHandle^.Files.Count) and (DirSize + Size + SizeOf(uint32) + SizeOf(uint32) < Abs(dircount)) and (Abs(WriteBuffer.Size) + Size + SizeOf(uint32) + SizeOf(uint32) <= Abs(maxcount))) do
        begin
          ohandle := ObjectHandles.GetObjectHandle(dir, @ReadDirHandle^.Files.Items[cookie + Index]^.cFileName);

          Result := Result and Write(True); // Entry follows
          Result := Result and Write(fileid3(ObjectHandles.IndexOf(ohandle))); // fileid
          Result := Result and Write(ULONG(lstrlenA(@nameA))); // length
          Result := Result and Write(nameA, lstrlenA(@nameA)); // name
          Result := Result and Write(cookie3(cookie + Index + 1)); // cookie
          if (not ObjectHandles.GetAttr3(ohandle, Attr)) then
            Result := Result and Write(False) // Attribute follows
          else
          begin
            Result := Result and Write(True); // Attribute follows
            Result := Result and Write(Attr, SizeOf(Attr)); // Attributes
          end;
          if (not Assigned(ohandle)) then
            Result := Result and Write(False) // File Handle follows
          else
          begin
            Result := Result and Write(True); // File Handle follows
            Result := Result and Write(ULONG(SizeOf(ohandle)));
            Result := Result and Write(ohandle, SizeOf(ohandle));
          end;
          Inc(DirSize, Size);

          Inc(Index);
          if (cookie + Index >= ReadDirHandle^.Files.Count) then
            Size := 0
          else
          begin
            lstrcpynA(@nameA, EncodeName(ReadDirHandle^.Files.Items[cookie + Index]^.cFileName), SizeOf(nameA));
            Size := lstrlenA(@nameA); if (Size mod 4 > 0) then Inc(Size, 4 - (Size mod 4));
            Size := SizeOf(uint32) + SizeOf(fileid3) + SizeOf(uint32) + Size + SizeOf(cookie3) + SizeOf(uint32) + SizeOf(Attr) + SizeOf(uint32) + SizeOf(uint32) + SizeOf(ohandle);
          end;
        end;
        Result := Result and Write(False); // Entry follows
        Result := Result and Write(cookie + Index = ReadDirHandle^.Files.Count); // EOF
      end;

      LeaveCriticalSection(ReadDirHandles.CriticalSection);
    end;
  end;
end;

function TDaemon.NFS3_Remove(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  status: NFS_Stat3;
  OldDirAttr, NewDirAttr: fattr3;
  Index: Integer;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);
  Result := Result and Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(nameA, len); if (Result) then nameA[len] := #0;


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(dir)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(dir, OldDirAttr)) then
        status := GetNFSStatus(GetLastError())
      else if (Length(dir.Path + DecodeName(nameA)) > MAX_PATH) then
        status := NFS3ERR_NAMETOOLONG
      else if (not DeleteFileW(PWideChar(dir.Path + DecodeName(nameA)))) then
        status := GetNFSStatus(GetLastError())
      else if (not ObjectHandles.GetAttr3(dir, NewDirAttr)) then
        status := GetNFSStatus(GetLastError())
      else
        status := NFS3_OK;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
      begin
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
      end
      else
      begin
        Result := Result and WriteWCC(OldDirAttr, NewDirAttr);

        Index := ObjectHandles.IndexOf(ObjectHandles.GetObjectHandle(dir, DecodeName(nameA)));
        if (Index >= 0) then
          ObjectHandles.Delete(Index);
      end;
    end;
  end;
end;

function TDaemon.NFS3_Rename(): Boolean;
var
  len: uint32;
  from, _to: record dir: TDirHandle; nameA: array [0..MNTPATHLEN] of AnsiChar; end;
  status: NFS_Stat3;
  OldFromDirAttr, NewFromDirAttr, OldToDirAttr, NewToDirAttr: fattr3;
  Index: Integer;
begin
  Result := Read(len) and (len = SizeOf(from.dir));
  Result := Result and Read(from.dir, SizeOf(from.dir));
  Result := Result and Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(from.nameA, len); if (Result) then from.nameA[len] := #0;
  Result := Result and Read(len) and (len = SizeOf(_to.dir));
  Result := Result and Read(_to.dir, len);
  Result := Result and Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(_to.nameA, len); if (Result) then _to.nameA[len] := #0;


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(from.dir) or not Assigned(_to.dir)) then
        status := NFS3ERR_BADHANDLE
      else if ((ObjectHandles.IndexOf(from.dir) < 0) or (ObjectHandles.IndexOf(_to.dir) < 0)) then
        status := NFS3ERR_STALE
      else if (FileExists(_to.dir.Path + DecodeName(_to.nameA))) then
        status := NFS3ERR_NOTDIR
      else if (not ObjectHandles.GetAttr3(from.dir, OldFromDirAttr) or not ObjectHandles.GetAttr3(_to.dir, OldToDirAttr)) then
        status := GetNFSStatus(GetLastError())
      else if (Length(_to.dir.Path + DecodeName(_to.nameA)) > MAX_PATH) then
        status := NFS3ERR_NAMETOOLONG
      else if (not MoveFileW(PWideChar(from.dir.Path + DecodeName(from.nameA)), PWideChar(_to.dir.Path + DecodeName(_to.nameA)))) then
        status := GetNFSStatus(GetLastError())
      else if (not ObjectHandles.GetAttr3(from.dir, NewFromDirAttr) or not ObjectHandles.GetAttr3(_to.dir, NewToDirAttr)) then
        status := GetNFSStatus(GetLastError())
      else
        status := NFS3_OK;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
      begin
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
      end
      else
      begin
        Result := Result and WriteWCC(OldFromDirAttr, NewFromDirAttr);
        Result := Result and WriteWCC(OldToDirAttr, NewToDirAttr);

        Index := ObjectHandles.IndexOf(ObjectHandles.GetObjectHandle(from.dir, DecodeName(from.nameA)));
        if (Index >= 0) then
          ObjectHandles.Delete(Index);
      end;
    end;
  end;
end;

function TDaemon.NFS3_RmDir(): Boolean;
var
  len: uint32;
  dir: TDirHandle;
  nameA: array [0..MNTPATHLEN] of AnsiChar;
  status: NFS_Stat3;
  OldDirAttr, NewDirAttr: fattr3;
  Index: Integer;
begin
  Result := Read(len) and (len = SizeOf(dir));
  Result := Result and Read(dir, len);
  Result := Result and Read(len) and (0 < len) and (len < MNTPATHLEN);
  Result := Result and Read(nameA, len); if (Result) then nameA[len] := #0;


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(dir)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(dir) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(dir, OldDirAttr)) then
        status := GetNFSStatus(GetLastError())
      else if (Length(dir.Path + DecodeName(nameA)) > MAX_PATH) then
        status := NFS3ERR_NAMETOOLONG
      else if (not RemoveDirectoryW(PWideChar(dir.Path + DecodeName(nameA)))) then
        status := GetNFSStatus(GetLastError())
      else if (not ObjectHandles.GetAttr3(dir, NewDirAttr)) then
        status := GetNFSStatus(GetLastError())
      else
        status := NFS3_OK;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
      begin
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
      end
      else
      begin
        Result := Result and WriteWCC(OldDirAttr, NewDirAttr);

        Index := ObjectHandles.IndexOf(ObjectHandles.GetObjectHandle(dir, DecodeName(nameA)));
        if (Index >= 0) then
          ObjectHandles.Delete(Index);
      end;
    end;
  end;
end;

function TDaemon.NFS3_SetAttr(): Boolean;
var
  len: uint32;
  fhandle: TFileHandle;
  OldAttr, NewAttr: fattr3;
  sattr: sattr3;
  guard: sattrguard3;
  status: NFS_Stat3;
  Handle: THandle;
  FileOffset: LARGE_INTEGER;
  CreationTime, LastAccessTime, LastWriteTime: FILETIME;
begin
  Result := Read(len) and (len = SizeOf(fhandle));
  Result := Result and Read(fhandle, len);
  Result := Result and ReadNewAttr(sattr);
  Result := Result and Read(guard.check);
  Result := Result and (not guard.check or Read(guard.obj_ctime.seconds));
  Result := Result and (not guard.check or Read(guard.obj_ctime.nseconds));


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      if (not Assigned(fhandle)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(fhandle) < 0) then
        status := NFS3ERR_STALE
      else if (not ObjectHandles.GetAttr3(fhandle, OldAttr)) then
        status := GetNFSStatus(GetLastError())
      else
      begin
        Handle := CreateFileW(PWideChar(fhandle.Path),
                              GENERIC_WRITE,
                              FILE_SHARE_READ or FILE_SHARE_WRITE,
                              nil, OPEN_EXISTING, 0, 0);
        if (Handle = INVALID_HANDLE_VALUE) then
          status := GetNFSStatus(GetLastError())
        else
        begin
          status := NFS3_OK;

          if (sattr.mode.set_it) then
            status := NFS3ERR_NOTSUPP;
          if (sattr.uid.set_it) then
            status := NFS3ERR_NOTSUPP;
          if (sattr.gid.set_it) then
            status := NFS3ERR_NOTSUPP;
          if ((status = NFS3_OK) and sattr.size.set_it) then
          begin
            FileOffset.QuadPart := sattr.size.size;
            FileOffset.LowPart := SetFilePointer(Handle, FileOffset.LowPart, @FileOffset.HighPart, FILE_BEGIN);
            if ((GetLastError() <> 0) or not SetEndOfFile(Handle)) then
              status := GetNFSStatus(GetLastError())
            else if (not ObjectHandles.GetAttr3(fhandle, Handle, NewAttr)) then
              status := GetNFSStatus(GetLastError());
          end;
          if ((status = NFS3_OK) and sattr.atime.set_it) then
          begin
            if (not GetFileTime(Handle, @CreationTime, @LastAccessTime, @LastWriteTime)) then
              status := GetNFSStatus(GetLastError())
            else
            begin
              GetSystemTimeAsFileTime(LastAccessTime);
              if (not SetFileTime(Handle, @CreationTime, @LastAccessTime, @LastWriteTime)) then
                status := GetNFSStatus(GetLastError())
              else
                status := NFS3_OK;
            end;
          end;
          if ((status = NFS3_OK) and sattr.mtime.set_it) then
          begin
            if (not GetFileTime(Handle, @CreationTime, @LastAccessTime, @LastWriteTime)) then
              status := GetNFSStatus(GetLastError())
            else
            begin
              GetSystemTimeAsFileTime(LastWriteTime);
              if (not SetFileTime(Handle, @CreationTime, @LastAccessTime, @LastWriteTime)) then
                status := GetNFSStatus(GetLastError())
              else
                status := NFS3_OK;
            end;
          end;

          if (not ObjectHandles.GetAttr3(fhandle, Handle, NewAttr)) then
            status := GetNFSStatus(GetLastError());

          CloseHandle(Handle);
        end;
      end;

      Result := Write(ULONG(status));
      if (status <> NFS3_OK) then
      begin
        Result := Result and Write(False);
        Result := Result and Write(False);
      end
      else
        Result := Result and WriteWCC(OldAttr, NewAttr);
    end;
  end;
end;

function TDaemon.NFS3_Write(): Boolean;
var
  len: uint32;
  fhandle: TFileHandle;
  offset: offset3;
  count: count3;
  stable: ULONG;
  status: NFS_Stat3;
  OldAttr, NewAttr: fattr3;
  FileOffset, OldFileSize: LARGE_INTEGER;
  verf: writeverf3;
  FileOpened: Boolean;
  ChunkSize: DWord;
begin
  Result := Read(len) and (len = SizeOf(fhandle));
  Result := Result and Read(fhandle, len);
  Result := Result and Read(offset);
  Result := Result and Read(count);
  Result := Result and Read(stable);
  Result := Result and Read(count) and ((count >= FileBuffer.TotalSize) or ReallocBuffer(FileBuffer, count));
  Result := Result and Read(FileBuffer.Mem^, count);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if (Result) then
    begin
      verf := 0;

      if (not Assigned(fhandle)) then
        status := NFS3ERR_BADHANDLE
      else if (ObjectHandles.IndexOf(fhandle) < 0) then
        status := NFS3ERR_STALE
      else
      begin
        FileOpened := fhandle.WriteHandle = INVALID_HANDLE_VALUE;

        if (FileOpened) then
          fhandle.WriteHandle := CreateFileW(PWideChar(fhandle.Path),
                                             GENERIC_WRITE,
                                             FILE_SHARE_READ or FILE_SHARE_WRITE,
                                             nil, OPEN_EXISTING, 0, 0);
        if (fhandle.WriteHandle = INVALID_HANDLE_VALUE) then
          status := GetNFSStatus(GetLastError())
        else if (not ObjectHandles.GetAttr3(fhandle, fhandle.WriteHandle, OldAttr)) then
          status := GetNFSStatus(GetLastError())
        else
        begin
          OldFileSize.LowPart := GetFileSize(fhandle.WriteHandle, @OldFileSize.HighPart);

          if (GetLastError() <> 0) then
            status := GetNFSStatus(GetLastError())
          else
          begin
            FileOffset.QuadPart := offset;
            FileOffset.LowPart := SetFilePointer(fhandle.WriteHandle, FileOffset.LowPart, @FileOffset.HighPart, FILE_BEGIN);

            if (Filebuffer.TotalSize < count) then
              status := NFS3ERR_SERVERFAULT
            else if ((FileOffset.QuadPart <> offset) or not WriteFile(fhandle.WriteHandle, FileBuffer.Mem^, count, count, nil)) then
              status := GetNFSStatus(GetLastError())
            else if (not ObjectHandles.GetAttr3(fhandle, fhandle.WriteHandle, NewAttr)) then
              status := GetNFSStatus(GetLastError())
            else
            begin
              status := NFS3_OK;

              fhandle.WriteTickCount := GetTickCount();

              if (OldFileSize.QuadPart < FileOffset.QuadPart) then
              begin
                ZeroMemory(FileBuffer.Mem, FileBuffer.TotalSize);

                while (OldFileSize.QuadPart < FileOffset.QuadPart) do
                begin
                  ChunkSize := Max(FileBuffer.TotalSize, FileOffset.QuadPart - OldFileSize.QuadPart);
                  SetFilePointer(fhandle.WriteHandle, OldFileSize.LowPart, @OldFileSize.HighPart, FILE_BEGIN);
                  if ((GetLastError() <> 0) or not WriteFile(fhandle.WriteHandle, FileBuffer.Mem^, ChunkSize, ChunkSize, nil) or (ChunkSize = 0)) then
                    OldFileSize.QuadPart := FileOffset.QuadPart
                  else
                    Inc(OldFileSize.QuadPart, ChunkSize);
                end;
              end;
            end;

            if (((status <> NFS3_OK) and (fhandle.WriteHandle = INVALID_HANDLE_VALUE)) or (stable_how(stable) <> UNSTABLE)) then
              ObjectHandles.CloseWriteHandle(fhandle);
          end;

          if (fhandle.WriteHandle = INVALID_HANDLE_VALUE) then
            verf := 0
          else
            verf := fhandle.WriteHandle;
        end;
      end;

      Result := Write(status, SizeOf(status));
      if (status <> NFS3_OK) then
      begin
        Result := Result and Write(False); // Attribute follows
        Result := Result and Write(False); // Attribute follows
      end
      else
      begin
        Result := Result and WriteWCC(OldAttr, NewAttr);
        Result := Result and Write(count);
        Result := Result and Write(stable);
        Result := Result and Write(verf);
      end;
    end;
  end;
end;

function TDaemon.PMA2_Dump(): Boolean;
begin
  Result := Write(ULONG(SUCCESS));

  Result := Result and Write(True);
  Result := Result and Write(RPCB_PROG);
  Result := Result and Write(RPCB_VERS);
  Result := Result and Write(IPPROTO_TCP);
  Result := Result and Write(RPCB_PORT);

  Result := Result and Write(True);
  Result := Result and Write(RPCB_PROG);
  Result := Result and Write(RPCB_VERS);
  Result := Result and Write(IPPROTO_UDP);
  Result := Result and Write(RPCB_PORT);

  Result := Result and Write(True);
  Result := Result and Write(MOUNT_PROGRAM);
  Result := Result and Write(MOUNT_V3);
  Result := Result and Write(IPPROTO_TCP);
  Result := Result and Write(MountDaemonPort);

  Result := Result and Write(True);
  Result := Result and Write(MOUNT_PROGRAM);
  Result := Result and Write(MOUNT_V3);
  Result := Result and Write(IPPROTO_UDP);
  Result := Result and Write(MountDaemonPort);

  Result := Result and Write(True);
  Result := Result and Write(NFS_PROGRAM);
  Result := Result and Write(NFS_V3);
  Result := Result and Write(IPPROTO_TCP);
  Result := Result and Write(NFSDeamounPort);

  Result := Result and Write(True);
  Result := Result and Write(NFS_PROGRAM);
  Result := Result and Write(NFS_V3);
  Result := Result and Write(IPPROTO_UDP);
  Result := Result and Write(NFSDeamounPort);

  Result := Result and Write(False);
end;

function TDaemon.PMA2_GetPort(): Boolean;
var
  ProgramId: ULONG;
  ProgramVer: ULONG;
  Protocol: ULONG;
  Port: ULONG;
begin
  Result := Read(ProgramId);
  Result := Result and Read(ProgramVer);
  Result := Result and Read(Protocol);
  Result := Result and Read(Port);


  if (not Result) then
    Result := Write(ULONG(GARBAGE_ARGS))
  else
  begin
    Result := Write(ULONG(SUCCESS));

    if ((ProgramId = RPCB_PROG) and (ProgramVer = RPCB_VERS)) then
      Result := Result and Write(ULONG(RPCB_PORT))
    else if ((ProgramId = MOUNT_PROGRAM) and (ProgramVer = MOUNT_V3)) then
      Result := Result and Write(ULONG(MountDaemonPort))
    else if ((ProgramId = NFS_PROGRAM) and (ProgramVer = NFS_V3)) then
      Result := Result and Write(ULONG(NFSDeamounPort))
    else
      Result := Result and Write(ULONG(0)); // Unknown
  end;
end;

function TDaemon.PMA2_GetTime(): Boolean;
var
  SystemTime: FILETIME;
begin
  Result := Write(ULONG(SUCCESS));

  GetSystemTimeAsFileTime(SystemTime);
  Result := Result and Write(FILETIMETonfstime3(SystemTime).seconds);
end;

function TDaemon.PMA2_Null(): Boolean;
begin
  Result := Write(ULONG(SUCCESS));
end;

function TDaemon.Read(var Value: Boolean): Boolean;
var
  ul: ULONG;
begin
  Result := Read(ul, SizeOf(ul));

  if (Result) then
    Value := ntohl(ul) <> 0;
end;

function TDaemon.Read(var Value: ULONG): Boolean;
begin
  Result := Read(Value, SizeOf(Value));

  if (Result) then
    Value := ntohl(Value);
end;

function TDaemon.Read(var Value: LONGLONG): Boolean;
begin
  Result := Read(Value, SizeOf(Value));

  if (Result) then
    Value := ntohll(Value);
end;

function TDaemon.Read(var Data; const BytesToRead: ULONG): Boolean;
var
  FragmentHeader: ULONG;
  PacketSize, SocketSize: Cardinal;
  Len, Size: u_int;
  Retry: Boolean;
begin
  Result := True;

  if (ReadBuffer.Size = 0) then
    if (Protocol = IPPROTO_TCP) then
    begin
      Len := recv(Socket, FragmentHeader, SizeOf(FragmentHeader), 0);
      Result := (Len <> SOCKET_ERROR) and (Len >= 4);
      if (Result) then
      begin
        FragmentHeader := ntohl(FragmentHeader);
        PacketSize := Min(FragmentHeader and $7FFFFFFF, MaxPacketSize);
        Result := (FragmentHeader shr 31 <> 0) and (4 + PacketSize <= MaxPacketSize);

        Size := SizeOf(PacketSize);
        Result := Result and (getsockopt(Socket, SOL_SOCKET, SO_RCVBUF, @SocketSize, Size) <> SOCKET_ERROR);
        if (Result and (PacketSize > SocketSize)) then
          Result := setsockopt(Socket, SOL_SOCKET, SO_RCVBUF, @PacketSize, SizeOf(PacketSize)) <> SOCKET_ERROR;

        if (Result and (PacketSize > ReadBuffer.TotalSize)) then
        begin
          ReallocMem(ReadBuffer.Mem, PacketSize);
          ReadBuffer.TotalSize := PacketSize;
        end;

        while (Result and (ReadBuffer.Size < PacketSize)) do
        begin
          Len := recv(Socket, ReadBuffer.Mem[ReadBuffer.Size], PacketSize - ReadBuffer.Size, 0);
          Result := Len <> SOCKET_ERROR;
          if (Result) then
            Inc(ReadBuffer.Size, Len);
        end;
      end;
    end
    else
    repeat
      Retry := False;

      PacketSize := ReadBuffer.TotalSize;
      Size := SizeOf(PacketSize);
      Result := getsockopt(Socket, SOL_SOCKET, SO_RCVBUF, @SocketSize, Size) <> SOCKET_ERROR;
      if (Result and (PacketSize > SocketSize)) then
        Result := setsockopt(Socket, SOL_SOCKET, SO_RCVBUF, @PacketSize, SizeOf(PacketSize)) <> SOCKET_ERROR;

      if (Result) then
      begin
        Size := SizeOf(RemoteAddr);
        Len := recvfrom(Socket, ReadBuffer.Mem[ReadBuffer.Size], PacketSize, 0, RemoteAddr, Size);
        Result := Len <> SOCKET_ERROR;
        if (Result) then
          Inc(ReadBuffer.Size, Len)
        else if ((WSAGetLastError() = WSAEMSGSIZE) and (2 * ReadBuffer.TotalSize <= MaxPacketSize)) then
          Retry := ReallocBuffer(ReadBuffer, 2 * ReadBuffer.TotalSize, MinPacketSize);
      end;
    until (Result or not Retry);

  Result := Result and (ReadBuffer.Offset + BytesToRead <= ReadBuffer.Size);

  if (Result) then
  begin
    MoveMemory(@Data, @ReadBuffer.Mem[ReadBuffer.Offset], BytesToRead);
    Inc(ReadBuffer.Offset, (BytesToRead + 3) div 4 * 4);
  end;
end;

function TDaemon.ReadNewAttr(out NewAttr: sattr3): Boolean;
begin
  ZeroMemory(@NewAttr, SizeOf(NewAttr));
  Result := Read(NewAttr.mode.set_it);
  Result := Result and (not NewAttr.mode.set_it or Read(NewAttr.mode.mode));
  Result := Result and Read(NewAttr.uid.set_it);
  Result := Result and (not NewAttr.uid.set_it or Read(NewAttr.uid.uid));
  Result := Result and Read(NewAttr.gid.set_it);
  Result := Result and (not NewAttr.gid.set_it or Read(NewAttr.gid.gid));
  Result := Result and Read(NewAttr.size.set_it);
  Result := Result and (not NewAttr.size.set_it or Read(NewAttr.size.size));
  Result := Result and Read(NewAttr.atime.set_it);
  Result := Result and Read(NewAttr.mtime.set_it);
end;

function TDaemon.Write(var Data; const BytesToWrite: ULONG): Boolean;
var
  NewTotalSize: ULONG;
begin
  NewTotalSize := Min(MaxPacketSize, WriteBuffer.Size + BytesToWrite);
  if (NewTotalSize > WriteBuffer.TotalSize) then
    ReallocBuffer(WriteBuffer, NewTotalSize, MinPacketSize);

  Result := (WriteBuffer.Size + BytesToWrite <= WriteBuffer.TotalSize);

  if (Result) then
  begin
    MoveMemory(@WriteBuffer.Mem[WriteBuffer.Size], @Data, BytesToWrite);
    Inc(WriteBuffer.Size, BytesToWrite);

    if (BytesToWrite mod 4) > 0 then
    begin
      ZeroMemory(@WriteBuffer.Mem[WriteBuffer.Size], 4 - (BytesToWrite mod 4));
      Inc(WriteBuffer.Size, 4 - (BytesToWrite mod 4));
    end;
  end;
end;

function TDaemon.Write(const Value: Boolean): Boolean;
var
  B: ULONG;
begin
  if (not Value) then
    B := htonl(ULONG(0))
  else
    B := htonl(ULONG(1));
  Result := Write(B, SizeOf(B));
end;

function TDaemon.Write(Value: ULONG): Boolean;
begin
  Value := htonl(Value);
  Result := Write(Value, SizeOf(Value));
end;

function TDaemon.Write(Value: LONGLONG): Boolean;
begin
  Value := htonll(Value);
  Result := Write(Value, SizeOf(Value));
end;

function TDaemon.WriteWCC(const OldAttr, NewAttr: fattr3): Boolean;
var
  Attr: fattr3;
begin
  MoveMemory(@Attr, @NewAttr, SizeOf(Attr));

  Result := Write(True); // Attribute follows
  Result := Result and Write(ntohll(OldAttr.size));  // OldAttr is Net-coded already
  Result := Result and Write(ntohl(OldAttr.mtime.seconds));
  Result := Result and Write(ntohl(OldAttr.mtime.nseconds));
  Result := Result and Write(ntohl(OldAttr.ctime.seconds));
  Result := Result and Write(ntohl(OldAttr.ctime.nseconds));
  Result := Result and Write(True); // Attribute follows
  Result := Result and Write(Attr, SizeOf(Attr));
end;

initialization
  Daemon := nil;
  if (WSAStartup($0101, WSAData) <> 0) then
    WSAData.wVersion := 0;
finalization
  if (WSAData.wVersion <> 0) then
    WSACleanup();
end.

