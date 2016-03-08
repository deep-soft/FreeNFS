### FreeNFS
FreeNFS is a NFS Server for Windows (NFSv3)

### Todo
- Fix windows support (GID/UID -2 issue)
- Finalize MOUNT V3 EXPORT changes
- Fix linux support (done?)

### How to
For Linux:
```
mount -v -t nfs -o nfsvers=3,vers=3,proto=tcp,sec=none,timeo=20,soft,intr [ip.addr]:/ /mnt/dest
```
For Windows:
```
mount -o anon -o fileaccess=666 [ip.addr]:/! X:
```
