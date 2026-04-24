import SwiftUI
import AppKit
import AVFoundation

struct CameraPreviewRepresentable: NSViewRepresentable {
    let camera: CameraManager
    var isFlipped: Bool = false

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = CGColor.black
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        guard let previewLayer = camera.previewLayer else { return }
        if previewLayer.superlayer == nil {
            previewLayer.frame = view.bounds
            previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            view.layer?.addSublayer(previewLayer)
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = view.bounds
            CATransaction.commit()
        }
        // Flip horizontally to show unmirrored (how others see you)
        previewLayer.transform = isFlipped
            ? CATransform3DMakeScale(-1, 1, 1)
            : CATransform3DIdentity
    }
}
