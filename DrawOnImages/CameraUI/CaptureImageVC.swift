//
//  CaptureImageVC.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/1/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//
// swiftlint:disable trailing_whitespace

import Foundation
import UIKit

class CaptureImageVC: UIViewController {

    var imageForPreviewImage: UIImage? = nil
    @IBOutlet weak var previewImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let prevImage = imageForPreviewImage {
            setPreviewImage(prevImage)
        }
    }
    
    @IBOutlet weak var takeImage: UIButton!

    private var textEdits = [TextFieldInfo]()   // store all the edits made by the user
    
    @IBAction func openCamera(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            showNoCameraAvailableAlert()
            print("Camera not available")
        }
    }

    func editImage() {
        let drawOverImageVC = DrawOverImage.fromStoryboard()
        drawOverImageVC.delgate = self as DrawOverImageDelegate
        drawOverImageVC.imageForMainImage = previewImage.image
        drawOverImageVC.textFieldsInfo = textEdits
        self.present(UINavigationController(rootViewController: drawOverImageVC), animated: true, completion: nil)
    }

    func saveImage() {
        if previewImage.image != nil {
            UIImageWriteToSavedPhotosAlbum(previewImage.image!, self, #selector(alertImageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            return
        }
    }

}

extension CaptureImageVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {

        guard let capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        setPreviewImage(capturedImage)
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func setPreviewImage(_ imageToDisplay: UIImage) {
        previewImage.image = imageToDisplay

        textEdits.removeAll() // remove all textedits in case the user takes a new picture

        if takeImage != nil {
            takeImage.removeFromSuperview() // remove the take image button after setting the preview image
        }

        if imageForPreviewImage != nil {
            imageForPreviewImage = nil
        }

        for sub in previewImage.subviews {
            sub.removeFromSuperview()
        }

        addRetakeImageButtonToTabBar()
    }
    
    private func addRetakeImageButtonToTabBar() {
        let parent  = self.parent as? TakePicture
        parent?.addRetakeImageButtonToTabBar()
    }

    @objc func reopenCamera() {
        openCamera(UIButton(type: .system))
    }

    private func showNoCameraAvailableAlert() {
        let alertController = UIAlertController(title: "No Camera Available", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension CaptureImageVC: UINavigationControllerDelegate {
    
}

extension CaptureImageVC: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0 { // Tag 0 is for editing image
            let drawOverImageVC = DrawOverImage.fromStoryboard()
            drawOverImageVC.delgate = self as DrawOverImageDelegate
            drawOverImageVC.imageForMainImage = previewImage.image
            drawOverImageVC.textFieldsInfo = textEdits
//            UINavigationController(rootViewController: drawOverImageVC)
            self.present(UINavigationController(rootViewController: drawOverImageVC), animated: true, completion: nil)
        }
        if item.tag == 1 { // trigger for save image
            if previewImage.image != nil {
                UIImageWriteToSavedPhotosAlbum(previewImage.image!, self, #selector(alertImageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
            } else {
                return
            }
        }
        if item.tag == 2 { // retake image
            openCamera(UIButton(type: .system)) // just a temp button to send to openCamera function
        }
    }
    
    @objc func alertImageSaved(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            let alertVC = UIAlertController(title: "Error saving image", message: nil, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alertVC, animated: true, completion: nil)
        } else {
            let alertVC = UIAlertController(title: "Image Saved", message: nil, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            present(alertVC, animated: true, completion: nil)
//            tabBar.selectedItem = nil
        }
    }
}

extension CaptureImageVC: DrawOverImageDelegate {
    func doneEditing(image: UIImage, textEdits: [TextFieldInfo]) {
        previewImage.image = image
        addTextFieldsToImage(textEdits: textEdits)
    }

    private func addTextFieldsToImage(textEdits: [TextFieldInfo]) {
        self.textEdits = textEdits
        for textEdit in textEdits {
            let textfield = UITextField(frame: textEdit.frame)
            textfield.text = textEdit.text
            textfield.textColor = textEdit.textColor
            previewImage.addSubview(textfield)
        }
    }

}
