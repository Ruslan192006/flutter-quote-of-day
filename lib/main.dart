import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class Quote {
  final String text;
  final String author;
  final String category;

  Quote({required this.text, required this.author, required this.category});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quote of the Day',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QuotePage(),
    );
  }
}

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  final List<Quote> _quotes = [
    Quote(text: 'Единственный способ сделать великую работу - любить то, что вы делаете.', author: 'Стив Джобс', category: 'Мотивация'),
    Quote(text: 'Жизнь - это то, что происходит, пока вы строите другие планы.', author: 'Джон Леннон', category: 'Жизнь'),
    Quote(text: 'Будущее принадлежит тем, кто верит в красоту своих мечтаний.', author: 'Элеонора Рузвельт', category: 'Мечты'),
    Quote(text: 'Успех - это способность идти от неудачи к неудаче, не теряя энтузиазма.', author: 'Уинстон Черчилль', category: 'Успех'),
    Quote(text: 'Не важно, как медленно вы идете, главное - не останавливаться.', author: 'Конфуций', category: 'Мотивация'),
    Quote(text: 'Лучшее время посадить дерево было 20 лет назад. Второе лучшее время - сейчас.', author: 'Китайская пословица', category: 'Мудрость'),
    Quote(text: 'Образование - самое мощное оружие, которым можно изменить мир.', author: 'Нельсон Мандела', category: 'Образование'),
    Quote(text: 'Счастье - это не что-то готовое. Оно приходит от ваших собственных действий.', author: 'Далай Лама', category: 'Счастье'),
    Quote(text: 'Верьте, что можете, и вы уже на полпути.', author: 'Теодор Рузвельт', category: 'Вера'),
    Quote(text: 'Единственное ограничение - это то, которое вы сами себе устанавливаете.', author: 'Неизвестен', category: 'Мотивация'),
  ];

  Quote? _currentQuote;
  List<String> _favorites = [];
  String _selectedCategory = 'Все';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _loadFavorites();
    _loadRandomQuote();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
  }

  void _loadRandomQuote() {
    final filteredQuotes = _selectedCategory == 'Все'
        ? _quotes
        : _quotes.where((q) => q.category == _selectedCategory).toList();
    
    if (filteredQuotes.isNotEmpty) {
      setState(() {
        _currentQuote = filteredQuotes[Random().nextInt(filteredQuotes.length)];
      });
      _controller.forward(from: 0.0);
    }
  }

  void _toggleFavorite() {
    if (_currentQuote != null) {
      setState(() {
        final quoteKey = '${_currentQuote!.text}|${_currentQuote!.author}';
        if (_favorites.contains(quoteKey)) {
          _favorites.remove(quoteKey);
        } else {
          _favorites.add(quoteKey);
        }
      });
      _saveFavorites();
    }
  }

  bool _isFavorite() {
    if (_currentQuote == null) return false;
    final quoteKey = '${_currentQuote!.text}|${_currentQuote!.author}';
    return _favorites.contains(quoteKey);
  }

  void _copyToClipboard() {
    if (_currentQuote != null) {
      Clipboard.setData(ClipboardData(
        text: '"${_currentQuote!.text}"\n- ${_currentQuote!.author}',
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Цитата скопирована!')),
      );
    }
  }

  List<String> get _categories {
    return ['Все', ..._quotes.map((q) => q.category).toSet().toList()..sort()];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote of the Day'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => _showFavorites(),
          ),
        ],
      ),
      body: _currentQuote == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 8,
                    children: _categories.map((category) {
                      return ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                          _loadRandomQuote();
                        },
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Card(
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.format_quote,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _currentQuote!.text,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  '- ${_currentQuote!.author}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[600],
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Chip(
                                  label: Text(_currentQuote!.category),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton.filled(
                        onPressed: _toggleFavorite,
                        icon: Icon(_isFavorite() ? Icons.favorite : Icons.favorite_border),
                        iconSize: 32,
                      ),
                      IconButton.filled(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        iconSize: 32,
                      ),
                      FloatingActionButton.extended(
                        onPressed: _loadRandomQuote,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Новая цитата'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showFavorites() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Избранные цитаты',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _favorites.isEmpty
                  ? const Center(child: Text('Нет избранных цитат'))
                  : ListView.builder(
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final parts = _favorites[index].split('|');
                        return Card(
                          child: ListTile(
                            title: Text(parts[0]),
                            subtitle: Text('- ${parts[1]}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setState(() {
                                  _favorites.removeAt(index);
                                });
                                _saveFavorites();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
