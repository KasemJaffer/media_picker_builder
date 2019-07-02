package com.kasem.media_picker_builder

import org.json.JSONArray
import org.json.JSONObject

class Album(
        var id: Long,
        var name: String,
        var files: MutableList<MediaFile>) {


    fun toJSONObject(): JSONObject {
        return JSONObject()
                .put("id", id.toString())
                .put("name", name)
                .put("files", JSONArray(files.map { it.toJSONObject() }))
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as Album

        if (id != other.id) return false

        return true
    }

    override fun hashCode(): Int {
        return id.hashCode()
    }


}