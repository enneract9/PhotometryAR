import SwiftUI

/// Превью модели
struct ThumbnailView: View {
    
    /// Путь до модели
    let url: URL
    
    /// Удаление модели
    let removeAction: () -> Void
    
    @State private var image: UIImage? = nil
    @State private var showFileExporter = false
    
    init(url: URL, removeAction: @escaping () -> Void) {
        self.url = url
        self.removeAction = removeAction
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let image {
                thumbnailImage(uiimage: image)
            } else {
                ProgressView()
            }
            title(url.deletingPathExtension().lastPathComponent)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 16))
        .task {
            do {
                image = try await PreviewGenerator.getPreviewImage(from: url)
            } catch {
                print(error.localizedDescription)
            }
        }
        .contextMenu(menuItems: {
            Button("Удалить", role: .destructive) {
                removeAction()
            }
            
            Button {
                showFileExporter = true
            } label: {
                HStack {
                    Text("Экспорт")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
            }
        })
        .sheet(isPresented: $showFileExporter) {
            ActivityView(activityItems: [url])
        }
    }
    
    private func thumbnailImage(uiimage: UIImage) -> some View {
        Image(uiImage: uiimage)
            .resizable()
            .aspectRatio(1, contentMode: .fit)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18))
            .padding(.horizontal, 8)
            .tint(.primary)
    }
}

#Preview {
    let mockModelStorage: ModelStorage = .mock
    let url = mockModelStorage.urls[0]
    
    ThumbnailView(url: url, removeAction: {})
        .padding()
}
