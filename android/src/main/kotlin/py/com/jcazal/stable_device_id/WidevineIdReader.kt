package py.com.jcazal.stable_device_id

import android.media.MediaDrm
import android.os.Build
import java.security.MessageDigest
import java.util.UUID

/**
 * Reads the Widevine DRM device unique ID.
 *
 * The raw value is device-wide (shared by every app) and usually survives a
 * factory reset. It is never returned as is: it is hashed together with the
 * package name, so each app gets its own value and the raw hardware
 * identifier is not exposed.
 */
internal object WidevineIdReader {
    private val WIDEVINE_UUID = UUID(-0x121074568629b532L, -0x5c37d8232ae2de13L)
    private const val HASH_ALGORITHM = "SHA-256"
    private const val HEX_FORMAT = "%02x"

    fun read(packageName: String): String? {
        if (!MediaDrm.isCryptoSchemeSupported(WIDEVINE_UUID)) return null

        var drm: MediaDrm? = null
        return try {
            drm = MediaDrm(WIDEVINE_UUID)
            val raw = drm.getPropertyByteArray(MediaDrm.PROPERTY_DEVICE_UNIQUE_ID)
            if (raw.isEmpty()) null else hash(raw, packageName)
        } catch (_: Exception) {
            null
        } finally {
            drm?.let(::close)
        }
    }

    private fun hash(raw: ByteArray, packageName: String): String {
        val digest = MessageDigest.getInstance(HASH_ALGORITHM)
        digest.update(raw)
        digest.update(packageName.toByteArray(Charsets.UTF_8))
        return digest.digest().joinToString("") { HEX_FORMAT.format(it) }
    }

    @Suppress("DEPRECATION")
    private fun close(drm: MediaDrm) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) drm.close() else drm.release()
        } catch (_: Exception) {
        }
    }
}
