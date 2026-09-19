-- Ledgerly / Supabase schema
-- Run this in Supabase SQL Editor. RLS is enabled for every tenant-owned table.
create extension if not exists "uuid-ossp";
create type public.document_status as enum ('draft','review','approved','archived');
create type public.invoice_status as enum ('draft','sent','paid','overdue','cancelled');

create table public.workspaces (id uuid primary key default uuid_generate_v4(), name text not null, owner_id uuid references auth.users(id) on delete cascade, created_at timestamptz not null default now());
create table public.workspace_members (workspace_id uuid references public.workspaces(id) on delete cascade, user_id uuid references auth.users(id) on delete cascade, role text not null default 'member', primary key (workspace_id,user_id));
create table public.contacts (id uuid primary key default uuid_generate_v4(), workspace_id uuid references public.workspaces(id) on delete cascade not null, name text not null, email text, company text, type text default 'client', created_at timestamptz not null default now());
create table public.documents (id uuid primary key default uuid_generate_v4(), workspace_id uuid references public.workspaces(id) on delete cascade not null, uploaded_by uuid references auth.users(id), name text not null, storage_path text not null, file_type text, file_size bigint, status public.document_status not null default 'draft', due_date date, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.invoices (id uuid primary key default uuid_generate_v4(), workspace_id uuid references public.workspaces(id) on delete cascade not null, contact_id uuid references public.contacts(id) on delete set null, invoice_number text not null, status public.invoice_status not null default 'draft', amount numeric(12,2) not null default 0, issue_date date not null default current_date, due_date date, created_at timestamptz not null default now());
create table public.transactions (id uuid primary key default uuid_generate_v4(), workspace_id uuid references public.workspaces(id) on delete cascade not null, description text not null, category text, amount numeric(12,2) not null, type text not null check (type in ('income','expense')), transaction_date date not null default current_date, created_at timestamptz not null default now());

create or replace function public.is_workspace_member(target_workspace uuid) returns boolean language sql security definer set search_path = public as $$ select exists(select 1 from workspace_members where workspace_id=target_workspace and user_id=auth.uid()) or exists(select 1 from workspaces where id=target_workspace and owner_id=auth.uid()); $$;

alter table public.workspaces enable row level security; alter table public.workspace_members enable row level security; alter table public.contacts enable row level security; alter table public.documents enable row level security; alter table public.invoices enable row level security; alter table public.transactions enable row level security;
create policy "members can view workspaces" on public.workspaces for select using (owner_id=auth.uid() or public.is_workspace_member(id));
create policy "owners can manage workspaces" on public.workspaces for all using (owner_id=auth.uid()) with check (owner_id=auth.uid());
create policy "members can access members" on public.workspace_members for select using (public.is_workspace_member(workspace_id));
create policy "members access contacts" on public.contacts for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "members access documents" on public.documents for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "members access invoices" on public.invoices for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "members access transactions" on public.transactions for all using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));

insert into storage.buckets (id, name, public) values ('documents','documents',false) on conflict (id) do nothing;
create policy "workspace members upload documents" on storage.objects for insert to authenticated with check (bucket_id='documents');
create policy "authenticated users read documents" on storage.objects for select to authenticated using (bucket_id='documents');
