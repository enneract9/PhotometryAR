import RealityKit
import SwiftUI

struct OnboardingTutorialView: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    var onboardingStateMachine: OnboardingStateMachine
    var viewSize: CGSize

    var body: some View {
        VStack {
            let frameSize = min(viewSize.width, viewSize.height) * (UIDevice.current.userInterfaceIdiom == .pad ? 0.5 : 0.8)
            switch appModel.captureMode {
                case .object:
                    ZStack {
//                        if shouldShowTutorialInReview, let url = tutorialUrl {
//                            TutorialVideoView(url: url, isInReviewSheet: true)
//                        } else {
                            VStack {
                                Spacer()
                                ObjectCapturePointCloudView(session: session)
                                Spacer()
                            }
//                        }

                        VStack {
                            Spacer()
                            HStack {
                                ForEach(AppDataModel.Orbit.allCases) { orbit in
                                    if let orbitImageName = getOrbitImageName(orbit: orbit) {
                                        Text(Image(systemName: orbitImageName))
                                            .font(.system(size: 28))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: frameSize, height: frameSize)
                case .area:
                    Spacer().frame(height: 50)
                    ObjectCapturePointCloudView(session: session)
                        .frame(width: frameSize, height: frameSize)
                }

            VStack {
                Text(title)
                    .font(.largeTitle)
                    .lineLimit(3)
                    .minimumScaleFactor(0.5)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)

                Text(detailText)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Spacer()

                if appModel.captureMode == .area {
                    Text("Примерное время обработки 2-10 минут.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer().frame(height: 130)
                }
            }
            .foregroundColor(.primary)
            .frame(maxHeight: .infinity)
            .padding([.leading, .trailing], UIDevice.current.userInterfaceIdiom == .pad ? 50 : 30)
        }
    }

//    private var shouldShowTutorialInReview: Bool {
//        switch onboardingStateMachine.currentState {
//            case .flipObject, .flipObjectASecondTime, .captureFromLowerAngle, .captureFromHigherAngle:
//                return true
//            default:
//                return false
//        }
//    }

//    private let onboardingStateToTutorialNameMapOnIphone: [ OnboardingState: String ] = [
//        .flipObject: "ScanPasses-iPhone-FixedHeight-2",
//        .flipObjectASecondTime: "ScanPasses-iPhone-FixedHeight-3",
//        .captureFromLowerAngle: "ScanPasses-iPhone-FixedHeight-unflippable-low",
//        .captureFromHigherAngle: "ScanPasses-iPhone-FixedHeight-unflippable-high"
//    ]
//
//    private let onboardingStateToTutorialNameMapOnIpad: [ OnboardingState: String ] = [
//        .flipObject: "ScanPasses-iPad-FixedHeight-2",
//        .flipObjectASecondTime: "ScanPasses-iPad-FixedHeight-3",
//        .captureFromLowerAngle: "ScanPasses-iPad-FixedHeight-unflippable-low",
//        .captureFromHigherAngle: "ScanPasses-iPad-FixedHeight-unflippable-high"
//    ]
//
//    private var tutorialUrl: URL? {
//        let videoName: String
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            videoName = onboardingStateToTutorialNameMapOnIpad[onboardingStateMachine.currentState] ?? "ScanPasses-iPad-FixedHeight-1"
//        } else {
//            videoName = onboardingStateToTutorialNameMapOnIphone[onboardingStateMachine.currentState] ?? "ScanPasses-iPhone-FixedHeight-1"
//        }
//        return Bundle.main.url(forResource: videoName, withExtension: "mp4")
//    }

    private func getOrbitImageName(orbit: AppDataModel.Orbit) -> String? {
        guard let session = appModel.objectCaptureSession else { return nil }
        let orbitCompleted = session.userCompletedScanPass
        let orbitCompleteImage = orbit <= appModel.orbit ? orbit.imageSelected : orbit.image
        let orbitNotCompleteImage = orbit < appModel.orbit ? orbit.imageSelected : orbit.image
        return orbitCompleted ? orbitCompleteImage : orbitNotCompleteImage
    }

    private let onboardingStateToTitleMap: [ OnboardingState: String ] = [
        .tooFewImages: "Слишком мало изображений",
        .firstSegmentNeedsWork: "Продолжите сканирование, чтобы завершить первый цикл",
        .firstSegmentComplete: "Первый цикл завершен",
        .secondSegmentNeedsWork: "Продолжите сканирование, чтобы завершить второй цикл",
        .secondSegmentComplete: "Второй цикл завершен",
        .thirdSegmentNeedsWork: "Продолжите сканирование, чтобы завершить последний цикл",
        .thirdSegmentComplete: "Последний цикл завершен",
        .flipObject: "Переверните объект на бок и проведите сканирование еще раз",
        .flipObjectASecondTime: "Переверните объект на другой бок и проведите сканирование еще раз",
        .flippingObjectNotRecommended: "Не рекомендуется переворачивать объект",
        .captureFromLowerAngle: "Проведите сканирование объекта еще раз с меньшего угла",
        .captureFromHigherAngle: "Проведите сканирование объекта еще раз с большего угла",
        .captureInAreaMode: "Предпросмотр модели"
    ]

    private var title: String {
        onboardingStateToTitleMap[onboardingStateMachine.currentState] ?? ""
    }

    private let onboardingStateToDetailTextMap: [ OnboardingState: String ] = [
        .tooFewImages: String(format: "Вам необходимо как минимум %d изобажений, чтобы создать модель.", AppDataModel.minNumImages),
        .firstSegmentNeedsWork: "Для лучшего качества модели рекомендуется прохождение трех циклов сканирования.",
        .firstSegmentComplete: "Для лучшего качества модели рекомендуется прохождение трех циклов сканирования.",
        .secondSegmentNeedsWork: "Для лучшего качества модели рекомендуется прохождение трех циклов сканирования.",
        .secondSegmentComplete: "Для лучшего качества модели рекомендуется прохождение трех циклов сканирования.",
        .thirdSegmentNeedsWork: "Для лучшего качества модели рекомендуется прохождение трех циклов сканирования.",
        .thirdSegmentComplete: "Нажмите Завершить, чтобы перейти к генерации модели.",
        .flipObject: "Переверните объект так, чтобы остались видимыми уже отсканированные области.",
        .flipObjectASecondTime: "Переверните объект так, чтобы остались видимыми уже отсканированные области.",
        .flippingObjectNotRecommended: "Не рекомендуется переворачивать ваш объект (возможно из-за слаборазличимых цветов).",
        .captureFromLowerAngle: "Проведите сканирование объекта еще раз ближе к его основанию.",
        .captureFromHigherAngle: "Проведите сканирование сверху объекта еще раз.",
        .captureInAreaMode: "Точки показывают то, что будет включено в модель сканируемой площади."
    ]

    private var detailText: String {
        onboardingStateToDetailTextMap[onboardingStateMachine.currentState] ?? ""
    }
}
