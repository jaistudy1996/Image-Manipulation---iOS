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

struct TextFieldInfo {
    var frame: CGRect
    var text: String
}

extension TextFieldInfo: Hashable {
    var hashValue: Int {
        return frame.origin.x.hashValue ^ frame.origin.y.hashValue //&* 16777619
    }

    static func ==(lhs: TextFieldInfo, rhs: TextFieldInfo) -> Bool {
        return lhs.frame == rhs.frame// && lhs.text == rhs.text
    }
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

    private var textFieldsInfo = [TextFieldInfo]()
    
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
            print("Initial Touch Gesture at: \(gesture.location(in: editsForImage))")
            addSmallView(loc: gesture.location(in: editsForImage))
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
//        mergeTextFields()
        let renderer = UIGraphicsImageRenderer(size: mainImage.frame.size)
        
        let img = renderer.image { ctx in
            let rectangle = CGRect(x: 0, y: 0, width: mainImage.frame.width, height: mainImage.frame.height)
            ctx.cgContext.addRect(rectangle)
            mainImage.image?.draw(in: rectangle)
            editsForImage.image?.draw(in: rectangle)
            for case let view as UITextField in editsForImage.subviews {
                let text = view.text!
                text.draw(with: rectangle, options: .usesLineFragmentOrigin, attributes: nil, context: nil)
            }

//            let paragraphStyle = NSMutableParagraphStyle()
//            paragraphStyle.alignment = .center
//
//            let attrs = [NSAttributedStringKey.font: UIFont(name: "HelveticaNeue-Thin", size: 36)!, NSAttributedStringKey.paragraphStyle: paragraphStyle]

//            let string = "How much wood would a woodchuck\nchuck if a woodchuck would chuck wood?"
//            string.draw(with: CGRect(x: 32, y: 32, width: 448, height: 448), options: .usesLineFragmentOrigin, attributes: nil, context: nil) // .usesLineFragmentOrigin, attributes: attrs, context: nil)
        }
        mainImage.image = img
    }

    private func addSmallView(loc: CGPoint) {
        let x = loc.x - 20
        let y = loc.y - 20
        let textfield = UITextField(frame: CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: 100, height: 100)))
        textfield.delegate = self
        editsForImage.addSubview(textfield)
    }

    private func mergeTextFields() {
        let renderer = UIGraphicsImageRenderer(size: editsForImage.frame.size)

        let img = renderer.image { ctx in
            let rectangle = CGRect(x: 0, y: 0, width: mainImage.frame.width, height: mainImage.frame.height)
            for view in editsForImage.subviews {
                view.draw(rectangle)
            }
        }
        editsForImage.image = img
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

extension DrawOverImage: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        let tempField = TextFieldInfo(frame: textField.frame, text: textField.text!)
        if let index = textFieldsInfo.index(of: tempField) {
            print("Index at: \(index)")
            if let newText = textField.text{
                if newText == "" {
                    textField.removeFromSuperview() // remove textfield if it has an empty string
                    textFieldsInfo.remove(at: index)
                } else {
                    textFieldsInfo[index].text = newText
                }
            } else {
                textField.removeFromSuperview() // remove the textfield if it is empty
                textFieldsInfo.remove(at: index)
            }
        } else {
            textFieldsInfo.append(tempField)
        }
    }
}
