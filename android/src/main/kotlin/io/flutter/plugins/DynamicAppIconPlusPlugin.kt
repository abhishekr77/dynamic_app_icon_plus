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
      iconIdentifier in listOf("christmas", "halloween", "payme", "independance") -> iconIdentifier
      else -> {
        Log.w("DynamicAppIconPlus", "Unknown icon identifier: '$iconIdentifier'. Defaulting to 'default'.")
        "default"
      }
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // First, disable all activity aliases and MainActivity
      val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
      val availableIcons = listOf("christmas", "halloween", "payme", "independance")
      
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
        // Enable the specific activity alias
        val newComponent = ComponentName(packageName, "$packageName.${finalIconIdentifier}Activity")
        pm.setComponentEnabledSetting(newComponent, 
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
            PackageManager.DONT_KILL_APP)
        Log.i("DynamicAppIconPlus", "Icon changed to $finalIconIdentifier. ${finalIconIdentifier}Activity is now enabled.")
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
      val availableIcons = listOf("christmas", "halloween", "payme", "independance")
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
      val availableIcons = listOf("christmas", "halloween", "payme", "independance")
      
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
      val availableIcons = listOf("christmas", "halloween", "payme", "independance") // Add your icon names here
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
      
      val availableIcons = listOf("christmas", "halloween", "payme", "independance")
      result.success(availableIcons)
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error getting available icons: ${e.message}")
      result.error("GET_AVAILABLE_ICONS_ERROR", "Failed to get available icons: ${e.message}", null)
    }
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
