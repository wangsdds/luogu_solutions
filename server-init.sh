#!/usr/bin/env bash
# server-init.sh —— 新买的 Linux 云主机初始化（Ubuntu / Debian，学习用途）
#
# 用法：
#   1) 本地上传：scp server-init.sh root@<服务器IP>:/root/
#   2) 登录服务器执行：sudo bash /root/server-init.sh
#
# 设计原则：只装学习要用的东西；不动 SSH 端口、不关密码登录，避免把自己锁在门外；
#           脚本可以重复执行，已完成的步骤会自动跳过。

set -euo pipefail

# ── 可调开关 ──────────────────────────────────────────────
# 服务器在国内就改成 1：pip 换清华源，装包快很多（阿里云等国内机器已默认打开）
USE_CN_MIRROR=1
# 内存 1G 及以下的小机器建议改成 1，创建 2G swap，编译/跑 Python 不容易被 OOM 杀掉
CREATE_SWAP=0
# git 身份（拉代码、提交时用到）
GIT_NAME="wangsdds"
GIT_EMAIL="114740884+wangsdds@users.noreply.github.com"
# ─────────────────────────────────────────────────────────

log()  { printf "\033[36m==> %s\033[0m\n" "$*"; }
ok()   { printf "\033[32m[OK] %s\033[0m\n" "$*"; }
warn() { printf "\033[33m[!] %s\033[0m\n" "$*"; }
die()  { printf "\033[31m[ERROR] %s\033[0m\n" "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root 运行：sudo bash $0"

# 1. 认清是什么系统
if [[ -r /etc/os-release ]]; then . /etc/os-release; fi
case "${ID:-unknown}" in
  ubuntu|debian) ok "系统：${PRETTY_NAME:-$ID}" ;;
  *) warn "本脚本只在 Ubuntu/Debian 上验证过，当前系统是 ${ID:-未知}，后面可能报错。" ;;
esac

# 2. 更新源 + 装常用工具（编译器、Python、git、终端复用）
export DEBIAN_FRONTEND=noninteractive
log "更新软件源（第一次可能要等一两分钟）"
apt-get update
log "升级已安装的包"
apt-get -y upgrade

log "安装常用工具"
apt-get -y install \
  curl wget git vim nano tmux htop tree unzip rsync \
  build-essential gcc g++ gdb make \
  python3 python3-pip python3-venv \
  ufw fail2ban ca-certificates
ok "工具安装完成"

# 3. 时区（日志时间、cron 时间才对得上）
log "设置时区为 Asia/Shanghai"
timedatectl set-timezone Asia/Shanghai || warn "设置时区失败，稍后手动执行：timedatectl set-timezone Asia/Shanghai"

# 4. pip 镜像（国内机器建议打开）
if [[ "$USE_CN_MIRROR" == 1 ]]; then
  log "配置 pip 使用清华源"
  mkdir -p /root/.pip
  printf "[global]\nindex-url = https://pypi.tuna.tsinghua.edu.cn/simple\n" > /root/.pip/pip.conf
  ok "pip 源已改为清华"
else
  warn "pip 用默认源。国内机器如果下载慢，把脚本顶部 USE_CN_MIRROR 改成 1 再跑一次。"
fi

# 5. git 身份
if [[ -n "$(git config --global user.name || true)" ]]; then
  ok "git 身份已存在：$(git config --global user.name) <$(git config --global user.email)>"
else
  git config --global user.name  "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  ok "git 身份已设为 $GIT_NAME <$GIT_EMAIL>"
fi
warn "注意：本机的 http.proxy=127.0.0.1:10808 只在你自己的电脑上有效，服务器上不要照抄。"

# 6. 防火墙：只放行必要的端口，SSH 端口自动探测，防止把自己关在外面
setup_firewall() {
  local ssh_port
  ssh_port=$(sshd -T 2>/dev/null | awk "/^port /{print \$2; exit}" || true)
  ssh_port=${ssh_port:-22}
  log "配置防火墙（放行 SSH $ssh_port、80、443）"
  ufw allow "$ssh_port"/tcp >/dev/null
  ufw allow 80/tcp >/dev/null
  ufw allow 443/tcp >/dev/null
  ufw --force enable >/dev/null
  ok "防火墙已开启。以后要开别的端口：ufw allow 5000"
}
setup_firewall

# 7. SSH 防爆破
log "启动 fail2ban"
systemctl enable --now fail2ban >/dev/null 2>&1 || warn "fail2ban 启动失败，可先忽略"

# 8. swap（小内存机器建议打开）
if [[ "$CREATE_SWAP" == 1 ]]; then
  if swapon --show | grep -q .; then
    ok "已有 swap，跳过"
  else
    log "创建 2G swap（/swapfile）"
    fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null
    swapon /swapfile
    grep -q "^/swapfile " /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
    ok "swap 已启用"
  fi
fi

# 9. 收尾自检
echo
log "环境自检"
for c in git gcc g++ python3 pip3 tmux ufw; do
  if command -v "$c" >/dev/null 2>&1; then
    printf "  %-8s %s\n" "$c" "$("$c" --version 2>&1 | head -n1)"
  else
    printf "  %-8s %s\n" "$c" "缺失"
  fi
done
echo
log "资源情况"
printf "  内存：%s\n" "$(free -h | awk "/^Mem:/{print \$2\" 总量 / \"\$7\" 可用\"}")"
printf "  磁盘：%s\n" "$(df -h / | awk "NR==2{print \$2\" 总量 / \"\$4\" 可用\"}")"
printf "  公网IP：%s\n" "$(curl -s --max-time 5 ifconfig.me || echo 获取失败)"
echo
ok "初始化完成。下一步建议："
echo "  1) 改 root 密码：passwd"
echo "  2) 建个普通用户：adduser 你的名字 && usermod -aG sudo 你的名字"
echo "  3) 拉代码：git clone https://github.com/wangsdds/luogu_solutions.git"
echo "  4) Python 项目用虚拟环境：python3 -m venv .venv && source .venv/bin/activate"
echo "  5) 学习用最省事的常驻方式：tmux 里跑服务，Ctrl+B 然后 D 退出不中断"
