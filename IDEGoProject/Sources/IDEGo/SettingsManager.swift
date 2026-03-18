import Foundation

struct SearchPathConfig: Codable, Hashable, Identifiable {
    let id: UUID
    var path: String
    var maxDepth: Int

    init(id: UUID = UUID(), path: String, maxDepth: Int) {
        self.id = id
        self.path = path
        self.maxDepth = maxDepth
    }
}

struct ScanConfig: Codable {
    var pathConfigs: [SearchPathConfig]
    
    static let defaultPaths = [
        "~/dev",
        "~/workspace",
        "~/projects"
    ]
    
    static let defaultDepth = 3

    init(pathConfigs: [SearchPathConfig]) {
        self.pathConfigs = pathConfigs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let pathConfigs = try? container.decode([SearchPathConfig].self, forKey: .pathConfigs) {
            self.pathConfigs = pathConfigs
            return
        }

        let legacyPaths = try container.decode([String].self, forKey: .searchPaths)
        let legacyDepth = try container.decode(Int.self, forKey: .maxDepth)
        self.pathConfigs = legacyPaths.map { SearchPathConfig(path: $0, maxDepth: legacyDepth) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pathConfigs, forKey: .pathConfigs)
    }

    enum CodingKeys: String, CodingKey {
        case pathConfigs
        case searchPaths
        case maxDepth
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var config: ScanConfig {
        didSet {
            save()
        }
    }
    
    private let storageKey = "IDEGoConfig"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(ScanConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = ScanConfig(
                pathConfigs: ScanConfig.defaultPaths.map {
                    SearchPathConfig(path: $0, maxDepth: ScanConfig.defaultDepth)
                }
            )
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func addPath(_ path: String) {
        if !config.pathConfigs.contains(where: { $0.path == path }) {
            config.pathConfigs.append(SearchPathConfig(path: path, maxDepth: ScanConfig.defaultDepth))
        }
    }
    
    func removePath(id: UUID) {
        config.pathConfigs.removeAll { $0.id == id }
    }
}
