package py.com.jcazal.stable_device_id

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.ArgumentMatchers.anyString
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.isNull
import org.mockito.Mockito
import kotlin.test.Test

/*
 * Run with `./gradlew testDebugUnitTest` from the `example/android/` directory
 * once the example app has been built.
 */

internal class StableDeviceIdPluginTest {
    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        val plugin = StableDeviceIdPlugin()

        val call = MethodCall("unknown", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).notImplemented()
    }

    @Test
    fun onMethodCall_getIdWithoutContext_returnsUnavailableError() {
        val plugin = StableDeviceIdPlugin()

        val call = MethodCall("getId", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(eq("UNAVAILABLE"), anyString(), isNull())
    }

    @Test
    fun onMethodCall_getWidevineIdWithoutContext_returnsUnavailableError() {
        val plugin = StableDeviceIdPlugin()

        val call = MethodCall("getId", mapOf("androidSource" to "widevine"))
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(eq("UNAVAILABLE"), anyString(), isNull())
    }

    @Test
    fun onMethodCall_unknownAndroidSource_returnsInvalidArgumentError() {
        val plugin = StableDeviceIdPlugin()

        val call = MethodCall("getId", mapOf("androidSource" to "imei"))
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).error(eq("INVALID_ARGUMENT"), anyString(), isNull())
    }
}
