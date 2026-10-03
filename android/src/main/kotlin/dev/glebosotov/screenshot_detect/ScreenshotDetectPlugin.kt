package dev.glebosotov.screenshot_detect

import android.annotation.TargetApi
import android.app.Activity
import android.os.Build
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.EventChannel

/** Observes Android 14 screenshot events while the attached activity is visible. */
class ScreenshotDetectPlugin : FlutterPlugin, ActivityAware, EventChannel.StreamHandler {
    private var channel: EventChannel? = null
    private var events: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var lifecycle: Lifecycle? = null
    private var unregister: (() -> Unit)? = null
    private val lifecycleObserver = LifecycleEventObserver { _, event ->
        when (event) {
            Lifecycle.Event.ON_STOP, Lifecycle.Event.ON_DESTROY -> stopObserving()
            Lifecycle.Event.ON_START -> startObserving()
            else -> Unit
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = EventChannel(binding.binaryMessenger, "screenshot_detect/events").also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        detachActivity()
        events = null
        channel?.setStreamHandler(null)
        channel = null
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        stopObserving()
        events = sink
        if (Build.VERSION.SDK_INT < 34) {
            sink.error(
                "unsupported_platform",
                "Screenshot detection requires Android 14 (API 34) or later.",
                null,
            )
            return
        }
        startObservingIfVisible()
    }

    override fun onCancel(arguments: Any?) {
        stopObserving()
        events = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding).also {
            it.addObserver(lifecycleObserver)
        }
        startObservingIfVisible()
    }

    override fun onDetachedFromActivityForConfigChanges() = detachActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() = detachActivity()

    private fun startObservingIfVisible() {
        if (lifecycle?.currentState?.isAtLeast(Lifecycle.State.STARTED) == true) {
            startObserving()
        }
    }

    private fun startObserving() {
        if (Build.VERSION.SDK_INT < 34 || unregister != null) return
        val currentActivity = activity ?: return
        val sink = events ?: return
        try {
            unregister = Api34.register(currentActivity) {
                events?.success(null)
            }
        } catch (error: SecurityException) {
            sink.error("permission_denied", error.message, null)
        }
    }

    private fun stopObserving() {
        unregister?.invoke()
        unregister = null
    }

    private fun detachActivity() {
        stopObserving()
        lifecycle?.removeObserver(lifecycleObserver)
        lifecycle = null
        activity = null
    }

    // Keep API 34 types out of the class loaded on older Android versions.
    @TargetApi(34)
    private object Api34 {
        fun register(activity: Activity, onScreenshot: () -> Unit): () -> Unit {
            val callback = Activity.ScreenCaptureCallback { onScreenshot() }
            activity.registerScreenCaptureCallback(activity.mainExecutor, callback)
            return { activity.unregisterScreenCaptureCallback(callback) }
        }
    }
}
