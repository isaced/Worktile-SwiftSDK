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
        }else{
            print("Authorize falied")
        }
    }
    
    // MARK: -
    
    @IBAction func refreshToken(sender: UIButton) {
        // 刷新 Token
        worktile.toRefreshToken()
        print("refresh token.")
    }
    
    @IBAction func getUserInfo(sender: UIButton) {
        // 获取用户信息
        worktile.profile({ (response) -> Void in
            print("profile: \(response)")
        })
    }
}

