-- Panel administratora. Uruchom raz w SQL Editor w Supabase, po usage_02.sql.
--
-- Klucz publiczny nadal widzi tylko opublikowane i wycofane ciekawostki. Pełny
-- dostęp ma wyłącznie zalogowane konto wpisane do tabeli admins.
create table public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.admins enable row level security;

revoke all on public.admins from anon, authenticated;

create function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admins where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- review_note: powód wątpliwości przy szkicu. Znika przy publikacji.
-- rejected: odrzucony szkic. Zostaje w bazie, żeby nie wrócił z kolejną paczką,
-- ale aplikacja nigdy go nie pobiera.
alter table public.facts add column review_note text;

alter table public.facts drop constraint facts_status_check;
alter table public.facts add constraint facts_status_check
  check (status in ('draft', 'published', 'withdrawn', 'rejected'));

drop policy "Aplikacja czyta opublikowane i wycofane ciekawostki"
  on public.facts;

create policy "Aplikacja czyta opublikowane i wycofane ciekawostki"
  on public.facts
  for select
  to anon, authenticated
  using (status in ('published', 'withdrawn'));

create policy "Administrator czyta wszystkie ciekawostki"
  on public.facts for select to authenticated
  using (public.is_admin());

create policy "Administrator dodaje ciekawostki"
  on public.facts for insert to authenticated
  with check (public.is_admin());

create policy "Administrator zmienia ciekawostki"
  on public.facts for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant insert, update on public.facts to authenticated;

create policy "Administrator czyta kategorie"
  on public.categories for select to authenticated
  using (public.is_admin());

create policy "Administrator czyta statystyki dni"
  on public.usage_days for select to authenticated
  using (public.is_admin());

create policy "Administrator czyta statystyki ciekawostek"
  on public.fact_stats for select to authenticated
  using (public.is_admin());

grant select on public.categories, public.usage_days, public.fact_stats
  to authenticated;
