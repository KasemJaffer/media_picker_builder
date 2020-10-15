//
//  MediaFile.swift
//  file_picker
//
//  Created by Kasem Mohamed on 6/29/19.
//

import Foundation

struct MediaFile : Codable {
    var id: String
    var dateAdded: Int? // seconds since 1970
    var path: String?
    var thumbnailPath: String?
    var orientation: Int
    var videoOrientation: Int
    var duration: Double?
    var mimeType: String?
    var type: MediaType
    
    init(id: String, dateAdded: Int?, path: String?, thumbnailPath: String?, orientation: Int, videoOrientation: Int, duration: Double?, mimeType: String?, type: MediaType) {
        self.id = id
        self.dateAdded = dateAdded
        self.path = path
        self.thumbnailPath = thumbnailPath
        self.orientation = orientation
        self.videoOrientation = videoOrientation
        self.duration = duration
        self.mimeType = mimeType
        self.type = type
    }
}

enum MediaType: Int, Codable {
    case IMAGE
    case VIDEO
}


