# group17_BITREV

2026 計算機組織「Custom RISC-V Instruction」學期專題——組別 `group17_BITREV`，
負責指令 **`BITREV`（位元反轉，DSP 類，題號 17）**。

正式作業規定以 [HOMEWORK.md](../HOMEWORK.md) 為準。

## 小組資訊

| 項目 | 內容 |
|---|---|
| 題目 | BITREV |
| 組名 | 一群瘋子 |
| 組長 | 范芯瑜Fan Xin-Yu |
| 組員 | 范芯瑜Fan Xin-Yu（1114405020）、陳絜歆Chen Jie-Xin（1114405042）、賴俋勳A1SimpleSmile（1114405041）、葉宥樑Allenyeh（1114405012） |
| 分支 | `dev/1114405020`、`dev/1114405042`、`dev/1114405041`、`dev/1114405012` |

個人貢獻聲明見 [CONTRIBUTIONS.md](CONTRIBUTIONS.md)。

## 目錄結構

```
group17_BITREV/
├── README.md                      # 本檔（組別總覽、CP 對照）
├── CONTRIBUTIONS.md               # 個人貢獻聲明
├── instructions/
│   ├── README.md
│   └── BITREV/
│       └── README.md              # 指令語意與說明
├── report/
│   ├── README.md
│   ├── CP1.md  CP2.md  CP3.md     # 各 Checkpoint 報告（六段式）
│   └── figures/                   # 報告用圖表
└── src/
    ├── README.md
    ├── c_baseline/                # CP1：C 參考實作、測資、測試、Makefile
    └── rv32im/                    # CP2：RV32IM 組合語言與指令統計
```

## CP ↔ 目錄 對照（PR 分界）

| CP | 產物路徑（皆在 `group17_BITREV/` 下） | 對應 tag |
|---|---|---|
| **CP1** C baseline | `src/c_baseline/` + `report/CP1.md` | `cp1-submit` |
| **CP2** RV32IM 實作 | `src/rv32im/` + `report/CP2.md` | `cp2-submit` |
| **CP3** 指令規格與編碼 | [主報告](report/CP3.md)、[語意與虛擬碼](instructions/BITREV/README.md)、[B：編碼及驗證](report/cp3-b/README.md)、[C：指令數比較](report/cp3-c/README.md)、[圖表](report/figures/README.md) | `cp3-submit`（預定提交tag，非已完成聲明） |

## 繳交流程

1. 組員在 `dev/<學號>` 分支，只修改**該 CP 對應的目錄**。
2. 組長開 PR：`dev/<學號>` → `main`（PR 標題註明 `[CP1]`/`[CP2]`/`[CP3]`）。
3. 合併到 `main` 後打 tag（`cp1-submit`/`cp2-submit`/`cp3-submit`）並 push，為正式繳交依據。
4. 全員同步 `main` 後再開始下一個 CP，避免同一 PR 混入多個 CP 的修改。

## 文件導覽

| 路徑 | 內容 |
|---|---|
| `instructions/BITREV/README.md` | BITREV 語意與說明 |
| `src/c_baseline/README.md` | CP1 成品說明與使用方式 |
| [CP1](report/CP1.md)、[CP2](report/CP2.md)、[CP3](report/CP3.md) | 各 Checkpoint 六段式報告 |
| `CONTRIBUTIONS.md` | 個人貢獻聲明（每人至少 15%，加總 100%） |
