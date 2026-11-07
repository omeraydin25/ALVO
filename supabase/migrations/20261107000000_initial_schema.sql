-- ALVO initial Supabase schema. Apply with Supabase CLI or SQL Editor.
-- No secrets, service-role key, or project-specific credentials belong here.

begin;

create extension if not exists pgcrypto with schema extensions;

grant usage on schema public to anon, authenticated;

-- Public-facing profile data only. Privileged roles deliberately do not live here.
create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  username text,
  display_name text not null default 'ALVO kullanıcısı',
  avatar_path text,
  bio text,
  city text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_length check (username is null or char_length(username) between 3 and 30),
  constraint profiles_display_name_length check (char_length(display_name) between 1 and 80),
  constraint profiles_bio_length check (bio is null or char_length(bio) <= 500),
  constraint profiles_city_length check (city is null or char_length(city) <= 80)
);
create unique index if not exists profiles_username_lower_uidx
  on public.profiles (lower(username)) where username is not null;

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles (user_id) on delete cascade,
  title text not null,
  description text not null,
  price numeric(12,2) not null,
  category text not null,
  city text not null,
  district text,
  status text not null default 'draft',
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint listings_title_length check (char_length(title) between 5 and 120),
  constraint listings_description_length check (char_length(description) between 1 and 10000),
  constraint listings_price_nonnegative check (price >= 0),
  constraint listings_category_allowed check (category in (
    'Elektronik','Telefon','Bilgisayar','Ev ve Yaşam','Moda','Giyim',
    'Araç','Yedek Parça','Spor','Hobi','Anne ve Bebek','Diğer'
  )),
  constraint listings_city_length check (char_length(city) between 1 and 80),
  constraint listings_district_length check (district is null or char_length(district) <= 80),
  constraint listings_status_allowed check (status in ('draft','active','sold','archived'))
);
create index if not exists listings_public_feed_idx on public.listings (published_at desc, id desc) where status = 'active';
create index if not exists listings_seller_created_idx on public.listings (seller_id, created_at desc);
create index if not exists listings_category_feed_idx on public.listings (category, published_at desc) where status = 'active';
create index if not exists listings_city_feed_idx on public.listings (city, published_at desc) where status = 'active';

create table if not exists public.listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  storage_path text not null unique,
  alt_text text,
  sort_order smallint not null default 0,
  created_at timestamptz not null default now(),
  constraint listing_images_path_shape check (
    storage_path !~ '(^/|(^|/)\.\.?(/|$)|\\|//)'
    and char_length(storage_path) <= 500
  ),
  constraint listing_images_alt_length check (alt_text is null or char_length(alt_text) <= 200),
  constraint listing_images_sort_order check (sort_order between 0 and 99)
);
create index if not exists listing_images_listing_order_idx on public.listing_images (listing_id, sort_order, created_at);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles (user_id) on delete cascade,
  listing_id uuid not null references public.listings (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, listing_id)
);
create index if not exists favorites_listing_idx on public.favorites (listing_id);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles (user_id) on delete restrict,
  kind text not null default 'direct',
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint conversations_kind_allowed check (kind in ('direct','group')),
  constraint conversations_title_length check (title is null or char_length(title) between 1 and 120)
);
create index if not exists conversations_created_by_idx on public.conversations (created_by, created_at desc);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (user_id) on delete cascade,
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);
create index if not exists conversation_members_user_idx on public.conversation_members (user_id, joined_at desc);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (user_id) on delete restrict,
  body text not null,
  created_at timestamptz not null default now(),
  constraint messages_body_length check (char_length(body) between 1 and 5000)
);
create index if not exists messages_conversation_timeline_idx on public.messages (conversation_id, created_at desc, id desc);
create index if not exists messages_sender_idx on public.messages (sender_id, created_at desc);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (user_id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  reason text not null,
  details text,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  constraint reports_target_type_allowed check (target_type in ('listing','profile','message')),
  constraint reports_reason_length check (char_length(reason) between 3 and 120),
  constraint reports_details_length check (details is null or char_length(details) <= 3000),
  constraint reports_status_allowed check (status in ('pending','reviewing','resolved','rejected'))
);
create index if not exists reports_reporter_created_idx on public.reports (reporter_id, created_at desc);
create index if not exists reports_moderation_queue_idx on public.reports (status, created_at asc);

-- Keep timestamps and publication time server-controlled.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function public.set_listing_publication_time()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'active' and (tg_op = 'INSERT' or old.status is distinct from 'active') then
    new.published_at := now();
  elsif new.status <> 'active' then
    new.published_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
drop trigger if exists listings_set_updated_at on public.listings;
create trigger listings_set_updated_at before update on public.listings
for each row execute function public.set_updated_at();
drop trigger if exists listings_set_publication_time on public.listings;
create trigger listings_set_publication_time before insert or update of status on public.listings
for each row execute function public.set_listing_publication_time();
drop trigger if exists conversations_set_updated_at on public.conversations;
create trigger conversations_set_updated_at before update on public.conversations
for each row execute function public.set_updated_at();

-- Create a public profile from trusted auth identity, taking only display data from signup metadata.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (
    new.id,
    coalesce(nullif(left(new.raw_user_meta_data ->> 'display_name', 80), ''), 'ALVO kullanıcısı')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;
revoke all on function public.handle_new_auth_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- SECURITY DEFINER avoids recursive conversation_members RLS checks. The fixed empty search_path
-- and fully qualified table name prevent search-path object substitution.
create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.conversation_members cm
    where cm.conversation_id = p_conversation_id
      and cm.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_conversation_member(uuid) from public, anon;
grant execute on function public.is_conversation_member(uuid) to authenticated;

-- Enable row-level security on every application table.
alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.listing_images enable row level security;
alter table public.favorites enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;

-- Profiles: all exposed fields are public profile fields; users can only change their own.
drop policy if exists profiles_public_read on public.profiles;
create policy profiles_public_read on public.profiles for select to anon, authenticated using (true);
drop policy if exists profiles_owner_update on public.profiles;
create policy profiles_owner_update on public.profiles for update to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Listings: published ads are discoverable; sellers retain access to their own drafts and records.
drop policy if exists listings_read_public_or_owner on public.listings;
create policy listings_read_public_or_owner on public.listings for select to anon, authenticated
using (status = 'active' or seller_id = (select auth.uid()));
drop policy if exists listings_owner_insert on public.listings;
create policy listings_owner_insert on public.listings for insert to authenticated
with check (seller_id = (select auth.uid()));
drop policy if exists listings_owner_update on public.listings;
create policy listings_owner_update on public.listings for update to authenticated
using (seller_id = (select auth.uid())) with check (seller_id = (select auth.uid()));
drop policy if exists listings_owner_delete on public.listings;
create policy listings_owner_delete on public.listings for delete to authenticated
using (seller_id = (select auth.uid()));

-- Image metadata can be seen with active listings or by the listing owner.
drop policy if exists listing_images_public_or_owner_read on public.listing_images;
create policy listing_images_public_or_owner_read on public.listing_images for select to anon, authenticated
using (exists (
  select 1 from public.listings l where l.id = listing_id
    and (l.status = 'active' or l.seller_id = (select auth.uid()))
));
drop policy if exists listing_images_owner_insert on public.listing_images;
create policy listing_images_owner_insert on public.listing_images for insert to authenticated
with check (
  split_part(storage_path, '/', 1) = (select auth.uid())::text
  and split_part(storage_path, '/', 2) = listing_id::text
  and exists (select 1 from public.listings l where l.id = listing_id and l.seller_id = (select auth.uid()))
);
drop policy if exists listing_images_owner_update on public.listing_images;
create policy listing_images_owner_update on public.listing_images for update to authenticated
using (exists (select 1 from public.listings l where l.id = listing_id and l.seller_id = (select auth.uid())))
with check (
  split_part(storage_path, '/', 1) = (select auth.uid())::text
  and split_part(storage_path, '/', 2) = listing_id::text
  and exists (select 1 from public.listings l where l.id = listing_id and l.seller_id = (select auth.uid()))
);
drop policy if exists listing_images_owner_delete on public.listing_images;
create policy listing_images_owner_delete on public.listing_images for delete to authenticated
using (exists (select 1 from public.listings l where l.id = listing_id and l.seller_id = (select auth.uid())));

-- Favorites are private to the account that created them; only active listings can be favorited.
drop policy if exists favorites_owner_read on public.favorites;
create policy favorites_owner_read on public.favorites for select to authenticated
using (user_id = (select auth.uid()));
drop policy if exists favorites_owner_insert on public.favorites;
create policy favorites_owner_insert on public.favorites for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (select 1 from public.listings l where l.id = listing_id and l.status = 'active')
);
drop policy if exists favorites_owner_delete on public.favorites;
create policy favorites_owner_delete on public.favorites for delete to authenticated
using (user_id = (select auth.uid()));

-- Conversation visibility is membership-based. Only the creator can create a conversation and
-- add its initial participants; no user can join a conversation by inserting themselves.
drop policy if exists conversations_member_read on public.conversations;
create policy conversations_member_read on public.conversations for select to authenticated
using (public.is_conversation_member(id));
drop policy if exists conversations_creator_insert on public.conversations;
create policy conversations_creator_insert on public.conversations for insert to authenticated
with check (created_by = (select auth.uid()));
drop policy if exists conversation_members_member_read on public.conversation_members;
create policy conversation_members_member_read on public.conversation_members for select to authenticated
using (public.is_conversation_member(conversation_id));
drop policy if exists conversation_members_creator_insert on public.conversation_members;
create policy conversation_members_creator_insert on public.conversation_members for insert to authenticated
with check (
  exists (
    select 1 from public.conversations c
    where c.id = conversation_id and c.created_by = (select auth.uid())
  )
);
drop policy if exists conversation_members_owner_update_read_marker on public.conversation_members;
create policy conversation_members_owner_update_read_marker on public.conversation_members for update to authenticated
using (user_id = (select auth.uid()) and public.is_conversation_member(conversation_id))
with check (user_id = (select auth.uid()) and public.is_conversation_member(conversation_id));
drop policy if exists conversation_members_owner_delete on public.conversation_members;
create policy conversation_members_owner_delete on public.conversation_members for delete to authenticated
using (user_id = (select auth.uid()));

-- No participant can read another conversation's messages; messages are append-only for clients.
drop policy if exists messages_member_read on public.messages;
create policy messages_member_read on public.messages for select to authenticated
using (public.is_conversation_member(conversation_id));
drop policy if exists messages_member_insert on public.messages;
create policy messages_member_insert on public.messages for insert to authenticated
with check (sender_id = (select auth.uid()) and public.is_conversation_member(conversation_id));

-- Reports are private to their reporter. Report status is not client-writable.
drop policy if exists reports_reporter_read on public.reports;
create policy reports_reporter_read on public.reports for select to authenticated
using (reporter_id = (select auth.uid()));
drop policy if exists reports_reporter_insert on public.reports;
create policy reports_reporter_insert on public.reports for insert to authenticated
with check (
  reporter_id = (select auth.uid())
  and status = 'pending'
  and case target_type
    when 'listing' then exists (select 1 from public.listings l where l.id = target_id and l.status = 'active')
    when 'profile' then target_id <> (select auth.uid()) and exists (select 1 from public.profiles p where p.user_id = target_id)
    when 'message' then exists (select 1 from public.messages m where m.id = target_id and public.is_conversation_member(m.conversation_id))
    else false
  end
);

-- Explicit grants keep the browser's anon/authenticated roles least-privileged.
revoke all on public.profiles, public.listings, public.listing_images, public.favorites,
  public.conversations, public.conversation_members, public.messages, public.reports
from anon, authenticated;

grant select on public.profiles to anon, authenticated;
grant update (username, display_name, avatar_path, bio, city) on public.profiles to authenticated;

grant select on public.listings to anon, authenticated;
grant insert (seller_id, title, description, price, category, city, district, status) on public.listings to authenticated;
grant update (title, description, price, category, city, district, status) on public.listings to authenticated;
grant delete on public.listings to authenticated;

grant select on public.listing_images to anon, authenticated;
grant insert (listing_id, storage_path, alt_text, sort_order) on public.listing_images to authenticated;
grant update (alt_text, sort_order) on public.listing_images to authenticated;
grant delete on public.listing_images to authenticated;

grant select, insert, delete on public.favorites to authenticated;

grant select, insert on public.conversations to authenticated;
grant select, insert, delete on public.conversation_members to authenticated;
grant update (last_read_at) on public.conversation_members to authenticated;
grant select, insert on public.messages to authenticated;
grant select, insert on public.reports to authenticated;

-- Private object bucket. Public images are served through Storage API policies only when
-- linked to an active listing; never make this bucket public (draft photos must stay private).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('listing-images', 'listing-images', false, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists alvo_listing_images_read on storage.objects;
create policy alvo_listing_images_read on storage.objects for select to anon, authenticated
using (
  bucket_id = 'listing-images'
  and (
    (select auth.uid()) is not null and (storage.foldername(name))[1] = (select auth.uid())::text
    or exists (
      select 1 from public.listing_images li
      join public.listings l on l.id = li.listing_id
      where li.storage_path = name and l.status = 'active'
    )
  )
);
drop policy if exists alvo_listing_images_upload on storage.objects;
create policy alvo_listing_images_upload on storage.objects for insert to authenticated
with check (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.listings l
    where l.id::text = (storage.foldername(name))[2]
      and l.seller_id = (select auth.uid())
  )
);
drop policy if exists alvo_listing_images_update on storage.objects;
create policy alvo_listing_images_update on storage.objects for update to authenticated
using (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.listings l
    where l.id::text = (storage.foldername(name))[2]
      and l.seller_id = (select auth.uid())
  )
);
drop policy if exists alvo_listing_images_delete on storage.objects;
create policy alvo_listing_images_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

commit;
