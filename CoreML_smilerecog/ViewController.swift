//
//  ViewController.swift
//  CoreML_smilerecog
//
//  Created by Bailey Andrew on 20/02/2018.
//  Copyright © 2018 Alliterative Anchovies. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {

	@IBOutlet var outputText: UILabel!
	@IBOutlet var phoneDisplay: UIImageView!
	@IBOutlet var highscoreOutput: UILabel!
	
	var captureSession: AVCaptureSession?
	var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	var smileDetector: ImprovedSmilerMK2?
	var frameOutput: AVCapturePhotoOutput?
	var capturedPhoto: UIImage?
	var cid: CIDetector?
	var lastDetection: Bool?
	var detectionArray: [Bool]?
	var happinessCounter: Int?
	var smilePoints: Int?
	@IBOutlet var faceCam: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		outputText.text = "Smile please!";
		outputText.layer.zPosition = 1;//draw on top of camera
		outputText.center = view.center;
		outputText.center.y = view.center.y+view.bounds.maxY/2 - 20;
		highscoreOutput.layer.zPosition = 3;
		highscoreOutput.text = "Smile Points: 0"
		highscoreOutput.backgroundColor = UIColor.white;
		smilePoints = 0;
		faceCam.layer.zPosition = 2;
		//let captureDevice = AVCaptureDevice.default(for: .video)
		let captureDevice = cameraWithPosition(.front)
		var input : AVCaptureInput?;
		do {input = try AVCaptureDeviceInput(device: captureDevice!)}
		catch {print(error)}
		frameOutput = AVCapturePhotoOutput();
		captureSession = AVCaptureSession()
		captureSession?.addInput(input!)
		captureSession?.addOutput(frameOutput!);
		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
		videoPreviewLayer?.frame = view.layer.bounds
		phoneDisplay.layer.addSublayer(videoPreviewLayer!)
		captureSession?.startRunning()
		smileDetector = ImprovedSmilerMK2();
		cid = CIDetector(ofType:CIDetectorTypeFace, context:nil, options:[CIDetectorAccuracy: CIDetectorAccuracyHigh,CIDetectorImageOrientation: 6]);
		lastDetection = false;
		detectionArray = [];
		happinessCounter = 0;
		//now set smile detector to run every so often
		Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(detectSmile), userInfo: nil, repeats: true)
	}
	
	func getSettings() -> AVCapturePhotoSettings {
		let settings = AVCapturePhotoSettings()
		let previewPixelType = kCVPixelFormatType_32BGRA
      	let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                           kCVPixelBufferWidthKey as String: 160,
                           kCVPixelBufferHeightKey as String: 160]
		settings.previewPhotoFormat = previewFormat
		return settings;
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
	func cameraWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
		let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
			mediaType: AVMediaType.video,
			position: AVCaptureDevice.Position.unspecified);

		for device in deviceDescoverySession.devices {
			if device.position == position {
				return device
			}
		}

		return nil
	}
	
	func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {

        if let error = error {
            print(error.localizedDescription)
        }

        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
			capturedPhoto = UIImage(data: dataImage);
			//detect whether its a smile or not
			let prev = lastDetection!;
			let isSmile = runThroughNet(img: capturedPhoto);
			//run it through the net.
			if (isSmile == nil) {return;}//don't append if nil
			detectionArray?.append(isSmile!);
			let swiftIsAnnoying : Int = (detectionArray?.count)!
			if (swiftIsAnnoying>5) {
				detectionArray?.remove(at: 0);//keep last five
			}
			var smilesThrice = 0;
			for smile in detectionArray! {
				if (smile) {
					smilesThrice+=1
				}
			}
			let isHappy: Bool = isSmile!//smilesThrice>=3;
			var shouldChange = false;
			happinessCounter!+=1;
			if (!(isHappy==prev)) {//if changed happiness, change text
				happinessCounter = 0;
				shouldChange = true;
			}
			if (happinessCounter!>=10) {//if showed same text for a while, change text
				happinessCounter = 0;
				shouldChange = true;
			}
			if (shouldChange) {
				if (isHappy) {
					outputText.text = ["You're smiling!","Great smile!  Keep it up!","Wow, you're good at smiling!"].randomItem();
					outputText.backgroundColor = UIColor.white;
				}
				else {
					outputText.text = ["Turn that frown upside down!","Don't take a while, start to smile!"].randomItem();
					outputText.backgroundColor = UIColor.red;
				}
			}
			if (isHappy) {
				smilePoints!+=1;
				highscoreOutput.text = "Smile Points: "+String(smilePoints!);
			}
			outputText.layer.zPosition = 1;//draw on top of camera
			outputText.center = view.center;
			outputText.center.y = view.center.y+view.bounds.maxY/2 - 20;
        }

    }
	
	@objc func detectSmile() {
		//get image
		//let grabbedImage = phoneDisplay.image;
		frameOutput?.capturePhoto(with: getSettings(), delegate: self)
		
	
	}
	
	func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {

		let scale = newWidth / image.size.width
		let newHeight = image.size.height * scale
		UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
		image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage
	}
	
	func runThroughNet(img: UIImage?) -> Bool? {
		if (img == nil) {
			NSLog("Nil Image!");
			return false;
		}
		let ciimg = CIImage(image: img!)
		let results = cid!.features(in:ciimg!,options:[CIDetectorImageOrientation: 6]);
		
        for r in results {
        	NSLog("Found OMG!");
			let face:CIFaceFeature = r as! CIFaceFeature;
            NSLog("Face found at (%f,%f) of dimensions %fx%f", face.bounds.origin.x, face.bounds.origin.y, face.bounds.width, face.bounds.height);
			let resultantImg = resizeImage(image: (img?.crop(rect: CGRect(x:face.bounds.origin.x,y:face.bounds.origin.y,width:face.bounds.width,height:face.bounds.height)))!,newWidth:227)
            faceCam.image = resultantImg;
			let imageAsPixelBuf = buffer(from: resultantImg!)
			guard let output = try? smileDetector?.prediction(image: imageAsPixelBuf!) else {
				NSLog("Unexpected runtime error.")
				return lastDetection!;
			}
			NSLog(String(format:"%f", (output?.labelProbability["smile"])!));
			NSLog((output?.label)!);
			//lastDetection = output?.label == "smile";
			lastDetection = Double((output?.labelProbability["smile"])!)>0.985;
			return lastDetection
        }

		/*
		let resizedImg = resizeImage(image: img!, newWidth: 227)?.crop(rect: CGRect(x: 0,y:87,width:227,height:227));
		faceCam.image = resizedImg?.imageFlippedForRightToLeftLayoutDirection();
		let imageAsPixelBuf = buffer(from: resizedImg!)
		guard let output = try? smileDetector?.prediction(image: imageAsPixelBuf!) else {
			NSLog("Unexpected runtime error.")
			return false;
		}
		NSLog(String(format:"%f", (output?.labelProbability["smile"])!));
		NSLog((output?.label)!);
		return output?.label == "smile";*/
		return nil;
	}
	

	func buffer(from image: UIImage) -> CVPixelBuffer? {
	  let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
	  var pixelBuffer : CVPixelBuffer?
	  let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
	  guard (status == kCVReturnSuccess) else {
		return nil
	  }

	  CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
	  let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

	  let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
	  let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

	  context?.translateBy(x: 0, y: image.size.height)
	  context?.scaleBy(x: 1.0, y: -1.0)

	  UIGraphicsPushContext(context!)
	  image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
	  UIGraphicsPopContext()
	  CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

	  return pixelBuffer
	}

}

extension UIImage {
	func crop( rect: CGRect) -> UIImage {
		var rect = rect
		rect.origin.x*=self.scale
		rect.origin.y*=self.scale
		rect.size.width*=self.scale
		rect.size.height*=self.scale

		let imageRef = self.cgImage!.cropping(to: rect)
		let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
		return image
	}
}

extension Array {
    func randomItem() -> Element? {
        if isEmpty { return nil }
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

/*extension UIImage {
    func buffer(with size:CGSize) -> CVPixelBuffer? {
        if let image = self.cgImage {
            let frameSize = size
            var pixelBuffer:CVPixelBuffer? = nil
            let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(frameSize.width), Int(frameSize.height), kCVPixelFormatType_32BGRA , nil, &pixelBuffer)
            if status != kCVReturnSuccess {
                return nil
            }
            CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
            let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
            let context = CGContext(data: data, width: Int(frameSize.width), height: Int(frameSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
            context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
			
            return pixelBuffer
        }else{
            return nil
        }
    }
}*/

