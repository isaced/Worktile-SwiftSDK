//
//  ViewController.swift
//  WorktileiOSDemo
//
//  Created by isaced on 15/6/19.
//  Copyright © 2015年 isaced. All rights reserved.
//

import UIKit
import WorktileiOS

class ViewController: UIViewController , WorktileDelegate {

    let worktile = Worktile(appKey: "eef4247ee75c4eeba9946900f9579688")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        worktile.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func login(sender: UIButton) {
        let authorizeVC = worktile.authorizeViewController()
        let nav = UINavigationController(rootViewController: authorizeVC)
        self.presentViewController(nav, animated: true, completion: nil)
    }

    func authorizeComplate(currentAuthorizeViewController: UIViewController, success: Bool) {
        currentAuthorizeViewController.dismissViewControllerAnimated(true, completion: nil)
        if success == true {
            print("Authorize success!")
            
            // After
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))),dispatch_get_main_queue()) {
                print("After...")
                
                self.worktile.toRefreshToken()
            }
            
        }else{
            print("Authorize falied")
        }
    }
}

