import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for making direct phone calls (bypasses dialer on Android)
class DirectCallService {
  static const _channel = MethodChannel('com.phoneroulette/direct_call');

  /// Check if we're on Android (direct call supported)
  bool get isDirectCallSupported => Platform.isAndroid;

  /// Check if we have the CALL_PHONE permission (Android only)
  Future<bool> hasCallPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('hasCallPermission') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request the CALL_PHONE permission (Android only)
  Future<void> requestCallPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestCallPermission');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Check if permission is permanently denied (user selected "Don't ask again")
  Future<bool> isPermissionPermanentlyDenied() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('isPermissionPermanentlyDenied') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Make a phone call - uses direct call on Android, dialer on iOS
  Future<bool> makeCall(String phoneNumber) async {
    // Clean the phone number
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (Platform.isAndroid) {
      // Try direct call on Android
      try {
        final result = await _channel.invokeMethod('makeDirectCall', {
          'phoneNumber': cleanNumber,
        });
        if (result == true) {
          return true;
        }
        // If permission not granted, fall back to dialer
        return _fallbackToDialer(cleanNumber);
      } catch (e) {
        // Fall back to dialer on error
        return _fallbackToDialer(cleanNumber);
      }
    } else {
      // iOS - always use dialer (Apple requirement)
      return _fallbackToDialer(cleanNumber);
    }
  }

  Future<bool> _fallbackToDialer(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }
}
