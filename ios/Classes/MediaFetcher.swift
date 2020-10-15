//
//  MediaFetcher.swift
//  media_picker_builder
//
//  Created by Juan Alvarez on 10/15/20.
//

import Foundation
import Photos
import UIKit

class MediaFetcher {
    static func getAssetsWithDateRange(start: Date?, end: Date?, type: PHAssetMediaType) -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        
        var predicates: [NSPredicate] = []
        if let startDate = start {
            predicates.append(NSPredicate(format: "creationDate > %@", startDate as CVarArg))
        }
        if let endDate = end {
            predicates.append(NSPredicate(format: "creationDate < %@", endDate as CVarArg))
        }
        
        fetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let results = PHAsset.fetchAssets(with: type, options: fetchOptions)
        
        guard results.count > 0 else {
            return []
        }
        
        var assets: [PHAsset] = []
        
        results.enumerateObjects { (asset, index, stop) in
            assets.append(asset)
        }
        
        return assets
    }
    
    static func getMediaFileForVideo(asset: PHAsset) -> MediaFile {
        let assetId = asset.localIdentifier
        
        var duration: Double? = UserDefaults.standard.double(forKey: "duration-\(assetId)")
        if duration == 0 {
            duration = nil
        }
        
        let since1970 = asset.creationDate?.timeIntervalSince1970
        var dateAdded: Int? = nil
        if since1970 != nil {
            dateAdded = Int(since1970!)
        }
        
        let mediaFile = MediaFile(
            id: assetId,
            dateAdded: dateAdded,
            path: nil,
            thumbnailPath: nil,
            orientation: 0,
            duration: asset.duration,
            mimeType: nil,
            type: .VIDEO)
        
        return mediaFile
    }
    
    static func getMediaFileForImage(asset: PHAsset) -> MediaFile {
        let assetId = asset.localIdentifier
        
        var dateAdded: Int?
        if let creationDate = asset.creationDate {
            dateAdded = Int(creationDate.timeIntervalSince1970)
        }
        
        let mediaFile = MediaFile(
            id: assetId,
            dateAdded: dateAdded,
            path: nil,
            thumbnailPath: nil,
            orientation: 0,
            duration: nil,
            mimeType: nil,
            type: .IMAGE)
        
        return mediaFile
    }
    
    static func getAssetFor(file: MediaFile) -> PHAsset? {
        var asset: PHAsset?
        
        let assetFetch = PHAsset.fetchAssets(withLocalIdentifiers: [file.id], options: nil)
        assetFetch.enumerateObjects { (_asset, _, _) in
            asset = _asset
        }
        
        return asset
    }
    
    static func getThumbnailFor(file: MediaFile, imageSize: CGSize, completion: @escaping (Data?) -> Void) {
        guard let asset = getAssetFor(file: file) else {
            completion(nil)
            return
        }
        
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        
        let manager = PHCachingImageManager.default()
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { (image, info) in
            if let imageData = image?.jpegData(compressionQuality: 0.7) {
                completion(imageData)
            } else {
                completion(nil)
            }
        }
    }
    
    static func getVideoURL(file: MediaFile, progressBlock: @escaping (Double) -> Void, completion: @escaping (URL?) -> Void) {
        guard let asset = getAssetFor(file: file) else {
            completion(nil)
            return
        }
        
        let requestOptions = PHVideoRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.progressHandler = { progress, error, stop, info in
            
        }
        
        let manager = PHCachingImageManager.default()
        manager.requestAVAsset(forVideo: asset, options: requestOptions) { (avAsset, mix, info) in
            guard let urlAsset = avAsset as? AVURLAsset else {
                completion(nil)
                return
            }
            
            completion(urlAsset.url)
        }
    }
}
