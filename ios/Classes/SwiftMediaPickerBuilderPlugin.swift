import Flutter
import UIKit
import Photos

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
            guard let loadPaths = (call.arguments as? Dictionary<String, Any>)?["loadIOSPaths"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "loadIOSPaths must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getAlbums").async {
                let albums = FileFetcher.getAlbums(withImages: withImages, withVideos: withVideos, loadPaths: loadPaths)
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
        case "getMediaFile":
            guard let fileId = (call.arguments as? Dictionary<String, Any>)?["fileId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "fileId must not be null", details: nil))
                return
            }
            guard let loadPath = (call.arguments as? Dictionary<String, Any>)?["loadIOSPath"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "loadIOSPath must not be null", details: nil))
                return
            }
            guard let loadThumbnail = (call.arguments as? Dictionary<String, Any>)?["loadThumbnail"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "loadIOSPath must not be null", details: nil))
                return
            }
            DispatchQueue(label: "getMediaFile").async {
                let asset = PHAsset.fetchAssets(withLocalIdentifiers: [fileId], options: .none).firstObject
                if asset == nil {
                    result(FlutterError(code: "NOT_FOUND", message: "Unable to get the file", details: nil))
                    return
                }
                let mediaFile = FileFetcher.getMediaFile(for: asset!, loadPath: loadPath, generateThumbnailIfNotFound: loadThumbnail)
                if (mediaFile != nil) {
                    let encodedData = try? JSONEncoder().encode(mediaFile)
                    let json = String(data: encodedData!, encoding: .utf8)!
                    result(json)
                } else {
                    result(FlutterError(code: "NOT_FOUND", message: "Unable to get the file", details: nil))
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
