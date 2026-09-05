# Architecture

## Shared Flutter layer

`lib/domain` contains calendar calculations, the device data model, search, natural sorting, filters, and monthly aggregation. `CalendarDay` calculates day differences across UTC midnight while obtaining the automatic reference date from the local calendar. Daylight-saving transitions therefore do not shift day counts.

`lib/state/viewer_controller.dart` manages the source, loaded snapshot, reference date, location selection, pagination, and persisted settings. If a refresh fails, the previous snapshot remains visible but is marked as stale. Changing the source discards old device data and source-specific filters. A manual reference date persists.

`lib/ui` contains Flutter widgets and a `CustomPainter` for the ring chart. `lib/data/platform_store.dart` is the boundary to native file and database access. `DemoViewerStore` is an explicit, entirely synthetic implementation of the same interface.

## Native integration

Method channel: `com.pezezzle.testmasterviewer/data`.

| Call | Response |
|---|---|
| `configuration` | JSON containing folder, source identifier, relative path, and configuration state |
| `chooseFolder` | Persisted folder grant as JSON; `null` when cancelled |
| `savePath` | Validated relative path and current configuration |
| `readSnapshot` | JSON containing `devices`, `customers`, source metadata, and the successful read time |
| `loadSettings` / `saveSettings` | Shared JSON settings state |

Android uses Java, `FlutterActivity`, the Storage Access Framework, SharedPreferences, and Android SQLite. Reads run on a serial worker and return results on the UI thread.

iOS uses Swift, `FlutterAppDelegate`/`FlutterSceneDelegate`, `UIDocumentPickerViewController`, a security-scoped bookmark, UserDefaults, and SQLite3. `NSFileCoordinator` coordinates file reads on a serial queue.

## Data model

The required table is `tblIDNumbers` with `CustomerNumber`, `IDNumber`, `Location`, `DeviceDescription`, and `NextTest`. Additional known columns are included when present; missing optional columns remain empty. Customers are read from `tblCustomer` when available. If a customer name is missing, the customer number is displayed.

Devices are identified by **customer number + device ID**. IDs remain strings to preserve leading zeroes. Identical device IDs owned by different customers are never merged. Empty locations appear as **No location**. Multiple selected locations use OR; different filters and search terms use AND.

Due-date reporting uses `NextTest` from the device master record. Dates are not projected from inspection intervals, and results are not reconstructed from other tables. `LastTest` and the result code also come from the device master record. Reinterpreting inspection history is outside the scope of the two views.

The due categories are: before the reference date, on the reference date, 1–30 days, 31–90 days, more than 90 days, and no valid date. The dashboard's 30-day filter includes the reference date. A future due date does not indicate technical safety. Result code `F` remains a separate warning.

## Snapshot protection

1. Accept only files inside the folder granted by the user.
2. Reject active SQLite companion files.
3. Copy the source into private temporary storage and calculate SHA-256.
4. Hash the full source again and inspect companion files before and after the copy.
5. Open the copy only when both hashes match and the SQLite header is valid.
6. Run `PRAGMA quick_check(1)`, validate the schema, and read a bounded number of records.
7. Delete the temporary copy and only its companion files.

Limits: 512 MB source file, 200,000 records in the mobile reader, and 500 characters in the relative path. These safeguards do not replace testing with the actual file provider. An inspection app with an active WAL must safely commit its changes to the main file first; the viewer never forces a checkpoint in another app's database.

## Storage and privacy

The app has no server connection, telemetry, account, or remote fonts. Android release builds have no `INTERNET` permission; debug/profile builds require it for Flutter tooling. The source grant and filters are stored locally. Operating-system backups and the origin of a user-selected file are outside the app's control.

Public source files contain no original database and no private keys. The iOS privacy manifest describes the local APIs in use and must be checked again against the final archive before store submission.
