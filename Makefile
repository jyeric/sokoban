.PHONY: run all clean rebuild

all: build/game.gb

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