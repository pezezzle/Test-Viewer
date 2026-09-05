import Foundation

let args = CommandLine.arguments
if args.count > 1 {
    do {
        let reader = try DeviceDatabase(path: args[1])
        let payload = try reader.read()
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        FileHandle.standardOutput.write(data)
    } catch {
        FileHandle.standardError.write(Data(error.localizedDescription.utf8))
        exit(2)
    }
} else {
    let valid = ["pcdrdata.sqlite3", "Prüfungen/pcdrdata.sqlite3", " Ordner\\db.sqlite "]
    let expected = ["pcdrdata.sqlite3", "Prüfungen/pcdrdata.sqlite3", "Ordner/db.sqlite"]
    for (index, path) in valid.enumerated() { precondition(try! DatabasePath.normalize(path) == expected[index]) }
    let invalid = ["", "/db.sqlite", "../db", "x/../db", "x/./db", "x//db", "x/", "C:\\db", "x\0db", String(repeating: "a", count: 501)]
    for path in invalid {
        do { _ = try DatabasePath.normalize(path); fatalError("Path unexpectedly accepted") } catch { }
    }
    print("13 Swift path validation cases passed")
}
