//
//  Worktile.swift
//  Worktile
//
//  Created by isaced on 15/6/19.
//  Copyright © 2015年 isaced. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

public typealias DictionaryCallback = (Dictionary<String,AnyObject>) -> Void
public typealias ArrayCallback = (Array<AnyObject>) -> Void

let accessTokenKey = "worktile_access_token"
let refreshTokenKey = "worktile_refresh_token"
let expiresDateKey = "worktile_expires_date"

public class Worktile : AuthorizeWebControllerDelegate {
    
    /// 申请应用时分配的 AppKey
    public let clientID: String
    
    /// 授权回调地址
    public static let redirectURI = "https://worktile_redirect"
    
    /// OAuth2 授权拿回来的 code
    public var authorizeCode: String?
    
    /// 授权后访问 API 的令牌
    public var accessToken: String?
    
    /// accessToken 过期时间
    public var expiresDate: NSDate?
    
    /// 用于刷新获取最新的access_token
    public var refreshToken: String?
    
    /// 根据 /oauth2/authorize 组装拼接的 OAuth2 授权地址
    public var authorizeURL: String {
        return "https://api.worktile.com/oauth2/authorize?client_id=\(clientID)&redirect_uri=\(Worktile.redirectURI)&display=mobile"
    }
    
    /// 是否需要进行授权登录
    public var needAuthorize: Bool {
        // 判断 token 是否过期
        if let expiresDate = self.expiresDate {
            if NSDate().compare(expiresDate) == NSComparisonResult.OrderedAscending {
                return false
            }
        }
        return true
    }
    
    /// 当前授权控制器
    var currentAuthorizeViewController: AuthorizeWebController?
    
    /// Delegate
    public var delegate: WorktileDelegate?
    
    /// Alamofire Manager
    var httpManager: Manager
    
    // MARK: Init
    
    /**
    构造函数
    
    :param: appKey 从 Worktile Open 后台来的 App Key
    
    :returns: Worktile 实例
    */
    public init(appKey:String){
        
        /// 保存 App Key (ClientID)
        self.clientID = appKey
        
        /// 从磁盘读取 token
        self.accessToken = NSUserDefaults.standardUserDefaults().stringForKey(accessTokenKey)
        self.refreshToken = NSUserDefaults.standardUserDefaults().stringForKey(refreshTokenKey)
        self.expiresDate = NSUserDefaults.standardUserDefaults().objectForKey(expiresDateKey) as? NSDate
        
        /// 初始化 Alamofire Manager
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        httpManager = Alamofire.Manager(configuration: configuration)
    }
    
    
    // MARK: OAuth
    
    /**
    授权成功的回调
    */
    func authorizeComplate(authorizeCode: String?) {
        if let authorizeCode = authorizeCode {
            if authorizeCode.characters.count > 0 {
                // 储存获取到的 code
                self.authorizeCode = authorizeCode
                
                // 获取 Access token
                self.getAccessToken()
                
                // 获取成功
                self.delegate?.authorizeComplate(currentAuthorizeViewController!,success: true)
            }else{
                // 获取失败
                self.delegate?.authorizeComplate(currentAuthorizeViewController!,success: false)
            }
        }
    }
    
    /**
    获取 access_token
    
    :returns: access_token
    */
    public func getAccessToken() {
        if let authorizeCode = self.authorizeCode {
            httpManager.request(.POST, "https://api.worktile.com/oauth2/access_token", parameters: ["client_id": self.clientID,"code":authorizeCode])
                .responseJSON { (_, _, JSON, _) in

                    if let jsonDict = JSON as? Dictionary<String,AnyObject>{

                        // Success
                        if let accessToken = jsonDict["access_token"] as? String ,
                                refreshToken = jsonDict["refresh_token"] as? String ,
                                expiresIn = jsonDict["expires_in"] as? NSNumber {
                                    self.accessToken = accessToken
                                    self.refreshToken = refreshToken
                                    self.expiresDate = NSDate(timeIntervalSinceNow: expiresIn.doubleValue)
                                    
                                    // Save to disk
                                    NSUserDefaults.standardUserDefaults().setObject(accessToken , forKey: accessTokenKey)
                                    NSUserDefaults.standardUserDefaults().setObject(refreshToken, forKey: refreshTokenKey)
                                    NSUserDefaults.standardUserDefaults().setObject(self.expiresDate, forKey: expiresDateKey)
                        }
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                        
                    }
            }
        }else{
            print("error : No authorizeCode.")
        }


    }
    
    /**
    刷新 access_token
    
    :returns: access_token
    */
    public func toRefreshToken(){
        if let refreshToken = self.refreshToken {
            Alamofire.request(.GET, URLString: "https://api.worktile.com/oauth2/refresh_token", parameters: ["client_id": clientID,"refresh_token": refreshToken])
                .responseJSON { (_, _, JSON, _) in
                    if let jsonDict = JSON as? Dictionary<String,AnyObject>{
                        
                        // Success
                        if let accessToken = jsonDict["access_token"] as? String {
                            self.accessToken = accessToken
                        }
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }

    /// 获取授权视图控制器
    public func authorizeViewController() -> UIViewController {
        currentAuthorizeViewController = AuthorizeWebController(url: self.authorizeURL, delegate: self)
        return currentAuthorizeViewController!
    }
    
    // MARK: User
    
    /**
    获取用户
    
    :param: finishCallback 返回内容
    */
    public func profile(finishCallback: DictionaryCallback) {
        if let accessToken = accessToken {
            httpManager.request(.GET, self.requestURL("user/profile"), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Dictionary<String,AnyObject> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    // MARK: Team
    
    /**
    获取用户所在的团队列表
    */
    public func teams(finishCallback: ArrayCallback) {
        if let accessToken = accessToken {
            httpManager.request(.GET, self.requestURL("teams"), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Array<Dictionary<String,AnyObject>> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    /**
    获取团队信息
    */
    public func teamInfo(teamID: String, finishCallback: DictionaryCallback) {
        if let accessToken = accessToken {
            httpManager.request(.GET, self.requestURL("teams",item: teamID), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Dictionary<String,AnyObject> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    /**
    获取团队所有成员
    */
    public func teamMembers(teamID: String, finishCallback: ArrayCallback) {
        if let accessToken = accessToken {
            httpManager.request(.GET, self.requestURL("teams",item: teamID,arg2: "members"), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Array<Dictionary<String,AnyObject>> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    /**
    获取团队所有项目
    */
    public func teamProjects(teamID: String, finishCallback: ArrayCallback) {
        if let accessToken = accessToken {
            httpManager.request(.GET, self.requestURL("teams",item: teamID,arg2: "projects"), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Array<Dictionary<String,AnyObject>> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    // MARK: Project
    
    /**
    获取用户所有项目
    */
    public func projects(finishCallback: ArrayCallback) {
        if let accessToken = accessToken {
            httpManager.request(.GET, self.requestURL("projects"), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Array<Dictionary<String,AnyObject>> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }

    /**
    获取项目详情
    
    :param: projectID      项目ID
    */
    public func projectInfo(projectID: String, finishCallback: DictionaryCallback) {
        if let accessToken = accessToken {
            httpManager.request(.GET, self.requestURL("projects",item: projectID), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Dictionary<String,AnyObject> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    /**
    获取项目成员
    
    :param: projectID      项目ID
    */
    public func projectMembers(projectID: String, finishCallback: ArrayCallback) {
        if let accessToken = accessToken {
            httpManager.request(.GET, self.requestURL("projects",item: projectID,arg2: "members"), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Array<Dictionary<String,AnyObject>> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    /**
    项目添加成员
    
    :param: projectID      项目ID
    :param: uid            用户ID
    :param: role           成员角色
    */
    public func projectAddMember(projectID: String,userID: String,role: Int, finishCallback: DictionaryCallback) {
        if let accessToken = accessToken {
            httpManager.request(.POST, self.requestURL("projects",item: projectID,arg2: "members"), parameters: ["access_token":accessToken,"pid":projectID,"uid":userID,"role":role])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Dictionary<String,AnyObject> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    /**
    项目移除成员
    
    :param: projectID      项目ID
    :param: uid            用户ID
    */
    public func projectRemoveMember(projectID: String,userID: String, finishCallback: DictionaryCallback) {
        if let accessToken = accessToken {
            httpManager.request(.DELETE, self.requestURL("projects",item: projectID,arg2: "members",arg3: userID), parameters: ["access_token":accessToken])
                .responseJSON { (_, _, JSON, _) -> Void in
                    if let jsonDict = JSON as? Dictionary<String,AnyObject> {
                        
                        // Success
                        finishCallback(jsonDict)
                        
                        // Error
                        self.printErrorInfo(jsonDict)
                    }
            }
        }
    }
    
    // MARK: Util
    
    /**
    构造请求的 URL (eg. /projects/:pid/members)
    
    :param: arg1 projects
    :param: item :pid
    :param: arg2 members
    */
    func requestURL(arg1: String, item: String = "", arg2: String = "", arg3: String = "") -> String {
        var url = "https://api.worktile.com/v1/" + arg1 + "/"
        
        if item.characters.count > 0 {
            url = url + item + "/"
        }

        if arg2.characters.count > 0 {
            url = url + arg2 + "/"
        }

        if arg3.characters.count > 0 {
            url = url + arg3
        }

        return url
    }
    
    /**
    输出错误信息
    
    :param: responseJSON 请求返回的 JSON Dictionary
    */
    func printErrorInfo(responseJSON : AnyObject) {
        if let responseJSON = responseJSON as? Dictionary<String,AnyObject> {
            if let errorCode = responseJSON["error_code"] , errorMessage = responseJSON["error_message"] {
                print("error:\(errorCode),\(errorMessage)")
            }
        }
    }
}

// MARK: Delegate

/**
*  Worktile 回调
*/
public protocol WorktileDelegate {
    /**
    授权完成
    
    :param: success 成功或者失败
    */
    func authorizeComplate(currentAuthorizeViewController: UIViewController, success: Bool)
}

// MARK: AuthorizeWebController

/**
*  授权登录的 WebViewController 回调给 Worktile
*/
protocol AuthorizeWebControllerDelegate {
    func authorizeComplate(authorizeCode: String?)
}

/**
*  授权登录的 ViewController
*/
class AuthorizeWebController : UIViewController , UIWebViewDelegate {
    
    var url: String
    var webView = UIWebView()
    var delegate: AuthorizeWebControllerDelegate

    init(url: String, delegate: AuthorizeWebControllerDelegate) {
        self.url = url
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        
        webView.delegate = self
        self.view = webView
        
        // Nav
        if let _ = self.presentingViewController {
            let x = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: Selector("dismissViewController"))
            self.navigationItem.leftBarButtonItem = x
        }
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: url)!))
    }
    
    /**
    截取 NSURLRequest，从回调地址中读取 code

    */
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.URLString.hasPrefix(Worktile.redirectURI) {
            let code = request.URLString.componentsSeparatedByString("code=").last as String?
            self.delegate.authorizeComplate(code)
        }
        return true
    }
    
    func dismissViewController() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
