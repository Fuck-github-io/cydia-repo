#!/usr/bin/env bash
# ============================================================
# 生成 Cydia/Sileo 软件源索引
# 用法: ./build_repo.sh
# 产出:
#   ./Packages          (gzip 压缩索引)
#   ./Packages.bz2      (bzip2 压缩索引)
#   ./Packages.xz       (xz 压缩索引, 现代源推荐)
#   ./Release           (源元信息)
# ============================================================
set -euo pipefail

# 仓库根目录 (脚本所在目录)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEBS_DIR="$REPO_DIR/debs"
OUT_DIR="$REPO_DIR"

# 源信息 (发布前按需修改)
REPO_NAME="${REPO_NAME:-xiaoleng Cydia Repo}"
REPO_ORIGIN="${REPO_ORIGIN:-xiaoleng}"
REPO_LABEL="${REPO_LABEL:-xiaoleng Repo}"
REPO_SUITE="${REPO_SUITE:-stable}"
REPO_VERSION="${REPO_VERSION:-1.0}"
REPO_COMPONENT="${REPO_COMPONENT:-main}"
REPO_DESCRIPTION="${REPO_DESCRIPTION:- 越狱插件软件源}"
ARCHITECTURES="${ARCHITECTURES:-iphoneos-arm64 iphoneos-arm64e iphoneos-arm}"

command -v dpkg-scanpackages >/dev/null 2>&1 || {
    echo "错误: 未找到 dpkg-scanpackages, 请先安装 dpkg (brew install dpkg)" >&2
    exit 1
}

echo "==> 扫描 deb 目录: $DEBS_DIR"
if [ ! -d "$DEBS_DIR" ]; then
    echo "错误: deb 目录不存在: $DEBS_DIR" >&2
    exit 1
fi

deb_count=$(ls -1 "$DEBS_DIR"/*.deb 2>/dev/null | wc -l | tr -d ' ')
if [ "$deb_count" -eq 0 ]; then
    echo "警告: deb 目录下没有 .deb 文件, 将生成空索引" >&2
fi

echo "==> 生成 Packages 索引"
# 扫描 deb, 生成未压缩的 Packages 文件 (输出到 stdout)
# 注意: 必须用相对路径 (debs) 扫描, 否则 Filename 字段会是本地绝对路径,
#       导致设备无法下载安装
cd "$REPO_DIR"
dpkg-scanpackages --multiversion debs /dev/null > "$OUT_DIR/Packages.tmp"

# 生成各压缩格式索引
echo "==> 生成 Packages.gz / Packages.bz2 / Packages.xz"
gzip -9c "$OUT_DIR/Packages.tmp" > "$OUT_DIR/Packages.gz"
bzip2 -9c "$OUT_DIR/Packages.tmp" > "$OUT_DIR/Packages.bz2"
xz -9c "$OUT_DIR/Packages.tmp" > "$OUT_DIR/Packages.xz"
mv "$OUT_DIR/Packages.tmp" "$OUT_DIR/Packages"

# 计算校验和 (SHA256)
sha256_gz=$(shasum -a 256 "$OUT_DIR/Packages.gz" | awk '{print $1}')
sha256_bz2=$(shasum -a 256 "$OUT_DIR/Packages.bz2" | awk '{print $1}')
sha256_xz=$(shasum -a 256 "$OUT_DIR/Packages.xz" | awk '{print $1}')
size_gz=$(stat -f%z "$OUT_DIR/Packages.gz")
size_bz2=$(stat -f%z "$OUT_DIR/Packages.bz2")
size_xz=$(stat -f%z "$OUT_DIR/Packages.xz")

echo "==> 生成 Release 文件"
cat > "$OUT_DIR/Release" <<EOF
Origin: $REPO_ORIGIN
Label: $REPO_LABEL
Suite: $REPO_SUITE
Version: $REPO_VERSION
Codename: $REPO_SUITE
Architectures: $ARCHITECTURES
Components: $REPO_COMPONENT
Description: $REPO_DESCRIPTION
MD5Sum:
 $(md5 -q "$OUT_DIR/Packages" | awk -v s="$(stat -f%z "$OUT_DIR/Packages")" '{printf " %s %d Packages\n", $1, s}')
 $(md5 -q "$OUT_DIR/Packages.gz" | awk -v s="$size_gz" '{printf " %s %d Packages.gz\n", $1, s}')
 $(md5 -q "$OUT_DIR/Packages.bz2" | awk -v s="$size_bz2" '{printf " %s %d Packages.bz2\n", $1, s}')
 $(md5 -q "$OUT_DIR/Packages.xz" | awk -v s="$size_xz" '{printf " %s %d Packages.xz\n", $1, s}')
SHA256:
 $(printf "%s %d Packages\n" "$(shasum -a 256 "$OUT_DIR/Packages" | awk '{print $1}')" "$(stat -f%z "$OUT_DIR/Packages")")
 $(printf "%s %d Packages.gz\n" "$sha256_gz" "$size_gz")
 $(printf "%s %d Packages.bz2\n" "$sha256_bz2" "$size_bz2")
 $(printf "%s %d Packages.xz\n" "$sha256_xz" "$size_xz")
EOF

echo ""
echo "✅ 软件源索引生成完成"
echo "   包数量: $deb_count"
echo "   产物:"
ls -lh "$OUT_DIR"/Packages "$OUT_DIR"/Packages.gz "$OUT_DIR"/Packages.bz2 "$OUT_DIR"/Packages.xz "$OUT_DIR"/Release
