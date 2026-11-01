-- Licznik użytkowników. Uruchom raz w SQL Editor w Supabase, po schema.sql.
--
-- Każda instalacja zostawia najwyżej jeden wiersz dziennie z losowym
-- identyfikatorem. Nic tu nie wskazuje osoby ani jej postępu w aplikacji.
create table public.usage_days (
  day date not null default (now() at time zone 'utc')::date,
  install_id text not null check (install_id ~ '^[0-9a-f]{32}$'),
  platform text not null check (char_length(platform) between 1 and 20),
  app_version text not null check (char_length(app_version) between 1 and 20),
  primary key (day, install_id)
);

-- Bezpieczeństwo: klucz publiczny nie widzi tej tabeli i nie zapisuje do niej
-- wprost. Może tylko wywołać funkcję poniżej, która dodaje dzisiejszy wiersz.
alter table public.usage_days enable row level security;

revoke all on public.usage_days from anon, authenticated;

create function public.record_usage(
  p_install_id text,
  p_platform text,
  p_app_version text
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.usage_days (install_id, platform, app_version)
  values (p_install_id, p_platform, p_app_version)
  on conflict (day, install_id) do nothing;
$$;

revoke all on function public.record_usage(text, text, text) from public;
grant execute on function public.record_usage(text, text, text)
  to anon, authenticated;

-- Zestawienie do czytania w panelu Supabase: select * from public.usage_summary;
-- active_users to aktywni danego dnia, new_users to widziani po raz pierwszy.
create view public.usage_summary
  with (security_invoker = true)
as
  select
    day,
    count(*) as active_users,
    count(*) filter (
      where day = first_seen.day_one
    ) as new_users
  from public.usage_days
  join (
    select install_id, min(day) as day_one
    from public.usage_days
    group by install_id
  ) as first_seen using (install_id)
  group by day
  order by day desc;

revoke all on public.usage_summary from anon, authenticated;
