# 天机录 App Store 提交指南

> 本文档包含提交到 App Store 审核所需的全部配置信息和操作步骤。

---

## 一、App Store Connect 创建 App

### 基础信息

| 字段 | 值 |
|------|-----|
| 平台 | iOS |
| App 名称 | 天机录 |
| 主要语言 | 简体中文 |
| Bundle ID | `com.lifescript.solo.tianjilu` |
| SKU | `tianjilu-solo-001` |

### App 分类

| 字段 | 推荐值 |
|------|--------|
| 主要类别 | 游戏 - 角色扮演 (Games - Role Playing) |
| 次要类别 | 图书 (Books) |

> 建议选"游戏-角色扮演"作为主类别，因为 App 包含属性系统、选择分支和角色关系等游戏化元素，更容易被目标用户发现。

### 内容版权

- 版权所有者: 你的开发者名称
- 不包含第三方内容

---

## 二、定价与销售

| 字段 | 值 |
|------|-----|
| 价格 | 免费 |
| 销售区域 | 全部区域（或按需选择） |
| 预购 | 否 |

---

## 三、年龄分级问卷

在 App Store Connect 提交时需回答以下问题：

| 问题 | 选择 | 说明 |
|------|------|------|
| 卡通或幻想暴力 | **频繁** | 修仙战斗、宗门冲突为核心玩法 |
| 现实暴力 | 无 | 纯虚构世界观 |
| 恐怖/惊悚主题 | **偶尔** | 黑暗主题、心理压迫 |
| 色情或裸露内容 | 无 | — |
| 成人/性暗示主题 | 无 | — |
| 亵渎或粗鲁幽默 | **偶尔** | 角色冲突对话 |
| 药物/酒精/烟草使用 | 无 | — |
| 模拟赌博 | 无 | — |
| 医学/医疗信息 | 无 | — |
| 比赛 | 无 | — |
| 无限制网络访问 | **否** | 离线应用 |
| 用户生成内容 | **否** | 无 UGC |

**预计分级结果: 17+**

---

## 四、In-App Purchase (IAP) 产品

需在 App Store Connect 中创建以下 **9 个非消耗型** 产品：

| Product ID | 中文名称 | 英文名称 | 价格 |
|-----------|---------|---------|------|
| `com.lifescript.solo.tianjilu.volume2` | 第二卷：宗门暗战 (第121-240章) | Volume 2: Shadow War (Ch.121-240) | $0.99 |
| `com.lifescript.solo.tianjilu.volume3` | 第三卷：秘境争锋 (第241-360章) | Volume 3: Secret Realm (Ch.241-360) | $0.99 |
| `com.lifescript.solo.tianjilu.volume4` | 第四卷：魔道渗透 (第361-480章) | Volume 4: Demonic Infiltration (Ch.361-480) | $0.99 |
| `com.lifescript.solo.tianjilu.volume5` | 第五卷：天命反噬 (第481-600章) | Volume 5: Fate Backlash (Ch.481-600) | $0.99 |
| `com.lifescript.solo.tianjilu.volume6` | 第六卷：大陆格局 (第601-720章) | Volume 6: Continental Shift (Ch.601-720) | $0.99 |
| `com.lifescript.solo.tianjilu.volume7` | 第七卷：上古真相 (第721-840章) | Volume 7: Ancient Truth (Ch.721-840) | $0.99 |
| `com.lifescript.solo.tianjilu.volume8` | 第八卷：魔道大战 (第841-960章) | Volume 8: Great War (Ch.841-960) | $0.99 |
| `com.lifescript.solo.tianjilu.volume9` | 第九卷：天道裂变 (第961-1080章) | Volume 9: Heavenly Fission (Ch.961-1080) | $0.99 |
| `com.lifescript.solo.tianjilu.volume10` | 第十卷：棋局终局 (第1081-1200章) | Volume 10: Endgame (Ch.1081-1200) | $0.99 |

> **重要**: Product ID 必须与 `SoloStoreKit.storekit` 配置文件中的 ID 完全一致。

### IAP 审核信息

每个 IAP 产品需填写：
- **审核截图**: paywall 界面截图（显示购买按钮和章节预览）
- **审核备注**: "Non-consumable purchase that permanently unlocks chapters [X] through [Y] of the interactive novel."

---

## 五、App Review Information（审核备注）

### 联系信息

| 字段 | 值 |
|------|-----|
| 名 | [你的名] |
| 姓 | [你的姓] |
| 电话 | [你的电话] |
| 邮箱 | wpowening@gmail.com |

### 审核备注（Notes for Review）

```
1. This is an offline interactive fiction app. No internet connection is required for core functionality.

2. Volume 1 is fully free, which means the first 120 chapters are available without purchase. Subsequent chapters are unlocked via non-consumable in-app purchases organized by volume ($0.99 per volume). Each purchase grants permanent access.

3. All story content is original fiction. No real persons, events, or locations are depicted.

4. Content includes fantasy violence and dark themes (cultivation combat, sect conspiracies, psychological tension). We recommend a 17+ age rating.

5. No user-generated content, no social features, no account system.

6. Demo account: Not applicable (offline app, no login required).

7. To test IAP: Volume 1 (chapters 1-120) is accessible without purchase. To review the paywall, navigate past chapter 120 to trigger the volume gate screen.
```

### 演示账号

- **不需要** — 纯离线应用，无登录系统

---

## 六、App Screenshots（截图）

### 必需尺寸

| 设备 | 分辨率 | 数量 |
|------|--------|------|
| iPhone 6.9" | 1320 × 2868 / 1290 × 2796 / 1260 × 2736 | 1-10 张，建议 5 张 |
| iPhone 6.5"（如未提供 6.9"） | 1284 × 2778 / 1242 × 2688 | 1-10 张，建议 5 张 |

> 以 Apple Developer 当前截图规范为准。当前 iPhone 提交可优先提供一组 6.9" 截图；若不提供 6.9"，则至少需要 6.5" 截图。

### 建议截图内容

1. **入口页** — 展示天机录主题视觉和"进入天机局" CTA
2. **阅读界面** — 对话节点 + 叙事文本，体现暗色电影级 UI
3. **选择分支** — 展示 2-4 个选项 + 代价提示 + 属性影响
4. **人物档案** — 角色关系多维度可视化（信任/好奇/警惕等）
5. **章节结算** — 属性变化回顾 + 选择复盘

### 截图获取方式

在模拟器中运行 `LifeScriptSoloTianjilu` scheme：

```bash
# 生成 Xcode 项目
cd LifeScript-Solo && xcodegen generate

# 使用模拟器运行
xcodebuild -project LifeScriptSolo.xcodeproj \
  -scheme LifeScriptSoloTianjilu \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  -configuration Debug \
  build

# 在模拟器中手动截图: Cmd+S
```

> 截图保存到 `fastlane/screenshots/zh-Hans/` 和 `fastlane/screenshots/en/` 目录。

---

## 七、法律页面 URL

确保以下 URL 在提交审核前可公开访问：

| 用途 | URL |
|------|-----|
| 隐私政策 | https://lifescript.app/privacy |
| 用户支持 | https://lifescript.app/support |

### 部署方案

**方案 A: 自有域名**
将 `LegalPages/` 目录部署到 `lifescript.app` 域名。

**方案 B: GitHub Pages（备选）**
1. 创建 GitHub 仓库（如 `lifescript-legal`）
2. 将 `LegalPages/` 内容推送到该仓库
3. 启用 GitHub Pages
4. 更新 metadata 中的 URL 指向 `https://yourname.github.io/lifescript-legal/privacy.html`

> **重要**: 如果 URL 返回 404，审核会被拒绝。提交前务必测试所有链接。

---

## 八、提交前检查清单

### 代码 & 构建
- [x] NSLog 调试日志已用 `#if DEBUG` 包裹
- [x] `xcodegen generate` 成功生成项目
- [x] Release 构建通过
- [x] 本地测试通过（52 tests）
- [ ] App Store 导出通过（当前缺 `com.lifescript.solo.tianjilu` 的 App Store profile）
- [ ] StoreKit 测试通过（sandbox 环境购买流程）

### Metadata
- [x] 中文 App 名称、副标题、描述、关键词
- [x] 英文 App 名称、副标题、描述、关键词
- [x] 推广文案已更新为天机录专属内容
- [ ] App Screenshots（至少 3 张/尺寸）

### 法律
- [x] 隐私政策页面（中文 + 英文）
- [x] 服务条款页面（中文 + 英文）
- [x] 用户支持页面（中文 + 英文）
- [x] 内容分级说明（中文 + 英文）
- [ ] 法律页面 URL 可公开访问（当前 `lifescript.app` 仍未解析）

### App Store Connect
- [ ] App 已创建（Bundle ID 注册）
- [ ] 9 个 IAP 非消耗品已创建
- [ ] 为 `com.lifescript.solo.tianjilu` 创建 App Store Distribution profile
- [ ] 年龄分级问卷已填写（预期 17+）
- [ ] App 分类已选择
- [ ] 审核备注已填写
- [ ] 联系信息已填写

### 图标
- [x] AppIconTianjilu.appiconset 包含 1024×1024 通用图标
- [x] Contents.json 配置正确

### 隐私
- [x] PrivacyInfo.xcprivacy 已配置
- [x] ITSAppUsesNonExemptEncryption = false
- [x] NSAppTransportSecurity 未禁用（ATS 生效）

---

## 九、Fastlane 提交命令

```bash
cd LifeScript-Solo

# 1. 先确保本机已安装 fastlane，并补齐 App Store profile
fastlane certs

# 2. 上传到 TestFlight（先内测）
fastlane beta

# 3. 上传到 App Store（正式提交）
fastlane release
```

如果要用 `xcodebuild` 手动导出，可使用：

```bash
xcodebuild -exportArchive \
  -archivePath /tmp/LifeScriptSoloTianjilu_signed.xcarchive \
  -exportPath /tmp/LifeScriptSoloExport \
  -exportOptionsPlist fastlane/ExportOptions-app-store-connect.plist
```

---

## 十、提交后注意事项

1. **审核时间**: 通常 24-48 小时，首次提交可能更长
2. **被拒处理**: 查看 Resolution Center 中的具体原因，修复后重新提交
3. **IAP 审核**: IAP 产品需要单独审核，确保审核截图清晰
4. **版本更新**: 后续版本更新时只需修改 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION`
