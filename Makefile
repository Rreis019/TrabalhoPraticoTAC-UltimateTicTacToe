# Variáveis
C = ml
CodeFolder = C:\8086\CODIGO
ASM_FILES = $(wildcard *.asm)
OBJ_FILES = $(patsubst %.asm, %.obj, $(ASM_FILES))
OUTPUT_FILE = main.exe

all: $(wildcard *.asm)
	copy *.asm C:\8086\CODIGO
	dosbox -c "ml $(ASM_FILES)" -c "link $(OBJ_FILES);" -c "$(OUTPUT_FILE)"