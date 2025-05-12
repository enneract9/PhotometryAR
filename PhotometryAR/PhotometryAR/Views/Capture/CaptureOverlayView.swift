import AVFoundation
import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "CaptureOverlayView")

struct CaptureOverlayView: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    
    @State private var showCaptureModeGuidance: Bool = false
    @State private var hasDetectionFailed = false
    @State private var showTutorialView = false
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

    var body: some View {
        ZStack {
            VStack(
                spacing: 20
            ) {
                TopOverlayButtons(
                    session: session,
                    showCaptureModeGuidance: showCaptureModeGuidance
                )
                
                Spacer()
                
                BoundingBoxGuidanceView(
                    session: session,
                    hasDetectionFailed: hasDetectionFailed
                )
                
                BottomOverlayButtons(
                    session: session,
                    hasDetectionFailed: $hasDetectionFailed,
                    showCaptureModeGuidance: $showCaptureModeGuidance,
                    showTutorialView: $showTutorialView
                )
            }
            .padding()
            .padding(
                .horizontal,
                15
            )
            .background {
                VStack {
                    Spacer()
                        .frame(
                            height: UIDevice.current.userInterfaceIdiom == .pad ? 65 : 25
                        )
                    
                    FeedbackView(
                        messageList: appModel.messageList
                    )
                    .layoutPriority(
                        1
                    )
                }
            }
            .task {
                for await _ in NotificationCenter.default
                    .notifications(
                        named: UIDevice.orientationDidChangeNotification
                    ) {
                        withAnimation {
                            deviceOrientation = UIDevice.current.orientation
                        }
                    }
            }
        }
        .opacity(shouldShowOverlayView ? 1.0 : 0.0)
    }

    private var shouldShowOverlayView: Bool {
        return (session.cameraTracking == .normal && !session.isPaused)
    }
}

private struct BoundingBoxGuidanceView: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    var hasDetectionFailed: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack {
            if let guidanceText {
                Text(guidanceText)
                    .font(.callout)
                    .bold()
                    .foregroundColor(.white)
                    .transition(.opacity)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 400 : 360)
            }
        }
    }

    private var guidanceText: String? {
        if case .ready = session.state {
            switch appModel.captureMode {
                case .object:
                    if hasDetectionFailed {
                        return "Не получается найти объект."
                    } else {
                        return "Приблизьтесь и наведите точку на центр вашего объекта. Затем нажмите продолжить."
                    }
                case .area:
                    return "Наведите камеру на ваш объект."
                }
        } else if case .detecting = session.state {
            return "Поместите ваш объект целиком в параллелепипед. Потяните за рукоятки для изменения размера."
        } else {
            return nil
        }
    }
}

protocol OverlayButtons {
    func isCapturingStarted(state: ObjectCaptureSession.CaptureState) -> Bool
}

extension OverlayButtons {
    func isCapturingStarted(state: ObjectCaptureSession.CaptureState) -> Bool {
        switch state {
            case .initializing, .ready, .detecting:
                return false
            default:
                return true
        }
    }
}
