# CP2 — BITREV 的 RV32IM 實作

- 對應 Checkpoint: CP2
- 負責人: Chen Jie-Xin（1114405042）
- 指令: `BITREV`，語意 `rd[i] = rs1[31 - i]`（HOMEWORK.md 6.5）

## 檔案

| 檔案 | 內容 |
|---|---|
| `bitrev.S` | `bitrev()` 函式（純 RV32IM）＋ Ripes 測試 harness（11 組 CP1 測資） |
| `test_results.md` | 手動測試紀錄（輸入／預期／實際／PASS-FAIL）與指令數統計 |
| `Makefile` | 重現用：組譯、反組譯、指令數統計、跑 Ripes |

## 一、演算法：分治 5 步遮罩交換

與 CP1 的 C baseline（`../c_baseline/bitrev.c`）同構，順序一致（16→8→4→2→1）：

| 步驟 | 位元組大小 k | 遮罩 L（往上移） | 遮罩 U（往下移） | 動作 |
|---|---|---|---|---|
| step1 | 16 | — | — | 交換兩個 16-bit 半字 |
| step2 | 8 | `0x00FF00FF` | `0xFF00FF00` | 交換每個半字內的兩個 byte |
| step3 | 4 | `0x0F0F0F0F` | `0xF0F0F0F0` | 交換每個 byte 內的兩個 nibble |
| step4 | 2 | `0x33333333` | `0xCCCCCCCC` | 交換每個 nibble 內的兩個 2-bit 群組 |
| step5 | 1 | `0x55555555` | `0xAAAAAAAA` | 交換相鄰的兩個位元 |

每一步的動作固定為：

```text
t2 = (x & L) << k
t3 = (x & U) >> k
x  = t2 | t3
```

step1 例外：位移 16 位不會遺失位元，因此不需要遮罩與 AND，只要 `slli` / `srli` / `or`
三條指令即可完成半字互換（與 C 版的結果完全相同）。

## 二、暫存器配置

`bitrev` 是 leaf function：不保存暫存器、不使用堆疊，只破壞 `a0` 與 `t0`–`t3`。

| 暫存器 | 角色 | 說明 |
|---|---|---|
| `a0` | 輸入 `x` → 輸出結果 | 每一步就地更新，不需搬回 |
| `t0` | `U(k)` 遮罩 | 標記「要往下移」的高半邊位元群組 |
| `t1` | `L(k)` 遮罩 | 標記「要往上移」的低半邊位元群組 |
| `t2` | 中間值 | `(x & L) << k` |
| `t3` | 中間值 | `(x & U) >> k` |

遮罩的取得方式：`t1` 用 `lui` + `addi` 兩條指令載入 `L(k)`，再用 `xori t0, t1, -1`
取補數得到 `U(k)`（兩者互補，只算一個常數）。

測試 harness 另外用到 `s0`–`s6`（測資游標、計數器、結果表寫入游標）、
`s7`–`s9`（`print_hex32` 的計數／位移／原值，`print_str` 的掃描游標）與 `t6`（本輪實際輸出），
與 `bitrev` 函式本身無關。

## 三、演算法選用理由（指令數 vs 分支數的取捨）

| 方案 | 靜態指令數 | 動態指令數 | 分支指令數 | 分支執行次數 |
|---|---|---|---|---|
| **分治 5 步（本檔 `bitrev`）** | 36（含 `ret`） | 36 | **0** | 0 |
| 同一份 C baseline 經 `gcc -O2` | 40（含 `ret`） | 40 | 0 | 0 |
| 迴圈逐位元搬移（對照組） | 11 | 196 | 1 | 33 |
| 自訂 `BITREV` 指令（CP3 目標） | 1 | 1 | 0 | 0 |

取捨理由：

1. **指令數**：迴圈版每筆資料都要跑 32 輪，動態指令數 196，是分治版（36）的 5.4 倍；
   分治版的指令數與輸入值無關，CP3 與自訂指令比較時基準清楚（36 : 1）。
2. **分支數**：迴圈版帶 1 條分支指令、每筆資料執行 33 次分支；分治版完全無分支，
   後續 pipeline 課程討論「分支預測／front-end 排程」時不會把迴圈控制的成本算進來。
3. **硬體面**：分治 5 步在硬體上其實就是 5 層固定接線（不需要 ALU、不需要迴圈控制），
   正是自訂指令硬體成本（32×32 接線網）的來源；迴圈版則需要 ALU + 移位器 + 迴圈控制。
4. 手寫版本比 `gcc -O2` 少 4 條指令，來自於 step1 省下遮罩、以及只載入一個遮罩再用
   `xori` 取補數。

迴圈版對照組原始碼（僅供對照，本組採分治版）：

```asm
bitrev_loop:
    mv    t0, a0              # x
    li    t1, 0               # r
    li    t2, 32              # 迴圈次數
1:  andi  t3, t0, 1           # 取 x 的最低位
    slli  t1, t1, 1           # r <<= 1
    or    t1, t1, t3           # r |= 該位元
    srli  t0, t0, 1           # x >>= 1
    addi  t2, t2, -1
    bnez  t2, 1b
    mv    a0, t1
    ret
```

## 四、在 Ripes 執行與逐步觀察

### CLI（可重現、產出指令數）

```sh
make run
# 等同於:
# Ripes --mode cli --src bitrev.S -t asm --proc RV32_5S --isaexts M --iret --cycles --regs
```

### GUI 逐步觀察

1. Ripes → `File > Open` 選 `bitrev.S`，ISA 設為 RV32IM，Processor 選 `RV32_5S`。
2. 在 Register 分頁觀察暫存器；於 `bitrev_step8`、`bitrev_step4`、`bitrev_step2`、
   `bitrev_step1` 這幾個標籤設 breakpoint，可看到 `a0` 每一步的變化：
   `a0` 的高／低半邊互換 → byte 互換 → nibble 互換 → 2-bit 群組互換 → 位元互換。
3. 執行結束後於 Memory 分頁查看：
   - `results[]`：11 組測資的實際輸出
   - `flags[]`：1 = PASS、0 = FAIL
   - `summary_pass` / `summary_fail`：通過與失敗的組數（應為 11 / 0）

### Ripes 的兩個限制（本檔已避開）

| 限制 | 現象 | 本檔的處理 |
|---|---|---|
| 組譯器不支援 `.type` / `.size` / `.space` | 組譯錯誤 | 全部不寫，改用 `.word` 列出資料 |
| `.string` 內的 `\n` 不會被當跳脫字元 | 會被組出 NUL(0x00)，console 沒有斷行 | 換行改用 `print_char(0x0A)`（`print_nl`） |
| `print_string`（`a7=4`）會連字串結尾的 NUL 一起印出 | console 出現雜訊字元 | 自寫 `print_str`：逐字元用 `print_char` 送出，遇到 NUL 就停且不印 |

`bitrev` 函式本身不受以上任何影響（純 RV32I，無 `ecall`、無偽指令相依）。

## 五、測試結果

- CP1 的 11 組測資：**11 / 11 PASS**
- 另以同一支函式跑 256 組（10 組邊界／對稱值 ＋ 246 組隨機值）：**256 / 256 PASS**

完整紀錄見 [`test_results.md`](test_results.md)。

> 註：`bitrev.S` 中只有測試 harness 使用 Ripes 專屬的 `ecall`（印字用）；
> `bitrev` 函式本身只用 RV32I 基礎指令，且不含任何 `ecall`。
