//
//  CaptureImageVC.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/1/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//

import Foundation
import UIKit

class CaptureImageVC: UIViewController {
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var previewImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
    }
    
    @IBAction func openCamera(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        if ( UIImagePickerController.isSourceTypeAvailable(.camera) ){
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            // TODO: Add some sort of warning if the camera is not available
            print("Camera not available")
        }
    }
}

extension CaptureImageVC: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // TODO: Change force cast of image
        setPreviewImage(info[UIImagePickerControllerOriginalImage] as! UIImage)
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func setPreviewImage(_ imageToDisplay: UIImage) {
        previewImage.image = imageToDisplay
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension CaptureImageVC: UINavigationControllerDelegate {
    
}

extension CaptureImageVC: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if (item.tag == 0) { // Tag 0 is for editing image
            let drawOverImageVC = DrawOverImage.fromStoryboard()
            drawOverImageVC.delgate = self as DrawOverImageDelegate
            drawOverImageVC.imageForMainImage = previewImage.image
            self.present(drawOverImageVC, animated: true, completion: nil)
        }
    }
}

extension CaptureImageVC: DrawOverImageDelegate {
    func doneEditing(image: UIImage) {
        previewImage.image = image
    }
}

