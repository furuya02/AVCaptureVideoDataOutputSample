//
//  ViewController.swift
//  AVCaptureVideoDataOutputSample
//
//  Created by hirauchi.shinichi on 2016/12/16.
//  Copyright © 2016年 SAPPOROWORKS. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController ,AVCaptureVideoDataOutputSampleBufferDelegate,AVAudioPlayerDelegate  {

    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var snapButton: UIButton!

    @IBOutlet weak var scrollView: UIScrollView!
    
    var videoDataOutput: AVCaptureVideoDataOutput?
    var images:[UIImage] = []
    var isShooting = false // 連写中
    var counter = 0
    
    var audioPlayer:AVAudioPlayer! // シャッター音用
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // シャッター音
        let audioPath = Bundle.main.path(forResource: "nc66359", ofType:"wav")!
        let audioUrl = URL(fileURLWithPath: audioPath)
        audioPlayer = try! AVAudioPlayer(contentsOf: audioUrl)
        audioPlayer.delegate = self
        audioPlayer.currentTime = 0
        
        // セッションのインスタンス生成
        let captureSession = AVCaptureSession()
        
        // 入力（背面カメラ）
        let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        videoDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)// フレームレート １/30秒
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice)
        captureSession.addInput(videoInput)
        // 出力（ビデオデータ）
        videoDataOutput = AVCaptureVideoDataOutput()
        
        // ピクセルフォーマット(32bit BGRA)
        videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        // キューのブロック中に新しいフレームが来たら削除する
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        // フレームをキャプチャするためのキューを指定
        videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)

        captureSession.addOutput(videoDataOutput)
        // クオリティ(1920x1080ピクセル)
        captureSession.sessionPreset = AVCaptureSessionPreset1920x1080

        // プレビュー
        if let videoLayer = AVCaptureVideoPreviewLayer.init(session: captureSession) {
            videoLayer.frame = previewView.bounds
            videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            previewView.layer.addSublayer(videoLayer)
        }
        // セッションの開始
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    // 新しいキャプチャの追加で呼ばれる(1/30秒に１回)
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if counter % 3 == 0 { // 1/10秒だけ処理する
            if isShooting {
                //        let image:UIImage = captureImage(sampleBuffer)
                //let image = UIImage(named: "003.jpg")
                
                let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
                addImage(image: image)
            }
        }
        counter += 1
    }
    
    @IBAction func touchUpButton(_ sender: UIButton) {
        isShooting = false // 連写終了
        audioPlayer.stop()
    }
    
    @IBAction func touchDownButton(_ sender: UIButton) {
        // 前回撮影の画像を削除
        images = []
        for imageView in scrollView.subviews {
            imageView.removeFromSuperview()
        }
        isShooting = true // 連写中
        audioPlayer.play()
    }
    
    // 連写音の連続再生
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if isShooting {
            audioPlayer.play()
        }
    }
    
    func imageFromSampleBuffer(sampleBuffer :CMSampleBuffer) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // イメージバッファのロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // 画像情報を取得
        let base = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        let bytesPerRow = UInt(CVPixelBufferGetBytesPerRow(imageBuffer))
        let width = UInt(CVPixelBufferGetWidth(imageBuffer))
        let height = UInt(CVPixelBufferGetHeight(imageBuffer))
        
        // ビットマップコンテキスト作成
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerCompornent = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        let newContext = CGContext(data: base, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerCompornent), bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: bitmapInfo.rawValue)! as CGContext
        
        // 画像作成
        let imageRef = newContext.makeImage()!
        let image = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        // イメージバッファのアンロック
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return image
    }
    
    func addImage(image: UIImage) {
 
        let height:CGFloat = 100 // 基準の高さ
        let margin = 10
        let magnification = height / image.size.height
        
        let width = image.size.width * magnification
        let x = (margin + Int(width)) * images.count
        let y = margin

        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: x, y: y, width: Int(width), height: Int(height))
        
        scrollView.addSubview(imageView)
        let w = x + Int(width)
        scrollView.contentSize = CGSize(width: CGFloat(w), height: scrollView.frame.size.height)
        images.append(image)
    }
    
}

