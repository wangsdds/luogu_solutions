# Git 代理设置

本仓库在 Windows 上通过本地 HTTP 代理访问 GitHub。下面的地址对应 v2rayN 的 HTTP 代理端口 `10808`；使用前需要确保 v2rayN 已启动。

## 设置代理

```powershell
git config --global http.proxy http://127.0.0.1:10808
git config --global https.proxy http://127.0.0.1:10808
git config --global http.schannelCheckRevoke false
```

`http.schannelCheckRevoke false` 用于避免部分网络环境下 Git 连接 GitHub 时卡在证书吊销检查。

## 检查代理

```powershell
git config --global --get http.proxy
git config --global --get https.proxy
Test-NetConnection 127.0.0.1 -Port 10808
```

确认端口可以连接后，测试推送：

```powershell
git push origin main
```

## 只对单次命令使用代理

不想修改全局配置时，可以只给当前命令临时指定代理：

```powershell
git -c http.proxy=http://127.0.0.1:10808 `
    -c https.proxy=http://127.0.0.1:10808 `
    push origin main
```

## 取消代理

```powershell
git config --global --unset http.proxy
git config --global --unset https.proxy
```

如果取消后提示配置项不存在，说明该代理本来就没有设置，可以忽略。

## 注意事项

- `127.0.0.1:10808` 只在本机代理软件运行时有效，服务器上的 `127.0.0.1` 指向服务器自身，不能直接照搬。
- 如果代理软件没有启动，Git 会连接失败；启动 v2rayN 后再执行 `git push`。
- 代理地址中不要写入账号、密码、订阅链接或其他密钥。
