import SwiftUI

struct StorageView: View {
    @Environment(DefaultModelStorage.self) var storage
    
    @State private var showFileImporter = false
    
    private let columns = [
        GridItem(),
        GridItem()
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(storage.urls, id: \.absoluteString) { url in
                        ModelCell(url: url)
                    }
                }
            }
            .background {
                background()
            }
            .padding(.horizontal, 8)
            .scrollClipDisabled()
            .navigationTitle("Модели")
            .scrollIndicators(.hidden)
            .toolbarBackground(.hidden, for: .tabBar)
            .toolbar {
                importButton()
            }
        }
    }
    
    private func ModelCell(url: URL) -> some View {
        NavigationLink(destination: ARView(url: url)) {
            ThumbnailView(url: url, removeAction: {
                Task {
                    do {
                        try storage.removeModel(url: url)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            })
        }
    }
    
    private func background() -> some View {
        Text(storage.urls.count == 0 ? "Нет моделей" : "")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func importButton() -> some View {
        Button {
            showFileImporter = true
        } label: {
            Image(systemName: "square.and.arrow.down")
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.usdz]) { result in
                Task {
                    do {
                        switch result {
                        case .success(let url):
                            try storage.addModel(url: url)
                        case .failure(let error):
                            throw error
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
    }
}

#Preview {
    StorageView()
        .environment(DefaultModelStorage())
}
