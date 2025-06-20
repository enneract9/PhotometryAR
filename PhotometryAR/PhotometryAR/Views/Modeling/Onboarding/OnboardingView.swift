import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: PhotometryARApp.subsystem, category: "OnboardingView")

/// Онбординг
/// Показывает текущее состояние процесса сканирования после завершения этапа сканирования
/// Содержит кнопку онбординга (соответсвующее состоянию действие)
struct OnboardingView: View {
    @Environment(AppDataModel.self) var appModel
    private var stateMachine: OnboardingStateMachine
    @Binding private var showOnboardingView: Bool
    @Environment(\.colorScheme) private var colorScheme

    init(state: OnboardingState, showOnboardingView: Binding<Bool>) {
        stateMachine = OnboardingStateMachine(state)
        _showOnboardingView = showOnboardingView
    }

    var body: some View {
        GeometryReader { geometryReader in
            ZStack {
                Color(colorScheme == .light ? .white : .black).ignoresSafeArea()
                if let session = appModel.objectCaptureSession {
                    OnboardingTutorialView(session: session, onboardingStateMachine: stateMachine,
                                           viewSize: geometryReader.size)
                    OnboardingButtonView(session: session,
                                         onboardingStateMachine: stateMachine,
                                         showOnboardingView: $showOnboardingView)
                }
            }
            .allowsHitTesting(!isFinishingOrCompleted)
        }
    }

    private var isFinishingOrCompleted: Bool {
        guard let session = appModel.objectCaptureSession else { return true }
        return session.state == .finishing || session.state == .completed
    }
}

