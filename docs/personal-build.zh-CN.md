# 个人 Apple Silicon 构建

工作流位于 `.github/workflows/personal-build.yml`，使用 GitHub 托管的 `xcode-27` Apple Silicon runner。推送到 `master` 或手动运行时，仓库所有者可以执行构建；重新运行也会校验实际操作者。

## 启用与下载

1. 提交并推送这批改动，在 GitHub 的 Actions 页面启用仓库工作流。
2. 打开 **Personal Apple Silicon build**，点击 **Run workflow**，选择 `master` 并运行。后续向 `master` 推送会自动运行。
3. 运行成功后，在该次运行的 **Artifacts** 区域下载 `AltTab-arm64-运行编号-重试编号`。
4. 解压下载文件，得到 `AltTab-personal-arm64.zip` 和对应的 `.sha256` 校验文件。产物保留 14 天，可见性遵循仓库访问权限。

工作流直接运行资源检查、Python 构建流程测试和 Debug 配置的 Swift 单元测试，再构建 Release 应用。依赖来自仓库内的本地 Swift Packages；构建工具使用 runner 预装版本。两个 GitHub 官方 Actions 固定到完整提交 SHA。

## 构建与签名

- 目标架构为 `arm64`，适用于 Apple Silicon Mac。
- 应用版本为 `0.0.<GitHub运行编号>`；本地构建默认 `0.0.0`。
- `config/personal.xcconfig` 使用 ad-hoc 签名，签名身份为 `-`，Developer Team 与 AppCenter Secret 留空。构建直接使用系统 `codesign`，省去证书、Apple 账号、Keychain 导入和公证。
- 脚本在打包前检查 arm64 架构、完整签名和 ad-hoc 签名类型。应用包通过 `ditto` 打包，保留 bundle 结构和权限。
- 仓库原有 bundle ID 和开发者构建配置保留；个人构建通过显式配置覆盖签名身份。切换到 ad-hoc 构建属于签名身份变化，已有辅助功能和屏幕录制授权可能需要重新授予。

## 安装

在下载并解压出的两个文件所在目录执行：

```zsh
shasum -a 256 -c AltTab-personal-arm64.zip.sha256
ditto -x -k AltTab-personal-arm64.zip .
```

退出已运行的 AltTab，再将解压出的 `AltTab.app` 移至 Applications。ad-hoc 构建保留 quarantine 属性，首次打开按 macOS 提示在“系统设置 → 隐私与安全性”中允许该应用。启动后按应用提示授予辅助功能和屏幕录制权限。

## 自动化边界

工作流权限固定为 `contents: read`，checkout 使用 `persist-credentials: false`。构建只向 GitHub Artifacts 保存应用 ZIP 和校验文件，原发布链路中的 AppCenter 符号上传、上游网站通知、自动修改仓库、Release 创建和生产环境引用已删除。

运行所需参数均来自当前仓库和 GitHub 运行上下文；Secrets 配置可保持为空。旧的签名、公证、发布脚本、相关预编译工具与 semantic-release 依赖已删除。已在 GitHub 后台单独配置的旧 Secrets 和 production 环境可在仓库 Settings 中清理。

## 本地验证

```zsh
python3 -m unittest discover -s scripts/tests -p 'test_*.py'
bash ai/test.sh -xcconfig config/personal.xcconfig CODE_SIGNING_ALLOWED=NO
bash scripts/ci/build.sh
```

Python 测试通过模拟 macOS 工具，检查构建参数、架构和签名失败处理、打包范围、校验文件，以及工作流权限。实际 Swift 编译、签名和应用运行通过 macOS runner 验证。

runner 清单见 [GitHub 官方镜像说明](https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md)。签名行为见 [Apple 代码签名说明](https://developer.apple.com/library/archive/technotes/tn2206/_index.html)。
