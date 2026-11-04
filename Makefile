ASM=pasmo
SRC=src/main.asm
BUILD=build
TAP=build/forthzx.tap
AFLAGS=--tapbas --alocal

.PHONY: all clean

all: $(TAP)

$(TAP): $(SRC) $(wildcard src/*.asm)
	mkdir -p $(BUILD)
	cd src && $(ASM) $(AFLAGS) main.asm ../$(TAP)

clean:
	rm -rf $(TAP)
