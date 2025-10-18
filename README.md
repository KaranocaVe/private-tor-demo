# Private Tor Network Demo

一个使用Docker Compose搭建的私有Tor网络演示项目，包含完整的目录权威服务器、中继节点、出口节点、隐藏服务和客户端。

## 快速启动

```bash
# 一键启动（推荐）
./setup.sh

# 或手动启动
docker-compose up -d

# 等待5-7分钟让网络建立共识，然后运行测试
docker-compose exec client /bin/bash /test.sh
```

**注意：** 首次启动需要等待约**5-7分钟**让网络完全建立（投票周期为5分钟）。

## 测试结果

项目已成功配置并测试通过：

- ✅ **HTTP服务器访问**：客户端通过Tor出口节点成功访问HTTP服务器
- ✅ **隐藏服务访问**：客户端通过Tor成功访问.onion隐藏服务

## 网络架构

```
┌─────────────┐
│  DirAuth    │ 172.20.0.10  目录权威服务器
│  (Authority)│
└─────────────┘
       │
   ┌───┴───┬───────┬───────┐
   │       │       │       │
┌──▼──┐ ┌──▼──┐ ┌──▼──┐ ┌──▼────────┐
│Relay│ │Relay│ │Exit │ │Hidden     │
│  1  │ │  2  │ │  1  │ │Service    │
└──┬──┘ └──┬──┘ └──┬──┘ └────┬──────┘
   │       │       │         │
   └───┬───┴───────┴─────┬───┘
       │                 │
   ┌───▼───┐         ┌───▼───────┐
   │Client │         │HTTP Server│
   │       │         │(Test)     │
   └───────┘         └───────────┘
```

### 组件说明

| 服务 | IP | 端口 | 说明 |
|------|---------|------|------|
| dirauth | 172.20.0.10 | 7000(OR), 7001(Dir) | 目录权威服务器 |
| relay1 | 172.20.0.11 | 7002(OR), 7003(Dir) | 中继节点1 |
| relay2 | 172.20.0.12 | 7004(OR), 7005(Dir) | 中继节点2 |
| exit1 | 172.20.0.13 | 7006(OR), 7007(Dir) | 出口节点 |
| hidden-service | 172.20.0.14 | 7008(OR) | 隐藏服务(.onion) |
| client | 172.20.0.15 | 9050(SOCKS) | Tor客户端 |
| http-server | 172.20.0.16 | 80, 8888 | HTTP测试服务器 |

## 使用说明

### 运行测试

```bash
# 完整测试（HTTP + 隐藏服务）
docker-compose exec client /bin/bash /test.sh

# 查看隐藏服务地址
docker-compose exec hidden-service cat /var/lib/tor/hidden_service/hostname

# 直接访问HTTP服务器（不通过Tor）
curl http://localhost:8888
```

### 查看日志

```bash
# 所有服务
docker-compose logs

# 特定服务
docker-compose logs dirauth
docker-compose logs client

# 实时跟踪
docker-compose logs -f client
```

### 停止网络

```bash
# 停止但保留数据
docker-compose down

# 停止并清除所有数据
docker-compose down -v
```

## 项目结构

```
.
├── docker-compose.yml      # 服务编排配置
├── Dockerfile             # 统一的Tor镜像
├── setup.sh               # 一键启动脚本
├── dirauth/
│   └── start.sh          # 目录权威启动脚本（包含完整配置）
├── relay1/
│   └── torrc             # 中继节点1配置模板
├── relay2/
│   └── torrc             # 中继节点2配置模板
├── exit/
│   └── torrc             # 出口节点配置模板
├── hidden-service/
│   ├── torrc             # 隐藏服务配置模板
│   ├── start.sh          # 隐藏服务启动脚本
│   └── index.html        # 隐藏服务网页
├── client/
│   ├── torrc             # 客户端配置模板
│   └── test.sh           # 测试脚本
└── http-server/
    └── index.html        # HTTP服务器网页
```

## 技术细节

### Tor配置

- **Tor版本**: 0.4.5.16 (Debian Bullseye)
- **网络模式**: TestingTorNetwork（仅用于测试，不连接公共网络）
- **共识算法**: v3 microdesc
- **投票周期**: 5分钟 (V3AuthVotingInterval)
- **投票延迟**: 20秒 (V3AuthVoteDelay)
- **分发延迟**: 20秒 (V3AuthDistDelay)

### 关键特性

1. **自动密钥生成**: 目录权威服务器自动生成身份密钥和签名密钥
2. **动态配置注入**: 各节点启动时自动获取DirAuth的指纹和V3身份
3. **Guard/Exit标志**: 所有节点自动获得Guard标志，exit1获得Exit标志
4. **隐藏服务**: 自动生成.onion地址并提供HTTP服务
5. **权限管理**: 所有Tor进程以debian-tor用户运行

### 为什么需要等待5-7分钟？

1. **密钥生成** (~10秒): DirAuth生成身份和签名密钥
2. **节点启动** (~30秒): 所有节点启动并连接到网络
3. **描述符发布** (~1分钟): 节点向DirAuth发布自己的描述符
4. **首次投票** (~5分钟): DirAuth等待到下一个投票周期
5. **共识发布** (~20秒): DirAuth计算并发布共识
6. **客户端引导** (~1分钟): 客户端下载共识和微描述符

## 故障排除

### 测试失败

```bash
# 1. 检查所有容器状态
docker-compose ps

# 2. 检查客户端引导进度
docker-compose logs client | grep "Bootstrapped"

# 3. 检查共识中的节点数量
docker-compose exec dirauth cat /var/lib/tor/cached-microdesc-consensus | grep "^r " | wc -l
# 应该显示 4（dirauth, relay1, relay2, exit1）

# 4. 重启特定服务
docker-compose restart client

# 5. 完全重启网络
docker-compose down -v && docker-compose up -d
```

### 隐藏服务地址未生成

```bash
# 检查隐藏服务日志
docker-compose logs hidden-service

# 检查隐藏服务目录
docker-compose exec hidden-service ls -la /var/lib/tor/hidden_service/

# 重启隐藏服务
docker-compose restart hidden-service
```

### 客户端无法连接

- 确保等待至少7分钟
- 检查客户端是否到达100% Bootstrapped
- 检查共识中是否有Exit标志的节点

## 配置说明

### 修改投票周期（加快网络建立）

编辑 `dirauth/start.sh`，将：
```bash
V3AuthVotingInterval 5 minutes
```
改为：
```bash
V3AuthVotingInterval 1 minutes
```

注意：更短的投票周期会增加网络负载。

### 添加更多节点

1. 复制现有relay配置
2. 修改昵称和IP地址
3. 在docker-compose.yml中添加服务
4. 在dirauth/start.sh的TestingDirAuthVoteGuard中添加节点昵称

## 安全警告

⚠️ **本项目仅用于测试和学习目的**

- 使用`TestingTorNetwork`模式，不连接公共Tor网络
- 所有配置都针对测试环境优化，不适合生产环境
- 私有网络的匿名性远低于公共Tor网络
- 不要用于任何需要真实匿名保护的场景

## 参考资料

- [Tor Project](https://www.torproject.org/)
- [Tor Manual](https://2019.www.torproject.org/docs/tor-manual.html.en)
- [Tor Directory Protocol](https://spec.torproject.org/dir-spec)
- [Setting up a private Tor network](https://ritter.vg/blog-setting_up_a_tor_hidden_service.html)

## License

本项目仅供学习和研究使用。Tor是自由软件，采用3-clause BSD license。
