import SwiftUI

@MainActor
final class NotchViewModel: ObservableObject {
    @Published var isExpanded = false

    let notchSize: CGSize
    let expandedSize: CGSize

    init(notchSize: CGSize, expandedSize: CGSize) {
        self.notchSize = notchSize
        self.expandedSize = expandedSize
    }

    func expand() {
        guard !isExpanded else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) {
            isExpanded = true
        }
    }

    func collapse() {
        guard isExpanded else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            isExpanded = false
        }
    }
}
