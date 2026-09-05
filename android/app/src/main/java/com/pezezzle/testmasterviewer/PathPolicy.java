package com.pezezzle.testmasterviewer;

import java.io.IOException;

/** Validates paths relative to the explicitly selected directory. */
public final class PathPolicy {
    private PathPolicy() { }
    public static String normalize(String value) throws IOException {
        String path = value == null ? "" : value.trim().replace('\\', '/');
        if (path.isEmpty() || path.startsWith("/") || path.contains(":") || path.indexOf('\0') >= 0 || path.length() > 500) throw new IOException("Gib einen Dateinamen oder relativen Pfad innerhalb des ausgewählten Ordners ein, zum Beispiel pcdrdata.sqlite3.");
        for (String part : path.split("/", -1)) if (part.isEmpty() || part.equals(".") || part.equals("..")) throw new IOException("Der Datenbankpfad enthält einen ungültigen Ordnerabschnitt.");
        return path;
    }
}
