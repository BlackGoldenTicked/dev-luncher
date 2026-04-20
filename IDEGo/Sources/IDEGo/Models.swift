import Foundation

struct Project: Identifiable, Hashable {
    var id: String { path }
    let name: String
    let path: String
    var modificationDate: Date = Date()
    var isRootLevel: Bool = false

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.path == rhs.path
    }
}

enum ToolType: Hashable {
    case app(bundleId: String?) // e.g., "com.microsoft.VSCode"
    case cli(command: String)   // e.g., "code", "cursor", "aider"
}

struct DevTool: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: ToolType
    let iconName: String
    
    // Default system icon
    static let defaultIcon = "terminal"
}

