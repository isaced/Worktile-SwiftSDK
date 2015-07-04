# Worktile Swift SDK

基于官方 Rest API 使用 Swift 2.0 为 Worktile 封装的一套 SDK，方便 Cocoa 开发者使用 Swift 进行开发。

> 计划支持 iOS 和 OS X，目前先针对 iOS 平台进行开发完善，后续会支持 OS X 平台

### 开发环境：

- Xcode 7.0 beta
- Swift 2.0
- iOS8 +

### 实现功能

- [x] OAuth2 登录授权
- [x] 获取用户信息
- [x] 团队
- [x] 项目
- [ ] 任务组
- [ ] 任务
- [ ] 日程
- [ ] 文件
- [ ] 话题
- [ ] 文档

> 这里可以随时查看开发进度，也欢迎有兴趣的开发者来添砖加瓦！
> 
> 有任何问题也请您让我知道，我会积极地维护这个项目。

### 使用

本项目内包含一个 iOS Demo，基本实现了所有 SDK 方法的调用和说明，这里也简单介绍一下：

首先 SDK 内包含完整的 OAuth2 认证授权流程，首先需要你在 Worktile 开放平台创建你自己的 APP 并拿到 App Key，然后用以下代码初始化 SDK 类：

``` 
let worktile = Worktile(appKey: "xxxx")
```

然后可以通过 `needAuthorize` 属性来判断用户是否需要进行授权登录，如果需要则通过 `authorizeViewController()`方法来得到一个登录用的 ViewController，用户在这个视图控制器上输入用户名密码连接 Worktile 并得到 *access token* ，你可以通过给这个 worktile 实例设置 `delegate<WorktileDelegate>` ，然后通过 `authorizeComplate` 方法来接收用户登录授权成功或失败的消息。

一旦授权成功，SDK 会记录并保存下来 *access token* ，当然也包括 token 的过期时间，过期时间内就可以直接使用上次请求的 *access token*，不用自己保存或重新授权了。

> 注意：Worktile 类并不是单例，所以你需要自己持有它！

<img src="http://ww1.sinaimg.cn/large/79439f49gw1etpq05ic7aj20hs0vkdhi.jpg" width = "320" height = "568" align = "center" />

### 参考

- [API 接口文档](https://open.worktile.com/wiki/)

### 感谢

🙏 [Alamofire](https://github.com/Alamofire/Alamofire)

🙏 [Carthage](https://github.com/Carthage/Carthage)

### 开源许可协议

MIT