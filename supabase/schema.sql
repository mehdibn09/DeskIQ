-- ============================================================
-- NovaDesk — PostgreSQL schema for Supabase
-- Run this in the Supabase SQL editor (or `supabase db push`).
-- ============================================================

create extension if not exists pgcrypto;
create extension if not exists pg_trgm;

-- ------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------

create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text unique not null,
  full_name   text not null default '',
  avatar_url  text,
  role        text not null default 'user' check (role in ('user', 'admin')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.folders (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 60),
  created_at  timestamptz not null default now(),
  unique (user_id, name)
);

create table if not exists public.documents (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  folder_id   uuid references public.folders (id) on delete set null,
  name        text not null check (char_length(name) between 1 and 180),
  description text,
  file_path   text not null,
  file_type   text not null,
  file_size   bigint not null default 0 check (file_size >= 0),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.activity_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  action      text not null,
  document_id uuid references public.documents (id) on delete set null,
  created_at  timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Indexes for frequently queried columns
-- ------------------------------------------------------------

create index if not exists documents_user_id_idx      on public.documents (user_id);
create index if not exists documents_folder_id_idx    on public.documents (folder_id);
create index if not exists documents_created_at_idx   on public.documents (created_at desc);
create index if not exists documents_user_created_idx on public.documents (user_id, created_at desc);
create index if not exists documents_name_trgm_idx    on public.documents using gin (name gin_trgm_ops);
create index if not exists folders_user_id_idx        on public.folders (user_id);
create index if not exists activity_user_created_idx  on public.activity_logs (user_id, created_at desc);
create index if not exists activity_created_idx       on public.activity_logs (created_at desc);

-- ------------------------------------------------------------
-- updated_at maintenance
-- ------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists documents_set_updated_at on public.documents;
create trigger documents_set_updated_at
  before update on public.documents
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- Automatic profile creation on signup
-- ------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------
-- Helper: role lookup without recursive RLS evaluation
-- ------------------------------------------------------------

create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ------------------------------------------------------------
-- Row Level Security
-- ------------------------------------------------------------

alter table public.profiles      enable row level security;
alter table public.folders       enable row level security;
alter table public.documents     enable row level security;
alter table public.activity_logs enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self" on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists "folders_select_own" on public.folders;
create policy "folders_select_own" on public.folders
  for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "folders_insert_own" on public.folders;
create policy "folders_insert_own" on public.folders
  for insert with check (user_id = auth.uid());

drop policy if exists "folders_update_own" on public.folders;
create policy "folders_update_own" on public.folders
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "folders_delete_own" on public.folders;
create policy "folders_delete_own" on public.folders
  for delete using (user_id = auth.uid() or public.is_admin());

drop policy if exists "documents_select_own" on public.documents;
create policy "documents_select_own" on public.documents
  for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "documents_insert_own" on public.documents;
create policy "documents_insert_own" on public.documents
  for insert with check (user_id = auth.uid());

drop policy if exists "documents_update_own" on public.documents;
create policy "documents_update_own" on public.documents
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "documents_delete_own" on public.documents;
create policy "documents_delete_own" on public.documents
  for delete using (user_id = auth.uid() or public.is_admin());

drop policy if exists "activity_select_own" on public.activity_logs;
create policy "activity_select_own" on public.activity_logs
  for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "activity_insert_own" on public.activity_logs;
create policy "activity_insert_own" on public.activity_logs
  for insert with check (user_id = auth.uid());

-- ------------------------------------------------------------
-- Private storage bucket + object policies
-- ------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'documents',
  'documents',
  false,
  10485760,
  array[
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
    'image/png',
    'image/jpeg'
  ]
)
on conflict (id) do nothing;

drop policy if exists "documents_bucket_select" on storage.objects;
create policy "documents_bucket_select" on storage.objects
  for select using (
    bucket_id = 'documents'
    and (auth.uid()::text = (storage.foldername(name))[1] or public.is_admin())
  );

drop policy if exists "documents_bucket_insert" on storage.objects;
create policy "documents_bucket_insert" on storage.objects
  for insert with check (
    bucket_id = 'documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "documents_bucket_update" on storage.objects;
create policy "documents_bucket_update" on storage.objects
  for update using (
    bucket_id = 'documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "documents_bucket_delete" on storage.objects;
create policy "documents_bucket_delete" on storage.objects
  for delete using (
    bucket_id = 'documents'
    and (auth.uid()::text = (storage.foldername(name))[1] or public.is_admin())
  );
