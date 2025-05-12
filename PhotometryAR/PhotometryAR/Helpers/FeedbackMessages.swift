import RealityKit
import SwiftUI

final class FeedbackMessages {
    static func getFeedbackString(for feedback: ObjectCaptureSession.Feedback, captureMode: AppDataModel.CaptureMode) -> String? {
           switch feedback {
               case .objectTooFar:
                   if captureMode == .area { return nil }
                   return "Приблизьтесь"
               case .objectTooClose:
                   if captureMode == .area { return nil }
                   return "Отдалитесь"
               case .environmentTooDark:
                   return "Нужно больше света"
               case .environmentLowLight:
                   return "Рекомендуется увеличить количество света"
               case .movingTooFast:
                   return "Двигайтесь медленнее"
               case .outOfFieldOfView:
                   return "Нацельтесь на ваш объект"
               default: return nil
           }
    }
}

