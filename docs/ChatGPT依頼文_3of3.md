【依頼文 3/3】
依頼文の最後です（バックエンド仕様・制約・成果物）。

## 5. バックエンド（Supabase）の仕様 ※変更不可

接続先は `config.js` に定義済み（`SUPABASE_URL` と `SUPABASE_ANON_KEY` をグローバル定数として読み込む）。
Supabase JS は v2（`@supabase/supabase-js@2`）を使う。

### テーブル `profiles`（社員1人1行。招待時に自動作成）
| 列 | 型 | 説明 |
|---|---|---|
| id | uuid | auth.users の id |
| email | text | |
| full_name | text | 氏名（本人が変更可） |
| is_admin | boolean | 管理者なら true（本人は変更不可） |
| default_start / default_end | text | 基本出勤・退勤時刻（"09:00" 形式、本人が変更可） |
| default_break | integer | 休憩（分、本人が変更可） |

### テーブル `timesheets`（社員1人・1ヶ月1行。`unique(user_id, year, month)`）
| 列 | 型 | 説明 |
|---|---|---|
| user_id | uuid | 社員 |
| year / month | integer | 年・月 |
| settings | jsonb | `{ year, month, startTime: "09:00", endTime: "18:00", breakMinutes: 60 }` |
| rows | jsonb | 1日ごとの配列（下記） |
| status | text | `draft`（作成中）または `submitted`（提出済） |
| updated_at | timestamptz | 自動更新 |

`rows` の1要素：
```json
{ "month": 11, "day": 3, "weekday": 2, "holidayName": "文化の日",
  "type": "休日", "start": "", "end": "", "breakMinutes": 0, "remark": "" }
```
（weekday は 0=日〜6=土。既存データとの互換のため、この形は変えないこと）

### 主な操作
- 保存：`timesheets` に `upsert`（`onConflict: "user_id,year,month"`、status は `draft`）
- 読み込み：`user_id`・`year`・`month` で `maybeSingle()`
- 提出：`update({ status: "submitted" })` → `.select()` で1行更新されたか確認
- 差し戻し（管理者）：`update({ status: "draft" })`
- 管理者一覧：`profiles` 全件 と その月の `timesheets` 全件を取得して結合

### アクセスの決まり（RLS）
- 本人は自分の行だけ読み書きできる。提出済（submitted）の行は本人は更新できない。
- 管理者は全員分を読め、status を更新できる。
- 削除はできない。未ログインでは何も読めない。

---

## 6. 技術的な制約

- 公開先は **Render の Static Site**（GitHub に push すると反映）。サーバー側の処理は持てない。
- 現在はビルドなしの素の HTML/CSS/JavaScript（`index.html` 1ファイル＋`config.js`＋`vendor/exceljs.min.js`）。
  - フレームワーク（React + Vite など）を使ってもよいが、その場合は Render の Build Command と Publish Directory（現在は `mkdir -p dist && cp -r index.html config.js vendor dist/` と `dist`）も合わせて示すこと。
  - 迷ったら、今の構成（ビルドなし）のままを推奨。
- 外部ライブラリは CDN からバージョン固定で読み込む。
- service_role キーなどの秘密情報は絶対に画面側に書かない（anon key だけを使う）。
- 氏名など利用者が入力した文字を画面に出すときは、HTML として解釈されないようにする（XSS 対策）。

---

## 7. お願いしたい成果物

1. 完成した `index.html`（またはフレームワーク版一式）
2. 変更点の説明（画面ごとに何を改善したか）
3. 上記「業務ルール」をすべて満たしているかのチェックリスト
4. コードのコメントは日本語で、初心者が読んでもわかるように丁寧に書く

### 特に改善してほしい点（自由に提案してよい）
- 全体の見た目を、今どきの業務アプリらしく整える（余白・文字の大きさ・ボタンの強弱）
- 1ヶ月分の表を入力しやすく（キーボードで次の欄へ移動しやすい、今日の行がわかる など）
- 保存状態・提出状態がひと目でわかる表示
- 管理者画面で、未提出の人がすぐわかる表示（並べ替え・絞り込みなど）
- スマホでの入力のしやすさ

---

以上で依頼文はすべてです。1/3〜3/3の内容をすべて踏まえて、まず「作る方針（構成・画面ごとの改善案）」を簡潔に示し、そのあと成果物を作成してください。
