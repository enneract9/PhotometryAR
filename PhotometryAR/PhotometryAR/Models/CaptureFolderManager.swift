import Foundation
import os

private let logger = Logger(subsystem: PhotometryARApp.subsystem,
                            category: "CaptureFolderManager")

/// Менеджер папкок для временных файлов сканирования и реконструкции
@Observable
class CaptureFolderManager {
    enum Error: Swift.Error {
        case notFileUrl
        case creationFailed
        case alreadyExists
        case invalidShotUrl
    }

    let appDocumentsFolder: URL = URL.documentsDirectory

    let captureFolder: URL

    let imagesFolder: URL

    let checkpointFolder: URL

    let modelsFolder: URL

    static let imagesFolderName = "Images/"

    init() throws {
        guard let newFolder = CaptureFolderManager.createNewCaptureDirectory() else {
            throw Error.creationFailed
        }
        captureFolder = newFolder

        imagesFolder = newFolder.appendingPathComponent(Self.imagesFolderName)
        try CaptureFolderManager.createDirectoryRecursively(imagesFolder)

        checkpointFolder = newFolder.appendingPathComponent("Checkpoint/")
        try CaptureFolderManager.createDirectoryRecursively(checkpointFolder)

        modelsFolder = newFolder.appendingPathComponent("Models/")
        try CaptureFolderManager.createDirectoryRecursively(modelsFolder)
    }

    // - MARK: Private interface below
    
    private static func createNewCaptureDirectory() -> URL? {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        let newCaptureDir = URL.documentsDirectory
            .appendingPathComponent(timestamp, isDirectory: true)

        logger.log("Creating capture path: \"\(String(describing: newCaptureDir))\"")
        let capturePath = newCaptureDir.path
        do {
            try FileManager.default.createDirectory(atPath: capturePath,
                                                    withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create capturepath=\"\(capturePath)\" error=\(String(describing: error))")
            return nil
        }
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: capturePath, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            return nil
        }

        return newCaptureDir
    }

    private static func createDirectoryRecursively(_ outputDir: URL) throws {
        guard outputDir.isFileURL else {
            throw CaptureFolderManager.Error.notFileUrl
        }
        let expandedPath = outputDir.path
        var isDirectory: ObjCBool = false

        guard !FileManager.default.fileExists(atPath: outputDir.path, isDirectory: &isDirectory) else {
            logger.error("File already exists at \(expandedPath, privacy: .private)")
            throw CaptureFolderManager.Error.alreadyExists
        }

        logger.log("Creating dir recursively: \"\(expandedPath, privacy: .private)\"")
        try FileManager.default.createDirectory(atPath: expandedPath,
                               withIntermediateDirectories: true)

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDir) && isDir.boolValue else {
            logger.error("Dir \"\(expandedPath, privacy: .private)\" doesn't exist after creation!")
            throw CaptureFolderManager.Error.creationFailed
        }
        logger.log("... success creating dir.")
    }

    private static let imageStringPrefix = "IMG_"
    private static let heicImageExtension = "HEIC"
}
