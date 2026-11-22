-- Liczba kliknięć w polecenia partnerskie. Uruchom raz w SQL Editor w Supabase,
-- po offers.sql i usage_02.sql. Bez tego pliku aplikacja nadal działa, a
-- serwer po prostu pomija nowe pole w raporcie.
--
-- Liczone są tylko kliknięcia osób, które zgodziły się na anonimowe
-- statystyki: identyfikator ciekawostki, bez adresu linku i bez identyfikatora
-- instalacji, tak jak pozostałe sumy w fact_stats.
alter table public.fact_stats
  add column offer_clicked bigint not null default 0;

create or replace function public.record_fact_stats(p_stats jsonb)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.fact_stats (
    fact_id, shown, liked, opened, shared, quiz_correct, quiz_wrong,
    offer_clicked
  )
  select
    stats.id,
    least(greatest(stats.shown, 0), 20),
    least(greatest(stats.liked, 0), 20),
    least(greatest(stats.opened, 0), 20),
    least(greatest(stats.shared, 0), 20),
    least(greatest(stats.quiz_correct, 0), 20),
    least(greatest(stats.quiz_wrong, 0), 20),
    least(greatest(coalesce(stats.offer_clicked, 0), 0), 20)
  from (
    select *
    from jsonb_to_recordset(p_stats) as item (
      id text, shown int, liked int, opened int, shared int,
      quiz_correct int, quiz_wrong int, offer_clicked int
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
    quiz_wrong = public.fact_stats.quiz_wrong + excluded.quiz_wrong,
    offer_clicked = public.fact_stats.offer_clicked + excluded.offer_clicked;
$$;
