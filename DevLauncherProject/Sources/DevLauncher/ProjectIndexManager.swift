import Foundation
import Combine

final class ProjectIndexManager: ObservableObject {
    static let shared = ProjectIndexManager()

    @Published private(set) var projects: [Project] = []
    @Published private(set) var isScanning: Bool = false

    private let settings = SettingsManager.shared
    private let searchEngine = SearchEngine()
    private let queue = DispatchQueue(label: "devlauncher.project-index", qos: .utility)

    private var timer: DispatchSourceTimer?
    private var settingsCancellable: AnyCancellable?

    private var lastConfigSignature: String = ""
    private var lastRootFingerprint: String = ""
    private var searchCache: [String: [Project]] = [:]
    private var searchCacheOrder: [String] = []
    private let maxSearchCacheEntries = 64

    private init() {
        settingsCancellable = settings.$config
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.refresh(force: true)
            }
    }

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.timer == nil {
                let timer = DispatchSource.makeTimerSource(queue: self.queue)
                timer.schedule(deadline: .now() + .seconds(2), repeating: .seconds(8), leeway: .seconds(2))
                timer.setEventHandler { [weak self] in
                    self?.refresh(force: false)
                }
                self.timer = timer
                timer.resume()
            }
            self.refresh(force: true)
        }
    }

    func forceRefresh() {
        queue.async { [weak self] in
            self?.refresh(force: true)
        }
    }

    func search(query: String) -> [Project] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty { 
            // Default limit 10 items when no query
            // Filter only root-level projects for default view
            let rootProjects = projects.filter { $0.isRootLevel }
            // They are already sorted by date descending in scan()
            return Array(rootProjects.prefix(10))
        }

        if let cached = searchCache[normalized] {
            return cached
        }

        let result = searchEngine.search(query: query, projects: projects)
        // Search limit 15 items
        let limitedResult = Array(result.prefix(15))
        
        cacheSearchResult(limitedResult, for: normalized)
        return limitedResult
    }

    private func refresh(force: Bool) {
        let config = settings.config
        let configSignature = makeConfigSignature(config)
        let rootFingerprint = makeRootFingerprint(config)

        if !force, configSignature == lastConfigSignature, rootFingerprint == lastRootFingerprint {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isScanning = true
        }

        let scanned = ProjectScanner.scan()
        let scannedPaths = scanned.map(\.path).sorted()
        let currentPaths = projects.map(\.path).sorted()

        lastConfigSignature = configSignature
        lastRootFingerprint = rootFingerprint

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isScanning = false
            
            if scannedPaths != currentPaths {
                self.projects = scanned
                self.searchCache.removeAll(keepingCapacity: true)
                self.searchCacheOrder.removeAll(keepingCapacity: true)
            }
        }
    }

    private func makeConfigSignature(_ config: ScanConfig) -> String {
        config.pathConfigs
            .map { "\(($0.path as NSString).expandingTildeInPath)|\($0.maxDepth)" }
            .sorted()
            .joined(separator: "||")
    }

    private func makeRootFingerprint(_ config: ScanConfig) -> String {
        let fm = FileManager.default
        return config.pathConfigs
            .map { item in
                let expanded = (item.path as NSString).expandingTildeInPath
                let attributes = try? fm.attributesOfItem(atPath: expanded)
                let modified = attributes?[.modificationDate] as? Date
                let ts = modified?.timeIntervalSince1970 ?? 0
                return "\(expanded)|\(Int(ts))"
            }
            .sorted()
            .joined(separator: "||")
    }

    private func cacheSearchResult(_ result: [Project], for key: String) {
        if searchCache[key] == nil {
            searchCacheOrder.append(key)
        }
        searchCache[key] = result

        while searchCacheOrder.count > maxSearchCacheEntries {
            let old = searchCacheOrder.removeFirst()
            searchCache.removeValue(forKey: old)
        }
    }
}
