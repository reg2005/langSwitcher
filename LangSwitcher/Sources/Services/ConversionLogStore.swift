import Foundation
import SQLite3

// MARK: - Conversion Log Store (SQLite)

/// Singleton service that persists conversion logs to a SQLite database.
/// Uses the C SQLite3 API directly — no external dependencies.
@MainActor
final class ConversionLogStore: ObservableObject {
    
    static let shared = ConversionLogStore()
    
    @Published private(set) var logs: [ConversionLog] = []
    
    private var db: OpaquePointer?
    
    // MARK: - Init
    
    private init() {
        openDatabase()
        createTableIfNeeded()
        fetchAll()
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }
    
    // MARK: - Database Path
    
    private static var databasePath: String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("LangSwitcher", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        
        return dir.appendingPathComponent("conversion_log.sqlite").path
    }
    
    // MARK: - Open Database
    
    private func openDatabase() {
        let path = Self.databasePath
        NSLog("[LangSwitcher] ConversionLogStore: opening database at \(path)")
        
        if sqlite3_open(path, &db) != SQLITE_OK {
            let err = db.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            NSLog("[LangSwitcher] ConversionLogStore: failed to open database: \(err)")
            db = nil
        }
    }
    
    // MARK: - Create Table
    
    private func createTableIfNeeded() {
        guard let db = db else { return }
        
        let sql = """
        CREATE TABLE IF NOT EXISTS conversion_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            input_text TEXT NOT NULL,
            output_text TEXT NOT NULL,
            source_layout TEXT NOT NULL,
            target_layout TEXT NOT NULL,
            conversion_mode TEXT NOT NULL,
            is_correct INTEGER
        );
        """
        
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let err = errMsg.map { String(cString: $0) } ?? "unknown"
            NSLog("[LangSwitcher] ConversionLogStore: failed to create table: \(err)")
            sqlite3_free(errMsg)
        } else {
            NSLog("[LangSwitcher] ConversionLogStore: table ready")
        }
    }
    
    // MARK: - Insert
    
    func log(
        inputText: String,
        outputText: String,
        sourceLayout: String,
        targetLayout: String,
        conversionMode: String
    ) {
        guard let db = db else { return }
        
        let sql = """
        INSERT INTO conversion_log (timestamp, input_text, output_text, source_layout, target_layout, conversion_mode, is_correct)
        VALUES (?, ?, ?, ?, ?, ?, NULL);
        """
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            NSLog("[LangSwitcher] ConversionLogStore: failed to prepare INSERT")
            return
        }
        defer { sqlite3_finalize(stmt) }
        
        let timestamp = Date().timeIntervalSince1970
        sqlite3_bind_double(stmt, 1, timestamp)
        sqlite3_bind_text(stmt, 2, (inputText as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (outputText as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 4, (sourceLayout as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 5, (targetLayout as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 6, (conversionMode as NSString).utf8String, -1, nil)
        
        if sqlite3_step(stmt) == SQLITE_DONE {
            NSLog("[LangSwitcher] ConversionLogStore: logged conversion '\(inputText)' -> '\(outputText)'")
            fetchAll() // Refresh published list
        } else {
            NSLog("[LangSwitcher] ConversionLogStore: INSERT failed")
        }
    }
    
    // MARK: - Fetch All
    
    func fetchAll() {
        guard let db = db else { return }
        
        let sql = "SELECT id, timestamp, input_text, output_text, source_layout, target_layout, conversion_mode, is_correct FROM conversion_log ORDER BY timestamp DESC;"
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            NSLog("[LangSwitcher] ConversionLogStore: failed to prepare SELECT")
            return
        }
        defer { sqlite3_finalize(stmt) }
        
        var results: [ConversionLog] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1))
            let inputText = String(cString: sqlite3_column_text(stmt, 2))
            let outputText = String(cString: sqlite3_column_text(stmt, 3))
            let sourceLayout = String(cString: sqlite3_column_text(stmt, 4))
            let targetLayout = String(cString: sqlite3_column_text(stmt, 5))
            let conversionMode = String(cString: sqlite3_column_text(stmt, 6))
            
            let isCorrect: Bool?
            if sqlite3_column_type(stmt, 7) == SQLITE_NULL {
                isCorrect = nil
            } else {
                isCorrect = sqlite3_column_int(stmt, 7) != 0
            }
            
            results.append(ConversionLog(
                id: id,
                timestamp: timestamp,
                inputText: inputText,
                outputText: outputText,
                sourceLayout: sourceLayout,
                targetLayout: targetLayout,
                conversionMode: conversionMode,
                isCorrect: isCorrect
            ))
        }
        
        logs = results
    }
    
    // MARK: - Update Rating
    
    /// Set the is_correct rating for a log entry. Pass nil to clear the rating.
    func updateRating(id: Int64, isCorrect: Bool?) {
        guard let db = db else { return }
        
        let sql = "UPDATE conversion_log SET is_correct = ? WHERE id = ?;"
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            NSLog("[LangSwitcher] ConversionLogStore: failed to prepare UPDATE")
            return
        }
        defer { sqlite3_finalize(stmt) }
        
        if let isCorrect = isCorrect {
            sqlite3_bind_int(stmt, 1, isCorrect ? 1 : 0)
        } else {
            sqlite3_bind_null(stmt, 1)
        }
        sqlite3_bind_int64(stmt, 2, id)
        
        if sqlite3_step(stmt) == SQLITE_DONE {
            // Update in-memory list
            if let idx = logs.firstIndex(where: { $0.id == id }) {
                logs[idx] = ConversionLog(
                    id: logs[idx].id,
                    timestamp: logs[idx].timestamp,
                    inputText: logs[idx].inputText,
                    outputText: logs[idx].outputText,
                    sourceLayout: logs[idx].sourceLayout,
                    targetLayout: logs[idx].targetLayout,
                    conversionMode: logs[idx].conversionMode,
                    isCorrect: isCorrect
                )
            }
        }
    }
    
    // MARK: - Delete Entry
    
    func delete(id: Int64) {
        guard let db = db else { return }
        
        let sql = "DELETE FROM conversion_log WHERE id = ?;"
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        
        sqlite3_bind_int64(stmt, 1, id)
        
        if sqlite3_step(stmt) == SQLITE_DONE {
            logs.removeAll { $0.id == id }
        }
    }
    
    // MARK: - Clear All
    
    func clearAll() {
        guard let db = db else { return }
        
        let sql = "DELETE FROM conversion_log;"
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) == SQLITE_OK {
            logs.removeAll()
            NSLog("[LangSwitcher] ConversionLogStore: cleared all logs")
        }
        sqlite3_free(errMsg)
    }
    
    // MARK: - Export as JSON
    
    /// Export all logs as a JSON array (for training data export).
    func exportJSON() -> String {
        struct ExportEntry: Codable {
            let id: Int64
            let timestamp: String
            let inputText: String
            let outputText: String
            let sourceLayout: String
            let targetLayout: String
            let conversionMode: String
            let isCorrect: Bool?
        }
        
        let formatter = ISO8601DateFormatter()
        let entries = logs.map { log in
            ExportEntry(
                id: log.id,
                timestamp: formatter.string(from: log.timestamp),
                inputText: log.inputText,
                outputText: log.outputText,
                sourceLayout: log.sourceLayout,
                targetLayout: log.targetLayout,
                conversionMode: log.conversionMode,
                isCorrect: log.isCorrect
            )
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(entries),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "[]"
    }
}
