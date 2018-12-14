//
//  mcaRecoveryPasswordManager.swift
//  mcaRecoveryPassword
//
//  Created by Pilar del Rosario Prospero Zeferino on 12/6/18.
//  Copyright © 2018 Speedy Movil. All rights reserved.
//

import UIKit

open class mcaRecoveryPasswordManager: NSObject {
    
    open class func launchModule(navController: UINavigationController?) {
        navController?.pushViewController(RecoveryPasswordVC(), animated: true);
    }
    
    open class func launch(navController: UINavigationController?, doLoginWhenFinish: @escaping ((_ doutomaticLogin: Bool) -> Void)) {
        let recoveryPasswordVC = RecoveryPasswordVC()
        recoveryPasswordVC.doLoginWhenFinish = doLoginWhenFinish
        navController?.pushViewController(recoveryPasswordVC, animated: true)
    }
    
    open class func findPasswordRecoveryVC(navigation: UINavigationController?) -> UIViewController? {
        if let viewControllers = navigation?.viewControllers {
            for viewController in viewControllers {
                if viewController.isKind(of: RecoveryPasswordVC.self) {
                    return viewController
                }
            }
        }
        return nil
    }
    
    

}
