import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_contacts/flutter_contacts.dart';

import '../models/roulette_contact.dart';

// #region agent log
void _debugLog(String location, String message, Map<String, dynamic> data, String hypothesisId) {
  debugPrint('[DEBUG][$hypothesisId] $location: $message | $data');
}
// #endregion

/// Service for accessing device contacts
class ContactsService {
  /// Check if contacts are supported on this platform
  bool get isSupported {
    // #region agent log
    final result = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    _debugLog('contacts_service.dart:isSupported', 'Platform check', {'kIsWeb': kIsWeb, 'isAndroid': Platform.isAndroid, 'isIOS': Platform.isIOS, 'result': result}, 'H1');
    // #endregion
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Request permission to access contacts (readonly - we only need to read, not write)
  Future<bool> requestPermission() async {
    // #region agent log
    _debugLog('contacts_service.dart:requestPermission', 'Called', {'isSupported': isSupported}, 'H2');
    // #endregion
    if (!isSupported) return false;
    try {
      // Use readonly: true since we only have READ_CONTACTS permission in manifest
      final result = await FlutterContacts.requestPermission(readonly: true);
      // #region agent log
      _debugLog('contacts_service.dart:requestPermission', 'FlutterContacts.requestPermission(readonly:true) returned', {'result': result}, 'H2');
      // #endregion
      return result;
    } catch (e) {
      // #region agent log
      _debugLog('contacts_service.dart:requestPermission', 'Exception caught', {'error': e.toString()}, 'H3');
      // #endregion
      return false;
    }
  }

  /// Check if we have contacts permission
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    return await FlutterContacts.requestPermission(readonly: true);
  }

  /// Get all contacts with phone numbers
  Future<List<Contact>> getAllContacts() async {
    // #region agent log
    _debugLog('contacts_service.dart:getAllContacts', 'Called', {'isSupported': isSupported}, 'H2');
    // #endregion
    if (!isSupported) return [];
    
    final hasPermission = await requestPermission();
    // #region agent log
    _debugLog('contacts_service.dart:getAllContacts', 'After requestPermission', {'hasPermission': hasPermission}, 'H2');
    // #endregion
    if (!hasPermission) {
      return [];
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    // Filter to only contacts with phone numbers
    // #region agent log
    _debugLog('contacts_service.dart:getAllContacts', 'Got contacts', {'totalCount': contacts.length, 'withPhonesCount': contacts.where((c) => c.phones.isNotEmpty).length}, 'H2');
    // #endregion
    return contacts.where((c) => c.phones.isNotEmpty).toList();
  }

  /// Search contacts by name
  Future<List<Contact>> searchContacts(String query) async {
    if (query.isEmpty) {
      return getAllContacts();
    }

    final allContacts = await getAllContacts();
    final lowerQuery = query.toLowerCase();

    return allContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Convert a flutter_contacts Contact to our RouletteContact model
  RouletteContact contactToRouletteContact(Contact contact, {int closeness = 3}) {
    // Get the first phone number, preferring mobile numbers
    String phoneNumber = '';
    if (contact.phones.isNotEmpty) {
      // Try to find a mobile number first
      final mobile = contact.phones.firstWhere(
        (p) => p.label == PhoneLabel.mobile,
        orElse: () => contact.phones.first,
      );
      phoneNumber = mobile.number;
    }

    return RouletteContact(
      id: contact.id,
      displayName: contact.displayName,
      phoneNumber: phoneNumber,
      closeness: closeness,
    );
  }
}
