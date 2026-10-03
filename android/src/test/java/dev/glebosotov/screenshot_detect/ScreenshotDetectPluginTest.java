package dev.glebosotov.screenshot_detect;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import android.app.Activity;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleEventObserver;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference;
import io.flutter.plugin.common.EventChannel;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = 34, manifest = Config.NONE)
public class ScreenshotDetectPluginTest {
    private ScreenshotDetectPlugin plugin;
    private Activity activity;
    private Lifecycle lifecycle;
    private ActivityPluginBinding binding;
    private EventChannel.EventSink sink;

    @Before
    public void setUp() {
        plugin = new ScreenshotDetectPlugin();
        activity = mock(Activity.class);
        lifecycle = mock(Lifecycle.class);
        binding = binding(activity, lifecycle);
        sink = mock(EventChannel.EventSink.class);
        when(activity.getMainExecutor()).thenReturn(Runnable::run);
        when(lifecycle.getCurrentState()).thenReturn(Lifecycle.State.STARTED);
    }

    private static ActivityPluginBinding binding(Activity activity, Lifecycle lifecycle) {
        ActivityPluginBinding binding = mock(ActivityPluginBinding.class);
        when(binding.getActivity()).thenReturn(activity);
        when(binding.getLifecycle()).thenReturn(new HiddenLifecycleReference(lifecycle));
        return binding;
    }

    @Test
    public void registersOnlyWhenListeningAndCancelsSameCallback() {
        plugin.onAttachedToActivity(binding);
        verify(activity, never()).registerScreenCaptureCallback(any(), any());
        plugin.onListen(null, sink);
        ArgumentCaptor<Activity.ScreenCaptureCallback> callback =
                ArgumentCaptor.forClass(Activity.ScreenCaptureCallback.class);
        verify(activity).registerScreenCaptureCallback(any(), callback.capture());
        callback.getValue().onScreenCaptured();
        verify(sink).success(null);
        plugin.onCancel(null);
        verify(activity).unregisterScreenCaptureCallback(callback.getValue());
        callback.getValue().onScreenCaptured();
        verify(sink, times(1)).success(null);
    }

    @Test
    public void listeningBeforeActivityAttachmentWaitsForActivity() {
        plugin.onListen(null, sink);
        verifyNoInteractions(sink);
        plugin.onAttachedToActivity(binding);
        verify(activity).registerScreenCaptureCallback(any(), any());
    }

    @Test
    public void stopsAndRestartsWithActivityLifecycle() {
        when(lifecycle.getCurrentState()).thenReturn(Lifecycle.State.CREATED);
        plugin.onAttachedToActivity(binding);
        plugin.onListen(null, sink);
        verify(activity, never()).registerScreenCaptureCallback(any(), any());
        ArgumentCaptor<LifecycleEventObserver> observer =
                ArgumentCaptor.forClass(LifecycleEventObserver.class);
        verify(lifecycle).addObserver(observer.capture());
        observer.getValue().onStateChanged(() -> lifecycle, Lifecycle.Event.ON_START);
        verify(activity).registerScreenCaptureCallback(any(), any());
        observer.getValue().onStateChanged(() -> lifecycle, Lifecycle.Event.ON_STOP);
        verify(activity).unregisterScreenCaptureCallback(any());
        observer.getValue().onStateChanged(() -> lifecycle, Lifecycle.Event.ON_START);
        verify(activity, times(2)).registerScreenCaptureCallback(any(), any());
    }

    @Test
    public void activityRecreationReleasesOldRegistration() {
        plugin.onAttachedToActivity(binding);
        plugin.onListen(null, sink);
        plugin.onDetachedFromActivityForConfigChanges();
        verify(activity).unregisterScreenCaptureCallback(any());
        verify(lifecycle).removeObserver(any());
        Activity replacement = mock(Activity.class);
        when(replacement.getMainExecutor()).thenReturn(Runnable::run);
        plugin.onReattachedToActivityForConfigChanges(binding(replacement, lifecycle));
        verify(replacement).registerScreenCaptureCallback(any(), any());
        plugin.onDetachedFromActivity();
        verify(replacement).unregisterScreenCaptureCallback(any());
    }

    @Test
    @Config(sdk = 33)
    public void olderAndroidReportsUnsupportedWithoutCallingNewApi() {
        plugin.onAttachedToActivity(binding);
        plugin.onListen(null, sink);
        verify(sink).error(eq("unsupported_platform"), any(), isNull());
        verify(activity, never()).getMainExecutor();
    }

    @Test
    public void missingManifestPermissionIsReported() {
        doThrow(new SecurityException("Missing DETECT_SCREEN_CAPTURE"))
                .when(activity).registerScreenCaptureCallback(any(), any());
        plugin.onAttachedToActivity(binding);
        plugin.onListen(null, sink);
        verify(sink).error(eq("permission_denied"), eq("Missing DETECT_SCREEN_CAPTURE"), isNull());
        plugin.onCancel(null);
        verify(activity, never()).unregisterScreenCaptureCallback(any());
    }
}
