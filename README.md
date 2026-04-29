# ai-cli-switch

统一管理多家 AI CLI 与模型源配置的实验性工具。

当前目标：
- 独立于 `codex-switch`
- 支持统一管理 `codex`、`gemini`
- 为后续接入 `claude`、`deepseek` 预留适配层

## 目录结构

```text
.
├── ai-switch.sh
├── install.sh
├── README.md
├── HISTORY.md
├── lib/
│   ├── core.sh
│   ├── store.sh
│   ├── ui.sh
│   ├── providers.sh
│   └── cli/
│       ├── codex.sh
│       ├── gemini.sh
│       ├── claude.sh
│       └── deepseek.sh
└── templates/
    ├── gemini-flash.json
    ├── glm-5.1.json
    ├── ollama-local.json
    └── openrouter-free.json
```

## 设计原则

- `provider` 和 `cli target` 分离
- 同一个 profile 可以应用到不同 CLI
- 每个 CLI 通过独立适配层完成安装、启动、同步
- 不把 Gemini / Claude / DeepSeek 继续堆进 `codex-switch`

## 当前状态

当前已经可用的 MVP 能力：
- 管理 profile
- 选择当前 target：`codex` / `gemini`
- 将 profile 应用到 `codex` 或 `gemini`
- 安装与启动 `codex` / `gemini`
- 从模板快速导入 `gemini-flash`、`glm-5.1`、`ollama-local`、`openrouter-free`

当前仍未完成：
- `claude` / `deepseek` target 适配
- 更细分的 provider 探测逻辑
- 更多高级命令行参数接口

## 运行

```bash
cd ai-cli-switch
bash install.sh

# 或直接运行
./ai-switch.sh
```

## 非交互用法

```bash
./ai-switch.sh --list-profiles
./ai-switch.sh --import-template gemini-flash gem-work YOUR_API_KEY
./ai-switch.sh --select-profile gem-work
./ai-switch.sh --select-target gemini
./ai-switch.sh --apply
./ai-switch.sh --install gemini
./ai-switch.sh --show-current
```

完整帮助：

```bash
./ai-switch.sh --help
```
