# ai-cli-switch

统一管理多家 AI CLI 与模型源配置的实验性工具。

支持的 CLI target：`codex`、`gemini`、`claude`

支持的 provider：`openai`、`gemini`、`glm`、`anthropic`、`ollama`、`openrouter`

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
    ├── openrouter-free.json
    └── claude-proxy.json
```

## 设计原则

- `provider` 和 `cli target` 分离
- 同一个 profile 可以应用到不同 CLI
- 每个 CLI 通过独立适配层完成安装、启动、同步
- 不把 Gemini / Claude / DeepSeek 继续堆进 `codex-switch`

## 当前状态

已可用的能力：
- 管理 profile（增删改查）
- 选择当前 target：`codex` / `gemini` / `claude`
- 将 profile 应用到 `codex`、`gemini` 或 `claude`
- 安装与启动 `codex`、`gemini`、`claude`
- 从模板快速导入 `gemini-flash`、`glm-5.1`、`ollama-local`、`openrouter-free`、`claude-proxy`
- Claude Code 中转代理支持（Anthropic 兼容接口）
- 自定义 `small_model`（用于 `ANTHROPIC_SMALL_FAST_MODEL`）
- 连接测试自动识别 Anthropic 接口格式

## 运行

```bash
cd ai-cli-switch
bash install.sh

# 或直接运行
./ai-switch.sh
```

远程安装：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/liut-coder/ai-cli-switch/main/install.sh)
```

安装后会生成：
- 启动命令：`/usr/local/bin/ai-switch`
- 运行目录：`/usr/local/lib/ai-cli-switch`

## 非交互用法

```bash
./ai-switch.sh --list-profiles
./ai-switch.sh --add-gemini gem-work YOUR_GEMINI_KEY https://ai.hybgzs.com/gemini/v1 gemini-2.0-flash-lite
./ai-switch.sh --add-glm glm-work YOUR_GLM_KEY
./ai-switch.sh --add-claude-gemini claude-gem YOUR_PROXY_KEY https://your-anthropic-compatible-proxy gemini-3.1-pro-preview
./ai-switch.sh --add-claude-proxy my-proxy YOUR_KEY https://your-proxy.com/v1
./ai-switch.sh --add-claude-proxy my-proxy YOUR_KEY https://your-proxy.com/v1 claude-opus-4-20250514 claude-haiku-4-5-20251001
./ai-switch.sh --import-template gemini-flash gem-work YOUR_API_KEY
./ai-switch.sh --import-template claude-proxy my-proxy YOUR_API_KEY
./ai-switch.sh --show-profile gem-work
./ai-switch.sh --update-profile gem-work gemini gemini-2.5-flash https://your-base/v1 YOUR_KEY '["codex","gemini"]'
./ai-switch.sh --select-profile gem-work
./ai-switch.sh --select-target gemini
./ai-switch.sh --apply
./ai-switch.sh --install gemini
./ai-switch.sh --test gem-work
./ai-switch.sh --show-current
```

完整帮助：

```bash
./ai-switch.sh --help
```

## Claude Code 走 Gemini 中转

如果你的中转提供 Anthropic 兼容接口，并把请求转到 Gemini，可以直接用：

```bash
./ai-switch.sh --add-claude-gemini claude-gem YOUR_PROXY_KEY https://your-anthropic-compatible-proxy gemini-3.1-pro-preview
./ai-switch.sh --select-profile claude-gem
./ai-switch.sh --select-target claude
./ai-switch.sh --apply
./ai-switch.sh --launch claude
```

## Claude Code 走中转代理

如果你有 Anthropic 兼容的中转 API（直接转发到 Claude），使用 `--add-claude-proxy`：

### 快速开始

```bash
# 1. 添加 profile（默认模型 claude-sonnet-4-20250514）
./ai-switch.sh --add-claude-proxy my-proxy YOUR_API_KEY https://your-proxy.com/v1

# 2. 选择 profile 和 target
./ai-switch.sh --select-profile my-proxy
./ai-switch.sh --select-target claude

# 3. 应用配置
./ai-switch.sh --apply

# 4. 启动 Claude Code
./ai-switch.sh --launch claude
```

### 自定义模型

```bash
# 指定主模型和小模型
./ai-switch.sh --add-claude-proxy my-proxy YOUR_KEY https://your-proxy.com/v1 claude-opus-4-20250514 claude-haiku-4-5-20251001
```

参数说明：
- 参数 4（MODEL）：主模型，默认 `claude-sonnet-4-20250514`
- 参数 5（SMALL_MODEL）：小模型，用于 `ANTHROPIC_SMALL_FAST_MODEL`，默认与主模型相同

### apply 后生成的环境变量

`--apply` 会写入 `~/.config/ai-switch/env/current.env`，内容示例：

```bash
export ANTHROPIC_BASE_URL='https://your-proxy.com/v1'
export ANTHROPIC_API_KEY='YOUR_KEY'
export ANTHROPIC_AUTH_TOKEN='YOUR_KEY'
export ANTHROPIC_MODEL='claude-sonnet-4-20250514'
export ANTHROPIC_SMALL_FAST_MODEL='claude-haiku-4-5-20251001'
export ENABLE_TOOL_SEARCH='true'
```

### 使用 --launch 启动

`--launch claude` 会自动 source 环境变量并启动 `claude`：

```bash
./ai-switch.sh --launch claude
```

也可以手动 source 后启动：

```bash
source ~/.config/ai-switch/env/current.env
claude
```

### 连接测试

```bash
./ai-switch.sh --select-profile my-proxy
./ai-switch.sh --test
```

测试会自动识别 Anthropic 接口格式，发送一个最小请求验证连通性。

### 从模板导入

```bash
./ai-switch.sh --import-template claude-proxy my-proxy YOUR_API_KEY
```

### 在另一台机器上验证

```bash
# 安装
bash <(curl -fsSL https://raw.githubusercontent.com/liut-coder/ai-cli-switch/main/install.sh)

# 添加 Claude 中转 profile
ai-switch --add-claude-proxy my-proxy YOUR_KEY https://your-proxy.com/v1

# 选择并应用
ai-switch --select-profile my-proxy
ai-switch --select-target claude
ai-switch --apply

# 验证环境变量
cat ~/.config/ai-switch/env/current.env

# 测试连接
ai-switch --test

# 启动
ai-switch --launch claude
```

## Claude Code 走中转代理（Anthropic 兼容）

适用于通过中转 API 使用 Claude 原生模型的场景。

### 快速开始

```bash
# 1. 添加中转 profile（默认模型 claude-sonnet-4-20250514）
./ai-switch.sh --add-claude-proxy my-proxy YOUR_API_KEY https://your-proxy.com/v1

# 2. 选择 profile 和 target
./ai-switch.sh --select-profile my-proxy
./ai-switch.sh --select-target claude

# 3. 应用配置
./ai-switch.sh --apply

# 4. 启动 Claude Code
./ai-switch.sh --launch claude
```

### 自定义模型

```bash
# 指定主模型和小模型
./ai-switch.sh --add-claude-proxy my-proxy YOUR_KEY https://your-proxy.com/v1 claude-opus-4-20250514 claude-haiku-4-5-20251001
```

参数说明：
- 参数 4（MODEL）：主模型，默认 `claude-sonnet-4-20250514`
- 参数 5（SMALL_MODEL）：小模型，用于 `ANTHROPIC_SMALL_FAST_MODEL`，默认与主模型相同

### apply 后生成的环境变量

`--apply` 会写入 `~/.config/ai-switch/env/current.env`：

```bash
export ANTHROPIC_BASE_URL='https://your-proxy.com/v1'
export ANTHROPIC_API_KEY='YOUR_KEY'
export ANTHROPIC_AUTH_TOKEN='YOUR_KEY'
export ANTHROPIC_MODEL='claude-sonnet-4-20250514'
export ANTHROPIC_SMALL_FAST_MODEL='claude-haiku-4-5-20251001'
export ENABLE_TOOL_SEARCH='true'
```

### 手动 source 使用

如果不用 `--launch`，可以手动加载环境变量：

```bash
source ~/.config/ai-switch/env/current.env
claude
```

### 连接测试

```bash
./ai-switch.sh --test my-proxy
```

测试会自动识别 Anthropic 接口，使用 `x-api-key` + `anthropic-version` 头发送请求。

### 在另一台机器上验证

```bash
# 安装
bash <(curl -fsSL https://raw.githubusercontent.com/liut-coder/ai-cli-switch/main/install.sh)

# 添加 profile 并启动
ai-switch --add-claude-proxy my-proxy YOUR_KEY https://your-proxy.com/v1
ai-switch --select-profile my-proxy
ai-switch --select-target claude
ai-switch --apply
ai-switch --launch claude
```

### 从模板导入

```bash
./ai-switch.sh --import-template claude-proxy my-proxy YOUR_KEY
```

模板默认值：provider=anthropic, model=claude-sonnet-4-20250514, targets=["claude"]。
导入后需要手动修改 base_url：

```bash
./ai-switch.sh --update-profile my-proxy anthropic claude-sonnet-4-20250514 https://your-actual-proxy.com/v1
```
