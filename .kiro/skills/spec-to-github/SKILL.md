---
name: spec-to-github
description: spec の tasks.md から GitHub Issue を起票し、branch 作成 → 実装 → commit/push → PR 作成までを進める。引数に spec 名とタスク番号(例 /spec-to-github vpc-network 1)
---

# Spec → GitHub 連携ワークフロー

`.kiro/specs/<機能名>/tasks.md` を GitHub のワークフロー(Issue → branch → commit → PR)に接続する。GitHub 操作は GitHub MCP を使い、失敗時のみ `gh` CLI にフォールバックする。

## モード 1: Issue 一括起票(タスク番号なしで呼ばれた場合)

1. tasks.md の各タスクを 1 Issue として起票する
   - タイトル: `[<機能名>] <タスク名>`
   - 本文: タスク詳細、対応要件(requirements.md へのリンク)、完了条件、関連 ADR
   - ラベル: `spec:<機能名>`(なければ作成)
2. 起票した Issue 番号を tasks.md の各行に追記する(`- [ ] 1. ... (#123)`)
3. 起票一覧をユーザーに報告する

## モード 2: タスク実装(タスク番号付きで呼ばれた場合)

1. 該当 Issue の内容を確認し、作業内容をユーザーに要約する
2. branch を作成する: `feat/<機能名>-task<番号>`(main から)
3. tasks.md の完了条件を満たすように実装する(steering 規約に従う)
4. `terraform fmt` / `validate` を通してから、意味のある単位で commit する
   - コミットメッセージ: `feat(<機能名>): <変更内容> (#<Issue番号>)`
5. push 前にユーザーへ diff の要約を提示し、**承認を得てから** push する
6. PR を作成する:
   - 本文に: 変更概要、spec(requirements/design/tasks)へのリンク、関連 ADR、`Closes #<Issue番号>`
   - plan 結果の要約(CI の plan コメントが付く旨も記載)
7. tasks.md のチェックボックスを更新する

## 注意(ハーネス)

- **push と PR 作成は必ずユーザー承認後**(無断で公開操作をしない)
- main への直接 push は禁止。必ず branch + PR 経由
- Issue・PR 本文に認証情報やアカウント ID など秘匿情報を書かない
