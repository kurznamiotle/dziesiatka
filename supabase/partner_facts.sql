-- Ciekawostki partnerskie: osobne karty napisane pod konkretny produkt.
-- Uruchom raz w SQL Editor w Supabase, po offers.sql.
--
-- Karta partnerska to nadal prawdziwa ciekawostka ze źródłem, ale zawsze ma
-- polecenie (offer) i stałą kategorię „Ciekawostka partnerska”. Starsze wersje
-- aplikacji nie znają kolumny kind, więc pokażą taką kartę jak zwykłą, z tą
-- nazwą w miejscu kategorii. Bez tego pliku aplikacja i panel działają dalej,
-- tylko bez kart partnerskich.

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
-- wiersza, więc zmiana kind też podbija updated_at i aplikacja ją pobierze.
-- Tworzymy go na nowo, żeby było to pewne także w bazach zmienianych ręcznie.
drop trigger if exists facts_set_updated_at on public.facts;
create trigger facts_set_updated_at
  before update on public.facts
  for each row execute function public.set_updated_at();
