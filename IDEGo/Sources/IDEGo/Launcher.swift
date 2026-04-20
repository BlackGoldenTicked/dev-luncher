import AppKit

class Launcher {

    /// 使用指定的工具打开项目
    /// - Parameters:
    ///   - project: 要打开的项目
    ///   - tool: 用于打开项目的工具
    static func open(project: Project, with tool: DevTool) {

        // Record usage
        UsageManager.shared.recordOpen(project: project)

        switch tool.type {
        case .app(let bundleId):
            openWithApp(project: project, bundleId: bundleId)
        case .cli(let command):
            openWithTerminal(project: project, command: command)
        }
    }
    
    private static func openWithApp(project: Project, bundleId: String?) {
        let projectURL = URL(fileURLWithPath: project.path)
        
        // If bundleId is provided, try to find the app
        if let bundleId = bundleId,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            
            NSWorkspace.shared.open(
                [projectURL],
                withApplicationAt: appURL,
                configuration: NSWorkspace.OpenConfiguration()
            )
        } else {
            // Fallback: Open with default file association
            NSWorkspace.shared.open(projectURL)
        }
    }
    
    private static func openWithTerminal(project: Project, command: String) {
        let escapedPath = project.path
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let escapedCommand = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Terminal"
            activate
            do script "cd \"\(escapedPath)\" && \(escapedCommand)"
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }
}
