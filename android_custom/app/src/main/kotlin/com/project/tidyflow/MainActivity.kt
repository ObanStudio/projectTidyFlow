package com.project.tidyflow

import android.app.ActivityManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.*

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.project.tidyflow/system"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRamInfo" -> result.success(getRamInfo())
                "getBatteryTemp" -> result.success(getBatteryTemperature())
                "killBackgroundProcesses" -> result.success(optimizeRam())
                "getInstalledApps" -> result.success(getInstalledAppsInfo())
                "getStorageInfo" -> result.success(getStorageInfo())
                "getAppUsageStats" -> result.success(getAppUsageStats())
                "findDuplicatePhotos" -> result.success(findDuplicatePhotos())
                "getDownloadsSize" -> result.success(getDownloadsSize())
                "getMessengerCacheSize" -> result.success(getMessengerCacheSize())
                "getBatteryHealth" -> result.success(getBatteryHealth())
                "requestUsageStatsPermission" -> result.success(requestUsageStatsPermission())
                "requestIgnoreBatteryOptimizations" -> result.success(requestIgnoreBatteryOptimizations())
                else -> result.notImplemented()
            }
        }
    }

    private fun getRamInfo(): Map<String, Long> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        return mapOf("total" to memoryInfo.totalMem, "avail" to memoryInfo.availMem)
    }

    private fun getBatteryTemperature(): Double {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        return temp / 10.0
    }

    private fun optimizeRam(): Int {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        var killedCount = 0
        val runningApps = activityManager.runningAppProcesses
        if (runningApps != null) {
            for (processInfo in runningApps) {
                if (processInfo.processName != packageName && processInfo.importance >= ActivityManager.RunningAppProcessInfo.IMPORTANCE_BACKGROUND) {
                    val packages = processInfo.pkgList
                    for (pkg in packages) {
                        activityManager.killBackgroundProcesses(pkg)
                        killedCount++
                    }
                }
            }
        }
        return killedCount
    }

    private fun getInstalledAppsInfo(): List<Map<String, Any>> {
        val pm = packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        val appList = mutableListOf<Map<String, Any>>()

        for (app in packages) {
            if ((app.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
                appList.add(mapOf(
                    "name" to pm.getApplicationLabel(app).toString(),
                    "packageName" to app.packageName,
                    "isSystem" to false
                ))
            }
        }
        return appList
    }

    private fun getStorageInfo(): Map<String, Long> {
        val path = Environment.getDataDirectory()
        val stat = StatFs(path.path)
        val blockSize = stat.blockSizeLong
        val totalBlocks = stat.blockCountLong
        val availableBlocks = stat.availableBlocksLong
        return mapOf(
            "total" to totalBlocks * blockSize,
            "free" to availableBlocks * blockSize
        )
    }

    private fun getAppUsageStats(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - (30L * 24 * 60 * 60 * 1000)
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val result = mutableListOf<Map<String, Any>>()
        val pm = packageManager

        for (usage in stats) {
            try {
                val appInfo = pm.getApplicationInfo(usage.packageName, 0)
                val appName = pm.getApplicationLabel(appInfo).toString()
                val lastUsed = usage.lastTimeUsed
                val totalTime = usage.totalTimeInForeground
                val daysSinceLastUse = (endTime - lastUsed) / (24 * 60 * 60 * 1000)
                if (daysSinceLastUse > 30) {
                    result.add(mapOf(
                        "name" to appName,
                        "packageName" to usage.packageName,
                        "lastUsed" to lastUsed,
                        "totalTime" to totalTime,
                        "candidateForRemoval" to true
                    ))
                }
            } catch (e: Exception) {
            }
        }
        return result
    }

    private fun findDuplicatePhotos(): List<Map<String, String>> {
        val duplicates = mutableListOf<Map<String, String>>()
        val photoPaths = mutableListOf<String>()
        val hashMap = mutableMapOf<String, MutableList<String>>()

        fun getFileHash(file: File): String? {
            return try {
                val digest = MessageDigest.getInstance("MD5")
                val buffer = ByteArray(8192)
                val fis = file.inputStream()
                var bytesRead: Int
                while (fis.read(buffer).also { bytesRead = it } != -1) {
                    digest.update(buffer, 0, bytesRead)
                }
                fis.close()
                digest.digest().joinToString("") { "%02x".format(it) }
            } catch (e: Exception) {
                null
            }
        }

        fun scanDir(dir: File) {
            val files = dir.listFiles() ?: return
            for (file in files) {
                if (file.isDirectory) {
                    scanDir(file)
                } else {
                    val name = file.name.lowercase()
                    if (name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png") || name.endsWith(".webp")) {
                        photoPaths.add(file.absolutePath)
                    }
                }
            }
        }

        val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        val dcimDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM)
        scanDir(picturesDir)
        scanDir(dcimDir)

        for (path in photoPaths) {
            val file = File(path)
            val hash = getFileHash(file) ?: continue
            hashMap.getOrPut(hash) { mutableListOf() }.add(path)
        }

        for ((_, paths) in hashMap) {
            if (paths.size > 1) {
                duplicates.add(mapOf("files" to paths.joinToString(";")))
            }
        }
        return duplicates
    }

    private fun getDownloadsSize(): Long {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        fun getSize(file: File): Long {
            if (file.isDirectory) {
                var size = 0L
                file.listFiles()?.forEach { size += getSize(it) }
                return size
            } else {
                return file.length()
            }
        }
        return getSize(downloadsDir)
    }

    private fun getMessengerCacheSize(): Map<String, Long> {
        val result = mutableMapOf<String, Long>()
        val telegramDir = File(Environment.getExternalStorageDirectory(), "Telegram/Telegram Documents")
        val whatsappDir = File(Environment.getExternalStorageDirectory(), "WhatsApp/Media/.Statuses")
        fun getDirSize(dir: File): Long {
            if (!dir.exists()) return 0L
            var size = 0L
            dir.listFiles()?.forEach { file ->
                if (file.isDirectory) size += getDirSize(file)
                else size += file.length()
            }
            return size
        }
        result["telegram"] = getDirSize(telegramDir)
        result["whatsapp"] = getDirSize(whatsappDir)
        return result
    }

    private fun getBatteryHealth(): Map<String, Any> {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val health = intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN) ?: BatteryManager.BATTERY_HEALTH_UNKNOWN
        val healthString = when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
            else -> "Unknown"
        }
        val chargeCounter = intent?.getIntExtra(BatteryManager.EXTRA_CHARGE_COUNTER, -1) ?: -1
        val capacity = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        return mapOf("health" to healthString, "chargeCounter" to chargeCounter, "capacity" to capacity)
    }

    private fun requestUsageStatsPermission(): Boolean {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    private fun requestIgnoreBatteryOptimizations(): Boolean {
        try {
            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            return true
        } catch (e: Exception) {
            return false
        }
    }
}
