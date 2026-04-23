---
description: 列出 Claude Code 從指定版本（或目前安裝版本）到最新版本的更新報告
argument-hint: "[from-version] （省略則以目前安裝版本為起點）"
---

使用者想看 Claude Code 的版本更新報告。參數（可選）: $ARGUMENTS

請依照下列步驟執行：

1. **抓取官方 CHANGELOG**：用 WebFetch 抓 `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md`。
   - 若抓不到 raw 網址，退回用 `https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md`。
   - 從 CHANGELOG 取得**最新版本**（檔案中列於最上方、語意版號最高的那一筆）作為終點。

2. **決定起點版本**：
   - **有給參數**（from-version）：以該版本作為起點（**不含**），與 CHANGELOG 最新版本（含）比對。回報時明確寫出「你指定的 vX.Y.Z 距離最新 vA.B.C 差 N 個版本」。
   - **沒給參數**：執行 `claude --version` 取得目前安裝版本作為起點（**不含**），與 CHANGELOG 最新版本（含）比對。回報時明確寫出「你目前的 vX.Y.Z 距離最新 vA.B.C 差 N 個版本」。
   - 若起點 = 終點（已是最新），直接回報「已是最新版 vA.B.C，沒有待同步的更新」並結束，不需產後續報告。
   - 若起點版本在 CHANGELOG 找不到（例如本地比 release 還新、或使用者輸入了不存在的版號），直接告訴使用者找不到該版本、列出 CHANGELOG 最新幾版供參考，然後停止。

3. **彙整變更內容**：擷取區間內所有版本（起點之後到最新，含最新）的 changelog 條目，分類整理：
   - 新功能 / 改進
   - Bug 修復
   - 破壞性變更或需注意事項（若有）
   - 其他（文件、內部調整等）

4. **輸出報告**（繁體中文台灣用語）格式：

   ```
   # Claude Code 更新報告

   **起點**：vX.Y.Z（{指定 | 目前安裝}）
   **最新**：vA.B.C
   **差距**：N 個版本

   ## 新功能 / 改進
   - [vA.B.C] …
   - [vA.B.C-1] …

   ## Bug 修復
   - …

   ## 需注意
   - …（若無可省略此段）

   ## 版本清單
   - vA.B.C
   - vA.B.C-1
   - …
   ```

   - 每條保留版本號前綴，讓使用者知道變更落在哪一版。
   - 若原文用英文，翻成繁中但保留技術詞（如 MCP、slash command、hook 等）原樣。
   - 盡量精簡，同類變更可合併但別過度濃縮到失真。

5. **不要**：不要自行安裝或升級任何東西；此 command 只做「讀取 + 報告」。
