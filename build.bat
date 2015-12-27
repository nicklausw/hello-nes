@echo off

echo asm6...
asm6 asm6\asm6.s asm6\asm6.nes

echo ---
echo ca65...
ca65 -o ca65\ca65.o ca65\ca65.s
ld65 -C ca65\nes.cfg -o ca65\ca65.nes ca65\ca65.o

echo ---
echo nesasm...
nesasm3 -o nesasm\nesasm.nes nesasm\nesasm.s

echo ---
echo wla-dx...
wla-6502 -o wla-dx\wla-dx.s wla-dx\wla-dx.o
echo [objects] >wla-dx\linkfile
echo wla-dx\wla-dx.o >>wla-dx\linkfile
wlalink wla-dx\linkfile wla-dx\wla-dx.nes

pause
