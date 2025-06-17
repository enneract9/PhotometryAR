import Foundation
import UniformTypeIdentifiers

protocol ModelStorage: AnyObject {
    var urls: [URL] { get }
    var supportedFileExtensions: [UTType] { get }
    
    func addModel(url: URL) async throws
    func removeModel(url: URL) async throws
}

extension ModelStorage {
    var supportedFileExtensions: [UTType] {
        [.usdz]
    }
}
