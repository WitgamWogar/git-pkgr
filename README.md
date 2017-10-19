# git-pkgr
Packages git files and creates a bash script to unpack changed files into their respective directories.
This is useful for things like sending only changed files to clients that do not use git, or uploading via FTP.

#### Install for Global Use
```
cp git-pkg.sh /usr/local/bin/git-pkg
chmod +x /usr/local/bin/git-pkg
```

#### Usage
```
git-pkg [output path] [from commit] [to commit]
```
