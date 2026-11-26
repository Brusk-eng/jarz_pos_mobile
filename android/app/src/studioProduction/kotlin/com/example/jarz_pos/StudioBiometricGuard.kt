package com.example.jarz_pos

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

/**
 * A Keystore key that exists only to notice new fingerprints or faces.
 *
 * It requires biometric authentication for every use and is invalidated by the
 * system when biometrics are enrolled. Initialising a cipher with an
 * invalidated key throws KeyPermanentlyInvalidatedException, which is how the
 * Dart side learns that the stored login must be wiped. The key never encrypts
 * the login itself and never leaves the Keystore.
 */
object StudioBiometricGuard {
    const val CHANNEL = "jarz_studio/biometric_guard"
    private const val ALIAS = "jarz_studio_biometric_guard"
    private const val PROVIDER = "AndroidKeyStore"

    private fun keyStore(): KeyStore = KeyStore.getInstance(PROVIDER).apply { load(null) }

    fun arm(): Boolean {
        return try {
            disarm()
            val builder = KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .setUserAuthenticationRequired(true)
                .setInvalidatedByBiometricEnrollment(true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                builder.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
            } else {
                @Suppress("DEPRECATION")
                builder.setUserAuthenticationValidityDurationSeconds(-1)
            }
            val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, PROVIDER)
            generator.init(builder.build())
            generator.generateKey()
            true
        } catch (e: Exception) {
            false
        }
    }

    /** False when the key is gone or was invalidated by a new enrolment. */
    fun isValid(): Boolean {
        return try {
            val key = keyStore().getKey(ALIAS, null) as? SecretKey ?: return false
            Cipher.getInstance("AES/GCM/NoPadding").init(Cipher.ENCRYPT_MODE, key)
            true
        } catch (e: KeyPermanentlyInvalidatedException) {
            false
        } catch (e: Exception) {
            // Any other failure is not proof that the enrolment changed.
            true
        }
    }

    fun disarm() {
        try {
            val ks = keyStore()
            if (ks.containsAlias(ALIAS)) ks.deleteEntry(ALIAS)
        } catch (e: Exception) {
        }
    }
}
