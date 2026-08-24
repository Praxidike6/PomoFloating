import Foundation
import Combine

struct DailyRecord: Identifiable, Codable {
    var id: String { dateString } // YYYY-MM-DD
    let dateString: String
    var totalFocusSeconds: Int
    var completedSessions: Int
}

class FocusHistoryStore: ObservableObject {
    @Published var records: [String: DailyRecord] = [:]
    
    private let storageKey = "saved_focus_history_records"
    
    init() {
        loadRecords()
    }
    
    /// Records completed focus time and session count for today
    func logFocusSession(seconds: Int, isCompletedSession: Bool) {
        let todayString = dateFormatter.string(from: Date())
        
        var record = records[todayString] ?? DailyRecord(dateString: todayString, totalFocusSeconds: 0, completedSessions: 0)
        record.totalFocusSeconds += seconds
        if isCompletedSession {
            record.completedSessions += 1
        }
        
        records[todayString] = record
        saveRecords()
    }
    
    /// Calculates current consecutive daily streak
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        // Check backwards day by day
        for _ in 0..<365 {
            let dateStr = dateFormatter.string(from: checkDate)
            if let record = records[dateStr], record.totalFocusSeconds > 0 {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                // If today has no records yet, don't break the streak from yesterday
                if streak == 0 && dateStr == dateFormatter.string(from: Date()) {
                    guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = previousDay
                    continue
                }
                break
            }
        }
        return streak
    }
    
    /// Total focus minutes for today
    var todayFocusMinutes: Int {
        let todayStr = dateFormatter.string(from: Date())
        return (records[todayStr]?.totalFocusSeconds ?? 0) / 60
    }
    
    /// Sorted list of records for the stats view (most recent first)
    var sortedRecords: [DailyRecord] {
        records.values.sorted { $0.dateString > $1.dateString }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: DailyRecord].self, from: data) {
            records = decoded
        }
    }
}//
//  FocusHistoryStore.swift
//  PomoFloating
//
//  Created by Stuart McDonnell on 16/8/2026.
//

