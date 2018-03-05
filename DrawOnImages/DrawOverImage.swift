//
//  DrawOverImage.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/1/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//

import UIKit

protocol DrawOverImageDelegate: class {
    func doneEditing(image: UIImage)
}

class DrawOverImage: UIViewController {
    
    // set this variable when instantiating this vc from some other vc
    weak var imageForMainImage: UIImage!
    
    weak var delgate: DrawOverImageDelegate?
    
    @IBOutlet weak var editsForImage: UIImageView!
    
    @IBAction func DoneEditing(_ sender: UIBarButtonItem) {
        
        // Merge two images before exiting view controller
        
        //mainImage.image = mergedImageWith(frontImage: editsForImage.image, backgroundImage: mainImage.image)
        
        //editsForImage = nil
        saveImage()
        delgate?.doneEditing(image: mainImage.image!) // TODO: remove implicit unwrap
//        mergeImageAsync()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func Brush(_ sender: UIBarButtonItem) {
        print("Brush Selected")
    }
    
    @IBOutlet weak var mainImage: UIImageView!
    
    var oldTouchPoint: CGPoint? // the last time when the screen was touch
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setUpImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory Warning -- DrawOverImageView")
    }
    
    // MARK: Setup Initial image
    private func setUpImage() {
        mainImage.image = imageForMainImage
    }
    
    
    
    // MARK: Setup touch gestures
    @IBAction func tapGesture(_ gesture: UITapGestureRecognizer) {
        
        if (gesture.state == .recognized) {
            print("Initial Touch Gesture")
        }
    }
    
    @IBAction func panGesture(_ gesture: UIPanGestureRecognizer) {
        
        let currentTouchLoc = gesture.location(in: editsForImage)
        
        if (gesture.state == .began) {
            oldTouchPoint = currentTouchLoc
        }
        
        if (gesture.state != .ended) {
            drawLine(from: oldTouchPoint!, to: currentTouchLoc) // FIX !!!!
        }
        
        oldTouchPoint = currentTouchLoc
    }
    
    // MARK: Draw line between two vertcies
    
    private func drawLine(from: CGPoint, to: CGPoint) {
        let size = editsForImage.frame.size
        
        // Start new image context
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        let context = UIGraphicsGetCurrentContext()
        editsForImage.image?.draw(at: CGPoint(x: 0, y: 0))

        let strokeColor = UIColor.black.cgColor

        context?.setLineWidth(2)
        context?.setStrokeColor(strokeColor)
        context?.setLineCap(.round)

        context?.move(to: from)
        context?.addLine(to: to)
        context?.strokePath()

        editsForImage.image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

    }
    
    private func saveImage() {
        let renderer = UIGraphicsImageRenderer(size: mainImage.frame.size)
        
        let img = renderer.image { ctx in
            let rectangle = CGRect(x: 0, y: 0, width: mainImage.frame.width, height: mainImage.frame.height)
            ctx.cgContext.addRect(rectangle)
//            ctx.cgContext.saveGState()
//            ctx.cgContext.concatenate(ctx.cgContext.userSpaceToDeviceSpaceTransform)
//            ctx.cgContext.rotate(by: CGFloat.pi/2)
//            ctx.cgContext.translateBy(x: 0, y: mainImage.frame.width)
            //
//            ctx.cgContext.translateBy(x: rectangle.midX, y: rectangle.midY)
//            ctx.cgContext.scaleBy(x: 1, y: -1)
//            ctx.cgContext.rotate(by: (-CGFloat.pi/2))
//            ctx.cgContext.translateBy(x: -rectangle.midX, y: -rectangle.midY)
//            ctx.cgContext.draw(mainImage.image!.cgImage!, in: rectangle)
            
//            ctx.cgContext.translateBy(x: rectangle.midX, y: rectangle.midY)
//            ctx.cgContext.scaleBy(x: 1, y: -1)
//            ctx.cgContext.rotate(by: (CGFloat.pi/2))
//            ctx.cgContext.translateBy(x: -rectangle.midX, y: -rectangle.midY)
//            ctx.cgContext.draw(editsForImage.image!.cgImage!, in: rectangle)
            //
            
            mainImage.image?.draw(in: rectangle)
            editsForImage.image?.draw(in: rectangle)
        }
        mainImage.image = img
    }
    
    /*
    private func mergedImageWith(frontImage:UIImage?, backgroundImage: UIImage?) -> UIImage{
        
        if (backgroundImage == nil) {
            return frontImage!
        }
        let size = backgroundImage?.size
//        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
//        UIGraphicsBeginImageContextWithOptions(size!, false, 1)
        
//        backgroundImage?.draw(in: CGRect.init(x: 0, y: 0, width: (size?.width)!, height: (size?.height)!))
//        frontImage?.draw(in: CGRect.init(x: 0, y: 0, width: (size?.width)!, height: (size?.height)!).insetBy(dx: (size?.width)! * 0.01, dy: (size?.height)! * 0.01))
//
//        backgroundImage?.draw(at: CGPoint(x: 0, y: 0))
//        frontImage?.draw(in: CGRect(x: 0, y: 0, width: (size?.width)!, height: (size?.height)!)) // TODO: remove force unwrap
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
        
        
//        return newImage
        return img
        
    }
    
    private func mergeImageAsync() {
        DispatchQueue.global(qos: .background).async {
            autoreleasepool(invoking: {
                let tempImage = self.mergedImageWith(frontImage: self.editsForImage.image, backgroundImage: self.mainImage.image)
                self.mainImage.image = tempImage
                self.delgate?.doneEditing(image: self.mainImage.image!)
                print("dispatch queue done")
            })
        }
    }
    */
}

extension DrawOverImage: StoryboardInitializable {
    static var storyboardName: String {
        return "DrawOverImage"
    }
    
    static var storyboardSceneID: String {
        return "DrawOverImage"
    }
    
    
}
