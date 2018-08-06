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

class CaptureImageViewController: UIViewController {
    // MARK: Outlets

    @IBOutlet var previewImage: UIImageView!
    @IBOutlet var takeImage: UIButton!

    // MARK: Properties

    var imageForPreviewImage: UIImage?
    private var textEdits = [TextFieldInfo]() // store all the edits made by the user

    override func viewDidLoad() {
        super.viewDidLoad()

        if let prevImage = imageForPreviewImage {
            setPreviewImage(prevImage)
        }
    }

    // MARK: Outlet actions

    @IBAction func openCamera(_: UIButton) {
        let imagePickerController = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self

            present(imagePickerController, animated: true, completion: nil)
        } else {
            showNoCameraAvailableAlert()
            print("Camera not available")
        }
    }

    // MARK: Actions for toolbar buttons

    func editImage() {
        let drawOverImageVC = DrawOverImage.fromStoryboard()
        drawOverImageVC.delgate = self as DrawOverImageDelegate
        drawOverImageVC.imageForMainImage = previewImage.image
        drawOverImageVC.textFieldsInfo = textEdits
        present(UINavigationController(rootViewController: drawOverImageVC), animated: true, completion: nil)
    }

    func deleteImage() {
        if previewImage.image != nil {
            previewImage.image = nil
            takeImage.isHidden = false

            // remove all textfields on delete button
            for case let textField as UITextField in previewImage.subviews {
                textField.removeFromSuperview()
            }

            if let parent = self.parent as? TakePicturePageViewController {
                parent.deleteButton.isEnabled = false
                parent.editButton.isEnabled = false
                parent.saveButton.isEnabled = false
            }
        }
    }

    func saveImage() {
        if previewImage.image != nil {
            UIImageWriteToSavedPhotosAlbum(previewImage.image!, self,
                                           #selector(alertImageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            return
        }
    }

    @objc func alertImageSaved(_: UIImage, didFinishSavingWithError error: NSError?,
                               contextInfo _: UnsafeRawPointer) {
        if error != nil {
            let alertVC = UIAlertController(title: "Error saving image", message: nil, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alertVC, animated: true, completion: nil)
        } else {
            let alertVC = UIAlertController(title: "Image Saved", message: nil, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            present(alertVC, animated: true, completion: nil)
        }
    }
}

extension CaptureImageViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        guard let capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        setPreviewImage(capturedImage)
        picker.dismiss(animated: true) {
            if let parent = self.parent as? TakePicturePageViewController {
                parent.editImage(UIBarButtonItem())
            }
        }
    }

    private func setPreviewImage(_ imageToDisplay: UIImage) {
        previewImage.image = imageToDisplay

        textEdits.removeAll() // remove all textedits in case the user takes a new picture

        if takeImage.isHidden == false {
            takeImage.isHidden = true
        }

        if imageForPreviewImage != nil {
            imageForPreviewImage = nil
        }

        for sub in previewImage.subviews {
            sub.removeFromSuperview()
        }

        if let parent = self.parent as? TakePicturePageViewController {
            parent.deleteButton.isEnabled = true
            parent.editButton.isEnabled = true
            parent.saveButton.isEnabled = true
        }
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

extension CaptureImageViewController: UINavigationControllerDelegate {
}

extension CaptureImageViewController: DrawOverImageDelegate {
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

extension CaptureImageViewController: StoryboardInitializable {
    static var storyboardName: String {
        return "TakePictures"
    }

    static var storyboardSceneID: String {
        return "CaptureImageViewController"
    }
}
