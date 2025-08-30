package com.wishy.wishy

import android.content.Intent
import android.os.Bundle
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

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
        if(intent.action ==Intent.ACTION_SEND) {
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
    }
}