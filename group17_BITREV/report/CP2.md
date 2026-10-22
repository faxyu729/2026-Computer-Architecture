# CP2 — RV32IM 實作

> 本檔於 CP2 繳交前完成，格式依 HOMEWORK.md 第 5.3 節（六段式）。

## 1. 本次目標

（待補：本次 CP2 要完成的項目，一句話。）

## 2. 設計內容

（待補：RV32IM 組合語言設計，僅允許 RV32IM；對應程式碼置於
`../src/rv32im/`。）

## 3. 結果與分析

以下區分 `bitrev` 核心與整個測試程式：核心統計範圍為
`bitrev` label 至 `ret`，不含呼叫端、測試迴圈及列印函式。

| 統計範圍 | 靜態指令數 | 動態指令數 | 靜態條件分支數 | 動態條件分支執行數 |
|---|---:|---:|---:|---:|
| `bitrev` 核心，單次呼叫 | 36（含 `ret`；不含 `ret` 為 35） | 36（固定路徑核算） | 0 | 0 |
| `bitrev` 核心，11 次呼叫 | 36 | 396（36 × 11，固定路徑核算） | 0 | 0 |
| 完整 Ripes 測試程式，CP1 11 組測資 | — | 6487（Ripes `--iret` 實測） | 不納入核心統計 | 不納入核心統計 |

核心靜態指令數由 GNU RISC-V GCC 16.2.0 組譯、GNU Binutils
`objdump` 2.47.20260726 反組譯計算，目標參數為
`-march=rv32im -mabi=ilp32`。核心不含條件分支；`ret` 展開為 `jalr`，是函式返回控制指令，不列入條件分支數。
核心沒有迴圈或條件分支，所以每次呼叫固定執行 36 條；
11 次呼叫合計 396 條，此數由固定路徑和呼叫次數核算。

動態指令數另以 Ripes `v2.2.6-106-g5b8a616`、`RV32_5S`、RV32IM
執行完整 11-vector 測試程式，透過 `--iret` 實測得到 6487 條。
此總數包含測試 harness、列印與核心，不能解讀為核心函式本身的指令數。
Ripes 輸出 11/11 PASS；逐筆輸入、預期與實際結果見
[`test-results.md`](cp2-b/test-results.md)。計數器輸出、終端機測試輸出及核心反組譯分別見
[`ripes-instruction-count.txt`](cp2-b/ripes-instruction-count.txt)、
[`ripes-instruction-count-console.txt`](cp2-b/ripes-instruction-count-console.txt)、
[`instruction-count-objdump.txt`](../src/rv32im/instruction-count-objdump.txt)，
統計方法與可重現命令見
[`instruction-count-results.md`](../src/rv32im/instruction-count-results.md)。

## 4. 遭遇的問題與解法

（待補：至少一個實際遇到的問題。）

## 5. 白話說明

（待補：200 字以內，用非術語方式解釋核心概念。）

## 6. AI 使用說明

（待補）
