# CP2 任務卡三：指令統計

## 統計範圍與方法

- 核心範圍：`bitrev` label 至 `ret`，不含 `test_main`、列印函式及測試 harness。
- 靜態指令數：以 GNU RISC-V GCC 組譯，再用 GNU `objdump` 檢視 RV32IM 機器碼；指令位置各計一次。
- 動態指令數：Ripes CLI 的 `--iret` 實測完整 11-vector 測試程式。這個總數包含核心、呼叫端、測試迴圈及列印函式，不可當成核心函式的動態指令數。
- 核心每次呼叫的動態數由固定路徑核算：核心沒有條件分支或迴圈，每次執行剛好經過 36 條機器指令。11 組測資各呼叫一次，因此核心合計 396 條；這是以反組譯路徑和呼叫次數計算，不是 Ripes 的函式區段計數器讀值。
- 條件分支只統計 `beq`、`bne`、`blt`、`bge` 等條件式分支；`ret` 展開為 `jalr`，是返回控制流程，不列為條件分支。

## 統計結果

| 統計範圍 | 靜態指令數 | 動態指令數 | 靜態條件分支數 | 動態條件分支執行數 |
|---|---:|---:|---:|---:|
| `bitrev` 函式，單次呼叫 | 36（含 `ret`；不含 `ret` 為 35） | 36（固定路徑核算） | 0 | 0 |
| `bitrev` 函式，CP1 11 組輸入各呼叫一次 | 36 | 396（36 × 11，固定路徑核算） | 0 | 0 |
| 完整 Ripes 11-vector 測試程式 | 不適用於核心函式比較 | 6487（Ripes `--iret` 實測） | 不納入核心統計 | 不納入核心統計 |

核心機器指令的靜態分布如下：

| RV32IM 機器指令 | 數量 |
|---|---:|
| `lui` | 4 |
| `addi` | 4 |
| `xori`（反組譯器以 `not` 別名顯示） | 4 |
| `and` | 8 |
| `slli` | 5 |
| `srli` | 5 |
| `or` | 5 |
| `jalr`（由 `ret` 展開） | 1 |
| **總計** | **36** |

核心無條件分支指令。測試 harness 自身含條件分支及迴圈控制，因此完整程式的 6487 條動態指令包含這些額外工作。

## 工具與可重現命令

靜態組譯／反組譯工具：

- GNU RISC-V GCC 16.2.0
- GNU Binutils `objdump` 2.47.20260726
- 目標參數：`-march=rv32im -mabi=ilp32`

```sh
riscv64-elf-gcc -march=rv32im -mabi=ilp32 \
  -c group17_BITREV/src/rv32im/bitrev.S -o /tmp/group17-bitrev.o
riscv64-elf-objdump -d --start-address=0x4 --stop-address=0x94 \
  /tmp/group17-bitrev.o
```

動態測試工具：

- Ripes `v2.2.6-106-g5b8a616`（macOS universal2）
- 處理器：`RV32_5S`；ISA 擴充：`M`

```sh
"/Applications/Ripes-v2.2.6-106-g5b8a616-mac-universal2.app/Contents/MacOS/Ripes" \
  --mode cli \
  --src group17_BITREV/src/rv32im/bitrev.S \
  -t asm --proc RV32_5S --isaexts M --timeout 30000 \
  --iret --regs --runinfo \
  --output group17_BITREV/report/cp2-b/ripes-instruction-count.txt
```

Ripes 實際輸出 `instructions retired = 6487`，11 組測資全部 PASS。Ripes 的計數器／處理器資訊見 [`ripes-instruction-count.txt`](../../report/cp2-b/ripes-instruction-count.txt)，終端機逐筆測試輸出見 [`ripes-instruction-count-console.txt`](../../report/cp2-b/ripes-instruction-count-console.txt)；核心反組譯輸出見 [`instruction-count-objdump.txt`](instruction-count-objdump.txt)。逐筆輸入、預期與實際結果表見 [`test-results.md`](../../report/cp2-b/test-results.md)。

終端機原始輸出以文字檔保存，未偽裝成 GUI 截圖。若組內要求一定要交 `report/figures/cp2_instr_count.png` 畫面截圖，仍需在本機終端機或 Ripes GUI 另外截取並放入該目錄。

## 檔案對照

任務卡三指定的產物位於 `group17_BITREV/src/rv32im/`（原始統計資料）及 `group17_BITREV/report/CP2.md`（統計表）。本統計原始說明與反組譯分別保存為 `instruction-count-results.md`、`instruction-count-objdump.txt`；CP2 報告第 3 節摘要同一組數據。
