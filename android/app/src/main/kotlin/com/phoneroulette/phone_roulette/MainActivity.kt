package com.phoneroulette.phone_roulette

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.phoneroulette/direct_call"
    private val CALL_PHONE_PERMISSION_CODE = 1001
    private val PREFS_NAME = "phone_roulette_prefs"
    private val KEY_PERMISSION_REQUESTED = "call_permission_requested"
    private var pendingPhoneNumber: String? = null

    private fun hasRequestedPermissionBefore(): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_PERMISSION_REQUESTED, false)
    }

    private fun setPermissionRequested() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_PERMISSION_REQUESTED, true).apply()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "makeDirectCall" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    if (phoneNumber != null) {
                        makeDirectCall(phoneNumber, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Phone number is required", null)
                    }
                }
                "hasCallPermission" -> {
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.CALL_PHONE
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(hasPermission)
                }
                "isPermissionPermanentlyDenied" -> {
                    val isPermanentlyDenied = isPermissionPermanentlyDenied()
                    result.success(isPermanentlyDenied)
                }
                "requestCallPermission" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) 
                        != PackageManager.PERMISSION_GRANTED) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.CALL_PHONE),
                            CALL_PHONE_PERMISSION_CODE
                        )
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isPermissionPermanentlyDenied(): Boolean {
        // Permission is permanently denied if:
        // 1. We don't have the permission
        // 2. shouldShowRequestPermissionRationale returns false (user selected "Don't ask again")
        // 3. We've asked before (to distinguish from first-time ask)
        val hasPermission = ContextCompat.checkSelfPermission(
            this, Manifest.permission.CALL_PHONE
        ) == PackageManager.PERMISSION_GRANTED
        
        if (hasPermission) return false
        
        val shouldShowRationale = ActivityCompat.shouldShowRequestPermissionRationale(
            this, Manifest.permission.CALL_PHONE
        )
        
        // If we shouldn't show rationale and we've asked before, it's permanently denied
        return !shouldShowRationale && hasRequestedPermissionBefore()
    }

    private fun makeDirectCall(phoneNumber: String, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) 
            == PackageManager.PERMISSION_GRANTED) {
            try {
                val intent = Intent(Intent.ACTION_CALL)
                intent.data = Uri.parse("tel:$phoneNumber")
                startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                result.error("CALL_FAILED", e.message, null)
            }
        } else if (isPermissionPermanentlyDenied()) {
            // Permission permanently denied, don't ask again - let Dart handle fallback
            result.success(false)
        } else {
            // Request permission and store number for later
            pendingPhoneNumber = phoneNumber
            setPermissionRequested()
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                CALL_PHONE_PERMISSION_CODE
            )
            result.success(false) // Permission not granted yet
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CALL_PHONE_PERMISSION_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, make the pending call if any
                pendingPhoneNumber?.let { number ->
                    try {
                        val intent = Intent(Intent.ACTION_CALL)
                        intent.data = Uri.parse("tel:$number")
                        startActivity(intent)
                    } catch (e: Exception) {
                        // Handle error silently
                    }
                    pendingPhoneNumber = null
                }
            }
        }
    }
}
