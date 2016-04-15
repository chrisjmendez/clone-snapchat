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
    
    @IBAction func onLogin(sender: AnyObject) {
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
        Async.main(after: delay, block: { () -> Void in
            self.navigationController?.popToRootViewControllerAnimated(true)
        })
    }
    
    func logIn(){
        let charSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        let user    = self.emailTextField.text?.stringByTrimmingCharactersInSet(charSet)
        let pass    = self.passwordTextField.text?.stringByTrimmingCharactersInSet(charSet)
        
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
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
    func didFail(message: String) {
        ActivityUtil.sharedInstance.hideLoader(self.view)
        AlertUtil.sharedInstance.show(AlertUtilType.ERROR, title: "Login Failed", message: message, sender: self)
    }
}

//MARK: - Validation Delegate
extension LoginViewController:ValidationDelegate{
    func validationSuccessful() {
        logIn()
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
