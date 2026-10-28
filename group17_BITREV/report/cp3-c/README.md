# cp3-c/

CP3 任務 C（負責人：1114405012）：BITREV 指令數比較。

| 檔案 | 說明 |
|---|---|
| [instruction-count-comparison.md](./instruction-count-comparison.md) | 比較表、減少比例算式、加速來源、假設 |
| [../figures/cp3_instr_compare.png](../figures/cp3_instr_compare.png) | 比較長條圖 |

重點：RV32IM baseline 36 條 → 加入 BITREV 函式形式 2 條（−94.4%）／內嵌 1 條（−97.2%）。BITREV 數字為靜態推算（Ripes 不支援自訂 opcode），不比較 cycle 數。
