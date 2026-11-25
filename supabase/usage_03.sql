-- Dzień w statystykach liczony na serwerze, w czasie polskim. Uruchom raz w
-- SQL Editor w Supabase, po usage_02.sql. Można uruchomić ponownie.
--
-- Dotąd dzień brał się z zegara urządzenia, więc telefon w innej strefie
-- czasowej (albo robot testowy Google Play) potrafił zapisać „jutro”, zanim
-- w Polsce minęła północ. Kolumna day zostaje jako dzień urządzenia, bo to po
-- nim aplikacja łączy kolejne raporty z tego samego dnia, także w starszych
-- wersjach (1.3 i wcześniejsze). Panel liczy jednak po nowej kolumnie
-- warsaw_day, którą ustawia wyłącznie serwer przy pierwszym zapisie wiersza.

-- Najstarsze wersje wołają record_usage i polegają na wartości domyślnej.
alter table public.usage_days
  alter column day set default (now() at time zone 'Europe/Warsaw')::date;

alter table public.usage_days
  add column if not exists warsaw_day date;

-- Dotychczasowe wiersze: dzień urządzenia, ale nigdy później niż dziś w Polsce.
update public.usage_days
set warsaw_day = least(day, (now() at time zone 'Europe/Warsaw')::date)
where warsaw_day is null;

alter table public.usage_days
  alter column warsaw_day set default (now() at time zone 'Europe/Warsaw')::date,
  alter column warsaw_day set not null;

create index if not exists usage_days_warsaw_day_idx
  on public.usage_days (warsaw_day);

-- Raport z bieżącego dnia dostaje dzisiejszą datę w Polsce. Raport spóźniony
-- (urządzenie było bez sieci) dostaje ją cofniętą o tyle dni, o ile był
-- spóźniony. Od wersji 1.4.0+10 aplikacja podaje sent_on, czyli swój dzień w
-- chwili wysyłki, więc spóźnienie jest dokładne. Starsze wersje go nie znają:
-- wtedy dzień z przyszłości staje się dzisiejszym, a reszta zostaje.
-- Przy kolejnych raportach z tego samego dnia warsaw_day się nie zmienia.
create or replace function public.record_usage_day(p_report jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  with today as (
    select (now() at time zone 'Europe/Warsaw')::date as pl
  )
  insert into public.usage_days (
    day, warsaw_day, install_id, platform, app_version, cards_completed,
    deck_finished, quiz_correct, quiz_total, bonus_rounds, streak_bucket,
    categories_changed, reminders_enabled, instructions, chose_all_categories,
    notifications_allowed
  )
  select
    report.day,
    case
      when report.sent_on is not null
        then today.pl - least(greatest(report.sent_on - report.day, 0), 30)
      else least(report.day, today.pl)
    end,
    report.install_id, report.platform, report.app_version,
    report.cards_completed, report.deck_finished, report.quiz_correct,
    report.quiz_total, report.bonus_rounds, report.streak_bucket,
    report.categories_changed, report.reminders_enabled, report.instructions,
    report.chose_all_categories, report.notifications_allowed
  from jsonb_to_record(p_report) as report (
    day date, sent_on date, install_id text, platform text, app_version text,
    cards_completed int, deck_finished boolean, quiz_correct int,
    quiz_total int, bonus_rounds int, streak_bucket text,
    categories_changed boolean, reminders_enabled boolean, instructions text,
    chose_all_categories boolean, notifications_allowed boolean
  )
  cross join today
  -- +1, bo urządzenie przed Polską w strefie czasowej ma już jutro.
  where report.day between today.pl - 30 and today.pl + 1
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

revoke all on function public.record_usage_day(jsonb) from public;
grant execute on function public.record_usage_day(jsonb)
  to anon, authenticated;

-- Zestawienia w panelu Supabase liczą teraz po dniu polskim. Urządzenie z
-- innej strefy może mieć dwa swoje dni w jednym polskim, więc użytkownicy są
-- liczeni bez powtórzeń.
create or replace view public.usage_summary
  with (security_invoker = true)
as
  select
    warsaw_day as day,
    count(distinct install_id) as active_users,
    count(distinct install_id) filter (
      where warsaw_day = first_seen.day_one
    ) as new_users
  from public.usage_days
  join (
    select install_id, min(warsaw_day) as day_one
    from public.usage_days
    group by install_id
  ) as first_seen using (install_id)
  group by warsaw_day
  order by warsaw_day desc;

create or replace view public.usage_daily
  with (security_invoker = true)
as
  select
    warsaw_day as day,
    count(distinct install_id) as active_users,
    count(distinct install_id) filter (where deck_finished) as finished_deck,
    round(sum(cards_completed)::numeric / count(distinct install_id), 1)
      as avg_cards,
    round(
      100.0 * sum(quiz_correct) / nullif(sum(quiz_total), 0), 1
    ) as quiz_correct_percent,
    sum(bonus_rounds) as bonus_rounds
  from public.usage_days
  group by warsaw_day
  order by warsaw_day desc;

revoke all on public.usage_summary, public.usage_daily from anon, authenticated;
