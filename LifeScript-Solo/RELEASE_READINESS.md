# 天机录 Release Readiness

## 当前已验证

- `xcodegen generate` 可成功生成工程
- `LifeScriptSoloTianjilu` 的 `Release build` 可通过
- 已签名 `archive` 可通过
- 单元测试 `52 / 52` 通过
- 免费口径已统一为：`卷一全免，前 120 章免费`

## 当前阻塞

### 1. App Store 导出仍失败

- 当前错误：`No profiles for 'com.lifescript.solo.tianjilu' were found`
- 现状说明：
- 本机只有一个开发通配 profile：`iOS Team Provisioning Profile: *`
- 本机只有一个无关的商店 profile：`com.workshield.clientapp`
- 结论：还没有为 `com.lifescript.solo.tianjilu` 创建对应的 App Store Distribution profile

### 2. 法律链接未上线

- `https://wpowen.github.io/wpprivacy/lifescript-solo/privacy.html`
- `https://wpowen.github.io/wpprivacy/lifescript-solo/support.html`
- `https://wpowen.github.io/wpprivacy/lifescript-solo/contact.html`
- `https://wpowen.github.io/wpprivacy/lifescript-solo/terms.html`
- `https://wpowen.github.io/wpprivacy/lifescript-solo/content-rating.html`
- 当前都无法解析，提审前必须可访问

### 3. 商店素材未产出

- 还没有 `fastlane/screenshots`
- 还没有 IAP 审核截图
- 宣传图还未制作

### 4. App Store Connect 后台仍需补齐

- 创建 App
- 创建 9 个非消耗型 IAP
- 补联系人姓名 / 电话
- 选择分类与年龄分级
- 填写审核备注
- 最终确认价格 tier

## 建议的下一个执行顺序

1. 在 Apple Developer / App Store Connect 中创建 `com.lifescript.solo.tianjilu` 的 App 与 IAP
2. 生成并下载对应的 App Store Distribution profile
3. 部署 `LegalPages` 到正式 URL
4. 采集 5 张商店截图 + 1 张 IAP 审核截图
5. 再执行 TestFlight 上传
