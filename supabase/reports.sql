-- Zgłoszenia błędów w ciekawostkach. Uruchom raz w SQL Editor w Supabase, po
-- admin.sql.
--
-- Zgłoszenie nie ma identyfikatora czytelnika. Klucz publiczny może je tylko
-- wysłać, a czytać i usuwać je może wyłącznie administrator.
create table public.fact_reports (
  id bigint generated always as identity primary key,
  fact_id text not null references public.facts (id) on delete cascade,
  reason text not null
    check (reason in ('wrong_fact', 'language', 'source', 'other')),
  comment text check (char_length(comment) <= 500),
  created_at timestamptz not null default now()
);

create index fact_reports_created_at_idx
  on public.fact_reports (created_at);

-- Złączenie z facts pomija nieznane identyfikatory, a limit na godzinę
-- ogranicza skutki zalania bazy zgłoszeniami przez publiczny klucz.
create function public.report_fact(
  p_fact_id text,
  p_reason text,
  p_comment text
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.fact_reports (fact_id, reason, comment)
  select facts.id, p_reason, nullif(left(btrim(p_comment), 500), '')
  from public.facts
  where facts.id = p_fact_id
    and (
      select count(*)
      from public.fact_reports
      where created_at > now() - interval '1 hour'
    ) < 200;
$$;

-- Bezpieczeństwo: klucz publiczny nie widzi tabeli. Może tylko wywołać funkcję.
alter table public.fact_reports enable row level security;

revoke all on public.fact_reports from anon, authenticated;
revoke all on function public.report_fact(text, text, text) from public;
grant execute on function public.report_fact(text, text, text)
  to anon, authenticated;

create policy "Administrator czyta zgłoszenia"
  on public.fact_reports for select to authenticated
  using (public.is_admin());

create policy "Administrator usuwa zgłoszenia"
  on public.fact_reports for delete to authenticated
  using (public.is_admin());

grant select, delete on public.fact_reports to authenticated;
