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
    var projectID: String?
    var entrieID: String?
    
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
        case 3: // 项目
            switch indexPath.row {
            case 0: // 项目列表
                worktile.projects { response in
                    print(response)
                    
                    // 取一个项目ID后面用
                    if let response = response as? Array<Dictionary<String,AnyObject>> {
                        if let firstTeam = response.first {
                            self.projectID = firstTeam["pid"] as? String
                        }
                    }
                }
            case 1: // 项目详情
                if let projectID = self.projectID {
                    worktile.projectInfo(projectID) { response in
                        print(response)
                    }
                }
            case 2: // 项目成员
                if let projectID = self.projectID {
                    worktile.projectMembers(projectID) { response in
                        print(response)
                    }
                }
            case 3: // 项目添加成员
                if let projectID = self.projectID {
                    worktile.projectAddMember(projectID, userID: "000", role: 1) { response in
                        print(response)
                    }
                }
                
            case 4: // 项目移除成员
                if let projectID = self.projectID {
                    worktile.projectRemoveMember(projectID, userID: "000") { response in
                        print(response)
                    }
                }
            default:print("-")
            }
        case 4: // 任务组
            switch indexPath.row {
            case 0: // 获取项目的任务组列表
                if let projectID = self.projectID {
                    worktile.entries(projectID) { response in
                        print(response)
                        
                        // 取一个项目ID后面用
                        if let response = response as? Array<Dictionary<String,AnyObject>> {
                            if let firstObject = response.first {
                                self.entrieID = firstObject["entry_id"] as? String
                            }
                        }
                    }
                }else{
                    print("需要读取到一个项目(Project)")
                }
            case 1: // 创建任务组
                if let projectID = self.projectID {
                    worktile.entryCreate(projectID, name: "TestEntry") { response in
                        print(response)
                    }
                }
            case 2: // 任务组重命名
                if let projectID = self.projectID, entrieID = self.entrieID {
                    worktile.entryRename(projectID, entryId: entrieID, name: "TESTEntry") { response in
                        print(response)
                    }
                }
            case 3: // 删除任务组
                if let projectID = self.projectID, entrieID = self.entrieID {
                    worktile.entryDelete(projectID, entryId: entrieID) { response in
                        print(response)
                    }
                }
            case 4: // 关注任务组
                if let projectID = self.projectID, entrieID = self.entrieID {
                    worktile.entryWatch(projectID, entryId: entrieID) { response in
                        print(response)
                    }
                }
            case 5: // 取消关注任务组
                if let projectID = self.projectID, entrieID = self.entrieID {
                    worktile.entryUnwatch(projectID, entryId: entrieID) { response in
                        print(response)
                    }
                }
            default:print("-")
            }
        default:print("~")
        }
    }
}

