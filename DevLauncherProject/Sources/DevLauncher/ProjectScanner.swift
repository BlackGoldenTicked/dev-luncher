import Foundation

class ProjectScanner {

    // Folders to ignore during recursive scan
    static let ignoredFolders: Set<String> = [
        ".git", "node_modules", ".build", "build", "dist", ".idea", ".vscode",
        "DerivedData", "Pods", "Carthage", "venv", ".venv", "__pycache__"
    ]

    /// Recursively scans for projects within configured paths.
    /// - Returns: An array of found projects.
    static func scan() -> [Project] {
        
        let config = SettingsManager.shared.config
        // Sort by path length descending to ensure nested/deeper paths are processed first
        // This prevents a parent path scan from blocking a more specific child path scan
        let pathConfigs = config.pathConfigs.sorted { $0.path.count > $1.path.count }

        var results: [Project] = []
        let fm = FileManager.default
        var processedPaths = Set<String>()

        for pathConfig in pathConfigs {

            let path = NSString(string: pathConfig.path).expandingTildeInPath
            
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue, !processedPaths.contains(path) else {
                continue
            }
            
            scanDirectory(at: URL(fileURLWithPath: path), depth: 0, maxDepth: pathConfig.maxDepth, results: &results, processedPaths: &processedPaths, rootPath: path)
        }
        
        // Sort results by modification date descending (newest first)
        results.sort { $0.modificationDate > $1.modificationDate }

        return results
    }
    
    private static func scanDirectory(at url: URL, depth: Int, maxDepth: Int, results: inout [Project], processedPaths: inout Set<String>, rootPath: String) {
        if depth > maxDepth { return }
        
        let fm = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey, .isSymbolicLinkKey, .contentModificationDateKey]
        
        // Remove .skipsHiddenFiles to ensure we see all folders, but manually filter them
        guard let items = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: resourceKeys, options: []) else {
            return
        }
        
        for item in items {
            let name = item.lastPathComponent
            
            // Skip ignored folders
            if ignoredFolders.contains(name) { continue }
            
            // Skip hidden folders (start with dot) unless they are "." or ".."
            if name.hasPrefix(".") { continue }
            
            var isDirectory: AnyObject?
            try? (item as NSURL).getResourceValue(&isDirectory, forKey: .isDirectoryKey)
            
            var isSymbolicLink: AnyObject?
            try? (item as NSURL).getResourceValue(&isSymbolicLink, forKey: .isSymbolicLinkKey)
            
            var modificationDate: AnyObject?
            try? (item as NSURL).getResourceValue(&modificationDate, forKey: .contentModificationDateKey)
            
            var effectiveIsDirectory = false
            
            if let isDir = isDirectory as? Bool, isDir {
                effectiveIsDirectory = true
            } else if let isSym = isSymbolicLink as? Bool, isSym {
                // Check if symlink points to a directory
                var targetIsDir: ObjCBool = false
                if fm.fileExists(atPath: item.path, isDirectory: &targetIsDir) && targetIsDir.boolValue {
                    effectiveIsDirectory = true
                }
            }
            
            if effectiveIsDirectory {
                
                let projectPath = item.path
                let modDate = (modificationDate as? Date) ?? Date.distantPast
                
                // Determine if this project is a "root-level" project (direct child of a configured path)
                // depth 0 in scanDirectory means we are scanning the *content* of the root path.
                // So items found at depth 0 ARE the direct children (1st level).
                let isRootLevel = (depth == 0)

                if !processedPaths.contains(projectPath) {
                    var project = Project(name: name, path: projectPath, modificationDate: modDate)
                    project.isRootLevel = isRootLevel
                    results.append(project)
                    processedPaths.insert(projectPath)
                    
                    scanDirectory(at: item, depth: depth + 1, maxDepth: maxDepth, results: &results, processedPaths: &processedPaths, rootPath: rootPath)
                }
            }
        }
    }
}
