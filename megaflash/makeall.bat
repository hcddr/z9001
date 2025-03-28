rem alle ROMs erstellen

rem del *.bin
make depend

rem KOMBI
type includes_kombi.asm > includes.asm
make all 
make all 
make all kombi

rem MEGA
type includes_mega.asm > includes.asm
make all 
make all 
make all mega FLASH
