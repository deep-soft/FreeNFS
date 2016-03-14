### FreeNFS
FreeNFS is a NFS Server for Windows (NFSv3)

### Todo
- Provide hack for windows support? (GID/UID -2 issue)
- Actually follow NFSv3 RFC 1813

### How to
For Linux:
```
mount -v -t nfs -o nfsvers=3,vers=3,proto=tcp,sec=none,timeo=20,soft,intr [ip.addr]:/ /mnt/dest
```
For Windows:
If you try to mount it will work but you can't access files because windows uses -2 as the default GID/UID. There is a registry fix where you add AnonymousGID/UID = 0. See this link:
See: https://support.dbssolutions.com/support/solutions/articles/1649-windows-7-client-for-nfs-and-user-name-mapping-without-ad-sua
```
mount -o anon -o fileaccess=666 [ip.addr]:/! X:
```
