-- Struktura bazy Dziesiątki. Uruchom raz w SQL Editor w Supabase.
-- Kolejność: najpierw ten plik, potem facts_import.sql.

-- Lista dozwolonych kategorii. Dzięki niej literówka w nazwie jest odrzucana.
-- Aplikacja zna kolory i ikony tych z pliku category_style.dart, a każda nowa
-- dostaje styl domyślny.
create table public.categories (
  name text primary key check (char_length(btrim(name)) > 0)
);

-- id jest tekstem, żeby ciekawostki z pliku zachowały identyfikatory seed-001
-- i dalsze, do których przypisany jest postęp użytkowników.
create table public.facts (
  id text primary key default ('fact-' || gen_random_uuid()),
  title text not null check (char_length(btrim(title)) between 1 and 60),
  category text not null references public.categories (name) on update cascade,
  short_text text not null check (char_length(btrim(short_text)) between 1 and 120),
  long_text text not null check (char_length(btrim(long_text)) > 0),
  source_label text not null check (char_length(btrim(source_label)) > 0),
  source_url text check (source_url ~ '^https?://'),
  -- { "question": "...", "options": ["A", "B", "C"], "correctIndex": 0 }
  quiz jsonb check (
    quiz is null or (
      jsonb_typeof(quiz -> 'question') = 'string'
      and jsonb_typeof(quiz -> 'options') = 'array'
      and jsonb_array_length(quiz -> 'options') = 3
      and jsonb_typeof(quiz -> 'correctIndex') = 'number'
      and (quiz ->> 'correctIndex')::int between 0 and 2
    )
  ),
  -- draft: widzi tylko redakcja. published: trafia do aplikacji.
  -- withdrawn: wycofana, nie wchodzi do nowych talii. Nie kasuj opublikowanych
  -- wierszy, bo aplikacja nie dowie się o zniknięciu. Ustaw im withdrawn.
  status text not null default 'draft'
    check (status in ('draft', 'published', 'withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Aplikacja pobiera tylko wiersze zmienione od ostatniego razu.
create index facts_updated_at_idx on public.facts (updated_at, id);

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger facts_set_updated_at
  before update on public.facts
  for each row execute function public.set_updated_at();

-- Bezpieczeństwo: klucz publiczny z aplikacji może tylko czytać ciekawostki
-- niebędące szkicami. Żadnych zapisów. Tabela kategorii jest niewidoczna, bo
-- aplikacja jej nie potrzebuje, a redakcja pracuje w panelu Supabase.
alter table public.categories enable row level security;
alter table public.facts enable row level security;

revoke all on public.categories, public.facts from anon, authenticated;
grant select on public.facts to anon, authenticated;

create policy "Aplikacja czyta opublikowane i wycofane ciekawostki"
  on public.facts
  for select
  to anon, authenticated
  using (status <> 'draft');
