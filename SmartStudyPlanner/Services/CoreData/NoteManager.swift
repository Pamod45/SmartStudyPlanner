
import Foundation

class NoteManager {
    static let shared = NoteManager()
    
    private init() {}
    
    func createNoteForSubject(subject: Subject, noteContent: String, fileName: String? = nil) async throws -> String {
        let filePath = try FileManagerService.shared.saveNoteFile(content: noteContent, fileName: fileName)
        
        try await SubjectService.shared.addNoteFilePath(to: subject, filePath: filePath)
        
        return filePath
    }
    
    func readNote(filePath: String) throws -> String {
        return try FileManagerService.shared.readNoteFile(relativePath: filePath)
    }
    
    func updateNote(filePath: String, content: String) throws {
        try FileManagerService.shared.updateNoteFile(relativePath: filePath, content: content)
    }
    
    func deleteNoteFromSubject(subject: Subject, filePath: String) async throws {
        try FileManagerService.shared.deleteNoteFile(relativePath: filePath)
        
        try await SubjectService.shared.removeNoteFilePath(from: subject, filePath: filePath)
    }
    
    func getAllNotesForSubject(subject: Subject) -> [(path: String, content: String)] {
        return subject.noteFilePaths.compactMap { path in
            guard let content = try? FileManagerService.shared.readNoteFile(relativePath: path) else {
                return nil
            }
            return (path, content)
        }
    }
    
    func getNoteFileName(from path: String) -> String {
        return (path as NSString).lastPathComponent
    }
}
