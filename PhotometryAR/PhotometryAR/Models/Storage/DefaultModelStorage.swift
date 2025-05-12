import Foundation
import UniformTypeIdentifiers

extension ModelStorage where Self == DefaultModelStorage {
    static var `default`: Self {
        DefaultModelStorage()
    }
}

@Observable
final class DefaultModelStorage: ModelStorage {
    enum StorageError: Error {
        case folderCreationError
        case unsupportedFileExtension
        case modelCopyError
        case noAccess
    }
    
    private(set) var urls: [URL] = []
    private let fileManager: FileManager = .default
    private let modelsFolder: URL = .documentsDirectory.appendingPathComponent("Models/")
    
    init() {
        do {
            try createFolderIfNeeded(at: modelsFolder)
            try load()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func addModel(url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw StorageError.noAccess
        }
        guard
            let type = UTType(filenameExtension: url.pathExtension),
            supportedFileExtensions.contains(type)
        else {
            throw StorageError.unsupportedFileExtension
        }
        
        let modelName = url.deletingPathExtension().lastPathComponent
        let newModelURL = newModelUrl(with: modelName)
        
        try fileManager.copyItem(at: url, to: newModelURL)
        
        url.stopAccessingSecurityScopedResource()
        
        guard fileManager.fileExists(atPath: newModelURL.path) else {
            throw StorageError.modelCopyError
        }
        urls.insert(newModelURL, at: 0)
    }
    
    func addModelUnsafe(url: URL, newName: String? = nil) throws {
        guard
            let type = UTType(filenameExtension: url.pathExtension),
            supportedFileExtensions.contains(type)
        else {
            throw StorageError.unsupportedFileExtension
        }
        
        let modelName: String
        if let newName, !newName.isEmpty {
            modelName = newName
        } else {
            modelName = url.deletingPathExtension().lastPathComponent
        }
        let newModelURL = newModelUrl(with: modelName)
        
        try fileManager.copyItem(at: url, to: newModelURL)
        
        guard fileManager.fileExists(atPath: newModelURL.path) else {
            throw StorageError.modelCopyError
        }
        urls.insert(newModelURL, at: 0)
    }
    
    func removeModel(url: URL) throws {
        try fileManager.removeItem(at: url)
        urls.removeAll { $0 == url }
    }
    
    private func newModelUrl(with name: String, _ num: Int? = nil) -> URL {
        var pathDublicateAddition = ""
        if let num {
            pathDublicateAddition = String(num)
        }
        
        var newModelURL = modelsFolder
            .appendingPathComponent(name + pathDublicateAddition).appendingPathExtension("usdz")
        
        if fileManager.fileExists(atPath: newModelURL.path) {
            newModelURL = newModelUrl(with: name, (num ?? 1) + 1)
        }
        
        return newModelURL
    }
    
    private func createFolderIfNeeded(at url: URL) throws {
        var isDirectory: ObjCBool = false
        
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            return
        }
        try fileManager.createDirectory(
            atPath: url.path,
            withIntermediateDirectories: true
        )
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue else {
            throw StorageError.folderCreationError
        }
    }
    
    private func load() throws {
        urls = try fileManager.contentsOfDirectory(
            at: modelsFolder,
            includingPropertiesForKeys: nil
        )
        .filter {
            if let type = UTType(filenameExtension: $0.pathExtension) {
                supportedFileExtensions.contains(type)
            } else {
                false
            }
        }
        .sorted(by: { lhs, rhs in
            let lhsCreationTime = (try? fileManager.attributesOfItem(atPath: lhs.path(percentEncoded: false))[.creationDate] as? Date) ?? Date()
            let rhsCreationTime = (try? fileManager.attributesOfItem(atPath: rhs.path(percentEncoded: false))[.creationDate] as? Date) ?? Date()
            return lhsCreationTime > rhsCreationTime
        })
    }
}
