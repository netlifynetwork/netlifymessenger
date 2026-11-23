-- Netlify Messenger database foundation
-- Review and apply in Supabase SQL Editor after creating the Supabase project.
-- Every exposed table has RLS enabled. No service-role key belongs in the desktop app.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone text unique,
  display_name text not null default 'New user',
  avatar_url text,
  about text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  title text,
  is_group boolean not null default false,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'admin')),
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  body text not null default '',
  message_type text not null default 'text'
    check (message_type in ('text', 'image', 'video', 'audio', 'file', 'system')),
  attachment_path text,
  reply_to uuid references public.messages(id) on delete set null,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  constraint messages_body_or_attachment check (
    length(trim(body)) > 0 or attachment_path is not null
  )
);

create index if not exists conversation_members_user_idx
  on public.conversation_members(user_id, joined_at desc);
create index if not exists messages_conversation_created_idx
  on public.messages(conversation_id, created_at desc);
create index if not exists conversations_updated_idx
  on public.conversations(updated_at desc);

-- Helper checks membership using the caller's authenticated identity.
create or replace function public.is_conversation_member(target_conversation uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1
    from public.conversation_members cm
    where cm.conversation_id = target_conversation
      and cm.user_id = (select auth.uid())
  );
$$;

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

-- Profiles are discoverable only by signed-in users. Users can edit only themselves.
drop policy if exists "Signed-in users can view profiles" on public.profiles;
create policy "Signed-in users can view profiles"
  on public.profiles for select to authenticated using (true);
drop policy if exists "Users can create their profile" on public.profiles;
create policy "Users can create their profile"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = id);
drop policy if exists "Users can update their profile" on public.profiles;
create policy "Users can update their profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- A conversation is visible only to its members.
drop policy if exists "Members can view conversations" on public.conversations;
create policy "Members can view conversations"
  on public.conversations for select to authenticated
  using (public.is_conversation_member(id));
drop policy if exists "Authenticated users can create conversations" on public.conversations;
create policy "Authenticated users can create conversations"
  on public.conversations for insert to authenticated
  with check ((select auth.uid()) = created_by);

-- Membership rows are visible to members of that same conversation.
drop policy if exists "Members can view conversation membership" on public.conversation_members;
create policy "Members can view conversation membership"
  on public.conversation_members for select to authenticated
  using (public.is_conversation_member(conversation_id));
drop policy if exists "Users can add themselves to a conversation" on public.conversation_members;
create policy "Users can add themselves to a conversation"
  on public.conversation_members for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- Only members can read messages; only the sender may create their own message.
drop policy if exists "Members can read messages" on public.messages;
create policy "Members can read messages"
  on public.messages for select to authenticated
  using (public.is_conversation_member(conversation_id));
drop policy if exists "Members can send messages as themselves" on public.messages;
create policy "Members can send messages as themselves"
  on public.messages for insert to authenticated
  with check (
    (select auth.uid()) = sender_id
    and public.is_conversation_member(conversation_id)
  );
drop policy if exists "Senders can edit their messages" on public.messages;
create policy "Senders can edit their messages"
  on public.messages for update to authenticated
  using ((select auth.uid()) = sender_id)
  with check (
    (select auth.uid()) = sender_id
    and public.is_conversation_member(conversation_id)
  );

-- Create a profile automatically when a new phone-OTP user is registered.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, phone, display_name)
  values (
    new.id,
    new.phone,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), 'New user')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_netlify_messenger on auth.users;
create trigger on_auth_user_created_netlify_messenger
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Enable realtime for message inserts. If this table is already in the publication,
-- remove it from the publication before rerunning this statement.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end
$$;
