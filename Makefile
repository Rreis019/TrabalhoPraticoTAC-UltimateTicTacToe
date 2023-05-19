# Variáveis
C = ml
CodeFolder = C:\8086\CODIGO
ASM_FILES = $(wildcard *.asm)
OBJ_FILES = $(patsubst %.asm, %.obj, $(ASM_FILES))
OUTPUT_FILE = GAME.exe

all: $(wildcard *.asm)
	copy *.asm C:\8086\CODIGO
	del C:\8086\CODIGO\$(OUTPUT_FILE)
	dosbox -c "ml $(ASM_FILES) /Fe$(OUTPUT_FILE)" -c "$(OUTPUT_FILE)"
