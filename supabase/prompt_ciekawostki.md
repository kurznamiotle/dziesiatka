# Nowa paczka ciekawostek

## Krok 1: pobierz listę istniejących ciekawostek

W SQL Editor w Supabase uruchom poniższe zapytanie, a wynik pobierz przyciskiem
eksportu do CSV. Docelowo zrobi to przycisk w panelu administratora.

```sql
select id, status, category, title, short_text
from public.facts
order by created_at, id;
```

## Krok 2: przekaż prompt do czatu

Włącz wyszukiwanie w sieci, dołącz plik CSV i wklej poniższy tekst.

```text
Przygotuj paczkę nowych ciekawostek do polskiej aplikacji Dziesiątka. Czytelnikami są dorośli, którzy czytają je w kilka minut dziennie. Wiarygodność jest ważniejsza od efektowności.

ZADANIE
Napisz 120 ciekawostek, dokładnie po 10 w każdej z tych 12 kategorii. Użyj nazw co do znaku:
Kosmos
Technologia
Psychologia
Historia
Zwierzęta
Popkultura & Gry
Biznes & Pieniądze
Zagadki Codzienności
Ciało & Jedzenie
Geografia & Miejsca
Absurdy Prawa
Język & Symbole

BEZ POWTÓREK
Dołączony plik CSV zawiera wszystkie ciekawostki z bazy. Przeczytaj go w całości przed pisaniem. Nowa ciekawostka nie może dotyczyć tego samego faktu co istniejąca, nawet innymi słowami. Żadne dwie nowe też nie mogą się pokrywać.

PRAWDZIWOŚĆ
Sprawdź każdy fakt w internecie przed zapisaniem, a podany adres otwórz i upewnij się, że strona potwierdza fakt. Nie podawaj adresów z pamięci. Jeśli fakt jest wyjątkowo zaskakujący, potwierdź go w drugim, niezależnym źródle. Jeśli popularna historia jest sporna, napisz o tym wprost w tekście.

ŹRÓDŁA
Sięgaj po źródła pierwotne i specjalistyczne, po polsku lub angielsku. Wikipedii używaj tylko do znalezienia tropu: podawaj ją jako źródło najwyżej przy 10 ze 120 ciekawostek i nigdy przy więcej niż 1 w kategorii. Staraj się, by jedna domena nie pojawiała się więcej niż 5 razy w całej paczce.
Przykłady dobrych źródeł:
- Kosmos: NASA, ESA, ESO, Polska Agencja Kosmiczna
- Technologia: IEEE Spectrum, Computer History Museum, Ars Technica, dokumentacja twórców
- Psychologia: American Psychological Association, Nature, Science, PubMed, uczelnie
- Historia: Britannica, Smithsonian Magazine, History Extra, muzea, Muzeum Historii Polski, archiwa
- Zwierzęta: National Geographic, Smithsonian, IUCN, Natural History Museum, ogrody zoologiczne
- Popkultura & Gry: strony twórców i studiów, Guinness World Records, BBC, The Guardian, Polygon
- Biznes & Pieniądze: strony firm o ich historii, Reuters, Financial Times, Bank Światowy, OECD, NBP
- Zagadki Codzienności: Scientific American, Live Science, BBC Science Focus, uczelnie, Smithsonian
- Ciało & Jedzenie: WHO, NIH, Mayo Clinic, Harvard Health, EFSA, Encyclopaedia Britannica
- Geografia & Miejsca: National Geographic, NOAA, USGS, UNESCO, GUS, oficjalne strony państw i parków
- Absurdy Prawa: oryginalne teksty ustaw (legislation.gov.uk, ISAP, EUR-Lex, Fedlex), sądy, urzędy, BBC, Reuters
- Język & Symbole: Rada Języka Polskiego, Poradnia Językowa PWN, Oxford English Dictionary, Merriam-Webster, Unicode Consortium
Nie używaj blogów bez autora, serwisów z ciekawostkami, list typu „dziwne prawa”, forów ani treści generowanych przez AI, bo często powielają mity.

FORMAT POLA
- title: do 60 znaków, chwytliwy, bez kropki
- short_text: do 120 znaków, jedno pełne zdanie, sedno ciekawostki
- long_text: dwa krótkie akapity rozdzielone pustą linią, 2-4 zdania razem, wnoszą coś nowego względem short_text
- source_label: nazwa wydawcy i tytuł strony, np. NASA, „Tytuł artykułu”
- source_url: pełny adres https
- quiz: JSON z polami question, options (dokładnie 3 różne odpowiedzi) i correctIndex (0, 1 lub 2)

QUIZ
Odpowiedź ma być w long_text, a najlepiej nie w short_text, bo użytkownik ma zaglądać do rozwinięcia. Odpowiedzi muszą być równie wiarygodne. Poprawna odpowiedź ma wypadać na każdej pozycji mniej więcej równie często.

STYL
Poprawna polszczyzna, prosty i żywy język, polskie cudzysłowy „ ”. Bez clickbaitu, bez zwrotów typu „czy wiesz, że”, bez wulgaryzmów, polityki bieżącej i treści niestosownych.

WĄTPLIWOŚCI
Jeśli fakt potwierdza tylko jedno słabe źródło, źródła się różnią albo nie masz pewności, ustaw status 'draft' i dodaj przed tym wierszem komentarz SQL zaczynający się od -- WĄTPLIWE: z konkretnym powodem. Pozostałe mają status 'published'. Nie zgaduj.

IDENTYFIKATORY
Znajdź w pliku CSV najwyższy numer w identyfikatorach typu fact-NNN i kontynuuj od następnego.

WYNIK
Zwróć jeden plik .sql w dokładnie tym układzie:

-- 120 nowych ciekawostek.
insert into public.facts
  (id, title, category, short_text, long_text, source_label, source_url, quiz, status)
values
  ('fact-301', 'Tytuł', 'Kosmos', 'Krótki tekst.', 'Pierwszy akapit.

Drugi akapit.', 'NASA, „Tytuł artykułu”', 'https://science.nasa.gov/adres-artykulu/', '{"question": "Pytanie?", "options": ["A", "B", "C"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-302', ...),
  ('fact-303', ...)
on conflict (id) do nothing;

Każdy apostrof wewnątrz tekstu zapisz podwójnie (''), także w polu quiz. Ostatni wiersz nie ma przecinka na końcu.

Przed oddaniem pliku sprawdź: 120 wierszy, po 10 w kategorii, limity 60 i 120 znaków, 3 różne odpowiedzi, brak powtórek z CSV, limity źródeł. Pod plikiem podaj liczbę wierszy 'published' i 'draft', liczbę źródeł z Wikipedii i najczęściej użyte domeny.

Jeśli limit odpowiedzi nie pozwala oddać całości naraz, pracuj kategoria po kategorii i na końcu złącz wszystko w jeden plik.
```

## Krok 3: wklej wynik do Supabase

Skopiuj całą zawartość pliku `.sql` do SQL Editor i kliknij Run. Ponowne
uruchomienie nie tworzy duplikatów, ale identyfikatory nie mogą się powtarzać
między paczkami.

Pozycje `draft` nie trafią do aplikacji. Znajdziesz je w Table Editor, w tabeli
`facts`, po filtrze `status = draft`. Po poprawieniu ustaw `published`. Komentarze
`-- WĄTPLIWE:` są tylko w pliku `.sql`.
