-- ============================================================
-- 勤務表サイト用のデータベース設定
-- Supabase の「SQL Editor」にこのファイルの中身をすべて貼り付けて「Run」を押します。
-- 何度実行しても壊れないように書いてあります（作り直しではなく、足りない分だけ作ります）。
-- ============================================================

-- ------------------------------------------------------------
-- 社員の情報（ログインしたユーザー1人につき1行）
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  email         text,
  full_name     text not null default '',
  is_admin      boolean not null default false,       -- 管理者なら true
  default_start text not null default '09:00',        -- 基本出勤時刻
  default_end   text not null default '18:00',        -- 基本退勤時刻
  default_break integer not null default 60,          -- 休憩時間（分）
  created_at    timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 勤務表（社員1人・1ヶ月につき1行）
-- ------------------------------------------------------------
create table if not exists public.timesheets (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  year       integer not null,
  month      integer not null check (month between 1 and 12),
  settings   jsonb not null,   -- 基本設定（年月・基本時刻・休憩）
  rows       jsonb not null,   -- 1日ごとの勤務内容（画面の rows をそのまま保存）
  status     text not null default 'draft' check (status in ('draft', 'submitted')),  -- 作成中 / 提出済
  updated_at timestamptz not null default now(),
  unique (user_id, year, month)
);

-- 保存するたびに「最終更新日時」を自動で更新する
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists timesheets_touch on public.timesheets;
create trigger timesheets_touch
  before update on public.timesheets
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------
-- 社員が招待されたら（auth.users に行が増えたら）、profiles にも自動で行を作る
-- 氏名は、招待時に full_name があればそれを、なければメールアドレスの@より前を入れておきます
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- このファイルを実行する前から登録済みのユーザーの分も作っておく
insert into public.profiles (id, email, full_name)
select id, email, split_part(email, '@', 1) from auth.users
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- 「今ログインしている人は管理者か？」を調べる関数
-- （ポリシーの中で profiles を読むと無限ループになるため、security definer で回避します）
-- ------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

-- ------------------------------------------------------------
-- アクセスの決まり（RLS：行レベルセキュリティ）
-- 社員は自分の分だけ、管理者は全員分を読めます
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.timesheets enable row level security;

-- profiles：自分の行（管理者は全員分）を読める
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

-- profiles：自分の行だけ書き換えられる（書き換えられる列は下の GRANT で制限）
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- 社員が自分で管理者になれないように、書き換えてよい列を氏名と基本時刻だけにする
revoke insert, update, delete on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, default_start, default_end, default_break) on public.profiles to authenticated;

-- timesheets：自分の分（管理者は全員分）を読める
drop policy if exists "timesheets_select" on public.timesheets;
create policy "timesheets_select" on public.timesheets
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- timesheets：自分の分を新しく作れる
drop policy if exists "timesheets_insert_own" on public.timesheets;
create policy "timesheets_insert_own" on public.timesheets
  for insert to authenticated
  with check (user_id = auth.uid());

-- timesheets：自分の分を書き換えられるのは「作成中」のあいだだけ（提出したら編集できない）
drop policy if exists "timesheets_update_own_draft" on public.timesheets;
create policy "timesheets_update_own_draft" on public.timesheets
  for update to authenticated
  using (user_id = auth.uid() and status = 'draft')
  with check (user_id = auth.uid());

-- timesheets：管理者は全員分を書き換えられる（差し戻しで使います）
drop policy if exists "timesheets_update_admin" on public.timesheets;
create policy "timesheets_update_admin" on public.timesheets
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

revoke all on public.timesheets from anon;
revoke delete on public.timesheets from authenticated;
grant select, insert, update on public.timesheets to authenticated;

-- ------------------------------------------------------------
-- 管理者の指定（メールアドレスを書き換えて、この行だけを選んで実行します）
-- ------------------------------------------------------------
-- update public.profiles set is_admin = true where email = 'admin@example.com';
