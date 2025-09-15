package com.wishy.wishy

import android.net.Uri
import android.content.Intent
import android.os.Bundle
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.InputStream
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {

    companion object {
        var formerActivity: MainActivity? = null
    }

    private val CHANNEL = "com.wishysa.wishy/channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "onCreate")
        Log.d("MainActivity", intent.toString())
        if(formerActivity != null) {
            formerActivity?.finish()
        }
        formerActivity = this
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // Verificar si el Intent contiene datos
        if ((intent?.action == Intent.ACTION_VIEW || intent.action ==Intent.ACTION_SEND) && intent.type != null) {
            when {
                intent.type?.contains("x-vcard") == true -> {
                    // Si el Intent es de tipo vCard, procesar el archivo
                    handleVCardIntent(intent)
                }
                else -> {
                    handleExternalLink(intent)
                }
            }
        }
    }

    private fun handleExternalLink(intent: Intent) {
        val sharedLinkInfo: MutableMap<String, String> = HashMap()
        sharedLinkInfo.put("link", intent.getStringExtra(Intent.EXTRA_TEXT) ?: "")
        sharedLinkInfo.put("title", intent.getStringExtra(Intent.EXTRA_TITLE) ?: "")
        sharedLinkInfo.put("subject", intent.getStringExtra(Intent.EXTRA_SUBJECT) ?: "")

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            {}
            MethodChannel(messenger, CHANNEL).invokeMethod(
                "onSharedText",
                (sharedLinkInfo as Map<*, *>?)?.let { JSONObject(it).toString() }
            )
        }
    }

    private fun handleVCardIntent(intent: Intent) {
        val clipDataItem = intent.clipData?.getItemAt(0)
        val vcardUri = clipDataItem?.uri
        if (vcardUri != null) {
            try {
                // Abre el InputStream para leer el contenido de la URI
                val inputStream: InputStream? = contentResolver.openInputStream(vcardUri)
                if (inputStream != null) {
                    val reader = BufferedReader(InputStreamReader(inputStream))
                    // Aquí puedes leer y parsear el contenido vCard
                    val vcardContent = StringBuilder()
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        vcardContent.append(line).append("\n")
                    }
                    reader.close()
                    inputStream.close()
                    // Ahora puedes usar 'vcardContent' para extraer la información del contacto
                    // ...
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}