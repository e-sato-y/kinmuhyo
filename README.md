# 勤務表作成ツール（全社員対応版）

社員ごとにログインして、月間勤務表を作成・途中保存・提出できるウェブサイトです。
管理者は全社員の勤務表を一覧で確認し、Excel に出力できます。

- 画面：`index.html`（Render の Static Site で公開）
- ログインとデータ保存：Supabase（Auth ＋ データベース）
- 接続先の設定：`config.js`
- データベースの定義：`supabase/schema.sql`

## 初回セットアップ

### 1. Supabase にテーブルを作る
1. [Supabase](https://supabase.com/dashboard) でプロジェクトを開き、左のメニューから **SQL Editor** を開く
2. `supabase/schema.sql` の中身をすべて貼り付けて **Run** を押す

### 2. Supabase のログイン設定
**Authentication → Sign In / Providers**
- **Allow new users to sign up** を **オフ** にする（社員は管理者が招待します）
- Email のログインが有効になっていることを確認する

**Authentication → URL Configuration**
- **Site URL**：Render の公開 URL（例：`https://kinmuhyo.onrender.com`）
- **Redirect URLs**：同じ URL を追加する（パソコンで試すときは `http://localhost:8000` も追加）

### 3. Render で公開する
1. Render の **New → Blueprint**（または **Static Site**）で、この GitHub リポジトリを選ぶ
2. `render.yaml` の設定がそのまま使われる（Static Site の場合は次のとおり入力）
   - Build Command：`mkdir -p dist && cp -r index.html config.js vendor dist/`
   - Publish Directory：`dist`
3. 以後は GitHub に push するたびに自動で反映される

### 4. 社員を招待する
1. Supabase の **Authentication → Users → Add user → Send invitation** で、社員のメールアドレスを入力する
2. 社員に届いたメールのリンクを開くと、パスワードを設定する画面が出る
3. 氏名は最初はメールアドレスの@より前になっているので、ログイン後に「氏名」欄で直してもらう

### 5. 管理者を指定する
SQL Editor で次の文を実行する（メールアドレスを書き換える）。

```sql
update public.profiles set is_admin = true where email = 'admin@example.com';
```

管理者がログインすると、画面上部に「管理者」タブが表示されます。

## 使い方
- **勤務表を作成する**：選んだ年月の1ヶ月分を作る（土日祝日は休日）
- **途中保存**：入力が止まって3秒たつと自動で保存される。ボタンを押すとすぐに保存する
- **提出する**：提出すると自分では修正できなくなる。管理者が「差し戻し」をすると、また修正できる
- **Excel出力**：表示中の勤務表を .xlsx で保存する
- **管理者タブ**：年月を選ぶと全社員の状態（未作成／作成中／提出済）と集計を表示する。1人ずつ、または全員分をまとめて Excel に出力できる

## パソコンで試す
```bash
python -m http.server 8000
```
ブラウザで `http://localhost:8000` を開く。

## メモ
- `config.js` の `SUPABASE_ANON_KEY` は公開してよいキーです。他人のデータを読めないようにする守りは、データベース側の決まり（RLS）が担っています。`service_role` や `secret` のキーは絶対に書かないでください。
- 旧版（1人用）は `backup/index_single_user.html` に残してあります（GitHub には上げていません）。
