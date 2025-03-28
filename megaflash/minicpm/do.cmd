@echo off
rem vp 16.08.2009

rem cpmls -f z9001 disk1.dum
rem cpmcp -f z9001 disk1.dum 0:*.* disk1
rem cpmcp -f z9001 disk2.dum 0:*.* disk2


rem Disketten zusammenstellen
rem es werden die CPMTOOLS für Windows (cygwin) genutzt.

set perl=%1

for %%i in (diskvp1 diskvp2) do (

	echo %%i

	%perl% leerdisk.pl %%i.dmp
	copy diskdefs %%i > nul
	cd %%i
	for %%f in (*.*) do (
		if not %%f==diskdefs (
			echo %%f
			..\cpmcp -f z9001 ..\%%i.dmp %%f 0:
		)
	)
	cd ..
)

%perl% mkdisksize.pl diskvp2.dmp

for %%i in (diskvp3) do (

	echo %%i

	%perl% leerdisk.pl %%i.dmp 64
	copy diskdefs %%i > nul
	cd %%i
	for %%f in (*.*) do (
		if not %%f==diskdefs (
			echo %%f
			..\cpmcp -f minicpm ..\%%i.dmp %%f 0:
		)
	)
	cd ..
)
