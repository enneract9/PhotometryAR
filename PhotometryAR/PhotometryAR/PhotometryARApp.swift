import SwiftUI

@main
struct PhotometryARApp: App {
    static let subsystem: String = "vargunin-photometry"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppDataModel.instance)
                .environment(DefaultModelStorage())
        }
    }
}
