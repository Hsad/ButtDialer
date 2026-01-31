import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/call_log_entry.dart';
import '../services/database_service.dart';
import '../services/direct_call_service.dart';

/// Page showing call history and statistics
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  final DatabaseService _dbService = DatabaseService();
  final DirectCallService _callService = DirectCallService();

  int _totalCalls = 0;
  int _uniqueContacts = 0;
  int _totalCancelled = 0;
  int _pendingCancelled = 0;
  Map<String, int> _callCounts = {};
  List<CallLogEntry> _recentCalls = [];
  List<Map<String, dynamic>> _pendingCalls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// Public method to refresh stats - called when tab becomes visible
  void refresh() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _totalCalls = await _dbService.getTotalCallCount();
      _uniqueContacts = await _dbService.getUniqueContactsCalledCount();
      _callCounts = await _dbService.getCallCountsByContact();
      _recentCalls = await _dbService.getCallLog(limit: 50);
      _totalCancelled = await _dbService.getTotalCancelledCount();
      _pendingCancelled = await _dbService.getPendingCancelledCount();
      _pendingCalls = await _dbService.getPendingCancelledCalls();
    } catch (e) {
      _error = e.toString();
    }

    setState(() => _isLoading = false);
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
              'Loading call history...',
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
                'Error loading stats',
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
                onPressed: _loadStats,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_totalCalls == 0 && _totalCancelled == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No calls made yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use the Spin tab to make roulette calls',
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
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Summary stats
          _buildSummaryCard(),

          const SizedBox(height: 8),

          // Pending calls (shame section)
          if (_pendingCalls.isNotEmpty) ...[
            _buildPendingCallsCard(),
            const SizedBox(height: 8),
          ],

          // Top contacts
          if (_callCounts.isNotEmpty) ...[
            _buildTopContactsCard(),
            const SizedBox(height: 8),
          ],

          // Recent calls
          if (_recentCalls.isNotEmpty) _buildRecentCallsCard(),
        ],
      ),
    );
  }

  Future<void> _redeemCall(Map<String, dynamic> cancelledCall) async {
    final phoneNumber = cancelledCall['phone_number'] as String;

    // Make direct call (Android) or open dialer (iOS)
    final success = await _callService.makeCall(phoneNumber);
    
    if (success) {
      // Mark as redeemed
      await _dbService.redeemCancelledCall(cancelledCall['id'] as int);
      // Refresh stats
      _loadStats();
    }
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.phone,
                  value: _totalCalls.toString(),
                  label: 'Calls Made',
                  color: Colors.green,
                ),
                _StatItem(
                  icon: Icons.phone_missed,
                  value: _totalCancelled.toString(),
                  label: 'Bailed',
                  color: Colors.red,
                ),
                _StatItem(
                  icon: Icons.people,
                  value: _uniqueContacts.toString(),
                  label: 'Contacts',
                ),
              ],
            ),
            if (_pendingCancelled > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text(
                      '$_pendingCancelled call${_pendingCancelled == 1 ? '' : 's'} to redeem',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCallsCard() {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Card(
      color: Colors.orange[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Icon(Icons.sentiment_dissatisfied, size: 18, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Text(
                  'Calls You Bailed On',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Call them to clear your conscience!',
              style: TextStyle(fontSize: 10, color: Colors.orange[600]),
            ),
          ),
          const Divider(height: 12),
          ..._pendingCalls.map((call) {
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
              call['timestamp'] as int,
            );
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.orange[300],
                child: Text(
                  (call['contact_name'] as String).isNotEmpty
                      ? (call['contact_name'] as String)[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(
                call['contact_name'] as String,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Bailed ${dateFormat.format(timestamp)}',
                style: TextStyle(fontSize: 10, color: Colors.orange[600]),
              ),
              trailing: ElevatedButton.icon(
                onPressed: () => _redeemCall(call),
                icon: const Icon(Icons.phone, size: 14),
                label: const Text('CALL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopContactsCard() {
    final topContacts = _callCounts.entries.take(5).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              'Most Called',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...topContacts.map((entry) => ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecentCallsCard() {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              'Recent Calls',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ..._recentCalls.take(20).map((call) => ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: const Icon(Icons.phone_forwarded, size: 18),
                title: Text(
                  call.contactName,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  dateFormat.format(call.timestamp),
                  style: const TextStyle(fontSize: 10),
                ),
              )),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;
    return Column(
      children: [
        Icon(icon, size: 24, color: effectiveColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
