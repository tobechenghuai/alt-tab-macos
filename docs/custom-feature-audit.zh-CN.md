# 本地高级功能审计

基础提交：`4d5f01c5f34c9b8fd10ac3b3986fb4c73e83e9e8`（master）。审计范围为该提交实际包含的本地实现。源码中原商业授权模块已移除，当前入口、偏好和运行时直接使用本地功能。`SF Pro Text`、设备型号中的 Pro、Accessibility subscription 和历史规格中的试用措辞属于关键词命中的其他含义。

## 功能映射

| 功能 | 实现与调用链 | 设置入口 | 权限/依赖 | 实现状态与本次处理 | 对原功能的影响 |
| --- | --- | --- | --- | --- | --- |
| 标题与应用搜索 | `KeyboardEvents` → `TilesView` → `Windows.updateSearchQuery` → `Search.ensureCache` → `SearchTestable.tierMatch` → `WindowOrderResolver` | Controls 的搜索快捷键、After keys released: Search；本次新增直接输入 | 活动切换器和原生字段编辑；依赖已跟踪窗口模型 | 匹配与排序已有实现；新增直接输入策略和中英文回归测试 | 保留命令键、菜单、快捷键优先级及缓存 |
| 中文、英文与 IME | `SearchTestable.normalize`；`TilesView.hasMarkedText`、`SearchModeResolver.routeKey` | 同一原生搜索框 | IME 使用 AppKit text input context | 已有 Unicode、IME 路由；补充中文标题和高亮范围测试 | 继续使用系统输入法 |
| 搜索选择、Enter、Escape | `SearchModeResolver` → `ShortcutActions` → `App.focusTarget` / `TilesView.disableSearchMode` / `App.hideUi` | 原有 when-active 快捷键设置 | 保留快捷键冲突与会话判断 | 已实现，保留既有模式语义 | Enter 激活当前结果；Escape 按会话入口退出搜索或切换器 |
| 其他 Space 的搜索 | `WindowFilterResolver` → `Windows.shouldDisplay` → `Search.matches` | 每组快捷键 Filtering 的 Spaces | Accessibility、Space 跟踪；受用户候选筛选影响 | 已实现；All Space 筛选包含其他 Space 窗口 | 保留筛选设置和窗口枚举策略 |
| Thumbnails / App Icons / Titles | `AppearanceStylePreference.allCases` → `AppearanceTab` → `Preferences.effectiveAppearanceStyle` → `Appearance.applyConcreteSize` → `TileView` | Appearance 样式卡片；每组快捷键 Appearance 面板 | 当前三种枚举值均直接可用；缩略图按系统权限与开关捕获 | 三种模式已有完整实现 | 保留缓存、图标、标题、省略和样式测量 |
| Light / Dark / System 与样式自定义 | `AppearanceThemePreference` → `Appearance.currentTheme/updateTheme`；`CustomizeStyleSheet`、`AnimationsSheet` | Appearance、Customize、Animations | 现有本地偏好；macOS 图形 API 能力按系统版本选择 | 已实现 | 保留系统主题及辅助显示设置 |
| Auto Size | `AppearanceSizePreference.auto` → `TilesView.resolveAutoSize` → `TileGridLayout.firstSizeThatFits` → `Appearance.applySize` | Appearance 的 Size；每组快捷键尺寸覆盖 | 真实 tile 测量、搜索框保留高度、屏幕宽高和 backingScaleFactor | 已实现；补充 500 窗口、多宽度、LTR/RTL 回归 | 保留 Large/Medium/Small 手动设置与滚动 |
| 九组快捷键 | `Preferences.maxShortcutCount=9` → `ControlsTab.addShortcutSlot` → `ATShortcut` / `KeyboardEventsTestable.globalShortcutsIds` | Controls 的加减按钮和触发键编辑器 | 数量边界和快捷键冲突检查 | 已实现；新增跨重启与迁移保留九组配置测试 | 默认两组继续保留，可增加至九组 |
| 每组独立筛选 | `ShortcutEditor.FilteringPane` → indexed `Preferences` → `WindowFilterResolver` | Controls → Filtering | 应用、Space、屏幕、最小化、隐藏、全屏、无窗口应用、排序 | 已实现；复用现有筛选测试 | 每组设置独立，保留原窗口状态语义 |
| 每组独立外观与释放行为 | `ShortcutEditor.AppearancePane` / `ShortcutOverrideBinding` → `Preferences.hasOverride/effective*` → 活动快捷键会话 | Controls → Appearance | Style、Size、Theme、ShortcutStyle、Preview 五类覆盖 | 已实现；保留覆盖继承、重置与缓存失效 | 未设置覆盖时使用全局偏好 |
| 预览、手势与辅助设置 | `PreviewPanel`、`TrackpadEvents`、`ControlsTab`、`SystemPermissions` | 原有 Controls / Appearance / 权限页面 | 系统权限、用户开关和平台支持 | 源码保留并可配置；相应内核测试继续运行 | 保留事件驱动与后台截图策略 |
| 偏好持久化 | `Preferences.write` → UserDefaults 与缓存失效；`PreferencesMigrations` | 原有设置、导入、导出与重置 | Custom 独立 Bundle ID 和偏好域 | 修复构建编号反复触发旧迁移的问题，使用独立 schema 标记 | 保留九组快捷键和外观设置；旧版本通过显式导入迁移 |
| 设置可进入性 | `AboutTab.makeContentView` → `GridView` | About / Settings | 两行内容对应索引 0、1 | 修复越界行索引 2 | 保留原样式和原作者支持入口 |

## 权限策略决定

本提交通过现有 `Preferences`、可用选项枚举和运行时解析器提供全部已有本地高级功能。源码已完成商业状态移除，新增一层始终返回 true 的商业权限对象会形成重复状态，因此沿用现有统一偏好入口。Custom 的构建差异集中于 `config/custom.xcconfig` 的 `CUSTOM_BUILD` 标志，用于身份、反馈边界和偏好 schema。

系统辅助功能、屏幕录制、会话有效性、快捷键冲突和平台 API 可用性检查继续保留。支付记录、许可证密钥、服务端激活和商业订阅均由原服务提供方负责。

## 自动化依据

- 搜索：`SearchTests`、`SearchModeResolverTests`、`SearchFieldEditingTests`、`WindowOrderResolverTests`。
- 外观/布局：`AppearanceTests`、`TileGridLayoutTests`、`TilePoolTests`。
- 筛选/Space/窗口状态：`WindowFilterResolverTests`、`SelectionResolverTests`、`WindowEventReducerSpaceTests`、`WindowEventReducerMinimizeTests`。
- 快捷键与冲突：`KeyboardEventsTests`、`ShortcutModifierResolverTests`、`ModifierReleaseLogTests`、`CustomRecorderControlTests`。
- 持久化：`PreferencesMigrationsTests.testNineShortcutSettingsAndAppearanceOverridesSurviveReopeningAndMigration`，包含重新创建 UserDefaults 和重复执行迁移。
- CI：`scripts/tests/test_personal_build.py` 验证真实脚本的模拟执行；bundle 和 ZIP 校验由独立 Python 函数执行。

新增 Swift 用例通过 Xcode Test scheme 执行，执行状态以验证记录为准。图形会话、真实输入法、多显示器和跨 Space 焦点需要真机验证。
