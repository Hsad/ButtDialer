import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../services/contacts_service.dart';
import '../services/database_service.dart';

/// Page for selecting which contacts to include in the roulette
class SelectContactsPage extends StatefulWidget {
  const SelectContactsPage({super.key});

  @override
  State<SelectContactsPage> createState() => SelectContactsPageState();
}

class SelectContactsPageState extends State<SelectContactsPage> {
  final ContactsService _contactsService = ContactsService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _platformSupported = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Public method to refresh selected IDs - called when tab becomes visible
  Future<void> refresh() async {
    final selectedIds = await _dbService.getSelectedContactIds();
    setState(() => _selectedIds = selectedIds);
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    // Check platform support
    _platformSupported = _contactsService.isSupported;
    if (!_platformSupported) {
      setState(() => _isLoading = false);
      return;
    }

    _hasPermission = await _contactsService.requestPermission();
    if (!_hasPermission) {
      setState(() => _isLoading = false);
      return;
    }

    _allContacts = await _contactsService.getAllContacts();
    _filteredContacts = _allContacts;
    _selectedIds = await _dbService.getSelectedContactIds();

    setState(() => _isLoading = false);
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredContacts = _allContacts
            .where((c) => c.displayName.toLowerCase().contains(lowerQuery))
            .toList();
      }
    });
  }

  Future<void> _toggleContact(Contact contact) async {
    final isSelected = _selectedIds.contains(contact.id);

    if (isSelected) {
      await _dbService.removeContact(contact.id);
      setState(() => _selectedIds.remove(contact.id));
    } else {
      final rouletteContact = _contactsService.contactToRouletteContact(contact);
      await _dbService.addContact(rouletteContact);
      setState(() => _selectedIds.add(contact.id));
    }
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
              'Loading contacts...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Requesting permission',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    if (!_platformSupported) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_android, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Android/iOS Only',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Contact access requires a mobile device.\nBuild and install on your phone to use.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.contacts, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Contacts permission required',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadContacts,
                child: const Text('Grant Access'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Compact search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterContacts('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: _filterContacts,
          ),
        ),

        // Selected count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '${_selectedIds.length} selected',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Contact list
        Expanded(
          child: _filteredContacts.isEmpty
              ? const Center(
                  child: Text(
                    'No contacts found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    final isSelected = _selectedIds.contains(contact.id);
                    final phoneNumber = contact.phones.isNotEmpty
                        ? contact.phones.first.number
                        : 'No number';

                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        phoneNumber,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleContact(contact),
                        visualDensity: VisualDensity.compact,
                      ),
                      onTap: () => _toggleContact(contact),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
