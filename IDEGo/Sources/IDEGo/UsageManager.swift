import Foundation

struct ProjectUsage: Codable {
    var path: String
    var count: Int
    var lastOpened: Date
}

class UsageManager: ObservableObject {
    static let shared = UsageManager()
    
    @Published var usages: [String: ProjectUsage] = [:]
    
    private let storageKey = "IDEGoUsage"
    
    init() {
        load()
    }
    
    func recordOpen(project: Project) {
        if var usage = usages[project.path] {
            usage.count += 1
            usage.lastOpened = Date()
            usages[project.path] = usage
        } else {
            usages[project.path] = ProjectUsage(path: project.path, count: 1, lastOpened: Date())
        }
        save()
    }
    
    func getTopProjects(limit: Int) -> [Project] {
        let sortedUsages = usages.values.sorted {
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            return $0.lastOpened > $1.lastOpened
        }
        
        return sortedUsages.prefix(limit).map { usage in
            let url = URL(fileURLWithPath: usage.path)
            return Project(name: url.lastPathComponent, path: usage.path)
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(usages) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: ProjectUsage].self, from: data) {
            self.usages = decoded
        }
    }
}
