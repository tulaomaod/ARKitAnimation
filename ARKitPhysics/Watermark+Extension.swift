//
//  Watermark+Extension.swift
//  MetalWatermark
//
//  Created by mac126 on 2018/5/31.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import AVFoundation

extension UIImage {
    
    /// 添加图片水印
    ///
    /// - Parameter waterImage: 水印图片
    /// - Returns: 新图片
    func createImageWaterMark(waterImage:UIImage) -> UIImage {
        
        // 开启画布
        UIGraphicsBeginImageContext(self.size)
        
        // 将原图绘制到画布上
        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))
        
        // 计算水印的位置
        let margin: CGFloat = 50
        let x = (size.width - waterImage.size.width) / 2
        let y = size.height - waterImage.size.height - margin
        let waterRect = CGRect(x: x,
                               y: y,
                               width: waterImage.size.width,
                               height: waterImage.size.height)
        
        // 将水印图片绘制到画布上
        waterImage.draw(in: waterRect)
        
        // 生成新图片
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

let kMediaContentDefaultScale: CGFloat = 1
let kProcessedTemporaryVideoFileName = "/processed.mp4"
let kMediaContentTimeValue: Int64 = 1
let kMediaContentTimeScale: Int32 = 30

extension URL {
    
    /// 为视频添加水印图片
    ///
    /// - Parameter waterImage: 水印图片
    /// - Returns: 视频url
    func createVideoWaterMark(waterImage:UIImage, completion: @escaping (_ videoURL: URL?, _ error: Error?) -> ()) {
        // 排版对象
        let mixComposition = AVMutableComposition()
        // 视频通道
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        // 视频资源
        let sourceAsset = AVURLAsset(url: self)
        let clipVideoTrack = sourceAsset.tracks(withMediaType: AVMediaType.video).first
        let clipAudioTrack = sourceAsset.tracks(withMediaType: AVMediaType.audio).first
        
        do {
            try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, sourceAsset.duration), of: clipVideoTrack!, at: kCMTimeZero)
        } catch {
            completion(nil, error)
        }
        
        if (clipAudioTrack != nil) {
            let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            do {
                try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, sourceAsset.duration), of: clipAudioTrack!, at: kCMTimeZero)
            } catch {
                completion(nil, error)
            }
        }
        
        compositionVideoTrack?.preferredTransform = (sourceAsset.tracks(withMediaType: AVMediaType.video).first?.preferredTransform)!
        
        // 视频宽高
        var sizeOfVideo: CGSize!
        if let track = AVAsset(url: sourceAsset.url).tracks(withMediaType: AVMediaType.video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            sizeOfVideo = CGSize(width: fabs(size.width), height: fabs(size.height))
        } else {
            sizeOfVideo = CGSize.zero
        }
        print("sizeOfVideo-\(sizeOfVideo)")
        
        // 水印layer
        let optionalLayer = CALayer()
        let watermarkLayer = CALayer()
        watermarkLayer.contents = waterImage.cgImage
        // 计算水印的位置
        let margin: CGFloat = 50
        let x = (sizeOfVideo.width - waterImage.size.width) / 2
        let waterRect = CGRect(x: x,
                               y: margin,
                               width: waterImage.size.width,
                               height: waterImage.size.height)
        watermarkLayer.frame = waterRect
        optionalLayer.addSublayer(watermarkLayer)
        
        optionalLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        optionalLayer.masksToBounds = true
        
        // 添加水印
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: sizeOfVideo.width, height: sizeOfVideo.height)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(optionalLayer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(kMediaContentTimeValue, kMediaContentTimeScale)
        videoComposition.renderSize = sizeOfVideo
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration)
        
        let videoTrack = mixComposition.tracks(withMediaType: AVMediaType.video).first
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
        layerInstruction.setTransform(transform(avAsset: sourceAsset, scaleFactor: kMediaContentDefaultScale), at: kCMTimeZero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        let processedUrl = processedMoviePath()
        clearTemporaryData(url: processedUrl, completion: completion)
        
        // 导出视频
        let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.videoComposition = videoComposition
        exportSession?.outputURL = processedUrl
        exportSession?.outputFileType = AVFileType.mp4
        
        exportSession?.exportAsynchronously(completionHandler: {
            if exportSession?.status == AVAssetExportSessionStatus.completed {
                completion(processedUrl, nil)
            } else {
                completion(nil, exportSession?.error)
                
            }
        })
        
    }
    
    // MARK: - private
    private func transform(avAsset: AVAsset, scaleFactor: CGFloat) -> CGAffineTransform {
        var offset = CGPoint.zero
        var angle: Double = 0
        
        switch avAsset.contentOrientation {
        case .left:
            offset = CGPoint(x: avAsset.contentCorrectSize.height, y: avAsset.contentCorrectSize.width)
            angle = Double.pi
        case .right:
            offset = CGPoint.zero
            angle = 0
        case .down:
            offset = CGPoint(x: 0, y: avAsset.contentCorrectSize.width)
            angle = -(Double.pi / 2)
        default:
            offset = CGPoint(x: avAsset.contentCorrectSize.height, y: 0)
            angle = Double.pi / 2
        }
        
        let scale = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        let translation = scale.translatedBy(x: offset.x, y: offset.y)
        let rotation = translation.rotated(by: CGFloat(angle))
        
        return rotation
    }
    
    /// 视频文件路径
    ///
    /// - Returns: 本地路径
    private func processedMoviePath() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + kProcessedTemporaryVideoFileName
        return URL(fileURLWithPath: documentsPath)
    }
    
    /// 清理临时文件
    private func clearTemporaryData(url: URL, completion: (_ videoURL: URL?, _ error: Error?) -> ()) {
        if (FileManager.default.fileExists(atPath: url.path)) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    
}

extension AVAsset {
    private var contentNaturalSize: CGSize {
        return tracks(withMediaType: AVMediaType.video).first?.naturalSize ?? .zero
    }
    
    var contentCorrectSize: CGSize {
        return isContentPortrait ? CGSize(width: contentNaturalSize.height, height: contentNaturalSize.width) : contentNaturalSize
    }
    
    var contentOrientation: UIImageOrientation {
        var assetOrientation = UIImageOrientation.up
        let transform = tracks(withMediaType: AVMediaType.video)[0].preferredTransform
        
        if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
            assetOrientation = .up
        }
        
        if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0) {
            assetOrientation = .down
        }
        
        if (transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0) {
            assetOrientation = .right
        }
        
        if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {
            assetOrientation = .left
        }
        
        return assetOrientation
    }
    
    var isContentPortrait: Bool {
        let portraits: [UIImageOrientation] = [.left, .right]
        return portraits.contains(contentOrientation)
    }
}


