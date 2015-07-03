//
//  ViewController.swift
//  WorktileiOSDemo
//
//  Created by isaced on 15/6/19.
//  Copyright © 2015年 isaced. All rights reserved.
//

import UIKit
import WorktileiOS

class ViewController: UITableViewController , WorktileDelegate {

    let worktile = Worktile(appKey: "eef4247ee75c4eeba9946900f9579688")
    
    var teamID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        worktile.delegate = self
        
        print((worktile.needAuthorize ? "需要" : "不需要") + "进行授权登录...")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Login Delegate
    func authorizeComplate(currentAuthorizeViewController: UIViewController, success: Bool) {
        currentAuthorizeViewController.dismissViewControllerAnimated(true, completion: nil)
        if success == true {
            print("Authorize success!")
        }else{
            print("Authorize falied")
        }
    }
    
    // MARK: -
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0: // 登录
                let authorizeVC = worktile.authorizeViewController()
                let nav = UINavigationController(rootViewController: authorizeVC)
                self.presentViewController(nav, animated: true, completion: nil)
            case 1: // 刷新 Token
                worktile.toRefreshToken()
                print("refresh token.")
            default: print("-")
            }
        case 1: // 用户
            worktile.profile() { response in
                print("profile: \(response)")
            }
        case 2: // 团队
            switch indexPath.row {
            case 0: // 团队列表
                worktile.teams() { response in
                    print(response)
                    
                    // 取一个团队ID后面用
                    if let response = response as? Array<Dictionary<String,AnyObject>> {
                        if let firstTeam = response.first {
                            self.teamID = firstTeam["team_id"] as? String
                        }
                    }
                }
            case 1: // 团队信息
                if let teamID = self.teamID {
                    worktile.teamInfo(teamID) { response in
                        print(response)
                    }
                }
            case 2: // 团队成员
                if let teamID = self.teamID {
                    worktile.teamMembers(teamID) { response in
                        print(response)
                    }
                }
            case 3: // 团队项目
                if let teamID = self.teamID {
                    worktile.teamProjects(teamID) { response in
                        print(response)
                    }
                }
            default: print("-")
            }
        default:print("~")
        }
    }
}

