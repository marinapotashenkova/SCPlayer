//
//  SpinnerViewController.swift
//  Project
//
//  Created by Марина on 10.02.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import UIKit

class SpinnerViewController: UIViewController {
    
    var spinner = UIActivityIndicatorView(style: .large)
    
    override func loadView() {
        
        view = UIView()
        view.backgroundColor = UIColor(white: 1, alpha: 1)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        view.addSubview(spinner)

        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

}
