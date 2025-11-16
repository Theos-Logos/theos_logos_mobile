# Instrukcje dla Claude - Theos Logos Mobile

## 🎯 Cel projektu

Aplikacja mobilna Flutter do odsłuchiwania nagrań biblijnych z serwera Theos-Logos. Użytkownicy mogą:
- Przeglądać i odtwarzać nagrania audio z różnych ksiąg Biblii
- Filtrować nagrania po księgach biblijnych
- Pobierać nagrania do odsłuchu offline
- Śledzić postęp odsłuchanych nagrań

## 📋 WAŻNE: Aktualizacja dokumentacji

**PRZY KAŻDEJ ISTOTNEJ ZMIANIE W PROJEKCIE:**

1. **Przeczytaj najpierw** `.claude/instructions.md` i `ARCHITECTURE.md`
2. **Przemyśl**, czy wprowadzona zmiana wpływa na:
   - Strukturę projektu
   - Wzorce architektoniczne
   - Przepływ danych
   - API/manifest
   - Nowe funkcjonalności
3. **Zaktualizuj odpowiednie sekcje** w tych plikach
4. **Dodaj nowe sekcje**, jeśli wprowadzasz nową funkcjonalność

### Przykłady zmian wymagających aktualizacji dokumentacji:
- ✅ Dodanie nowego providera → aktualizuj `ARCHITECTURE.md`
- ✅ Zmiana struktury modelu danych → aktualizuj oba pliki
- ✅ Nowy screen/widget → aktualizuj strukturę projektu
- ✅ Zmiana w formacie manifestu → aktualizuj "Manifest TOML"
- ✅ Nowa funkcjonalność → dodaj do przepływów w `ARCHITECTURE.md`
- ✅ Zmiana w architekturze → głównie `ARCHITECTURE.md`

### Przykłady zmian NIE wymagających aktualizacji:
- ❌ Drobne poprawki UI (kolory, marginesy)
- ❌ Fixowanie bugów bez zmiany logiki
- ❌ Refactoring bez zmiany architektury

## 🏗️ Quick Reference - Struktura projektu

```
lib/
├── main.dart                          # Entry point aplikacji
├── models/                            # Modele danych
│   └── audio_track.dart              # Model nagrania audio
├── providers/                         # State management (Riverpod)
│   ├── manifest_provider.dart        # Synchronizacja z manifestem
│   ├── audio_provider.dart           # Zarządzanie odtwarzaczem
│   └── book_filter_provider.dart     # Filtrowanie po księgach
├── screens/                           # Ekrany aplikacji
│   ├── playlist_screen.dart          # Główny ekran z listą nagrań
│   └── support_screen.dart           # Ekran wsparcia finansowego
├── widgets/                           # Komponenty UI
│   ├── audio_player_widget.dart      # Widget odtwarzacza
│   └── book_filter_drawer.dart       # Menu hamburgerowe z filtrami
└── router/
    └── app_router.dart               # Routing (GoRouter)
```

**Więcej szczegółów architektury:** Zobacz `ARCHITECTURE.md`

## 🔑 Kluczowe koncepcje

### 1. State Management - Riverpod

**Główne providery:**
- `manifestNotifierProvider` - lista wszystkich nagrań (AsyncNotifier)
- `audioPlayerNotifierProvider` - stan odtwarzacza (Notifier)
- `bookFilterProvider` - aktualnie wybrany filtr księgi (Notifier)
- `availableBooksProvider` - lista dostępnych ksiąg (computed Provider)
- `filteredTracksProvider` - przefiltrowana lista nagrań (computed Provider)

**Wzorzec**: AsyncNotifier dla operacji asynchronicznych, zwykły Notifier dla stanu synchronicznego.

**Szczegóły architektury:** Zobacz `ARCHITECTURE.md` → "State Layer"

### 2. Manifest TOML (Serwer)

Aplikacja pobiera manifest z: `https://theos-logos.pl/manifest.toml`

**Format wpisu w manifeście:**
```toml
[[files]]
id = "mrk1-1-20"
title = "Ewangelia Marka 1, 1-20"
book = "Marka"                    # WAŻNE: Pole używane do filtrowania
file_name = "Theos-Logos-Ewangelia Marka 1, 1-20.mp3"
url = "https://theos-logos.pl/audio/Theos-Logos-Ewangelia Marka 1, 1-20.mp3"
date_added = "2023-11-02T10:00:00Z"
```

**Konwencja nazewnictwa ksiąg:**
- Używamy **skrótowych nazw**: "Marka" zamiast "Ewangelia Marka"
- Format: "Mateusza", "Łukasza", "Jana", "1 Tesaloniczan", "Psalmy"
- Zobacz pełną listę w `book_filter_provider.dart` → `biblicalOrder`

### 3. Synchronizacja danych

**Przepływ:**
1. Przy starcie → `syncManifest()` pobiera manifest z serwera
2. Porównuje z lokalnym cache (SharedPreferences)
3. Wykrywa nowe nagrania
4. Aktualizuje cache
5. Pokazuje dialog "Co nowego?" jeśli są nowe nagrania

**Cache:** `SharedPreferences` przechowuje:
- `cached_tracks` - lista wszystkich nagrań
- `last_sync_timestamp` - timestamp ostatniej synchronizacji
- `new_tracks` - lista nowych nagrań (do pokazania w dialogu)

**Szczegółowy przepływ:** Zobacz `ARCHITECTURE.md` → "Przepływy danych"

### 4. System filtrowania

**Kolejność biblijna:**
Księgi w menu są sortowane według `biblicalOrder` (tablica w `book_filter_provider.dart`).
Kolejność zgodna z kanonem biblijnym: ST (Rodzaju → Malachiasza) → NT (Mateusza → Apokalipsa).

**Filtrowanie:**
- `null` w `bookFilterProvider` = "Wszystkie" (brak filtra)
- Wybranie księgi → ustawia `state` na nazwę księgi
- `filteredTracksProvider` automatycznie filtruje `track.book == selectedBook`

**Szczegółowy przepływ:** Zobacz `ARCHITECTURE.md` → "Filtrowanie ksiąg"

## 🎨 UI/UX Zasady

### Kolory
```dart
// Główny akcent (pomarańczowy/złoty)
Color(0xFFFFB300)

// Tła
Color(0xFF1a1a1a)  // główne tło (ciemne)
Color(0xFF2a2a2a)  // karty (jaśniejsze ciemne)

// Tekst
Colors.white       // główny tekst
Colors.grey[300]   // tekst secondary
```

### Interakcje
- **Tap na nagranie** → odtwarza od początku
- **Przycisk pobierania** → pobiera plik lokalnie
- **Menu hamburgerowe** → otwiera filtr ksiąg
- **Wybór księgi** → zamyka menu i filtruje nagrania

### Accessibility
- Używamy `Semantics` dla czytelników ekranu
- Minimalne rozmiary przycisków: 48x48 dp
- `Tooltip` na ikonach

## 🔧 Częste zadania

### Dodanie nowego pola do AudioTrack

1. Zaktualizuj model w `models/audio_track.dart`:
   - Dodaj pole do klasy
   - Zaktualizuj `fromJson`, `toJson`, `copyWith`

2. Zaktualizuj manifest serwera (`theos-logos-server/manifest.toml`):
   - Dodaj nowe pole do wszystkich wpisów

3. Zaktualizuj parser w `manifest_provider.dart`:
   - Dodaj parsowanie nowego pola w `syncManifest()`

4. **Zaktualizuj dokumentację:**
   - `ARCHITECTURE.md` → "Model Layer" → `AudioTrack`

### Dodanie nowej księgi

1. Dodaj wpisy do manifestu z właściwym polem `book`
2. Jeśli to nowa księga, dodaj ją do `biblicalOrder` w `book_filter_provider.dart` we właściwym miejscu
3. Księga automatycznie pojawi się w menu

### Zmiana logiki filtrowania

Wszystko dzieje się w `book_filter_provider.dart`:
- `availableBooksProvider` - ekstrahuje unikalne księgi z nagrań
- `filteredTracksProvider` - filtruje nagrania według wybranej księgi

**Pamiętaj:** Zaktualizuj `ARCHITECTURE.md` jeśli zmieniasz przepływ

### Dodanie nowego providera

1. Utwórz plik w `lib/providers/`
2. Zdefiniuj odpowiedni typ providera (AsyncNotifier, Notifier, Provider)
3. Dodaj do `main.dart` jeśli wymaga inicjalizacji
4. **Zaktualizuj:** `ARCHITECTURE.md` → "State Layer" z opisem nowego providera

## ⚠️ Pułapki i gotchas

### 1. Indeksy podczas filtrowania

**Problem:** Podczas filtrowania nagrań, indeksy w przefiltrowanej liście nie odpowiadają indeksom w oryginalnej liście.

**Rozwiązanie:** W `PlaylistScreen`:
```dart
final track = filteredTracks[trackIndex];
final originalIndex = tracks.indexWhere((t) => t.id == track.id);
// Użyj originalIndex do playback!
```

### 2. Kolejność w ListView

**Problem:** ListView ma header + opcjonalny nagłówek księgi + nagrania.

**Rozwiązanie:**
```dart
itemCount: filteredTracks.length + 2  // +2 for header and book title
// index 0 = header
// index 1 = book title (if filtered)
// index 2+ = tracks
```

### 3. Cache invalidation

**Problem:** Cache może zawierać stare dane po zmianie struktury.

**Rozwiązanie:** Zmień `tracksKey` lub dodaj wersjonowanie:
```dart
const String tracksKey = 'cached_tracks_v2';
```

### 4. DateTime parsing

**Problem:** TOML używa ISO 8601, ale może być nullable.

**Rozwiązanie:**
```dart
dateAdded: file['date_added'] != null
    ? DateTime.parse(file['date_added'] as String)
    : null,
```

### 5. Provider dependencies

**Problem:** Circular dependencies między providerami.

**Rozwiązanie:** Używaj computed Providers (`Provider`, nie `NotifierProvider`) dla derived state.
Zobacz diagram w `ARCHITECTURE.md` → "State Layer" → "Wzorzec dependency"

## 🧪 Testing

### Przed commitem:
```bash
flutter analyze
flutter test
flutter build apk --release
```

### Testowanie ręczne:
- [ ] Synchronizacja manifestu działa
- [ ] Filtrowanie po księgach działa
- [ ] Odtwarzacz działa (play, pause, seek)
- [ ] Pobieranie offline działa
- [ ] Dialog "Co nowego?" pokazuje się dla nowych nagrań
- [ ] Menu zamyka się po wyborze księgi

### Debug tips:
```dart
// Logowanie stanu providera
print(ref.read(manifestNotifierProvider).value);

// Check filtered tracks
final filtered = ref.read(filteredTracksProvider);
print('Filtered: ${filtered.length} tracks');
```

## 🔄 Git workflow

1. Zawsze commity po ukończeniu feature'a
2. Commit message format:
   ```
   feat: dodano filtrowanie po księgach
   fix: naprawiono błąd synchronizacji
   refactor: przepisano provider na Riverpod
   docs: zaktualizowano dokumentację
   ```
3. Przed commitem uruchom testy (patrz sekcja Testing)

## 💡 Wskazówki dla Claude

### Workflow
1. **Zawsze czytaj ARCHITECTURE.md** przed większymi zmianami
2. **Pytaj o niezdecydowane rzeczy** zamiast zgadywać
3. **Używaj TodoWrite** do trackowania postępów
4. **Testuj kod** przed commitem
5. **Aktualizuj dokumentację** gdy wprowadzasz zmiany!

### Co aktualizować gdzie:
- **Architektura, przepływy danych, wzorce** → `ARCHITECTURE.md`
- **Instrukcje dla Claude, częste zadania, pułapki** → `.claude/instructions.md`
- **README (jeśli istnieje)** → informacje dla użytkowników końcowych

### Debugging
Jeśli coś nie działa:
1. Sprawdź logi w konsoli Flutter
2. Zweryfikuj, czy providery są poprawnie zadeklarowane
3. Sprawdź, czy cache jest aktualny (może wymaga invalidation)
4. Zobacz sekcję "Pułapki i gotchas" powyżej

## 📚 Dodatkowe zasoby

### Dokumentacja używanych pakietów:
- [Riverpod](https://riverpod.dev/) - State management
- [GoRouter](https://pub.dev/packages/go_router) - Routing
- [just_audio](https://pub.dev/packages/just_audio) - Audio player
- [TOML](https://pub.dev/packages/toml) - Parser manifestu

### Serwer:
- Manifest: `https://theos-logos.pl/manifest.toml`
- Audio: `https://theos-logos.pl/audio/[filename]`
- Repo serwera: `/home/sel/Documents/theos-logos/theos-logos-server`

### Dokumentacja projektu:
- **ARCHITECTURE.md** - szczegółowa architektura aplikacji (PRZECZYTAJ PRZED WIĘKSZYMI ZMIANAMI!)
- **.claude/instructions.md** - ten plik

---

**Ostatnia aktualizacja:** 2025-11-16
**Wersja aplikacji:** 1.0.0
**Flutter SDK:** 3.x
