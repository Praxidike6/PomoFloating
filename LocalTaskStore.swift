import Foundation
import Combine

// MARK: - Task Model
struct LocalTaskItem: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var status: String                     // "Not Started", "In Progress", "Done"
    var totalFocusSeconds: Int
}

// MARK: - Reactive Store
class LocalTaskManager: ObservableObject {
    @Published var tasks: [LocalTaskItem] = []
    
    private let storageKey = "saved_local_tasks"
    
    init() {
        loadTasks()
        
        if tasks.isEmpty {
            tasks = [
                LocalTaskItem(title: "Sample Task", status: "Not Started", totalFocusSeconds: 0)
            ]
            saveTasks()
        }
    }
    
    // MARK: - Actions
    
    func addTask(title: String) {
        let newTask = LocalTaskItem(title: title, status: "Not Started", totalFocusSeconds: 0)
        tasks.append(newTask)
        saveTasks()
    }
    
    func updateStatus(id: String, status: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].status = status
            saveTasks()
        }
    }
    
    func logTime(id: String, seconds: Int) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].totalFocusSeconds += seconds
            saveTasks()
        }
    }
    
    // MARK: - Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([LocalTaskItem].self, from: data) {
            tasks = decoded
        }
    }
}
