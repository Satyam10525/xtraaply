-- Xtraaplywood Supabase schema
-- Apply this in the Supabase SQL editor after creating your project.

create extension if not exists pgcrypto;

-- Profiles ---------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null default 'customer' check (role in ('customer', 'admin')),
  loyalty_tier text not null default 'bronze' check (loyalty_tier in ('bronze', 'silver', 'gold', 'platinum')),
  total_points_earned integer not null default 0 check (total_points_earned >= 0),
  current_points_balance integer not null default 0 check (current_points_balance >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Catalog ----------------------------------------------------------------
create table if not exists public.product_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.product_categories(id) on delete set null,
  name text not null,
  slug text not null unique,
  description text,
  grade text,
  points_per_scan integer not null default 0 check (points_per_scan >= 0),
  stock_status text not null default 'in_stock' check (stock_status in ('in_stock', 'limited', 'enquire')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  label text not null,
  sku text unique,
  created_at timestamptz not null default now()
);

-- Rewards ----------------------------------------------------------------
create table if not exists public.rewards (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  points_cost integer not null check (points_cost > 0),
  tier_required text check (tier_required in ('bronze', 'silver', 'gold', 'platinum')),
  is_active boolean not null default true,
  stock_qty integer,
  created_at timestamptz not null default now()
);

create table if not exists public.reward_claims (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reward_id uuid not null references public.rewards(id) on delete restrict,
  points_cost integer not null check (points_cost > 0),
  status text not null default 'pending' check (status in ('pending', 'approved', 'delivered', 'cancelled')),
  claim_code text not null unique default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12)),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- QR codes and ledger ----------------------------------------------------
create table if not exists public.qr_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  product_id uuid not null references public.products(id) on delete cascade,
  product_variant_id uuid references public.product_variants(id) on delete set null,
  points_value integer not null check (points_value > 0),
  status text not null default 'active' check (status in ('active', 'redeemed', 'blocked')),
  redeemed_by uuid references public.profiles(id) on delete set null,
  redeemed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.point_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  qr_code_id uuid references public.qr_codes(id) on delete set null,
  reward_id uuid references public.rewards(id) on delete set null,
  type text not null check (type in ('earn', 'redeem', 'adjust', 'expire')),
  points_delta integer not null,
  description text,
  created_at timestamptz not null default now()
);

-- Enquiries --------------------------------------------------------------
create table if not exists public.enquiries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  full_name text not null,
  phone text not null,
  email text,
  product_id uuid references public.products(id) on delete set null,
  order_type text,
  quantity_requirement text,
  message text not null,
  status text not null default 'new' check (status in ('new', 'contacted', 'closed')),
  created_at timestamptz not null default now()
);

-- Utility functions ------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.update_timestamp()
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
for each row execute procedure public.update_timestamp();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute procedure public.update_timestamp();

drop trigger if exists reward_claims_set_updated_at on public.reward_claims;
create trigger reward_claims_set_updated_at
before update on public.reward_claims
for each row execute procedure public.update_timestamp();

create or replace function public.calculate_loyalty_tier(total_points integer)
returns text
language sql
immutable
as $$
  select case
    when total_points >= 2500 then 'platinum'
    when total_points >= 1000 then 'gold'
    when total_points >= 500 then 'silver'
    else 'bronze'
  end;
$$;

create or replace function public.redeem_qr_code(input_code text)
returns table (
  product_name text,
  points_added integer,
  new_balance integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
  qr_row public.qr_codes%rowtype;
  current_balance integer;
  new_total_earned integer;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into qr_row
  from public.qr_codes
  where code = upper(trim(input_code))
  for update;

  if not found then
    raise exception 'Invalid QR code';
  end if;

  if qr_row.status <> 'active' then
    raise exception 'QR code is not available for redemption';
  end if;

  update public.qr_codes
  set status = 'redeemed',
      redeemed_by = current_user_id,
      redeemed_at = now()
  where id = qr_row.id;

  insert into public.point_transactions (
    user_id,
    qr_code_id,
    type,
    points_delta,
    description
  ) values (
    current_user_id,
    qr_row.id,
    'earn',
    qr_row.points_value,
    'QR code redeemed'
  );

  update public.profiles
  set current_points_balance = current_points_balance + qr_row.points_value,
      total_points_earned = total_points_earned + qr_row.points_value,
      loyalty_tier = public.calculate_loyalty_tier(total_points_earned + qr_row.points_value)
  where id = current_user_id
  returning current_points_balance, total_points_earned
  into current_balance, new_total_earned;

  return query
  select p.name, qr_row.points_value, current_balance
  from public.products p
  where p.id = qr_row.product_id;
end;
$$;

create or replace function public.claim_reward(input_reward_id uuid)
returns table (
  reward_name text,
  points_spent integer,
  new_balance integer,
  claim_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
  reward_row public.rewards%rowtype;
  profile_row public.profiles%rowtype;
  new_claim public.reward_claims%rowtype;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into profile_row
  from public.profiles
  where id = current_user_id
  for update;

  select *
  into reward_row
  from public.rewards
  where id = input_reward_id
    and is_active = true
  for update;

  if not found then
    raise exception 'Reward not found';
  end if;

  if reward_row.tier_required is not null then
    if reward_row.tier_required = 'silver' and profile_row.total_points_earned < 500 then
      raise exception 'Silver tier required';
    elsif reward_row.tier_required = 'gold' and profile_row.total_points_earned < 1000 then
      raise exception 'Gold tier required';
    elsif reward_row.tier_required = 'platinum' and profile_row.total_points_earned < 2500 then
      raise exception 'Platinum tier required';
    end if;
  end if;

  if profile_row.current_points_balance < reward_row.points_cost then
    raise exception 'Not enough points';
  end if;

  if reward_row.stock_qty is not null and reward_row.stock_qty <= 0 then
    raise exception 'Reward is out of stock';
  end if;

  insert into public.reward_claims (
    user_id,
    reward_id,
    points_cost
  ) values (
    current_user_id,
    reward_row.id,
    reward_row.points_cost
  )
  returning * into new_claim;

  insert into public.point_transactions (
    user_id,
    reward_id,
    type,
    points_delta,
    description
  ) values (
    current_user_id,
    reward_row.id,
    'redeem',
    reward_row.points_cost * -1,
    'Reward claimed'
  );

  update public.profiles
  set current_points_balance = current_points_balance - reward_row.points_cost
  where id = current_user_id;

  if reward_row.stock_qty is not null then
    update public.rewards
    set stock_qty = stock_qty - 1
    where id = reward_row.id;
  end if;

  return query
  select reward_row.name, reward_row.points_cost, profile_row.current_points_balance - reward_row.points_cost, new_claim.claim_code;
end;
$$;

-- RLS --------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.product_categories enable row level security;
alter table public.products enable row level security;
alter table public.product_variants enable row level security;
alter table public.rewards enable row level security;
alter table public.reward_claims enable row level security;
alter table public.qr_codes enable row level security;
alter table public.point_transactions enable row level security;
alter table public.enquiries enable row level security;

-- Profiles
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
to authenticated
using (auth.uid() = id or public.is_admin());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (auth.uid() = id or public.is_admin())
with check (auth.uid() = id or public.is_admin());

-- Public catalog reads
drop policy if exists "categories_public_read" on public.product_categories;
create policy "categories_public_read"
on public.product_categories
for select
to anon, authenticated
using (true);

drop policy if exists "products_public_read" on public.products;
create policy "products_public_read"
on public.products
for select
to anon, authenticated
using (is_active = true or public.is_admin());

drop policy if exists "variants_public_read" on public.product_variants;
create policy "variants_public_read"
on public.product_variants
for select
to anon, authenticated
using (true);

drop policy if exists "rewards_public_read" on public.rewards;
create policy "rewards_public_read"
on public.rewards
for select
to anon, authenticated
using (is_active = true or public.is_admin());

-- Enquiries
drop policy if exists "enquiries_public_insert" on public.enquiries;
create policy "enquiries_public_insert"
on public.enquiries
for insert
to anon, authenticated
with check (true);

drop policy if exists "enquiries_user_read" on public.enquiries;
create policy "enquiries_user_read"
on public.enquiries
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists "enquiries_admin_update" on public.enquiries;
create policy "enquiries_admin_update"
on public.enquiries
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Reward claims and points
drop policy if exists "claims_user_read" on public.reward_claims;
create policy "claims_user_read"
on public.reward_claims
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

drop policy if exists "claims_admin_update" on public.reward_claims;
create policy "claims_admin_update"
on public.reward_claims
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "transactions_user_read" on public.point_transactions;
create policy "transactions_user_read"
on public.point_transactions
for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

-- QR codes are server-controlled only
drop policy if exists "qr_admin_read" on public.qr_codes;
create policy "qr_admin_read"
on public.qr_codes
for select
to authenticated
using (public.is_admin());
