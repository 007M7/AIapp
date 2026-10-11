# 设备语音云端服务

2026-10-11：从 elin66alpha/AI_figure 的 `69312fd87564579bb28825719000a9b952dad46c` 同步 `server/` 全部 23 个文件。16 个 Python 文件保持原始字节；部署说明隐藏具体服务器地址并适配本仓上传路径。逐文件来源与哈希见 [UPSTREAM.json](UPSTREAM.json)。上游当前目录由 `esp32_server/` 重命名而来。

## 实际能力

设备 WebSocket `/ws`、PCM 音频回合、echo / asr / chat 三种模式；ASR、LLM、TTS 编排及阿里／火山／DeepSeek 适配；stunnel TLS-PSK、systemd 部署模板、电脑客户端与回声自测。

这是设备语音服务。iOS 客户端所需的 `/api/v1/devices/claim`、账号登录、设备归属、资产、文字回合等 HTTP 业务接口尚未在这里实现。服务导入不代表 App 接口完成，也不代表已部署或更新线上服务。

## 本地运行

在本目录创建独立 Python 虚拟环境，安装 `requirements.txt`；Node 的零依赖工具不涵盖此服务。

```powershell
cd D:\APP1\AIapp\server
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements.txt
.\.venv\Scripts\python main.py
```

另开终端，在相同目录执行 `.\.venv\Scripts\python tools/smoke_echo.py`。默认监听 `127.0.0.1:8765/ws`，默认 echo 不调用模型厂商。`env.example` 是配置清单，不会自动加载；ASR/chat 运行前需按环境配置厂商凭证。真实环境文件和 PSK 不入库。

## 文件分工

| 路径 | 作用 |
|---|---|
| `main.py`、`config.py` | 服务入口、监听与音频配置 |
| `session.py`、`pipeline.py`、`pacer.py`、`aioutil.py` | 回合状态、语音管线、音频节奏与异步工具 |
| `asr.py`、`llm.py`、`tts.py`、`ali_*`、`volc_*` | 厂商接口适配 |
| `tools/` | PC 客户端、回声冒烟测试 |
| `deploy/` | Linux 部署说明与模板；部署目录仍为 `/opt/esp32_server` |
| `UPSTREAM.json` | 固定版本、文件哈希和本仓差异 |

协议与服务说明：[上游 AGENT](../docs/upstream/AGENT.md)、[上游 SERVER](../docs/upstream/SERVER.md)。这两份是脱敏参考快照；其中固件路径与相对路径按上游目录解释，固件仍在 AI_figure。本仓产品需求：[固件需求](../docs/firmware-evaluation-request.md)、[设备交互基线](../docs/app-device-interaction-baseline.md)。

## 更新规则

后续同步先固定上游提交、对比 `UPSTREAM.json` 与本地差异，再合并；不得无条件覆盖本仓业务开发。设备语音协议随上游固件对齐，App HTTP 后端需求按产品文档另行实现与验收。此次完成源码同步与静态语法检查；启动、音频回声和真设备联调结果分别留证。
