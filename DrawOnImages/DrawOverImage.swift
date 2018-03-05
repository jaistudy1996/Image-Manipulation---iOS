//
//  DrawOverImage.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/1/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//
// swiftlint:disable trailing_whitespace

import UIKit

protocol DrawOverImageDelegate: class {
    func doneEditing(image: UIImage)
}

class DrawOverImage: UIViewController {
    
    // set this variable when instantiating this vc from some other vc
    weak var imageForMainImage: UIImage!
    
    @IBOutlet weak var tabBarSelectColor: UITabBar!
    weak var delgate: DrawOverImageDelegate?
    
    @IBOutlet weak var editsForImage: UIImageView!
    
    @IBAction func doneEditing(_ sender: UIBarButtonItem) {
        
        // Merge two images before exiting view controller
        mergeImage()
        editsForImage = nil // free unnecessary memory usage.
        guard let imageForDelegate = mainImage.image else {
            dismiss(animated: true, completion: nil)
            return
        }
        delgate?.doneEditing(image: imageForDelegate)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func brush(_ sender: UIBarButtonItem) {
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
    /**
     Set up background image to be merged when the edits are complete
    */
    private func setUpImage() {
        mainImage.image = imageForMainImage
    }
    
    // MARK: Setup touch gestures
    @IBAction func tapGesture(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .recognized {
            // remove selection from tab bar when the user starts to scribble.
            tabBarSelectColor.selectedItem = nil
            print("Initial Touch Gesture")
        }
    }
    
    @IBAction func panGesture(_ gesture: UIPanGestureRecognizer) {
        
        let currentTouchLoc = gesture.location(in: editsForImage)
        
        if gesture.state == .began {
            oldTouchPoint = currentTouchLoc
        }
        
        if gesture.state != .ended {
            if oldTouchPoint != nil {
                drawLine(from: oldTouchPoint!, to: currentTouchLoc)
            }
        }
        
        oldTouchPoint = currentTouchLoc
    }
    
    // MARK: Draw line between two vertcies
    /**
     Connect two points using a line
     
     - parameters:
        - from: The starting point for line to be drawn
        - to: The ending point for line to be drawn
    */
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
    
    /**
     Merge two images together (bacground and foreground)
    */
    private func mergeImage() {
        let renderer = UIGraphicsImageRenderer(size: mainImage.frame.size)
        
        let img = renderer.image { ctx in
            let rectangle = CGRect(x: 0, y: 0, width: mainImage.frame.width, height: mainImage.frame.height)
            ctx.cgContext.addRect(rectangle)
            mainImage.image?.draw(in: rectangle)
            editsForImage.image?.draw(in: rectangle)
        }
        mainImage.image = img
    }
}

extension DrawOverImage: StoryboardInitializable {
    static var storyboardName: String {
        return "DrawOverImage"
    }
    
    static var storyboardSceneID: String {
        return "DrawOverImage"
    }
}
