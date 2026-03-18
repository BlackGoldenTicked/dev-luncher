import Foundation

struct Project: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    var modificationDate: Date = Date()
    var isRootLevel: Bool = false
    
    // Custom Hashable conformance to ignore modificationDate if we want stable hashing
    // or include it if we want changes to trigger updates.
    // For now, let's keep it simple.
    
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

// Deprecated: keeping for compatibility during migration if needed
struct DevApp: Identifiable {
    let id = UUID()
    let name: String
    let path: String
}
