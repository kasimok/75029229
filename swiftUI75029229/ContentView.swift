// Created for swiftUI75029229 by 0x67 on 2023-01-30

import SwiftUI
import CoreData
import UIKit
import AVFoundation

//let imageURL: URL = Bundle.main.url(forResource: "IMG_3255", withExtension: "jpg")!
let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("movie.mp4")


struct ContentView: View {
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            ZStack{
                Image("IMG_3255").resizable().scaledToFill().ignoresSafeArea()
                Button {
                    let image = self.snapshot()
                    try? FileManager.default.removeItem(atPath: tempPath)
                    writeSingleImageToMovie(image: image, movieLength: 2, outputFileURL: URL(fileURLWithPath: tempPath)) { error in
                        showingAlert = true
                    }
                } label: {
                    Text("Click to generate video...").font(.title).foregroundColor(.white).bold()
                }.alert("Video file generated at:\(tempPath), inspect it in simulator!", isPresented: $showingAlert) {
                    Button("OK", role: .cancel) {
                        UIPasteboard.general.string = tempPath
                    }
                }
            }
        }
    }

    
    
    func writeSingleImageToMovie(image: UIImage, movieLength: TimeInterval, outputFileURL: URL, completion: @escaping (Error?) -> ())
         {
            print("writeSingleImageToMovie is called")
         
            do {
                let imageSize = image.size
                let videoWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: AVFileType.mp4)
                let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                                    AVVideoWidthKey: imageSize.width, //was imageSize.width
                                                    AVVideoHeightKey: imageSize.height] //was imageSize.height
                
              
                let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)
                
                if !videoWriter.canAdd(videoWriterInput) { throw NSError() }
                videoWriterInput.expectsMediaDataInRealTime = true
                videoWriter.add(videoWriterInput)
                
                videoWriter.startWriting()
                let timeScale: Int32 = 4 // 600 recommended in CMTime for movies.
                _ = Float64(movieLength/2.0) // videoWriter assumes frame lengths are equal.
                let startFrameTime = CMTimeMake(value: 0, timescale: timeScale)
             
                
                let endFrameTime = CMTimeMakeWithSeconds(Double(60), preferredTimescale: timeScale)
                                                      
                videoWriter.startSession(atSourceTime: startFrameTime)
              
             
                
            guard let cgImage = image.cgImage else { throw NSError() }
                 
         
                let buffer: CVPixelBuffer = try CGImage.pixelBuffer(fromImage: cgImage, size: imageSize)

                while !adaptor.assetWriterInput.isReadyForMoreMediaData { usleep(10) }
                adaptor.append(buffer, withPresentationTime: startFrameTime)
                while !adaptor.assetWriterInput.isReadyForMoreMediaData { usleep(10) }
                adaptor.append(buffer, withPresentationTime: endFrameTime)
                
                videoWriterInput.markAsFinished()
                videoWriter.finishWriting
                {
                    completion(videoWriter.error)
                }
                
            } catch {
                print("CATCH Error in writeSingleImageToMovie")
                completion(error)
            }
    }
    
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self.ignoresSafeArea(.all))
        let view = controller.view

    let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
    
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        
    }
    
}




extension CGImage {
 
    static func pixelBuffer(fromImage image: CGImage, size: CGSize) throws -> CVPixelBuffer {
        print("pixelBuffer from CGImage")
        let options: CFDictionary = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true] as CFDictionary
        var pxbuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options, &pxbuffer)
        guard let buffer = pxbuffer, status == kCVReturnSuccess else { throw NSError() }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        guard let pxdata = CVPixelBufferGetBaseAddress(buffer)
        else { throw NSError() }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
         
            guard let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { print("error in `CG context")
                throw NSError() }
        context.concatenate(CGAffineTransform(rotationAngle: 0))
        context.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
        }
}


