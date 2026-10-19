# 用 GitHub Pages 免费上线官网（0 元方案）

> 目标：让 `www.pdgait.com.cn` 能打开官网，不买服务器、不备案。
> 代价：国内访问速度一般，GitHub Pages 偶尔不稳定；没有 ICP 备案号。
> 适合现阶段验证与展示，等公司注册或必须备案时再迁回国内。

---

## 0 你需要准备

- 一个 GitHub 账号（没有就注册，免费）：https://github.com/signup
- 仓库必须是 **Public**。免费账号的私有仓库不能开 Pages。

---

## 1 建仓库

1. 登录 GitHub，右上角 `+` → **New repository**
2. Repository name 填 `pdgait-site`
3. 选 **Public**
4. 不要勾选 README / .gitignore / license
5. 点 **Create repository**

---

## 2 上传网站文件（网页操作，不用命令行）

1. 在刚建好的仓库页面，点 **uploading an existing file**
2. 在 Windows 资源管理器打开：
   ```
   C:\Users\Lenovo\Desktop\步态检测\官网
   ```
3. **进入这个目录里面**，按 `Ctrl+A` 全选（index.html、product.html、assets、download 等）
4. 把这些文件/文件夹一起拖进浏览器的上传区域
   - 注意：不要拖 `官网` 这个文件夹本身，否则网站会变成 `/官网/index.html`
   - `download` 文件夹里有 11 MB 的 APK，上传会慢一点，正常
5. 下方 Commit changes 填 `site`，点 **Commit changes**

上传完成后，仓库根目录应该能看到 `index.html`、`assets/`、`download/`、`CNAME`。

---

## 3 开启 Pages

1. 仓库 → **Settings** → 左侧 **Pages**
2. Build and deployment → Source 选 **Deploy from a branch**
3. Branch 选 **main**，目录选 **/ (root)**，点 **Save**
4. 等 1–2 分钟，页面顶部会出现：
   ```
   Your site is live at https://<你的用户名>.github.io/pdgait-site/
   ```
5. 打开这个地址，确认官网能正常显示、图片和样式都在

> 这一步只是临时地址，下一步才绑 `www.pdgait.com.cn`。

---

## 4 绑定自定义域名

1. 还在 Settings → Pages 页面
2. **Custom domain** 填 `www.pdgait.com.cn`，点 **Save**
3. GitHub 会自动创建/更新仓库根目录的 `CNAME` 文件（内容就是 `www.pdgait.com.cn`）

此时会显示 DNS 检查未通过，正常，下一步去加解析。

---

## 5 在 DNSPod 加解析

打开腾讯云 → DNSPod → 域名解析 → `pdgait.com.cn`，添加两条记录：

**第一条：www**

| 字段 | 值 |
|---|---|
| 主机记录 | `www` |
| 记录类型 | `CNAME` |
| 记录值 | `<你的GitHub用户名>.github.io` |
| TTL | 默认（600） |

**第二条：裸域跳转**

| 字段 | 值 |
|---|---|
| 主机记录 | `@` |
| 记录类型 | 显性 URL |
| 记录值 | `https://www.pdgait.com.cn` |
| TTL | 默认 |

> `@` 不要加 CNAME，会和以后的企业邮箱 MX 冲突；用显性 URL 跳转到 www 最省事。

---

## 6 等证书

1. 回 GitHub → Settings → Pages，等 DNS check 变成 **successful**（几分钟到几小时）
2. 出现 **Enforce HTTPS** 复选框后，勾上
3. 证书签发通常几分钟到 24 小时，期间浏览器可能提示不安全，等就行

验证：

```bash
curl -I https://www.pdgait.com.cn/
# 期望 200，且是 text/html
```

---

## 7 以后怎么更新网站

改动本地 `官网/` 里的文件后：

1. 仓库页面 → **Add file** → **Upload files**
2. 把改过的文件拖进去，同名会覆盖
3. Commit changes
4. Pages 会在 1–2 分钟内自动重新发布

或者用命令行（推荐，快）：

```bash
cd /tmp
git clone https://github.com/<你的用户名>/pdgait-site.git
# 改文件后
cd pdgait-site
git add .
git commit -m "update"
git push
```

---

## 8 常见问题

**打开是 404**
- 确认仓库根目录有 `index.html`，不是 `官网/index.html`
- 确认 Pages 的 Branch 选的是 main / root，且已 Save
- 等 1–2 分钟再刷新

**样式丢了**
- 确认 `assets/` 文件夹上传到了仓库根，里面有 `style.css`、`main.js`、`logo.png`

**DNS 一直不通过**
- 用 `nslookup www.pdgait.com.cn` 看是否解析到 GitHub 的 IP
- CNAME 记录值只填 `xxx.github.io`，不要带 `https://`、不要带路径
- DNSPod 里 `www` 不要同时存在 A 记录和 CNAME 记录

**HTTPS 勾不上**
- 等 DNS 完全生效，通常 10 分钟到 2 小时
- 确认没有开 DNSPod 的“CDN 加速”或代理，先保持“仅 DNS”

**国内访问慢或打不开**
- 这是 GitHub Pages 的固有问题，不是配置错误
- 如果必须国内稳定，只能备案后迁回腾讯云 COS + CDN

---

## 9 之后迁回国内的路径

等公司注册或决定备案时：

1. 买包年包月轻量服务器（≥3 个月）→ 申请备案授权码
2. 提交备案，拿到备案号
3. 建 COS 静态站桶，跑 `deploy_website.sh --apply`
4. 把 DNSPod 的 `www` 从 GitHub 改成 COS/CDN 的 CNAME
5. 官网页脚替换备案号

DNS 切换是分钟级的，随时可以回滚。
