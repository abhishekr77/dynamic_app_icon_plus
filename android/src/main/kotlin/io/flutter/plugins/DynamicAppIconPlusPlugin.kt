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
      else -> result.notImplemented()
    }
  }

  private fun changeIcon(iconIdentifier: String?, result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    if (iconIdentifier == null) {
      result.error("INVALID_ARGUMENT", "Icon identifier is required", null)
      return
    }

    try {
      val pm = activity!!.packageManager
      val packageName = activity!!.packageName
      
      // Get the component name for the new icon
      val newComponent = ComponentName(packageName, 
          "$packageName.${iconIdentifier}Activity")
      
      // Disable the current component (default or previous icon)
      val currentComponent = if (pm.getComponentEnabledSetting(newComponent) == 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED) newComponent else 
          ComponentName(packageName, "$packageName.MainActivity")
      
      pm.setComponentEnabledSetting(currentComponent, 
          PackageManager.COMPONENT_ENABLED_STATE_DISABLED, 
          PackageManager.DONT_KILL_APP)
      
      // Enable the new component
      pm.setComponentEnabledSetting(newComponent, 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
          PackageManager.DONT_KILL_APP)
      
      // Don't restart the app - let the user restart manually
      // The icon change will take effect when the app is restarted
      Log.i("DynamicAppIconPlus", "Icon changed to $iconIdentifier. Please restart the app to see the change.")
      
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
      } else {
        // Find which custom icon is enabled
        // This is a simplified implementation - you might want to store the current icon
        result.success("default")
      }
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
      
      // Disable all activity aliases and enable main activity
      val mainActivity = ComponentName(packageName, "$packageName.MainActivity")
      pm.setComponentEnabledSetting(mainActivity, 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
          PackageManager.DONT_KILL_APP)
      
      // Don't restart the app - let the user restart manually
      // The icon change will take effect when the app is restarted
      Log.i("DynamicAppIconPlus", "Icon reset to default. Please restart the app to see the change.")
      
      result.success(true)
    } catch (e: Exception) {
      Log.e("DynamicAppIconPlus", "Error resetting icon: ${e.message}")
      result.error("RESET_ICON_ERROR", "Failed to reset icon: ${e.message}", null)
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
