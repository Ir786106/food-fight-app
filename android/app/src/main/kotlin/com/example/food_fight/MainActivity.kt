package com.example.food_fight

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.StatFs
import android.provider.Settings
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.food_fight/package_verifier"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Handle splash screen transition using androidx.core:core-splashscreen
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledCertSha256" -> {
                    try {
                        val cert = getInstalledSignatureSha256()
                        result.success(cert)
                    } catch (e: Exception) {
                        result.error("CERT_ERROR", e.localizedMessage, null)
                    }
                }
                "verifyApk" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath == null) {
                        result.error("INVALID_ARGS", "apkPath is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val verificationResult = verifyApk(apkPath)
                        result.success(verificationResult)
                    } catch (e: Exception) {
                        result.error("VERIFY_ERROR", e.localizedMessage, null)
                    }
                }
                "canRequestPackageInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallUnknownAppsSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            val intent = Intent(Settings.ACTION_SECURITY_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.localizedMessage, null)
                    }
                }
                "checkGooglePlayServices" -> {
                    try {
                        val gApi = GoogleApiAvailability.getInstance()
                        val resultCode = gApi.isGooglePlayServicesAvailable(this)
                        val isAvailable = (resultCode == ConnectionResult.SUCCESS)
                        val isUserResolvable = gApi.isUserResolvableError(resultCode)
                        val errorString = gApi.getErrorString(resultCode)
                        result.success(mapOf(
                            "isAvailable" to isAvailable,
                            "resultCode" to resultCode,
                            "isUserResolvable" to isUserResolvable,
                            "errorString" to errorString
                        ))
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "isAvailable" to false,
                            "resultCode" to -1,
                            "isUserResolvable" to false,
                            "errorString" to (e.localizedMessage ?: "Unknown error")
                        ))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledSignatureSha256(): String? {
        return try {
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                PackageManager.GET_SIGNING_CERTIFICATES
            } else {
                @Suppress("DEPRECATION")
                PackageManager.GET_SIGNATURES
            }
            val packageInfo = packageManager.getPackageInfo(packageName, flags)
            getSignaturesSha256(packageInfo).firstOrNull()
        } catch (e: Exception) {
            null
        }
    }

    private fun verifyApk(apkPath: String): Map<String, Any?> {
        val file = File(apkPath)
        if (!file.exists()) {
            return mapOf(
                "success" to false,
                "errorCode" to "FILE_NOT_FOUND",
                "errorMessage" to "The downloaded APK file was not found."
            )
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_SIGNATURES
        }

        val archiveInfo = packageManager.getPackageArchiveInfo(apkPath, flags)
            ?: return mapOf(
                "success" to false,
                "errorCode" to "PARSE_ERROR",
                "errorMessage" to "Android could not parse the downloaded APK package. The file may be incomplete or corrupted."
            )

        val archiveCerts = getSignaturesSha256(archiveInfo)
        val archiveCert = archiveCerts.firstOrNull() ?: ""

        val installedCert = getInstalledSignatureSha256() ?: ""
        val matchesSignature = installedCert.isNotEmpty() && archiveCert.isNotEmpty() &&
                installedCert.equals(archiveCert, ignoreCase = true)

        val installedVersionCode = getInstalledVersionCode()
        val archiveVersionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            archiveInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            archiveInfo.versionCode.toLong()
        }

        val isDowngrade = archiveVersionCode < installedVersionCode

        // Check storage space (minimum 120MB recommended)
        val stat = StatFs(cacheDir.absolutePath)
        val availableBytes = stat.availableBlocksLong * stat.blockSizeLong
        val hasEnoughStorage = availableBytes > 120 * 1024 * 1024

        val canInstallPackages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }

        val errorCode = when {
            !matchesSignature && installedCert.isNotEmpty() -> "SIGNATURE_MISMATCH"
            isDowngrade -> "VERSION_DOWNGRADE"
            !hasEnoughStorage -> "INSUFFICIENT_STORAGE"
            !canInstallPackages -> "UNKNOWN_SOURCES_BLOCKED"
            else -> "OK"
        }

        return mapOf(
            "success" to (errorCode == "OK"),
            "matchesSignature" to matchesSignature,
            "installedCertSha256" to installedCert,
            "archiveCertSha256" to archiveCert,
            "isDowngrade" to isDowngrade,
            "installedVersionCode" to installedVersionCode,
            "archiveVersionCode" to archiveVersionCode,
            "archivePackageName" to (archiveInfo.packageName ?: ""),
            "hasEnoughStorage" to hasEnoughStorage,
            "availableBytes" to availableBytes,
            "canRequestPackageInstalls" to canInstallPackages,
            "errorCode" to errorCode
        )
    }

    private fun getInstalledVersionCode(): Long {
        return try {
            val info = packageManager.getPackageInfo(packageName, 0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
        } catch (e: Exception) {
            0L
        }
    }

    private fun getSignaturesSha256(info: PackageInfo): List<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signingInfo = info.signingInfo
            if (signingInfo != null) {
                if (signingInfo.hasMultipleSigners()) {
                    signingInfo.apkContentsSigners
                } else {
                    signingInfo.signingCertificateHistory
                }
            } else {
                null
            }
        } else {
            @Suppress("DEPRECATION")
            info.signatures
        }

        if (signatures == null || signatures.isEmpty()) {
            return emptyList()
        }

        val md = MessageDigest.getInstance("SHA-256")
        return signatures.map { sig ->
            val digest = md.digest(sig.toByteArray())
            digest.joinToString("") { "%02x".format(it) }
        }
    }
}
