-- Dwie nowe kategorie. Uruchom raz w SQL Editor w Supabase, po schema.sql.
-- Aplikacja pokaże kategorię dopiero wtedy, gdy będzie w niej choć jedna
-- opublikowana ciekawostka. Kolory i ikony są w lib/views/category_style.dart.
insert into public.categories (name)
values ('Samorozwój'), ('Inżynieria & Motoryzacja')
on conflict do nothing;
