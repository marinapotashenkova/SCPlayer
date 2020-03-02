//
//  AuthViewController.swift
//  Project
//
//  Created by Марина on 27.01.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import UIKit

class AuthViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    private var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: emailField.text!)
    }
    
    var authClient: AuthClient!
    private let server = "www.soundcloud.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let spinnerViewController = SpinnerViewController()
        addChild(spinnerViewController)
        spinnerViewController.view.frame = view.frame
        view.addSubview(spinnerViewController.view)
        spinnerViewController.didMove(toParent: self)
        
        let nextVC = self.nextViewController()
        if nextVC != self {
            self.navigationController?.setViewControllers([nextVC], animated: true)
        }

    }
    
    @IBAction func signInTapped(_ sender: UIButton) {
//        print(emailField.text)
//        print(passwordField.text)
        
        if inputDataValidated() {
            sender.isEnabled = false
            authClient = AuthClient(username: emailField.text!, password: passwordField.text!)
            authClient.authorize() { [unowned self] (user) in
                try? UserRepository.save(user, from: self.server)
                
                DispatchQueue.main.async {
                    guard let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController else {
                        assertionFailure("Error of downcasting UIViewController to UITabBarContoller")
                        return
                    }
                    tabBarController.modalPresentationStyle = .fullScreen
                    guard let searchNavigationController = tabBarController.viewControllers?[0] as? UINavigationController else { return }
                    guard let searchViewController = searchNavigationController.viewControllers[0] as? SearchCollectionViewController else { return }
                    searchViewController.user = user
                    self.navigationController?.setViewControllers([tabBarController], animated: true)
                }
            }
            
        }
        
    }
    
    @IBAction func emailInputEnded(_ sender: UITextField) {
//        print(emailField.text)
        passwordField.becomeFirstResponder()
    }
    
    @IBAction func passwordInputEnded(_ sender: UITextField) {
//        print(passwordField.text)
        sender.resignFirstResponder()
    }
    
    
    private func inputDataValidated() -> Bool {
        
        guard let email = emailField.text, !email.isEmpty
        else {
            let alertController = UIAlertController(title: "Error", message: "Enter email to authorize.", preferredStyle: .alert)
                    
            let action = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in
                print("OK")
            }

            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
            
            return false
        }
        
        guard let password = passwordField.text, !password.isEmpty
        else {
            let alertController = UIAlertController(title: "Error", message: "Enter password to authorize.", preferredStyle: .alert)
                    
            let action = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in
                print("OK")
            }

            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
            
            return false
        }
        
       if !isValidEmail {
            
            let alertController = UIAlertController(title: "Error", message: "Email doesn't conform to the required format. Please check and try again.", preferredStyle: .alert)
                    
            let action = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) in
                print("OK")
            }

            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
    
    private func nextViewController() -> UIViewController {
    
        do {
            var user = try UserRepository.get(from: server)
            authClient = AuthClient(authInfo: user.authInfo)
            authClient.getMe { (newUser) in
                if user != newUser {
                    user = newUser
                    do {
                        try UserRepository.update(user: newUser, from: self.server)
                    } catch {
                        assertionFailure("Updating keychain error: \(error.localizedDescription)")
                    }
                }
            }
            guard let tabBarController = self.storyboard?.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController else {
                assertionFailure("Error of downcasting UIViewController to UITabBarController")
                return UIViewController()
            }
            tabBarController.modalPresentationStyle = .fullScreen
            guard let searchNavigationController = tabBarController.viewControllers?[0] as? UINavigationController else { return UIViewController() }
            guard let searchViewController = searchNavigationController.viewControllers[0] as? SearchCollectionViewController else { return UIViewController() }
            searchViewController.user = user
            return tabBarController
            
        } catch KeychainError.noPassword {
            print("No user data saved")
            
            let spinnerViewController = children[0]
            
            spinnerViewController.willMove(toParent: nil)
            spinnerViewController.view.removeFromSuperview()
            spinnerViewController.removeFromParent()
            
            return self
        } catch KeychainError.unexpectedPasswordData {
            assertionFailure(KeychainError.unexpectedPasswordData.localizedDescription)
        } catch {
            assertionFailure("Unexpected Error")
        }
        
        return UIViewController()
    }
    
}
