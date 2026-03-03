import UIKit
import Vision
import CoreML
import AVFoundation

class ObjectRecognizer {
    
    private let synthesizer = AVSpeechSynthesizer()
    
    // 识别图片
    func recognizeObjects(in image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        
        // 加载 Core ML 模型
        guard let model = try? VNCoreMLModel(for: YourMLModel().model) else { return }
        
        // 创建识别请求
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
            
            // 获取识别到的物体名称
            let objectNames = results.compactMap { $0.labels.first?.identifier }
            
            if !objectNames.isEmpty {
                print("识别到物体：", objectNames)
                self?.speak(objects: objectNames)
            }
        }
        
        // 执行请求
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([request])
    }
    
    // 播报物体名称
    private func speak(objects: [String]) {
        let sentence = objects.joined(separator: ", ")
        let utterance = AVSpeechUtterance(string: sentence)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // 可以改成 zh-CN
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}