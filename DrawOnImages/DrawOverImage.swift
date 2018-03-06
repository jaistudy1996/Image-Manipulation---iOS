//
//  DrawOverImage.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/1/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//
// swiftlint:disable trailing_whitespace

import UIKit
import ColorSlider

protocol DrawOverImageDelegate: class {
    func doneEditing(image: UIImage)
}

class DrawOverImage: UIViewController {
    
    // set this variable when instantiating this vc from some other vc
    weak var imageForMainImage: UIImage!
    lazy var strokeColor: UIColor = UIColor.black
    lazy var iPhoneColorSliderView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    
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
        self.tabBarSelectColor.delegate = self
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
            if UIDevice.current.userInterfaceIdiom == .phone {
                iPhoneColorSliderView.removeFromSuperview() // remove color selector when user taps on the screen
            }
            print("Initial Touch Gesture")
        }
    }
    
    @IBAction func panGesture(_ gesture: UIPanGestureRecognizer) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            iPhoneColorSliderView.removeFromSuperview() // remove color selector when user starts swiping on the screen
        }
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

        context?.setLineWidth(2)
        context?.setStrokeColor(strokeColor.cgColor)
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

// swiftlint:disable line_length
extension DrawOverImage: UITabBarDelegate, UIPopoverPresentationControllerDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("Change color selected")
        // the device is an iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ChangeColor") else {
                return
            }
            vc.modalPresentationStyle = .popover
            vc.preferredContentSize = CGSize(width: 220, height: 90)
            let popoverVC = vc.popoverPresentationController
            popoverVC?.permittedArrowDirections = .down
            popoverVC?.delegate = self
            popoverVC?.sourceView = tabBarSelectColor
            let colorSlider = ColorSlider(orientation: .horizontal, previewSide: .top)
            colorSlider.addTarget(self, action: #selector(changeDrawLineColor(_:)), for: .valueChanged)
            colorSlider.frame = CGRect(x: 10, y: 70, width: 200, height: 20)
            vc.view.addSubview(colorSlider)
            present(vc, animated: true, completion: nil)
        }
        
        // if the device is an iPhone
        if UIDevice.current.userInterfaceIdiom == .phone {
            // remove color slider view just in case it is already on the screeen
            iPhoneColorSliderView.removeFromSuperview()
            
            let tabBarFrame = tabBarSelectColor.frame
            let frame = CGRect(x: 10, y: tabBarFrame.origin.y - tabBarFrame.height, width: tabBarFrame.width - 40, height: tabBarFrame.height)
            iPhoneColorSliderView = UIView(frame: frame)
            
            // add colorSlider
            let colorSlider = ColorSlider(orientation: .horizontal, previewSide: .top)
            colorSlider.addTarget(self, action: #selector(changeDrawLineColor(_:)), for: .valueChanged)
            colorSlider.frame = CGRect(x: 10, y: 0, width: iPhoneColorSliderView.frame.width, height: 20)
            iPhoneColorSliderView.tag = 3 // Tag 3 is for the colorslider view.
            iPhoneColorSliderView.addSubview(colorSlider)
            self.view.addSubview(iPhoneColorSliderView)
        }
    }
    
    @objc func changeDrawLineColor(_ colorSlider: ColorSlider) {
        strokeColor = colorSlider.color
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
