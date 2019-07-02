import Flutter
import UIKit

public class SwiftMediaPickerBuilderPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "media_picker_builder", binaryMessenger: registrar.messenger())
        let instance = SwiftMediaPickerBuilderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAlbums":
            guard let withImages = (call.arguments as? Dictionary<String, Any>)?["withImages"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "withImages must not be null", details: nil))
                return
            }
            guard let withVideos = (call.arguments as? Dictionary<String, Any>)?["withVideos"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "withVideos must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getThumbnail").async {
                let albums = FileFetcher.getAlbums(withImages: withImages, withVideos: withVideos)
                let encodedData = try? JSONEncoder().encode(albums)
                let json = String(data: encodedData!, encoding: .utf8)!
                result(json)
            }
        case "getThumbnail":
            guard let fileId = (call.arguments as? Dictionary<String, Any>)?["fileId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "fileId must not be null", details: nil))
                return
            }
            guard let type = (call.arguments as? Dictionary<String, Any>)?["type"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "type must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getThumbnail").async {
                let thumbnail = FileFetcher.getThumbnail(for: fileId, type: MediaType.init(rawValue: type)!)
                if (thumbnail != nil) {
                    result(thumbnail)
                } else {
                    result(FlutterError(code: "NOT_FOUND", message: "Unable to get the thumbnail", details: nil))
                }
            }
            
        default:
            result(FlutterError.init(
                code: "NOT_IMPLEMENTED",
                message: "Unknown method:  \(call.method)",
                details: nil))
        }
        
    }
}
