//
//  AppDelegate.swift
//  AnimationVerifier
//
//  Created by Антон Красильников on 27.12.2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var _window: UIWindow?
    let listViewController = ListViewController()

    private var window: UIWindow {
        if _window == nil {
            _window = UIWindow(frame: UIScreen.main.bounds)
        }
        return _window!
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window.rootViewController =  UINavigationController(rootViewController: listViewController)
        window.makeKeyAndVisible()
        return true
    }

}

