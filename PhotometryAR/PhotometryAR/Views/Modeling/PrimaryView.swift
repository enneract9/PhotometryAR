import SwiftUI
import os

private let logger = Logger(subsystem: PhotometryARApp.subsystem, category: "PrimaryView")

struct PrimaryView: View {
    @Environment(AppDataModel.self) var appModel

    @State private var showReconstructionView: Bool = false
    @State private var showErrorAlert: Bool = false
    private var showProgressView: Bool {
        appModel.state == .completed || appModel.state == .restart || appModel.state == .ready
    }

    var body: some View {
        VStack {
            if appModel.state == .capturing {
                if let session = appModel.objectCaptureSession {
                    CapturePrimaryView(session: session)
                }
            } else if showProgressView {
                CircularProgressView()
            }
        }
        .toolbarBackground(.hidden, for: .tabBar)
        .onChange(of: appModel.state) { _, newState in
            if newState == .failed {
                showErrorAlert = true
                showReconstructionView = false
            } else {
                showErrorAlert = false
                showReconstructionView = newState == .reconstructing || newState == .viewing
            }
        }
        .sheet(isPresented: $showReconstructionView) {
            ReconstructionView()
                .interactiveDismissDisabled()
        }
        .alert(
            "Ошибка:  " + (appModel.error != nil  ? "\(String(describing: appModel.error!))" : ""),
            isPresented: $showErrorAlert,
            actions: {
                Button("OK") {
                    logger.log("Перезагрузка...")
                    appModel.state = .restart
                }
            },
            message: {}
        )
    }
}

private struct CircularProgressView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .light ? .black : .white))
                Spacer()
            }
            Spacer()
        }
    }
}

