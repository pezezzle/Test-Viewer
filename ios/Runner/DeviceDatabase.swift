import Foundation
import SQLite3

enum ViewerReadError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}

/// Only private, validated snapshots may be passed to this reader.
final class DeviceDatabase {
    static let columns = ["CustomerNumber", "IDNumber", "Location", "DeviceDescription", "Manufacturer", "Type", "Class", "Standard", "FactoryNumber", "LastTest", "NextTest", "TestInterval", "TestResult", "Remark", "Status", "User1", "User2", "User3", "SubStandard"]
    private var database: OpaquePointer?

    init(path: String) throws {
        guard sqlite3_open_v2(path, &database, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK else {
            if database != nil { sqlite3_close(database); database = nil }
            throw ViewerReadError.invalid("Die Datenbankkopie konnte nicht geöffnet werden.")
        }
        sqlite3_busy_timeout(database, 1000)
        sqlite3_exec(database, "PRAGMA trusted_schema=OFF", nil, nil, nil)
    }
    deinit { if let database = database { sqlite3_close(database) } }

    private func query(_ sql: String, maximum: Int = 200000) throws -> [[String: Any]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { throw ViewerReadError.invalid("Die erwarteten Prüfdaten konnten nicht gelesen werden.") }
        defer { sqlite3_finalize(statement) }
        var rows = [[String: Any]]()
        var status = sqlite3_step(statement)
        while status == SQLITE_ROW {
            guard rows.count < maximum else { throw ViewerReadError.invalid("Die Datenbank enthält zu viele Einträge für diese mobile Auswertung.") }
            var row = [String: Any]()
            for index in 0..<sqlite3_column_count(statement) {
                let name = String(cString: sqlite3_column_name(statement, index))
                if sqlite3_column_type(statement, index) == SQLITE_NULL { row[name] = NSNull() }
                else if let text = sqlite3_column_text(statement, index) { row[name] = String(cString: text) }
                else { row[name] = "" }
            }
            rows.append(row)
            status = sqlite3_step(statement)
        }
        guard status == SQLITE_DONE else { throw ViewerReadError.invalid("Beim Lesen der Datenbankkopie ist ein Fehler aufgetreten.") }
        return rows
    }

    func read() throws -> [String: Any] {
        let check = try query("PRAGMA quick_check(1)", maximum: 100)
        guard (check.first?["quick_check"] as? String)?.lowercased() == "ok" else { throw ViewerReadError.invalid("Die Datenbankkopie ist nicht konsistent. Prüfung speichern, Prüf-App schliessen und erneut aktualisieren. Die Originaldatei wurde nicht verändert.") }
        let available = Set(try query("PRAGMA table_info(tblIDNumbers)", maximum: 1000).compactMap { $0["name"] as? String })
        for required in ["CustomerNumber", "IDNumber", "Location", "DeviceDescription", "NextTest"] {
            guard available.contains(required) else { throw ViewerReadError.invalid("Diese Datei hat nicht die erwartete Geräte-Datenstruktur (tblIDNumbers / \(required)).") }
        }
        let projection = Self.columns.map { available.contains($0) ? "\"\($0)\"" : "NULL AS \"\($0)\"" }.joined(separator: ",")
        let devices = try query("SELECT \(projection) FROM tblIDNumbers")
        let customerColumns = Set(try query("PRAGMA table_info(tblCustomer)", maximum: 1000).compactMap { $0["name"] as? String })
        var customers = [[String: Any]]()
        if customerColumns.contains("CustomerNumber") {
            let name = customerColumns.contains("Name") ? "\"Name\"" : "NULL AS \"Name\""
            customers = try query("SELECT \"CustomerNumber\", \(name) FROM tblCustomer")
        }
        return ["devices": devices, "customers": customers]
    }
}

/// Shared validation is also exercised by the standalone native tests.
enum DatabasePath {
    static func normalize(_ value: String) throws -> String {
        let path = value.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "/")
        guard !path.isEmpty, !path.hasPrefix("/"), !path.contains(":"), !path.contains("\0"), path.count <= 500 else { throw ViewerReadError.invalid("Bitte einen Dateinamen oder relativen Pfad im gewählten Ordner eingeben.") }
        guard !path.components(separatedBy: "/").contains(where: { $0.isEmpty || $0 == "." || $0 == ".." }) else { throw ViewerReadError.invalid("Der Datenbankpfad enthält einen ungültigen Ordnerabschnitt.") }
        return path
    }
}
