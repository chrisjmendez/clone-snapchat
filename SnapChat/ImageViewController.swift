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
    
    fileprivate func onLoad(){
        let imageFile = thisMessage?.object(forKey: Messages.file) as! PFFile
        let imageFileURL = URL(string: imageFile.url!)
        let imageData = try? Data(contentsOf: imageFileURL!)
        imageView.image = UIImage(data: imageData!)
        
        let senderName = self.thisMessage?.object(forKey: "senderName") as? String
        self.navigationItem.title = "Sent from \(senderName)"
    }
    
    func timerStart(){
        if self.responds(to: #selector(ImageViewController.timerStop)) {
            Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(ImageViewController.timerStop), userInfo: nil, repeats: false)
        } else {
            myLog("Error")
        }
    }
    
    func timerStop(){
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        timerStart()
    }
}
