//
//  CameraView.swift
//  HeraKlue
//
//  SHARED. A live rear-camera passthrough, used as the AR background behind
//  the onboarding UI. Works on a real device only — the Simulator has no
//  camera, so it shows black there.
//
//  The permission prompt uses the project's NSCameraUsageDescription.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.start()
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: ()) {
        // Free the camera when we leave the tutorial, so the AR gameplay
        // section can take it over.
        uiView.stop()
    }

    /// A UIView whose backing layer is the camera preview.
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        private var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        private let session = AVCaptureSession()

        func start() {
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.session = session
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.addInputAndRun() }
            }
        }

        private func addInputAndRun() {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)
            let session = self.session
            DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        }

        func stop() {
            let session = self.session
            DispatchQueue.global(qos: .userInitiated).async { session.stopRunning() }
        }
    }
}
