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
    private init() {} //This prevents others from using the default '()' initializer for this class.
}

extension NSObject{
    func myLog<T>( object: T, _ file: String = __FILE__, _ function: String = __FUNCTION__, _ line: Int = __LINE__) {
        let info = "\(self.dynamicType).\(function)[\(line)]:\(object)"
        print(info)
    }
}

