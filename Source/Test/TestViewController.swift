//
//  TestViewController.swift
//  InstagramTransition
//
//  Created by Kolos Foltanyi on 2023. 07. 22..
//

import UIKit

class TestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let profileScreen = ProfileScreen()
        
        // Test modal presentation instead of navigation
        profileScreen.modalPresentationStyle = .fullScreen
        present(profileScreen, animated: false)
    }
}
