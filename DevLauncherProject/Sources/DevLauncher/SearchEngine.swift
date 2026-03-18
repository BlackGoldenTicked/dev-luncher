import Fuse

class SearchEngine {

    let fuse = Fuse()

    /// 使用 Fuse 模糊搜索库对项目列表进行搜索
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - projects: 待搜索的项目列表
    /// - Returns: 匹配并排序后的项目列表
    func search(query:String, projects:[Project]) -> [Project] {

        if query.isEmpty { return projects }

        let results = projects.compactMap { project -> (Project,Double)? in

            if let res = fuse.search(query, in: project.name) {
                return (project, res.score)
            }

            return nil
        }

        return results
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }
}
