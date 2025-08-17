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
        val availableIcons = call.argument<List<String>>("availableIcons") ?: listOf()
        val defaultIcon = call.argument<String>("defaultIcon") ?: "default"
        changeIcon(iconIdentifier, availableIcons, defaultIcon, result)
      }
      "isSupported" -> result.success(true) // Android supports dynamic icons
      "getCurrentIcon" -> getCurrentIcon(result)
      "resetToDefault" -> {
        val availableIcons = call.argument<List<String>>("availableIcons") ?: listOf()
        val defaultIcon = call.argument<String>("defaultIcon") ?: "default"
        resetToDefault(availableIcons, defaultIcon, result)
      }
      "resetForDevelopment" -> {
        val availableIcons = call.argument<List<String>>("availableIcons") ?: listOf()
        resetForDevelopment(availableIcons, result)
      }
      "getAvailableIcons" -> getAvailableIcons(result)
      else -> result.notImplemented()
    }
  }

  private fun changeIcon(iconIdentifier: String?, availableIcons: List<String>, defaultIcon: String, result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available. The app might not be fully loaded yet.", null)
      return
    }

    // Handle null, empty, or unknown icon identifiers by defaulting to configured default icon
    val finalIconIdentifier = when {
      iconIdentifier.isNullOrBlank() -> defaultIcon
      iconIdentifier == "default" -> defaultIcon // "default" now refers to the configured default icon
      iconIdentifier in availableIcons -> iconIdentifier // Use dynamic list from YAML
      else -> {
        Log.w("DynamicAppIconPlus", "Unknown icon identifier: '$iconIdentifier'. Available icons: ${availableIcons.joinToString()}. Defaulting to configured default: '$defaultIcon'.")
        defaultIcon
      }
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // First, disable all activity aliases and MainActivity
      val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
      
      // Disable MainActivity
      pm.setComponentEnabledSetting(mainActivity, 
          PackageManager.COMPONENT_ENABLED_STATE_DISABLED, 
          PackageManager.DONT_KILL_APP)
      
      // Disable all activity aliases using the dynamic list
      for (iconName in availableIcons) {
        try {
          val iconComponent = ComponentName(packageName, "$packageName.${iconName}Activity")
          pm.setComponentEnabledSetting(iconComponent, 
              PackageManager.COMPONENT_ENABLED_STATE_DISABLED, 
              PackageManager.DONT_KILL_APP)
        } catch (e: Exception) {
          // Ignore errors for non-existent activities (they might have been removed)
          Log.d("DynamicAppIconPlus", "Activity alias $iconName not found, skipping (may have been removed from config)")
        }
      }
      
      // Now enable only the requested icon
      if (finalIconIdentifier == defaultIcon) {
        // Enable the default activity alias for the configured default icon
        try {
          val defaultComponent = ComponentName(packageName, "$packageName.${defaultIcon}Activity")
          pm.setComponentEnabledSetting(defaultComponent, 
              PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
              PackageManager.DONT_KILL_APP)
          Log.i("DynamicAppIconPlus", "Icon changed to configured default: $defaultIcon. ${defaultIcon}Activity is now enabled.")
        } catch (e: Exception) {
          // If default activity alias doesn't exist, enable MainActivity
          Log.w("DynamicAppIconPlus", "Default activity alias not found, enabling MainActivity instead")
          pm.setComponentEnabledSetting(mainActivity, 
              PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
              PackageManager.DONT_KILL_APP)
          Log.i("DynamicAppIconPlus", "Icon changed to default. MainActivity is now enabled.")
        }
      } else {
        // Enable the specific activity alias
        try {
          val newComponent = ComponentName(packageName, "$packageName.${finalIconIdentifier}Activity")
          pm.setComponentEnabledSetting(newComponent, 
              PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
              PackageManager.DONT_KILL_APP)
          Log.i("DynamicAppIconPlus", "Icon changed to $finalIconIdentifier. ${finalIconIdentifier}Activity is now enabled.")
        } catch (e: Exception) {
          Log.e("DynamicAppIconPlus", "Activity alias ${finalIconIdentifier}Activity not found. It may have been removed from the configuration.")
          result.error("ICON_NOT_FOUND", "Icon '$finalIconIdentifier' not found. It may have been removed from the configuration.", null)
          return
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
      
      // Check if default activity alias is enabled
      val defaultActivity = ComponentName(packageName, "$packageName.defaultActivity")
      val defaultActivityEnabled = pm.getComponentEnabledSetting(defaultActivity) == 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED
      
      if (defaultActivityEnabled) {
        result.success("default")
        return
      }
      
      if (mainActivityEnabled) {
        result.success("default")
        return
      }
      
      // We need to get available icons from somewhere - for now, we'll use a fallback
      // In a real implementation, this should be passed from the Dart side
      val fallbackIcons = listOf("christmas", "halloween", "payme", "independance", "diwali", "new_year", "janmastami")
      
      // Check each activity alias to see which one is enabled
      for (iconName in fallbackIcons) {
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

  private fun resetToDefault(availableIcons: List<String>, defaultIcon: String, result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // First, disable all activity aliases
      // Disable all activity aliases using the dynamic list
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
      
      // Now enable the configured default icon
      try {
        val defaultComponent = ComponentName(packageName, "$packageName.${defaultIcon}Activity")
        pm.setComponentEnabledSetting(defaultComponent, 
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
            PackageManager.DONT_KILL_APP)
        Log.i("DynamicAppIconPlus", "Icon reset to configured default: $defaultIcon. ${defaultIcon}Activity is now enabled.")
      } catch (e: Exception) {
        // If default activity alias doesn't exist, enable MainActivity
        Log.w("DynamicAppIconPlus", "Default activity alias not found, enabling MainActivity instead")
        val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
        pm.setComponentEnabledSetting(mainActivity, 
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
            PackageManager.DONT_KILL_APP)
        Log.i("DynamicAppIconPlus", "Icon reset to default. MainActivity is now enabled.")
      }
      
      // Don't restart the app - let the user restart manually
      // The icon change will take effect when the app is restarted
      Log.i("DynamicAppIconPlus", "Icon reset to configured default: $defaultIcon. Please restart the app to see the change.")
      
      result.success(true)
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error resetting icon: ${e.message}")
      result.error("RESET_ICON_ERROR", "Failed to reset icon: ${e.message}", null)
    }
  }

  private fun resetForDevelopment(availableIcons: List<String>, result: Result) {
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
      
      Log.i("DynamicAppIconPlus", "Development mode enabled. All activities are now enabled.")
      result.success(true)
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error enabling development mode: ${e.message}")
      result.error("DEVELOPMENT_ERROR", "Failed to enable development mode: ${e.message}", null)
    }
  }

  private fun getAvailableIcons(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    try {
      // The Dart side should handle getting available icons from the YAML config
      // This method is kept for backward compatibility but returns empty list
      // Use DynamicAppIconPlus.availableIcons from Dart side instead
      result.success(listOf<String>())
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
    // Initialize the default icon when the activity is attached
    initializeDefaultIcon()
  }

  /// Initializes the default icon when the plugin is first loaded
  private fun initializeDefaultIcon() {
    if (activity == null) return
    
    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // Check if MainActivity is currently enabled (means no custom icon is set)
      val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
      val mainActivityEnabled = pm.getComponentEnabledSetting(mainActivity) == 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED
      
      if (mainActivityEnabled) {
        // If MainActivity is enabled, it means no custom icon is set
        // We should enable the default icon's activity alias
        // But we need to get the default icon from the Dart side
        // For now, we'll just log this information
        Log.i("DynamicAppIconPlus", "MainActivity is enabled. Consider calling changeIcon() to set the default icon.")
      }
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error initializing default icon: ${e.message}")
    }
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
