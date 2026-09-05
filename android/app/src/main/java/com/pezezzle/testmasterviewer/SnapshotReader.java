package com.pezezzle.testmasterviewer;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;
import android.provider.DocumentsContract;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.MessageDigest;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import org.json.JSONArray;
import org.json.JSONObject;

/** Copies a quiescent, user-selected database to private temporary storage and reads that copy. */
public final class SnapshotReader {
    private static final long MAX_BYTES = 512L * 1024L * 1024L;
    private static final String[] COLUMNS = { "CustomerNumber", "IDNumber", "Location", "DeviceDescription", "Manufacturer", "Type", "Class", "Standard", "FactoryNumber", "LastTest", "NextTest", "TestInterval", "TestResult", "Remark", "Status", "User1", "User2", "User3", "SubStandard" };
    private final Context context;
    private final ContentResolver resolver;
    public SnapshotReader(Context context) { this.context = context; this.resolver = context.getContentResolver(); }

    public static String normalizePath(String value) throws IOException { return PathPolicy.normalize(value); }

    public JSONObject read(Uri tree, String requestedPath) throws Exception {
        String path = normalizePath(requestedPath);
        String[] parts = path.split("/");
        String parentId = DocumentsContract.getTreeDocumentId(tree);
        for (int i = 0; i < parts.length - 1; i++) {
            Document folder = find(tree, parentId, parts[i]);
            if (folder == null || !folder.directory) throw new IOException("Unterordner nicht gefunden: " + parts[i] + ". Prüfe den Datenbankpfad.");
            parentId = folder.id;
        }
        String fileName = parts[parts.length - 1];
        Document source = find(tree, parentId, fileName);
        if (source == null || source.directory) throw new IOException("Datenbank nicht gefunden: " + path + ". Prüfe den ausgewählten Ordner und Dateinamen.");
        assertQuiet(tree, parentId, fileName);
        Uri sourceUri = DocumentsContract.buildDocumentUriUsingTree(tree, source.id);
        File copy = File.createTempFile("testmaster-read-", ".sqlite3", context.getCacheDir());
        SQLiteDatabase database = null;
        try {
            byte[] firstHash = copyAndHash(sourceUri, copy);
            assertQuiet(tree, parentId, fileName);
            // A second complete read detects changes while the temporary snapshot was copied.
            byte[] secondHash = copyAndHash(sourceUri, null);
            assertQuiet(tree, parentId, fileName);
            if (!MessageDigest.isEqual(firstHash, secondHash)) throw new IOException("Die Prüf-App hat die Datenbank während des Einlesens geändert. Speichere die Prüfung, pausiere die Prüf-App und aktualisiere erneut.");
            verifyHeader(copy);
            database = SQLiteDatabase.openDatabase(copy.getAbsolutePath(), null, SQLiteDatabase.OPEN_READONLY | SQLiteDatabase.NO_LOCALIZED_COLLATORS);
            try (Cursor check = database.rawQuery("PRAGMA quick_check(1)", null)) {
                if (!check.moveToFirst() || !"ok".equalsIgnoreCase(check.getString(0))) throw new IOException("Die Datenbankkopie ist inkonsistent. Speichere die Prüfung, schliesse die Prüf-App vollständig und aktualisiere erneut. Die Quelldatei wurde nicht verändert.");
            }
            Set<String> available = new HashSet<String>();
            try (Cursor schema = database.rawQuery("PRAGMA table_info(tblIDNumbers)", null)) { while (schema.moveToNext()) available.add(schema.getString(1)); }
            for (String required : new String[] { "CustomerNumber", "IDNumber", "Location", "DeviceDescription", "NextTest" }) {
                if (!available.contains(required)) throw new IOException("Diese Datei besitzt nicht das erwartete Geräteschema (tblIDNumbers / " + required + "). Wähle pcdrdata.sqlite3 aus der Prüf-App.");
            }
            StringBuilder sql = new StringBuilder("SELECT ");
            for (int i = 0; i < COLUMNS.length; i++) {
                if (i > 0) sql.append(',');
                String name = COLUMNS[i];
                sql.append(available.contains(name) ? "\"" + name + "\"" : "NULL AS \"" + name + "\"");
            }
            sql.append(" FROM tblIDNumbers");
            JSONArray rows = new JSONArray();
            try (Cursor cursor = database.rawQuery(sql.toString(), null)) {
                while (cursor.moveToNext()) {
                    if (rows.length() >= 200000) throw new IOException("Mehr als 200.000 Geräte. Diese Datenbank ist zu gross für die mobile Auswertung.");
                    JSONObject row = new JSONObject();
                    for (int i = 0; i < COLUMNS.length; i++) row.put(COLUMNS[i], cursor.isNull(i) ? JSONObject.NULL : cursor.getString(i));
                    rows.put(row);
                }
            }
            JSONObject output = new JSONObject();
            String base = DocumentsContract.getTreeDocumentId(tree);
            if (base.startsWith("primary:")) base = "Interner Speicher/" + base.substring(8);
            output.put("devices", rows);
            output.put("customers", CustomerReader.read(database));
            output.put("sourceLabel", base + "/" + path);
            output.put("sourceUri", sourceUri.toString());
            output.put("readAt", new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).format(new java.util.Date()));
            output.put("sourceModified", source.modified > 0 ? new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).format(new java.util.Date(source.modified)) : JSONObject.NULL);
            output.put("warnings", new JSONArray());
            output.put("version", "2.0.1");
            return output;
        } finally {
            if (database != null) database.close();
            copy.delete();
            new File(copy.getAbsolutePath() + "-wal").delete();
            new File(copy.getAbsolutePath() + "-shm").delete();
            new File(copy.getAbsolutePath() + "-journal").delete();
        }
    }

    private Document find(Uri tree, String parentId, String name) throws IOException {
        Uri children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId);
        String[] projection = { "document_id", "_display_name", "mime_type", "_size", "last_modified" };
        try (Cursor cursor = resolver.query(children, projection, null, null, null)) {
            if (cursor == null) throw new IOException("Der Ordner kann nicht gelesen werden. Erteile den Ordnerzugriff erneut.");
            while (cursor.moveToNext()) {
                if (name.equals(cursor.getString(1))) return new Document(cursor.getString(0), "vnd.android.document/directory".equals(cursor.getString(2)), cursor.isNull(3) ? -1 : cursor.getLong(3), cursor.isNull(4) ? 0 : cursor.getLong(4));
            }
        }
        return null;
    }

    private void assertQuiet(Uri tree, String parentId, String fileName) throws IOException {
        if (Thread.currentThread().isInterrupted()) throw new IOException("Einlesen abgebrochen.");
        for (String suffix : new String[] { "-wal", "-journal" }) {
            Document companion = find(tree, parentId, fileName + suffix);
            if (companion != null && companion.size != 0) {
                // Inactive rollback journals may exist with an all-zero header. A WAL is never ignored.
                if (suffix.equals("-journal") && isZeroJournal(DocumentsContract.buildDocumentUriUsingTree(tree, companion.id))) continue;
                throw new IOException("Die Prüfsoftware hat noch eine SQLite-Journaldatei geöffnet (" + suffix + "). Speichere die Prüfung, schliesse die Prüf-App vollständig und aktualisiere dann. Journal-Dateien niemals löschen.");
            }
        }
    }

    private boolean isZeroJournal(Uri uri) throws IOException {
        try (InputStream input = resolver.openInputStream(uri)) {
            if (input == null) return false;
            for (int i = 0; i < 8; i++) { int value = input.read(); if (value < 0) return true; if (value != 0) return false; }
            return true;
        }
    }

    private byte[] copyAndHash(Uri uri, File target) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream input = resolver.openInputStream(uri); FileOutputStream output = target == null ? null : new FileOutputStream(target)) {
            if (input == null) throw new IOException("Die Datenbank konnte nicht geöffnet werden.");
            byte[] buffer = new byte[65536];
            long total = 0;
            int count;
            while ((count = input.read(buffer)) != -1) {
                if (Thread.currentThread().isInterrupted()) throw new IOException("Einlesen abgebrochen.");
                total += count;
                if (total > MAX_BYTES) throw new IOException("Die Datenbank ist grösser als 512 MB. Diese App-Version unterstützt nur kleinere Prüfdatenbanken.");
                digest.update(buffer, 0, count);
                if (output != null) output.write(buffer, 0, count);
            }
            if (total < 100) throw new IOException("Die ausgewählte Datei ist keine gültige SQLite-Datenbank.");
        }
        return digest.digest();
    }

    private void verifyHeader(File file) throws IOException {
        byte[] header = new byte[16];
        try (InputStream input = new java.io.FileInputStream(file)) {
            int count = input.read(header);
            if (count != 16 || !Arrays.equals(header, "SQLite format 3\0".getBytes(java.nio.charset.StandardCharsets.US_ASCII))) throw new IOException("Die ausgewählte Datei ist keine unverschlüsselte SQLite-3-Datenbank.");
        }
    }

    public static String friendlyError(Exception exception) {
        if (exception instanceof SecurityException) return "Die gespeicherte Lesefreigabe ist nicht mehr gültig. Wähle den Ordner unter Datenbank erneut aus.";
        if (exception instanceof IOException) return exception.getMessage();
        String detail = exception.getMessage();
        return "Die Datenbank konnte nicht gelesen werden. Speichere und schliesse die Prüf-App und prüfe danach den Datenbankpfad." + (detail == null ? "" : "\nTechnische Meldung: " + detail);
    }

    private static final class Document {
        final String id; final boolean directory; final long size; final long modified;
        Document(String id, boolean directory, long size, long modified) { this.id = id; this.directory = directory; this.size = size; this.modified = modified; }
    }
}
