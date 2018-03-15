//
//  TakePictures.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/1/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//
// swiftlint:disable trailing_whitespace

import Foundation
import UIKit

class TakePicture: UIPageViewController {

    var currentPage: Int = 0

    private lazy var retakeButton: UIBarButtonItem = {
        let retakeImage = UIBarButtonItem(image: #imageLiteral(resourceName: "rubbish-bin"), style: .plain, target: self, action: #selector(reopenCamera))
        return retakeImage
    }()
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.newImageCaptureViewController(identifier: "CaptureImageViewController")]
    }()

    private func newImageCaptureViewController(identifier: String) -> UIViewController {
        return UIStoryboard(name: "TakePictures", bundle: nil) .
            instantiateViewController(withIdentifier: "CaptureImageViewController")
    }

    var pageControl = UIPageControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: false, completion: nil)
        }
        configurePageControl(currentPageNumber: 0, totalNumberofPages: orderedViewControllers.count)
    }
    override func didReceiveMemoryWarning() {
        print("Memory warning -- TakePictures")
    }
    
    private func createViewController() -> UIViewController? {
        guard let newVC = self.storyboard?.instantiateViewController(withIdentifier: "CaptureImageViewController") else {
            return nil
        }
        return newVC
    }
    
    /**
     Generate view controller when the user swipes and goes on to the next page.
     
     - returns: Index of added View Controller in the stack on arrays
     
     Will create a new view controller if total available are upto 5 in memory..
     otherwise will resuse an previously generated view controller
     
     - Important: Not yet used in code
    */
    private func generateNewVConSwipe() -> Int? {
        if orderedViewControllers.count <= 5 {
            let generatedViewIndex = orderedViewControllers.count
            // Make a new view controller and add it to orderedViewController
            guard let newController = createViewController() else {
                return nil
            }
            orderedViewControllers.append(newController)
            return generatedViewIndex
        } else {
            // Reuse one of the previously generated view controllers
            return 1 // TODO: work on this func
        }
    }

    @IBAction func editImage(_ sender: UIBarButtonItem) {
        if let vc = orderedViewControllers[self.currentPage] as? CaptureImageVC {
            vc.editImage()
        }
    }

    @IBAction func saveImage(_ sender: UIBarButtonItem) {
        if let vc = orderedViewControllers[self.currentPage] as? CaptureImageVC {
            vc.saveImage()
        }
    }

    @IBAction func addNewPicture(_ sender: UIBarButtonItem) {
        // open camera to take a new picture
        // must be a new controller otherwise the first view will not be used
        guard orderedViewControllers.count > 1 else {
            (orderedViewControllers.first as? CaptureImageVC)?.openCamera(UIButton()) // just to invoke the method
            return
        }
        self.openCamera()
    }

    private func openCamera() {
        let imagePickerController = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate

            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            //showNoCameraAvailableAlert()
            // TODO: create a file with all these utility functions
            print("Camera not available")
        }
    }

    func addRetakeImageButtonToTabBar() {
        if let toolbarItems = toolbarItems,
            toolbarItems.contains(retakeButton) {

        } else {
            self.toolbarItems?.append(retakeButton)
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
            self.toolbarItems?.append(flexibleSpace)
        }
    }

    @objc func reopenCamera() {
        if let vc = orderedViewControllers[self.currentPage] as? CaptureImageVC {
            vc.reopenCamera()
        }
    }

}

extension TakePicture: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }

        let prevIndex = viewControllerIndex - 1
        guard prevIndex >= 0 else { return nil }
        
        guard orderedViewControllers.count > prevIndex else { return nil }
        return orderedViewControllers[prevIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {

        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }
        
        let nextIndex = viewControllerIndex + 1
        guard nextIndex != orderedViewControllers.count else { return nil }

        guard orderedViewControllers.count > nextIndex else { return nil }
        
        return orderedViewControllers[nextIndex]
    }
    
//    func presentationCount(for pageViewController: UIPageViewController) -> Int {
//        return orderedViewControllers.count - 1
//    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let vcIndex = orderedViewControllers.index(of: pageViewController) else {
            return 0
        }
        return vcIndex
    }
}

extension TakePicture: UIPageViewControllerDelegate {
    func configurePageControl(currentPageNumber: Int, totalNumberofPages: Int) {
        
        if self.view.subviews.index(of: pageControl) != nil  {
            // remove and add page control again when a new view needs to be added
            pageControl.removeFromSuperview()
        }
        
        // The total number of pages that are available is based on how many available colors we have.
        pageControl = UIPageControl(frame: CGRect(x: 0, y: UIScreen.main.bounds.maxY - 70, width: UIScreen.main.bounds.width, height: 10))
        self.pageControl.numberOfPages = totalNumberofPages // increase number by 1 to hint user that there is something on the next page
        self.pageControl.currentPage = currentPageNumber
        self.pageControl.tintColor = UIColor.black
        self.pageControl.pageIndicatorTintColor = UIColor.white
        self.pageControl.currentPageIndicatorTintColor = UIColor.black
        self.pageControl.backgroundColor = UIColor.clear
        self.view.addSubview(pageControl)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.currentPage = orderedViewControllers.index(of: pageContentViewController)!
        self.pageControl.currentPage = self.currentPage

        // add retake image button again
        if let vc = self.orderedViewControllers[self.currentPage] as? CaptureImageVC {
            if vc.takeImage == nil {
                self.addRetakeImageButtonToTabBar()
            }
        }
    }
}

extension TakePicture: UINavigationControllerDelegate {
    // for imagepickerveiewdelegate only
}

extension TakePicture: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        guard let newController = createViewController() else {
            let alert = UIAlertController(title: "Error", message: "Cannot add new Image!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            return
        }
        orderedViewControllers.append(newController)

        guard let captureController = newController as? CaptureImageVC else {
            return
        }

        guard let capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }

        captureController.imageForPreviewImage = capturedImage // set image for new controller
        picker.dismiss(animated: true, completion: nil)

        // update current page
        self.currentPage = orderedViewControllers.count - 1
        // present new controller
        setViewControllers([orderedViewControllers.last!], direction: .forward, animated: true, completion: nil)
    }
}
