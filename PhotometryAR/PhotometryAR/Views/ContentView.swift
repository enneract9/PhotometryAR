import SwiftUI
import os

struct ContentView: View {
    @Environment(AppDataModel.self) var appDataModel
    @State private var selectedTab: Tab = .camera

    var body: some View {
        TabView(selection: $selectedTab) {
            PrimaryView()
                .tag(Tab.camera)
                .onAppear(perform: {
                    UIApplication.shared.isIdleTimerDisabled = true
                })
                .onDisappear(perform: {
                    UIApplication.shared.isIdleTimerDisabled = false
                })
            
            StorageView()
                .tag(Tab.ar)
        }
        .overlay(alignment: .bottom) {
            if let captureState = appDataModel.objectCaptureSession?.state,
               captureState == .ready || captureState == .completed {
                TabBar(selectedTab: $selectedTab)
            }
        }
    }
}
