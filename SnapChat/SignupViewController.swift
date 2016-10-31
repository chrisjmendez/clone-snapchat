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
    
    @IBAction func onSignUp(_ sender: AnyObject) {
        validator.validate(self)
    }

    func onLoad(){
        validator.registerField(emailTextField, errorLabel: emailErrorLabel, rules: [RequiredRule(), EmailRule(message: "Invalid email")])
        validator.registerField(passwordTextField, errorLabel: passwordErrorLabel, rules: [RequiredRule()])
    }

    //MARK: - Transitions
    func goToView(){
        let delay = 1.0
        Async.main(after: delay, { () -> Void in
            self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    //MARK: - User
    func createUser(){
        ActivityUtil.sharedInstance.showLoader(self.view)

        let charSet = CharacterSet.whitespacesAndNewlines
        let user    = self.emailTextField.text?.trimmingCharacters(in: charSet)
        let pass    = self.passwordTextField.text?.trimmingCharacters(in: charSet)

        userUtil = UserUtil()
        userUtil?.delegate = self
        userUtil?.signUp(user!, password: pass!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - Validation Delegate
extension SignupViewController:ValidationDelegate{
    /**
     This method will be called on delegate object when validation fails.
     
     - returns: No return value.
     */
    public func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        print("validationFailed")
    }

    func validationSuccessful() {
        createUser()
    }
    
    func validationFailed(_ errors: [UITextField : ValidationError]) {
        for (field, error) in validator.errors {
            //field.layer.borderColor = UIColor.redColor.CGColor
            error.errorLabel?.text = error.errorMessage // works if you added labels
            error.errorLabel?.isHidden = false
        }
    }
}

//MARK: - User Utility Delegate
extension SignupViewController:UserUtilDelegate{
    func didSignUp() {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        goToView()
    }

    func didFail(_ message:String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.error, title: "Registration Error", message: message, sender: self)
    }
}
