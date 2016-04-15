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
    case ERROR   = 0
    case SUCCESS = 1
}

class AlertUtil {
    
    static let sharedInstance = AlertUtil()
    private init(){}

    var delegate:AlertUtilDelegate?
    
    func onTap(){
        delegate?.didFinish()
    }
    
    func show(type:AlertUtilType , title:String, message:String, sender:UIViewController){
        switch(type){
            case AlertUtilType.SUCCESS:
                let alert = JSSAlertView().success(sender, title: title, text: message)
                    alert.addAction(onTap)
                break
            case AlertUtilType.ERROR:
                let alert = JSSAlertView().danger(sender, title: title, text: message)
                    alert.addAction(onTap)
                break
            }
    }
}


class ActivityUtil {
    
    static let sharedInstance = ActivityUtil()
    private init(){}
    
    var activityMonitor:MBProgressHUD?

    func hideLoader(view:UIView){
        Async.main{ () -> Void in
            MBProgressHUD.hideAllHUDsForView(view, animated: true)
        }
    }
    
    func updateLoader(progress:Float){
        self.activityMonitor!.progress = progress
    }
    
    func showProgressLoader(view:UIView){
        Async.main(block: { () -> Void in
            self.activityMonitor = MBProgressHUD.showHUDAddedTo(view, animated: true)
            self.activityMonitor!.labelText = "Uploading"
            self.activityMonitor!.detailsLabelText = ""
            self.activityMonitor!.show(true)
            self.activityMonitor!.mode = MBProgressHUDMode.AnnularDeterminate
            view.addSubview(self.activityMonitor!)
        })
    }
    
    
    func showLoader(view:UIView, label:String="Loading", message:String="Updating"){
        Async.main(block: { () -> Void in
           self.activityMonitor = MBProgressHUD.showHUDAddedTo(view, animated: true)
           self.activityMonitor!.labelText = label
           self.activityMonitor!.detailsLabelText = message
           self.activityMonitor!.show(true)
           self.activityMonitor!.mode = .Indeterminate
           view.addSubview(self.activityMonitor!)
        })
    }
}