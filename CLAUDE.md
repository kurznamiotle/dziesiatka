# dziesiatka

Aplikacja Flutter na platformy Web, Android i iOS.

## Architektura

Kod aplikacji w `lib/` jest podzielony na trzy warstwy:

```
lib/
├── main.dart     # punkt wejścia: uruchomienie aplikacji i konfiguracja startowa
├── models/       # dane i ich reguły
├── views/        # ekrany i widgety
└── services/     # logika aplikacji i komunikacja ze światem zewnętrznym
```

### `lib/models/`

- Klasy opisujące dane domenowe, najlepiej niemutowalne (pola `final`, konstruktory `const`).
- Serializacja (`fromJson` / `toJson`) i proste reguły wynikające z samych danych.
- Bez importów z `views/`, `services/` ani `package:flutter/*`.

### `lib/views/`

- Ekrany i widgety: wyłącznie prezentacja i obsługa interakcji użytkownika.
- Dane pobierane i zapisywane przez `services/`, nigdy bezpośrednio (bez HTTP, bazy danych, `SharedPreferences` w widgetach).
- Bez logiki biznesowej w metodach `build`.

### `lib/services/`

- Logika aplikacji oraz dostęp do API, bazy danych, pamięci lokalnej i usług platformy.
- Zwracają obiekty z `models/`, a nie surowe odpowiedzi (`Map`, `Response`).
- Bez importów z `views/` i bez zależności od `BuildContext`.

## Kierunek zależności

```
views → services → models
views → models
```

Zależności idą tylko w tę stronę. Warstwy niższe nie znają wyższych.

## Konwencje

- Pliki w `snake_case.dart`, klasy w `PascalCase`. Jedna główna klasa publiczna na plik.
- Importy wewnątrz projektu przez `package:dziesiatka/...`.
- Kod musi być zgodny z regułami z `analysis_options.yaml`.
- Kod działa na wszystkich trzech platformach. `dart:io` nie jest dostępne na Web, więc kod zależny od platformy należy izolować w `services/`.
- Testy w `test/` odwzorowują strukturę `lib/` (np. `test/services/` dla `lib/services/`).
- Przy aktualizacji Fluttera zmień też flutter-version w .github/workflows/ci.yml i panel.yml na tę samą wersję.

## Dane

- Treść ciekawostek i postęp użytkownika są zapisane osobno (`factContent` i `factStates`). `Fact` łączy je tylko w pamięci.
- Treść pochodzi z `FactSource`: `AssetFactSource` (plik w aplikacji) i `SupabaseFactSource` (serwer). Przy dwóch kopiach wygrywa nowszy `updatedAt`.
- Dobór talii (`DeckGeneratorService`): zasada 7-2-1, czyli 7 kart z ulubionych kategorii, 2 z pozostałych i 1 powtórka (bez powtórki 8-2), najwyżej 2 karty z tej samej kategorii pod rząd. Losowanie zależy od daty i lokalnego identyfikatora, który nie opuszcza urządzenia.
- Odpowiedzi z quizu (`quizHistory`, `QuizHistoryService`) i lista ukończonych dni (`streakDays`, `StreakService`) zostają na urządzeniu. `StatsService` liczy z nich statystyki ekranu końcowego.
- Talia nigdy nie czeka na sieć. Nowe ciekawostki pobierane są w tle i trafiają do następnej talii.
- Dostęp do Supabase ustawia się w `lib/services/supabase_config.dart`, a strukturę bazy opisują `supabase/schema.sql` oraz `supabase/usage.sql` , `supabase/usage_02.sql` (anonimowe statystyki), `supabase/admin.sql` (panel), `supabase/reports.sql` (zgłoszenia błędów), `supabase/categories_02.sql` (kategorie Samorozwój oraz Inżynieria & Motoryzacja), `supabase/offers.sql` (polecenia partnerskie), `supabase/offers_stats.sql` (liczba kliknięć w polecenia) i `supabase/partner_facts.sql` (ciekawostki partnerskie).
- Kategorie w aplikacji biorą się z ciekawostek w obiegu, więc kategoria bez opublikowanej ciekawostki nie pojawia się do wyboru. Wygląd kategorii jest w `lib/views/category_style.dart`.
- Polecenie partnerskie (`FactOffer`, kolumna `offer`) jest częścią ciekawostki. Po dacie `until` znika. W talii i w każdej rundzie „Jeszcze 5” jest najwyżej 1 karta z poleceniem. Link otwiera się w zewnętrznej przeglądarce. Aplikacja i panel działają także bez kolumny `offer`.
- Ciekawostka partnerska (`FactKind.partner`, kolumna `kind`) to osobna karta pod produkt, ze stałą kategorią „Ciekawostka partnerska” i obowiązkowym poleceniem. Dochodzi do talii lub rundy „Jeszcze 5” ponad zasadę 7-2-1, nigdy jako pierwsza ani ostatnia, i liczy się do limitu 1 karty z poleceniem. Nie trafia do quizu, powtórek, statystyk ani osiągnięć. Po dacie `until` znika. Bez kolumny `kind` wszystkie karty są zwykłe. Klucz publiczny nie widzi kart partnerskich w tabeli `facts` (starsze wersje aplikacji by je źle pokazały). Aplikacja pobiera je funkcją RPC `partner_facts()` (`PartnerFactSource`), zawsze pełną listę aktywnych, a karta, której na liście brak, staje się wycofana.
- Prośba o ocenę (`RatingService`, wtyczka `in_app_review`) tylko na Androidzie: systemowe okienko bez własnego pytania i nagród, na ekranie końcowym po co najmniej 3. ukończonym dniu i quizie min. 75%, nie w dniu pierwszego uruchomienia ani w dniu innego komunikatu (`recordOtherPrompt`, np. osiągnięcia). Najwyżej 3 próby co 60 dni. W ustawieniach stały przycisk „Oceń Dziesiątkę w Google Play”.
- Aplikacja nie ma zakupów. Na Androidzie nie ma żadnego linku do płatności, a link wsparcia (`AppLinks.support`) jest tylko w wersji przeglądarkowej. Dziesiątka+ i napiwki przez Google Play czekają na gałęzi `platnosci`.

## Panel administratora

- Osobna aplikacja Web z tego samego pakietu: punkt wejścia `lib/admin_main.dart`, ekrany w `lib/views/admin/`.
- Logowanie przez Supabase Auth. Prawa nadaje `supabase/admin.sql` (tabela `admins`). W panelu nie ma klucza sekretnego.
- Kod zależny od przeglądarki jest w `lib/services/browser_files_web.dart`.
- GitHub Pages publikuje stronę o aplikacji z `website/`, panel pod `/panel/`, a aplikację jako demo pod `/app/`. Na komputerze `website/demo.js` otwiera demo w ramce po kliknięciu, a na telefonie link prowadzi do pełnego ekranu. Na Web statystyki ruszają dopiero po zgodzie. Tekst polityki prywatności jest w `website/privacy.html` i `lib/views/settings_screen.dart`, więc zmieniaj oba.
- Nowe ciekawostki powstają w czacie według `supabase/prompt_ciekawostki.md` i trafiają do bazy przez Import w panelu.
- Zakładka „Polecenia” (`OffersPage`, logika w `AdminOffersService`) zbiera ciekawostki partnerskie i zwykłe karty z poleceniem. Tam powstają ciekawostki partnerskie (id `partner-NNN`), których nie ma na liście ciekawostek, w imporcie ani w CSV dla czatu. Usunięcie karty partnerskiej to wycofanie (`withdrawn`), bo aplikacja widzi tylko zmienione wiersze.

## Polecenia

```
flutter pub get             # instalacja zależności
flutter analyze             # analiza statyczna
flutter test                # testy
flutter run -d chrome       # uruchomienie na Web
flutter build web           # build produkcyjny Web
flutter run -d chrome -t lib/admin_main.dart   # panel administratora
```
