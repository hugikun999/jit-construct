BIN = interpreter \
      compiler-x86 compiler-x64 compiler-arm \
      jit-x86 jit-x64 jit-arm

CROSS_COMPILE = arm-linux-gnueabihf-
QEMU_ARM = qemu-arm -L /usr/arm-linux-gnueabihf
LUA = lua
SHELL = /bin/bash

all: $(BIN)

CFLAGS = -Wall -Werror -std=gnu99 -I.

interpreter: interpreter.c
	$(CC) $(CFLAGS) -o $@ $^

compiler-x86: compiler-x86.c
	$(CC) $(CFLAGS) -o $@ $^

compiler-x64: compiler-x64.c
	$(CC) $(CFLAGS) -o $@ $^

compiler-arm: compiler-arm.c
	$(CC) $(CFLAGS) -o $@ $^

run-compiler: compiler-x86 compiler-x64 compiler-arm
	./compiler-x86 progs/hello.b > hello.s
	$(CC) -m32 -o hello-x86 hello.s
	@echo 'x86: ' `./hello-x86`
	@echo
	./compiler-x64 progs/hello.b > hello.s
	$(CC) -o hello-x64 hello.s
	@echo 'x64: ' `./hello-x64`
	@echo
	./compiler-arm progs/hello.b > hello.s
	$(CROSS_COMPILE)gcc -o hello-arm hello.s
	@echo 'arm: ' `$(QEMU_ARM) hello-arm`
	@echo

jit0-x64: tests/jit0-x64.c
	$(CC) $(CFLAGS) -o $@ $^

jit-x86: dynasm-driver.c jit-x86.h
	$(CC) $(CFLAGS) -o $@ -DJIT=\"jit-x86.h\" \
		dynasm-driver.c -m32
jit-x86.h: jit-x86.dasc
	        $(LUA) dynasm/dynasm.lua -o $@ jit-x86.dasc
run-jit-x86: jit-x86
	./jit-x86 progs/hello.b && objdump -D -b binary \
		-mi386 -Mx86 /tmp/jitcode

jit-x64: dynasm-driver.c jit-x64.h
	$(CC) $(CFLAGS) -o $@ -DJIT=\"jit-x64.h\" \
		dynasm-driver.c
jit-x64.h: jit-x64.dasc
	        $(LUA) dynasm/dynasm.lua -o $@ jit-x64.dasc
run-jit-x64: jit-x64
	./jit-x64 progs/hello.b && objdump -D -b binary \
		-mi386 -Mx86-64 /tmp/jitcode

jit0-arm: tests/jit0-arm.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -o $@ $^

jit-arm: dynasm-driver.c jit-arm.h
	$(CROSS_COMPILE)gcc $(CFLAGS) -o $@ -DJIT=\"jit-arm.h\" \
		dynasm-driver.c
jit-arm.h: jit-arm.dasc
	$(LUA) dynasm/dynasm.lua -o $@ jit-arm.dasc
run-jit-arm: jit-arm
	$(QEMU_ARM) jit-arm progs/hello.b && \
	$(CROSS_COMPILE)objdump -D -b binary -marm /tmp/jitcode

bench-jit-x86: jit-x86
	@echo
	@echo Executing Brainf*ck benchmark suite. Be patient.
	@echo
	@env PATH='.:${PATH}' BF_RUN='$<' tests/bench.py

bench-jit-x64: jit-x64
	@echo
	@echo Executing Brainf*ck benchmark suite. Be patient.
	@echo
	@env PATH='.:${PATH}' BF_RUN='$<' tests/bench.py

test: test_stack jit0-x64 jit0-arm
	./test_stack
	(./jit0-x64 42 ; echo $$?)
	($(QEMU_ARM) jit0-arm 42 ; echo $$?)

test_stack: tests/test_stack.c
	$(CC) $(CFLAGS) -o $@ $^


TEMP = temp_file
VERSION = orig
x86-bench-%:
	touch $(TEMP)
	make bench-jit-x64 > $(TEMP)
	{ echo -n "$* " && grep GOOD $(TEMP) | grep  awib;} >> data/awib.txt
	{ echo -n "$* " && grep GOOD $(TEMP) | grep  man ;} >> data/mandelbrot.txt
	{ echo -n "$* " && grep GOOD $(TEMP) | grep  hanoi; } >> data/hanoi.txt
	rm $(TEMP)

x86-bench:
	cp jit-x86.dasc.orig jit-x86.dasc
	make
	make x86-bench-orig
	cp jit-x86.dasc.con jit-x86.dasc
	make
	make x86-bench-contraction
	cp jit-x86.dasc.rel jit-x86.dasc
	make
	make x86-bench-reduceloop
	cp jit-x86.dasc.opt jit-x86.dasc
	make
	make x86-bench-optimization

plot:
	gnuplot data/awib.gp
	eog comparison_awib.png
	gnuplot data/mandelbrot.gp
	gnuplot data/hanoi.gp



clean:
	$(RM) $(BIN) \
	      hello-x86 hello-x64 hello-arm hello.s \
	      test_stack jit0-x64 jit0-arm \
	      jit-x86.h jit-x64.h jit-arm.h\
		  data/awib.txt data/mandelbrot.txt data/hanoi.txt
