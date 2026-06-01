package com.HongNamgyeong.legioActivityApp

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File

object PublicBackupStorage {
    const val FILE_NAME = "legio_activity_report_backup.json"
    private const val BACKUP_FOLDER = "LegioActivityReport"
    private val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/$BACKUP_FOLDER/"
    private const val DISPLAY_NAME_LIKE = "legio_activity_report_backup%"

    fun write(context: Context, content: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                writeApi29Plus(context, content)
            } else {
                writeLegacy(context, content)
            }
        } catch (_: Exception) {
            false
        }
    }

    fun read(context: Context): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                readApi29Plus(context)
            } else {
                readLegacy(context)
            }
        } catch (_: Exception) {
            null
        }
    }

    fun exists(context: Context): Boolean {
        return read(context) != null
    }

    private fun writeApi29Plus(context: Context, content: String): Boolean {
        val resolver = context.contentResolver
        val collection =
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

        deleteAllBackupFilesApi29Plus(context)

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, FILE_NAME)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = resolver.insert(collection, values) ?: return false
        val wrote = resolver.openOutputStream(uri)?.use { stream ->
            stream.write(content.toByteArray(Charsets.UTF_8))
            true
        } == true

        if (!wrote) {
            resolver.delete(uri, null, null)
            return false
        }

        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return true
    }

    private fun readApi29Plus(context: Context): String? {
        val uri = findNewestBackupUri(context) ?: return null
        return context.contentResolver.openInputStream(uri)?.bufferedReader()?.use {
            it.readText()
        }
    }

    private fun findNewestBackupUri(context: Context): Uri? {
        val resolver = context.contentResolver
        val collection =
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(
            MediaStore.Downloads._ID,
            MediaStore.MediaColumns.DATE_MODIFIED,
        )
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
        val args = arrayOf(DISPLAY_NAME_LIKE)
        val sortOrder = "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"

        resolver.query(collection, projection, selection, args, sortOrder)?.use { cursor ->
            if (!cursor.moveToFirst()) return@use null
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
            val id = cursor.getLong(idColumn)
            return ContentUris.withAppendedId(collection, id)
        }
        return null
    }

    private fun deleteAllBackupFilesApi29Plus(context: Context) {
        val resolver = context.contentResolver
        val collection =
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
        val args = arrayOf(DISPLAY_NAME_LIKE)
        resolver.delete(collection, selection, args)
    }

    private fun writeLegacy(context: Context, content: String): Boolean {
        val dir = legacyBackupDir()
        if (!dir.exists()) {
            dir.mkdirs()
        }
        deleteLegacyBackupFiles(dir)
        File(dir, FILE_NAME).writeText(content, Charsets.UTF_8)
        return true
    }

    private fun readLegacy(context: Context): String? {
        val dir = legacyBackupDir()
        val files = dir.listFiles()
            ?.filter { it.isFile && it.name.startsWith("legio_activity_report_backup") }
            ?.sortedByDescending { it.lastModified() }
            ?: return null
        return files.firstOrNull()?.readText(Charsets.UTF_8)
    }

    private fun legacyBackupDir(): File {
        @Suppress("DEPRECATION")
        return File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            BACKUP_FOLDER,
        )
    }

    private fun deleteLegacyBackupFiles(dir: File) {
        dir.listFiles()?.forEach { file ->
            if (file.isFile && file.name.startsWith("legio_activity_report_backup")) {
                file.delete()
            }
        }
    }
}
