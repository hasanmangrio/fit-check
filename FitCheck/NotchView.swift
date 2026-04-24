import SwiftUI

struct NotchView: View {
    @ObservedObject var model: NotchViewModel
    @StateObject private var camera = CameraManager()
    @StateObject private var faces = FaceDetectionManager()
    @State private var cameraReady = false

    var blobWidth: CGFloat  { model.isExpanded ? model.expandedSize.width  : model.notchSize.width  }
    var blobHeight: CGFloat { model.isExpanded ? model.expandedSize.height : model.notchSize.height }
    var blobRadius: CGFloat { model.isExpanded ? 22 : 12 }

    var body: some View {
        ZStack(alignment: .top) {
            blob
        }
        .frame(width: model.expandedSize.width, height: model.expandedSize.height, alignment: .top)
        .onAppear { setupCamera() }
        .onChange(of: model.isExpanded) { expanded in
            expanded ? camera.start() : camera.stop()
        }
    }

    private var blob: some View {
        ZStack {
            // Black notch blob
            Color.black

            // Camera feed
            if cameraReady {
                CameraPreviewRepresentable(camera: camera)
                    .opacity(model.isExpanded ? 1 : 0)
                    .animation(.easeIn(duration: 0.15), value: model.isExpanded)
            }

            // "You look good, fam." badge
            if model.isExpanded && faces.faceDetected {
                VStack {
                    Spacer()
                    lookGoodBadge
                        .padding(.bottom, 18)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 6)),
                                removal: .opacity
                            )
                        )
                }
            }
        }
        .frame(width: blobWidth, height: blobHeight)
        .clipShape(RoundedRectangle(cornerRadius: blobRadius, style: .continuous))
        .shadow(
            color: model.isExpanded ? .black.opacity(0.45) : .clear,
            radius: 28, x: 0, y: 12
        )
        .animation(.spring(response: 0.42, dampingFraction: 0.68), value: model.isExpanded)
        .animation(.spring(response: 0.42, dampingFraction: 0.68), value: blobWidth)
        .animation(.spring(response: 0.42, dampingFraction: 0.68), value: blobHeight)
        .animation(.spring(response: 0.42, dampingFraction: 0.68), value: blobRadius)
    }

    private var lookGoodBadge: some View {
        Text("You look good, fam.")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func setupCamera() {
        camera.requestAccessAndConfigure { @MainActor in
            cameraReady = true
            faces.attach(to: camera.captureSession)
        }
    }
}
