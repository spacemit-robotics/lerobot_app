# Native LeRobot 应用

用于将 LeRobot 工作流封装成 C++ 原生应用，并通过 mlink device → mlink gateway → MCP
→ Hermes 的链路，对外提供可调用的机器人抓取工具。当前示例聚焦于 cube 抓取任务，适合作为
后续 LeRobot task 接入的基础模板。

## 功能特性

- 提供 `lerobot_native` 命令行入口，用于触发具体 task
- 提供 `lerobot_device` 设备进程，通过 mlink 动态注册工具到 gateway
- 当前内置示例工具为 `pick_cube`，对接底层 `lerobot-record` 工作流
- 保留 Python 虚拟环境和 LeRobot 依赖安装流程，方便继续复用 LeRobot 生态
- 支持通过项目构建系统 `mm` 构建，也支持本地 `cmake` 调试构建

## 前置准备

### 硬件准备与连接

运行 `pick_cube` 前，请先确认机械臂和相机已经正确上电并连接到当前设备。

- 机械臂：确认电源、通信线缆和控制接口连接正常，可通过执行 `lerobot-find-port` 检查机械臂连接端口。
- 相机：确认相机已正确接入，可通过执行 `lerobot-find-camera opencv` 查看当前可用的相机索引。

### 模型下载

`pick_cube` 依赖底层 LeRobot 工作流及其对应模型文件。首次运行前，请先按实际任务准备所需模型。

- 请根据本项目使用的 LeRobot/ACT 流程，下载对应策略模型和相关配置文件。
- 建议将模型放置到本地约定目录，例如 `models/` 或运行脚本中指定的模型目录。
- 若仓库或脚本对模型路径有额外约定，请以实际脚本参数和运行日志提示为准。

模型下载完成后，建议先检查：

- 模型文件是否完整可读
- 模型路径是否与 `scripts/pick_cube_record.sh` 中的实际配置一致
- 运行环境是否满足模型推理所需依赖

### Python 虚拟环境准备

请先在仓库根目录完成整体 SDK 环境准备，并确保以下依赖已可用：

- `cmake`
- `python3`
- 已执行项目根目录环境脚本：`source build/envsetup.sh`
- `mlink gateway` 已可正常启动
- 可通过 `mlink gateway start` 启动或重启网关，并通过 `mlink gateway tools` 查看当前网关支持的工具

由于底层 `lerobot-record` 属于 Python 生态，首次运行前需要准备当前应用的虚拟环境：

```bash
m_env_build application/native/lerobot
```

或者进入应用目录安装：

```bash
cd application/native/lerobot
bash scripts/setup_env.sh
```

脚本会在仓库根目录下准备虚拟环境：

```bash
output/envs/lerobot_app
```

### 编译 mlink device 依赖

`lerobot_device` 在编译时依赖 `mlink` 提供的头文件和动态库，在编译 `lerobot` 相关程序之前，先完成 `mlink device` 的构建：

```bash
cd components/agent_tools/mlink/device
mm
```
构建完成后，通常可在以下位置看到关键产物：

```bash
output/staging/include/mlink.h
output/staging/lib/libmlink_device.so
output/staging/bin/mlink_device_test
```

其中：

- `output/staging/include/mlink.h`：供 `lerobot_device` 编译时引用的头文件。
- `output/staging/lib/libmlink_device.so`：供 `lerobot_device` 链接及运行时加载的动态库。
- `output/staging/bin/mlink_device_test`：`mlink device` 组件自带的测试程序，可用于基础功能验证。

## 构建编译 lerobot_device

进入目录构建：

```bash
cd application/native/lerobot
mm
```

构建完成后，产物安装到：

```bash
output/staging/bin/lerobot_native
output/staging/bin/lerobot_device
```

- `output/staging/bin/lerobot_native`：本地命令行执行入口，用于直接触发 `pick_cube` 等具体 task。
- `output/staging/bin/lerobot_device`：mlink 设备进程，用于向 gateway 动态注册工具并转发调用到 `lerobot_native`。

如果只做本地调试，也可以使用独立 cmake：

```bash
cd application/native/lerobot
cmake -B build -S .
cmake --build build
```

此时本地产物位于：

```bash
build/lerobot_native
build/lerobot_device
```

## 运行示例

1. 直接验证 task：

```bash
output/staging/bin/lerobot_native tool-pick-cube
```

2. 启动 mlink device：

```bash
output/staging/bin/lerobot_device unix lerobot
```

3. 检查 gateway 工具列表：

```bash
mlink gateway tools
```

若注册成功，应看到类似工具名：

```text
lerobot.pick_cube
```

## 详细使用

### 目录结构

```text
application/native/lerobot/
├── CMakeLists.txt                # 定义本应用的构建方式、mlink 依赖链接和安装规则
├── LICENSE                       # 本目录组件的许可证文本
├── NOTICE                        # 第三方依赖与版权声明补充信息
├── README.md                     # 组件说明、构建方法和运行文档
├── package.xml                   # 供仓库构建系统识别的包元数据与依赖声明
├── pyproject.toml                # Python 虚拟环境依赖声明，用于 lerobot-record 环境准备
├── scripts/
│   ├── pick_cube_record.sh       # 封装 pick_cube task 的底层执行脚本
│   └── setup_env.sh              # 创建并安装当前应用 Python 运行环境
├── include/lerobot_app/
│   └── runner.hpp                # C++ 执行器接口声明
└── src/cpp/
    ├── lerobot_device.cpp        # lerobot_device 设备进程入口与 tool 注册实现
    ├── main.cpp                  # lerobot_native 命令行入口
    └── runner.cpp                # task 调度、环境检查和脚本调用实现
```

### 整体链路

完整执行链路如下：

1. 编译 `application/native/lerobot`
2. 启动 `lerobot_device`
3. `lerobot_device` 作为 mlink 设备连接到 `mlink gateway`
4. gateway 对设备执行 `initialize` 和 `tools/list`
5. gateway 将设备工具动态注册为 MCP tool
6. Hermes 连接 gateway 后看到该 tool
7. Hermes 调用 `lerobot.pick_cube`
8. `lerobot_device` 回调 `lerobot_native tool-pick-cube`
9. `lerobot_native` 调用 `scripts/pick_cube_record.sh`
10. `pick_cube_record.sh` 执行真实的 `lerobot-record ...`

### tool 注册说明

`lerobot_device` 启动时会在设备侧调用：

- `mlink_tool_create("pick_cube", ...)`
- `mlink_server_add_tool(server, tool)`

因此无需修改 gateway 内建工具代码。只要设备成功连接 gateway，tool 就会通过运行时发现机制自动
暴露为：

```text
<device_id>.<tool_name>
```

例如设备名为 `lerobot` 时，最终 tool 名为：

```text
lerobot.pick_cube
```

### Hermes 调用说明

Spacemit 平台已适配 Hermes，可直接安装并完成基础配置。

安装 Hermes：

```bash
sudo apt-get update
sudo apt-get install --reinstall hermes-agent
```

配置模型：

```bash
hermes model
```

随后按照命令行向导完成秘钥和模型配置。

启动交互式 CLI：

```bash
hermes
```

当 gateway 已运行且 `lerobot_device` 已连接后，Hermes 就能通过 MCP 看到 `lerobot.pick_cube`。

若需要将本机 gateway 的 HTTP MCP endpoint 写入 Hermes 配置，可参考如下方式维护
`~/.hermes/config.yaml`，使其指向当前运行中的 mlink gateway。

示例配置如下：

```yaml
mcp_servers:
    mlink-gateway:
        transport: http
        url: http://127.0.0.1:18765/mcp
        enabled: true
```

当 Hermes 绑定该 MCP 服务后，即可在 Hermes CLI 中使用自然语言发起指令，例如“抓木块”。
Hermes 会将该请求路由到 `lerobot.pick_cube` tool，进而触发机械臂执行对应的抓取动作。

## 常见问题

### 1. 执行 `./build/lerobot_device` 找不到文件

如果你使用的是 `mm application/native/lerobot`，产物默认安装在：

```bash
output/staging/bin/lerobot_device
output/staging/bin/lerobot_native
```

只有手动执行本地 cmake 构建时，产物才位于当前目录的 `build/` 下。

### 2. `mlink gateway tools` 里看不到 `lerobot.pick_cube`

请依次检查：

- gateway 是否已启动
- `lerobot_device` 是否已运行
- 设备名和 transport 参数是否正确
- `/tmp/mlink-gateway/gateway.log` 中是否出现设备注册成功日志

### 3. 执行 task 时提示虚拟环境或模型不存在

请检查：

- 是否已执行 `bash scripts/setup_env.sh`
- `output/envs/lerobot_app` 是否存在
- `models/` 下策略模型是否已准备完成

### 4. 为什么 C++ 应用仍依赖 Python 环境

当前 C++ 部分负责应用入口、参数组织和 mlink 工具注册；底层执行的 `lerobot-record` 仍属于
LeRobot Python 工作流，因此仍需要准备 Python 虚拟环境。

## 版本与发布

版本以本组件文档或仓库 tag 为准。

| 版本  | 说明                                                   |
|-------|--------------------------------------------------------|
| 1.0.0 | 初始版本，提供 `lerobot_native`、`lerobot_device` 与 `pick_cube` 示例流程 |

## 贡献方式

欢迎参与贡献：提交 Issue 反馈问题，或通过 Pull Request 提交代码。

1. C/C++ 代码遵循 [Google C++ 风格](https://google.github.io/styleguide/cppguide.html)
2. Python 代码遵循 [PEP 8](https://peps.python.org/pep-0008/)
3. Git commit 遵循 [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

## License

本组件源码文件头声明为 Apache-2.0，最终以本目录 `LICENSE` 文件为准。