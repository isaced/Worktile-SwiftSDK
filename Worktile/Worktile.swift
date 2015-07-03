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

public class Worktile : AuthorizeWebControllerDelegate {
    
    /// 申请应用时分配的 AppKey
    public let clientID: String
    
    /// 授权回调地址
    public static let redirectURI = "https://worktile_redirect"
    
    /// OAuth2 授权拿回来的 code
    public var authorizeCode: String?
    
    /// 授权后访问 API 的令牌
    public var accessToken: String?
    
    /// 用于刷新获取最新的access_token
    public var refreshToken: String?
    
    /// 根据 /oauth2/authorize 组装拼接的 OAuth2 授权地址
    public var authorizeURL: String {
        return "https://api.worktile.com/oauth2/authorize?client_id=\(clientID)&redirect_uri=\(Worktile.redirectURI)&display=mobile"
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

                    var jsonDict = JSON as! [String:AnyObject]

                    // Success
                    if let accessToken = jsonDict["access_token"] as? String {
                        self.accessToken = accessToken
                    }

                    if let refreshToken = jsonDict["refresh_token"] as? String {
                        self.refreshToken = refreshToken
                    }
                    
                    
                    // Error
                    self.printErrorInfo(jsonDict)
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
    
    
    
    // MARK: Util
    
    /**
    构造请求的 URL (eg. /projects/:pid/members)
    
    :param: arg1 projects
    :param: item :pid
    :param: arg2 members
    */
    func requestURL(arg1: String, item: String = "", arg2: String = "") -> String {
        var url = "https://api.worktile.com/v1/" + arg1 + "/"
        
        if item.characters.count > 0 {
            url = url + item + "/"
            
            if arg2.characters.count > 0 {
                url = url + arg2
            }
        }

        return url
    }
    
    /**
    输出错误信息
    
    :param: responseJSON 请求返回的 JSON Dictionary
    */
    func printErrorInfo(responseJSON : AnyObject) {
        if let errorCode = responseJSON["error_code"] , errorMessage = responseJSON["error_message"] {
            print("refreshToken - error:\(errorCode),\(errorMessage)")
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
