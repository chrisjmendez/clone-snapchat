//
//  AlertUtil.swift
//  SnapChat
//
//  Created by Chris on 1/28/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//
//  This approach makes it simpler for me to swap out different types of 
//    Alert libraries.
//
//     //https://github.com/stakes/JSSAlertView/blob/master/JSSAlertViewExample/JSSAlertViewExample/ViewController.swift

import UIKit
import Async
import MBProgressHUD

protocol AlertUtilDelegate{
    func didFinish()
}

enum AlertUtilType:Int {
    case error   = 0
    case success = 1
}

class AlertUtil {
    
    static let sharedInstance = AlertUtil()
    fileprivate init(){}

    var delegate:AlertUtilDelegate?
    
    func onTap(){
        delegate?.didFinish()
    }
    
    func show(_ type:AlertUtilType , title:String, message:String, sender:UIViewController){
        switch(type){
            case AlertUtilType.success:
                let alert = JSSAlertView().success(sender, title: title, text: message)
                    alert.addAction(onTap)
                break
            case AlertUtilType.error:
                let alert = JSSAlertView().danger(sender, title: title, text: message)
                    alert.addAction(onTap)
                break
            }
    }
}


class ActivityUtil {
    
    static let sharedInstance = ActivityUtil()
    fileprivate init(){}
    
    var activityMonitor:MBProgressHUD?

    func hideLoader(_ view:UIView){
        Async.main{ () -> Void in
            MBProgressHUD.hideAllHUDs(for: view, animated: true)
        }
    }
    
    func updateLoader(_ progress:Float){
        self.activityMonitor!.progress = progress
    }
    
    func showProgressLoader(_ view:UIView){
        Async.main {
            self.activityMonitor = MBProgressHUD.showAdded(to: view, animated: true)
            self.activityMonitor!.labelText = "Uploading"
            self.activityMonitor!.detailsLabelText = ""
            self.activityMonitor!.show(true)
            self.activityMonitor!.mode = MBProgressHUDMode.annularDeterminate
            view.addSubview(self.activityMonitor!)
        }
    }
    
    
    func showLoader(_ view:UIView, label:String="Loading", message:String="Updating"){
        Async.main{
           self.activityMonitor = MBProgressHUD.showAdded(to: view, animated: true)
           self.activityMonitor!.labelText = label
           self.activityMonitor!.detailsLabelText = message
           self.activityMonitor!.show(true)
           self.activityMonitor!.mode = .indeterminate
           view.addSubview(self.activityMonitor!)
        }
    }
}
