-- ============================================================================
--  Inventory CRM — Supabase database schema
--  Run this ONCE in Supabase:  Dashboard -> SQL Editor -> New query -> paste -> Run
-- ============================================================================

-- 1) The inventory table (one row per item, per plant, per month snapshot)
create table if not exists public.inventory (
  id            bigint generated always as identity primary key,
  month         date,                       -- period / month-end of the snapshot
  item_code     text not null,
  description   text,
  plant         text,
  category      text,
  qty           numeric default 0,          -- stock quantity on hand
  unit_value    numeric default 0,          -- price per unit (optional)
  value         numeric default 0,          -- stock value (qty * unit_value, or given)
  last_movement date,                        -- last movement / issue date (optional)
  created_at    timestamptz default now()
);

-- helpful indexes
create index if not exists inventory_month_idx on public.inventory (month);
create index if not exists inventory_plant_idx on public.inventory (plant);
create index if not exists inventory_item_idx  on public.inventory (item_code);

-- 2) Security: turn on Row Level Security, allow any LOGGED-IN user full access.
--    (Single-client app: everyone who can log in works on the same data.)
alter table public.inventory enable row level security;

drop policy if exists "authenticated full access" on public.inventory;
create policy "authenticated full access"
  on public.inventory
  for all
  to authenticated
  using (true)
  with check (true);

-- 3) (Optional) a storage bucket to keep the ORIGINAL uploaded files.
--    Create it in the Supabase UI instead if you prefer: Storage -> New bucket -> name: uploads (private).
insert into storage.buckets (id, name, public)
values ('uploads', 'uploads', false)
on conflict (id) do nothing;

drop policy if exists "auth upload" on storage.objects;
create policy "auth upload" on storage.objects
  for all to authenticated
  using (bucket_id = 'uploads') with check (bucket_id = 'uploads');
