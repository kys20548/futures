# Futures Go Rewrite

Java 期貨交易平台（futures-api + futures-server）→ Go 重構專案。

## 工作方式

此 repo 由 Claude Code 以三種模式操作：

- **ANALYZE**：分析 Java 原始碼，以架構師視角寫 spec
- **IMPLEMENT**：依 spec 用 TDD 實作 Go 程式碼
- **ISSUE**：將需求整理成 GitHub issue

詳見 `CLAUDE.md`。

## 進度

見 `_progress.md`。

## 結構

```
specs/     ← 架構分析 spec 文件
go/        ← Go 實作
_progress.md ← 分析進度追蹤
CLAUDE.md    ← Agent 工作指南
```
