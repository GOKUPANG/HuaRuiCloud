# 华睿云iOS客户端

浏览此文档可以使用Markdown预览器查看，或者登录到[gitlab](http://192.168.0.188:8082)中直接查看。

## 发布流程

 1. 代码方面：
	1. 关闭Log日志系统：在`Log.swift`文件中，将`DEBUG_LEVEL`设置为大于5即可，或者在`AppDelegate.swift`中，注释掉`setLogger()`;
	2. 确认没有使用私有API、广告ID（尤其是第三方库）；
	3. 检查信息收集功能（如友盟）可用；
	4. 所有修改完成之后，再真机中调试一遍或多遍，确认以上说的没有问题了就可以Archive生成app上传了。
 2. 上传：
	1. 确认app版本号大于已经上传的app版本，否则无法上传；
	2. 登陆到[iTunesConnect](http://itunesconnect.apple.com)创建新的app版本；
	3. 上传成功后，记得将源码提交到git服务器中，并写上详细的提交说明。
	4. 在`gitlab`上为上传的版本打上tag，或在终端中执行以下两条指令（举例打v1.2.5版本的tag）：

	```shell
	git tag a v1.2.5 -m 'v1.2.5版本的描述'
	git push origin v1.2.5
	```
 3. 等待1周左右，如果审核顺利的话，即可在AppStore中看到新版本的app。如果没有通过，就登陆到iTunesConnect查看具体被拒原因。如果苹果方面操作app不方便的话，可以录制一个视频，提交审核的时候在说明一栏附上视频地址。