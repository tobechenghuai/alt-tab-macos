# 源码安全与隐私审计

- 审计日期：2026-10-29
- 审计提交：`c500294bdb01186011a5c64a412b04cef9931bef`
- 审计方式：静态源码审查与关键调用链追踪
- 执行环境：Linux
- 审计范围：应用联网入口、截图与键盘事件、授权、崩溃报告、反馈、本地 IPC、自启动及构建脚本

本文记录该提交下的审查结果。代码链接中的行号以该提交为准。风险等级表示隐私影响和修复优先级；恶意意图需要独立证据支持。

## 后续整改记录（2026-10-29）

用户授权整改后，工作区已实施以下变更。原始审计发现保留在后文，作为审计提交的历史记录。

| 原始发现 | 当前处理状态 |
| --- | --- |
| AUDIT-01 更新遥测 | 已删除更新检查、反馈前更新检查、更新菜单、Sparkle 依赖、appcast 配置及发布脚本 |
| AUDIT-02 授权信息上传 | 已删除授权激活、复核、设备指纹、授权 Cookie、激活 URL，以及试用限制和购买入口；外观、搜索和快捷键直接可用 |
| AUDIT-03 后台截图开关 | 已移除强制绕过参数，并在延迟截图任务调用系统 API 前重新检查设置；已补充策略规格与回归测试 |
| AUDIT-04 本地 CLI | 默认关闭消息端口；显式传入 `--enable-cli` 后开放当前进程的 CLI；已补充策略规格与回归测试 |
| CI 凭据保护 | 凭据改为步骤级传入，环境输出采用白名单，敏感脚本关闭命令追踪；签名使用临时 Keychain；清理失败保留恢复目录，Keychain 删除失败时尝试锁定，并支持重试 |
| 诊断附件上传 | 已完全移除应用诊断信息构建器、反馈诊断字段和崩溃附件回调；AppCenter 队列同时过滤新增附件和旧版本持久化附件 |
| 旧统计键清理 | 启动清理会移除 `triggersAppIcons`、`triggersTitles`、`triggersAutoSize`，同时丢弃对应缓存和待写入记录；当前统计键保持原有数据 |
| 本地统计控制 | 通用设置新增本地使用统计开关与清除使用历史入口；清除涵盖统计缓存、待写入记录、当前及旧统计键和搜索提示历史 |
| 安装隔离属性 | 已删除安装重启脚本中的 quarantine 清除命令，复制与重启流程保留系统隔离属性 |

CLI 的具体操作与开放后的信息范围见 [本地 CLI 说明](local-cli.md)。已启用 CLI 的进程继续向可连接端口的本地进程提供支持的查询和操作。

验证结果：工程结构、源码路径与新增测试的目标归属检查通过；修改文件的 Swift 语法解析检查通过；插画生成检查和 6 项插画测试通过。完整构建与 Swift 单元测试需要在 macOS 上继续执行：当前 Linux 环境缺少 `plutil`、`genstrings` 和 `xcodebuild`。新增 Swift 回归测试的执行及 macOS 动态抓包、权限边界复核属于待验证项。

原始审计中已删除文件的代码依据可通过 `git show c500294:文件路径` 查看。崩溃报告、用户主动提交反馈、本地使用统计及其余安全加固事项继续按后文的审计范围记录。

第二批整改验证：9 项 CI 凭据模拟测试通过，覆盖日志输出、临时签名材料、导入失败、配置恢复、清理边界、公证和符号上传路径；工作流结构及 Shell 语法检查通过。当批新增脱敏与旧键清理测试已加入单元测试目标；第三批移除诊断附件功能时同步删除脱敏实现和测试。Swift 单元测试、实际签名、公证及发布流程需要在 macOS 上继续验证。

第三批整改：CI 恢复配置、删除生成配置、删除 Keychain、删除临时目录的失败边界均保留可重试状态，删除 Keychain 失败会尝试锁定。安装脚本保留 quarantine 属性。统计开关默认延续开启状态，关闭后停止新增计数和提示历史持久化；清除历史保留用户设置与开关状态。反馈请求仅包含标题、正文和类别，崩溃报告保留现有发送策略；自动诊断附件构建和上传路径已删除，SDK 对旧队列中的附件也执行过滤。

第三批验证：13 项 CI 凭据模拟测试通过，包含四项清理失败与重试用例；工程引用、源文件目标归属、Shell 语法、6 项插画测试和资源生成检查通过。53 个修改或新增 Swift 文件的解析检查通过（两处既有语法解析器诊断保持原样）。21 种语言的 276 个应用文案键、占位符和非空译文通过便携式一致性检查；完整本地化校验继续依赖 macOS 的 `genstrings` 与 `plutil`。AppCenter 附件过滤补丁可从原始 vendor 文件复现当前源码。新增 7 项统计存储测试和 1 项提示历史清除测试已加入单元测试目标，覆盖开关、缓存、延迟写入和历史清除。macOS 构建、Swift 测试、安装隔离属性、实际 Keychain 清理及旧 AppCenter 队列的网络载荷仍需动态验证。

当前后续待办包括：恢复动态库验证、CLI 启用后的调用方认证、预编译依赖的来源与完整性校验，以及在 macOS 上完成构建和运行验证。本地统计当前仍使用秒级时间戳，保留窗口为 365 天。

## 原始审计结论（对应审计提交）

审计时源码确认存在默认开启的遥测、授权流程中的设备信息上传，以及本地隐私暴露面。对于隐藏远控后门、密码窃取和截图外传，该次静态审查的证据不足。

优先处理以下四项：

1. 更新检查附带遥测，缺少独立关闭选项。
2. 授权激活上传原始设备 UUID、电脑名称及试用开始时间。
3. 部分后台截图路径越过“后台捕获窗口”设置。
4. 正式版本地 CLI 返回窗口信息，缺少调用方身份校验。

## 主要发现

### AUDIT-01：更新检查附带默认遥测

**风险等级：中。状态：源码确认。**

应用默认开启自动检查更新。请求 `https://alt-tab.app/appcast.xml` 时，自定义参数包含：

| 参数 | 内容 |
| --- | --- |
| `version` | 应用版本 |
| `macos` | macOS 版本 |
| `arch` | 系统架构 |
| `lang` | 首选语言 |
| `tier` | 授权状态 |
| `day` | 试用天数，存在试用开始记录时附带 |

`SparkleDelegate.feedParameters` 每次都返回这些字段，传入的 `sendingSystemProfile` 参数被忽略。Sparkle 自身的系统信息发送开关因此无法控制这组自定义字段。

将更新策略设为手动可以停止周期检查。手动检查及反馈流程中的更新检查仍会携带上述字段。购买链接还通过 `via` 参数携带试用天数和入口代码，用于转化归因。

**影响：** 更新功能同时承担系统信息和试用状态采集，用户缺少独立控制这些附加数据的选项。

**建议：** 为附加遥测提供明确说明和独立选择权，将更新必需参数与产品分析参数分别控制。

代码依据：

- 自定义发送字段，SparkleDelegate.swift:33（审计提交中的 src/vendors/SparkleDelegate.swift）
- [默认更新与崩溃策略，Preferences.swift:39](../src/preferences/Preferences.swift#L39)
- [更新策略应用，PreferencesEvents.swift:95](../src/events/PreferencesEvents.swift#L95)
- [反馈前更新检查，FeedbackWindow.swift:148](../src/secondary-windows/FeedbackWindow.swift#L148)
- [购买入口归因，Endpoints.swift:15](../src/api/Endpoints.swift#L15)

### AUDIT-02：授权流程上传原始设备标识及电脑名称

**风险等级：中。状态：源码确认。**

激活请求发送到 `https://alt-tab.app/api/v1/license/activate`，包含：

| 字段 | 来源与内容 |
| --- | --- |
| `license_key` | 输入或激活 URL 提供的授权密钥 |
| `fingerprint` | 优先读取 `IOPlatformUUID`；读取失败时使用 Keychain 中保存或新生成的随机 UUID |
| `machine_name` | 系统电脑名称，移除控制字符并限制长度 |
| `trial_started_at` | 精确到秒的试用开始时间，存在记录时附带 |

原始设备 UUID 具有较强的设备关联能力。电脑名称可能包含姓名或公司信息。源码注释明确说明，试用开始时间用于分析试用到购买的转化耗时。

数据在服务器判断密钥是否有效之前发送。手动激活和自定义 URL 激活都能触发该路径。已激活用户在启动时按 30 天间隔条件进行联网复核，复核请求包含授权密钥、实例 ID 和电脑名称。

**影响：** 服务器可以把稳定设备标识、设备名称和试用时间与授权记录关联。

**建议：** 使用应用专属随机标识，为电脑名称和转化分析数据提供说明与选择权。调整标识方案时保留既有授权的迁移兼容性。

代码依据：

- 激活请求，RemoteLicenseClient.swift:24（审计提交中的 src/pro/license/RemoteLicenseClient.swift）
- 读取设备 UUID，MachineFingerprint.swift:9（审计提交中的 src/pro/license/MachineFingerprint.swift）
- 附加电脑名称，RemoteLicenseClient.swift:116（审计提交中的 src/pro/license/RemoteLicenseClient.swift）
- 复核条件，LicenseManager.swift:285（审计提交中的 src/pro/license/LicenseManager.swift）
- [URL 激活入口，App.swift:700](../src/App.swift#L700)

### AUDIT-03：关闭后台捕获后仍存在强制截图路径

**风险等级：中。状态：源码确认，运行时复现待验证。**

焦点变化的 `.applyFocus` 分支调用 `WindowThumbnails.captureFocusedInBackground`，后者以 `force: true` 调用 `refreshAsync`。截图条件包含：

```swift
Preferences.captureWindowsInBackground || SwitcherSession.isActive || force
```

因此，在满足其他截图条件时，`force` 允许后台捕获越过 `captureWindowsInBackground` 设置。

触发条件包括：

1. 用户已经授予录屏权限，且系统处于解锁状态。
2. 存在显示窗口截图的快捷键配置。
3. 切换器处于关闭状态，焦点变化进入上述分支。

**影响：** 关闭“后台捕获窗口”后，应用仍可能读取其他应用的窗口画面。已追踪的图像交付路径用于内存缩略图与预览缓存。

**验证步骤：** 在 macOS 上关闭“后台捕获窗口”，关闭切换器后改变窗口焦点，观察 `captureFocusedInBackground` 与实际截图 API 的调用。

**建议：** 让所有后台截图路径遵守该开关，或者为特殊捕获行为提供清楚且独立的用户控制。

代码依据：

- [焦点变化调用，TrackedWindowStateBridge.swift:189](../src/switcher/state/TrackedWindowStateBridge.swift#L189)
- [强制后台捕获入口，WindowThumbnails.swift:31](../src/switcher/state/WindowThumbnails.swift#L31)
- [截图条件，WindowThumbnails.swift:153](../src/switcher/state/WindowThumbnails.swift#L153)
- [设置界面说明，GeneralTab.swift:40](../src/preferences/settings-window/tabs/GeneralTab.swift#L40)
- [图像交付，WindowCaptureEvents.swift:271](../src/events/WindowCaptureEvents.swift#L271)

### AUDIT-04：本地 CLI 暴露窗口信息，缺少调用方身份校验

**风险等级：中。状态：源码确认，系统访问边界待验证。**

应用在正式版中创建固定名称的 `CFMessagePort`：`com.lwouis.alt-tab-macos.cli`。服务端接收字符串后直接解析并执行命令，代码中缺少调用方身份校验和用户授权步骤。

能够连接该端口的本地进程可以请求：

- `--list`：窗口 ID 和标题。
- `--detailed-list`：窗口标题、应用名称、Bundle ID、窗口位置、尺寸及窗口状态等信息。
- `--focus=`、`--show=`、`--hide` 等：执行窗口切换或界面操作。

**影响：** 窗口标题可能包含文档名、网页标题和项目名称。该接口形成向可访问端口的本地进程提供这些信息的通道。实际可访问进程范围受 macOS 会话及沙盒等系统边界影响，需要动态验证。

**建议：** 为 CLI 提供明确的启用控制，并通过能够验证调用方身份的 IPC 机制限制敏感查询和操作。

代码依据：

- [端口建立与请求处理，CliEvents.swift:1](../src/events/CliEvents.swift#L1)
- [返回窗口信息，CliEvents.swift:74](../src/events/CliEvents.swift#L74)
- [窗口操作命令，CliEvents.swift:181](../src/events/CliEvents.swift#L181)

## 其他已确认的数据处理行为

| 行为 | 触发与数据范围 | 审查判断 |
| --- | --- | --- |
| 崩溃报告 | 默认先询问用户；发送到 AppCenter，附带崩溃信息及应用设置、系统、硬件诊断信息 | 用户确认后上传；选择“始终发送”后可自动上传 |
| 意见反馈 | 向作者 API 提交标题、正文、反馈类别和诊断信息；界面提示创建公开 GitHub issue | 存在明确确认步骤，建议增加附件预览和脱敏功能 |
| 使用统计 | 本地保存触发、搜索事件及部分功能使用的秒级时间戳，保留窗口为 365 天 | 已追踪用途为本地统计与 Pro 提示；记录内容为事件时间与类别 |
| `TrackingTelemetryRecorder` | 记录窗口跟踪诊断事件 | 记录逻辑受 `#if DEBUG` 控制，正式版对应方法为空 |
| 授权 Cookie | 为作者域名写入授权层级 Cookie | 值为 `pro`、`proExpired` 或空字符串 |
| 开机自启动 | 默认启用，在 `~/Library/LaunchAgents` 写入启动当前应用的 plist | 属于设置控制的持久化行为 |
| 键盘事件监听 | 处理全局切换快捷键及修饰键顺序 | `ModifierReleaseLog` 的按键记录限定为已注册的切换组合键，使用容量受限的内存缓存 |

代码依据：

- [崩溃报告确认流程，AppCenterCrashes.swift:31](../src/vendors/AppCenterCrashes.swift#L31)
- [崩溃报告诊断附件，AppCenterCrashes.swift:94](../src/vendors/AppCenterCrashes.swift#L94)
- [AppCenter 默认服务地址，MSACAppCenter.m:39](../vendor/AppCenter/Sources/AppCenter/MSACAppCenter.m#L39)
- [反馈确认，FeedbackWindow.swift:351](../src/secondary-windows/FeedbackWindow.swift#L351)
- [反馈发送字段，FeedbackWindow.swift:425](../src/secondary-windows/FeedbackWindow.swift#L425)
- 诊断信息组成，DebugProfile.swift:16（审计提交中的 src/secondary-windows/DebugProfile.swift，当前已删除）
- [本地使用统计，UsageStats.swift:9](../src/util/UsageStats.swift#L9)
- [调试遥测编译条件，TrackingTelemetryRecorder.swift:10](../src/window-tracking/TrackingTelemetryRecorder.swift#L10)
- 授权 Cookie，LicenseCookie.swift:5（审计提交中的 src/pro/license/LicenseCookie.swift）
- [自启动，LoginItem.swift:10](../src/macos/LoginItem.swift#L10)
- [快捷键内存记录，ModifierReleaseLog.swift:86](../src/events/ModifierReleaseLog.swift#L86)

## 安全加固事项

### 应用权限边界

`app-sandbox` 设置为 `false`，`disable-library-validation` 设置为 `true`。应用拥有较宽的系统访问能力，并放宽动态库验证限制。建议逐项记录必要性，并评估收紧动态库验证的可行性。

依据：[alt_tab_macos.entitlements:5](../alt_tab_macos.entitlements#L5)。

### 安装流程修改 quarantine 属性

移动到 Applications 后的重启脚本执行 `xattr -d -r com.apple.quarantine`，递归删除目标应用的隔离属性。这属于主动修改系统安全标记的行为，建议重新评估其必要性。

依据：[MoveToApplicationsFolder.swift:158](../src/util/MoveToApplicationsFolder.swift#L158)。

### CI 将完整环境变量交给日志

发布工作流注入 AppCenter 凭据、Apple 相关凭据和 Sparkle 更新签名私钥，并执行包含 `env | sort` 的脚本。实际泄露程度取决于 CI 的脱敏能力与日志访问控制。

建议以允许列表输出构建所需的普通配置字段，并对凭据处理脚本中的命令追踪进行专项审查。

依据：[print_env.sh:6](../scripts/print_env.sh#L6)、[ci_cd.yml:5](../.github/workflows/ci_cd.yml#L5)。

## 验证边界

本次完成静态源码审查，源码保持原样。当前环境为 Linux，以下项目仍需后续验证：

1. 在 macOS 上抓取首次启动、更新检查、授权激活、授权复核、崩溃报告和反馈提交的实际网络流量。
2. 动态复现后台截图设置行为，并测试本地 CLI 在普通应用、沙盒应用及不同会话中的访问边界。
3. 验证 Sparkle 更新助手、CrashReporter 等预编译依赖的来源一致性及发布包签名。
4. 核对服务端的数据保留、访问控制和反馈公开内容；这些信息需要服务端实现或部署证据支持。

## 处理顺序

优先修复后台截图开关的覆盖范围，为更新遥测增加独立选择权，并收紧本地 CLI 的默认访问范围。随后减少授权流程中的设备信息采集，处理 CI 日志与动态库验证等加固事项，最后通过 macOS 动态验证补齐证据。
