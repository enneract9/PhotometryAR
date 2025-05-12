import SwiftUI

enum Tab: String, CaseIterable {
    case camera
    case ar
    
    var image: String? {
        switch self {
        case .camera:
            return "camera"
        default:
            return nil
        }
    }
    
    var selectedImage: String? {
        guard let image else {
            return nil
        }
        return image + ".fill"
    }
    
    var title: String? {
        switch self {
        case .ar:
            return "AR"
        default:
            return nil
        }
    }
}

struct TabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                label(for: tab)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(.capsule)
    }
    
    private func label(for tab: Tab) -> some View {
        let imageName = switch tab {
        case selectedTab:
            tab.selectedImage
        default:
            tab.image
        }
        
        var imageSize: CGFloat
        var titleSize: CGFloat
        
        switch (imageName, tab.title) {
        case (.none, .some(_)):
            imageSize = 0
            titleSize = 24
        case (.some(_), .none):
            imageSize = 24
            titleSize = 0
        case (.some(_), .some(_)):
            imageSize = 18
            titleSize = 10
        case (.none, .none):
            imageSize = 0
            titleSize = 0
        }
        
        return VStack {
            if let imageName {
                Image(systemName: imageName)
                    .font(.system(size: imageSize))
            }
            if let title = tab.title {
                Text(title)
                    .font(.system(size: titleSize))
            }
        }
        .padding()
        .padding(.horizontal)
        .foregroundStyle(tab == selectedTab ? .blue : Color.primary)
        .scaleEffect(tab == selectedTab ? 1.1 : 1.0)
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.1)) {
                selectedTab = tab
            }
        }
    }
}

#Preview {
    TabBar(selectedTab: .constant(.ar))
}
