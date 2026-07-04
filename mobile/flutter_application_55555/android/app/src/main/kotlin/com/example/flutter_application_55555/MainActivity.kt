package com.example.flutter_application_55555

import android.app.AlarmManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "app.channel.schedule_exact_alarm"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "requestExactAlarm") {
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
					val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
					if (!alarmManager.canScheduleExactAlarms()) {
						try {
							val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
							intent.data = Uri.parse("package:$packageName")
							startActivity(intent)
							result.success(true)
						} catch (e: Exception) {
							result.error("FAILED", e.message, null)
						}
					} else {
						result.success(true)
					}
				} else {
					result.success(true)
				}
			} else {
				result.notImplemented()
			}
		}
	}
}
