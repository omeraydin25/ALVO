-- ALVO initial Supabase schema; safe for a clean project or the documented legacy listings table.
-- No credentials or service-role key belong in this migration.
begin;

-- Preserve the pre-existing ALVO listing table instead of letting IF NOT EXISTS
-- silently reuse an incompatible schema. A conflicting backup name aborts safely.
do $$
declare
  has_user_id boolean;
  has_image_url boolean;
  has_seller_id boolean;
begin
  if to_regclass('public.listings') is not null then
    select exists(select 1 from information_schema.columns where table_schema='public' and table_name='listings' and column_name='user_id'),
           exists(select 1 from information_schema.columns where table_schema='public' and table_name='listings' and column_name='image_url'),
           exists(select 1 from information_schema.columns where table_schema='public' and table_name='listings' and column_name='seller_id')
      into has_user_id, has_image_url, has_seller_id;

    if has_user_id and has_image_url and not has_seller_id then
      if to_regclass('public.listings_legacy_backup_20261108') is not null then
        raise exception 'Both legacy public.listings and public.listings_legacy_backup_20261108 exist. No table was renamed; inspect and manually preserve both before retrying.';
      end if;
      execute 'alter table public.listings rename to listings_legacy_backup_20261108';
    elsif not has_seller_id then
      raise exception 'public.listings exists with an unrecognized schema; migration stopped without changing or deleting it.';
    end if;
  end if;
end $$;

-- Lock down the preserved legacy table. Renaming retains all its rows and columns.
-- Remove old policies as well as inherited grants so a former public policy cannot
-- continue exposing the backup under its new name.
do $$
declare p record;
begin
  if to_regclass('public.listings_legacy_backup_20261108') is not null then
    for p in select policyname from pg_policies where schemaname='public' and tablename='listings_legacy_backup_20261108' loop
      execute format('drop policy %I on public.listings_legacy_backup_20261108', p.policyname);
    end loop;
    execute 'alter table public.listings_legacy_backup_20261108 enable row level security';
    execute 'alter table public.listings_legacy_backup_20261108 force row level security';
    execute 'revoke all on table public.listings_legacy_backup_20261108 from public, anon, authenticated';
  end if;
end $$;

create extension if not exists pgcrypto with schema extensions;
grant usage on schema public to anon, authenticated;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
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
create unique index if not exists profiles_username_lower_uidx on public.profiles(lower(username)) where username is not null;

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(user_id) on delete cascade,
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
  constraint listings_category_allowed check (category in ('Elektronik','Telefon','Bilgisayar','Ev ve Yaşam','Moda','Giyim','Araç','Yedek Parça','Spor','Hobi','Anne ve Bebek','Diğer')),
  constraint listings_city_length check (char_length(city) between 1 and 80),
  constraint listings_district_length check (district is null or char_length(district) <= 80),
  constraint listings_status_allowed check (status in ('draft','active','sold','archived'))
);
create index if not exists listings_public_feed_idx on public.listings(published_at desc,id desc) where status='active';
create index if not exists listings_seller_created_idx on public.listings(seller_id,created_at desc);
create index if not exists listings_category_feed_idx on public.listings(category,published_at desc) where status='active';
create index if not exists listings_city_feed_idx on public.listings(city,published_at desc) where status='active';

create table if not exists public.listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  storage_path text not null unique,
  alt_text text,
  sort_order smallint not null default 0,
  created_at timestamptz not null default now(),
  constraint listing_images_path_shape check (storage_path !~ '(^/|(^|/)\.\.?(/|$)|\\|//)' and char_length(storage_path)<=500),
  constraint listing_images_alt_length check (alt_text is null or char_length(alt_text)<=200),
  constraint listing_images_sort_order check (sort_order between 0 and 99)
);
create index if not exists listing_images_listing_order_idx on public.listing_images(listing_id,sort_order,created_at);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  listing_id uuid not null references public.listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id,listing_id)
);
create index if not exists favorites_listing_idx on public.favorites(listing_id);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(user_id) on delete restrict,
  listing_id uuid not null references public.listings(id) on delete cascade,
  kind text not null default 'direct',
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint conversations_kind_allowed check (kind='direct'),
  constraint conversations_title_length check (title is null or char_length(title) between 1 and 120)
);
create index if not exists conversations_listing_idx on public.conversations(listing_id,created_at desc);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key(conversation_id,user_id)
);
create index if not exists conversation_members_user_idx on public.conversation_members(user_id,joined_at desc);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(user_id) on delete restrict,
  body text not null,
  created_at timestamptz not null default now(),
  constraint messages_body_length check (char_length(body) between 1 and 5000)
);
create index if not exists messages_conversation_timeline_idx on public.messages(conversation_id,created_at desc,id desc);
create index if not exists messages_sender_idx on public.messages(sender_id,created_at desc);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(user_id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  reason text not null,
  details text,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  constraint reports_target_type_allowed check (target_type in ('listing','profile','message')),
  constraint reports_reason_length check (char_length(reason) between 3 and 120),
  constraint reports_details_length check (details is null or char_length(details)<=3000),
  constraint reports_status_allowed check (status in ('pending','reviewing','resolved','rejected'))
);
create index if not exists reports_reporter_created_idx on public.reports(reporter_id,created_at desc);
create index if not exists reports_moderation_queue_idx on public.reports(status,created_at asc);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path=''
as $$ begin new.updated_at:=now(); return new; end $$;

create or replace function public.set_listing_publication_time()
returns trigger language plpgsql set search_path=''
as $$
begin
  if new.status='active' and (tg_op='INSERT' or old.status is distinct from 'active') then new.published_at:=now();
  elsif new.status<>'active' then new.published_at:=null; end if;
  return new;
end $$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists listings_set_updated_at on public.listings;
create trigger listings_set_updated_at before update on public.listings for each row execute function public.set_updated_at();
drop trigger if exists listings_set_publication_time on public.listings;
create trigger listings_set_publication_time before insert or update of status on public.listings for each row execute function public.set_listing_publication_time();
drop trigger if exists conversations_set_updated_at on public.conversations;
create trigger conversations_set_updated_at before update on public.conversations for each row execute function public.set_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger language plpgsql security definer set search_path=''
as $$
begin
  insert into public.profiles(user_id,display_name)
  values(new.id,coalesce(nullif(left(new.raw_user_meta_data->>'display_name',80),''),'ALVO kullanıcısı'))
  on conflict(user_id) do nothing;
  return new;
end $$;
revoke all on function public.handle_new_auth_user() from public,anon,authenticated;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_auth_user();

create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.conversation_members cm where cm.conversation_id=p_conversation_id and cm.user_id=(select auth.uid())) $$;
revoke all on function public.is_conversation_member(uuid) from public,anon;
grant execute on function public.is_conversation_member(uuid) to authenticated;

-- Secure, atomic direct conversation creation; clients cannot add arbitrary members.
create or replace function public.start_listing_conversation(p_listing_id uuid)
returns uuid language plpgsql security definer set search_path=''
as $$
declare
  v_buyer uuid := auth.uid();
  v_seller uuid;
  v_conversation uuid;
begin
  if v_buyer is null then raise exception 'Authentication required'; end if;
  select seller_id into v_seller from public.listings where id=p_listing_id and status='active';
  if v_seller is null then raise exception 'Active listing not found'; end if;
  if v_seller=v_buyer then raise exception 'Seller cannot message themselves'; end if;
  select c.id into v_conversation
  from public.conversations c
  join public.conversation_members buyer on buyer.conversation_id=c.id and buyer.user_id=v_buyer
  join public.conversation_members seller on seller.conversation_id=c.id and seller.user_id=v_seller
  where c.listing_id=p_listing_id and c.kind='direct'
  limit 1;
  if v_conversation is null then
    insert into public.conversations(created_by,listing_id,kind) values(v_buyer,p_listing_id,'direct') returning id into v_conversation;
    insert into public.conversation_members(conversation_id,user_id) values(v_conversation,v_buyer),(v_conversation,v_seller);
  end if;
  return v_conversation;
end $$;
revoke all on function public.start_listing_conversation(uuid) from public,anon;
grant execute on function public.start_listing_conversation(uuid) to authenticated;

create or replace function public.touch_conversation_from_message()
returns trigger language plpgsql security definer set search_path=''
as $$ begin update public.conversations set updated_at=now() where id=new.conversation_id; return new; end $$;
drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation after insert on public.messages for each row execute function public.touch_conversation_from_message();

-- RLS is enabled on all eight application tables.
alter table public.profiles enable row level security;
alter table public.listings enable row level security;
alter table public.listing_images enable row level security;
alter table public.favorites enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;

-- Remove same-named policies from an earlier ALVO attempt before defining the audited set.
do $$
declare t text; p record;
begin
  foreach t in array array['profiles','listings','listing_images','favorites','conversations','conversation_members','messages','reports'] loop
    for p in select policyname from pg_policies where schemaname='public' and tablename=t loop
      execute format('drop policy %I on public.%I',p.policyname,t);
    end loop;
  end loop;
end $$;

create policy profiles_public_read on public.profiles for select to anon,authenticated using(true);
create policy profiles_owner_update on public.profiles for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));

create policy listings_read_public_or_owner on public.listings for select to anon,authenticated using(status='active' or seller_id=(select auth.uid()));
create policy listings_owner_insert on public.listings for insert to authenticated with check(seller_id=(select auth.uid()));
create policy listings_owner_update on public.listings for update to authenticated using(seller_id=(select auth.uid())) with check(seller_id=(select auth.uid()));
create policy listings_owner_delete on public.listings for delete to authenticated using(seller_id=(select auth.uid()));

create policy listing_images_public_or_owner_read on public.listing_images for select to anon,authenticated using(exists(select 1 from public.listings l where l.id=listing_id and (l.status='active' or l.seller_id=(select auth.uid()))));
create policy listing_images_owner_insert on public.listing_images for insert to authenticated with check(
  split_part(storage_path,'/',1)=(select auth.uid())::text and split_part(storage_path,'/',2)=listing_id::text
  and exists(select 1 from public.listings l where l.id=listing_id and l.seller_id=(select auth.uid())));
create policy listing_images_owner_update on public.listing_images for update to authenticated using(exists(select 1 from public.listings l where l.id=listing_id and l.seller_id=(select auth.uid()))) with check(
  split_part(storage_path,'/',1)=(select auth.uid())::text and split_part(storage_path,'/',2)=listing_id::text
  and exists(select 1 from public.listings l where l.id=listing_id and l.seller_id=(select auth.uid())));
create policy listing_images_owner_delete on public.listing_images for delete to authenticated using(exists(select 1 from public.listings l where l.id=listing_id and l.seller_id=(select auth.uid())));

create policy favorites_owner_read on public.favorites for select to authenticated using(user_id=(select auth.uid()));
create policy favorites_owner_insert on public.favorites for insert to authenticated with check(user_id=(select auth.uid()) and exists(select 1 from public.listings l where l.id=listing_id and l.status='active'));
create policy favorites_owner_delete on public.favorites for delete to authenticated using(user_id=(select auth.uid()));

create policy conversations_member_read on public.conversations for select to authenticated using(public.is_conversation_member(id));
create policy conversation_members_member_read on public.conversation_members for select to authenticated using(public.is_conversation_member(conversation_id));
create policy conversation_members_owner_update_read_marker on public.conversation_members for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy messages_member_read on public.messages for select to authenticated using(public.is_conversation_member(conversation_id));
create policy messages_member_insert on public.messages for insert to authenticated with check(sender_id=(select auth.uid()) and public.is_conversation_member(conversation_id));

create policy reports_reporter_read on public.reports for select to authenticated using(reporter_id=(select auth.uid()));
create policy reports_reporter_insert on public.reports for insert to authenticated with check(
  reporter_id=(select auth.uid()) and status='pending' and case target_type
    when 'listing' then exists(select 1 from public.listings l where l.id=target_id and l.status='active')
    when 'profile' then target_id<>(select auth.uid()) and exists(select 1 from public.profiles p where p.user_id=target_id)
    when 'message' then exists(select 1 from public.messages m where m.id=target_id and public.is_conversation_member(m.conversation_id))
    else false end);

-- Explicit least-privilege grants; protected owner/role/timestamp fields cannot be client-updated.
revoke all on public.profiles,public.listings,public.listing_images,public.favorites,public.conversations,public.conversation_members,public.messages,public.reports from public,anon,authenticated;
grant select on public.profiles to anon,authenticated;
grant update(username,display_name,avatar_path,bio,city) on public.profiles to authenticated;
grant select on public.listings to anon,authenticated;
grant insert(seller_id,title,description,price,category,city,district,status) on public.listings to authenticated;
grant update(title,description,price,category,city,district,status) on public.listings to authenticated;
grant delete on public.listings to authenticated;
grant select on public.listing_images to anon,authenticated;
grant insert(listing_id,storage_path,alt_text,sort_order) on public.listing_images to authenticated;
grant update(alt_text,sort_order) on public.listing_images to authenticated;
grant delete on public.listing_images to authenticated;
grant select,insert,delete on public.favorites to authenticated;
grant select on public.conversations to authenticated;
grant select,update(last_read_at) on public.conversation_members to authenticated;
grant select,insert on public.messages to authenticated;
grant select,insert on public.reports to authenticated;

-- Private Storage bucket. Enforce private settings even if an earlier bucket exists.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('listing-images','listing-images',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists alvo_listing_images_read on storage.objects;
drop policy if exists alvo_listing_images_upload on storage.objects;
drop policy if exists alvo_listing_images_update on storage.objects;
drop policy if exists alvo_listing_images_delete on storage.objects;
create policy alvo_listing_images_read on storage.objects for select to anon,authenticated using(
  bucket_id='listing-images' and (
    ((select auth.uid()) is not null and (storage.foldername(name))[1]=(select auth.uid())::text)
    or exists(select 1 from public.listing_images li join public.listings l on l.id=li.listing_id where li.storage_path=name and l.status='active')
  ));
create policy alvo_listing_images_upload on storage.objects for insert to authenticated with check(
  bucket_id='listing-images' and (storage.foldername(name))[1]=(select auth.uid())::text
  and exists(select 1 from public.listings l where l.id::text=(storage.foldername(name))[2] and l.seller_id=(select auth.uid())));
create policy alvo_listing_images_update on storage.objects for update to authenticated using(
  bucket_id='listing-images' and (storage.foldername(name))[1]=(select auth.uid())::text
) with check(
  bucket_id='listing-images' and (storage.foldername(name))[1]=(select auth.uid())::text
  and exists(select 1 from public.listings l where l.id::text=(storage.foldername(name))[2] and l.seller_id=(select auth.uid())));
create policy alvo_listing_images_delete on storage.objects for delete to authenticated using(
  bucket_id='listing-images' and (storage.foldername(name))[1]=(select auth.uid())::text);

commit;
