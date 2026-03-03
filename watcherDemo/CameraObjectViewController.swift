import UIKit
import AVFoundation
import Vision
import CoreML

class CameraObjectViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var lastDetectionTime = Date()
    private let detectionInterval: TimeInterval = 0.5
    private var recognizedObjects = Set<String>()
    
    private var model: VNCoreMLModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupModel()
        setupCamera()
    }
    
    private func setupModel() {
        if let coreMLModel = try? yolov5s().model {
            model = try? VNCoreMLModel(for: coreMLModel)
        }
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .high
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        captureSession.addInput(input)
        
        // 显示摄像头画面
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // 设置输出
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        captureSession.startRunning()
    }
    
    // MARK: - Video Frame Delegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= detectionInterval else { return }
        lastDetectionTime = now
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let model = self.model else { return }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
            
            for obj in results {
                if let name = obj.labels.first?.identifier {
                    self.recognizedObjects.insert(name)
                }
            }
            
            print("已识别物体：", self.recognizedObjects)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
}