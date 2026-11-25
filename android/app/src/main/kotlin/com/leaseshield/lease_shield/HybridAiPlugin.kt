package com.leaseshield.lease_shield

import android.content.Context
import android.os.Build
import android.os.SystemClock
import com.google.firebase.Firebase
import com.google.firebase.ai.InferenceMode
import com.google.firebase.ai.InferenceSource
import com.google.firebase.ai.OnDeviceConfig
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.GenerativeBackend
import com.google.firebase.ai.type.PublicPreviewAPI
import com.google.firebase.ai.type.generationConfig
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Native Android bridge for Firebase AI Logic Hybrid Inference (Gemini Nano 4 + Cloud Gemini).
 *
 * Channel: `com.leaseshield/hybrid_ai`
 * Methods:
 * - `generateContent`: executes prompt with explicit `InferenceMode` (`ONLY_ON_DEVICE`,
 *   `PREFER_ON_DEVICE`, or `ONLY_IN_CLOUD`) and returns telemetry + generated text.
 * - `getCapabilities`: reports Android runtime & on-device target metadata.
 */
@OptIn(PublicPreviewAPI::class)
class HybridAiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    companion object {
        const val CHANNEL_NAME = "com.leaseshield/hybrid_ai"
        private const val DEFAULT_CLOUD_MODEL = "gemini-2.5-flash"
        private const val ON_DEVICE_MODEL_LABEL = "Gemini Nano 4"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        PDFBoxResourceLoader.init(appContext)
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> handleGetCapabilities(result)
            "generateContent" -> handleGenerateContent(call, result)
            "extractPdfText" -> handleExtractPdfText(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleExtractPdfText(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "PDF file path is required.", null)
            return
        }
        scope.launch {
            try {
                val file = File(path)
                val extracted = PDDocument.load(file).use { doc ->
                    val stripper = PDFTextStripper()
                    stripper.getText(doc).trim()
                }
                withContext(Dispatchers.Main) {
                    result.success(extracted)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("PDF_EXTRACT_ERROR", e.localizedMessage ?: "Failed to read PDF.", null)
                }
            }
        }
    }

    private fun handleGetCapabilities(result: MethodChannel.Result) {
        val supportedSdk = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
        result.success(
            mapOf(
                "platform" to "android",
                "onDeviceSupported" to supportedSdk,
                "onDeviceModelName" to ON_DEVICE_MODEL_LABEL,
            ),
        )
    }

    private fun handleGenerateContent(call: MethodCall, result: MethodChannel.Result) {
        val prompt = call.argument<String>("prompt")
        if (prompt.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "Prompt must not be empty.", null)
            return
        }

        val modeArg = call.argument<String>("mode") ?: "ONLY_ON_DEVICE"
        val cloudModelName = call.argument<String>("cloudModelName") ?: DEFAULT_CLOUD_MODEL
        val temperature = (call.argument<Double>("temperature") ?: 0.2).toFloat()

        val inferenceMode = when (modeArg) {
            "ONLY_ON_DEVICE" -> InferenceMode.ONLY_ON_DEVICE
            "PREFER_ON_DEVICE" -> InferenceMode.PREFER_ON_DEVICE
            "ONLY_IN_CLOUD" -> InferenceMode.ONLY_IN_CLOUD
            else -> InferenceMode.ONLY_ON_DEVICE
        }

        scope.launch {
            val startMs = SystemClock.elapsedRealtime()
            try {
                val model = Firebase.ai(backend = GenerativeBackend.googleAI()).generativeModel(
                    modelName = cloudModelName,
                    generationConfig = generationConfig {
                        this.temperature = temperature
                    },
                    onDeviceConfig = OnDeviceConfig(mode = inferenceMode),
                )

                val response = model.generateContent(prompt)
                val latencyMs = (SystemClock.elapsedRealtime() - startMs).toInt()
                val rawText = response.text ?: ""

                val sourceString = when (response.inferenceSource) {
                    InferenceSource.ON_DEVICE -> "ON_DEVICE"
                    InferenceSource.IN_CLOUD -> "IN_CLOUD"
                    else -> if (inferenceMode == InferenceMode.ONLY_IN_CLOUD) {
                        "IN_CLOUD"
                    } else {
                        "ON_DEVICE"
                    }
                }

                val resolvedModelName = if (sourceString == "ON_DEVICE") {
                    ON_DEVICE_MODEL_LABEL
                } else {
                    cloudModelName
                }

                withContext(Dispatchers.Main) {
                    result.success(
                        mapOf(
                            "text" to rawText,
                            "inferenceSource" to sourceString,
                            "latencyMs" to latencyMs,
                            "modelName" to resolvedModelName,
                        ),
                    )
                }
            } catch (e: Exception) {
                val code = if (inferenceMode == InferenceMode.ONLY_ON_DEVICE) {
                    "ON_DEVICE_UNAVAILABLE"
                } else {
                    "HYBRID_AI_ERROR"
                }
                withContext(Dispatchers.Main) {
                    result.error(code, e.localizedMessage ?: e.javaClass.simpleName, null)
                }
            }
        }
    }
}
