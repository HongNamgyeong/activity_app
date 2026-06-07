package com.HongNamgyeong.legioActivityApp

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import org.json.JSONObject
import java.io.File
import java.time.Instant

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
            pickNewestByExportedAt(readAllCandidates(context))
        } catch (_: Exception) {
            null
        }
    }

    fun exists(context: Context): Boolean {
        return read(context) != null
    }

    /** 복원 후 — 새 파일 생성 없이 중복만 정리 */
    fun cleanupDuplicates(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            cleanupDuplicatesApi29Plus(context)
        } else {
            cleanupLegacyDuplicates()
        }
    }

    private fun writeApi29Plus(context: Context, content: String): Boolean {
        val legacyOk = writeLegacyFile(content)
        val mediaOk = syncMediaStoreDownload(context, content)
        if (legacyOk || mediaOk) {
            cleanupDuplicatesApi29Plus(context)
            return true
        }
        return legacyOk
    }

    private fun writeLegacyFile(content: String): Boolean {
        return try {
            val dir = legacyBackupDir()
            if (!dir.exists()) {
                dir.mkdirs()
            }
            cleanupLegacyDuplicates()
            File(dir, FILE_NAME).writeText(content, Charsets.UTF_8)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun syncMediaStoreDownload(context: Context, content: String): Boolean {
        val resolver = context.contentResolver
        val bytes = content.toByteArray(Charsets.UTF_8)

        for (uri in findAllBackupUris(context)) {
            try {
                val wrote = resolver.openOutputStream(uri, "wt")?.use { stream ->
                    stream.write(bytes)
                    true
                } == true
                if (wrote) {
                    deleteDuplicateMediaStore(context, keep = uri)
                    return true
                }
            } catch (_: Exception) {
                // 이전 설치·타 앱 소유 파일은 덮어쓰기 불가
            }
        }

        // 디스크/MediaStore에 백업이 남아 있으면 insert 금지 → (1)(2) 방지
        if (hasAnyBackupArtifact(context)) {
            return false
        }

        val collection =
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, FILE_NAME)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = resolver.insert(collection, values) ?: return false
        val wrote = resolver.openOutputStream(uri)?.use { stream ->
            stream.write(bytes)
            true
        } == true

        if (!wrote) {
            resolver.delete(uri, null, null)
            return false
        }

        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        deleteDuplicateMediaStore(context, keep = uri)
        return true
    }

    private fun hasAnyBackupArtifact(context: Context): Boolean {
        if (findAllBackupUris(context).isNotEmpty()) {
            return true
        }
        return readDirectDiskCandidates().isNotEmpty()
    }

    private fun readAllCandidates(context: Context): List<String> {
        val candidates = mutableListOf<String>()
        val seen = HashSet<String>()

        fun add(text: String?) {
            if (text.isNullOrBlank()) return
            val hash = text.hashCode().toString() + text.length
            if (seen.add(hash)) {
                candidates.add(text)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = context.contentResolver
            for (uri in findAllBackupUris(context)) {
                try {
                    resolver.openInputStream(uri)?.bufferedReader()?.use { reader ->
                        add(reader.readText())
                    }
                } catch (_: Exception) {
                    // 권한 없으면 스킵
                }
            }
            for (uri in findAllBackupFileUris(context)) {
                try {
                    resolver.openInputStream(uri)?.bufferedReader()?.use { reader ->
                        add(reader.readText())
                    }
                } catch (_: Exception) {
                    // ignore
                }
            }
        }

        readDirectDiskCandidates().forEach { add(it) }
        return candidates
    }

    /** MediaStore.Files — Downloads 컬렉션에 안 잡히는 항목 보완 */
    private fun findAllBackupFileUris(context: Context): List<Uri> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return emptyList()
        }
        val resolver = context.contentResolver
        val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(MediaStore.Files.FileColumns._ID)
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
        val args = arrayOf(DISPLAY_NAME_LIKE)

        val uris = mutableListOf<Uri>()
        resolver.query(collection, projection, selection, args, null)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                uris.add(ContentUris.withAppendedId(collection, id))
            }
        }
        return uris
    }

    private fun findAllBackupUris(context: Context): List<Uri> {
        val resolver = context.contentResolver
        val collection =
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(MediaStore.Downloads._ID)
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
        val args = arrayOf(DISPLAY_NAME_LIKE)

        val uris = mutableListOf<Uri>()
        resolver.query(collection, projection, selection, args, null)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumn)
                uris.add(ContentUris.withAppendedId(collection, id))
            }
        }
        return uris
    }

    private fun readDirectDiskCandidates(): List<String> {
        val results = mutableListOf<String>()
        try {
            @Suppress("DEPRECATION")
            val downloads =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            scanBackupFiles(downloads, results, depth = 2)
        } catch (_: Exception) {
            // ignore
        }
        return results
    }

    private fun scanBackupFiles(dir: File?, results: MutableList<String>, depth: Int) {
        if (dir == null || !dir.exists() || depth < 0) return
        val files = dir.listFiles() ?: return
        for (file in files) {
            when {
                file.isFile && file.name.startsWith("legio_activity_report_backup") -> {
                    runCatching { file.readText(Charsets.UTF_8) }
                        .getOrNull()
                        ?.takeIf { it.isNotBlank() }
                        ?.let { results.add(it) }
                }
                file.isDirectory && depth > 0 -> scanBackupFiles(file, results, depth - 1)
            }
        }
    }

    private fun cleanupDuplicatesApi29Plus(context: Context) {
        val candidates = readAllCandidates(context)
        val best = pickNewestByExportedAt(candidates) ?: run {
            deleteAllDeletableMediaStore(context)
            cleanupLegacyDuplicates()
            return
        }

        val keepUri = findUriForContent(context, best)
        if (keepUri != null) {
            deleteDuplicateMediaStore(context, keep = keepUri)
        }
        cleanupLegacyDuplicates()
        // 최신 내용을 canonical 파일에 반영
        writeLegacyFile(best)
    }

    private fun findUriForContent(context: Context, target: String): Uri? {
        val resolver = context.contentResolver
        val allUris = findAllBackupUris(context) + findAllBackupFileUris(context)
        for (uri in allUris.distinct()) {
            try {
                val text = resolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
                if (text == target) {
                    return uri
                }
            } catch (_: Exception) {
                // ignore
            }
        }
        return null
    }

    private fun deleteAllDeletableMediaStore(context: Context) {
        val resolver = context.contentResolver
        for (uri in (findAllBackupUris(context) + findAllBackupFileUris(context)).distinct()) {
            try {
                resolver.delete(uri, null, null)
            } catch (_: Exception) {
                // ignore
            }
        }
    }

    private fun deleteDuplicateMediaStore(context: Context, keep: Uri) {
        val resolver = context.contentResolver
        for (uri in (findAllBackupUris(context) + findAllBackupFileUris(context)).distinct()) {
            if (uri == keep) continue
            try {
                resolver.delete(uri, null, null)
            } catch (_: Exception) {
                // ignore
            }
        }
    }

    private fun pickNewestByExportedAt(contents: List<String>): String? {
        var best: String? = null
        var bestMillis = Long.MIN_VALUE
        for (raw in contents) {
            val exportedAt = parseExportedAtMillis(raw) ?: continue
            if (exportedAt > bestMillis) {
                bestMillis = exportedAt
                best = raw
            }
        }
        return best
    }

    private fun parseExportedAtMillis(raw: String): Long? {
        return try {
            val json = JSONObject(raw)
            val exportedAt = json.optString("exportedAt", "")
            if (exportedAt.isEmpty()) return null
            Instant.parse(exportedAt).toEpochMilli()
        } catch (_: Exception) {
            null
        }
    }

    private fun writeLegacy(context: Context, content: String): Boolean {
        return writeLegacyFile(content)
    }

    private fun readLegacy(context: Context): String? {
        return pickNewestByExportedAt(readDirectDiskCandidates())
    }

    private fun cleanupLegacyDuplicates() {
        val dir = legacyBackupDir()
        if (!dir.exists()) return
        val files = dir.listFiles()
            ?.filter { it.isFile && it.name.startsWith("legio_activity_report_backup") }
            ?: return
        if (files.isEmpty()) return

        val texts = files.mapNotNull { file ->
            val text = runCatching { file.readText(Charsets.UTF_8) }.getOrNull()
            if (text.isNullOrBlank()) null else file to text
        }
        if (texts.isEmpty()) return

        val best = texts.maxByOrNull { (_, text) -> parseExportedAtMillis(text) ?: 0L }
        for ((file, _) in texts) {
            if (file != best?.first) {
                file.delete()
            }
        }
        best?.first?.let { keep ->
            if (keep.name != FILE_NAME) {
                val target = File(dir, FILE_NAME)
                keep.renameTo(target)
            }
        }
    }

    private fun legacyBackupDir(): File {
        @Suppress("DEPRECATION")
        return File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            BACKUP_FOLDER,
        )
    }
}
