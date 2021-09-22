TARGET = main
OUTPUT = txtadv
ROOT = ../common
COMMON_ASM = $(ROOT)/string.asm $(ROOT)/functions.asm $(ROOT)/math.asm $(ROOT)/struct_array.asm
COMMON_OBJ = $(ROOT)/string.o $(ROOT)/functions.o $(ROOT)/math.o $(ROOT)/struct_array.o

default : $(TARGET).o $(COMMON_OBJ)
	gcc $(TARGET).o $(COMMON_OBJ) -o $(OUTPUT) -e main -fverbose-asm -no-pie

$(TARGET).o : $(TARGET).asm $(ROOT)/macros.asm
	nasm -f elf64 -g -F dwarf $(TARGET).asm

$(ROOT)/string.o : $(ROOT)/string.asm $(ROOT)/macros.asm
	nasm -f elf64 -g -F dwarf $(ROOT)/string.asm

$(ROOT)/functions.o : $(ROOT)/functions.asm $(ROOT)/macros.asm
	nasm -f elf64 -g -F dwarf $(ROOT)/functions.asm

$(ROOT)/math.o : $(ROOT)/math.asm $(ROOT)/macros.asm
	nasm -f elf64 -g -F dwarf $(ROOT)/math.asm

$(ROOT)/struct_array.o : $(ROOT)/struct_array.asm $(ROOT)/macros.asm
	nasm -f elf64 -g -F dwarf $(ROOT)/struct_array.asm

clean :
	rm $(TARGET).o $(TARGET) $(COMMON_OBJ)

run :
	./$(TARGET)

debug :
	gdb $(TARGET)
