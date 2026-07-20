#!/usr/bin/env python3
"""
YueDu-iOS 一键上传脚本
将本地项目文件推送到 GitHub ccf-yang/YueDu-iOS 的 bd 分支

使用方法：
  export GITHUB_TOKEN="your_personal_access_token"
  python3 upload_to_github.py

GitHub Token 获取地址：
  https://github.com/settings/tokens/new
  → 勾选 repo（完整仓库权限）
"""

import os, base64, json, urllib.request, urllib.error, sys, time

# ── 配置 ──────────────────────────────────────────────────────────────────────
REPO        = "ccf-yang/YueDu-iOS"
BRANCH      = "bd"
BASE_DIR    = os.path.dirname(os.path.abspath(__file__))   # 脚本所在目录
API         = "https://api.github.com"
COMMIT_MSG  = "feat: add YueDu-iOS SwiftUI complete project"

# ── GitHub API 封装 ───────────────────────────────────────────────────────────
def gh(method, path, data=None, token=None):
    url = f"{API}{path}"
    headers = {
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "YueDu-iOS-Uploader/1.0"
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = json.dumps(data).encode() if data else None
    req  = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:    resp = json.loads(raw)
        except: resp = {"message": raw.decode(errors="replace")}
        return e.code, resp
    except Exception as ex:
        return -1, {"error": str(ex)}

# ── 收集需要上传的文件 ────────────────────────────────────────────────────────
SKIP_EXTS = {".DS_Store", ".pyc"}
SKIP_DIRS = {"__pycache__", ".git", "build", "DerivedData"}

def collect_files(base):
    result = {}
    for root, dirs, files in os.walk(base):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for fname in files:
            if any(fname.endswith(e) for e in SKIP_EXTS):
                continue
            if fname == os.path.basename(__file__):   # 跳过脚本本身
                continue
            fpath = os.path.join(root, fname)
            rel   = os.path.relpath(fpath, base).replace("\\", "/")
            with open(fpath, "rb") as f:
                result[rel] = base64.b64encode(f.read()).decode()
    return result

# ── 获取文件在仓库中的当前 SHA（PUT 时需要） ──────────────────────────────────
def get_file_sha(path, branch, token):
    s, r = gh("GET", f"/repos/{REPO}/contents/{path}?ref={branch}", token=token)
    if s == 200:
        return r.get("sha")
    return None

# ── 主流程 ────────────────────────────────────────────────────────────────────
def main():
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not token:
        print("❌ 未找到 GITHUB_TOKEN 环境变量！")
        print("\n请先执行：")
        print("  export GITHUB_TOKEN=\"ghp_xxxxxxxxxxxx\"")
        print("\nToken 申请地址：https://github.com/settings/tokens/new")
        print("  → 勾选 repo 权限 → Generate token")
        sys.exit(1)

    print(f"🚀 开始上传到 {REPO} 的 {BRANCH} 分支\n")

    # 1. 确认仓库可访问
    s, r = gh("GET", f"/repos/{REPO}", token=token)
    if s != 200:
        print(f"❌ 仓库访问失败 ({s}): {r.get('message')}")
        sys.exit(1)
    print(f"✅ 仓库确认: {r['full_name']} (默认分支: {r['default_branch']})")

    # 2. 获取 main 分支 HEAD SHA
    s, r = gh("GET", f"/repos/{REPO}/git/ref/heads/{r['default_branch']}", token=token)
    if s != 200:
        print(f"❌ 获取主分支失败: {r.get('message')}")
        sys.exit(1)
    main_sha = r["object"]["sha"]
    print(f"✅ main HEAD SHA: {main_sha[:8]}")

    # 3. 创建 bd 分支（若不存在）
    s, r = gh("GET", f"/repos/{REPO}/branches/{BRANCH}", token=token)
    if s == 404:
        s2, r2 = gh("POST", f"/repos/{REPO}/git/refs", token=token, data={
            "ref": f"refs/heads/{BRANCH}",
            "sha": main_sha
        })
        if s2 in (200, 201):
            print(f"✅ bd 分支创建成功")
        else:
            print(f"❌ 创建 bd 分支失败 ({s2}): {r2.get('message')}")
            sys.exit(1)
    elif s == 200:
        print(f"✅ bd 分支已存在")
    else:
        print(f"❌ 检查分支失败 ({s}): {r.get('message')}")
        sys.exit(1)

    # 4. 收集并上传所有文件
    files = collect_files(BASE_DIR)
    print(f"\n📁 共 {len(files)} 个文件待上传：")
    for f in sorted(files.keys()):
        print(f"   {f}")

    print(f"\n⬆️  开始逐文件上传...")
    ok, fail = 0, 0
    for rel_path, b64_content in sorted(files.items()):
        # 获取已存在文件的 SHA（更新时需要）
        existing_sha = get_file_sha(rel_path, BRANCH, token)
        payload = {
            "message": COMMIT_MSG,
            "content": b64_content,
            "branch":  BRANCH
        }
        if existing_sha:
            payload["sha"] = existing_sha

        s, r = gh("PUT", f"/repos/{REPO}/contents/{rel_path}", data=payload, token=token)
        if s in (200, 201):
            action = "更新" if existing_sha else "新建"
            print(f"   ✅ [{action}] {rel_path}")
            ok += 1
        else:
            print(f"   ❌ [{s}] {rel_path}: {r.get('message', r)}")
            fail += 1
        time.sleep(0.3)   # 避免触发 GitHub API 速率限制

    print(f"\n{'='*50}")
    print(f"📊 上传结果: 成功 {ok} 个，失败 {fail} 个")
    if fail == 0:
        print(f"\n🎉 全部上传成功！")
        print(f"   查看地址: https://github.com/{REPO}/tree/{BRANCH}")
    else:
        print(f"\n⚠️  部分文件上传失败，请检查 Token 权限或重新运行")

if __name__ == "__main__":
    main()
