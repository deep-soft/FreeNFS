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

Unit RPCConsts;

Interface

Const
  NFS3_FHSIZE         = 64; {* The maximum size in bytes of the opaque file handle *}
  NFS3_COOKIEVERFSIZE =  8; {* The size in bytes of the opaque cookie verifier     *}
  NFS3_CREATEVERFSIZE =  8; {* The size in bytes of the opaque verifier            *}
  NFS3_WRITEVERFSIZE  =  8; {* The size in bytes of the opaque verifier            *}

Type
  uint64      = System.Int64;
  int64       = System.Int64;
  uint32      = Longword;
  int32       = Longint;
  filename3   = PAnsiChar;
  nfspath3    = PAnsiChar;
  fileid3     = uint64;         {* unsigned 64 bit integer                         *}
  cookie3     = uint64;         {* unsigned 64 bit integer                         *}
  cookieverf3 = uint64;         {* unsigned 64 bit integer                         *}
  createverf3 = uint64;         {* unsigned 64 bit integer                         *}
  writeverf3  = uint64;         {* unsigned 64 bit integer                         *}
  uid3        = uint32;         {* unsigned 64 bit integer                         *}
  gid3        = uint32;         {* unsigned 64 bit integer                         *}
  size3       = uint64;         {* unsigned 64 bit integer                         *}
  offset3     = uint64;         {* unsigned 64 bit integer                         *}
  mode3       = uint32;         {* unsigned 64 bit integer                         *}
  count3      = uint32;         {* unsigned 64 bit integer                         *}

  NFSPROC3 = (
    NFSPROC3_NULL        = 0,
    NFSPROC3_GETATTR     = 1,
    NFSPROC3_SETATTR     = 2,
    NFSPROC3_LOOKUP      = 3,
    NFSPROC3_ACCESS      = 4,
    NFSPROC3_READLINK    = 5,
    NFSPROC3_READ        = 6,
    NFSPROC3_WRITE       = 7,
    NFSPROC3_CREATE      = 8,
    NFSPROC3_MKDIR       = 9,
    NFSPROC3_SYMLINK     = 10,
    NFSPROC3_MKNOD       = 11,
    NFSPROC3_REMOVE      = 12,
    NFSPROC3_RMDIR       = 13,
    NFSPROC3_RENAME      = 14,
    NFSPROC3_LINK        = 15,
    NFSPROC3_READDIR     = 16,
    NFSPROC3_READDIRPLUS = 17,
    NFSPROC3_FSSTAT      = 18,
    NFSPROC3_FSINFO      = 19,
    NFSPROC3_PATHCONF    = 20,
    NFSPROC3_COMMIT      = 21
  );

  NFS_Stat3 = (
    NFS3_OK             = 0,     {* Success                                        *}
    NFS3ERR_PERM        = 1,     {* Not owner                                      *}
    NFS3ERR_NOENT       = 2,     {* No such file or directory                      *}
    NFS3ERR_IO          = 5,     {* I/O error. A hard error (for example, a disk   *}
                                 {* error)                                         *}
    NFS3ERR_NXIO        = 6,     {* I/O error. No such device or address           *}
    NFS3ERR_ACCES       = 13,    {* Permission denied                              *}
    NFS3ERR_EXIST       = 17,    {* File exists                                    *}
    NFS3ERR_XDEV        = 18,    {* Attempt to do a cross-device hard link         *}
    NFS3ERR_NODEV       = 19,    {* No such device                                 *}
    NFS3ERR_NOTDIR      = 20,    {* Not a directory                                *}
    NFS3ERR_ISDIR       = 21,    {* Is a directory                                 *}
    NFS3ERR_INVAL       = 22,    {* Invalid argument or unsupported argument       *}
    NFS3ERR_FBIG        = 27,    {* File too large                                 *}
    NFS3ERR_NOSPC       = 28,    {* No space left on device                        *}
    NFS3ERR_ROFS        = 30,    {* Read-only file system                          *}
    NFS3ERR_MLINK       = 31,    {* Too many hard links                            *}
    NFS3ERR_NAMETOOLONG = 63,    {* The filename in an operation was too long      *}
    NFS3ERR_NOTEMPTY    = 66,    {* An attempt was made to remove a directory that *}
                                 {* was not empty                                  *}
    NFS3ERR_DQUOT       = 69,    {* Resource (quota) hard limit exceeded           *}
    NFS3ERR_STALE       = 70,    {* Invalid file handle                            *}
    NFS3ERR_REMOTE      = 71,    {* Too many levels of remote in path              *}
    NFS3ERR_BADHANDLE   = 10001, {* Illegal NFS file handle                        *}
    NFS3ERR_NOT_SYNC    = 10002, {* Update synchronization mismatch                *}
    NFS3ERR_BAD_COOKIE  = 10003, {* READDIR or READDIRPLUS cookie is stale         *}
    NFS3ERR_NOTSUPP     = 10004, {* Operation is not supported                     *}
    NFS3ERR_TOOSMALL    = 10005, {* Buffer or request is too small                 *}
    NFS3ERR_SERVERFAULT = 10006, {* An error occurred on the server                *}
    NFS3ERR_BADTYPE     = 10007, {* An attempt was made to create an object of a   *}
                                 {* type not supported                             *}
    NFS3ERR_JUKEBOX     = 10008  {* The server initiated the request, but was not  *}
                                 {* able to complete it in a timely fashion        *}
  );

  ftype3 = (
    NF3REG    = 1,
    NF3DIR    = 2,
    NF3BLK    = 3,
    NF3CHR    = 4,
    NF3LNK    = 5,
    NF3SOCK   = 6,
    NF3FIFO   = 7
  );

  stable_how = (
    UNSTABLE  = 0,
    DATA_SYNC = 1,
    FILE_SYNC = 2
  );

  createmode3 = (
    UNCHECKED = 0,
    GUARDED   = 1,
    EXCLUSIVE = 2
  );

  Spec_Data3 = packed record
    Spec_Data1: uint32;
    Spec_Data2: uint32;
  end;

  nfstime3 = packed record
    seconds : uint32;
    nseconds: uint32;
  end;

  fattr3 = packed record
    ftype : uint32;
    mode  : mode3;
    nlink : uint32;
    uid   : uid3;
    gid   : gid3;
    size  : size3;
    used  : size3;
    rdev  : Spec_Data3;
    fsid  : uint64;
    fileid: fileid3;
    atime : nfstime3;
    mtime : nfstime3;
    ctime : nfstime3;
  end;

  sattr3 = record
    mode: record
      set_it: Boolean;
      mode: mode3;
    end;
    uid: record
      set_it: Boolean;
      uid: uid3;
    end;
    gid: record
      set_it: Boolean;
      gid: gid3;
    end;
    size: record
      set_it: Boolean;
      size: size3;
    end;
    atime: record
      set_it: Boolean;
    end;
    mtime: record
      set_it: Boolean;
    end;
  end;

  sattrguard3 = record
    check    : Boolean;
    obj_ctime: nfstime3;
  end;


Const
  NFS_PROGRAM = 100003;     {* NFS program                                         *}
  NFS_V3 = 3;               {* NFS program version                                 *}
  ACCESS3_READ    = $0001;
  ACCESS3_LOOKUP  = $0002;
  ACCESS3_MODIFY  = $0004;
  ACCESS3_EXTEND  = $0008;
  ACCESS3_DELETE  = $0010;
  ACCESS3_EXECUTE = $0020;
  FSF_LINK        = $0001;
  FSF_SYMLINK     = $0002;
  FSF_HOMOGENEOUS = $0008;
  FSF_CANSETTIME  = $0010;

{ Mount ***********************************************************************}

Const
  MNTPATHLEN = 1024;             {* Maximum bytes in a path name                   *}
  MNTNAMLEN  = 255;              {* Maximum bytes in a name                        *}

Type
  exportpath = array[0..MNTPATHLEN-1] of AnsiChar;

  MOUNTPROC3 = (
    MOUNTPROC3_NULL    = 0,
    MOUNTPROC3_MNT     = 1,
    MOUNTPROC3_DUMP    = 2,
    MOUNTPROC3_UMNT    = 3,
    MOUNTPROC3_UMNTALL = 4,
    MOUNTPROC3_EXPORT  = 5
  );

  mountstat3 = (
    MNT3_OK             = 0,     {* no error                                       *}
    MNT3ERR_PERM        = 1,     {* Not owner                                      *}
    MNT3ERR_NOENT       = 2,     {* No such file or directory                      *}
    MNT3ERR_IO          = 5,     {* I/O error                                      *}
    MNT3ERR_ACCES       = 13,    {* Permission denied                              *}
    MNT3ERR_NOTDIR      = 20,    {* Not a directory                                *}
    MNT3ERR_INVAL       = 22,    {* Invalid argument                               *}
    MNT3ERR_NAMETOOLONG = 63,    {* Filename too long                              *}
    MNT3ERR_NOTSUPP     = 10004, {* Operation not supported                        *}
    MNT3ERR_SERVERFAULT = 10006  {* A failure on the server                        *}
  );

Const
  MOUNT_PROGRAM = 100005;   {* Mount program                                       *}
  MOUNT_V3 = 3;             {* Mount program version                               *}

{ Port mapper                                                                      *}

Type
  RPCBPROC = (
    RPCBPROC_NULL        = 0,
    RPCBPROC_SET         = 1,
    RPCBPROC_UNSET       = 2,
    RPCBPROC_GETPORT     = 3,
    RPCBPROC_DUMP        = 4,
    RPCBPROC_CALLIT      = 5,
    RPCBPROC_GETTIME     = 6,
    RPCBPROC_UADDR2TADDR = 7,
    RPCBPROC_TADDR2UADDR = 8
  );

const
  RPCB_PROG = 100000;       {* portmapper program                                  *}
  RPCB_VERS = 2;            {* portmapper program version                          *}
  RPCB_PORT = 111;          {* portmapper port number                              *}

{ Remote Procedure Call *******************************************************}

type
  msg_type = (
    CALL  = 0,
    REPLY = 1
  );

  reply_stat = (
    MSG_ACCEPTED = 0,
    MSG_DENIED   = 1
  );

  accept_stat = (
    SUCCESS       = 0,      {* RPC executed successfully                           *}
    PROG_UNAVAIL  = 1,      {* remote hasn't exported program                      *}
    PROG_MISMATCH = 2,      {* remote can't support version #                      *}
    PROC_UNAVAIL  = 3,      {* program can't support procedure                     *}
    GARBAGE_ARGS  = 4,      {* procedure can't decode params                       *}
    SYSTEM_ERR    = 5       {* errors like memory allocation failure               *}
  );

  reject_stat = (
    RPC_MISMATCH  = 0,      {* RPC version number != 2                             *}
    AUTH_ERROR    = 1       {* remote can't authenticate caller                    *}
  );

  AUTH = (
    AUTH_NONE  = 0,         {* no authentication                                   *}
    AUTH_SYS   = 1,         {* unix style (uid, gids)                              *}
    AUTH_UNIX  = AUTH_SYS,
    AUTH_SHORT = 2,         {* short hand unix style                               *}
    AUTH_DH    = 3,         {* for Diffie-Hellman mechanism                        *}
    AUTH_KERB  = 4          {* kerberos style                                      *}
  );

  auth_stat = (
    AUTH_OK           = 0,  {* success                                             *}
    {* failed remotely                                                             *}
    AUTH_BADCRED      = 1,  {* bad credential (seal broken)                        *}
    AUTH_REJECTEDCRED = 2,  {* client must begin new session                       *}
    AUTH_BADVERF      = 3,  {* bad verifier (seal broken)                          *}
    AUTH_REJECTEDVERF = 4,  {* verifier expired or replayed                        *}
    AUTH_TOOWEAK      = 5,  {* rejected for security reasons                       *}
    {* failed locally                                                              *}
    AUTH_INVALIDRESP  = 6,  {* bogus response verifier                             *}
    AUTH_FAILED       = 7   {* reason unknown                                      *}
  );

const
  RPCBVERS = 2;

implementation {***************************************************************}

end.

