//
//  FileInfoOptions.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 15/03/15.
//  Copyright (c) 2015 Dominik Pich. All rights reserved.
//

import Foundation

struct FileInfoOptions : OptionSet {
    let rawValue : Int
    static let GIT = FileInfoOptions(rawValue: 1 << 0)
    static let LOCAL = FileInfoOptions(rawValue: 1 << 2)
}
