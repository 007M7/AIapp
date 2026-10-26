# iPhone 构建与产物管理

> 2026-10-03 · 当前 Windows 没有 Swift／Xcode，不能执行 iOS 编译或模拟器截图。本轮工具改动完成静态检查后仍需 macOS 编译。

## 1. 单一构建入口

工程定义：`ios/project.yml`；Swift／资源：`ios/AIFigure/`；构建入口：仓库根执行 `bash ios/tools/build-ipa.sh`。每次从 project.yml 重生工程，不能因磁盘上已有 xcodeproj 跳过生成。本地和 Actions 调用同一入口，避免两个 xcodebuild 命令逐步漂移。

移植自测入口：`bash ios/tools/run-selftests.sh`。将自测顶层程序作为 main.swift 与协议源码一起编译后运行；不能用 `swift selftest.swift 其他.swift` 的脚本参数形式声称其他文件已参与编译。

构建流程：检查工具→生成工程→移植自测→Release iphoneos 未签名编译→校验应用名与蓝牙权限→打包 IPA→保存 metadata（commit、dirty、版本、构建时间、Xcode、包 SHA256）。临时目录退出清理；失败不覆盖已有成功产物。

## 2. 云构建与签名

已有 `.github/workflows/ios-unsigned.yml` 手动触发，权限限 contents:read，调用同一脚本；上传 IPA、metadata 和日志。云端只构建已提交并推送的代码；本轮未推送的代码不会因旧 run 成功自动获得验证。

未签名 IPA 不是可直接安装的发布包。签名、安装与真机仍按 ios/README 路线由人执行；远程推送、支付、小组件与 OTA 不因构建成功而解锁。

## 3. 产物与门禁

`ios/dist/`、生成 xcodeproj、build、Payload 不提交。记录源提交及 dirty 状态，不以旧 IPA 代表新改动。构建日志不得打印 token、密钥或用户内容；上传日志前保留最小必要信息。

旧基线：7e82e87 的 [run 36817476681](https://github.com/007M7/AIapp/actions/runs/36817476681) 于 2026-10-01 成功；它只能证明该提交能编译。本轮状态以 VALIDATION 为准。
