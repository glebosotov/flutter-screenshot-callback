package dev.glebosotov.screenshot_detect

import android.app.Activity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.Executor
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.doThrow
import org.mockito.kotlin.eq
import org.mockito.kotlin.isNull
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.times
import org.mockito.kotlin.verify
import org.mockito.kotlin.verifyNoInteractions
import org.mockito.kotlin.whenever
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], manifest = Config.NONE)
class ScreenshotDetectPluginTest {
    private lateinit var plugin: ScreenshotDetectPlugin
    private lateinit var activity: Activity
    private lateinit var lifecycle: Lifecycle
    private lateinit var binding: ActivityPluginBinding
    private lateinit var sink: EventChannel.EventSink

    @Before
    fun setUp() {
        plugin = ScreenshotDetectPlugin()
        activity = mock()
        lifecycle = mock()
        binding = bindingFor(activity, lifecycle)
        sink = mock()
        whenever(activity.mainExecutor).thenReturn(Executor { it.run() })
        whenever(lifecycle.currentState).thenReturn(Lifecycle.State.STARTED)
    }

    private fun bindingFor(activity: Activity, lifecycle: Lifecycle): ActivityPluginBinding =
        mock<ActivityPluginBinding>().also {
            whenever(it.activity).thenReturn(activity)
            whenever(it.lifecycle).thenReturn(HiddenLifecycleReference(lifecycle))
        }

    @Test
    fun registersOnlyWhenListeningAndCancelsSameCallback() {
        plugin.onAttachedToActivity(binding)
        verify(activity, never()).registerScreenCaptureCallback(any(), any())
        plugin.onListen(null, sink)
        val callback = argumentCaptor<Activity.ScreenCaptureCallback>()
        verify(activity).registerScreenCaptureCallback(any(), callback.capture())
        callback.firstValue.onScreenCaptured()
        verify(sink).success(null)
        plugin.onCancel(null)
        verify(activity).unregisterScreenCaptureCallback(callback.firstValue)
        callback.firstValue.onScreenCaptured()
        verify(sink, times(1)).success(null)
    }

    @Test
    fun listeningBeforeActivityAttachmentWaitsForActivity() {
        plugin.onListen(null, sink)
        verifyNoInteractions(sink)
        plugin.onAttachedToActivity(binding)
        verify(activity).registerScreenCaptureCallback(any(), any())
    }

    @Test
    fun stopsAndRestartsWithActivityLifecycle() {
        whenever(lifecycle.currentState).thenReturn(Lifecycle.State.CREATED)
        plugin.onAttachedToActivity(binding)
        plugin.onListen(null, sink)
        verify(activity, never()).registerScreenCaptureCallback(any(), any())
        val observer = argumentCaptor<LifecycleEventObserver>()
        verify(lifecycle).addObserver(observer.capture())
        val owner = mock<LifecycleOwner>()
        whenever(owner.lifecycle).thenReturn(lifecycle)
        observer.firstValue.onStateChanged(owner, Lifecycle.Event.ON_START)
        verify(activity).registerScreenCaptureCallback(any(), any())
        observer.firstValue.onStateChanged(owner, Lifecycle.Event.ON_STOP)
        verify(activity).unregisterScreenCaptureCallback(any())
        observer.firstValue.onStateChanged(owner, Lifecycle.Event.ON_START)
        verify(activity, times(2)).registerScreenCaptureCallback(any(), any())
    }

    @Test
    fun activityRecreationReleasesOldRegistration() {
        plugin.onAttachedToActivity(binding)
        plugin.onListen(null, sink)
        plugin.onDetachedFromActivityForConfigChanges()
        verify(activity).unregisterScreenCaptureCallback(any())
        verify(lifecycle).removeObserver(any())
        val replacement = mock<Activity>()
        whenever(replacement.mainExecutor).thenReturn(Executor { it.run() })
        plugin.onReattachedToActivityForConfigChanges(bindingFor(replacement, lifecycle))
        verify(replacement).registerScreenCaptureCallback(any(), any())
        plugin.onDetachedFromActivity()
        verify(replacement).unregisterScreenCaptureCallback(any())
    }

    @Test
    @Config(sdk = [33])
    fun olderAndroidReportsUnsupportedWithoutCallingNewApi() {
        plugin.onAttachedToActivity(binding)
        plugin.onListen(null, sink)
        verify(sink).error(eq("unsupported_platform"), any(), isNull())
        verify(activity, never()).mainExecutor
    }

    @Test
    fun missingManifestPermissionIsReported() {
        doThrow(SecurityException("Missing DETECT_SCREEN_CAPTURE"))
            .whenever(activity).registerScreenCaptureCallback(any(), any())
        plugin.onAttachedToActivity(binding)
        plugin.onListen(null, sink)
        verify(sink).error(eq("permission_denied"), eq("Missing DETECT_SCREEN_CAPTURE"), isNull())
        plugin.onCancel(null)
        verify(activity, never()).unregisterScreenCaptureCallback(any())
    }
}
