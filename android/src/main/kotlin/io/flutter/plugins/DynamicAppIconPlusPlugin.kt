package io.flutter.plugins

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** DynamicAppIconPlusPlugin */
class DynamicAppIconPlusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var context: Context? = null

  // Legacy plugin registration method for Flutter < 1.12
  companion object {
    @JvmStatic
    fun registerWith(registrar: PluginRegistry.Registrar) {
      val channel = MethodChannel(registrar.messenger(), "dynamic_app_icon_plus")
      channel.setMethodCallHandler(DynamicAppIconPlusPlugin())
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dynamic_app_icon_plus")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "changeIcon" -> {
        val iconIdentifier = call.argument<String>("iconIdentifier")
        changeIcon(iconIdentifier, result)
      }
      "isSupported" -> result.success(true) // Android supports dynamic icons
      "getCurrentIcon" -> getCurrentIcon(result)
      "resetToDefault" -> resetToDefault(result)
      "resetForDevelopment" -> resetForDevelopment(result)
      "getAvailableIcons" -> getAvailableIcons(result)
      else -> result.notImplemented()
    }
  }

  private fun changeIcon(iconIdentifier: String?, result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    // Handle null, empty, or unknown icon identifiers by defaulting to "default"
    val finalIconIdentifier = when {
      iconIdentifier.isNullOrBlank() -> "default"
      iconIdentifier == "default" -> "default"
      else -> iconIdentifier
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // Get available icons dynamically from manifest
      val availableIcons = getAvailableIconsFromManifest(pm, packageName)
      Log.d("DynamicAppIconPlus", "Requested icon: '$finalIconIdentifier'")
      Log.d("DynamicAppIconPlus", "Available icons: ${availableIcons.joinToString(", ")}")
      
      // First, disable all activity aliases and MainActivity
      val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
      
      // Disable MainActivity
      pm.setComponentEnabledSetting(mainActivity, 
          PackageManager.COMPONENT_ENABLED_STATE_DISABLED, 
          PackageManager.DONT_KILL_APP)
      
      // Disable all activity aliases
      for (iconName in availableIcons) {
        try {
          val iconComponent = ComponentName(packageName, "$packageName.${iconName}Activity")
          pm.setComponentEnabledSetting(iconComponent, 
              PackageManager.COMPONENT_ENABLED_STATE_DISABLED, 
              PackageManager.DONT_KILL_APP)
        } catch (e: Exception) {
          // Ignore errors for non-existent activities
          Log.d("DynamicAppIconPlus", "Activity alias $iconName not found, skipping")
        }
      }
      
      // Now enable only the requested icon
      if (finalIconIdentifier == "default") {
        // Enable MainActivity for default icon
        pm.setComponentEnabledSetting(mainActivity, 
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
            PackageManager.DONT_KILL_APP)
        Log.i("DynamicAppIconPlus", "Icon changed to default. MainActivity is now enabled.")
      } else {
        // Check if the requested icon exists
        if (finalIconIdentifier in availableIcons) {
          // Enable the specific activity alias
          val newComponent = ComponentName(packageName, "$packageName.${finalIconIdentifier}Activity")
          pm.setComponentEnabledSetting(newComponent, 
              PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
              PackageManager.DONT_KILL_APP)
          Log.i("DynamicAppIconPlus", "Icon changed to $finalIconIdentifier. ${finalIconIdentifier}Activity is now enabled.")
        } else {
          Log.w("DynamicAppIconPlus", "Unknown icon identifier: '$finalIconIdentifier'. Defaulting to 'default'.")
          // Enable MainActivity for default icon
          pm.setComponentEnabledSetting(mainActivity, 
              PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
              PackageManager.DONT_KILL_APP)
          Log.i("DynamicAppIconPlus", "Icon changed to default. MainActivity is now enabled.")
        }
      }
      
      // Don't restart the app - let the user restart manually
      // The icon change will take effect when the app is restarted
      Log.i("DynamicAppIconPlus", "Icon changed to $finalIconIdentifier. Please restart the app to see the change.")
      
      result.success(true)
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error changing icon: ${e.message}")
      result.error("CHANGE_ICON_ERROR", "Failed to change icon: ${e.message}", null)
    }
  }

  private fun getCurrentIcon(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // Check which activity alias is currently enabled
      val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
      val mainActivityEnabled = pm.getComponentEnabledSetting(mainActivity) == 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED
      
      if (mainActivityEnabled) {
        result.success("default")
        return
      }
      
      // Check each activity alias to see which one is enabled
      val availableIcons = getAvailableIconsFromManifest(pm, packageName)
      for (iconName in availableIcons) {
        try {
          val iconComponent = ComponentName(packageName, "$packageName.${iconName}Activity")
          val iconEnabled = pm.getComponentEnabledSetting(iconComponent) == 
              PackageManager.COMPONENT_ENABLED_STATE_ENABLED
          
          if (iconEnabled) {
            result.success(iconName)
            return
          }
        } catch (e: Exception) {
          // Ignore errors for non-existent activities
          continue
        }
      }
      
      // If no activity is enabled, return default
      result.success("default")
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error getting current icon: ${e.message}")
      result.error("GET_ICON_ERROR", "Failed to get current icon: ${e.message}", null)
    }
  }

  private fun resetToDefault(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // First, disable all activity aliases
      val availableIcons = getAvailableIconsFromManifest(pm, packageName)
      
      // Disable all activity aliases
      for (iconName in availableIcons) {
        try {
          val iconComponent = ComponentName(packageName, "$packageName.${iconName}Activity")
          pm.setComponentEnabledSetting(iconComponent, 
              PackageManager.COMPONENT_ENABLED_STATE_DISABLED, 
              PackageManager.DONT_KILL_APP)
        } catch (e: Exception) {
          // Ignore errors for non-existent activities
          Log.d("DynamicAppIconPlus", "Activity alias $iconName not found, skipping")
        }
      }
      
      // Now enable MainActivity for default icon
      val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
      pm.setComponentEnabledSetting(mainActivity, 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
          PackageManager.DONT_KILL_APP)
      
      // Don't restart the app - let the user restart manually
      // The icon change will take effect when the app is restarted
      Log.i("DynamicAppIconPlus", "Icon reset to default. MainActivity is now enabled.")
      
      result.success(true)
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error resetting icon: ${e.message}")
      result.error("RESET_ICON_ERROR", "Failed to reset icon: ${e.message}", null)
    }
  }

  private fun resetForDevelopment(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // Enable MainActivity for development
      val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
      pm.setComponentEnabledSetting(mainActivity, 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
          PackageManager.DONT_KILL_APP)
      
      // Also enable all activity aliases for development
      // This ensures the app can be launched from any icon
      val availableIcons = getAvailableIconsFromManifest(pm, packageName) // Add your icon names here
      for (iconName in availableIcons) {
        try {
          val iconComponent = ComponentName(packageName, "$packageName.${iconName}Activity")
          pm.setComponentEnabledSetting(iconComponent, 
              PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
              PackageManager.DONT_KILL_APP)
        } catch (e: Exception) {
          // Ignore errors for non-existent activities
          Log.d("DynamicAppIconPlus", "Activity alias $iconName not found, skipping")
        }
      }
      
      Log.i("DynamicAppIconPlus", "All activities enabled for development")
      result.success(true)
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error resetting for development: ${e.message}")
      result.error("RESET_DEV_ERROR", "Failed to reset for development: ${e.message}", null)
    }
  }

  private fun getAvailableIcons(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      val availableIcons = getAvailableIconsFromManifest(pm, packageName)
      result.success(availableIcons)
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error getting available icons: ${e.message}")
      result.error("GET_AVAILABLE_ICONS_ERROR", "Failed to get available icons: ${e.message}", null)
    }
  }

  private fun getAvailableIconsFromManifest(pm: PackageManager, packageName: String): List<String> {
    val availableIcons = mutableListOf<String>()
    
    try {
      // Get package info to access manifest
      val packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
      
      // Look for activity aliases in the manifest
      for (activityInfo in packageInfo.activities) {
        val activityName = activityInfo.name
        Log.d("DynamicAppIconPlus", "Found activity: $activityName")
        
        // Check if it's an activity alias (ends with Activity but not MainActivity)
        // Activity aliases are included in the activities list
        if (activityName.endsWith("Activity") && !activityName.endsWith("MainActivity")) {
          // Extract icon name from activity name (e.g., "com.example.diwaliActivity" -> "diwali")
          val iconName = activityName.substringAfterLast(".").removeSuffix("Activity")
          if (iconName.isNotEmpty()) {
            availableIcons.add(iconName)
            Log.d("DynamicAppIconPlus", "Added icon: $iconName")
          }
        }
      }
      
      Log.d("DynamicAppIconPlus", "Available icons found: ${availableIcons.joinToString(", ")}")
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error reading manifest: ${e.message}")
      // Fallback to empty list
    }
    
    return availableIcons
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
