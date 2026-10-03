package dev.glebosotov.screenshot_detect;

import android.annotation.TargetApi;
import android.app.Activity;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleEventObserver;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;
import io.flutter.plugin.common.EventChannel;

/** Observes Android 14 screenshot events while the attached activity is visible. */
public final class ScreenshotDetectPlugin
        implements FlutterPlugin, ActivityAware, EventChannel.StreamHandler {
    private EventChannel channel;
    private EventChannel.EventSink events;
    private Activity activity;
    private Lifecycle lifecycle;
    private Runnable unregister;
    private final LifecycleEventObserver lifecycleObserver = (source, event) -> {
        if (event == Lifecycle.Event.ON_STOP || event == Lifecycle.Event.ON_DESTROY) {
            stopObserving();
        } else if (event == Lifecycle.Event.ON_START) {
            startObserving();
        }
    };

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new EventChannel(binding.getBinaryMessenger(), "screenshot_detect/events");
        channel.setStreamHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        detachActivity();
        events = null;
        channel.setStreamHandler(null);
        channel = null;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink sink) {
        stopObserving();
        events = sink;
        if (Build.VERSION.SDK_INT < 34) {
            sink.error("unsupported_platform", "Screenshot detection requires Android 14 (API 34) or later.", null);
            return;
        }
        startObservingIfVisible();
    }

    @Override
    public void onCancel(Object arguments) {
        stopObserving();
        events = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
        lifecycle.addObserver(lifecycleObserver);
        startObservingIfVisible();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        detachActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        detachActivity();
    }

    private void startObservingIfVisible() {
        if (lifecycle != null && lifecycle.getCurrentState().isAtLeast(Lifecycle.State.STARTED)) {
            startObserving();
        }
    }

    private void startObserving() {
        if (Build.VERSION.SDK_INT < 34 || activity == null || events == null || unregister != null) {
            return;
        }
        try {
            unregister = Api34.register(activity, () -> {
                if (events != null) events.success(null);
            });
        } catch (SecurityException error) {
            events.error("permission_denied", error.getMessage(), null);
        }
    }

    private void stopObserving() {
        if (unregister != null) {
            unregister.run();
            unregister = null;
        }
    }

    private void detachActivity() {
        stopObserving();
        if (lifecycle != null) lifecycle.removeObserver(lifecycleObserver);
        lifecycle = null;
        activity = null;
    }

    // Keep API 34 types out of the class loaded on older Android versions.
    @TargetApi(34)
    private static final class Api34 {
        static Runnable register(Activity activity, Runnable onScreenshot) {
            Activity.ScreenCaptureCallback callback = onScreenshot::run;
            activity.registerScreenCaptureCallback(activity.getMainExecutor(), callback);
            return () -> activity.unregisterScreenCaptureCallback(callback);
        }
    }
}
