-- AI Restaurant Chatbot schema for self-hosted Supabase/PostgreSQL.
-- Run in Supabase SQL editor or psql after setting up Supabase with Docker.

create extension if not exists "pgcrypto";

do $$ begin
  create type app_role as enum ('owner', 'kitchen_staff', 'reception_staff');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type account_status as enum ('active', 'inactive');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type menu_availability as enum ('available', 'sold_out');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type order_status as enum ('new', 'preparing', 'ready', 'completed', 'cancelled');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  role app_role not null,
  status account_status not null default 'active',
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.menu_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_th text not null default '',
  description text not null,
  description_th text not null default '',
  category text not null check (category in ('Starters', 'Main Courses', 'Drinks')),
  price numeric(10, 2) not null check (price >= 0),
  image_url text not null,
  ingredients text[] not null default '{}',
  ingredients_th text[] not null default '{}',
  allergens text[] not null default '{}',
  allergens_th text[] not null default '{}',
  dietary_tags text[] not null default '{}',
  dietary_tags_th text[] not null default '{}',
  taste_profile_tags text[] not null default '{}',
  taste_profile_tags_th text[] not null default '{}',
  spice_level text not null default 'None',
  availability_status menu_availability not null default 'available',
  metadata_complete boolean generated always as (
    name <> ''
    and category <> ''
    and price >= 0
    and array_length(ingredients, 1) is not null
    and array_length(taste_profile_tags, 1) is not null
    and image_url <> ''
  ) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.menu_items add column if not exists name_th text not null default '';
alter table public.menu_items add column if not exists description_th text not null default '';
alter table public.menu_items add column if not exists ingredients_th text[] not null default '{}';
alter table public.menu_items add column if not exists allergens_th text[] not null default '{}';
alter table public.menu_items add column if not exists dietary_tags_th text[] not null default '{}';
alter table public.menu_items add column if not exists taste_profile_tags_th text[] not null default '{}';

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  customer_session_id text,
  table_number text not null,
  customer_note text,
  preference_snapshot text[] not null default '{}',
  allergy_snapshot text[] not null default '{}',
  subtotal numeric(10, 2) not null default 0,
  service_fee numeric(10, 2) not null default 0,
  total_price numeric(10, 2) not null default 0,
  status order_status not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  menu_item_id uuid references public.menu_items(id) on delete set null,
  item_name_snapshot text not null,
  price_snapshot numeric(10, 2) not null,
  quantity integer not null check (quantity > 0),
  special_request text,
  allergens_snapshot text[] not null default '{}',
  dietary_tags_snapshot text[] not null default '{}',
  taste_profile_snapshot text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.chatbot_conversations (
  id uuid primary key default gen_random_uuid(),
  customer_session_id text,
  order_id uuid references public.orders(id) on delete set null,
  user_message text not null,
  bot_response text not null,
  related_menu_item_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

create index if not exists idx_menu_items_category on public.menu_items(category);
create index if not exists idx_menu_items_availability on public.menu_items(availability_status);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_orders_order_number on public.orders(order_number);
create index if not exists idx_order_items_order_id on public.order_items(order_id);

alter table public.profiles enable row level security;
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.chatbot_conversations enable row level security;

-- Demo-friendly policies. Tighten these for production.
create policy "Anyone can read available menu items" on public.menu_items
  for select using (true);

create policy "Authenticated owners manage menu items" on public.menu_items
  for all using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner' and p.status = 'active')
  );

create policy "Anyone can create orders" on public.orders
  for insert with check (true);

create policy "Anyone can read orders by app lookup" on public.orders
  for select using (true);

create policy "Authenticated staff and owners update orders" on public.orders
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.status = 'active')
  );

create policy "Anyone can create order items" on public.order_items
  for insert with check (true);

create policy "Anyone can read order items" on public.order_items
  for select using (true);

create policy "Owners manage staff profiles" on public.profiles
  for all using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner' and p.status = 'active')
  );

create policy "Users can read own profile" on public.profiles
  for select using (id = auth.uid());

create policy "Anyone can create chatbot messages" on public.chatbot_conversations
  for insert with check (true);

create policy "Owners can read chatbot conversations" on public.chatbot_conversations
  for select using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'owner' and p.status = 'active')
  );
