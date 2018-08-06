//
//  TextFieldInfo.swift
//  DrawOnImages
//
//  Created by Jayant Arora on 3/20/18.
//  Copyright © 2018 Jayant Arora. All rights reserved.
//

import Foundation
import UIKit

struct TextFieldInfo {
    var frame: CGRect
    var text: String
    var textColor: UIColor = UIColor.black
}

extension TextFieldInfo: Hashable {
    var hashValue: Int {
        return frame.origin.x.hashValue ^ frame.origin.y.hashValue // &* 16777619
    }

    static func == (lhs: TextFieldInfo, rhs: TextFieldInfo) -> Bool {
        return lhs.frame == rhs.frame // && lhs.text == rhs.text
    }
}
