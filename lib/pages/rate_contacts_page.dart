import 'package:flutter/material.dart';

import '../models/roulette_contact.dart';
import '../services/database_service.dart';

/// Page for setting closeness ratings for selected contacts
class RateContactsPage extends StatefulWidget {
  const RateContactsPage({super.key});

  @override
  State<RateContactsPage> createState() => RateContactsPageState();
}

class RateContactsPageState extends State<RateContactsPage> {
  final DatabaseService _dbService = DatabaseService();

  List<RouletteContact> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  /// Public method to refresh contacts - called when tab becomes visible
  void refresh() {
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _contacts = await _dbService.getRouletteContacts();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateCloseness(RouletteContact contact, int closeness) async {
    await _dbService.updateCloseness(contact.id, closeness);
    setState(() {
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _contacts[index] = contact.copyWith(closeness: closeness);
      }
    });
  }

  Future<void> _removeContact(RouletteContact contact) async {
    await _dbService.removeContact(contact.id);
    setState(() {
      _contacts.removeWhere((c) => c.id == contact.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading selected contacts...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                'Error loading data',
                style: TextStyle(fontSize: 14, color: Colors.red[700]),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadContacts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No contacts selected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Go to Select tab to add contacts',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${_contacts.length} contacts • Slide to rate',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Contact list with sliders
        Expanded(
          child: ListView.builder(
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              return _ContactRatingTile(
                contact: contact,
                onClosenessChanged: (value) => _updateCloseness(contact, value),
                onRemove: () => _removeContact(contact),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactRatingTile extends StatelessWidget {
  final RouletteContact contact;
  final ValueChanged<int> onClosenessChanged;
  final VoidCallback onRemove;

  const _ContactRatingTile({
    required this.contact,
    required this.onClosenessChanged,
    required this.onRemove,
  });

  Color _getClosenessColor(int closeness) {
    if (closeness <= 3) return Colors.blue[300]!;
    if (closeness <= 6) return Colors.green[400]!;
    return Colors.orange[400]!;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name row with remove button
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _getClosenessColor(contact.closeness),
                  child: Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        contact.phoneNumber,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Closeness value display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getClosenessColor(contact.closeness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${contact.closeness}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey,
                ),
              ],
            ),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: contact.closeness.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: _getClosenessColor(contact.closeness),
                onChanged: (value) => onClosenessChanged(value.round()),
              ),
            ),

            // Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Acquaintance',
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                  Text(
                    'Best Friend',
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
