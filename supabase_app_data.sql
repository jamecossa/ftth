-- Registo FTTH: base de dados (versao com gastos, recibos e seguranca reforcada)
-- Cola isto em Supabase > SQL Editor > New query e clica em Run.
-- Pode ser executado mais de uma vez sem dar erro e sem apagar dados.

-- 1) Dados de cada utilizador (perfil, servicos, registos diarios e gastos)
create table if not exists public.app_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  profile jsonb not null default '{}'::jsonb,
  services jsonb not null default '[]'::jsonb,
  records jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

-- coluna dos gastos (portagem e alimentacao); nao faz nada se ja existir
alter table public.app_data add column if not exists expenses jsonb not null default '[]'::jsonb;

-- Limites e tipos: impede dados malformados ou gigantes
alter table public.app_data drop constraint if exists app_data_limites;
alter table public.app_data add constraint app_data_limites check (
  jsonb_typeof(profile) = 'object'
  and jsonb_typeof(services) = 'array'
  and jsonb_typeof(records) = 'array'
  and jsonb_typeof(expenses) = 'array'
  and jsonb_array_length(services) <= 500
  and jsonb_array_length(records) <= 50000
  and jsonb_array_length(expenses) <= 20000
  and pg_column_size(profile) < 200000
  and pg_column_size(services) < 500000
  and pg_column_size(records) < 8000000
  and pg_column_size(expenses) < 4000000
);

-- Seguranca por linha: cada pessoa so ve e altera os seus proprios dados
alter table public.app_data enable row level security;

drop policy if exists "ver os proprios dados" on public.app_data;
drop policy if exists "criar os proprios dados" on public.app_data;
drop policy if exists "alterar os proprios dados" on public.app_data;
drop policy if exists "apagar os proprios dados" on public.app_data;

create policy "ver os proprios dados" on public.app_data
  for select to authenticated
  using (auth.uid() = user_id);

create policy "criar os proprios dados" on public.app_data
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "alterar os proprios dados" on public.app_data
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "apagar os proprios dados" on public.app_data
  for delete to authenticated
  using (auth.uid() = user_id);

revoke all on public.app_data from anon;
revoke all on public.app_data from public;
grant select, insert, update, delete on public.app_data to authenticated;

-- 2) Fotos dos recibos (uma por gasto, guardadas em separado para a app ser rapida)
create table if not exists public.receipts (
  user_id uuid not null references auth.users(id) on delete cascade,
  expense_id text not null,
  photo text not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, expense_id),
  constraint receipts_limites check (
    char_length(expense_id) between 1 and 40
    and expense_id ~ '^[A-Za-z0-9_-]+$'
    and char_length(photo) < 800000
    and photo ~ '^data:image/jpeg.base64,'
  )
);

alter table public.receipts enable row level security;

drop policy if exists "ver os proprios recibos" on public.receipts;
drop policy if exists "criar os proprios recibos" on public.receipts;
drop policy if exists "alterar os proprios recibos" on public.receipts;
drop policy if exists "apagar os proprios recibos" on public.receipts;

create policy "ver os proprios recibos" on public.receipts
  for select to authenticated
  using (auth.uid() = user_id);

create policy "criar os proprios recibos" on public.receipts
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy "alterar os proprios recibos" on public.receipts
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "apagar os proprios recibos" on public.receipts
  for delete to authenticated
  using (auth.uid() = user_id);

revoke all on public.receipts from anon;
revoke all on public.receipts from public;
grant select, insert, update, delete on public.receipts to authenticated;
