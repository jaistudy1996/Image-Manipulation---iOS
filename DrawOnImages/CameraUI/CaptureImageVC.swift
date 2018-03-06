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
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var previewImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
    }
    
    @IBOutlet weak var takeImage: UIButton!
    
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
}

extension CaptureImageVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {

        guard let capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        setPreviewImage(capturedImage)
        tabBar.selectedItem = nil // after taking the picture set selected item as nil
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func setPreviewImage(_ imageToDisplay: UIImage) {
        previewImage.image = imageToDisplay
        if takeImage != nil {
            takeImage.removeFromSuperview() // remove the take image button after setting the preview image
        }
        addRetakeImageButtonToTabBar()
    }
    
    private func addRetakeImageButtonToTabBar() {
        if (tabBar.items?.count)! < 3 {
            let retakeImage = UITabBarItem(title: "Retake", image: #imageLiteral(resourceName: "retakeImage"), tag: 2)
            tabBar.items?.append(retakeImage)
        } else {
            return
        }
    }
    
    private func showNoCameraAvailableAlert() {
        let alertController = UIAlertController(title: "No Camera Available", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        tabBar.selectedItem = nil // if the user clicks cancel remove the currently selected button
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
            self.present(drawOverImageVC, animated: true, completion: nil)
        }
        if item.tag == 1 { // trigger for save image
            if previewImage.image != nil {
                UIImageWriteToSavedPhotosAlbum(previewImage.image!, nil, nil, nil)
            } else {
                return
            }
        }
        if item.tag == 2 { // retake image
            openCamera(UIButton(type: .system)) // just a temp button to send to openCamera function
        }
    }
}

extension CaptureImageVC: DrawOverImageDelegate {
    func doneEditing(image: UIImage) {
        previewImage.image = image
    }
}
