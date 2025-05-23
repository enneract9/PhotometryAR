import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                            category: "FeedbackView")

struct FeedbackView: View {
    var messageList: TimedMessageList

    var body: some View {
        VStack {
            if let activeMessage = messageList.activeMessage {
                Text("\(activeMessage.message)")
                    .padding(.top, 32)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .environment(\.colorScheme, .dark)
                    .transition(.opacity)
            }
        }
    }
}
