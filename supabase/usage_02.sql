-- Rozszerzony licznik. Uruchom raz w SQL Editor w Supabase, po usage.sql.
--
-- usage_days dostaje dzienne podsumowanie instalacji. fact_stats sumuje wyniki
-- ciekawostek i celowo nie ma identyfikatora instalacji, więc nie da się z
-- niego odczytać, kto co czytał.
alter table public.usage_days
  add column cards_completed int not null default 0
    check (cards_completed between 0 and 500),
  add column deck_finished boolean not null default false,
  add column quiz_correct int check (quiz_correct between 0 and 20),
  add column quiz_total int check (quiz_total between 0 and 20),
  add column bonus_rounds int not null default 0
    check (bonus_rounds between 0 and 100),
  add column streak_bucket text
    check (streak_bucket in ('0', '1-4', '5-9', '10+')),
  add column categories_changed boolean not null default false,
  add column reminders_enabled boolean,
  add column instructions text check (instructions in ('finished', 'skipped')),
  add column chose_all_categories boolean,
  add column notifications_allowed boolean;

-- Aplikacja wysyła sumy z całego dnia, więc nowszy raport zastępuje starszy.
create function public.record_usage_day(p_report jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.usage_days (
    day, install_id, platform, app_version, cards_completed, deck_finished,
    quiz_correct, quiz_total, bonus_rounds, streak_bucket, categories_changed,
    reminders_enabled, instructions, chose_all_categories,
    notifications_allowed
  )
  select
    report.day, report.install_id, report.platform, report.app_version,
    report.cards_completed, report.deck_finished, report.quiz_correct,
    report.quiz_total, report.bonus_rounds, report.streak_bucket,
    report.categories_changed, report.reminders_enabled, report.instructions,
    report.chose_all_categories, report.notifications_allowed
  from jsonb_to_record(p_report) as report (
    day date, install_id text, platform text, app_version text,
    cards_completed int, deck_finished boolean, quiz_correct int,
    quiz_total int, bonus_rounds int, streak_bucket text,
    categories_changed boolean, reminders_enabled boolean, instructions text,
    chose_all_categories boolean, notifications_allowed boolean
  )
  where report.day between current_date - 30 and current_date + 1
  on conflict (day, install_id) do update set
    app_version = excluded.app_version,
    cards_completed = excluded.cards_completed,
    deck_finished = excluded.deck_finished,
    quiz_correct = excluded.quiz_correct,
    quiz_total = excluded.quiz_total,
    bonus_rounds = excluded.bonus_rounds,
    streak_bucket = excluded.streak_bucket,
    categories_changed = excluded.categories_changed,
    reminders_enabled = excluded.reminders_enabled,
    instructions = excluded.instructions,
    chose_all_categories = excluded.chose_all_categories,
    notifications_allowed = excluded.notifications_allowed;
$$;

create table public.fact_stats (
  fact_id text primary key references public.facts (id) on delete cascade,
  shown bigint not null default 0,
  liked bigint not null default 0,
  opened bigint not null default 0,
  shared bigint not null default 0,
  quiz_correct bigint not null default 0,
  quiz_wrong bigint not null default 0
);

-- Dodaje wyniki z jednego raportu. Złączenie z facts pomija nieznane
-- identyfikatory, a limity ograniczają skutki sfałszowanego raportu.
create function public.record_fact_stats(p_stats jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.fact_stats (
    fact_id, shown, liked, opened, shared, quiz_correct, quiz_wrong
  )
  select
    stats.id,
    least(greatest(stats.shown, 0), 20),
    least(greatest(stats.liked, 0), 20),
    least(greatest(stats.opened, 0), 20),
    least(greatest(stats.shared, 0), 20),
    least(greatest(stats.quiz_correct, 0), 20),
    least(greatest(stats.quiz_wrong, 0), 20)
  from (
    select *
    from jsonb_to_recordset(p_stats) as item (
      id text, shown int, liked int, opened int, shared int,
      quiz_correct int, quiz_wrong int
    )
    limit 500
  ) as stats
  join public.facts on facts.id = stats.id
  on conflict (fact_id) do update set
    shown = public.fact_stats.shown + excluded.shown,
    liked = public.fact_stats.liked + excluded.liked,
    opened = public.fact_stats.opened + excluded.opened,
    shared = public.fact_stats.shared + excluded.shared,
    quiz_correct = public.fact_stats.quiz_correct + excluded.quiz_correct,
    quiz_wrong = public.fact_stats.quiz_wrong + excluded.quiz_wrong;
$$;

-- Bezpieczeństwo: klucz publiczny nie widzi tabel. Może tylko wywołać funkcje.
alter table public.fact_stats enable row level security;

revoke all on public.fact_stats from anon, authenticated;
revoke all on function public.record_usage_day(jsonb) from public;
revoke all on function public.record_fact_stats(jsonb) from public;
grant execute on function public.record_usage_day(jsonb)
  to anon, authenticated;
grant execute on function public.record_fact_stats(jsonb)
  to anon, authenticated;

-- Zestawienia do czytania w panelu Supabase.
-- select * from public.usage_daily;
create view public.usage_daily
  with (security_invoker = true)
as
  select
    day,
    count(*) as active_users,
    count(*) filter (where deck_finished) as finished_deck,
    round(avg(cards_completed), 1) as avg_cards,
    round(
      100.0 * sum(quiz_correct) / nullif(sum(quiz_total), 0), 1
    ) as quiz_correct_percent,
    sum(bonus_rounds) as bonus_rounds
  from public.usage_days
  group by day
  order by day desc;

-- select * from public.fact_ranking;
-- Najwyżej ciekawostki, które ludzie lubią i rozwijają. Niski quiz_percent
-- może oznaczać złe pytanie.
create view public.fact_ranking
  with (security_invoker = true)
as
  select
    facts.id,
    facts.title,
    facts.category,
    stats.shown,
    round(100.0 * stats.liked / nullif(stats.shown, 0), 1) as liked_percent,
    round(100.0 * stats.opened / nullif(stats.shown, 0), 1) as opened_percent,
    stats.shared,
    round(
      100.0 * stats.quiz_correct
        / nullif(stats.quiz_correct + stats.quiz_wrong, 0),
      1
    ) as quiz_percent
  from public.fact_stats as stats
  join public.facts on facts.id = stats.fact_id
  order by liked_percent desc nulls last;

revoke all on public.usage_daily, public.fact_ranking from anon, authenticated;
