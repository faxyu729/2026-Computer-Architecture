# CP2 BITREV — RV32IM 實作的重現腳本
#
#   make asm     組譯成 .o（riscv64-elf-gcc, -march=rv32im -mabi=ilp32）
#   make dis     反組譯
#   make count   統計 bitrev 函式的指令數與分支數
#   make run     用 Ripes 執行 11 組測資並輸出指令數／cycle 數
#   make clean   清除 build/

CC      = riscv64-elf-gcc
OBJDUMP = riscv64-elf-objdump
RIPES   ?= /Applications/Ripes-v2.3.0-mac-universal2.app/Contents/MacOS/Ripes
PROC    ?= RV32_5S
BUILD   = build
TARGET  = $(BUILD)/bitrev.o

# bitrev 函式（含內部標籤）的反組譯區段
FUNC = $(OBJDUMP) -d $(TARGET) | sed -n '/<bitrev>:/,/<test_main>:/p' \
       | grep -E '^[[:space:]]+[0-9a-f]+:'

.PHONY: all asm dis count run clean

all: count run

asm: $(TARGET)

$(TARGET): bitrev.S
	mkdir -p $(BUILD)
	$(CC) -march=rv32im -mabi=ilp32 -c $< -o $@

dis: $(TARGET)
	$(OBJDUMP) -d $(TARGET)

count: $(TARGET)
	@echo "=== bitrev 函式指令數（不含 ret）==="
	@$(FUNC) | grep -cv 'ret$$' || true
	@echo "=== bitrev 函式指令數（含 ret）==="
	@$(FUNC) | grep -c ':' || true
	@echo "=== bitrev 函式分支指令數 ==="
	@$(FUNC) | grep -Ec '[[:space:]](b(eq|ne|lt|ge|ltu|geu)|j)[[:space:]]' || true
	@echo "=== 整個 .text 指令數 ==="
	@$(OBJDUMP) -d $(TARGET) | grep -Ec '^[[:space:]]+[0-9a-f]+:' || true
	@echo "=== 整個 .text 分支指令數 ==="
	@$(OBJDUMP) -d $(TARGET) | grep -Ec '^[[:space:]]+[0-9a-f]+:.*[[:space:]](b(eq|ne|lt|ge|ltu|geu)|j)[[:space:]]' || true

run:
	$(RIPES) --mode cli --src bitrev.S -t asm --proc $(PROC) --isaexts M --iret --cycles --regs

clean:
	rm -rf $(BUILD)
