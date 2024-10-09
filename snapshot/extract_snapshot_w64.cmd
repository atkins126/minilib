echo off

set d=%DATE:~-4%-%DATE:~4,2%-%DATE:~7,2%
cd %d%

7z x fpc-3.3.1.x86_64-win64.built.on.x86_64-linux.tar.gz -so | 7z x -si -ttar -o.\fpc\

move /Y .\fpc\bin\*.* .\fpc\bin\x86_64-win64

7z x fpc.zip -o*
rename .\fpc\fpc src

7z x fpcbuild.zip -o.\fpc\ -y

copy .\fpc\fpcbuild\install\binw64\*.* .\fpc\bin\x86_64-win64

copy ..\makecfg.cmd .\fpc\bin\x86_64-win64