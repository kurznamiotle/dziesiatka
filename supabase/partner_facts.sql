-- Ciekawostki partnerskie: osobne karty napisane pod konkretny produkt.
-- Uruchom raz w SQL Editor w Supabase, po offers.sql i admin.sql.
--
-- Karta partnerska to nadal prawdziwa ciekawostka ze źródłem, ale zawsze ma
-- polecenie (offer) i stałą kategorię „Ciekawostka partnerska”. Bez tego pliku
-- aplikacja i panel działają dalej, tylko bez kart partnerskich.
--
-- Starsze wersje aplikacji (do 1.3.0 włącznie, a także 1.4.0+7 i +8) czytają
-- całą tabelę facts i potraktowałyby taką kartę jak zwykłą: z kategorią do
-- wyboru, w statystykach, osiągnięciach i powtórkach. Dlatego klucz publiczny
-- nie widzi już kart partnerskich w tabeli. Aplikacja od 1.4.0+9 pobiera je
-- osobno funkcją partner_facts(), a panel administratora nadal widzi wszystko.

insert into public.categories (name)
values ('Ciekawostka partnerska')
on conflict do nothing;

alter table public.facts
  add column kind text not null default 'regular'
    check (kind in ('regular', 'partner'));

-- Karta partnerska musi mieć polecenie i swoją kategorię, a zwykła nie może
-- tej kategorii używać.
alter table public.facts
  add constraint facts_partner_check check (
    (kind = 'partner') = (category = 'Ciekawostka partnerska')
    and (kind <> 'partner' or offer is not null)
  );

-- Wyzwalacz facts_set_updated_at z schema.sql działa przy każdej zmianie
-- wiersza, więc zmiana kind też podbija updated_at. Tworzymy go na nowo, żeby
-- było to pewne także w bazach zmienianych ręcznie.
drop trigger if exists facts_set_updated_at on public.facts;
create trigger facts_set_updated_at
  before update on public.facts
  for each row execute function public.set_updated_at();

-- Aplikacja (rola anon, a także zalogowane konto bez praw administratora)
-- czyta z tabeli tylko zwykłe ciekawostki. Polityka „Administrator czyta
-- wszystkie ciekawostki” z admin.sql zostaje, więc panel widzi też partnerskie.
-- Tabela categories nie jest widoczna dla klucza publicznego (schema.sql), więc
-- nowej kategorii nie trzeba tam ukrywać.
drop policy "Aplikacja czyta opublikowane i wycofane ciekawostki"
  on public.facts;

create policy "Aplikacja czyta opublikowane i wycofane ciekawostki"
  on public.facts
  for select
  to anon, authenticated
  using (status in ('published', 'withdrawn') and kind = 'regular');

-- Wszystkie karty partnerskie, które aplikacja może teraz pokazać:
-- opublikowane i z poleceniem ważnym jeszcze dziś (czas polski). Zwraca
-- zawsze pełną listę, więc karta wycofana lub po terminie po prostu z niej
-- znika, a aplikacja wtedy ją chowa. Daty porównujemy jako tekst RRRR-MM-DD,
-- żeby błędna data nie przerwała całego zapytania.
create function public.partner_facts()
returns setof public.facts
language sql
stable
security definer
set search_path = ''
as $$
  select *
  from public.facts
  where kind = 'partner'
    and status = 'published'
    and offer is not null
    and (
      offer ->> 'until' is null
      or offer ->> 'until' >=
        to_char(now() at time zone 'Europe/Warsaw', 'YYYY-MM-DD')
    )
  order by id
  limit 200;
$$;

revoke all on function public.partner_facts() from public;
grant execute on function public.partner_facts() to anon, authenticated;
