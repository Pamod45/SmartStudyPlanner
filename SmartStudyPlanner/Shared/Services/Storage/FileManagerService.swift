import Foundation

class FileManagerService {
    static let shared = FileManagerService()
    
    private init() {}
    
    private var notesDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let notesPath = documentsPath.appendingPathComponent("Notes", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: notesPath.path) {
            try? FileManager.default.createDirectory(at: notesPath, withIntermediateDirectories: true, attributes: nil)
        }
        
        return notesPath
    }
    
    func saveNoteFile(content: String, fileName: String? = nil) throws -> String {
        let finalFileName = fileName ?? "\(UUID().uuidString).txt"
        let fileURL = notesDirectory.appendingPathComponent(finalFileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return "Notes/\(finalFileName)"
    }
    
    func readNoteFile(relativePath: String) throws -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(relativePath)
        
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
    
    func deleteNoteFile(relativePath: String) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(relativePath)
        
        try FileManager.default.removeItem(at: fileURL)
    }
    
    func updateNoteFile(relativePath: String, content: String) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(relativePath)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func fileExists(relativePath: String) -> Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(relativePath)
        
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    func getFileURL(relativePath: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(relativePath)
    }
}

