//
//  FileFetcher.swift
//  file_picker
//
//  Created by Kasem Mohamed on 6/29/19.
//

import Foundation
import Photos

class FileFetcher {
    static func getAlbums(withImages: Bool, withVideos: Bool)-> [Album] {
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
            let topLevelAlbum = topLevelAlbumAsset as! PHAssetCollection
            let album = fetchAssets(forCollection: topLevelAlbum, fetchOptions: fetchOptions)
            if album != nil {
                albums.append(album!)
            }
        }
        
        smartAlbums.enumerateObjects{(smartAlbum, index, stop) in
            let album = fetchAssets(forCollection: smartAlbum, fetchOptions: fetchOptions)
            if album != nil {
                albums.append(album!)
            }
        }
        return albums
    }
    
    static func fetchAssets(forCollection collection: PHAssetCollection, fetchOptions: PHFetchOptions) -> Album? {
        let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        var files = [MediaFile]()
        assets.enumerateObjects{asset, index, info in
            if let mediaFile = getMediaFile(for: asset) {
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
        let cachePath = getCachePath(for: fileId)
        if FileManager.default.fileExists(atPath: cachePath.path) {
            return cachePath.path
        }
        
        
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [fileId], options: .none).firstObject
        if asset == nil {
            return nil
        }
        
        if generateThumbnail(asset: asset!, destination: cachePath) {
            return cachePath.path
        }
        
        return nil
    }
    
    private static func getMediaFile(for asset: PHAsset) -> MediaFile? {
        
        var mediaFile: MediaFile? = nil
        var url: String? = nil
        
        if (asset.mediaType ==  .image) {
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImageData(for: asset, options: options) { (_, fileName, orientation, info) in
                url = (info?["PHImageFileURLKey"] as? NSURL)?.path
                
                var cachePath: URL? = getCachePath(for: asset.localIdentifier)
                if !FileManager.default.fileExists(atPath: cachePath!.path) {
                    cachePath = nil
                }
                
                if (url != nil) {
                    let since1970 = asset.creationDate?.timeIntervalSince1970
                    var dateAdded: Int? = nil
                    if since1970 != nil {
                        dateAdded = Int(since1970!)
                    }
                    mediaFile = MediaFile.init(
                        id: asset.localIdentifier,
                        dateAdded: dateAdded,
                        path: url!,
                        thumbnailPath: cachePath?.path,
                        orientation: orientation.inDegrees(),
                        type: .IMAGE)
                }
            }
        } else if (asset.mediaType == .video) {
            let semaphore = DispatchSemaphore(value: 0)
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, _, info) in
                url = (avAsset as? AVURLAsset)?.url.path
                var cachePath: URL? = getCachePath(for: asset.localIdentifier)
                if !FileManager.default.fileExists(atPath: cachePath!.path) {
                    cachePath = nil
                }
                
                if (url != nil) {
                    let since1970 = asset.creationDate?.timeIntervalSince1970
                    var dateAdded: Int? = nil
                    if since1970 != nil {
                        dateAdded = Int(since1970!)
                    }
                    mediaFile = MediaFile.init(
                        id: asset.localIdentifier,
                        dateAdded: dateAdded,
                        path: url!,
                        thumbnailPath: cachePath?.path,
                        orientation: 0,
                        type: .VIDEO)
                }
                semaphore.signal()
            }
            semaphore.wait()
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
    
    private static func getCachePath(for identifier: String) -> URL {
        let fileName = Data(identifier.utf8).base64EncodedString().replacingOccurrences(of: "==", with: "")
        let path = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(fileName + ".png")
        return path
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
