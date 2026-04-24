import AVFoundation
import AppKit

final class CameraManager: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isRunning = false

    let captureSession = AVCaptureSession()
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "com.fitcheck.camera", qos: .userInitiated)
    private var isConfigured = false

    func requestAccessAndConfigure(completion: @escaping @MainActor () -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession(completion: completion)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.configureSession(completion: completion) }
            }
        default:
            break
        }
    }

    private func configureSession(completion: @escaping @MainActor () -> Void) {
        sessionQueue.async { [weak self] in
            guard let self, !self.isConfigured else { return }
            self.isConfigured = true

            // Disable Center Stage globally — it digitally zooms in to track faces
            if #available(macOS 12.3, *), AVCaptureDevice.isCenterStageEnabled {
                AVCaptureDevice.centerStageControlMode = .app
                AVCaptureDevice.isCenterStageEnabled = false
            }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1280x720

            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
               let input = try? AVCaptureDeviceInput(device: device),
               self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
            self.captureSession.commitConfiguration()

            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer?.videoGravity = .resizeAspect   // show full frame, no cropping
                completion()
            }
        }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }
}
