//
//  LogUtil.swift
//  SnapChat
//
//  Created by Chris Mendez on 3/7/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//
//  This is a smart logger than helps you quickly figure out
//    the Class().method()[line] and object you're referring to.
//    You can also include ./location/of/file.swift 

import Foundation

class LogUtil {
    static let sharedInstance = LogUtil()
    fileprivate init() {} //This prevents others from using the default '()' initializer for this class.
}

extension NSObject{
    func myLog<T>( _ object: T, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        let info = "\(type(of: self)).\(function)[\(line)]:\(object)"
        print(info)
    }
}

