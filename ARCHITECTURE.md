# Architektura Theos Logos Mobile

## 📐 Przegląd architektury

Aplikacja Theos Logos Mobile jest zbudowana w architekturze **MVVM (Model-View-ViewModel)** z wykorzystaniem **Riverpod** jako warstwy zarządzania stanem.

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│  (Screens, Widgets - PlaylistScreen, AudioPlayerWidget)    │
└────────────────────┬────────────────────────────────────────┘
                     │ consumes
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    State Layer (Riverpod)                    │
│  (Providers - manifestNotifier, audioPlayer, bookFilter)    │
└────────────────────┬────────────────────────────────────────┘
                     │ manages
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                     Model Layer                              │
│              (AudioTrack, business logic)                    │
└────────────────────┬────────────────────────────────────────┘
                     │ uses
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Data Layer                                 │
│         (HTTP, SharedPreferences, File System)              │
└─────────────────────────────────────────────────────────────┘
```

## 🏛️ Warstwy architektury

### 1. UI Layer (Presentation)

**Odpowiedzialność:** Wyświetlanie danych i obsługa interakcji użytkownika.

#### Screens
- `PlaylistScreen` - główny ekran z listą nagrań
  - Zarządza filtrowaniem i wyświetlaniem nagrań
  - Integruje AudioPlayerWidget
  - Obsługuje menu hamburgerowe

- `SupportScreen` - ekran wsparcia finansowego

#### Widgets
- `AudioPlayerWidget` - sticky player na dole ekranu
  - Kontrolki odtwarzania (play/pause, seek)
  - Informacje o aktualnym nagraniu
  - Mini player w trybie zminimalizowanym

- `BookFilterDrawer` - drawer z filtrowaniem ksiąg
  - Lista dostępnych ksiąg
  - Opcja "Wszystkie"
  - Wizualne oznaczenie aktywnego filtra

**Zasady:**
- Screens i Widgets są **stateless gdzie to możliwe**
- Stan pochodzi z providerów (Riverpod)
- UI reaguje reaktywnie na zmiany stanu
- Brak logiki biznesowej w UI - tylko prezentacja

### 2. State Layer (ViewModel)

**Odpowiedzialność:** Zarządzanie stanem aplikacji, logika biznesowa.

#### Providers

##### `manifestNotifierProvider` (AsyncNotifier)
```dart
AsyncNotifierProvider<ManifestNotifier, List<AudioTrack>>
```

**Stan:** Lista wszystkich nagrań audio z manifestu

**Operacje:**
- `syncManifest()` - pobiera i parsuje manifest z serwera
- `downloadTrack(trackId)` - pobiera plik audio lokalnie
- `markAsListened(trackId)` - oznacza nagranie jako odsłuchane
- `clearAllListened()` - czyści wszystkie flagi odsłuchanych
- `getNewTracks()` - zwraca listę nowych nagrań

**Przepływ danych:**
```
Server TOML → HTTP GET → Parse TOML → Compare with cache →
Update SharedPreferences → Notify listeners
```

##### `audioPlayerNotifierProvider` (Notifier)
```dart
NotifierProvider<AudioPlayerNotifier, AudioPlayerState>
```

**Stan:**
```dart
class AudioPlayerState {
  final AudioTrack? currentTrack;
  final int? currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
}
```

**Operacje:**
- `playTrack(track, index)` - odtwarza wybrane nagranie
- `pause()` - pauzuje odtwarzanie
- `resume()` - wznawia odtwarzanie
- `seek(position)` - przewija do pozycji
- `playNext()` - następne nagranie
- `playPrevious()` - poprzednie nagranie

**Integracja:** Używa `just_audio` package

##### `bookFilterProvider` (Notifier)
```dart
NotifierProvider<BookFilterNotifier, String?>
```

**Stan:** Nazwa aktualnie wybranej księgi lub `null` (wszystkie)

**Operacje:**
- `setFilter(bookName)` - ustawia filtr
- `clearFilter()` - czyści filtr (wszystkie)

##### `availableBooksProvider` (Provider - computed)
```dart
Provider<List<String>>
```

**Computed state** - automatycznie ekstrahuje unikalne księgi z nagrań i sortuje je według `biblicalOrder`.

**Zależności:** `manifestNotifierProvider`

##### `filteredTracksProvider` (Provider - computed)
```dart
Provider<List<AudioTrack>>
```

**Computed state** - filtruje nagrania według aktywnego filtra księgi.

**Zależności:** `manifestNotifierProvider`, `bookFilterProvider`

**Wzorzec dependency:**
```
manifestNotifierProvider (source of truth)
         ↓
    ┌────┴────┐
    ↓         ↓
availableBooks  filteredTracks
    ↑              ↑
    └──bookFilter──┘
```

### 3. Model Layer

#### AudioTrack
```dart
class AudioTrack {
  final String id;           // Unikalny identyfikator
  final String title;        // Pełny tytuł (np. "Ewangelia Marka 1, 1-20")
  final String? book;        // Nazwa księgi (np. "Marka")
  final String fileName;     // Nazwa pliku MP3
  final String url;          // URL do pobrania
  final int order;           // Kolejność w manifeście
  final DateTime? dateAdded; // Data dodania
  bool isDownloaded;         // Czy pobrane lokalnie
  String? localPath;         // Ścieżka do lokalnego pliku
  bool isListened;           // Czy odsłuchane
}
```

**Serializacja:**
- `fromJson()` - deserializacja z Map (cache lub TOML)
- `toJson()` - serializacja do Map (cache)
- `copyWith()` - immutable updates

**Ważne:** `book` jest używane do filtrowania - musi być zgodne z `biblicalOrder`

### 4. Data Layer

#### Źródła danych

##### Remote (HTTP)
- **Manifest TOML:** `https://theos-logos.pl/manifest.toml`
  - Format: TOML array of tables
  - Parsowane przez `toml` package
  - Encoding: UTF-8

- **Audio Files:** `https://theos-logos.pl/audio/[filename]`
  - Format: MP3
  - Streaming lub download

##### Local (Persistence)

**SharedPreferences:**
- `cached_tracks` - JSON array wszystkich nagrań
- `last_sync_timestamp` - timestamp ostatniej synchronizacji
- `new_tracks` - JSON array nowych nagrań (tymczasowe)

**File System (path_provider):**
- Pobrane pliki MP3 w `ApplicationDocumentsDirectory`
- Struktura: `{appDir}/{fileName}`

## 🔄 Przepływy danych

### Synchronizacja manifestu

```
1. User opens app
   ↓
2. PlaylistScreen.initState()
   ↓
3. manifestNotifier.syncManifest()
   ↓
4. HTTP GET manifest.toml
   ↓
5. Parse TOML → List<Map>
   ↓
6. Load cached tracks from SharedPreferences
   ↓
7. Compare IDs (detect new tracks)
   ↓
8. Merge (preserve isDownloaded, isListened)
   ↓
9. Save to SharedPreferences
   ↓
10. Update provider state
   ↓
11. UI rebuilds reactively
   ↓
12. Show "Co nowego?" dialog if new tracks exist
```

### Filtrowanie ksiąg

```
1. User opens hamburger menu
   ↓
2. BookFilterDrawer builds
   ↓
3. Reads availableBooksProvider
   │  ↓
   │  Extract unique book names from tracks
   │  ↓
   │  Sort by biblicalOrder
   ↓
4. User selects book (e.g., "Marka")
   ↓
5. bookFilterNotifier.setFilter("Marka")
   ↓
6. filteredTracksProvider recomputes
   │  ↓
   │  Filter tracks where track.book == "Marka"
   ↓
7. PlaylistScreen rebuilds with filtered tracks
   ↓
8. Show book header ("Marka")
   ↓
9. Display only tracks from that book
```

### Odtwarzanie audio

```
1. User taps on track
   ↓
2. audioPlayerNotifier.playTrack(track, index)
   ↓
3. Load audio source (URL or local file)
   ↓
4. just_audio starts playing
   ↓
5. Stream position updates
   ↓
6. Update audioPlayerState
   ↓
7. AudioPlayerWidget rebuilds
   ↓
8. On completion → markAsListened(trackId)
```

### Pobieranie offline

```
1. User taps download icon
   ↓
2. manifestNotifier.downloadTrack(trackId)
   ↓
3. HTTP GET audio file
   ↓
4. Write to ApplicationDocumentsDirectory
   ↓
5. Update track: isDownloaded = true, localPath = path
   ↓
6. Save to cache
   ↓
7. Update state
   ↓
8. UI shows "Pobrane" badge
```

## 🎯 Wzorce projektowe

### 1. Repository Pattern (Implicit)

Choć nie ma jawnego Repository, `ManifestNotifier` pełni tę rolę:
- Abstrakcja nad źródłami danych (HTTP, SharedPreferences)
- Zarządzanie synchronizacją
- Cache strategy

### 2. Provider Pattern (Riverpod)

Używamy różnych typów providerów:
- **AsyncNotifierProvider** - dla operacji async z mutacją stanu
- **NotifierProvider** - dla synchronicznego stanu z mutacją
- **Provider** - dla computed/derived state (bez mutacji)

### 3. Reactive Programming

UI jest reaktywne:
```dart
final tracks = ref.watch(filteredTracksProvider);
// Automatycznie rebuilds gdy tracks się zmienią
```

### 4. Immutability

Modele są immutable:
```dart
final updatedTrack = track.copyWith(isListened: true);
```

Listy są kopiowane przy update:
```dart
final updatedTracks = List<AudioTrack>.from(tracks);
```

### 5. Dependency Injection

Riverpod zapewnia DI:
```dart
// Provider dostępny globalnie
ref.read(manifestNotifierProvider.notifier).syncManifest();
```

## 🔐 Stan aplikacji jako źródło prawdy

### Single Source of Truth

**manifestNotifierProvider** jest SSOT dla nagrań:
- Wszystkie inne providery (filteredTracks, availableBooks) są **derived**
- Mutacje tylko przez notifier methods
- Cache w SharedPreferences jako backup

### State Flow

```
User Action → Notifier Method → Update State → Cache → Notify Listeners → UI Rebuild
```

## 🧩 Rozszerzalność

### Dodanie nowej funkcjonalności

**Przykład: System zakładek (bookmarks)**

1. **Model:** Dodaj `List<String> bookmarks` do `AudioTrack`
2. **Provider:** Utwórz `bookmarkNotifierProvider`
3. **UI:** Dodaj ikonę zakładki w track tile
4. **Persistence:** Zapisz w SharedPreferences
5. **Screen:** Nowy `BookmarksScreen` z przefiltrowaną listą
6. **Router:** Dodaj route w `app_router.dart`

### Migracja do nowej architektury

Jeśli będziesz migrować (np. do Redux, BLoC):

1. **Zachowaj Model Layer** - to jest niezależne
2. **Zamień Provider Layer** - implementuj te same metody w nowej architekturze
3. **UI może zostać** - zmień tylko `ref.watch()` na odpowiednik

## 📊 Performance Considerations

### Optymalizacje

1. **Computed Providers** - używaj `Provider` dla derived state (automatyczne memoization)
2. **List operations** - używaj `where()` zamiast filtrowania ręcznego
3. **Immutability** - zapobiega nieoczekiwanym side effects
4. **Tree-shaking** - ikony są automatycznie tree-shaken w release build

### Cache Strategy

- **In-memory:** Riverpod trzyma state w pamięci
- **Persistent:** SharedPreferences dla długotrwałego cache
- **Invalidation:** Przy każdym `syncManifest()` porównujemy i mergujemy

## 🔍 Debugging

### Riverpod DevTools

```dart
// Enable logging
ProviderContainer(
  observers: [LoggerObserver()],
);
```

### State inspection

```dart
// W czasie developmentu możesz logować:
print(ref.read(manifestNotifierProvider).value);
```

### Network debugging

```dart
// W manifest_provider.dart są print statements:
print('Error downloading track: $e');
```

## ⚠️ WAŻNE: Przy każdej zmianie

**Zastanów się:**

1. Czy zmiana wpływa na przepływ danych? → **Zaktualizuj sekcję "Przepływy danych"**
2. Czy dodałeś nowy provider? → **Zaktualizuj sekcję "State Layer"**
3. Czy zmieniłeś model? → **Zaktualizuj sekcję "Model Layer"**
4. Czy dodałeś nowy pattern? → **Dodaj do "Wzorce projektowe"**
5. Czy zmiana ma wpływ na performance? → **Zaktualizuj "Performance Considerations"**

**Przykład:**
```
Dodano system placów (playlists)
→ Dodano PlaylistModel do Model Layer
→ Dodano playlistProvider do State Layer
→ Dodano nowy przepływ "Tworzenie playlisty"
→ Zaktualizowano diagram architektury
```

---

**Ostatnia aktualizacja:** 2025-11-16
**Architektura version:** 1.0
**Stack:** Flutter + Riverpod + just_audio + SharedPreferences
