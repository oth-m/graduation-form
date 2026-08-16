-- =====================================================================
-- استمارة حجز زي التخرج — إعداد قاعدة البيانات على Supabase
-- انسخ هذا الملف كامل، والصقه في: Supabase Dashboard > SQL Editor > New Query
-- ثم اضغط Run
-- =====================================================================

-- تفعيل امتداد توليد UUID
create extension if not exists "pgcrypto";

-- =====================================================================
-- 1) جدول صلاحيات الإدارة (القائد + القادة المساعدون فقط — عبر تسجيل دخول حقيقي)
-- =====================================================================
create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('leader','assistant')),
  created_at timestamptz default now()
);

-- دالة مساعدة (SECURITY DEFINER) لمعرفة دور المستخدم الحالي بدون تكرار (recursion) بالسياسات
create or replace function public.current_role_name()
returns text
language sql
security definer
set search_path = public
as $$
  select role from public.profiles where auth_user_id = auth.uid() limit 1;
$$;

alter table public.profiles enable row level security;

create policy "profiles_select_authenticated" on public.profiles
  for select using (auth.uid() is not null);

create policy "profiles_update_leader_only" on public.profiles
  for update using (public.current_role_name() = 'leader');

create policy "profiles_insert_leader_only" on public.profiles
  for insert with check (public.current_role_name() = 'leader' or not exists (select 1 from public.profiles));

create policy "profiles_delete_leader_only" on public.profiles
  for delete using (public.current_role_name() = 'leader');

-- =====================================================================
-- 2) جدول استمارات الطلاب
-- =====================================================================
create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  student_name text not null,
  pieces text[] default '{}',
  robe jsonb default '{}',
  cap jsonb default '{}',
  scarf jsonb default '{}',
  general jsonb default '{}',
  status text default 'submitted',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.submissions enable row level security;

-- الطلاب (بدون تسجيل دخول) يقدرون يضيفون ويعدلون استمارتهم بالاسم
create policy "submissions_insert_public" on public.submissions
  for insert with check (true);

create policy "submissions_select_public" on public.submissions
  for select using (true);

create policy "submissions_update_public" on public.submissions
  for update using (true);

-- الحذف فقط من القائد أو القائد المساعد (تسجيل دخول حقيقي مطلوب)
create policy "submissions_delete_admin_only" on public.submissions
  for delete using (public.current_role_name() in ('leader','assistant'));

-- تحديث updated_at تلقائياً
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_submissions_updated_at on public.submissions;
create trigger trg_submissions_updated_at
  before update on public.submissions
  for each row execute function public.set_updated_at();

-- =====================================================================
-- 3) سجل التعديلات (Activity Logs) — لكل عملية إضافة/تعديل/حذف يقوم بها القائد أو المساعد
-- =====================================================================
create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  actor_name text,
  actor_role text,
  action text not null,           -- 'create' | 'update' | 'delete'
  target_student text,
  details jsonb,
  created_at timestamptz default now()
);

alter table public.activity_logs enable row level security;

create policy "logs_insert_anyone" on public.activity_logs
  for insert with check (true);

create policy "logs_select_admin_only" on public.activity_logs
  for select using (public.current_role_name() in ('leader','assistant'));

-- =====================================================================
-- 4) تخزين الصور (Storage Bucket)
-- =====================================================================
insert into storage.buckets (id, name, public)
values ('submission-images', 'submission-images', true)
on conflict (id) do nothing;

create policy "storage_public_read" on storage.objects
  for select using (bucket_id = 'submission-images');

create policy "storage_public_upload" on storage.objects
  for insert with check (bucket_id = 'submission-images');

-- =====================================================================
-- تم! بعد تشغيل هذا الملف:
-- 1) روح Authentication > Users بلوحة Supabase، وأضف مستخدم جديد بالبريد وكلمة مرور تختارها
--    (هذا سيكون حساب "القائد" عثمان جليل الصالح)
-- 2) روح Table Editor > profiles، وأضف صف جديد يربط auth_user_id بنفس المستخدم اللي سويته،
--    مع full_name = 'عثمان جليل الصالح' و role = 'leader'
-- 3) روح Project Settings > API، وانسخ:
--    - Project URL
--    - anon public key
--    وأرسلهم لي حتى أربط الموقع فيهم
-- =====================================================================
