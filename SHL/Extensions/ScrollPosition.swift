import SwiftUI


struct ScrollProgressModifier: ViewModifier {
    @Binding var progress: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: proxy.frame(in: .global).minY)
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            // Calculate progress based on safeAreaTop to viewTop distance
                            let safeAreaTop = getSafeAreaTop()
                            let viewTop = value
                            let distance = viewTop - safeAreaTop
                            
                            // Clamp progress value between 0 and 1
                            let clampedProgress = max(0, min(1, distance / abs(distance)))
                            progress = clampedProgress
                        }
                }
            )
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private func getSafeAreaTop() -> CGFloat {
    // Default safe area inset for devices without a notch
    let defaultSafeAreaTop: CGFloat = 20
    
    // This is an approximation - for real usage, consider using @Environment(\.safeAreaInsets)
#if os(iOS)
    // Return a reasonable default value for the safe area top
    return defaultSafeAreaTop
#else
    return 0
#endif
}

extension View {
    @ViewBuilder
    func getScrollPosition(_ position: Binding<CGFloat>) -> some View {
        if #available(iOS 18.0, *) {
            self
                .onScrollGeometryChange(for: ScrollGeometry.self, of: {
                    $0
                }) { _, val in
                    let offsetY = val.contentOffset.y + val.contentInsets.top
                    guard val.contentInsets.top > 0 else {
                        position.wrappedValue = 0
                        return
                    }
                    position.wrappedValue = max(min(offsetY / val.contentInsets.top, 1), 0)
                }
        } else {
            self
        }
    }
}
