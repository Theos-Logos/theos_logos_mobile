import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_track.dart';
import 'manifest_provider.dart';

// Biblical order of books
const List<String> biblicalOrder = [
  // Stary Testament - Pięcioksiąg
  'Rodzaju',
  'Wyjścia',
  'Kapłańska',
  'Liczb',
  'Powtórzonego Prawa',

  // Księgi historyczne
  'Jozuego',
  'Sędziów',
  'Rut',
  '1 Samuela',
  '2 Samuela',
  '1 Królewska',
  '2 Królewska',
  '1 Kronik',
  '2 Kronik',
  'Ezdrasza',
  'Nehemiasza',
  'Estery',

  // Księgi poetyckie i mądrościowe
  'Joba',
  'Psalmy',
  'Przysłów',
  'Koheleta',
  'Pieśń nad Pieśniami',

  // Prorocy więksi
  'Izajasza',
  'Jeremiasza',
  'Lamentacje',
  'Ezechiela',
  'Daniela',

  // Prorocy mniejsi
  'Ozeasza',
  'Joela',
  'Amosa',
  'Abdiasza',
  'Jonasza',
  'Micheasza',
  'Nahuma',
  'Habakuka',
  'Sofoniasza',
  'Aggeusza',
  'Zachariasza',
  'Malachiasza',

  // Nowy Testament - Ewangelie
  'Mateusza',
  'Marka',
  'Łukasza',
  'Jana',

  // Dzieje Apostolskie
  'Dzieje Apostolskie',

  // Listy Pawła
  'Rzymian',
  '1 Koryntian',
  '2 Koryntian',
  'Galatów',
  'Efezjan',
  'Filipian',
  'Kolosan',
  '1 Tesaloniczan',
  '2 Tesaloniczan',
  '1 Tymoteusza',
  '2 Tymoteusza',
  'Tytusa',
  'Filemona',
  'Hebrajczyków',

  // Listy katolickie
  'Jakuba',
  '1 Piotra',
  '2 Piotra',
  '1 Jana',
  '2 Jana',
  '3 Jana',
  'Judy',

  // Apokalipsa
  'Apokalipsa',
];

class BookFilterNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // null means "Wszystkie" (no filter)
  }

  void setFilter(String? bookName) {
    state = bookName;
  }

  void clearFilter() {
    state = null;
  }
}

// Provider declaration
final bookFilterProvider = NotifierProvider<BookFilterNotifier, String?>(() {
  return BookFilterNotifier();
});

// Provider that returns list of available books from tracks
final availableBooksProvider = Provider<List<String>>((ref) {
  final tracksAsync = ref.watch(manifestNotifierProvider);

  return tracksAsync.when(
    data: (tracks) {
      // Extract unique book names from the 'book' field
      final bookNames = <String>{};
      for (final track in tracks) {
        if (track.book != null && track.book!.isNotEmpty) {
          bookNames.add(track.book!);
        }
      }

      // Sort by biblical order
      final bookList = bookNames.toList();
      bookList.sort((a, b) {
        final indexA = biblicalOrder.indexOf(a);
        final indexB = biblicalOrder.indexOf(b);

        // If both books are in the biblical order list, sort by that order
        if (indexA != -1 && indexB != -1) {
          return indexA.compareTo(indexB);
        }

        // If only one is in the list, prioritize it
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;

        // If neither is in the list, sort alphabetically
        return a.compareTo(b);
      });

      return bookList;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider that returns filtered tracks based on selected book
final filteredTracksProvider = Provider<List<AudioTrack>>((ref) {
  final tracksAsync = ref.watch(manifestNotifierProvider);
  final selectedBook = ref.watch(bookFilterProvider);

  return tracksAsync.when(
    data: (tracks) {
      if (selectedBook == null) {
        return tracks; // No filter, return all
      }

      // Filter tracks by book name
      return tracks.where((track) {
        return track.book == selectedBook;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
