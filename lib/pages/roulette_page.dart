import 'dart:async';

import 'package:flutter/material.dart';

import '../models/roulette_contact.dart';
import '../services/database_service.dart';
import '../services/direct_call_service.dart';
import '../services/roulette_service.dart';

/// Main roulette page with spin and call functionality
class RoulettePage extends StatefulWidget {
  const RoulettePage({super.key});

  @override
  State<RoulettePage> createState() => RoulettePageState();
}

class RoulettePageState extends State<RoulettePage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final RouletteService _rouletteService = RouletteService();
  final DirectCallService _callService = DirectCallService();

  List<RouletteContact> _contacts = [];
  bool _isLoading = true;

  // Spin state
  bool _isSpinning = false;
  RouletteContact? _currentDisplay;
  RouletteContact? _winner;
  int _spinIndex = 0;
  List<RouletteContact> _spinSequence = [];

  // Countdown state
  bool _showingCountdown = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Public method to refresh contacts - called when tab becomes visible
  void refresh() {
    _loadContacts();
  }

  String? _error;

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

  void _startSpin() {
    if (_contacts.isEmpty) return;

    // Select winner
    final winner = _rouletteService.selectWeightedRandom(_contacts);
    if (winner == null) return;

    // Generate spin sequence
    _spinSequence = _rouletteService.getSpinSequence(_contacts, winner);
    _winner = winner;
    _spinIndex = 0;

    setState(() {
      _isSpinning = true;
      _currentDisplay = null;
      _showingCountdown = false;
    });

    // Animate through the sequence
    _animateSpin();
  }

  void _animateSpin() {
    if (_spinIndex >= _spinSequence.length) {
      // Spin complete
      setState(() {
        _isSpinning = false;
        _currentDisplay = _winner;
      });
      _startCountdown();
      return;
    }

    // Calculate delay - starts fast, slows down at end
    final progress = _spinIndex / _spinSequence.length;
    final delay = Duration(milliseconds: (50 + (progress * 200)).toInt());

    setState(() {
      _currentDisplay = _spinSequence[_spinIndex];
    });

    _spinIndex++;
    Future.delayed(delay, _animateSpin);
  }

  void _startCountdown() {
    setState(() {
      _showingCountdown = true;
      _countdownSeconds = 7;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _makeCall();
      } else {
        setState(() => _countdownSeconds--);
      }
    });
  }

  Future<void> _cancelCall() async {
    _countdownTimer?.cancel();
    
    // Log the bailed call for shame tracking
    if (_winner != null) {
      await _dbService.logCancelledCall(
        _winner!.id,
        _winner!.displayName,
        _winner!.phoneNumber,
      );
    }
    
    setState(() {
      _showingCountdown = false;
      _winner = null;
      _currentDisplay = null;
    });
  }

  Future<void> _makeCall() async {
    if (_winner == null) return;

    // Log the call
    await _dbService.logCall(_winner!.id, _winner!.displayName);

    // Make direct call (Android) or open dialer (iOS)
    await _callService.makeCall(_winner!.phoneNumber);

    // Reset state
    setState(() {
      _showingCountdown = false;
      _winner = null;
      _currentDisplay = null;
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
              'Loading roulette pool...',
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
              Icon(Icons.casino, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No contacts in roulette',
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

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height - 150, // Account for nav
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Contact count
              Text(
                '${_contacts.length} contacts ready',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // Display area
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 120,
                child: _buildDisplayArea(),
              ),

              const SizedBox(height: 24),

              // Action button(s)
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayArea() {
    if (_currentDisplay == null && !_isSpinning) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino,
            size: 48,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Press SPIN to start',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Name
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: Text(
            _currentDisplay?.displayName ?? '',
            key: ValueKey(_currentDisplay?.id ?? 'empty'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _showingCountdown
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),

        if (_currentDisplay != null) ...[
          const SizedBox(height: 4),
          Text(
            _currentDisplay!.phoneNumber,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],

        // Countdown display
        if (_showingCountdown) ...[
          const SizedBox(height: 16),
          Text(
            'Calling in $_countdownSeconds...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton() {
    if (_showingCountdown) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: _makeCall,
            icon: const Icon(Icons.phone),
            label: const Text('CALL NOW'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _cancelCall,
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: _isSpinning ? null : _startSpin,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        _isSpinning ? 'SPINNING...' : 'SPIN',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
