import Foundation
import AppKit

struct ToolStatus: Identifiable, Hashable {
    let tool: DevTool
    let isInstalled: Bool
    
    var id: UUID { tool.id }
}

class ToolManager: ObservableObject {
    static let shared = ToolManager()
    @Published var tools: [DevTool] = []
    
    @Published var allToolsStatus: [ToolStatus] = []
    @Published var selectedToolId: UUID?
    
    init() {
        refreshTools()
    }
    
    // Helper to get icon name for a tool (used for image loading)
    // Format: "icon_{toolName}_{state}" where state is "color" or "black"
    func getIconName(for tool: DevTool, installed: Bool) -> String {
        let safeName = tool.name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ".", with: "")
        let state = installed ? "color" : "black"
        return "icon_\(safeName)_\(state)"
    }
    
    func refreshTools() {
        var availableTools: [DevTool] = []
        var statusList: [ToolStatus] = []
        
        // Define all supported tools (Sorted as requested)
        let allTools = [
            // 1. Trae
            DevTool(name: "Trae", type: .app(bundleId: "com.trae.app"), iconName: "t.square"),
            // 2. Cursor
            DevTool(name: "Cursor", type: .app(bundleId: "com.todesktop.230313mzl4w4u92"), iconName: "arrow.up.right.square"),
            // 3. IDEA
            DevTool(name: "IntelliJ IDEA", type: .app(bundleId: "com.jetbrains.intellij"), iconName: "terminal"),
            // 4. Kiro
            DevTool(name: "Kiro", type: .app(bundleId: "dev.kiro.desktop"), iconName: "k.square"), // Assuming icon exists or fallback to system
            // 5. Xcode
            DevTool(name: "Xcode", type: .app(bundleId: "com.apple.dt.Xcode"), iconName: "hammer")
        ]
        
        // Check installation status for all tools
        for tool in allTools {
            let installed = isInstalled(tool)
            statusList.append(ToolStatus(tool: tool, isInstalled: installed))
            
            if installed {
                availableTools.append(tool)
            }
        }
        
        DispatchQueue.main.async {
            self.tools = availableTools
            self.allToolsStatus = statusList
            // Select first by default if not already selected
            if self.selectedToolId == nil {
                self.selectedToolId = availableTools.first?.id
            }
        }
    }
    
    private func isInstalled(_ tool: DevTool) -> Bool {
        switch tool.type {
        case .app(let bundleId):
            guard let bundleId = bundleId else { return false }
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) != nil
            
        case .cli(let command):
            // Check if command exists in path
            // Extract the actual command name (e.g. "code" from "code .")
            let cmdName = command.split(separator: " ").first.map(String.init) ?? command
            return commandExists(cmdName)
        }
    }
    
    private func commandExists(_ command: String) -> Bool {
        // First check standard system paths
        // Expanded to include common locations for dev tools
        let standardPaths = [
            "/usr/bin", "/bin", "/usr/sbin", "/sbin",
            "/usr/local/bin",
            "/opt/homebrew/bin", // Homebrew on Apple Silicon
            "/opt/local/bin", // MacPorts
            NSHomeDirectory() + "/.cargo/bin", // Rust/Cargo
            NSHomeDirectory() + "/go/bin" // Go
        ]
        
        let fm = FileManager.default
        
        for path in standardPaths {
            let fullPath = (path as NSString).appendingPathComponent(command)
            if fm.fileExists(atPath: fullPath) && fm.isExecutableFile(atPath: fullPath) {
                return true
            }
        }
        
        // Fallback to `which` command (might pick up user shell config if we were running in a shell, but Process runs in a restricted env)
        let process = Process()
        process.launchPath = "/usr/bin/which"
        process.arguments = [command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    func getSelectedTool() -> DevTool? {
        return tools.first { $0.id == selectedToolId }
    }
}
