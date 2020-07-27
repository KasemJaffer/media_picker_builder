//
//  FileFetcher.swift
//  file_picker
//
//  Created by Kasem Mohamed on 6/29/19.
//

import Foundation
import Photos

class FileFetcher {
    static func getAlbums(withImages: Bool, withVideos: Bool, loadPaths: Bool)-> [Album] {
        var albums = [Album]()
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor.init(key: "endDate", ascending: false)]  // TODO: This does not work, I don't know why
        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: options)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: options)
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        if withImages && withVideos {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        } else if withImages {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        } else if withVideos {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        }
        
        topLevelUserCollections.enumerateObjects{(topLevelAlbumAsset, index, stop) in
            if (topLevelAlbumAsset is PHAssetCollection) {
                let topLevelAlbum = topLevelAlbumAsset as! PHAssetCollection
                let album = fetchAssets(forCollection: topLevelAlbum, fetchOptions: fetchOptions, loadPath: loadPaths)
                if album != nil {
                    albums.append(album!)
                }
            }
        }
        
        smartAlbums.enumerateObjects{(smartAlbum, index, stop) in
            let album = fetchAssets(forCollection: smartAlbum, fetchOptions: fetchOptions, loadPath: loadPaths)
            if album != nil {
                albums.append(album!)
            }
        }
        return albums
    }
    
    static func fetchAssets(forCollection collection: PHAssetCollection, fetchOptions: PHFetchOptions, loadPath: Bool) -> Album? {
        let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        var files = [MediaFile]()
        assets.enumerateObjects{asset, index, info in
            if let mediaFile = getMediaFile(for: asset, loadPath: loadPath, generateThumbnailIfNotFound: false) {
                files.append(mediaFile)
            } else {
                print("File path not found for an item in \(String(describing: collection.localizedTitle))")
            }
        }
        
        //        if !files.isEmpty {
        return Album.init(
            id: collection.localIdentifier,
            name: collection.localizedTitle!,
            files: files)
        
        //        }
        //        return nil
    }
    
    static func getThumbnail(for fileId: String, type: MediaType) -> String? {
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [fileId], options: .none).firstObject
        if asset == nil {
            return nil
        }
        
        let modificationDate = Int((asset!.value(forKey: "modificationDate") as! Date).timeIntervalSince1970)
        let cachePath = getCachePath(for: fileId, modificationDate: modificationDate)
        if FileManager.default.fileExists(atPath: cachePath.path) {
            return cachePath.path
        }
        
        if generateThumbnail(asset: asset!, destination: cachePath) {
            return cachePath.path
        }
        
        return nil
    }
    
    static func getMediaFile(for asset: PHAsset, loadPath: Bool, generateThumbnailIfNotFound: Bool) -> MediaFile? {
        
        var mediaFile: MediaFile? = nil
        var url: String? = nil
        var duration: Double? = nil
        var orientation: Int = 0
        
        let modificationDate = Int((asset.value(forKey: "modificationDate") as! Date).timeIntervalSince1970)
        var cachePath: URL? = getCachePath(for: asset.localIdentifier, modificationDate: modificationDate)
        if !FileManager.default.fileExists(atPath: cachePath!.path) {
            if generateThumbnailIfNotFound {
                if !generateThumbnail(asset: asset, destination: cachePath!) {
                    cachePath = nil
                }
            } else {
                cachePath = nil
            }
        }
        
        if (asset.mediaType ==  .image) {
            
            if loadPath {
         
                (url, orientation) = getFullSizeImageURLAndOrientation(for: asset)

                // Not working since iOS 13
                // (url, orientation) = getPHImageFileURLKeyAndOrientation(for: asset)

            }



            let since1970 = asset.creationDate?.timeIntervalSince1970
            var dateAdded: Int? = nil
            if since1970 != nil {
                dateAdded = Int(since1970!)
            }
            mediaFile = MediaFile.init(
                id: asset.localIdentifier,
                dateAdded: dateAdded,
                path: url,
                thumbnailPath: cachePath?.path,
                orientation: orientation,
                duration: nil,
                mimeType: nil,
                type: .IMAGE)

        } else if (asset.mediaType == .video) {

            if loadPath {
                let semaphore = DispatchSemaphore(value: 0)
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAssetData, _, info) in
                    var avAsset = avAssetData
                    if avAssetData is AVComposition {
                        avAsset = convertAvcompositionToAvasset(avComp: (avAssetData as? AVComposition)!)
                    }
                    let avURLAsset = avAsset as? AVURLAsset
                    url = avURLAsset?.url.path
                    let durationTime = avAsset?.duration
                    if durationTime != nil {
                        duration = (CMTimeGetSeconds(durationTime!) * 1000).rounded()
                        UserDefaults.standard.set(duration, forKey: "duration-\(asset.localIdentifier)")
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            } else {
                duration = UserDefaults.standard.double(forKey: "duration-\(asset.localIdentifier)")
                if duration == 0 {
                    duration = nil
                }
            }

            let since1970 = asset.creationDate?.timeIntervalSince1970
            var dateAdded: Int? = nil
            if since1970 != nil {
                dateAdded = Int(since1970!)
            }
            mediaFile = MediaFile.init(
                id: asset.localIdentifier,
                dateAdded: dateAdded,
                path: url,
                thumbnailPath: cachePath?.path,
                orientation: 0,
                duration: duration,
                mimeType: nil,
                type: .VIDEO)

        }
        return mediaFile
    }

    private static func generateThumbnail(asset: PHAsset, destination: URL) -> Bool {

        let scale = UIScreen.main.scale
        let imageSize = CGSize(width: 79 * scale, height: 79 * scale)
        let imageContentMode: PHImageContentMode = .aspectFill
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        var saved = false
        PHCachingImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: imageContentMode, options: options) { (image, info) in
            do {
                try UIImagePNGRepresentation(image!)?.write(to: destination)
                saved = true
            } catch (let error) {
                print(error)
                saved = false
            }

        }
        return saved
    }

    private static func getCachePath(for identifier: String, modificationDate: Int) -> URL {
        let fileName = Data(identifier.utf8).base64EncodedString().replacingOccurrences(of: "==", with: "")
        let path = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("\(fileName)-\(modificationDate).png")
        return path
    }

    private static func getFullSizeImageURLAndOrientation(for asset: PHAsset)-> (String?, Int) {
        var url: String? = nil
        var orientation: Int = 0
        let semaphore = DispatchSemaphore(value: 0)
        let options2 = PHContentEditingInputRequestOptions()
        options2.isNetworkAccessAllowed = true
        asset.requestContentEditingInput(with: options2){(input, info) in
            orientation = Int(input?.fullSizeImageOrientation ?? 0)
            url = input?.fullSizeImageURL?.path
            semaphore.signal()
        }
        semaphore.wait()

        return (url, orientation)
    }

    private static func getPHImageFileURLKeyAndOrientation(for asset: PHAsset) -> (String?, Int) {
        var url: String? = nil
        var orientation: Int = 0
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImageData(for: asset, options: options) { (_, fileName, _orientation, info) in
            orientation = _orientation.inDegrees()
            url = (info?["PHImageFileURLKey"] as? NSURL)?.path
        }
        return (url, orientation)
    }

    private static func convertAvcompositionToAvasset(avComp: AVComposition) -> AVAsset? {
        let exporter = AVAssetExportSession(asset: avComp, presetName: AVAssetExportPresetHighestQuality)
        let randNum:Int = Int(arc4random())
        //Generating Export Path
        let exportPath: NSString = NSTemporaryDirectory().appendingFormat("\(randNum)"+"video.mov") as NSString
        let exportUrl: NSURL = NSURL.fileURL(withPath: exportPath as String) as NSURL
        //SettingUp Export Path as URL
        exporter?.outputURL = exportUrl as URL
        exporter?.outputFileType = AVFileType.mov
        var avAsset: AVAsset?
        let semaphore = DispatchSemaphore(value: 0)
        exporter?.exportAsynchronously(completionHandler: {() -> Void in
            if exporter?.status == .completed {
                let url = exporter?.outputURL
                avAsset = AVAsset(url: url!)
            }
            semaphore.signal()
        })
        semaphore.wait()
        return avAsset
    }
}

extension UIImageOrientation{
    func inDegrees() -> Int {
        switch  self {
        case .down:
            return 180
        case .downMirrored:
            return 180
        case .left:
            return 270
        case .leftMirrored:
            return 270
        case .right:
            return 90
        case .rightMirrored:
            return 90
        case .up:
            return 0
        case .upMirrored:
            return 0
        }
    }
}
