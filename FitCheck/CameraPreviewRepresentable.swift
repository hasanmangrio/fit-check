import SwiftUI
import AppKit
import AVFoundation

struct CameraPreviewRepresentable: NSViewRepresentable {
    let camera: CameraManager

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
    }
}
