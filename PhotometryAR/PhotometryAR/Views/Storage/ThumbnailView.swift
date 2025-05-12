import SwiftUI

/// Превью модели
struct ThumbnailView: View {
    
    /// Путь до модели
    let url: URL
    
    @State private var image: UIImage? = nil
    
    init(url: URL) {
        self.url = url
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let image {
                thumbnailImage(uiimage: image)
            } else {
                ProgressView()                                      // TODO: Шиммер
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
    
    ThumbnailView(url: url)
        .padding()
}
