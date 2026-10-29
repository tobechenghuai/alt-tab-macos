# AltTab Custom

定制修改日期：2026-10-29。个人使用的 GPL-3.0 定制版本，保留 [Louis Pontoise（lwouis）与 AltTab contributors](https://github.com/lwouis/alt-tab-macos) 的署名、源码结构与许可证。源码依据为本仓库 `master` 的 `4d5f01c5f34c9b8fd10ac3b3986fb4c73e83e9e8`；本地功能范围按该提交实际实现确定。

## 功能清单与审计

完整调用链、设置入口、权限状态、测试依据和修改范围见 [本地高级功能审计表](docs/custom-feature-audit.zh-CN.md)。

| 功能 | Custom 行为 |
| --- | --- |
| 窗口搜索 | 支持标题、应用名、大小写折叠、中英文及原生 IME；可直接输入未被当前命令占用的字符进入搜索 |
| 搜索导航 | 方向键选择、Enter 激活；Escape 依现有模式清除搜索或关闭切换器 |
| 外观 | Thumbnails、App Icons、Titles；保留 Light、Dark、System 和样式自定义 |
| Auto Size | 复用原有大、中、小候选布局测量；保留手动尺寸、多显示器与 HiDPI 计算 |
| 快捷键 | 最多九组；独立触发键、筛选、外观、主题、尺寸、释放行为及预览覆盖 |
| 筛选 | 应用、Space、显示器、最小化、隐藏、全屏、无窗口应用和窗口顺序均沿用现有设置 |
| 系统集成 | 保留辅助功能、屏幕录制、焦点管理、窗口事件、睡眠唤醒恢复与缩略图缓存 |

这些本地实现通过现有 `Preferences`、枚举和运行时解析器直接提供。当前基础提交已移除商业许可证、试用和付费状态判断，Custom 沿用这一状态。源码以外的商业服务、支付、许可证签发及服务端能力属于各自服务提供方。

直接输入搜索沿用已有原生搜索框和当前窗口模型。已有匹配的 hold-key 命令（例如激活修饰键加 W）保留命令语义；独立的搜索快捷键与 Search on Release 继续可用。其他 Space 的窗口是否进入候选集由当前快捷键的 Space 筛选设置决定，选择 All 即可包含其他 Space。

## 与上游及个人旧构建的区别

- 应用名称为 **AltTab Custom**，稳定 Bundle ID 为 `com.tobechenghuai.alttab-custom`。专用 `ALTTAB_*` 变量由主应用的 base 配置使用，保持依赖包与测试目标的产品名称和身份。
- 设置域、CLI 端口、登录项和 macOS 授权跟随独立 Bundle ID。原应用的数据与身份继续保留；可通过原应用的“导出设置”和 Custom 的“导入设置”迁移支持的偏好。
- 构建版本为 `0.0.<Actions运行编号>`；Custom 偏好版本单独标记为 `11.0.0`，避免构建编号触发旧版本的快捷键迁移。
- Custom 反馈入口打开 Fork 的 issue 页面，由用户在浏览器中提交。
- 更新检查、商业授权流程及 Sparkle 发布链在基础提交中已删除。CI 仅向当前仓库的 GitHub Artifacts 上传应用和校验文件。
- 后台截图开关、默认关闭的本地 CLI、诊断附件移除、统计开关与历史清除继续保留。

## 核心修改位置

| 文件 | 作用 |
| --- | --- |
| `src/events/KeyboardEvents.swift` | 在活动切换器接收的本地按键上接入直接输入搜索 |
| `src/switcher/main-window/TilesView.swift`、`src/switcher/state/SearchModeResolver.swift` | 重用搜索状态和原生字段编辑，保留菜单、快捷键与 IME 路由 |
| `src/preferences/PreferencesMigrations.swift` | 分离 Custom 偏好版本与应用构建编号 |
| `src/preferences/settings-window/tabs/AboutTab.swift` | 修复 About 内容行索引 |
| `src/App.swift`、`Info.plist`、`config/base.xcconfig` | 读取源码仓库标识，Custom 反馈指向 Fork |
| `config/custom.xcconfig` | 独立身份、CUSTOM_BUILD 标志及 ad-hoc 签名 |
| `.github/workflows/build-custom.yml`、`scripts/ci/` | 依赖、Xcode、测试、完整 Debug/Release 构建、校验和打包 |

## GitHub Actions

1. 将 `master` 推送到自己的 Fork，在 Actions 页面启用工作流。
2. 工作流 **AltTab Custom ARM64** 响应向 `master` 推送，也支持 **Run workflow** 手动触发。执行与重新运行均限制为仓库所有者。
3. 使用 GitHub 托管 Apple Silicon runner `xcode-27`。脚本读取 `xcode-select -p`，检查 runner 当前 Xcode 和 macOS SDK（至少 26），再将实际 Developer 目录传给后续步骤。
4. 检查本地 Swift Packages、资源和本地化，执行 Python 构建测试与 Debug Swift 单元测试，完整编译 Debug 应用，再完整编译 Release 应用。
5. 校验 Bundle ID、可执行文件、签名资源、精确 `arm64` 架构、ad-hoc 签名、ZIP 完整性和 SHA-256。

构建使用 runner 已安装的工具和仓库内的 vendored 依赖。`GITHUB_TOKEN` 仅具备仓库内容读取权限；checkout 关闭凭据持久化。Secrets 可保持为空。

## 下载和安装

成功运行的 **Artifacts** 区域提供 `AltTab-Custom-arm64-<运行编号>-<重试编号>`，保留 30 天，访问权限跟随仓库。

解压下载的 Artifact 后得到：

```text
AltTab-Custom-arm64.zip
SHA256SUMS.txt
```

在这个目录执行：

```zsh
shasum -a 256 -c SHA256SUMS.txt
ditto -x -k AltTab-Custom-arm64.zip .
```

应用 ZIP 包含 `AltTab Custom.app`、`LICENCE.md` 和本文。退出正在运行的旧实例，将 `AltTab Custom.app` 移入 Applications 后启动。

## 签名和系统权限

构建使用 ad-hoc 签名（身份 `-`），由系统 `codesign` 验证。它适合私人测试，具有与 Developer ID、公证版本不同的 Gatekeeper 信任属性。首次运行按 macOS 提示在“系统设置 → 隐私与安全性”中允许该应用，并为 **AltTab Custom** 授予辅助功能和屏幕录制权限。

独立 Bundle ID 会使用独立授权。后续 ad-hoc 构建的代码身份也可能使系统再次要求授权。安装和重启流程保留 quarantine 属性。系统权限检查完整保留。

## 本地构建

在带完整 Xcode 的 Apple Silicon Mac 上执行：

```zsh
bash scripts/ci/select-xcode.sh
bash ai/test.sh -xcconfig config/custom.xcconfig CODE_SIGNING_ALLOWED=NO
bash ai/build.sh -xcconfig config/custom.xcconfig CODE_SIGNING_ALLOWED=YES ARCHS=arm64
bash scripts/ci/build.sh
```

Release 产物位于 `artifacts/`。Linux 可执行 Python 测试和静态检查；AppKit、Swift macOS 单元测试和完整应用编译由 Mac 或 GitHub runner 执行。

## 验证状态与已知限制

每次修改后的实际检查结果记录在 [验证记录](docs/custom-build-validation.zh-CN.md)。源文件检查和模拟工具测试分别证明静态约束与脚本控制流；Swift 测试和完整应用构建结果由实际执行记录确认。

以下项目依赖真实 Mac 图形会话与系统授权：中文 IME 首字符及候选窗口、跨 Space 激活、全屏应用、多显示器与 Retina 切换、最小化与隐藏窗口、同一应用多窗口、大量窗口、快速切换、睡眠唤醒和 VoiceOver。

## 同步上游 master

```zsh
git remote add upstream https://github.com/lwouis/alt-tab-macos.git
git fetch upstream master
git merge upstream/master
```

已有 `upstream` 时直接执行 fetch 和 merge。处理冲突时重点检查：Custom 配置与 Bundle ID、直接输入搜索、`Preferences` 与新增偏好迁移、九组快捷键、基础提交已移除的授权/更新路径，以及 workflow 中的外部服务调用。上游增加偏好迁移时，需要同步审查并推进 Custom 的偏好版本标记。随后重新运行测试与完整构建。

## GPL-3.0 与归属

完整 GPL-3.0 文本保存在 `LICENCE.md`，原始来源为 Louis Pontoise（lwouis）及 AltTab contributors。Custom 改动由当前 Fork 的提交历史记录。分发修改后的二进制时，应同时提供其对应源码与修改说明；当前 Fork 的提交与 Actions 运行关联提供源码定位。第三方依赖继续遵循各自许可证与仓库现有署名说明。

源代码：https://github.com/tobechenghuai/alt-tab-macos

上游：https://github.com/lwouis/alt-tab-macos
