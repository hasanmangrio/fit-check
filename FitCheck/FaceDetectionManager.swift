import Vision
import AVFoundation

final class FaceDetectionManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    @Published var faceDetected = false

    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.fitcheck.vision", qos: .userInitiated)

    func attach(to session: AVCaptureSession) {
        output.setSampleBufferDelegate(self, queue: queue)
        output.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
    }

    func detach(from session: AVCaptureSession) {
        session.removeOutput(output)
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
        try? handler.perform([request])

        let detected = !(request.results?.isEmpty ?? true)
        DispatchQueue.main.async { [weak self] in
            self?.faceDetected = detected
        }
    }
}
