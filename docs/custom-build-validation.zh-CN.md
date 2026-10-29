# Custom 构建验证记录

- 基础提交：`4d5f01c5f34c9b8fd10ac3b3986fb4c73e83e9e8`
- 工作分支：`master`
- 本地验证日期：2026-10-29
- 环境：Linux；构建与 AppKit 运行验证通过 macOS 执行。

## 实际执行结果

| 检查 | 结果 | 范围 |
| --- | --- | --- |
| Python 构建与功能源码检查 | 19 项通过 | 真实构建脚本的模拟执行、Xcode/SDK 依赖、独立 Bundle ID、arm64、ad-hoc、打包/校验失败，以及实际功能枚举和 schema 约束 |
| 插画测试 | 6 项通过 | 资源生成器及图形数据 |
| 插画生成状态 | 通过 | 29 个插画，生成资源与源码一致 |
| 工程引用与测试目标归属 | 通过 | 205 个 app 源文件、151 个单元测试目标源文件；新增用例所在文件均在 Test scheme 对应目标内 |
| Swift 语法解析 | 11 个改动文件通过 | 相对基础提交的新增语法解析错误为零；这是语法检查 |
| 翻译一致性 | 21 种语言、276 个应用键通过 | 便携式键扫描、格式占位符、非空译文；macOS genstrings/plutil 完整校验待执行 |
| Workflow YAML、Shell、Info.plist | 通过 | 触发条件、只读权限、官方 Action 完整 SHA、30 天保留、脚本语法和 plist 格式 |
| `ai/test.sh` | 在本地化检查处停止 | Python 部分通过，Linux 缺少 plutil；Swift 测试尚待 macOS 执行 |
| 完整 Debug app 命令 | 退出码 127 | Linux 缺少 xcodebuild |
| Release 打包脚本 | 退出码 127 | Linux 缺少 xcodebuild；实际 app、签名和 ZIP 尚待 macOS 构建 |

新增 Swift 回归方法：8 个，包括 Custom 条件编译下的 schema 用例。既有匹配、布局、快捷键、窗口筛选、Space、焦点和设置迁移测试继续由 `ai/test.sh` 执行。

## Actions 与产物

工作流：`.github/workflows/build-custom.yml`。它先执行资源与单元测试，再完整编译 Debug app 和 Release app。产物为 `AltTab-Custom-arm64.zip` 与 `SHA256SUMS.txt`，保留 30 天。

本记录产生于本地提交前。提交、推送、Actions 运行及 Artifact 的实际状态以最终交付报告和对应 GitHub 运行页面为准。

## 真机验证清单

- [ ] 初次安装、Gatekeeper 允许、辅助功能和屏幕录制授权。
- [ ] 直接输入、中文 IME 首字符与候选窗口、英文、大小写、方向键、Enter、Escape。
- [ ] 三种外观、深浅主题、长标题、缩略图缓存和实时窗口增删/改名。
- [ ] 九组快捷键添加、删除、冲突、重置、独立筛选与外观，退出重启后保留。
- [ ] 不同 Space、最小化、隐藏、全屏，以及同一应用的多个窗口。
- [ ] 多显示器、Retina/HiDPI、不同分辨率、屏幕边缘和 Auto Size/手动尺寸。
- [ ] 大量窗口与快速连续切换的响应、焦点正确性。
- [ ] 系统睡眠唤醒后的跟踪、快捷键和权限恢复。

## 本次修改文件

- `.github/workflows/build-custom.yml`
- `.github/workflows/personal-build.yml`
- `.gitignore`
- `CUSTOM_BUILD.md`
- `Info.plist`
- `config/base.xcconfig`
- `config/custom.xcconfig`
- `config/personal.xcconfig`
- `docs/contributing.md`
- `docs/custom-build-validation.zh-CN.md`
- `docs/custom-feature-audit.zh-CN.md`
- `docs/personal-build.zh-CN.md`
- `scripts/ci/build.sh`
- `scripts/ci/select-xcode.sh`
- `scripts/ci/verify_archive.py`
- `scripts/ci/verify_bundle.py`
- `scripts/tests/test_custom_features.py`
- `scripts/tests/test_personal_build.py`
- `src/App.swift`
- `src/api/Secrets.swift`
- `src/events/KeyboardEvents.swift`
- `src/preferences/PreferencesMigrations.swift`
- `src/preferences/PreferencesMigrationsSpecs.md`
- `src/preferences/PreferencesMigrationsTests.swift`
- `src/preferences/settings-window/tabs/AboutTab.swift`
- `src/switcher/SearchSpecs.md`
- `src/switcher/SearchTests.swift`
- `src/switcher/main-window/TileGridLayoutSpecs.md`
- `src/switcher/main-window/TileGridLayoutTests.swift`
- `src/switcher/main-window/TilesView.swift`
- `src/switcher/state/SearchModeResolver.swift`
- `src/switcher/state/SearchModeResolverSpecs.md`
- `src/switcher/state/SearchModeResolverTests.swift`
