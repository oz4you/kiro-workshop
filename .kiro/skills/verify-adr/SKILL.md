---
name: verify-adr
description: 壁打ちで決まった設計決定を MCP で検証し、結果を docs/adr/ に ADR として記録する。引数に spec 名を渡す(例 /verify-adr vpc-network)
---

# 設計決定の検証と ADR 記録

指定された spec(`.kiro/specs/<機能名>/design.md`)の「設計決定の記録」を読み、各決定を検証して ADR に記録する。

## 手順

1. `design.md` から設計決定(採用案・代替案・却下理由)を抽出し、一覧をユーザーに提示する
2. 各決定について以下を**実際にツールで検証**する(推測禁止):
   - **実在性**: 使用予定の Terraform リソース・引数が最新プロバイダに存在するか(Terraform MCP)
   - **ベストプラクティス適合**: AWS 公式ドキュメント・Well-Architected 観点での妥当性(AWS Documentation MCP / Well-Architected MCP)
   - **steering 適合**: `.kiro/steering/` の規約(セキュリティ・命名・コスト)に反しないか
3. 検証結果(合格/条件付き/不合格と根拠)をユーザーに報告する
4. ユーザー承認後、`docs/adr/template.md` の形式で `docs/adr/NNN-<題名>.md` を作成する
   - NNN は既存 ADR の最大番号 + 1(ゼロ埋め3桁)
   - 1つの ADR には1つの決定だけを書く(複数決定は複数 ADR)
5. 対応する spec の design.md に ADR へのリンクを追記する

## ADR に必ず含めること

- 壁打ちで出た論点(なぜこの決定が必要になったか)
- 検証方法と結果(どの MCP ツール・ドキュメントで何を確認したか)
- 採用案と却下した代替案(却下理由付き)
- 決定の帰結(将来の制約、再検討のトリガー)

## 注意

- 検証で問題が見つかった場合は ADR を書く前にユーザーへ差し戻す(設計の修正が先)
- ADR は追記のみ。過去の ADR を書き換えない(取り消す場合は新しい ADR で Supersede する)
