import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/book_filter_provider.dart';

class BookFilterDrawer extends ConsumerWidget {
  const BookFilterDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableBooks = ref.watch(availableBooksProvider);
    final selectedBook = ref.watch(bookFilterProvider);

    return Drawer(
      backgroundColor: const Color(0xFF1a1a1a),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Color(0xFFFFB300),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Filtruj po księdze',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2a2a2a)),
            // "Wszystkie" option
            ListTile(
              leading: Icon(
                selectedBook == null ? Icons.check_circle : Icons.circle_outlined,
                color: selectedBook == null
                    ? const Color(0xFFFFB300)
                    : Colors.grey[600],
              ),
              title: const Text(
                'Wszystkie',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              selected: selectedBook == null,
              selectedTileColor: const Color(0xFF2a2a2a),
              onTap: () {
                ref.read(bookFilterProvider.notifier).clearFilter();
                Navigator.of(context).pop();
              },
            ),
            const Divider(color: Color(0xFF2a2a2a)),
            // List of books
            Expanded(
              child: availableBooks.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Brak dostępnych ksiąg',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: availableBooks.length,
                      itemBuilder: (context, index) {
                        final book = availableBooks[index];
                        final isSelected = selectedBook == book;

                        return ListTile(
                          leading: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? const Color(0xFFFFB300)
                                : Colors.grey[600],
                          ),
                          title: Text(
                            book,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[300],
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: const Color(0xFF2a2a2a),
                          onTap: () {
                            ref.read(bookFilterProvider.notifier).setFilter(book);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
