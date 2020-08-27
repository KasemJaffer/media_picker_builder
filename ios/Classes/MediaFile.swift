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
    var duration: Double?
    var mimeType: String?
    var fileName: String?
    var type: MediaType
    
    init(id: String, dateAdded: Int?, path: String?, thumbnailPath: String?, orientation: Int, duration: Double?, mimeType: String?, fileName: String?, type: MediaType) {
        self.id = id
        self.dateAdded = dateAdded
        self.path = path
        self.thumbnailPath = thumbnailPath
        self.orientation = orientation
        self.duration = duration
        self.mimeType = mimeType
        self.fileName = fileName
        self.type = type
    }
}

enum MediaType: Int, Codable {
    case IMAGE
    case VIDEO
}


