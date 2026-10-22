# CP2-B — 編譯與模擬

負責人：1114405041 A1SimpleSmile。實測日期：2026-10-22（Asia/Taipei）；本次重新取得 PR #4 的 LF 原始檔後重跑，精確時間見 manifest.json。

## 工具與輸入

本次來源為 PR #4 的固定 commit `4b4d4390eae81aeb9c473416e5a42bff2bfbc5a1`。
取得時 PR 尚未合併；直接下載 GitHub 原始位元組，沒有將本機 CRLF 副本當成最終來源。
原始檔 SHA-256 為 `5e9003ef7b39cb4396d3f73861f77d2fa0f175f6787cdcd12abca12cbcdb0bf7`，
與重跑後 manifest 一致。來源紀錄見 [source-provenance.txt](../../report/cp2-b/source-provenance.txt)。
本目錄 `.gitattributes` 將 `bitrev.S` 指定為 LF，以避免 checkout 改變換行。

- Ripes **v2.3.0**，Windows x86-64 可攜版；版本由 GUI「Help → Version」確認。
- 處理器：**5-stage processor / RV32_5S**；ISA：**RV32IM**，啟用 M，未啟用 C。
- `bitrev.S`：延續任務 A／PR #4 的原始程式，核心與測試 harness 均未修改。
- `../c_baseline/test_vectors.h`：CP1 的全部 11 組測資，含 0、全 1、LSB、MSB 四組邊界值。
- 本流程直接使用 Ripes 內建組譯器組譯 `.S`，不需要先產生 ELF。
  另補 GNU RISC-V GCC 的交叉組譯驗證，指定
  `-march=rv32im -mabi=ilp32`。GCC 僅組譯成 relocatable object，未連結或執行為 Linux 程式。
- 程式內的 `ecall` 使用 Ripes 服務編號，應在 Ripes 中執行。

## GUI 重現步驟（已由負責人手動操作）

1. 開啟 Ripes。用晶片圖示選擇 32-bit 5-stage processor，啟用 M；右下角確認 `ISA: RV32IM`。
2. 點 **File → Load Program**（Ctrl+O），File type 選 **Source file**，選取本目錄 `bitrev.S`，按 OK。
3. 在 Editor 確認 Input type 為 Assembly，能看到原始碼及組譯後的指令，沒有組譯錯誤。
4. 點工具列 **雙箭頭 ▶▶** 執行到結束；Console 應列出 T1～T11 全部 PASS、
   `PASSED=11 FAILED=0` 及 `Program exited with code: 0`。
5. 保留執行後狀態。在 Processor 的 Registers 選 Hex，記錄 x18/s2=11、x19/s3=11、x20/s4=0。
6. 切到左側 Memory，Display type 選 Hex。Go to register 選 s5/x21，查看結果區及 flags。
   本檔的資料布局如下；每列 Word 為 32 位元，畫面位址由上往下遞減。
7. 查看 `results[]` 的 11 個 word 與 `flags[]` 的 11 個 1；Go to register 選 s6/x22
   可跳到總結資料附近。先保留執行後截圖，再按重設，以便額外觀察資料從初始 0 變成結果。
8. 點 **Help → Version**，記錄 v2.3.0。

| 記憶體區域 | 位址 | 執行後內容 |
|---|---|---|
| results[0..10] | 0x10000058～0x10000080 | 見 [逐筆結果](../../report/cp2-b/test-results.md) |
| flags[0..10] | 0x10000084～0x100000AC | 11 個 0x00000001 |
| summary_pass | 0x100000B0 | 實際 0x0000000B |
| summary_fail | 0x100000B4 | 實際 0x00000000 |

位址適用於這份未修改的程式。若資料區或測資數量改動，須重新確認位址。

## CLI 重現步驟（已實際執行）

下載並解壓 [官方 Ripes v2.3.0 Windows 可攜版](https://github.com/mortbopet/Ripes/releases/tag/v2.3.0)。
從 repository 根目錄開 PowerShell，將 RipesPath 改成自己的工具路徑：

```powershell
.\group17_BITREV\src\rv32im\run-ripes.ps1 -RipesPath '.\tools\Ripes\Ripes.exe'
```

腳本以 Ripes 的內建組譯器組譯並執行原始程式，等待完成、擷取 stdout/stderr 與暫存器。
Windows GUI executable 使用 `Start-Process -Wait` 擷取輸出，避免直接呼叫時沒有等待或沒有 Console 輸出。
實際 CLI 參數為：

```text
Ripes.exe --mode cli --src group17_BITREV/src/rv32im/bitrev.S -t asm --proc RV32_5S --isaexts M --timeout 30000 --regs --runinfo --output group17_BITREV/report/cp2-b/ripes-registers.txt
```

執行時以 repo 根目錄為工作目錄；來源與輸出使用相對路徑，工具的本機安裝位置不寫入交付紀錄。實際命令保存在 [command.txt](../../report/cp2-b/command.txt)。
GUI 與 CLI 的 sp/gp 初值可能不同；本程式不使用堆疊，驗收比較測試結果、s2/s3/s4 及資料區，
不要求所有暫存器都相同。

腳本核對 11 組 input/expected/actual 與 CP1 header、PASS 總結、程式結束碼及 s2/s3/s4。
失敗會拋出錯誤；成功才產生測試表與 manifest。輸出存於 `report/cp2-b/`：

- `command.txt`：本次執行的完整命令。
- `ripes-stdout.txt`：Ripes 實際輸出，11/11 PASS。
- `ripes-stderr.txt`：本次為空。
- `ripes-registers.txt`：最終暫存器與處理器設定。
- `test-results.md`：從本次 stdout 核對並產生的 11 組結果表。
- `manifest.json`：時間、原始碼／CP1 測資／Ripes.exe 的 SHA-256 與結果。

本次未啟用 `--iret`、`--cycles` 等效能統計；指令統計由任務 C 處理，
也不將包含列印 harness 的整個程式當成 bitrev 核心的指令數。

## CP1 C baseline 交叉驗證

另外在 WSL Ubuntu 用 **GCC 15.2.0** 執行原有 C 測試程式。
在 `group17_BITREV/src/c_baseline/` 中的等效重現指令：

```sh
gcc --version
gcc -Wall -Wextra -std=c11 bitrev.c test_bitrev.c -o /tmp/cp2-bitrev-cp1
/tmp/cp2-bitrev-cp1
```

本次實際執行的工作目錄及指令見 [CP1 執行說明](../../report/cp2-b/cp1-command.txt)，
原始輸出見 [cp1-baseline.txt](../../report/cp2-b/cp1-baseline.txt)：
`Total: 11, Passed: 11, Failed: 0`，結束碼 0。
這是主機 C 正確性比對，不是 RV32IM GCC 交叉編譯。

## GCC 編譯驗證（本次新增，已實際執行）

使用 WSL Ubuntu，GNU RISC-V GCC **14.2.0**（Ubuntu 套件 14.2.0+19）。
本機原本沒有交叉編譯器，因此從官方 Ubuntu 套件來源下載 GCC 與 binutils，解壓於本機工具目錄，
將工具目錄的 `usr/bin` 加入 PATH；未修改系統安裝。其他組員可使用自己安裝的同名工具。
從 repo 根目錄執行：

```sh
riscv64-unknown-elf-gcc --version
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -c group17_BITREV/src/rv32im/bitrev.S -o /tmp/bitrev.o
riscv64-unknown-elf-readelf -h -A /tmp/bitrev.o
```

實際結果：GCC 結束碼 **0**，無錯誤或警告；readelf 確認 **ELF32、RISC-V、REL**，
架構屬性 `rv32i2p1_m2p0_zmmul1p0`。這是組譯成功的 object，不是可直接載入執行的 ELF executable。
完整命令、版本及原始輸出見 [gcc-build.txt](../../report/cp2-b/gcc-build.txt)。

## 本次重跑的截圖

原有截圖是 2026-10-22 手動操作 CRLF 副本的紀錄；已比對確認指令、註解與測資
和本次 LF 檔案完全相同，僅換行格式與檔案結尾不同，因此可保留為既有功能佐證。
本次 CLI 重跑的證據是更新後的 stdout、registers、manifest 及 source-provenance。
使用者已重新載入 repo 內的 `bitrev.S` 並執行，補拍的
[cp2_ripes_tests_rerun.png](../../report/figures/cp2_ripes_tests_rerun.png)
完整顯示 T1～T11 全部 PASS、`PASSED=11 FAILED=0`、程式結束碼 0，
右下角確認 5-stage processor / RV32IM。此圖為本次 GUI 重跑佐證，原圖保留為先前紀錄。

## 佐證與遇到的問題

| 圖片 | 證明內容 |
|---|---|
| [cp2_ripes_tests_01.png](../../report/figures/cp2_ripes_tests_01.png) | 手動 GUI 執行的 11 組輸出、PASS 總結、exit 0；右下角 RV32IM |
| [cp2_ripes_regs.png](../../report/figures/cp2_ripes_regs.png) | s2=11、s3=11、s4=0；5-stage processor / RV32IM |
| [cp2_ripes_memory_results.png](../../report/figures/cp2_ripes_memory_results.png) | results[] 全部 11 組實際結果 |
| [cp2_ripes_memory_flags.png](../../report/figures/cp2_ripes_memory_flags.png) | flags[] 全部為 1 |
| [cp2_ripes_summary_values.png](../../report/figures/cp2_ripes_summary_values.png) | summary_pass=11、summary_fail=0 的記憶體內容 |
| [cp2_ripes_version.png](../../report/figures/cp2_ripes_version.png) | Ripes v2.3.0 |

- 載入 `.S` 時若選 Executable (ELF)，會顯示 `Error: Not an ELF file`；改選 **Source file** 即可。
- 本版選單名稱是 **Load Program**、**Help → Version**。
- Computer Use 未獲准存取 Ripes 視窗，因此 GUI 操作與截圖由負責人手動完成；CLI 由 AI 協助執行與核對。
- 原命名 `cp2_ripes_memory_summary.png` 的圖片只拍到 flags，交付時按內容另存為 `cp2_ripes_memory_flags.png`；
  使用者另外補拍 `cp2_ripes_summary_values.png`，已確認 B0=11、B4=0。

本任務交付組譯／模擬流程與正確性紀錄；任務 C 的靜態／動態指令統計、任務 D 的完整六段式報告仍由其負責人完成。
