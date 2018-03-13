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
    func doneEditing(image: UIImage, textEdits: [TextFieldInfo])
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

    // scroll view
    @IBOutlet weak var mainScrollView: UIScrollView!

    // current editing text field
    var currentTextField: UITextField? = nil

    // set this variable when instantiating this vc from some other vc
    weak var imageForMainImage: UIImage!
    lazy var strokeColor: UIColor = UIColor.black
    lazy var iPhoneColorSliderView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    weak var toolBar: UIToolbar!
    
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
        delgate?.doneEditing(image: imageForDelegate, textEdits: textFieldsInfo)
        // TODO: remove observers
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func brush(_ sender: UIBarButtonItem) {
        print("Brush Selected")
    }
    
    @IBOutlet weak var mainImage: UIImageView!

    var textFieldsInfo = [TextFieldInfo]()
    
    var oldTouchPoint: CGPoint? // the last time when the screen was touch
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpImage()
//        self.tabBarSelectColor.delegate = self
        self.toolBar = self.navigationController?.toolbar
        self.navigationController?.setToolbarHidden(false, animated: true)

        NotificationCenter.default.addObserver(self, selector: #selector(self.insetTextFieldOnKeyboardAppear), name:  NSNotification.Name.UIKeyboardDidShow, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.resetScrolledViewOnKeyboardHide), name:  NSNotification.Name.UIKeyboardDidHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory Warning -- DrawOverImageView")
    }

//    override func viewDidAppear(_ animated: Bool) {
//        mainScrollView.scrollRectToVisible(mainScrollView.frame, animated: true)
//    }

    // MARK: Setup Initial image
    /**
     Set up background image to be merged when the edits are complete
     Also add text sub views if they exist
    */
    private func setUpImage() {
        mainImage.image = imageForMainImage
        imageForMainImage = nil // dealloc imageformainimage
        for textEdit in textFieldsInfo {
            let textfield = UITextField(frame: textEdit.frame)
            textfield.text = textEdit.text
            editsForImage.addSubview(textfield)
        }
    }
    
    // MARK: Setup touch gestures
    @IBAction func tapGesture(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .recognized {
            // remove selection from tab bar when the user starts to scribble.
//            tabBarSelectColor.selectedItem = nil
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
        }
        mainImage.image = img
    }

    private func addSmallView(loc: CGPoint) {
        let x = loc.x - 20
        let y = loc.y - 20
        let textfield = UITextField(frame: CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: 100, height: 100)))
        textfield.delegate = self
        editsForImage.addSubview(textfield)
        textfield.becomeFirstResponder() // make this first responder in order to show keyboard and let the user type
        currentTextField = textfield // set current to the one being edited
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

    @objc func insetTextFieldOnKeyboardAppear(notification: Notification) {
        print(notification)
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        mainScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame?.height ?? 0, right: 0)

        if let _ = currentTextField?.frame {
            mainScrollView.scrollRectToVisible(currentTextField!.frame, animated: true)
        }
    }

    @objc func resetScrolledViewOnKeyboardHide(notification: Notification) {

        UIView.animate(withDuration: 0.2, animations: ({
            self.mainScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }), completion: nil)

        mainScrollView.scrollRectToVisible(mainScrollView.frame, animated: true)

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
extension DrawOverImage: UIPopoverPresentationControllerDelegate {

    @IBAction func colorSelect(_ sender: UIBarButtonItem) {
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
//            popoverVC?.sourceView = tabBarSelectColor
            popoverVC?.sourceView = toolBar
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

//            let tabBarFrame = tabBarSelectColor.frame
            let toolbarFrame = toolBar.frame
            let frame = CGRect(x: 10, y: toolbarFrame.origin.y - toolbarFrame.height, width: toolbarFrame.width - 40, height: toolbarFrame.height)
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
}

extension DrawOverImage: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        self.currentTextField = nil // remove any current textfield
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
