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

## Dane

- Treść ciekawostek i postęp użytkownika są zapisane osobno (`factContent` i `factStates`). `Fact` łączy je tylko w pamięci.
- Treść pochodzi z `FactSource`: `AssetFactSource` (plik w aplikacji) i `SupabaseFactSource` (serwer). Przy dwóch kopiach wygrywa nowszy `updatedAt`.
- Dobór talii (`DeckGeneratorService`): zasada 7-2-1, czyli 7 kart z ulubionych kategorii, 2 z pozostałych i 1 powtórka (bez powtórki 8-2), najwyżej 2 karty z tej samej kategorii pod rząd. Losowanie zależy od daty i lokalnego identyfikatora, który nie opuszcza urządzenia.
- Talia nigdy nie czeka na sieć. Nowe ciekawostki pobierane są w tle i trafiają do następnej talii.
- Dostęp do Supabase ustawia się w `lib/services/supabase_config.dart`, a strukturę bazy opisują `supabase/schema.sql` oraz `supabase/usage.sql` , `supabase/usage_02.sql` (anonimowe statystyki), `supabase/admin.sql` (panel) i `supabase/reports.sql` (zgłoszenia błędów).

## Panel administratora

- Osobna aplikacja Web z tego samego pakietu: punkt wejścia `lib/admin_main.dart`, ekrany w `lib/views/admin/`.
- Logowanie przez Supabase Auth. Prawa nadaje `supabase/admin.sql` (tabela `admins`). W panelu nie ma klucza sekretnego.
- Kod zależny od przeglądarki jest w `lib/services/browser_files_web.dart`.
- GitHub Pages publikuje stronę o aplikacji z `website/`, panel pod `/panel/`, a aplikację jako demo pod `/app/`. Na komputerze `website/demo.js` otwiera demo w ramce po kliknięciu, a na telefonie link prowadzi do pełnego ekranu. Na Web statystyki ruszają dopiero po zgodzie. Tekst polityki prywatności jest w `website/privacy.html` i `lib/views/settings_screen.dart`, więc zmieniaj oba.
- Nowe ciekawostki powstają w czacie według `supabase/prompt_ciekawostki.md` i trafiają do bazy przez Import w panelu.

## Polecenia

```
flutter pub get             # instalacja zależności
flutter analyze             # analiza statyczna
flutter test                # testy
flutter run -d chrome       # uruchomienie na Web
flutter build web           # build produkcyjny Web
flutter run -d chrome -t lib/admin_main.dart   # panel administratora
```
