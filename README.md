# 越狱软件源说明

## 1. 复制 deb 包

把你所有的 `.deb` 包放进 `debs/` 目录。

## 2. 生成索引

```bash
cd CydiaRepo
./build_repo.sh
```

会生成：
- `Packages` / `Packages.gz` / `Packages.bz2` / `Packages.xz` — 包索引
- `Release` — 源元信息

## 3. 发布到 GitHub

### 方案 A：GitHub Pages（推荐，免服务器）

1. 建仓库，例如 `love-sss/cydia-repo`
2. 在仓库 Settings → Pages → Source 选 `main` 分支、`/ (root)` 目录
3. 把整个 `CydiaRepo` 目录内容 push 到仓库根目录
4. 软件源地址就是：

```
https://love-sss.github.io/cydia-repo/
```

在 Sileo / Cydia 里添加这个地址即可。

### 方案 B：静态托管

内容推到任意静态托管（Vercel / Netlify / 对象存储），同样把根目录内容上传即可。

## 4. 常用命令

```bash
# 添加新 deb 后重新生成索引
cp ~/some/path/new-package.deb debs/
./build_repo.sh

# 提交并推送
git add -A
git commit -m "add package xxx"
git push
```

## 5. 源信息修改

编辑 `build_repo.sh` 顶部的 `REPO_*` 变量（源名、作者、描述等），或直接编辑生成的 `Release` 文件。
