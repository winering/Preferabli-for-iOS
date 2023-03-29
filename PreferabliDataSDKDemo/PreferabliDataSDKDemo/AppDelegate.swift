//
//  AppDelegate.swift
//  WineRingSDKTest
//
//  Created by Nicholas Bortolussi on 5/29/20.
//  Copyright © 2020 RingIT, Inc,. All rights reserved.
//

import UIKit
import PreferabliDataSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
        Preferabli.initialize(client_interface: "YOUR_CLIENT_INTERFACE_HERE", integration_id: 6301)
        
        return true
    }
}

