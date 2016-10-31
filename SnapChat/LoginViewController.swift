//
//  LoginViewController.swift
//  SnapChat
//
//  Created by Chris on 1/27/16.
//  Copyright © 2016 Chris Mendez. All rights reserved.
//

import Async
import MBProgressHUD
import SwiftValidator

class LoginViewController: UIViewController {
    
    var validator = Validator()
    var userUtil:UserUtil?
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    
    @IBAction func onLogin(_ sender: AnyObject) {
        validator.validate(self)
    }
    
    func onLoad(){
        //Remove Navigation Controller back Button
        self.navigationItem.hidesBackButton = true
        
        //Register fields for validation
        validator.registerField(emailTextField, errorLabel: emailErrorLabel, rules: [RequiredRule(), EmailRule(message: "Invalid email")])
        validator.registerField(passwordTextField, errorLabel: passwordErrorLabel, rules: [RequiredRule()])
    }
    
    func goToView(){
        let delay = 1.0
        Async.main(after: delay, { () -> Void in
            self.navigationController?.popToRootViewController(animated: true)
        })
    }
    
    func logIn(){
        let charSet = CharacterSet.whitespacesAndNewlines
        let user    = self.emailTextField.text?.trimmingCharacters(in: charSet)
        let pass    = self.passwordTextField.text?.trimmingCharacters(in: charSet)
        
        ActivityUtil.sharedInstance.showLoader(self.view)
        
        userUtil = UserUtil()
        userUtil?.delegate = self
        userUtil?.signIn(user!, password: pass!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        onLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

//MARK: - Activity Loader
extension LoginViewController {

}

//MARK: - User Utility Delegate
extension LoginViewController:UserUtilDelegate{
    func didSignIn() {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        goToView()
    }
    func didFail(_ message: String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.error, title: "Login Failed", message: message, sender: self)
    }
}

//MARK: - Validation Delegate
extension LoginViewController:ValidationDelegate{
    /**
     This method will be called on delegate object when validation fails.
     
     - returns: No return value.
     */
    public func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        for (field, error) in validator.errors {
        }
    }

    func validationSuccessful() {
        logIn()
    }
    
    func validationFailed(_ errors: [UITextField : ValidationError]) {
        for (field, error) in validator.errors {
            //field.layer.borderColor = UIColor.redColor.CGColor
            error.errorLabel?.text = error.errorMessage // works if you added labels
            error.errorLabel?.isHidden = false
        }
    }
}
