import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "ReconstructionView")

struct ReconstructionView: View {
    @Environment(AppDataModel.self) var appModel
    @Environment(DefaultModelStorage.self) var storage
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var fileName: String = ""
    @State private var completed: Bool = false
    @State private var cancelled: Bool = false
    @State private var progress: Float = 0
    @State private var estimatedRemainingTime: TimeInterval?
    @State private var processingStageDescription: String?
    @State private var pointCloud: PhotogrammetrySession.PointCloud?
    @State private var gotError: Bool = false
    @State private var error: Error?
    @State private var isCancelling: Bool = false

    private var padding: CGFloat {
        horizontalSizeClass == .regular ? 60.0 : 24.0
    }
    private func isReconstructing() -> Bool {
        return !completed && !gotError && !cancelled
    }
    
    private let tempModelPath: URL = {
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: Date())
        return .documentsDirectory.appendingPathComponent("/Temp/model-\(timestamp)", conformingTo: .usdz)
    }()

    var body: some View {
        VStack(spacing: 0) {
            if isReconstructing() {
                HStack {
                    Button(action: {
                        logger.log("Отмена...")
                        isCancelling = true
                        appModel.photogrammetrySession?.cancel()
                    }, label: {
                        Text("Отменить")
                            .font(.headline)
                            .bold()
                            .padding(30)
                            .foregroundColor(.blue)
                    })
                    .padding(.trailing)

                    Spacer()
                }
            }

            Spacer()

            Text("Генерация модели")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()
            
            TextField("Имя модели", text: $fileName, prompt: Text("Имя модели"))
                .font(.title)
                .multilineTextAlignment(.center)
            
            Spacer()

            ProgressBarView(progress: progress,
                            estimatedRemainingTime: estimatedRemainingTime,
                            processingStageDescription: processingStageDescription)
            .padding(padding)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
        .alert(
            "Ошибка:  " + (error != nil  ? "\(String(describing: error!))" : ""),
            isPresented: $gotError,
            actions: {
                Button("OK") {
                    logger.log("Перезагрузка...")
                    appModel.state = .restart
                }
            },
            message: {}
        )
        .task {
            precondition(appModel.state == .reconstructing)
            assert(appModel.photogrammetrySession != nil)
            guard let session = appModel.photogrammetrySession else {
                logger.error("Nil значение photogrammetrySession.")
                logger.log("Перезагрузка...")
                appModel.state = .restart
                return
            }

            let outputs = UntilProcessingCompleteFilter(input: session.outputs)
            do {
                try session.process(requests: [.modelFile(url: tempModelPath)])
            } catch {
                logger.error("Генерация моделей не сработала: \(error)")
                logger.log("Перезагрузка...")
                appModel.state = .restart
            }
            for await output in outputs {
                switch output {
                    case .inputComplete:
                        break
                    case .requestProgress(let request, fractionComplete: let fractionComplete):
                        if case .modelFile = request {
                            progress = Float(fractionComplete)
                        }
                    case .requestProgressInfo(let request, let progressInfo):
                        if case .modelFile = request {
                            estimatedRemainingTime = progressInfo.estimatedRemainingTime
                            processingStageDescription = progressInfo.processingStage?.processingStageString
                        }
                    case .requestComplete(let request, _):
                        switch request {
                            case .modelFile(_, _, _):
                                logger.log("Получили .modelFile")
                            case .modelEntity(_, _), .bounds, .poses, .pointCloud:
                                // Not supported yet
                                break
                            @unknown default:
                                logger.warning("Невалидный запрос: \(String(describing: request))")
                        }
                    case .requestError(_, let requestError):
                        if !isCancelling {
                            gotError = true
                            error = requestError
                        }
                    case .processingComplete:
                        if !gotError {
                            do {
                                try storage.addModelUnsafe(url: tempModelPath, newName: fileName)
                            } catch {
                                print("Ошибка при сохранении модели: \(error.localizedDescription)")
                            }
                            completed = true
                            appModel.endCapture()
                        }
                    case .processingCancelled:
                        cancelled = true
                        appModel.state = .restart
                    case .invalidSample(id: _, reason: _), .skippedSample(id: _), .automaticDownsampling:
                        continue
                    case .stitchingIncomplete:
                        logger.log("Проблема с stitching во время генерации модели!")
                    @unknown default:
                        logger.warning("Неизвестный ответ во время генерации модели: \(String(describing: output))")
                    }
            }
            logger.log("Генерация модели завершена")
        } 
    }
}

extension PhotogrammetrySession.Output.ProcessingStage {
    var processingStageString: String? {
        switch self {
            case .preProcessing:
                return "Предобработка изображений…"
            case .imageAlignment:
                return "Выравнивание изображений…"
            case .pointCloudGeneration:
                return "Создание облака точек…"
            case .meshGeneration:
                return "Создание структурной сетки…"
            case .textureMapping:
                return "Обработка текстур…"
            case .optimization:
                return "Оптимизация модели…"
            default:
                return nil
            }
    }
}
