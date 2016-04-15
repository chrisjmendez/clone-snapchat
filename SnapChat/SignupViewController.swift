//
//  SignupViewController.swift
//  SnapChat
//
//  Created by Chris on 1/27/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

import Async
import Dollar
import UIKit
import MBProgressHUD
import SwiftValidator

class SignupViewController: UIViewController {

    var userUtil:UserUtil?
    var validator = Validator()

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    
    @IBAction func onSignUp(sender: AnyObject) {
        validator.validate(self)
    }

    func onLoad(){
        validator.registerField(emailTextField, errorLabel: emailErrorLabel, rules: [RequiredRule(), EmailRule(message: "Invalid email")])
        validator.registerField(passwordTextField, errorLabel: passwordErrorLabel, rules: [RequiredRule()])
    }

    //MARK: - Transitions
    func goToView(){
        let delay = 1.0
        Async.main(after: delay, block: { () -> Void in
            self.navigationController?.popToRootViewControllerAnimated(true)
        })
    }
    
    //MARK: - User
    func createUser(){
        ActivityUtil.sharedInstance.showLoader(self.view)

        let charSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        let user    = self.emailTextField.text?.stringByTrimmingCharactersInSet(charSet)
        let pass    = self.passwordTextField.text?.stringByTrimmingCharactersInSet(charSet)

        userUtil = UserUtil()
        userUtil?.delegate = self
        userUtil?.signUp(user!, password: pass!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onLoad()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - Validation Delegate
extension SignupViewController:ValidationDelegate{
    func validationSuccessful() {
        createUser()
    }
    
    func validationFailed(errors: [UITextField : ValidationError]) {
        for (field, error) in validator.errors {
            field.layer.borderColor = UIColor.redColor().CGColor
            field.layer.borderWidth = 1.0
            error.errorLabel?.text = error.errorMessage // works if you added labels
            error.errorLabel?.hidden = false
        }
    }
}

//MARK: - User Utility Delegate
extension SignupViewController:UserUtilDelegate{
    func didSignUp() {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        goToView()
    }

    func didFail(message:String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.ERROR, title: "Registration Error", message: message, sender: self)
    }
}
