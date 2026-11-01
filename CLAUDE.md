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
- Talia nigdy nie czeka na sieć. Nowe ciekawostki pobierane są w tle i trafiają do następnej talii.
- Dostęp do Supabase ustawia się w `lib/services/supabase_config.dart`, a strukturę bazy opisują `supabase/schema.sql` i `supabase/usage.sql` (licznik użytkowników).

## Polecenia

```
flutter pub get             # instalacja zależności
flutter analyze             # analiza statyczna
flutter test                # testy
flutter run -d chrome       # uruchomienie na Web
flutter build web           # build produkcyjny Web
```
