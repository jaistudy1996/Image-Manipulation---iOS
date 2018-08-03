//
//  DrawOverImage.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/1/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//

import UIKit
import ColorSlider

protocol DrawOverImageDelegate: class {
    func doneEditing(image: UIImage, textEdits: [TextFieldInfo])
}

class DrawOverImage: UIViewController {

    // MARK: Properties

    // current editing text field
    var currentTextField: UITextField?

    // set this variable when instantiating this vc from some other vc
    lazy var strokeColor: UIColor = UIColor.black
    lazy var textColor: UIColor = UIColor.black
    lazy var iPhoneColorSliderView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    weak var imageForMainImage: UIImage!
    weak var toolBar: UIToolbar!
    weak var delgate: DrawOverImageDelegate?
    var textFieldsInfo = [TextFieldInfo]()
    var oldTouchPoint: CGPoint? // the last time when the screen was touch

    // MARK: Outlets

    // scroll view
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var editsForImage: UIImageView!
    @IBOutlet weak var mainImage: UIImageView!

    // MARK: Actions

    @IBAction func doneEditing(_ sender: UIBarButtonItem) {
        
        // Merge two images before exiting view controller
        // only merge if there is a background image
        if mainImage.image != nil {
            mergeImage()
        }
        editsForImage = nil // free unnecessary memory usage.
        guard let imageForDelegate = mainImage.image else {
            dismiss(animated: true, completion: nil)
            return
        }
        delgate?.doneEditing(image: imageForDelegate, textEdits: textFieldsInfo)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Public Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpImage()
        self.toolBar = self.navigationController?.toolbar
        self.navigationController?.setToolbarHidden(false, animated: true)
        startObservingNotifications()
    }

    deinit {
        stopObservingNotifications()
    }

    // MARK: Setup Initial image

    /// Set up background image to be merged when the edits are complete
    /// Also add text sub views if they exist
    private func setUpImage() {
        mainImage.image = imageForMainImage

        imageForMainImage = nil // dealloc imageformainimage
        for textEdit in textFieldsInfo {
            let textfield = UITextField(frame: textEdit.frame)
            textfield.text = textEdit.text
            textfield.textColor = textEdit.textColor
            editsForImage.addSubview(textfield)
        }

    }
    
    // MARK: Setup touch gestures
    @IBAction func tapGesture(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .recognized {
            // remove selection from tab bar when the user starts to scribble.
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

        switch gesture.state {
        case .began:
            oldTouchPoint = currentTouchLoc
        case .ended:
            if oldTouchPoint != nil {
                drawLine(from: oldTouchPoint!, to: currentTouchLoc)
            }
        default:
            break
        }
        oldTouchPoint = currentTouchLoc
    }
    
    // MARK: Draw line between two vertcies

    /// Connect two points using a line
    ///
    /// - Parameters:
    ///   - from: The starting point for line to be draw
    ///   - toPoint: The ending point for line to be drawn
    private func drawLine(from: CGPoint, to toPoint: CGPoint) {
        let size = editsForImage.frame.size
        // Start new image context
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        editsForImage.image?.draw(at: CGPoint(x: 0, y: 0))
        context?.setLineWidth(2)
        context?.setStrokeColor(strokeColor.cgColor)
        context?.setLineCap(.round)
        context?.move(to: from)
        context?.addLine(to: toPoint)
        context?.strokePath()
        editsForImage.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    // MARK: Image editing utility methods

    /// Merge two images together (bacground and foreground)
    private func mergeImage() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = mainImage.contentScaleFactor // to keep the scale factor
        let renderer = UIGraphicsImageRenderer(size: mainImage.bounds.size, format: format)
        
        let img = renderer.image { ctx in
            let rectangle = CGRect(x: 0, y: 0, width: mainImage.bounds.width, height: mainImage.bounds.height)
            ctx.cgContext.addRect(rectangle)
            mainImage.image?.draw(in: rectangle)
            editsForImage.image?.draw(in: rectangle)
        }
        mainImage.image = img
    }

    /// Add text fields on touch
    private func addSmallView(loc: CGPoint) {
        let xCord = loc.x - 20
        let yCord = loc.y - 20
        let textfield = UITextField(frame: CGRect(origin: CGPoint(x: xCord, y: yCord),
                                                  size: CGSize(width: 64, height: 44)))
        textfield.delegate = self
        textfield.textColor = textColor
        editsForImage.addSubview(textfield)
        textfield.becomeFirstResponder() // make this first responder in order to show keyboard and let the user type
        currentTextField = textfield // set current to the one being edited
    }

    @objc func insetTextFieldOnKeyboardAppear(notification: Notification) {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        mainScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame?.height ?? 0, right: 0)

        if currentTextField?.frame != nil {
            mainScrollView.scrollRectToVisible(currentTextField!.frame, animated: true)
        }
    }

    @objc func resetScrolledViewOnKeyboardHide(notification: Notification) {
        UIView.animate(withDuration: 0.2, animations: ({
            self.mainScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }), completion: nil)

        mainScrollView.scrollRectToVisible(mainScrollView.frame, animated: true)
    }

    // MARK: Notifications
    private func startObservingNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.insetTextFieldOnKeyboardAppear),
                                               name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetScrolledViewOnKeyboardHide),
                                               name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }

    private func stopObservingNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }

}

extension DrawOverImage: UIPopoverPresentationControllerDelegate {

    @IBAction func colorSelect(_ sender: UIBarButtonItem) {
        print("Change color selected")
        // the device is an iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let changeColorvc = self.storyboard?.instantiateViewController(withIdentifier: "ChangeColor") else {
                return
            }
            changeColorvc.modalPresentationStyle = .popover
            changeColorvc.preferredContentSize = CGSize(width: 220, height: 90)
            let popoverVC = changeColorvc.popoverPresentationController
            popoverVC?.permittedArrowDirections = .down
            popoverVC?.delegate = self
            popoverVC?.sourceView = toolBar
            let colorSlider = ColorSlider(orientation: .horizontal, previewSide: .top)
            colorSlider.addTarget(self, action: #selector(changeDrawLineColor(_:)), for: .valueChanged)
            colorSlider.frame = CGRect(x: 10, y: 70, width: 200, height: 20)
            changeColorvc.view.addSubview(colorSlider)
            present(changeColorvc, animated: true, completion: nil)
        }

        // if the device is an iPhone
        if UIDevice.current.userInterfaceIdiom == .phone {
            if iPhoneColorSliderView.superview != nil {
                // remove color slider view just in case it is already on the screeen
                iPhoneColorSliderView.removeFromSuperview()
            } else {
                let toolbarFrame = toolBar.frame
                let frame = CGRect(x: 10, y: toolbarFrame.origin.y - 100,
                                   width: toolbarFrame.width - 40, height: toolbarFrame.height)
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
    }

    @objc private func changeDrawLineColor(_ colorSlider: ColorSlider) {
        strokeColor = colorSlider.color
        textColor = colorSlider.color
    }

}

extension DrawOverImage: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        currentTextField = nil // remove any current textfield
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        let tempField = TextFieldInfo(frame: textField.frame, text: textField.text!, textColor: self.textColor)
        if let index = textFieldsInfo.index(of: tempField) {
            print("Index at: \(index)")
            if let newText = textField.text {
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

extension DrawOverImage: StoryboardInitializable {

    static var storyboardName: String {
        return "DrawOverImage"
    }

    static var storyboardSceneID: String {
        return "DrawOverImage"
    }

}
