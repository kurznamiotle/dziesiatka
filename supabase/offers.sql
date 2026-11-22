-- Polecenia partnerskie przy ciekawostkach (afiliacja, np. TradeTracker).
-- Uruchom raz w SQL Editor w Supabase, po schema.sql.
-- Polecenie jest w tej samej tabeli co ciekawostka, więc jego zmiana podbija
-- updated_at i aplikacja pobierze ją przy zwykłej synchronizacji.
alter table public.facts
  add column offer jsonb check (
    offer is null or (
      jsonb_typeof(offer -> 'product') = 'string'
      and char_length(btrim(offer ->> 'product')) between 1 and 80
      and jsonb_typeof(offer -> 'shop') = 'string'
      and char_length(btrim(offer ->> 'shop')) between 1 and 40
      and jsonb_typeof(offer -> 'url') = 'string'
      and (offer ->> 'url') ~ '^https://'
      and (offer -> 'until' is null or (offer ->> 'until') ~ '^\d{4}-\d{2}-\d{2}$')
    )
  );
