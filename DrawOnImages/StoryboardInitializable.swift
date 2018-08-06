//
//  StoryboardInitializable.swift
//  cameraTest
//
//  Created by Jayant Arora on 3/2/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//
// swiftlint:disable trailing_whitespace

import Foundation
import UIKit

// MARK: - StoryboardInitializable

@objc
protocol StoryboardInitializable: class {
    static var storyboardName: String { get }
    static var storyboardSceneID: String { get }
}

// MARK: - Default Implementation

extension StoryboardInitializable where Self: UIViewController {
    static func fromStoryboard() -> Self {
        guard let viewController = containingStoryboard?
            .instantiateViewController(withIdentifier: storyboardSceneID) as? Self
        else { fatalError(
            "Something went wrong. Check to make sure the parameters are what you expect:\n\t" +
                "storyboardName: \(storyboardName)\n\t" +
                "storyboardID: \(storyboardSceneID)\n\t"
        )
        }
        return viewController
    }

    private static var containingStoryboard: UIStoryboard? {
        return UIStoryboard(name: storyboardName, bundle: nil)
    }
}
