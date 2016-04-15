//
//  Messages.swift
//  SnapChat
//
//  Created by Chris Mendez on 3/14/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//
//  This object is designed to mirror what we have in 
//     Parse or any other mobile back-end service
//
//   Notes:
//     This is used in the "CameraTableViewController"
//     and the "InboxTableViewController"
//
import Parse

struct Messages {
    static let className    = "Messages"
    static let recipientIds = "recipientIds"
    static let senderName   = "senderName"
    static let senderId     = "senderId"
    static let fileType     = "fileType"
    static let file         = "file"
    
    var messages:PFObject
}
