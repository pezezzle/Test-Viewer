package com.pezezzle.testmasterviewer;

import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.provider.DocumentsContract;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.json.JSONObject;

/** Native file access only. All screens and calculations are Flutter widgets and Dart. */
public final class MainActivity extends FlutterActivity {
    private static final int PICK_DIRECTORY = 401;
    private static final String CHANNEL = "com.pezezzle.testmasterviewer/data";
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private SharedPreferences preferences;
    private MethodChannel channel;
    private MethodChannel.Result pendingPicker;
    private volatile boolean destroyed;

    @Override
    public void configureFlutterEngine(FlutterEngine engine) {
        super.configureFlutterEngine(engine);
        // Preserve the native source grant from the earlier Java/WebView version.
        preferences = getSharedPreferences("viewer", MODE_PRIVATE);
        channel = new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler((call, result) -> {
            try {
                switch (call.method) {
                    case "configuration": result.success(configuration().toString()); break;
                    case "loadSettings": result.success(preferences.getString("flutterFilters", "{}")); break;
                    case "saveSettings":
                        if (!(call.arguments instanceof String)) throw new IllegalArgumentException("Invalid settings.");
                        String settings = (String) call.arguments;
                        if (settings.length() > 1024 * 1024) throw new IllegalArgumentException("The settings are too large.");
                        new JSONObject(settings);
                        // Commit confirms persistence before acknowledging the method call.
                        executor.execute(() -> {
                            boolean saved = preferences.edit().putString("flutterFilters", settings).commit();
                            runOnUiThread(() -> { if (!destroyed) { if (saved) result.success(null); else result.error("settings", "The settings could not be saved.", null); } });
                        });
                        break;
                    case "chooseFolder": chooseFolder(result); break;
                    case "savePath":
                        if (!(call.arguments instanceof String)) throw new IllegalArgumentException("Enter a file name.");
                        String path = PathPolicy.normalize((String) call.arguments);
                        if (!preferences.edit().putString("path", path).commit()) throw new IllegalStateException("The path could not be saved.");
                        result.success(configuration().toString());
                        break;
                    case "readSnapshot": readSnapshot(result); break;
                    default: result.notImplemented();
                }
            } catch (Exception exception) { result.error("viewer", SnapshotReader.friendlyError(exception), null); }
        });
    }

    private JSONObject configuration() throws Exception {
        String tree = preferences.getString("tree", "");
        String folder = tree.isEmpty() ? "" : DocumentsContract.getTreeDocumentId(Uri.parse(tree));
        if (folder.startsWith("primary:")) folder = "Interner Speicher/" + folder.substring(8);
        JSONObject value = new JSONObject();
        value.put("folder", folder);
        value.put("treeUri", tree);
        value.put("path", preferences.getString("path", "pcdrdata.sqlite3"));
        value.put("configured", !tree.isEmpty());
        value.put("version", "2.0.0");
        return value;
    }

    private void chooseFolder(MethodChannel.Result result) {
        if (pendingPicker != null) { result.error("busy", "The folder picker is already open.", null); return; }
        pendingPicker = result;
        try {
            Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION | Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
            String tree = preferences.getString("tree", "");
            if (!tree.isEmpty()) intent.putExtra("android.provider.extra.INITIAL_URI", Uri.parse(tree));
            startActivityForResult(intent, PICK_DIRECTORY);
        } catch (Exception exception) {
            pendingPicker = null;
            result.error("picker", "The Android file picker could not be opened.", null);
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != PICK_DIRECTORY || pendingPicker == null) return;
        MethodChannel.Result result = pendingPicker;
        pendingPicker = null;
        if (resultCode != RESULT_OK || data == null || data.getData() == null) { result.success(null); return; }
        try {
            Uri selected = data.getData();
            getContentResolver().takePersistableUriPermission(selected, Intent.FLAG_GRANT_READ_URI_PERMISSION);
            if (!preferences.edit().putString("tree", selected.toString()).commit()) throw new IllegalStateException("The folder grant could not be saved.");
            result.success(configuration().toString());
        } catch (Exception exception) { result.error("permission", "The read grant could not be saved. Select a local folder under Documents.", null); }
    }

    private void readSnapshot(MethodChannel.Result result) {
        final String tree = preferences.getString("tree", "");
        final String path = preferences.getString("path", "pcdrdata.sqlite3");
        if (tree.isEmpty()) { result.error("source", "Select the database folder first.", null); return; }
        executor.execute(() -> {
            try {
                String snapshot = new SnapshotReader(getApplicationContext()).read(Uri.parse(tree), path).toString();
                runOnUiThread(() -> { if (!destroyed) result.success(snapshot); });
            } catch (Exception exception) {
                runOnUiThread(() -> { if (!destroyed) result.error("snapshot", SnapshotReader.friendlyError(exception), null); });
            }
        });
    }

    @Override
    protected void onDestroy() {
        destroyed = true;
        if (channel != null) channel.setMethodCallHandler(null);
        if (pendingPicker != null) { pendingPicker.error("cancelled", "Folder selection was closed.", null); pendingPicker = null; }
        executor.shutdownNow();
        super.onDestroy();
    }
}
