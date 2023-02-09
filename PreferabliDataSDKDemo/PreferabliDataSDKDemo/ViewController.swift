//
//  ContentView.swift
//  WineRingSDKTest
//
//  Created by Nicholas Bortolussi on 5/29/20.
//  Copyright © 2020 RingIT, Inc,. All rights reserved.
//

import SwiftUI
import PreferabliDataSDK
import TTGSnackbar

class ViewController : UIViewController {
    
    @IBOutlet weak public var loginButton: UIButton!
    @IBOutlet weak public var email: UITextField!
    @IBOutlet weak public var password: UITextField!
    @IBOutlet weak public var firstLabel: UILabel!
    @IBOutlet weak public var loadingView: UIView!
    
    override func viewDidLoad() {
        handleLogoutButton()
    }
    
    func handleLogoutButton() {
        if (Preferabli.main.isUserLoggedIn()) {
            email.isHidden = true
            password.isHidden = true
            loginButton.setTitle("LOGOUT", for: .normal)
            firstLabel.text = "You are now logged in. You can logout below."
        } else {
            email.isHidden = false
            password.isHidden = false
            loginButton.setTitle("LOGIN", for: .normal)
            firstLabel.text = "First make sure you initialize the SDK. Then try logging in..."
        }
    }
    
    // Login before you can perform any actions associated with a user.
    @IBAction func loginPressed() {
        showLoadingView()
        hideKeyboard()
        
        if (Preferabli.main.isUserLoggedIn()) {
            Preferabli.async.logout() {
                self.hideLoadingView()
                self.handleLogoutButton()
            } onFailure: { error in
                self.hideLoadingView()
                self.showSnackBar(message: error.getMessage())
            }
        } else {
            let emailString = email.text ?? ""
            let passwordString = password.text ?? ""
            
            Preferabli.async.login(email: emailString, password: passwordString) { user in
                self.hideLoadingView()
                self.handleLogoutButton()
            } onFailure: { error in
                self.hideLoadingView()
                self.showSnackBar(message: error.getMessage())
            }
        }
    }
    
    @IBAction func searchProductsPressed() {
        showLoadingView()
        Preferabli.async.searchProducts(query: "wine") { products in
            self.hideLoadingView()
        } onFailure: { error in
            self.hideLoadingView()
            self.showSnackBar(message: error.getMessage())
        }
    }
    
    @IBAction func getRatedProductsPressed() {
        showLoadingView()
        Preferabli.async.getRatedProducts(force_refresh: false) { products in
            self.hideLoadingView()
        } onFailure: { error in
            self.hideLoadingView()
            self.showSnackBar(message: error.getMessage())
        }
    }
    
    func showLoadingView() {
        loadingView.isHidden = false
    }
    
    func hideLoadingView() {
        loadingView.isHidden = true
    }
    
    public func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    public func showSnackBar(message: String) {
        let snackbar = TTGSnackbar.init(message: message, duration: .long)
        snackbar.show()
    }
}
