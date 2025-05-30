import SwiftUI

struct HelpPageView: View {
    @Binding var showHelpPageView: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        showHelpPageView = false
                    }},
                       label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(white: 0.7, opacity: 0.5))
                        .font(.title)
                })
            }
            
            ScrollView {
                VStack {
                    CaptureTypesHelpPageView()
                    HowToCaptureHelpPageView()
                }
            }
        }
    }
}

private struct CaptureTypesHelpPageView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TutorialPageView(pageName: "Виды сканирования",
                         imageName: nil,
                         imageCaption: "",
                         sections: sections())
    }
    
    private func sections() -> [Section] {
        [
            Section(
                title: "Сканирование объекта",
                body: ["Сканирование объекта отдельно от окружающего пространства.",
                      "Лучше проводить в помещении."],
                symbol: nil,
                symbolColor: nil
            ),
            Section(
                title: "Сканирование пространства",
                body: ["Сканирование всего простанства, охватываемого камерой устройства."],
                symbol: nil,
                symbolColor: nil
            )
        ]
    }
}

private struct HowToCaptureHelpPageView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TutorialPageView(
            pageName: "Как проводить сканирование",
            imageName: colorScheme == .light ? "OrbitTutorial-light" : "OrbitTutorial",
            imageCaption: "Перемещайте устройство медленно вокруг объекта, чтобы захватить все его стороны.",
            sections: sections()
        )
    }
    
    private func sections() -> [Section] {
        [
            Section(
                title: "Порядок действий",
                body: ["1. Выберите подходящий режим сканирования.",
                       "2. Удерживайте целевой объект в видимости камеры устройста.",
                       "3. Медленно перемещайте устройство, чтобы захватить все стороны объекта сканирования."],
                symbol: nil,
                symbolColor: nil
            ),
            Section(
                title: "Может негативно сказаться на точности модели объекта",
                body: ["1. Недостаточная освещенность.",
                       "2. Быстрое перемещение устройства во время сканирования.",
                       "3. Малое количество снимков.",
                       "4. Резкие тени или пятна света на целевом объекте.",
                       "5. Глянцевые или полупрозраные материалы."],
                symbol: nil,
                symbolColor: nil
            )
        ]
    }
}
