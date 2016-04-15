//
//  ImageViewController.swift
//  SnapChat
//
//  Created by Chris Mendez on 3/15/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

//import AlamofireImage
import UIKit
import Parse

class ImageViewController: UIViewController {
    
    var thisMessage:PFObject?
    
    @IBOutlet weak var imageView: UIImageView!
    
    private func onLoad(){
        let imageFile = thisMessage?.objectForKey(Messages.file) as! PFFile
        let imageFileURL = NSURL(string: imageFile.url!)
        let imageData = NSData(contentsOfURL: imageFileURL!)
        imageView.image = UIImage(data: imageData!)
        
        let senderName = self.thisMessage?.objectForKey("senderName") as? String
        self.navigationItem.title = "Sent from \(senderName)"
    }
    
    func timerStart(){
        if self.respondsToSelector("timerStop") {
            NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "timerStop", userInfo: nil, repeats: false)
        } else {
            myLog("Error")
        }
    }
    
    func timerStop(){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        timerStart()
    }
}
