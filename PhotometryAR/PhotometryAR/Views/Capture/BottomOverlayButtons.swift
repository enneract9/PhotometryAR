import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "BottomOverlayButtons")

struct BottomOverlayButtons: View, OverlayButtons {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    @Binding var hasDetectionFailed: Bool
    @Binding var showCaptureModeGuidance: Bool
    @Binding var showTutorialView: Bool

    var body: some View {
        HStack(alignment: .center) {
            HStack {
                switch session.state {
                    case .ready:
                        HelpButton()
                            .frame(width: 30)
                    case .detecting:
                        ResetBoundingBoxButton(session: session)
                    default:
                        NumOfImagesButton(session: session)
                        Spacer()
                }
            }
            .frame(maxWidth: .infinity)

            if !isCapturingStarted(state: session.state) {
                CaptureButton(session: session,
                              hasDetectionFailed: $hasDetectionFailed,
                              showTutorialView: $showTutorialView)
                    .frame(width: 200)
            }

            HStack {
                switch session.state {
                    case .ready:
                    if appModel.orbit == .orbit1 {
                        CaptureModeButton(session: session,
                                          showCaptureModeGuidance: $showCaptureModeGuidance)
                            .frame(width: 30)
                    }
                    case .detecting:
                        AutoDetectionStateView(session: session)
                    default:
                        HStack {
                            Spacer()
                            AutoCaptureToggle(session: session)
                            ManualShotButton(session: session)
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .transition(.opacity)
    }
}

@MainActor
private struct CaptureButton: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    @Binding var hasDetectionFailed: Bool
    @Binding var showTutorialView: Bool

    var body: some View {
        Button(
            action: {
                performAction()
            },
            label: {
                Text(buttonLabel)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                    .background(.blue)
                    .clipShape(Capsule())
            })
    }

    private var buttonLabel: String {
        if session.state == .ready {
            switch appModel.captureMode {
                case .object:
                    return "Продолжить"
                case .area:
                    return "Сканировать"
            }
        } else {
            if !appModel.isObjectFlipped {
                return "Сканировать"
            } else {
                return "Продолжить"
            }
        }
    }

    private func performAction() {
        if session.state == .ready {
            switch appModel.captureMode {
            case .object:
                hasDetectionFailed = !(session.startDetecting())
            case .area:
                session.startCapturing()
            }
        } else if case .detecting = session.state {
            session.startCapturing()
        }
    }
}

private struct AutoDetectionStateView: View {
    var session: ObjectCaptureSession

    var body: some View {
        VStack(spacing: 6) {
            let imageName = session.feedback.contains(.objectNotDetected) ? "eye.slash.circle" : "eye.circle"
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(5)
                .frame(width: 30)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let text = session.feedback.contains(.objectNotDetected) ? "Не найден" : "Найден"
                Text(text)
                    .frame(width: 90)
                    .font(.footnote)
                    .opacity(0.7)
                    .fontWeight(.semibold)
            }
        }
        .foregroundColor(.white)
        .fontWeight(.semibold)
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 0 : 15)
    }
}

private struct ResetBoundingBoxButton: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession

    var body: some View {
        Button(
            action: {
                session.resetDetection()
            },
            label: {
                VStack(spacing: 6) {
                    Image("ResetBbox")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)

                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text("Сбросить рамки")
                            .font(.footnote)
                            .opacity(0.7)
                    }
                }
                .foregroundColor(.white)
                .fontWeight(.semibold)
            })
        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 0 : 15)
    }
}

private struct ManualShotButton: View {
    var session: ObjectCaptureSession

    var body: some View {
        Button(
            action: {
                session.requestImageCapture()
            },
            label: {
                Text(Image(systemName: "button.programmable"))
                    .font(.largeTitle)
                    .foregroundColor(session.canRequestImageCapture ? .white : .gray)
            }
        )
        .disabled(!session.canRequestImageCapture)
    }
}

private struct HelpButton: View {
    @Environment(AppDataModel.self) var appModel
    @State private var showHelpPageView: Bool = false

    var body: some View {
        Button(action: {
            logger.log("Нажата кнопка документации сканера")
            withAnimation {
                showHelpPageView = true
            }
        }, label: {
            Image(systemName: "questionmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22)
                .foregroundColor(.white)
                .padding(20)
                .contentShape(.rect)
        })
        .padding(-20)
        .sheet(isPresented: $showHelpPageView) {
            HelpPageView(showHelpPageView: $showHelpPageView)
                .padding()
        }
        .onChange(of: showHelpPageView) {
            appModel.setShowOverlaySheets(to: showHelpPageView)
        }
    }
}

private struct CaptureModeButton: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    @Binding var showCaptureModeGuidance: Bool
    @State private var captureModeGuidanceTimer: Timer? = nil

    var body: some View {
        Button(action: {
            switch appModel.captureMode {
                case .object:
                    DispatchQueue.main.async {
                        logger.log("Выбран режим сканирования по площади")
                        appModel.captureMode = .area
                    }
                case .area:
                    DispatchQueue.main.async {
                        logger.log("Выбран режим сканирования отдельного объекта")
                        appModel.captureMode = .object
                    }
            }
            logger.log("Отображение подсказки текущего режима рабоыт сканера")
            withAnimation {
                showCaptureModeGuidance = true
            }
            // Cancel the previous scheduled timer.
            if captureModeGuidanceTimer != nil {
                captureModeGuidanceTimer?.invalidate()
                captureModeGuidanceTimer = nil
            }
            captureModeGuidanceTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) {_ in
                logger.log("Скрытие подсказки текущего режима работы сканера")
                withAnimation {
                    showCaptureModeGuidance = false
                }
            }
        }, label: {
            VStack {
                switch appModel.captureMode {
                    case .area:
                        Image(systemName: "circle.dashed")
                            .resizable()
                    case .object:
                        Image(systemName: "cube")
                            .resizable()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 22)
            .foregroundStyle(.white)
            .padding(20)
            .contentShape(.rect)
        })
        .padding(-20)
    }
}

private struct NumOfImagesButton: View {
    var session: ObjectCaptureSession

    @State private var showInfo: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            showInfo = true
        },
               label: {
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .padding([.horizontal, .top], 4)
                    .overlay(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
                        if session.feedback.contains(.overCapturing) {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.orange)
                                .font(.caption2)
                        }
                    }
                Text(String(format: "%d/%d",
                            session.numberOfShotsTaken,
                            session.maximumNumberOfInputImages))
                .font(.footnote)
                .fontWidth(.condensed)
                .fontDesign(.rounded)
                .bold()
            }
            .foregroundColor(.white)
        })
        .popover(isPresented: $showInfo) {
            VStack(alignment: .leading, spacing: 20) {
                Label("Максимальное количество фотографий", systemImage: "photo")
                    .font(.headline)
                Text(String(format: "Чтобы создать модель объекта вам нужно минимум %d фотографий, максимальное количество - %d фотографий.",
                            AppDataModel.minNumImages,
                            session.maximumNumberOfInputImages))
            }
            .foregroundStyle(colorScheme == .light ? .black : .white)
            .padding()
            .frame(idealWidth: UIDevice.current.userInterfaceIdiom == .pad ? 300 : .infinity)
            .presentationDetents([.fraction(0.3)])
        }
    }
}

private struct AutoCaptureToggle: View {
    var session: ObjectCaptureSession

    var body: some View {
        Button(action: {
            session.isAutoCaptureEnabled.toggle()
        }, label: {
            HStack(spacing: 5) {
                if session.isAutoCaptureEnabled {
                    Image(systemName: "a.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15)
                        .foregroundStyle(.black)
                } else {
                    Image(systemName: "circle.slash.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15)
                        .foregroundStyle(.black)
                }
                Text("Auto")
                    .font(.footnote)
                    .foregroundStyle(.black)
            }
            .padding(.all, 5)
            .background(.ultraThinMaterial)
            .background(session.isAutoCaptureEnabled ? .white : .clear)
            .cornerRadius(15)
        })
    }
}
