import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "TopOverlayButtons")

struct TopOverlayButtons: View, OverlayButtons {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    var showCaptureModeGuidance: Bool

    var body: some View {
        VStack {
            HStack {
                if isCapturingStarted(state: session.state) {
                    CaptureCancelButton()
                    Spacer()
                    NextButton(session: session)
                }
            }
            .foregroundColor(.white)
            Spacer().frame(height: 26)
            if session.state == .ready, showCaptureModeGuidance {
                CaptureModeGuidanceView()
            }
        }
    }
}

private struct CaptureCancelButton: View {
    @Environment(AppDataModel.self) var appModel

    var body: some View {
        Button(action: {
            logger.log("Нажата кнопка Отмена")
            appModel.objectCaptureSession?.cancel()
            appModel.removeCaptureFolder()
        }, label: {
            Text("Отмена")
                .modifier(VisualEffectRoundedCorner())
        })
    }
}

private struct NextButton: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    @State private var showOnboardingView: Bool = false

    var body: some View {
        Button(action: {
            logger.log("Нажата кнопка Дальше")
            showOnboardingView = true
        },
               label: {
            Text(appModel.captureMode == .object ? "Дальше" : "Готово")
                .modifier(VisualEffectRoundedCorner())
        })
        .sheet(isPresented: $showOnboardingView) {
            if let onboardingState = appModel.determineCurrentOnboardingState() {
                OnboardingView(state: onboardingState,
                               showOnboardingView: $showOnboardingView)
                .interactiveDismissDisabled()
            }
        }
        .onChange(of: showOnboardingView) {
            appModel.setShowOverlaySheets(to: showOnboardingView)
        }
        .task {
            for await userCompletedScanPass in session.userCompletedScanPassUpdates where userCompletedScanPass {
                logger.log("Пройден цикл сканирования")
                showOnboardingView = true
            }
        }
    }
}

private struct CaptureModeGuidanceView: View {
    @Environment(AppDataModel.self) var appModel

    var body: some View {
        Text(guidanceText)
            .font(.subheadline)
            .bold()
            .padding(.all, 6)
            .foregroundColor(.white)
            .background(.blue)
            .cornerRadius(5)
    }

    private var guidanceText: String {
        switch appModel.captureMode {
            case .object:
                return "Режим Объекта"
            case .area:
                return "Режим Площади"
        }
    }
}

private struct VisualEffectRoundedCorner: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16.0)
            .font(.subheadline)
            .bold()
            .foregroundColor(.white)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .cornerRadius(15)
            .multilineTextAlignment(.center)
    }
}
