@echo off
rem JKCEMU-Basiccompiler aufrufen


rem set jkcemu=..\jkcemu-0.9.3.jar
set jkcemu=..\jkcemu-0.9.4.jar
set jkcemu=..\jkcemu-0.9.7.jar

set source=sysinfo_2.3.bas

rem Version ausgeben
java -jar %jkcemu% -v

echo Assembler-Src erzeugen
java -jar %jkcemu% --bc -S -L DE -B0 -O3 -t Z9001 -A 300 -N SYSINFO -o sysinfo.asm %source%

echo TAP erzeugen
java -jar %jkcemu% --bc -L DE -B0 -O3 -t Z9001 -A 300 -N SYSINFO -o sysinfo.tap %source%
