# figures/

報告用圖表（例如指令數比較長條圖、編碼欄位示意圖）。

- 檔名請標明對應 CP，例如 `cp2_instruction_count.svg`、`cp3_encoding.svg`。
- 優先使用向量格式（`.svg`）或高解析度 `.png`。

## CP3 圖表

| 檔案 | 負責 | 內容 |
|---|---|---|
| [`cp3_encoding_fields.png`](cp3_encoding_fields.png) | B | 3 個範例的 R-type 32-bit 欄位分佈圖（bit 31 在左、bit 0 在右） |
| [`cp3_instr_compare.png`](cp3_instr_compare.png) | C | RV32IM baseline 與加入 BITREV 後的指令數比較長條圖 |
