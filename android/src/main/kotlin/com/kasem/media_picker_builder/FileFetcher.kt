package com.kasem.media_picker_builder

import android.content.Context
import android.graphics.Bitmap
import android.provider.MediaStore
import org.json.JSONArray

class FileFetcher {
    companion object {
        fun getAlbums(context: Context, withImages: Boolean, withVideos: Boolean): JSONArray {
            val albumHashMap: MutableMap<Long, Album> = LinkedHashMap()

            if (withImages)
                fetchImages(context, albumHashMap)

            if (withVideos)
                fetchVideos(context, albumHashMap)

            fetchThumbnails(context, albumHashMap, withImages, withVideos)

            albumHashMap.values.forEach { album ->
                album.files.sortByDescending { file ->
                    file.dateAdded
                }
            }

            return JSONArray(albumHashMap.values.map { it.toJSONObject() })
        }

        private fun fetchImages(context: Context, albumHashMap: MutableMap<Long, Album>) {
            context.contentResolver.query(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                    arrayOf(
                            MediaStore.Images.Media._ID,
                            MediaStore.Images.Media.DATE_ADDED,
                            MediaStore.Images.Media.DATA,
                            MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
                            MediaStore.Images.Media.BUCKET_ID,
                            MediaStore.Images.Media.ORIENTATION)
                    , null,
                    null,
                    "${MediaStore.Images.Media._ID} DESC")?.use { cursor ->

                while (cursor.moveToNext()) {
                    val fileId = cursor.getLong(0)
                    val fileDateAdded = cursor.getLong(1)
                    val filePath = cursor.getString(2)
                    val albumName = cursor.getString(3)
                    val albumId = cursor.getLong(4)
                    val orientation = cursor.getInt(5)
                    val album = albumHashMap[albumId]
                    if (album == null) {
                        albumHashMap[albumId] = Album(
                                albumId,
                                albumName,
                                mutableListOf(
                                        MediaFile(
                                                fileId,
                                                fileDateAdded,
                                                filePath,
                                                null,
                                                orientation,
                                                MediaFile.MediaType.IMAGE
                                        )
                                )
                        )
                    } else {
                        album.files.add(
                                MediaFile(
                                        fileId,
                                        fileDateAdded,
                                        filePath,
                                        null,
                                        orientation,
                                        MediaFile.MediaType.IMAGE
                                )
                        )
                    }
                }
            }
        }

        private fun fetchVideos(context: Context, albumHashMap: MutableMap<Long, Album>) {
            context.contentResolver.query(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                    arrayOf(
                            MediaStore.Video.Media._ID,
                            MediaStore.Video.Media.DATE_ADDED,
                            MediaStore.Video.Media.DATA,
                            MediaStore.Video.Media.BUCKET_DISPLAY_NAME,
                            MediaStore.Video.Media.BUCKET_ID)
                    , null,
                    null,
                    "${MediaStore.Video.Media._ID} DESC")?.use { cursor ->

                while (cursor.moveToNext()) {
                    val fileId = cursor.getLong(0)
                    val fileDateAdded = cursor.getLong(1)
                    val filePath = cursor.getString(2)
                    val albumName = cursor.getString(3)
                    val albumId = cursor.getLong(4)
                    val album = albumHashMap[albumId]
                    if (album == null) {
                        albumHashMap[albumId] = Album(
                                albumId,
                                albumName,
                                mutableListOf(
                                        MediaFile(
                                                fileId,
                                                fileDateAdded,
                                                filePath,
                                                null,
                                                0,
                                                MediaFile.MediaType.VIDEO
                                        )
                                )
                        )
                    } else {
                        album.files.add(
                                MediaFile(
                                        fileId,
                                        fileDateAdded,
                                        filePath,
                                        null,
                                        0,
                                        MediaFile.MediaType.VIDEO
                                )
                        )
                    }
                }
            }
        }

        private fun fetchThumbnails(context: Context,
                                    albumHashMap: MutableMap<Long, Album>,
                                    withImages: Boolean,
                                    withVideos: Boolean) {
            if (withImages)
                context.contentResolver.query(
                        MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI,
                        arrayOf(
                                MediaStore.Images.Thumbnails.IMAGE_ID,
                                MediaStore.Images.Thumbnails.DATA
                        ),
                        null,
                        null,
                        null)?.use { cursor ->
                    while (cursor.moveToNext()) {
                        val fileId = cursor.getLong(0)
                        val thumbnail = cursor.getString(1)
                        for (album in albumHashMap.values) {
                            val file = album.files.firstOrNull { it.id == fileId }
                            if (file != null) {
                                file.thumbnailPath = thumbnail
                                break
                            }
                        }
                    }

                }

            if (withVideos)
                context.contentResolver.query(
                        MediaStore.Video.Thumbnails.EXTERNAL_CONTENT_URI,
                        arrayOf(
                                MediaStore.Video.Thumbnails.VIDEO_ID,
                                MediaStore.Video.Thumbnails.DATA
                        ),
                        null,
                        null,
                        null)?.use { cursor ->

                    val fileIdColumn = cursor.getColumnIndex(MediaStore.Video.Thumbnails.VIDEO_ID)
                    val thumbnailPathColumn = cursor.getColumnIndex(MediaStore.Video.Thumbnails.DATA)
                    while (cursor.moveToNext()) {
                        val fileId = cursor.getLong(fileIdColumn)
                        val thumbnail = cursor.getString(thumbnailPathColumn)
                        for (album in albumHashMap.values) {
                            val file = album.files.firstOrNull { it.id == fileId }
                            if (file != null) {
                                file.thumbnailPath = thumbnail
                                break
                            }
                        }
                    }
                }
        }

        fun getThumbnail(context: Context, fileId: Long, type: MediaFile.MediaType): String? {
            generateThumbnail(context, fileId, type)
            var path: String? = null
            when (type) {
                MediaFile.MediaType.IMAGE -> {
                    context.contentResolver.query(
                            MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI,
                            arrayOf(MediaStore.Images.Thumbnails.DATA),
                            "${MediaStore.Images.Thumbnails.IMAGE_ID} = $fileId"
                                    + " AND ${MediaStore.Images.Thumbnails.KIND} = ${MediaStore.Images.Thumbnails.MINI_KIND}",
                            null,
                            null)?.use { cursor ->
                        if (cursor.count > 0) {
                            cursor.moveToFirst()
                            path = cursor.getString(0)
                        }
                    }
                }
                MediaFile.MediaType.VIDEO -> {
                    context.contentResolver.query(
                            MediaStore.Video.Thumbnails.EXTERNAL_CONTENT_URI,
                            arrayOf(MediaStore.Video.Thumbnails.DATA),
                            "${MediaStore.Video.Thumbnails.VIDEO_ID} = $fileId AND "
                                    + "${MediaStore.Video.Thumbnails.KIND} = ${MediaStore.Video.Thumbnails.MINI_KIND}",
                            null,
                            null)?.use { cursor ->
                        if (cursor.count > 0) {
                            cursor.moveToFirst()
                            path = cursor.getString(0)
                        }
                    }
                }
            }
            return path
        }

        private fun generateThumbnail(context: Context, fileId: Long, type: MediaFile.MediaType) {
            val bitmap: Bitmap? = when (type) {
                MediaFile.MediaType.IMAGE -> {
                    MediaStore.Images.Thumbnails.getThumbnail(
                            context.contentResolver, fileId,
                            MediaStore.Images.Thumbnails.MINI_KIND, null)
                }
                MediaFile.MediaType.VIDEO -> {
                    MediaStore.Video.Thumbnails.getThumbnail(
                            context.contentResolver, fileId,
                            MediaStore.Video.Thumbnails.MINI_KIND, null)

                }
            }
            bitmap?.recycle()
        }
    }
}