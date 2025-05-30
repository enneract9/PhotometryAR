import SwiftUI
import os

private let logger = Logger(subsystem: PhotometryARApp.subsystem,
                            category: "TimedMessageList")

/// FIFO очередь для сообщений пользователю
/// Автоматически обновляет интерфейс приложения
@Observable
class TimedMessageList {
    struct Message: Identifiable {
        let id = UUID()
        let message: String
        let startTime: Date
        fileprivate(set) var endTime: Date?

        init(_ msg: String, startTime inStartTime: Date = Date()) {
            message = msg
            startTime = inStartTime
            endTime = nil
        }

        func hasExpired() -> Bool {
            guard let endTime else {
                return false
            }
            return Date() >= endTime
        }
    }

    var activeMessage: Message? = nil

    private var messages: [Message] = [] {
        didSet {
            dispatchPrecondition(condition: .onQueue(.main))
            let newActiveMsg = !messages.isEmpty ? messages[0] : nil
            if activeMessage?.message != newActiveMsg?.message {
                withAnimation {
                    activeMessage = newActiveMsg
                }
            }
        }
    }

    private var timer: Timer?

    private let feedbackMessageMinimumDurationSecs: Double = 2.0

    init() { }

    func add(_ msg: String) {
        dispatchPrecondition(condition: .onQueue(.main))

        if let index = messages.lastIndex(where: { $0.message == msg }) {
            messages[index].endTime = nil
        } else {
            messages.append(Message(msg))
        }
        setTimer()
    }
    
    func remove(_ msg: String) {
        dispatchPrecondition(condition: .onQueue(.main))

        guard let index = messages.lastIndex(where: { $0.message == msg }) else { return }
        var endTime = Date()
        let earliestAcceptableEndTime = messages[index].startTime + feedbackMessageMinimumDurationSecs
        if endTime < earliestAcceptableEndTime {
            endTime = earliestAcceptableEndTime
        }
        messages[index].endTime = endTime
        setTimer()
    }

    func removeAll() {
        timer?.invalidate()
        timer = nil
        activeMessage = nil
        messages.removeAll()
    }

    private func setTimer() {
        dispatchPrecondition(condition: .onQueue(.main))

        timer?.invalidate()
        timer = nil

        cullExpired()
        if let nearestEndTime = (messages.compactMap { $0.endTime }).min() {
            let duration = nearestEndTime.timeIntervalSinceNow
            timer = Timer.scheduledTimer(timeInterval: duration,
                                         target: self,
                                         selector: #selector(onTimer),
                                         userInfo: nil,
                                         repeats: false)

        }
    }

    private func cullExpired() {
        dispatchPrecondition(condition: .onQueue(.main))

        withAnimation {
            messages.removeAll(where: { $0.hasExpired() })
        }
    }

    @objc
    private func onTimer() {
        dispatchPrecondition(condition: .onQueue(.main))

        timer?.invalidate()
        cullExpired()
        setTimer()
    }
}
