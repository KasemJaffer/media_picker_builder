package com.kasem.media_picker_builder

import android.content.Context
import android.os.Handler
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.lang.Exception
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MediaPickerBuilderPlugin(private val context: Context) : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "media_picker_builder")
            channel.setMethodCallHandler(MediaPickerBuilderPlugin(registrar.context()))
        }
    }

    private val executor: ExecutorService = Executors.newFixedThreadPool(1)
    private val mainHandler by lazy { Handler(context.mainLooper) }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAlbums" -> {
                val withImages = call.argument<Boolean>("withImages")
                val withVideos = call.argument<Boolean>("withVideos")
                if (withImages == null || withVideos == null) {
                    result.error("INVALID_ARGUMENTS", "withImages or withVideos must not be null", null)
                    return
                }
                val albums = FileFetcher.getAlbums(context, withImages, withVideos)
                result.success(albums.toString())
            }
            "getThumbnail" -> {
                val fileId = call.argument<String>("fileId")
                val type = call.argument<Int>("type")
                if (fileId == null || type == null) {
                    result.error("INVALID_ARGUMENTS", "fileId or type must not be null", null)
                    return
                }
                executor.execute {
                    try {
                        val thumbnail = FileFetcher.getThumbnail(
                                context,
                                fileId.toLong(),
                                MediaFile.MediaType.values()[type]
                        )
                        mainHandler.post {
                            if (thumbnail != null)
                                result.success(thumbnail)
                            else
                                result.error("NOT_FOUND", "Unable to get the thumbnail", null)
                        }
                    } catch (e: Exception) {
                        Log.e("MediaPickerBuilder", e.message.toString())
                        mainHandler.post {
                            result.error("GENERATE_THUMBNAIL_FAILED", "Unable to generate thumbnail ${e.message}", null)
                        }
                    }
                }
            }
            "getMediaFile" -> {
                val fileIdString = call.argument<String>("fileId")
                val type = call.argument<Int>("type")
                val loadThumbnail = call.argument<Boolean>("loadThumbnail")
                if (fileIdString == null || type == null || loadThumbnail == null) {
                    result.error("INVALID_ARGUMENTS", "fileId, type or loadThumbnail must not be null", null)
                    return
                }

                val fileId = fileIdString.toLongOrNull()
                if (fileId == null) {
                    result.error("NOT_FOUND", "Unable to find the file", null)
                    return
                }

                executor.execute {
                    try {
                        val mediaFile = FileFetcher.getMediaFile(
                                context,
                                fileId,
                                MediaFile.MediaType.values()[type],
                                loadThumbnail)
                        mainHandler.post {
                            if (mediaFile != null)
                                result.success(mediaFile.toJSONObject().toString())
                            else
                                result.error("NOT_FOUND", "Unable to find the file", null)
                        }
                    } catch (e: Exception) {
                        Log.e("MediaPickerBuilder", e.message.toString())
                        mainHandler.post {
                            result.error("GENERATE_THUMBNAIL_FAILED", "Unable to generate thumbnail ${e.message}", null)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }
}
