-- Run this once in the Supabase SQL Editor (Project > SQL Editor > New query)
-- after creating the project. It sets up tables, RLS, and the two RPCs the
-- app calls for the only state changes a human Approver is allowed to make.

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null,
  department text not null default '',
  role text not null default 'user' check (role in ('user', 'approver', 'admin')),
  allowance_total numeric not null default 0,
  allowance_remaining numeric not null default 0,
  allowed_categories text[] not null default '{}'
);

create table claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  user_name text not null,
  category text not null,
  requested_amount numeric not null,
  approved_amount numeric not null default 0,
  receipt_image_url text not null,
  status text not null default 'pendingApprove' check (status in ('pendingApprove', 'approved', 'rejected')),
  ai_note text,
  reject_reason text,
  created_at timestamptz not null default now(),
  reviewed_by uuid references profiles(id),
  reviewed_at timestamptz
);

alter table profiles enable row level security;
alter table claims enable row level security;

create function is_approver() returns boolean
  language sql security definer stable as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role in ('approver', 'admin')
  );
$$;

-- profiles: everyone reads their own row, Approver/Admin reads everyone's.
-- No client-side insert/update/delete policy exists at all — a profile's
-- balance only ever changes inside approve_claim below.
create policy "read own or approver reads all" on profiles
  for select using (auth.uid() = id or is_approver());

-- claims: same read shape; a user may only ever insert their own claim, and
-- only in a state the AI screening step is allowed to leave it in.
create policy "read own claims or approver reads all" on claims
  for select using (auth.uid() = user_id or is_approver());

create policy "user files own claim" on claims
  for insert with check (
    auth.uid() = user_id
    and status in ('pendingApprove', 'rejected')
    and reviewed_by is null
    and reviewed_at is null
  );

-- Approve: the only path that changes allowance_remaining, wrapped so the
-- balance check and the status flip commit together.
create function approve_claim(p_claim_id uuid, p_approved_amount numeric)
  returns void language plpgsql security definer as $$
declare
  v_user_id uuid;
  v_status text;
  v_remaining numeric;
begin
  if not is_approver() then
    raise exception 'not authorized';
  end if;

  select user_id, status into v_user_id, v_status from claims where id = p_claim_id for update;
  if v_status is distinct from 'pendingApprove' then
    raise exception 'claim already reviewed';
  end if;

  select allowance_remaining into v_remaining from profiles where id = v_user_id for update;

  update profiles set allowance_remaining = greatest(v_remaining - p_approved_amount, 0) where id = v_user_id;

  update claims set
    status = 'approved',
    approved_amount = p_approved_amount,
    reviewed_by = auth.uid(),
    reviewed_at = now()
  where id = p_claim_id;
end;
$$;

create function reject_claim(p_claim_id uuid, p_reason text)
  returns void language plpgsql security definer as $$
begin
  if not is_approver() then
    raise exception 'not authorized';
  end if;

  update claims set
    status = 'rejected',
    reject_reason = p_reason,
    reviewed_by = auth.uid(),
    reviewed_at = now()
  where id = p_claim_id and status = 'pendingApprove';
end;
$$;

grant execute on function approve_claim(uuid, numeric) to authenticated;
grant execute on function reject_claim(uuid, text) to authenticated;

-- Storage: receipts/{uid}/filename — the folder name is the owning user's id.
insert into storage.buckets (id, name, public) values ('receipts', 'receipts', false);

create policy "user uploads own receipts" on storage.objects
  for insert with check (
    bucket_id = 'receipts' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "owner or approver reads receipts" on storage.objects
  for select using (
    bucket_id = 'receipts'
    and ((storage.foldername(name))[1] = auth.uid()::text or is_approver())
  );
