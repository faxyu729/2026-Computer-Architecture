# CP2 手動測試紀錄 — BITREV RV32IM 實作

- 測試對象：`bitrev.S`（`bitrev` 函式 ＋ Ripes 測試 harness）
- 測試資料：CP1 的 11 組測資（`../c_baseline/test_vectors.h`）
- 測試者：Chen Jie-Xin（1114405042）
- 結果：**11 / 11 PASS**

## 一、測試環境

| 工具 | 版本 | 用途 |
|---|---|---|
| Ripes | v2.3.0（mac-universal2） | 執行、逐步觀察暫存器、統計指令數與 cycle 數 |
| riscv64-elf-gcc | 16.2.0（Homebrew） | 組譯、反組譯、統計靜態指令數 |
| riscv64-elf-objdump | 2.47 | 靜態指令數與分支數統計 |

Processor model：`RV32_5S`（5 級 pipeline），ISA 擴充：`M`。

## 二、執行方式

```sh
cd group17_BITREV/src/rv32im
make run
```

等同於：

```sh
Ripes --mode cli --src bitrev.S -t asm --proc RV32_5S --isaexts M --iret --cycles --regs
```

GUI 逐步觀察：Ripes 開啟 `bitrev.S` → Register 分頁觀察暫存器 → 於
`bitrev_step8` / `bitrev_step4` / `bitrev_step2` / `bitrev_step1` 設 breakpoint，
可逐步看到 `a0` 的變化；執行結束後 Memory 分頁可查 `results[]`、`flags[]`、
`summary_pass`、`summary_fail`。

## 三、逐組測試結果

| # | 輸入 (hex) | 預期輸出 (hex) | 實際輸出 (hex) | 結果 | 備註 |
|---|---|---|---|---|---|
| 1 | `0x00000001` | `0x80000000` | `0x80000000` | PASS | 邊界：LSB → MSB |
| 2 | `0x0000000F` | `0xF0000000` | `0xF0000000` | PASS | 低 nibble → 高 nibble |
| 3 | `0x12345678` | `0x1E6A2C48` | `0x1E6A2C48` | PASS | 題目指定範例 |
| 4 | `0x00000000` | `0x00000000` | `0x00000000` | PASS | 邊界：全零 |
| 5 | `0xFFFFFFFF` | `0xFFFFFFFF` | `0xFFFFFFFF` | PASS | 邊界：全一（自我反轉） |
| 6 | `0x80000000` | `0x00000001` | `0x00000001` | PASS | 邊界：MSB → LSB |
| 7 | `0x0000FFFF` | `0xFFFF0000` | `0xFFFF0000` | PASS | 交換左右兩個 16-bit 區塊 |
| 8 | `0x00FF00FF` | `0xFF00FF00` | `0xFF00FF00` | PASS | 交錯 byte 圖樣 |
| 9 | `0xAAAA5555` | `0xAAAA5555` | `0xAAAA5555` | PASS | 對稱位元圖樣 |
| 10 | `0xDEADBEEF` | `0xF77DB57B` | `0xF77DB57B` | PASS | 隨機測試值 |
| 11 | `0xF0F0F0F0` | `0x0F0F0F0F` | `0x0F0F0F0F` | PASS | nibble 圖樣 |

實際輸出由 `bitrev` 函式計算後寫入 `results[]`，並與 CP1 測資的預期值逐筆比對，
比對結果寫入 `flags[]`（1 = PASS，0 = FAIL）。

## 四、Ripes CLI 完整輸出

```text
T1 in=0x00000001 exp=0x80000000 act=0x80000000 PASS
T2 in=0x0000000F exp=0xF0000000 act=0xF0000000 PASS
T3 in=0x12345678 exp=0x1E6A2C48 act=0x1E6A2C48 PASS
T4 in=0x00000000 exp=0x00000000 act=0x00000000 PASS
T5 in=0xFFFFFFFF exp=0xFFFFFFFF act=0xFFFFFFFF PASS
T6 in=0x80000000 exp=0x00000001 act=0x00000001 PASS
T7 in=0x0000FFFF exp=0xFFFF0000 act=0xFFFF0000 PASS
T8 in=0x00FF00FF exp=0xFF00FF00 act=0xFF00FF00 PASS
T9 in=0xAAAA5555 exp=0xAAAA5555 act=0xAAAA5555 PASS
T10 in=0xDEADBEEF exp=0xF77DB57B act=0xF77DB57B PASS
T11 in=0xF0F0F0F0 exp=0x0F0F0F0F act=0x0F0F0F0F PASS
PASSED=11 FAILED=0

Program exited with code: 0
===== cycles
5981
===== instructions retired
4084
```

## 五、執行結束後的暫存器狀態（`--regs`）

| 暫存器 | 值 | 意義 |
|---|---|---|
| `x9` (s1) | `11` (`0x0000000B`) | 測資總數 |
| `x18` (s2) | `11` (`0x0000000B`) | 已執行的測資組數 |
| `x19` (s3) | `11` (`0x0000000B`) | **PASS 計數 = 11** |
| `x20` (s4) | `0` (`0x00000000`) | **FAIL 計數 = 0** |
| `x31` (t6) | `0x0F0F0F0F` | 最後一組（`0xF0F0F0F0`）的實際輸出 |

記憶體同樣保留結果：`results[]` 為 11 筆實際輸出、`flags[]` 為 11 個 1、
`summary_pass = 11`、`summary_fail = 0`（於 Ripes GUI 的 Memory 分頁查看）。

### 記憶體結果表的額外驗證

在測試結束前加入一段迴圈讀回 `flags[]` 與 `results[]` 的檢查程式（僅供驗證，
未放入 `bitrev.S`），以 Ripes 執行後得到：

```text
PASSED=11 FAILED=0
flags[] PASS count = 11
results[] checksum = 1050756391
```

`results[]` 的 checksum 與 11 筆實際輸出加總後的值 `0x3EA14527` = 1050756391
完全相同，確認結果確實有被寫入記憶體。

### 補充驗證：256 組隨機測試

除了 CP1 的 11 組測資，另以同一支 `bitrev` 函式跑 256 組測試值
（10 組邊界／對稱值 ＋ 246 組隨機 32-bit 值，預期值由獨立的 Python 位元反轉
計算產生），結果 **256 / 256 PASS**。

## 六、指令數統計

計數方法：**靜態**（`riscv64-elf-objdump` 反組譯後逐條計算）與**動態**
（Ripes CLI `--iret`，指令退休數）。模擬器版本：Ripes v2.3.0。

| 項目 | 數值 | 備註 |
|---|---|---|
| `bitrev` 函式指令數（不含 `ret`） | **35** | `make count` |
| `bitrev` 函式指令數（含 `ret`） | 36 | |
| `bitrev` 函式分支指令數 | **0** | 完全無分支 |
| `bitrev` 動態指令數 | 35／每次呼叫 | 與靜態相同（無分支、與輸入無關） |
| 11 組測資的 `bitrev` 動態指令數 | 385 | 35 × 11 |
| 整個 `bitrev.S` 的 `.text` 指令數 | 147 | 含測試 harness |
| 整個程式的動態指令數 | 4084 | 含 33 次 8 位 hex 印字 |
| 整個程式的 cycle 數（RV32_5S） | 5981 | 5 級 pipeline |

### 對照組（同一工具鏈量測）

| 方案 | 靜態指令數 | 動態指令數 | 分支指令數 |
|---|---|---|---|
| **本檔 `bitrev`（分治 5 步）** | 36（含 `ret`） | 36 | **0** |
| 同一份 C baseline 經 `gcc -O2 -march=rv32im` | 40（含 `ret`） | 40 | 0 |
| 迴圈逐位元搬移（對照組原始碼見 README） | 11 | 196 | 1（執行 33 次） |
| 自訂 `BITREV` 指令（CP3 目標） | 1 | 1 | 0 |

## 七、跨處理器模型驗證（結果一致）

| Processor model | 指令退休數 | cycle 數 | 結果 |
|---|---|---|---|
| `RV32_SS`（單一 cycle） | 4084 | 4084 | 11/11 PASS |
| `RV32_5S`（5 級 pipeline） | 4084 | 5981 | 11/11 PASS |
| `RV32_ISS`（指令級模擬） | 4085 | 4085 | 11/11 PASS |
