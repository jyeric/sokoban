.PHONY: run all clean rebuild debug

all: build/game.gb build/debug.gb

data.asm: levels.txt data.nolevels.asm level2asm.py
	python3 level2asm.py > data.asm

build/debug.gb: main.asm data.asm hardware.inc | build
	rgbasm -Weverything -E -o build/debug.o main.asm
	rgblink -n build/debug.sym -m build/debug.map -o build/debug.gb build/debug.o
	rgbfix -v -p 0xFF build/debug.gb

debug: build/debug.gb
ifeq ($(OS),Windows_NT)
	cmd /c start build\debug.gb
else
	xdg-open build/debug.gb
endif

build:
	mkdir build

# assemble
build/main.o: main.asm data.asm hardware.inc | build
	rgbasm -o $@ $<

# link and fix
build/game.gb: build/main.o
	rgblink -o $@ $<
	rgbfix -v -p 0xFF $@

run: build/game.gb
ifeq ($(OS),Windows_NT)
	cmd /c start build\game.gb
else
	xdg-open build/game.gb
endif

clean:
ifeq ($(OS),Windows_NT)
	cmd /c if exist build rd /s /q build
else
	rm -rf build
endif

rebuild: clean all