# Nowa paczka ciekawostek

## Krok 1: pobierz listę istniejących ciekawostek

W panelu administratora otwórz Ciekawostki i kliknij „Pobierz CSV dla czatu”.
Plik obejmuje także szkice i odrzucone pozycje, więc czat ich nie powtórzy.

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
Jeśli fakt potwierdza tylko jedno słabe źródło, źródła się różnią albo nie masz pewności, ustaw status "draft" i wpisz w review_note konkretny powód. Pozostałe mają status "published" i review_note równe null. Nie zgaduj.

WYNIK
Zwróć jeden plik .json: listę obiektów, bez żadnego tekstu przed nią ani po niej w pliku. Nie nadawaj identyfikatorów, zrobi to panel. Układ jednego obiektu:

[
  {
    "title": "Tytuł",
    "category": "Kosmos",
    "short_text": "Krótki tekst.",
    "long_text": "Pierwszy akapit.\n\nDrugi akapit.",
    "source_label": "NASA, „Tytuł artykułu”",
    "source_url": "https://science.nasa.gov/adres-artykulu/",
    "quiz": {"question": "Pytanie?", "options": ["A", "B", "C"], "correctIndex": 1},
    "status": "published",
    "review_note": null
  }
]

Przed oddaniem pliku sprawdź: poprawny JSON, 120 pozycji, po 10 w kategorii, limity 60 i 120 znaków, 3 różne odpowiedzi, brak powtórek z CSV, limity źródeł. Pod plikiem podaj liczbę pozycji "published" i "draft", liczbę źródeł z Wikipedii i najczęściej użyte domeny.

Jeśli limit odpowiedzi nie pozwala oddać całości naraz, pracuj kategoria po kategorii i na końcu złącz wszystko w jeden plik.
```

## Krok 3: zaimportuj wynik w panelu

W panelu otwórz Import, wybierz plik i kliknij „Sprawdź”. Panel pokaże błędy,
możliwe duplikaty oraz uwagi czatu, a dopiero potem zapisze wybrane pozycje.

Domyślnie wszystko trafia do szkiców, czyli aplikacja jeszcze tego nie widzi.
Szkice przejrzysz, poprawisz i opublikujesz w zakładce Ciekawostki.
