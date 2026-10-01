package py.com.jcazal.stable_device_id

import android.annotation.SuppressLint
import android.content.Context
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** StableDeviceIdPlugin */
class StableDeviceIdPlugin :
    FlutterPlugin,
    MethodCallHandler {

    companion object {
        private const val CHANNEL = "stable_device_id"
        private const val GET_ID_METHOD = "getId"
        private const val UNAVAILABLE_ERROR = "UNAVAILABLE"
    }

    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            GET_ID_METHOD -> getId(result)
            else -> result.notImplemented()
        }
    }

    // ANDROID_ID is scoped to signing key + user + device since Android 8.0,
    // so it survives updates and reinstalls of the same app.
    @SuppressLint("HardwareIds")
    private fun getId(result: Result) {
        val androidId = context?.let {
            Settings.Secure.getString(it.contentResolver, Settings.Secure.ANDROID_ID)
        }

        if (androidId.isNullOrEmpty()) {
            result.error(UNAVAILABLE_ERROR, "ANDROID_ID is not available on this device.", null)
        } else {
            result.success(androidId)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }
}
