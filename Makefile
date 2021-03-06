all: image check

image: test/make-image.fth forth/asm.fth
	echo include $< | forth

kernel: forth/compiler.fth
	echo include $< | forth

check: test-asm test-cpu test-verilog test-verilator

test-cpu: image forth/nybble.fth
	echo include forth/nybble.fth  load $<  hex start | forth > $@
	grep "FF undefined" $@

test-asm: test/test-asm.fth forth/asm.fth
	echo include $< | forth > $@
	grep "Assembler test: PASS" $@

nybble: verilog/cpu.v
	iverilog -o $@ $^

image.hex: image
	hexdump -ve '1/1 "%02x "' < $< > $@

bench: test/cpu_tb.v verilog/cpu.v image.hex
	iverilog -Wall -o $@ $<

test-verilog: bench
	vvp $< > $@
	grep "ff undefined" $@

obj_dir/Vcpu.cpp: verilog/cpu.v test/sim.cpp
	verilator -Wall -Wno-fatal --cc --trace $< --top-module cpu --exe test/sim.cpp

obj_dir/Vcpu: obj_dir/Vcpu.cpp
	$(MAKE) -C obj_dir -f Vcpu.mk Vcpu

test-verilator: obj_dir/Vcpu image.hex
	$< > $@
	grep "ff undefined" $@

clean:
	rm -rf *.hex *.vcd test-* image nybble bench obj_dir
