import Foundation
import Combine

class NotionService: ObservableObject {
   
    private let notionVersion = "2022-06-28"
    
    @Published var tasks: [TaskItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Safely fetch credentials from environment variables
        private var apiKey: String {
            ProcessInfo.processInfo.environment["NOTION_API_KEY"] ?? ""
        }
        
        private var databaseId: String {
            ProcessInfo.processInfo.environment["NOTION_DATABASE_ID"] ?? ""
        }
    
    /// Fetches tasks from your Notion database with graceful fallback if missing/invalid
    func fetchTasks() {
        print("🔍 1. STARTING NOTION FETCH...")
        
        guard let url = URL(string: "https://api.notion.com/v1/databases/\(databaseId)/query") else {
            print("❌ ERROR: Invalid Database URL format.")
            self.tasks = []
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "page_size": 20
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("📡 2. SENDING NETWORK REQUEST TO NOTION...")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                // Graceful failure: if network errors occur or database is unconfigured/missing (non-200),
                // clear tasks quietly without throwing errors so local fallback kicks in.
                if error != nil || (response as? HTTPURLResponse)?.statusCode != 200 {
                    print("⚠️ Notion table unreachable or invalid. Falling back to local mode.")
                    self.tasks = []
                    return
                }
                
                guard let data = data else {
                    print("❌ 3. NO DATA RETURNED")
                    self.tasks = []
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(NotionQueryResponse.self, from: data)
                    let parsedTasks = decodedResponse.results.compactMap { page -> TaskItem? in
                        let title = page.properties.Name?.title.first?.plainText ?? "Untitled"
                        let status = page.properties.Status?.status?.name ?? page.properties.Status?.select?.name
                        return TaskItem(id: page.id, title: title, status: status)
                    }
                    
                    print("✅ SUCCESS: Decoded \(parsedTasks.count) tasks.")
                    self.tasks = parsedTasks
                } catch {
                    print("⚠️ DECODING ERROR: \(error)")
                    self.tasks = []
                }
            }
        }.resume()
    }
    
    /// Updates a Notion task status to "In Progress" or "Done"
    func updateTaskStatus(pageId: String, status: String) {
        guard let url = URL(string: "https://api.notion.com/v1/pages/\(pageId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "properties": [
                "Status": [
                    "status": [
                        "name": status
                    ]
                ]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }
    
    /// Logs focus time (in minutes) to a Number property named "Time Spent" in Notion
    func logFocusTime(pageId: String, elapsedSeconds: Int) {
        guard let url = URL(string: "https://api.notion.com/v1/pages/\(pageId)") else { return }
        let minutesSpent = Double(elapsedSeconds) / 60.0
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "properties": [
                "Time Spent": [
                    "number": minutesSpent
                ]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }
}
