import 'dart:math';

import '../models/roulette_contact.dart';

/// Service for weighted random selection
class RouletteService {
  final Random _random = Random();

  /// Select a random contact using weighted selection based on closeness
  /// Higher closeness = more "tickets" in the raffle
  RouletteContact? selectWeightedRandom(List<RouletteContact> contacts) {
    if (contacts.isEmpty) {
      return null;
    }

    if (contacts.length == 1) {
      return contacts.first;
    }

    // Calculate total tickets (sum of closeness values)
    final totalTickets = contacts.fold<int>(0, (sum, c) => sum + c.closeness);

    if (totalTickets == 0) {
      // Fallback to uniform random if all closeness values are 0
      return contacts[_random.nextInt(contacts.length)];
    }

    // Pick a random ticket
    int ticket = _random.nextInt(totalTickets);

    // Find the winning contact
    int cumulative = 0;
    for (final contact in contacts) {
      cumulative += contact.closeness;
      if (ticket < cumulative) {
        return contact;
      }
    }

    // Fallback (shouldn't happen)
    return contacts.last;
  }

  /// Get a list of contacts for spinning animation
  /// Returns a shuffled list that ends with the winner
  List<RouletteContact> getSpinSequence(
    List<RouletteContact> contacts,
    RouletteContact winner, {
    int spinCount = 20,
  }) {
    if (contacts.isEmpty) return [];

    final sequence = <RouletteContact>[];
    final shuffled = List<RouletteContact>.from(contacts)..shuffle(_random);

    // Generate spin sequence
    for (int i = 0; i < spinCount; i++) {
      sequence.add(shuffled[i % shuffled.length]);
    }

    // Ensure winner is at the end
    sequence.add(winner);

    return sequence;
  }
}
