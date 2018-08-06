//
//  TakePictures.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/1/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//

import Foundation
import UIKit

class TakePicturePageViewController: UIPageViewController {

    // MARK: Properties
    var currentPage: Int = 0
    var pageControl = UIPageControl()

    // MARK: Private properties
    private var orderedViewControllers: [UIViewController] = {
        return [CaptureImageViewController.fromStoryboard()]
    }()

    // MARK: Outlets
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: false, completion: nil)
        }
        configurePageControl(currentPageNumber: 0, totalNumberofPages: orderedViewControllers.count)
        deleteButton.isEnabled = false
        saveButton.isEnabled = false
        editButton.isEnabled = false
    }

    // MARK: IBActions

    @IBAction func deleteImage(_ sender: UIBarButtonItem) {
        guard orderedViewControllers.count > 1 else {
            let capVC = orderedViewControllers[self.currentPage] as? CaptureImageViewController
            capVC?.deleteImage()
            return
        }
        orderedViewControllers.remove(at: self.currentPage)
        self.currentPage = orderedViewControllers.count - 1 // reset currentpage

        // set current page to last one
        setViewControllers([orderedViewControllers[self.currentPage]],
                           direction: .reverse, animated: true, completion: nil)

        // update page control
        configurePageControl(currentPageNumber: self.currentPage, totalNumberofPages: orderedViewControllers.count)
    }

    @IBAction func editImage(_ sender: UIBarButtonItem) {
        if let vc = orderedViewControllers[self.currentPage] as? CaptureImageViewController {
            vc.editImage()
        }
    }

    @IBAction func saveImage(_ sender: UIBarButtonItem) {
        if let vc = orderedViewControllers[self.currentPage] as? CaptureImageViewController {
            vc.saveImage()
        }
    }

    @IBAction func addNewPicture(_ sender: UIBarButtonItem) {
        // open camera to take a new picture
        // must be a new controller otherwise the first view will not be used
        guard let captureController =  orderedViewControllers[currentPage] as? CaptureImageViewController,
            captureController.previewImage.image != nil
        else { return }
        openCamera()
    }

    // MARK: Private functions
    private func openCamera() {
        let imagePickerController = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            showNoCameraAlert()
            print("Camera not available")
        }
    }

    private func showNoCameraAlert() {
        let alertView = UIAlertController(title: "No Camera Available",
                                          message: "Camera permissions are needed for this application to work",
                                          preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "dismiss", style: .cancel, handler: nil)
        alertView.addAction(alertAction)
    }

}

// MARK: PageViewController DataSource
extension TakePicturePageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }

        let prevIndex = viewControllerIndex - 1
        guard prevIndex >= 0,
            orderedViewControllers.count > prevIndex
        else { return nil }

        return orderedViewControllers[prevIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {

        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }
        
        let nextIndex = viewControllerIndex + 1
        guard nextIndex != orderedViewControllers.count,
            orderedViewControllers.count > nextIndex
            else { return nil }

        return orderedViewControllers[nextIndex]
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.index(of: pageViewController) ?? 0
    }

}

extension TakePicturePageViewController: UIPageViewControllerDelegate {

    func configurePageControl(currentPageNumber: Int, totalNumberofPages: Int) {
        
        if self.view.subviews.index(of: pageControl) != nil {
            // remove and add page control again when a new view needs to be added
            pageControl.removeFromSuperview()
        }
        
        // y value is set to starting point of tool bar - height of tool bar
        let yCord = CGFloat((self.navigationController?.toolbar.frame.origin.y)! - 90)
        pageControl = UIPageControl(frame: CGRect(x: 0, y: yCord,
                                                  width: UIScreen.main.bounds.width, height: 30))
        pageControl.numberOfPages = totalNumberofPages

        pageControl.currentPage = currentPageNumber
        pageControl.tintColor = UIColor.black
        pageControl.pageIndicatorTintColor = UIColor.white
        pageControl.currentPageIndicatorTintColor = UIColor.black
        pageControl.backgroundColor = UIColor.clear
        pageControl.hidesForSinglePage = true

        // handle when the user clicks the dots itself
        pageControl.addTarget(self, action: #selector(pageControlDotClicked(page:)), for: .valueChanged)

        self.view.addSubview(pageControl)
    }

    @objc func pageControlDotClicked(page: Int) {
        setViewControllers([orderedViewControllers[pageControl.currentPage]],
                           direction: .forward, animated: false, completion: nil)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.currentPage = orderedViewControllers.index(of: pageContentViewController)!
        self.pageControl.currentPage = self.currentPage

        // add delete image button again
        if let vc = self.orderedViewControllers[self.currentPage] as? CaptureImageViewController {
            if vc.takeImage.isHidden == true {
                // Enable delete button - required only first time
                deleteButton.isEnabled = true
            }
        }
        configurePageControl(currentPageNumber: self.currentPage, totalNumberofPages: orderedViewControllers.count)
    }

}

extension TakePicturePageViewController: UINavigationControllerDelegate {}

extension TakePicturePageViewController: UIImagePickerControllerDelegate {

    // this delegate funciton is invoked when the user tries to take the second picture
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {

        let captureController = CaptureImageViewController.fromStoryboard()
        orderedViewControllers.append(captureController)

        guard let capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            picker.dismiss(animated: true, completion: nil)
            return
        }

        picker.dismiss(animated: true, completion: nil)

        captureController.imageForPreviewImage = capturedImage // set image for new controller
        deleteButton.isEnabled = true
        saveButton.isEnabled = true
        editButton.isEnabled = true

        // update current page
        currentPage = orderedViewControllers.count - 1
        // present new controller
        setViewControllers([orderedViewControllers.last!], direction: .forward, animated: true, completion: nil)
        // update page control
        configurePageControl(currentPageNumber: currentPage, totalNumberofPages: orderedViewControllers.count)

        editImage(UIBarButtonItem())
    }

}

///**
// Generate view controller when the user swipes and goes on to the next page.
//
// - returns: Index of added View Controller in the stack on arrays
//
// Will create a new view controller if total available are upto 5 in memory..
// otherwise will resuse an previously generated view controller
//
// - Important: Not yet used in code
// */
//private func generateNewVConSwipe() -> Int? {
//    if orderedViewControllers.count <= 5 {
//        let generatedViewIndex = orderedViewControllers.count
//        // Make a new view controller and add it to orderedViewController
//        guard let newController = createViewController() else {
//            return nil
//        }
//        orderedViewControllers.append(newController)
//        return generatedViewIndex
//    } else {
//        // Reuse one of the previously generated view controllers
//        return 1 // TODO: work on this func
//    }
//}
