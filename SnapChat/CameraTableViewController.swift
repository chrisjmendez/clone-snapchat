//
//  CameraTableViewController.swift
//  SnapChat
//
//  Created by Chris Mendez on 3/7/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

import UIKit
import Async
import Cent
import MobileCoreServices
import Parse

class CameraTableViewController: UITableViewController {
    
    let MAX_VIDEO_DURATION:TimeInterval = 10
    
    //View controllers can be properties of other view controllers
    var image:UIImage?
    var imagePicker:UIImagePickerController?
    
    var videoFilePath:String?

    var friendUtil:FriendUtil?
    //List of current friends
    var friends:[PFUser] = []
    //Friends who will get this message
    var recipients = [String]()
    
    //MARK: - IBActions
    
    @IBAction func onCancel(_ sender: AnyObject) {
        //Cancel the entire send process
        clearLocalData()
        goToView(Config.appTab.INBOX)
    }
    
    @IBAction func onSend(_ sender: AnyObject) {
        //Ensure that a photo or video was captured or selected

        let vidIsEmpty = (videoFilePath ?? "").isEmpty
        if vidIsEmpty == true && image == nil {
            AlertUtil.sharedInstance.show(AlertUtilType.error, title: "Error", message: "Please first pick a photo or video to send", sender: self)
        } else {
            uploadMessage()
        }
    }
    
    //MARK: - App Logic
    
    func clearLocalData(){
        image         = nil
        videoFilePath = ""
        recipients.removeAll()
    }
    
    func goToView(_ index:Int){
        //Take the user back to the inbox tab programatically
        self.tabBarController?.selectedIndex = index
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipients.removeAll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initCamera()
        getFriends()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.friends.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisUser:PFUser = self.friends[(indexPath as NSIndexPath).row] as! PFUser
        let reuseIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as UITableViewCell!
            cell?.textLabel?.text = thisUser.username
        
        //If the user has been selected, they should be in recipients.  If they are, they deserve a checkmark
        if recipients.contains(thisUser.objectId!){
            cell?.accessoryType = .checkmark
        } else {
            cell?.accessoryType = .none
        }
        
        return cell!
    }
    
    //Tap on a friend and select a checkmark
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //We dont want the row to remain highlighted
        tableView.deselectRow(at: indexPath, animated: false)
        
        let cell = tableView.cellForRow(at: indexPath)! as UITableViewCell

        //Selected User
        let user = self.friends[(indexPath as NSIndexPath).row] as! PFUser
        
        if cell.accessoryType == .none {
            cell.accessoryType = .checkmark
            //Just record the Parse user Object
            recipients.append( user.objectId! )
        } else {
            cell.accessoryType = .none
            //Just delete the Parse user object string from the array
            recipients = recipients.filter({ $0 != user.objectId! })
        }
    }
}


//MARK: - Image Manipulation

extension CameraTableViewController{
    fileprivate func resizeImage(_ sourceImage:UIImage, w:Int, h:Int) -> UIImage{
        let newSize = CGSize(width: w, height: h)
        let newRect = CGRect(x: 0, y: 0, width: w, height: h)
        //Create a context in which you manipulate a smaller verions of the image
        UIGraphicsBeginImageContext(newSize)
        sourceImage.draw(in: newRect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        return resizedImage!
    }
}

//MARK: - Friend Connection

extension CameraTableViewController: FriendUtilDelegate{

    func uploadMessage(){
        
        struct File {
            var data:Data?
            let name:String?
            let type:String?
        }
        var file:File?

        //http://nshipster.com/nsoperation/
        Async.userInitiated {
            ActivityUtil.sharedInstance.showProgressLoader(self.view)
            
            //We're sending an image
            if self.image != nil {
                let newImage = self.resizeImage(self.image!, w: 256, h: 256)
                let png = UIImagePNGRepresentation(newImage)
                file = File(data: png, name: "image.png", type: "image")
            }
            //WE're sending a video
            else {
                let video = NSData.dataWithContentsOfMappedFile(self.videoFilePath!) as! NSData
                file = File(data: video as Data, name: "video.mov", type: "video")
            }
            let parseFile = PFFile.init(name: file?.name, data: (file?.data)!)
            parseFile?.saveInBackground({ (success, error) -> Void in
                if error != nil {
                    self.myLog("error")
                } else {
                    //This is where we construct a Parse Object using the Messages structure
                    let message = PFObject(className: Messages.className )
                        message.setObject(parseFile!, forKey: Messages.file)
                        //We need this when we are viewing messages in the inbox
                        message.setObject((file?.type)!, forKey: Messages.fileType)
                        message.setObject(self.recipients, forKey: Messages.recipientIds)
                        message.setObject((PFUser.current()?.objectId)!, forKey: Messages.senderId)
                        message.setObject((PFUser.current()?.username)!, forKey: Messages.senderName)
                        message.saveInBackground(block: { (success, error) -> Void in
                            if error != nil {
                                self.myLog(error)
                            } else {
                                self.clearLocalData()
                                self.myLog("YES")
                            }
                            self.goToView(Config.appTab.INBOX)
                        })
                }
            },
            progressBlock: { (percentage) -> Void in
                let progress = Float( Double(percentage) * 0.01 )
                ActivityUtil.sharedInstance.updateLoader(progress)
                if progress >= 1.0 {
                    ActivityUtil.sharedInstance.hideLoader(self.view)
                }
            })
        }
    }
    
    func getFriends(){
        friendUtil = FriendUtil()
        friendUtil!.updateFriendships()
        friendUtil!.delegate = self
    }
    
    func relationshipDidComplete(_ users: NSArray) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        self.friends = users as! [Any] as! [PFUser]
        self.tableView.reloadData()
    }
    func relationshipDidFail(_ message: String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.error, title: "Error", message: message, sender: self)
    }
}

//MARK: - Camera related tasks

extension CameraTableViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func initCamera(){
        //A. Determine if a video or image has been picked by calculating whether they're empty
        let vidIsEmpty = (videoFilePath ?? "").isEmpty
        //B. If there's already a picked item or video, don't show the camera
        if image == nil && vidIsEmpty == true {
            imagePicker = UIImagePickerController()
            imagePicker?.delegate      = self
            imagePicker?.allowsEditing = false
            imagePicker?.videoMaximumDuration = MAX_VIDEO_DURATION
            
            if UIImagePickerController.isSourceTypeAvailable( UIImagePickerControllerSourceType.camera ){
                imagePicker?.sourceType = .camera
            } else {
                imagePicker?.sourceType = .photoLibrary
            }
            //imagePicker?.mediaTypes = [ kUTTypeImage as String ]
            imagePicker?.mediaTypes = UIImagePickerController.availableMediaTypes(for: (imagePicker?.sourceType)!)!
            
            showCamera(false)
        }
    }
    
    func showCamera(_ animated:Bool){
        Async.main(after: 0.1) { () -> Void in
            self.present(self.imagePicker!, animated: animated, completion: nil)
        }
    }
    
    //Hide the modal camera window
    func hideCamera(_ animated:Bool){
        imagePicker?.dismiss(animated: animated, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //Dismiss a view controller that was presented modally
        picker.dismiss(animated: false, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //1. Handle images
        //2. Handle videos
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        //Camera took a photo
        if( mediaType == kUTTypeImage as String ){
            //Only store this image if the camera was used
            self.image = info[UIImagePickerControllerOriginalImage] as? UIImage
            //Save the image
            if imagePicker?.sourceType == .camera{
                UIImageWriteToSavedPhotosAlbum(self.image!, nil, nil, nil)
            }
        }
        //Camera took a video
        else {
            videoFilePath = (info[UIImagePickerControllerMediaURL]! as AnyObject).path
            print(videoFilePath)
            //Save the video
            if imagePicker?.sourceType == .camera{
                //Check to see that we can actually save a video
                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoFilePath!) {
                    UISaveVideoAtPathToSavedPhotosAlbum(videoFilePath!, nil, nil, nil)
                }
            }
        }
        hideCamera(true)
    }
}

