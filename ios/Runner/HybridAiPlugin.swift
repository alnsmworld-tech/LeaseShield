import Flutter
import Foundation
import PDFKit

#if canImport(FirebaseAI)
import FirebaseAI
#endif

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Native iOS bridge for Firebase AI Logic Hybrid Inference
/// (Apple Foundation Models on-device + Cloud Gemini via Firebase AI Logic).
///
/// Channel: `com.leaseshield/hybrid_ai`
/// Matches the exact Android MethodChannel contract and response payload.
public final class HybridAiPlugin: NSObject, FlutterPlugin {
    public static let channelName = "com.leaseshield/hybrid_ai"
    private static let defaultCloudModel = "gemini-2.5-flash"
    private static let onDeviceModelLabel = "Apple Foundation Models"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = HybridAiPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCapabilities":
            handleGetCapabilities(result: result)
        case "generateContent":
            handleGenerateContent(call: call, result: result)
        case "extractPdfText":
            handleExtractPdfText(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleExtractPdfText(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              !path.isEmpty else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "PDF file path is required.",
                details: nil
            ))
            return
        }
        let url = URL(fileURLWithPath: path)
        guard let document = PDFDocument(url: url) else {
            result(FlutterError(
                code: "PDF_EXTRACT_ERROR",
                message: "Unable to open PDF document.",
                details: nil
            ))
            return
        }
        let extracted = (document.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        result(extracted)
    }

    private func handleGetCapabilities(result: @escaping FlutterResult) {
        result([
            "platform": "ios",
            "onDeviceSupported": isAppleFoundationModelAvailable(),
            "onDeviceModelName": Self.onDeviceModelLabel,
        ])
    }

    private func isAppleFoundationModelAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    private func handleGenerateContent(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let prompt = args["prompt"] as? String,
              !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Prompt must not be empty.",
                details: nil
            ))
            return
        }

        let mode = (args["mode"] as? String) ?? "ONLY_ON_DEVICE"
        let cloudModelName = (args["cloudModelName"] as? String) ?? Self.defaultCloudModel
        let temperature = (args["temperature"] as? Double) ?? 0.2

        Task {
            let start = Date()
            do {
                let output: (text: String, source: String, modelName: String)
                switch mode {
                case "ONLY_ON_DEVICE":
                    let text = try await runOnDeviceAppleModel(prompt: prompt)
                    output = (text, "ON_DEVICE", Self.onDeviceModelLabel)

                case "PREFER_ON_DEVICE":
                    if isAppleFoundationModelAvailable() {
                        do {
                            let text = try await runOnDeviceAppleModel(prompt: prompt)
                            output = (text, "ON_DEVICE", Self.onDeviceModelLabel)
                        } catch {
                            let text = try await runCloudGemini(
                                prompt: prompt,
                                modelName: cloudModelName,
                                temperature: Float(temperature)
                            )
                            output = (text, "IN_CLOUD", cloudModelName)
                        }
                    } else {
                        let text = try await runCloudGemini(
                            prompt: prompt,
                            modelName: cloudModelName,
                            temperature: Float(temperature)
                        )
                        output = (text, "IN_CLOUD", cloudModelName)
                    }

                case "ONLY_IN_CLOUD":
                    let text = try await runCloudGemini(
                        prompt: prompt,
                        modelName: cloudModelName,
                        temperature: Float(temperature)
                    )
                    output = (text, "IN_CLOUD", cloudModelName)

                default:
                    let text = try await runOnDeviceAppleModel(prompt: prompt)
                    output = (text, "ON_DEVICE", Self.onDeviceModelLabel)
                }

                let latencyMs = Int(Date().timeIntervalSince(start) * 1000.0)
                await MainActor.run {
                    result([
                        "text": output.text,
                        "inferenceSource": output.source,
                        "latencyMs": latencyMs,
                        "modelName": output.modelName,
                    ])
                }
            } catch {
                let code = mode == "ONLY_ON_DEVICE" ? "ON_DEVICE_UNAVAILABLE" : "HYBRID_AI_ERROR"
                await MainActor.run {
                    result(FlutterError(
                        code: code,
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    private func runOnDeviceAppleModel(prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard SystemLanguageModel.default.isAvailable else {
                throw NSError(
                    domain: "com.leaseshield.hybrid_ai",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Apple Foundation Models not available on this device."]
                )
            }
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content
        }
        #endif
        throw NSError(
            domain: "com.leaseshield.hybrid_ai",
            code: 1002,
            userInfo: [NSLocalizedDescriptionKey: "Apple Foundation Models requires iOS 26+ on Apple Intelligence-capable hardware."]
        )
    }

    private func runCloudGemini(
        prompt: String,
        modelName: String,
        temperature: Float
    ) async throws -> String {
        #if canImport(FirebaseAI)
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let config = GenerationConfig(temperature: temperature)
        let model = ai.generativeModel(modelName: modelName, generationConfig: config)
        let response = try await model.generateContent(prompt)
        return response.text ?? ""
        #else
        throw NSError(
            domain: "com.leaseshield.hybrid_ai",
            code: 2001,
            userInfo: [NSLocalizedDescriptionKey: "FirebaseAI Swift SDK not linked. Add FirebaseAI via CocoaPods or Swift Package Manager."]
        )
        #endif
    }
}
