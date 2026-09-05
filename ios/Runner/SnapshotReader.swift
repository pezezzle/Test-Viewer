import Foundation
import CryptoKit

/// Copies a quiescent source twice and compares hashes. Never opens the source with SQLite.
final class SnapshotReader {
    private let maxBytes = 512 * 1024 * 1024
    private let manager = FileManager.default

    func read(folder: URL, relativePath: String) throws -> [String: Any] {
        let path = try DatabasePath.normalize(relativePath)
        let root = folder.standardizedFileURL.resolvingSymlinksInPath()
        let source = folder.appendingPathComponent(path).standardizedFileURL.resolvingSymlinksInPath()
        guard source.path.hasPrefix(root.path + "/") else { throw ViewerReadError.invalid("The database path is outside the shared folder.") }
        var isDirectory: ObjCBool = false
        guard manager.fileExists(atPath: source.path, isDirectory: &isDirectory), !isDirectory.boolValue else { throw ViewerReadError.invalid("Database not found: \(path). Check the folder and file name.") }
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var outcome: Result<[String: Any], Error>?
        coordinator.coordinate(readingItemAt: source, options: .withoutChanges, error: &coordinationError) { coordinated in
            outcome = Result { try self.makeSnapshot(source: coordinated, label: folder.lastPathComponent + "/" + path, identity: source.absoluteString) }
        }
        if let error = coordinationError { throw error }
        guard let result = outcome else { throw ViewerReadError.invalid("The selected file cannot be read locally.") }
        return try result.get()
    }

    private func makeSnapshot(source: URL, label: String, identity: String) throws -> [String: Any] {
        let copy = manager.temporaryDirectory.appendingPathComponent("testmaster-\(UUID().uuidString).sqlite3")
        defer {
            for suffix in ["", "-wal", "-shm", "-journal"] { try? manager.removeItem(atPath: copy.path + suffix) }
        }
        try assertQuiet(source)
        let first = try hash(source, copyTo: copy)
        try assertQuiet(source)
        let second = try hash(source, copyTo: nil)
        try assertQuiet(source)
        guard first == second else { throw ViewerReadError.invalid("The inspection app changed the database while it was being read. Save the inspection and refresh again.") }
        let headerHandle = try FileHandle(forReadingFrom: copy)
        let header = try headerHandle.read(upToCount: 16) ?? Data()
        try headerHandle.close()
        guard header == Data("SQLite format 3\0".utf8) else { throw ViewerReadError.invalid("The selected file is not an SQLite database.") }
        let database = try DeviceDatabase(path: copy.path)
        var result = try database.read()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        result["sourceLabel"] = label
        result["sourceUri"] = identity
        result["readAt"] = dateFormatter.string(from: Date())
        if let attributes = try? manager.attributesOfItem(atPath: source.path), let modified = attributes[.modificationDate] as? Date { result["sourceModified"] = dateFormatter.string(from: modified) }
        result["warnings"] = [String]()
        result["version"] = "2.0.0"
        return result
    }

    private func assertQuiet(_ source: URL) throws {
        for suffix in ["-wal", "-journal"] {
            let companion = URL(fileURLWithPath: source.path + suffix)
            // Read the parent directory first: an unreadable directory must not be mistaken for no WAL.
            let names = try manager.contentsOfDirectory(atPath: source.deletingLastPathComponent().path)
            if !names.contains(companion.lastPathComponent) { continue }
            let attributes = try manager.attributesOfItem(atPath: companion.path)
            if let size = attributes[.size] as? NSNumber, size.int64Value == 0 { continue }
            if suffix == "-journal" {
                let handle = try FileHandle(forReadingFrom: companion)
                let header = try handle.read(upToCount: 8) ?? Data()
                try handle.close()
                if header.allSatisfy({ $0 == 0 }) { continue }
            }
            throw ViewerReadError.invalid("The inspection software still has an SQLite journal file open (\(suffix)). Save the inspection, fully close the inspection app, and refresh again. Never delete journal files.")
        }
    }

    private func hash(_ source: URL, copyTo target: URL?) throws -> Data {
        let input = try FileHandle(forReadingFrom: source)
        defer { try? input.close() }
        var output: FileHandle?
        if let target = target {
            guard manager.createFile(atPath: target.path, contents: nil, attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]) else { throw ViewerReadError.invalid("The temporary read copy could not be created.") }
            output = try FileHandle(forWritingTo: target)
        }
        defer { try? output?.close() }
        var digest = SHA256()
        var total = 0
        while let data = try input.read(upToCount: 65536), !data.isEmpty {
            total += data.count
            guard total <= maxBytes else { throw ViewerReadError.invalid("The database is larger than 512 MB.") }
            digest.update(data: data)
            try output?.write(contentsOf: data)
        }
        guard total >= 100 else { throw ViewerReadError.invalid("The selected file is not a valid SQLite database.") }
        return Data(digest.finalize())
    }
}
