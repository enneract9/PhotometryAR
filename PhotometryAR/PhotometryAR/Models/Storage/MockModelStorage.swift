import Foundation

extension ModelStorage where Self == MockModelStorage {
    static var mock: MockModelStorage {
        MockModelStorage()
    }
}

@Observable
final class MockModelStorage: ModelStorage {
    var urls: [URL] {
        fileNames.compactMap {
            Bundle.main.url(forResource: $0, withExtension: "usdz")
        }
    }
    
    private var fileNames = [
        "tv_retro",
        "cup_saucer_set",
        "teapot",
        "robot_walk_idle",
        "toy_biplane_idle",
        "wateringcan",
        "chair_swan",
        "flower_tulip",
        "pancakes",
        "toy_car"
    ]
    
    func addModel(url: URL) throws { }
    
    func removeModel(url: URL) throws {
        fileNames.removeAll { fileName in
            let removalFileName = url.deletingPathExtension().lastPathComponent
            return fileName == removalFileName
        }
    }
}
