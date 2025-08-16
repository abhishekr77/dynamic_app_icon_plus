package io.flutter.plugins;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

import java.util.HashMap;
import java.util.Map;

/** DynamicAppIconPlusPlugin */
public class DynamicAppIconPlusPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Activity activity;
  private Context context;

  // Legacy plugin registration method for Flutter < 1.12
  public static void registerWith(PluginRegistry.Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "dynamic_app_icon_plus");
    channel.setMethodCallHandler(new DynamicAppIconPlusPlugin());
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "dynamic_app_icon_plus");
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.getApplicationContext();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "changeIcon":
        String iconIdentifier = call.argument("iconIdentifier");
        changeIcon(iconIdentifier, result);
        break;
      case "isSupported":
        result.success(true); // Android supports dynamic icons
        break;
      case "getCurrentIcon":
        getCurrentIcon(result);
        break;
      case "resetToDefault":
        resetToDefault(result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void changeIcon(String iconIdentifier, Result result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null);
      return;
    }

    try {
      PackageManager pm = activity.getPackageManager();
      String packageName = activity.getPackageName();
      
      // Get the component name for the new icon
      ComponentName newComponent = new ComponentName(packageName, 
          packageName + "." + iconIdentifier + "Activity");
      
      // Disable the current component (default or previous icon)
      ComponentName currentComponent = pm.getComponentEnabledSetting(newComponent) == 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED ? newComponent : 
          new ComponentName(packageName, packageName + ".MainActivity");
      
      pm.setComponentEnabledSetting(currentComponent, 
          PackageManager.COMPONENT_ENABLED_STATE_DISABLED, 
          PackageManager.DONT_KILL_APP);
      
      // Enable the new component
      pm.setComponentEnabledSetting(newComponent, 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
          PackageManager.DONT_KILL_APP);
      
      // Restart the app to apply the icon change
      Intent intent = new Intent(activity, activity.getClass());
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
      activity.startActivity(intent);
      activity.finish();
      
      result.success(true);
    } catch (Exception e) {
      Log.e("DynamicAppIconPlus", "Error changing icon: " + e.getMessage());
      result.error("ICON_CHANGE_ERROR", "Failed to change icon: " + e.getMessage(), null);
    }
  }

  private void getCurrentIcon(Result result) {
    if (activity == null) {
      result.success(null);
      return;
    }

    try {
      PackageManager pm = activity.getPackageManager();
      String packageName = activity.getPackageName();
      
      // Check which activity is currently enabled
      ComponentName mainActivity = new ComponentName(packageName, packageName + ".MainActivity");
      int mainState = pm.getComponentEnabledSetting(mainActivity);
      
      if (mainState == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
        result.success(null); // Default icon is active
        return;
      }
      
      // Check for custom icons (this is a simplified approach)
      // In a real implementation, you'd need to track which icon is currently active
      result.success("default");
    } catch (Exception e) {
      Log.e("DynamicAppIconPlus", "Error getting current icon: " + e.getMessage());
      result.success(null);
    }
  }

  private void resetToDefault(Result result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null);
      return;
    }

    try {
      PackageManager pm = activity.getPackageManager();
      String packageName = activity.getPackageName();
      
      // Disable all custom icon activities
      // This is a simplified approach - you'd need to know all your custom activities
      ComponentName mainActivity = new ComponentName(packageName, packageName + ".MainActivity");
      
      // Enable the main activity
      pm.setComponentEnabledSetting(mainActivity, 
          PackageManager.COMPONENT_ENABLED_STATE_ENABLED, 
          PackageManager.DONT_KILL_APP);
      
      // Restart the app
      Intent intent = new Intent(activity, activity.getClass());
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
      activity.startActivity(intent);
      activity.finish();
      
      result.success(true);
    } catch (Exception e) {
      Log.e("DynamicAppIconPlus", "Error resetting icon: " + e.getMessage());
      result.error("ICON_RESET_ERROR", "Failed to reset icon: " + e.getMessage(), null);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }
}
