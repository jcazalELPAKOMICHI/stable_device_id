package py.com.jcazal.stable_device_id

import android.annotation.SuppressLint
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** StableDeviceIdPlugin */
class StableDeviceIdPlugin :
    FlutterPlugin,
    MethodCallHandler {

    companion object {
        private const val CHANNEL = "stable_device_id"
        private const val GET_ID_METHOD = "getId"
        private const val ANDROID_SOURCE_ARGUMENT = "androidSource"
        private const val ANDROID_ID_SOURCE = "androidId"
        private const val WIDEVINE_SOURCE = "widevine"
        private const val UNAVAILABLE_ERROR = "UNAVAILABLE"
        private const val WIDEVINE_UNAVAILABLE_ERROR = "WIDEVINE_UNAVAILABLE"
        private const val INVALID_ARGUMENT_ERROR = "INVALID_ARGUMENT"
    }

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }
    private var executor: ExecutorService? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        executor = Executors.newSingleThreadExecutor()
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            GET_ID_METHOD -> getId(call.argument<String>(ANDROID_SOURCE_ARGUMENT), result)
            else -> result.notImplemented()
        }
    }

    private fun getId(source: String?, result: Result) {
        when (source ?: ANDROID_ID_SOURCE) {
            ANDROID_ID_SOURCE -> getAndroidId(result)
            WIDEVINE_SOURCE -> getWidevineId(result)
            else -> result.error(INVALID_ARGUMENT_ERROR, "Unknown androidSource: $source", null)
        }
    }

    // ANDROID_ID is scoped to signing key + user + device since Android 8.0,
    // so it survives updates and reinstalls of the same app.
    @SuppressLint("HardwareIds")
    private fun getAndroidId(result: Result) {
        val androidId = context?.let {
            Settings.Secure.getString(it.contentResolver, Settings.Secure.ANDROID_ID)
        }

        if (androidId.isNullOrEmpty()) {
            result.error(UNAVAILABLE_ERROR, "ANDROID_ID is not available on this device.", null)
        } else {
            result.success(androidId)
        }
    }

    // MediaDrm can take a few hundred milliseconds, so it never runs on the main thread.
    private fun getWidevineId(result: Result) {
        val appContext = context
        val worker = executor
        if (appContext == null || worker == null) {
            result.error(UNAVAILABLE_ERROR, "The plugin is not attached to an engine.", null)
            return
        }

        worker.execute {
            val widevineId = WidevineIdReader.read(appContext.packageName)
            mainHandler.post {
                if (widevineId == null) {
                    result.error(
                        WIDEVINE_UNAVAILABLE_ERROR,
                        "Widevine DRM is not available on this device.",
                        null
                    )
                } else {
                    result.success(widevineId)
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor?.shutdown()
        executor = null
        context = null
    }
}
