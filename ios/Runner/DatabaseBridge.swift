import Flutter
import UIKit
import UniformTypeIdentifiers

final class DatabaseBridge: NSObject, UIDocumentPickerDelegate {
    private let defaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "com.pezezzle.testmasterviewer.snapshot", qos: .userInitiated)
    private var channel: FlutterMethodChannel?
    private var pickerResult: FlutterResult?

    func register(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.pezezzle.testmasterviewer/data", binaryMessenger: messenger)
        channel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { result(FlutterError(code: "closed", message: "The file integration was closed.", details: nil)); return }
            do {
                switch call.method {
                case "configuration": result(try self.json(self.configuration()))
                case "loadSettings": result(self.defaults.string(forKey: "flutterFilters") ?? "{}")
                case "saveSettings":
                    guard let text = call.arguments as? String, text.utf8.count <= 1024 * 1024, let data = text.data(using: .utf8), (try JSONSerialization.jsonObject(with: data)) is [String: Any] else { throw ViewerReadError.invalid("Invalid settings.") }
                    self.defaults.set(text, forKey: "flutterFilters")
                    result(nil)
                case "chooseFolder": try self.chooseFolder(result)
                case "savePath":
                    guard let path = call.arguments as? String else { throw ViewerReadError.invalid("Enter a file name.") }
                    self.defaults.set(try DatabasePath.normalize(path), forKey: "path")
                    result(try self.json(self.configuration()))
                case "readSnapshot": self.readSnapshot(result)
                default: result(FlutterMethodNotImplemented)
                }
            } catch { self.fail(result, error) }
        }
    }

    private func resolveFolder() throws -> URL {
        guard let bookmark = defaults.data(forKey: "folderBookmark") else { throw ViewerReadError.invalid("Select the database folder first.") }
        var stale = false
        let folder = try URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &stale)
        if stale {
            let access = folder.startAccessingSecurityScopedResource()
            defer { if access { folder.stopAccessingSecurityScopedResource() } }
            let refreshed = try folder.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(refreshed, forKey: "folderBookmark")
        }
        return folder
    }

    private func configuration() -> [String: Any] {
        let folder = try? resolveFolder()
        return ["folder": folder?.path ?? "", "treeUri": folder?.absoluteString ?? "", "configured": folder != nil, "path": defaults.string(forKey: "path") ?? "pcdrdata.sqlite3", "version": "2.0.0"]
    }

    private func presenter() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        var controller = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }

    private func chooseFolder(_ result: @escaping FlutterResult) throws {
        guard pickerResult == nil else { throw ViewerReadError.invalid("The folder picker is already open.") }
        guard let presenter = presenter() else { throw ViewerReadError.invalid("The iOS file picker is not ready yet.") }
        pickerResult = result
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.allowsMultipleSelection = false
        picker.delegate = self
        if let folder = try? resolveFolder() { picker.directoryURL = folder }
        presenter.present(picker, animated: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        pickerResult?(nil)
        pickerResult = nil
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let result = pickerResult else { return }
        pickerResult = nil
        guard let folder = urls.first else { result(nil); return }
        let access = folder.startAccessingSecurityScopedResource()
        defer { if access { folder.stopAccessingSecurityScopedResource() } }
        do {
            let bookmark = try folder.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(bookmark, forKey: "folderBookmark")
            result(try json(configuration()))
        } catch { fail(result, error) }
    }

    private func readSnapshot(_ result: @escaping FlutterResult) {
        let path = defaults.string(forKey: "path") ?? "pcdrdata.sqlite3"
        queue.async { [self] in
            do {
                let folder = try resolveFolder()
                let access = folder.startAccessingSecurityScopedResource()
                defer { if access { folder.stopAccessingSecurityScopedResource() } }
                let snapshot = try SnapshotReader().read(folder: folder, relativePath: path)
                let payload = try json(snapshot)
                DispatchQueue.main.async { result(payload) }
            } catch { DispatchQueue.main.async { self.fail(result, error) } }
        }
    }

    private func json(_ value: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
        guard let result = String(data: data, encoding: .utf8) else { throw ViewerReadError.invalid("The inspection data could not be transferred.") }
        return result
    }
    private func fail(_ result: FlutterResult, _ error: Error) { result(FlutterError(code: "viewer", message: error.localizedDescription, details: nil)) }
}
