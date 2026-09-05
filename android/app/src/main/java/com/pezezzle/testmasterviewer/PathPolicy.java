package com.pezezzle.testmasterviewer;

import java.io.IOException;

/** Validates paths relative to the explicitly selected directory. */
public final class PathPolicy {
    private PathPolicy() { }
    public static String normalize(String value) throws IOException {
        String path = value == null ? "" : value.trim().replace('\\', '/');
        if (path.isEmpty() || path.startsWith("/") || path.contains(":") || path.indexOf('\0') >= 0 || path.length() > 500) throw new IOException("Enter a file name or relative path inside the selected folder, for example pcdrdata.sqlite3.");
        for (String part : path.split("/", -1)) if (part.isEmpty() || part.equals(".") || part.equals("..")) throw new IOException("The database path contains an invalid folder segment.");
        return path;
    }
}
