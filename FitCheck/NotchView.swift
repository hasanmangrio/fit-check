import SwiftUI

struct NotchView: View {
    @ObservedObject var model: NotchViewModel
    @StateObject private var camera = CameraManager()
    @StateObject private var faces = FaceDetectionManager()
    @State private var cameraReady = false
    @State private var isFlipped = false

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

            // Camera feed — centered, fills the blob
            if cameraReady {
                CameraPreviewRepresentable(camera: camera, isFlipped: isFlipped)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(model.isExpanded ? 1 : 0)
                    .animation(.easeIn(duration: 0.15), value: model.isExpanded)
            }

            // Controls + badge overlay
            if model.isExpanded {
                VStack {
                    // Flip button — top-right corner
                    HStack {
                        Spacer()
                        flipButton
                            .padding(12)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }

                    Spacer()

                    // "You look good, fam." badge — bottom center
                    if faces.faceDetected {
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

    private var flipButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .help(isFlipped ? "Show mirror view" : "Show how others see you")
    }

    private var lookGoodBadge: some View {
        Text("You look good, fam.")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func setupCamera() {
        camera.requestAccessAndConfigure { @MainActor in
            cameraReady = true
            faces.attach(to: camera.captureSession)
        }
    }
}
