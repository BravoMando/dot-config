# Neovim C/C++ 开发配置

面向 Neovim 0.12+，默认提供 CMake + Ninja 构建流程，兼顾 Windows、Linux / WSL 和 macOS。推荐使用 LLVM；编译器与链接器由项目的 CMake 配置决定，Neovim 不自动指定。插件只通过原生 `vim.pack.add` 安装；LSP 只通过 `vim.lsp.config` / `vim.lsp.enable` 配置。

## 目录

- [安装和首次启动](#安装和首次启动)
- [日常工作流](#日常工作流)
- [调试指南与快捷键](#debugging)
- [编辑、诊断和格式化](#编辑诊断和格式化)
- [Markdown 阅读与编辑](#markdown)
- [通用快捷键](#快捷键)
- [文件结构和维护](#文件结构和维护)

## 安装和首次启动

将仓库的 `nvim` 目录放到 `:echo stdpath('config')` 指向的位置：Linux/macOS 通常为 `~/.config/nvim`，Windows 通常为 `%LOCALAPPDATA%\nvim`。替换已有配置前先备份。不要将整个仓库当作 Neovim 配置目录。

首次启动需要联网访问 GitHub 和 Mason registry。确认 Neovim 原生插件安装提示后，Mason 在后台自动下载以下工具到 `stdpath('data')/mason`，只影响 Neovim 进程的 PATH，不需要系统级安装这些语言服务和调试器。

| 自动安装 | 用途 |
| --- | --- |
| clangd | C/C++ LSP、补全、语义高亮、诊断、内置 clang-tidy 检查和格式化 |
| clang-format | 独立 C/C++ 格式化 CLI，clangd 未连接时作为保存格式化兜底 |
| neocmakelsp | CMake 文件补全、导航和诊断 |
| CodeLLDB | C/C++ 断点、单步、变量、调用栈和表达式调试 |
| tree-sitter-cli | 编译和安装语法解析器 |

安装成功后自动启用语言服务，无需退出重开。配置按模块加载，单个模块出错会通知并继续加载其余功能。通过 `:Mason` 查看进度；失败时查看 `:MasonLog`，运行 `:DevToolsInstall` 重试。离线启动可以使用已安装的工具，但 registry 更新可能提示网络错误。

Mason 仅安装外部开发工具；Neovim 插件由原生 `vim.pack` 管理，语言服务由原生 LSP API 配置和启用。

### 仍需准备的基础环境

编辑器安装语言服务不能替代编译器、链接器、系统 SDK 和项目依赖。请准备：

- Neovim 0.12+、Git、CMake、Ninja，以及项目所需的 C/C++ 工具链。推荐 LLVM（`clang` / `clang++`），也可按项目配置使用 GCC、MSVC 等工具链。
- Python 3 与 venv：Mason 的 `clang-format` 包来自 PyPI；Debian/Ubuntu 需安装 `python3-venv`，Windows 需 Python 3。安装后的 clang-format 通过 Mason 的虚拟环境运行。
- Linux：与目标匹配的标准库、头文件、链接器，及 curl 或 wget、tar、gzip、unzip。
- Windows：PowerShell、Git、tar 和 Mason 支持的解压工具（例如 7-Zip）；准备项目工具链所需的 Windows SDK、C/C++ 标准库和链接器。使用 MSVC 库时，从 VS Developer PowerShell / Developer Command Prompt 启动 Neovim，让 INCLUDE、LIB 等环境变量生效。
- macOS：可用的 SDK 和开发工具，例如 Xcode Command Line Tools；使用自行安装的 LLVM 时将其 bin 放入 PATH。

运行 `:checkhealth cxx`、`:checkhealth mason` 检查环境。Mason 的预编译包受平台/CPU/运行库支持范围限制；不能保证所有 ARM 或 musl 系统都能安装 clangd。详见 [Mason 环境要求](https://github.com/mason-org/mason.nvim#requirements) 和 [clangd 包定义](https://github.com/mason-org/mason-registry/blob/main/packages/clangd/package.yaml)。

### WSL

将配置和工程放在 WSL 原生文件系统，避免 `/mnt/*` 的跨系统 I/O 拖慢 clangd 索引和 Ninja 构建。WSLg 下安装 `wl-clipboard` 可在 WSL 与 Windows 间共享系统剪贴板；没有剪贴板 provider 时不会强制启用 `unnamedplus`。附加已有进程可能受到系统 ptrace 策略限制。终端若拦截插入模式的 `Ctrl-S`，可执行 `stty -ixon`。

### 搜索工具（所有平台）

搜索使用 `fzf-lua + fzf + fd + ripgrep`：fzf 负责模糊筛选，fd 负责列出文件，rg 负责实时内容搜索。请将 fzf、fd、ripgrep 的可执行文件加入 PATH（它们不由 Mason 自动安装）；缺少 fd 时使用 `rg --files`，也支持部分 Linux 发行版的 `fdfind` 名称。搜索包含隐藏文件、排除 `.git` 并遵循工具的 ignore 规则，建议在项目 `.gitignore` 中排除构建产物。

安装 fzf 后，目标选择和代码操作列表也使用 fzf；未安装时这些列表保留原生选择界面，但 fzf-lua 搜索仍需要 fzf。mini 提供文件管理和编辑功能。使用 `:checkhealth cxx` 检查依赖。Nerd Font 只影响部分图标显示。接口与依赖要求见 [fzf-lua 官方文档](https://github.com/ibhagwan/fzf-lua#installation)。

## 日常工作流

1. 在项目根目录打开 Neovim，打开 C/C++ 文件。
2. 按 `<Space>pc` 配置 CMake，或直接按 `F7`，缺少缓存时会先配置再构建。
3. 按 `F6` 构建并运行；需要调试时，按 `<Space>b` 设置断点，再按 `<Space>dd` 构建并调试。
4. 已有可执行文件时，可按 `F5` 直接调试：优先使用项目 `.nvim/debug.lua`，没有该文件时复用当前项目已选的 target，未选择 target 时再输入程序路径；启动参数仍会询问。启动方式和全部调试快捷键见[调试指南](#debugging)。

构建前保存已命名的修改缓冲区；保存失败则不启动构建。任务异步执行，不阻塞编辑；失败日志进入 quickfix，`[q` / `]q` 跳转错误。构建失败时不会继续运行或调试。运行程序使用集成终端，支持标准输入；终端里按两次 Esc 返回普通模式。

默认缩进为两个空格；Makefile、Automake、TSV 及调试缓冲区等需要真实 Tab 的场景见[缩进与制表符](#indentation)。

<a id="cmake"></a>

### CMake、Ninja 和编译数据库

默认构建目录是项目下的 `build/`，默认构建类型是 Debug，配置使用 `CMAKE_EXPORT_COMPILE_COMMANDS=ON`。全新构建目录中，发现 Ninja 时默认使用 Ninja；未发现时交由 CMake 选择生成器。已有缓存保留原生成器，额外参数可以覆盖默认选项。

编译器、链接器及其选项由项目的 CMake 配置或 toolchain 文件管理。Neovim 不自动传入 `CMAKE_C_COMPILER`、`CMAKE_CXX_COMPILER`、链接器或链接器选择参数，也不修改 `CC` / `CXX` 环境变量；即使 PATH 中存在 clang/clang++，也不会自动优先选用。CMake 按项目配置、已有缓存和继承的环境选择工具链。推荐 LLVM，但不是使用本配置的前提；clangd、clang-format 和 CodeLLDB 是编辑器工具，不决定构建所用的编译器或链接器。`:checkhealth cxx` 不要求安装 clang/clang++。

```vim
:DevConfigure
:DevConfigure -DCMAKE_CXX_STANDARD=23
:DevConfigure -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain.cmake
:DevConfigure -DCMAKE_CXX_FLAGS="-O2 -g"
:DevBuild
:DevTarget
:DevRun
:DevDebug
:DevTest
:DevStop
```

配置参数支持单引号或双引号，含空格的值和带空格的 Windows 路径可以直接引用。`DevTest` 先构建全部目标，再运行 CTest。`DevStop` 向最近启动的构建任务发送终止信号；是否终止所有派生编译进程取决于系统与构建工具。调试入口见[启动、继续与结束](#debug-launch)。已有 Makefile 项目可构建，但不会自动生成其编译数据库。

项目根目录从当前文件所在目录向上寻找最近的 `.git` 或 `.clangd`，其中 `.git` 支持目录和 worktree / submodule 使用的文件形式；没有这些标记时，使用 Neovim 启动配置时的工作目录。请先在终端进入工程根目录，再运行 `nvim .`。启动目录只作为固定的回退位置；进入含独立 `.git` 或 `.clangd` 的子项目后，仍会使用子项目根目录。没有普通文件路径的缓冲区从当前工作目录开始查找。

CMakeLists.txt、Makefile 和 compile_commands.json 不单独作为根目录标记。构建目录、默认调试工作目录、LSP 和项目搜索共用此规则。多工程 monorepo 可在子工程根放置 `.clangd` 明确边界；实际路径可用[目录检查命令](#debug-targets)确认。

可在本次会话中更改构建子目录，然后重新配置：

```vim
:lua vim.g.cxx_build_dir = 'out/debug'
:lua vim.g.cxx_build_type = 'Release'
:DevConfigure
```

构建目录和构建类型设定都是会话级的，建议各工程统一相对目录；内置构建、目标选择和 CTest 都使用设定的类型。绝对构建目录也可以直接使用。CMake File API 提供目标和真实产物路径，避免猜测程序名。目标选择保存在当前会话，重新配置后清除。若修改 CMakeLists.txt 增删目标，重新运行 `DevConfigure` 和 `DevTarget`。

生成 `compile_commands.json` 后自动重启 clangd。根目录已有编译数据库时优先使用它，否则使用所选构建目录。外部生成数据库后可运行 `:DevLspRestart`。自定义目录也可以在项目 `.clangd` 中指定：

```yaml
CompileFlags:
  CompilationDatabase: out/debug
```

CMake Presets 不会自动选择；复杂工程可以在终端用自己的 preset 配置，并将 `vim.g.cxx_build_dir` 指向其 binaryDir。内置构建/测试默认按 Debug 执行，可用 `vim.g.cxx_build_type` 切换；单配置生成器缓存中的非空构建类型与设定不同时，下次构建会重新配置，多配置生成器则通过 `--config` 选择类型。请让会话设定与项目预期一致。已有 CMakeCache.txt 中的编译器选择不会因更新 Neovim 配置而改变；切换工具链或生成器时请使用新的构建目录。

<a id="debugging"></a>

## 调试指南与快捷键

快速查找：[首次调试](#debug-first) · [启动与结束](#debug-launch) · [项目调试配置](#debug-project-config) · [目标、参数与目录](#debug-targets) · [断点与单步](#debug-stepping) · [变量与面板](#debug-inspect) · [REPL](#debug-repl) · [数据断点](#debug-watchpoints) · [附加进程](#debug-attach) · [常见问题](#debug-troubleshooting) · [配置位置](#debug-config)

以下快捷键默认在普通模式使用，`<Space>` 表示先按空格再依次按后续字符；大小写有区别，例如 `<Space>dw` 添加监视，`<Space>dW` 打开监视列表。按 `<Space>fk` 可搜索映射。命令中的 `!` 是命令的一部分，例如 `:DevDebug!` 表示跳过构建。

<a id="debug-first"></a>

### 第一次调试

准备好带调试符号、架构匹配的程序及其源码。内置 CMake 构建默认使用 Debug；已有 Release 程序可能因优化而出现变量不可见或单步跳行。通过 `:Mason` 确认 CodeLLDB 已安装，环境问题用 `:checkhealth cxx` 检查。

1. 在工程根目录运行 `nvim .`，打开要调试的 C/C++ 源文件。
2. 将光标放到 `main` 内一条可执行语句上，按 `<Space>b` 设置断点。
3. 按 `<Space>dd`（或执行 `:DevDebug`）构建并调试；没有项目调试配置且有多个可执行目标时选择需要的目标。
4. 没有项目调试配置时，在参数提示中输入 `[]`，表示无命令行参数；已有 `.nvim/debug.lua` 则直接使用其中的程序路径和参数。
5. 命中断点后，用 `<Space>dS` 看变量、`<Space>dT` 看调用栈，按 `F10` 单步或 `F5` 继续。
6. 按 `Shift-F5` 或 `<Space>dq` 结束调试。

如果程序已在外部构建好，第 3 步改为按 `F5`；有 `.nvim/debug.lua` 时直接使用它，没有时复用当前项目已选的 target，未选择 target 时输入程序路径，然后输入启动参数。默认 `stopOnEntry = false`，启动后不会自动停在入口；没有命中断点时，程序可能直接运行完毕。

<a id="debug-launch"></a>

### 启动、继续与结束

| 快捷键 / 命令 | 没有调试会话时 | 已有调试会话时 |
| --- | --- | --- |
| `F5` | 优先读取 `.nvim/debug.lua`；没有时复用已选 target，未选择时输入路径；再输入参数，不构建 | 继续执行，不重新读取配置或询问参数 |
| `<Space>dd` / `:DevDebug` | 优先读取 `.nvim/debug.lua`，`launch` 配置构建成功后启动，`attach` 配置直接附加；没有时选择目标、构建并询问参数 | 继续执行，不重新读取配置或构建 |
| `:DevDebug!` | 优先读取 `.nvim/debug.lua`；没有时选择已有目标（无目标信息则输入路径）并询问参数；不构建 | 继续执行，不重新读取配置 |
| `<Space>dl` | 使用上一次的调试配置重跑，不构建 | 建议结束当前会话后再使用 |
| `<Space>da` | 从进程列表选择已有进程并附加 | 见[附加进程](#debug-attach) |
| `Shift-F5` / `<Space>dq` | — | 结束调试，调用 `dap.terminate()` |
| `<Space>dQ` | 无操作 | 断开调试连接，调用 `dap.disconnect()`，主要用于附加会话 |

修改源码后，要让新代码参与调试，应先结束当前会话，再按 `<Space>dd` 重新构建并启动。`F5` 和 `<Space>dl` 都不会编译源码。关闭调试面板也不会结束调试。

相关的构建和运行入口：

| 快捷键 / 命令 | 操作 |
| --- | --- |
| `<Space>pc` / `:DevConfigure` | 配置 CMake，更新目标信息 |
| `F7` / `<Space>pb` / `:DevBuild` | 构建；没有 CMake 缓存时先配置 |
| `F6` / `<Space>pr` / `:DevRun` | 构建后在终端运行，不启动调试器，也不读取 `.nvim/debug.lua` |
| `<Space>pt` / `:DevTarget` | 重新选择可执行目标 |
| `<Space>ps` / `:DevStop` | 停止最近启动的构建任务；停止调试用 `Shift-F5` |
| `<Space>q`、`[q`、`]q` | 打开 quickfix、跳到上一个 / 下一个编译错误 |

构建前自动保存已命名的修改缓冲区。保存或构建失败时，不会继续启动调试。

<a id="debug-project-config"></a>

### 项目调试配置：.nvim/debug.lua

在项目根目录创建 `.nvim/debug.lua`，返回一个 DAP 配置表。`F5`、`:DevDebug`、`:DevDebug!` 和 `<Space>dd` 在启动新会话时会自动检测此文件；存在时使用其中的配置，不再询问程序路径、目标或参数；不存在时完整保留原有交互流程。

```lua
-- .nvim/debug.lua
local root = require("project").root()
local suffix = vim.fn.has("win32") == 1 and ".exe" or ""

return {
  name = "调试 myapp",
  type = "codelldb",
  request = "launch",
  program = root .. "/build/myapp" .. suffix,
  cwd = root,
  args = { "--config", "config/dev.json", "--port", "8080" },
  env = {
    APP_ENV = "development",
    LOG_LEVEL = "debug",
    DATA_DIR = root .. "/data",
  },
  stopOnEntry = false,
  terminal = "integrated",
}
```

| 字段 | 含义 / 省略时的行为 |
| --- | --- |
| `program` | `launch` 必填：实际可执行文件路径，也支持返回路径的函数；建议像示例一样基于项目根目录组成绝对路径 |
| `name` | 调试配置显示名称；默认 `Project debug` |
| `type` / `request` | 默认 `codelldb` / `launch`；`attach` 配置可提供 `pid`，并跳过构建 |
| `cwd` | 程序工作目录；默认项目根目录，可提供另一个绝对路径 |
| `args` | Lua 字符串数组；省略时为 `{}`，不会弹出参数输入框 |
| `env` | 环境变量表，值写成字符串，补充或覆盖被调试进程继承的环境 |
| `stopOnEntry` | 是否在启动后立即暂停；默认 `false` |
| `terminal` | 程序输入输出位置；默认 `integrated` |

`program` 是程序路径，不是 CMake 目标名。使用项目的 `launch` 配置执行 `DevDebug` / `<Space>dd` 时会构建工程的全部目标，然后启动 `program`，避免之前选择的其他目标影响构建；构建失败不会启动。`attach` 配置跳过构建。`F5` / `DevDebug!` 不构建，适合已编译好的程序或外部构建流程。

每次启动新会话都会重新执行该 Lua 文件，没有模块缓存。修改后先保存文件，再结束旧会话并重新启动；已有会话时上述入口只继续执行。`<Space>dl` 仍重跑上次配置，不重新读文件；`<Space>da` 仍打开原来的进程选择流程。

文件必须返回单个配置表。语法错误、执行错误或缺少启动所需的 `program` 会显示带文件路径的错误并停止，不会退回交互流程。其他 DAP 字段（如 `initCommands`）会原样传给 nvim-dap。此文件作为 Lua 代码执行，可使用 `require("project").root()` 等现有模块；配置检测使用当前项目根目录，定位方法见[目标、参数与目录](#debug-targets)。

<a id="debug-targets"></a>

### 可执行目标、程序参数与工作目录

未找到 `.nvim/debug.lua` 时，`DevDebug` / `DevDebug!` 优先使用当前会话中已选择的工程目标；否则从 CMake File API 读取可执行目标。唯一目标自动选择，多个目标显示列表，没有目标信息时提示输入程序路径。首次 `DevDebug` 可以先配置、构建工程，再获取目标。重新选择用 `<Space>pt`；增删 CMake 目标后先运行 `:DevConfigure`，再运行 `:DevTarget`。

未找到 `.nvim/debug.lua` 时，`F5` 复用当前 Neovim 会话中通过 `<Space>dd`、`<Space>pt` / `:DevTarget` 等操作保存的当前项目 target，不再询问程序路径；未选择 target 时才询问路径，即使 CMake 已发现可用目标。启动参数仍会询问。已选 target 的可执行文件不存在时会尝试刷新路径，仍找不到则报错；可先构建或用 `:DevTarget` 重新选择。路径输入从项目构建目录开始，支持文件路径补全；应输入可执行文件，而不是源码、目录或带参数的整条命令。

交互输入框中的程序参数使用 **JSON 字符串数组**（`.nvim/debug.lua` 中使用上面的 Lua 表语法）：

```json
["--input", "data/my file.txt", "--count", "10"]
```

每个字符串是一个参数，含空格的路径保持为一个参数。无参数输入 `[]`；数字也要写成字符串，例如 `"10"`。Windows 路径可使用正斜杠（如 `"D:/data/input.txt"`），使用反斜杠时需按 JSON 规则写成 `"D:\\data\\input.txt"`。不要直接输入 `--input file.txt` 这样的 shell 参数串。

被调试进程的 `cwd` 默认设置为项目根目录，因此 `data/input.txt` 等相对路径默认从项目根目录解析；项目调试配置可覆盖 `cwd`。默认构建目录为根目录下的 `build/`，可通过 `vim.g.cxx_build_dir` 修改，见 [CMake、Ninja 和编译数据库](#cmake)。

当前实现仍从当前文件向上查找最近的 `.git` / `.clangd`，无标记才回退到启动目录；进入带 `.git` 的 submodule 时可能识别为子项目。可用以下命令确认实际目录：

```vim
:lua print(require('project').root())
:lua print(require('project').build_dir())
```

程序输入输出默认使用集成终端，需要标准输入时切到程序终端输入；终端模式中连续按两次 `Esc` 返回普通模式，再使用调试快捷键。项目调试配置可通过 `terminal` 选择其他输入输出位置。

<a id="debug-stepping"></a>

### 断点与单步

| 快捷键 | 操作 | 使用说明 |
| --- | --- | --- |
| `<Space>b` | 切换普通断点 | 在当前行添加 / 移除断点 |
| `<Space>B` | 设置条件断点 | 输入条件，例如 `i == 100`；条件成立时暂停 |
| `<Space>dp` | 设置日志断点 | 输入日志消息，例如 `i={i}, total={total}`；命中时输出消息而不暂停 |
| `F5` | 继续 | 运行到下一个断点或其他暂停事件 |
| `F10` | 单步跳过 | 执行当前语句，通常不进入被调用函数 |
| `F11` | 单步进入 | 进入当前语句调用的函数 |
| `F12` | 单步跳出 | 执行到当前函数返回 |

单步操作在程序暂停后使用。源码边栏中，`●` 表示断点，`▶` 表示当前暂停位置，并高亮当前执行行。断点列表通过 `<Space>dB` 查看；异常断点相关视图通过 `<Space>dE` 打开。

<a id="debug-inspect"></a>

### 变量、监视、调用栈与面板

调试面板由 `nvim-dap-view` 提供，启用自动打开 / 关闭，默认显示作用域变量（scopes），顶部带调试控制按钮。

| 快捷键 | 操作 | 适合查看什么 |
| --- | --- | --- |
| `<Space>de` | 浮窗求值 | 临时查看光标处表达式的值 |
| `<Space>dw` | 添加监视表达式 | 持续观察表达式；支持普通和可视模式 |
| `<Space>dW` | 打开监视列表 | 已添加的监视表达式及其值 |
| `<Space>dS` | 打开变量视图 | 当前栈帧作用域中的变量 |
| `<Space>dT` | 打开线程与调用栈 | 当前线程、函数调用链与栈帧 |
| `<Space>dB` | 打开断点视图 | 查看和管理断点 |
| `<Space>dE` | 打开异常视图 | 异常断点相关设置 |
| `<Space>dR` | 打开 REPL | 调试交互与表达式求值 |
| `<Space>dC` | 打开控制台 | 查看调试输出 |
| `<Space>dv` | 显示 / 隐藏调试面板 | 切换面板可见性 |
| `<Space>dc` | 关闭调试面板 | 收起界面，调试会话仍继续 |

变量值和表达式求值通常需要程序暂停，并且表达式在所选栈帧中有效。`<Space>dw` 添加的是表达式监视；需要在值被改写时暂停，见[数据断点](#debug-watchpoints)。

`nvim-dap-virtual-text` 会在源码旁显示变量值，使用注释形式的前缀；这些是虚拟文本，不写入源文件。继续运行时清除旧值。源码内变量显示依赖可用的 Tree-sitter parser 和变量查询；显示缺失时可先在变量面板查看。调试缓冲区及可编辑临时浮窗中的插入模式 `Tab` 保留为实际制表符。

<a id="debug-repl"></a>

### REPL：查看变量与执行调试命令

先让程序停在断点处，按 `<Space>dR` 打开 REPL，切到该窗口后按 `i` 输入，Enter 提交，Esc 返回普通模式。变量求值使用当前选中的栈帧；找不到变量时，用 `<Space>dT` 检查调用栈和作用域。

CodeLLDB 默认把输入当作 LLDB 命令，计算表达式时加 `?`。以下例子假设相应变量在当前栈帧中可用：

| REPL 输入 | 操作 |
| --- | --- |
| `?count` | 查看变量 |
| `?count + 10` | 计算表达式 |
| `?array[0]` / `?ptr->value` | 查看数组元素或对象成员 |
| `?/nat values.size()` | 使用原生 C++ 表达式求值；函数调用可能产生副作用 |
| `.scopes` | 显示当前作用域变量 |
| `.frames` / `.threads` | 显示调用栈 / 线程 |
| `.n` / `.into` / `.out` | 单步跳过 / 进入 / 跳出 |
| `.c` | 继续执行 |
| `.exit` | 关闭 REPL，不结束调试 |

以点开头的上述命令由 nvim-dap 提供，其他输入发送给 CodeLLDB。程序中的 `scanf` / `std::cin` 应在程序终端输入，REPL 用于调试器交互。完整语法见 [CodeLLDB 调试控制台](https://github.com/vadimcn/codelldb/blob/master/MANUAL.md#debug-console)；nvim-dap 命令可在 `:help dap.repl.open()` 中查阅。

<a id="debug-watchpoints"></a>

### 数据断点：在变量被改写时暂停

数据断点（watchpoint）监视一段内存的访问。当前没有专用快捷键，可在 CodeLLDB 的 REPL 中使用 LLDB 命令设置写入监视点：

1. 用普通断点停在变量已初始化、仍在作用域内的位置。
2. 按 `<Space>dR` 打开 REPL，输入 `watchpoint set variable count`，将 `count` 替换为要监视的变量。
3. 设置成功后输入 `.c` 继续，发生被监视的写入时程序暂停，再用 `<Space>dT` 查找修改来源。

| REPL 输入 | 操作 |
| --- | --- |
| `watchpoint set variable count` | 监视变量自身的内存写入 |
| `watchpoint set expression -x 4 -- &obj.value` | 监视成员地址起始的 4 字节；示例假设 `value` 是 `int32_t` |
| `watchpoint set expression -x 4 -- ptr` | 监视 `ptr` 当前指向的 4 字节，而非指针变量自身 |
| `watchpoint list` | 列出数据断点及编号 |
| `watchpoint delete 1` | 删除编号为 1 的数据断点，以实际编号为准 |

地址在设置时确定。局部变量离开作用域、对象释放、容器重新分配或指针改指向后，应重新检查监视地址；监视点不会自动跟随指针。支持情况取决于 CPU、操作系统和 LLDB，常见 x86-64 硬件限制为最多 4 个、每个区域 1 / 2 / 4 / 8 字节，优先监视具体成员。见 [LLDB 监视点命令](https://lldb.llvm.org/use/map.html#watchpoint-commands)和 [CodeLLDB 数据断点](https://github.com/vadimcn/codelldb/blob/master/MANUAL.md#data-breakpoints)。

<a id="debug-attach"></a>

### 附加到正在运行的进程

先在外部启动程序，再按 `<Space>da` 从进程列表选择目标。C 和 C++ 共用 CodeLLDB 的 `attach` 配置；这个入口不会构建程序，也不会询问启动参数。附加是否成功取决于目标架构、调试信息与操作系统权限，Linux / WSL 还可能受到 ptrace 限制。

附加后可使用相同的断点、单步和变量快捷键。需要断开连接时使用 `<Space>dQ`。当前配置未显式指定断开时是否终止目标进程，最终行为取决于会话类型和适配器；不要将它视为对所有会话都保证保留进程。结束调试使用 `<Space>dq` / `Shift-F5`。

<a id="debug-troubleshooting"></a>

### 常见问题

| 现象 | 检查与处理 |
| --- | --- |
| 提示 `CodeLLDB is not ready` | 在 `:Mason` 检查安装状态；运行 `:DevToolsInstall` 重试，失败看 `:MasonLog`。配置使用 Mason 安装目录中的 CodeLLDB |
| 提示 `Invalid debug configuration` | 按错误中的路径检查 `.nvim/debug.lua`，确保返回单个配置表且 `launch` 提供 `program`；修正并保存后重新启动 |
| `.nvim/debug.lua` 没生效或仍弹出路径输入框 | 用目录检查命令确认文件放在实际项目根目录下；结束旧会话后用 `F5` / `DevDebug` 启动，`<Space>dl` 不重读配置 |
| 启动后直接退出，没有停在 `main` | 默认不在入口自动暂停；先在 `main` 内可执行语句上设置断点，并确认程序执行到了该行 |
| 断点不命中、源码位置不匹配 | 确认可执行文件与当前源码对应，使用带调试符号的构建；结束旧会话后按 `<Space>dd` 重新构建 |
| 改了源码，调试行为没变化 | `F5` / `<Space>dl` 不构建；已有会话时 `<Space>dd` 也只继续执行。先结束会话，再构建并启动 |
| 找不到程序或选中了旧目标 | 有 `.nvim/debug.lua` 时检查其中的 `program`；没有时检查构建结果，增删目标后运行 `:DevConfigure` 和 `:DevTarget`；未选择 target 时也可用 `F5` 指定已有程序 |
| 找不到相对路径的数据文件，或 build 出现在子目录 | 用上面的目录检查命令确认项目根目录；注意当前 submodule 的 `.git` 也会参与根目录识别 |
| 变量不可见或单步跳行 | 检查优化等级、调试符号、当前栈帧及变量作用域；优先用 Debug 构建排查 |
| 程序等待输入，快捷键却被输入到终端 | 在程序终端输入数据；需要控制调试时按两次 `Esc` 返回普通模式 |
| 关了面板但程序还在运行 | `<Space>dc` 仅关闭界面；`Shift-F5` / `<Space>dq` 才结束调试 |
| `DevStop` 没有结束调试 | 它停止的是构建任务；调试使用 `Shift-F5` / `<Space>dq` |
| 附加进程失败 | 检查操作系统调试权限、进程架构以及目标是否仍在运行 |
| REPL 输入变量名被当作命令，或提示找不到变量 | 表达式前加 `?`；确认程序暂停，并选中变量所在的栈帧 |
| 添加监视表达式后，变量改变却没有暂停 | `<Space>dw` 仅显示表达式结果；需要暂停时设置[数据断点](#debug-watchpoints) |

<a id="debug-config"></a>

### 配置位置与扩展

| 文件 | 调试相关职责 |
| --- | --- |
| [dap-config.lua](nvim/lua/dap-config.lua) | CodeLLDB 适配器、启动与附加配置、断点、面板和调试快捷键 |
| [project.lua](nvim/lua/project.lua) | 根目录、CMake 目标、构建、程序路径和 JSON 参数输入 |
| [mason-tools.lua](nvim/lua/mason-tools.lua) | 安装 CodeLLDB 等外部工具 |
| [plugins.lua](nvim/lua/plugins.lua) | 使用原生 `vim.pack.add` 安装调试插件 |
| [basic.lua](nvim/lua/basic.lua) | 终端退出映射、调试缓冲区的 Tab 行为 |

CodeLLDB 适配器位于 `stdpath('data')/mason/packages/codelldb/extension/adapter/codelldb`（Windows 加 `.exe`），由 nvim-dap 启动并通过动态端口连接，实际调试使用 LLDB。`lldb-dap` 是另一种适配器，本配置不需要同时安装它；切换适配器需要调整注册和启动参数。clangd 负责编辑时的语言服务；`compile_commands.json` 供语言服务使用，不能替代程序调试符号。

项目启动参数、环境变量、源码路径映射及其他 DAP 字段可放在 [`.nvim/debug.lua`](#debug-project-config)；更换适配器或扩展全局调试流程可修改 `dap-config.lua`。当前没有自动导入 `.vscode/launch.json`。进一步查阅：[nvim-dap 操作说明](https://github.com/mfussenegger/nvim-dap/blob/master/doc/dap.txt)、[CodeLLDB 参数与表达式](https://github.com/vadimcn/codelldb/blob/master/MANUAL.md)、[调试面板](https://github.com/igorlfs/nvim-dap-view)、[源码虚拟变量值](https://github.com/theHamsta/nvim-dap-virtual-text)。

## 编辑、诊断和格式化

<a id="indentation"></a>

### 缩进与制表符

默认使用两个空格缩进。以下文件按文件类型保留真实 Tab，按键输入不会展开成空格：

| 文件类型 | 常见文件 | Tab 行为 |
| --- | --- | --- |
| `make` | Makefile、makefile、GNUmakefile、`*.mk` | 保留真实制表符，用于规则中的命令行缩进 |
| `automake` | Makefile.am | 保留真实制表符 |
| `tsv` | `*.tsv` | 保留真实制表符作为字段分隔符，包括行内输入 |

这些文件设置 `noexpandtab`、`softtabstop=0`、`shiftwidth=0`，缩进操作按当前 `tabstop` 宽度处理，文件中保存的是真实制表符。文件类型识别、切入缓冲区及进入插入模式时都会应用这条规则，因此通用 `.editorconfig` 空格缩进规则也不会使这些文件的 Tab 变成空格。此设置不自动改写文件里已有的空格。

调试缓冲区及可编辑的临时浮窗同样保留真实 Tab。其他语言仍可由 Neovim 的文件类型插件或项目 `.editorconfig` 定义缩进。若自定义文件名没有被识别为 Makefile，可用 `:setfiletype make` 指定；用 `:setlocal filetype? expandtab? softtabstop? shiftwidth? tabstop?` 查看当前设置。

### 补全、诊断与格式化

C/C++ 使用原生 LSP 补全与 snippet 跳转。输入字母、数字和下划线自动触发补全，Tab / Shift-Tab 选择候选或跳转 snippet，Enter 接受候选，Esc 先关闭补全菜单。clangd 的 inlay hints（参数名和推导类型）默认开启，可用 `<Space>ch` 切换；光标停留时会高亮当前符号的所有引用。未选择候选时 Enter 接受第一项；手动触发可使用原生 `Ctrl-X Ctrl-O`。

clangd 内置 clang-tidy 实时检查，无需独立 clang-tidy 可执行程序；这不等同于执行完整的离线 clang-tidy 扫描。默认不启用 clang-tidy，也不会生成模板；只有项目根目录存在 `.clang-tidy` 时才启用，新增或修改该文件后运行 `:DevLspRestart` 生效。项目可用 `.clang-tidy` 选择规则：

```yaml
Checks: '-*,clang-analyzer-*,bugprone-*,performance-*,modernize-use-nullptr'
WarningsAsErrors: ''
```

clangd 内置格式化遵循项目 `.clang-format`，没有项目文件时使用 LLVM 风格。Mason 安装的独立 `clang-format` 在 clangd 未连接时作为保存和手动格式化兜底。默认保存 C/C++ 文件时格式化，可按 `<Space>cF` 切换；手动格式化为 `<Space>cf` 或 `:DevFormat`。没有可用格式化器时不会阻止保存。例：

```yaml
BasedOnStyle: LLVM
IndentWidth: 2
ColumnLimit: 100
```

配置不强行指定项目 C/C++ 标准、include 路径和宏，它们来自 CMake 编译数据库。遇到“找不到头文件”先检查构建是否成功、数据库是否覆盖当前源文件、SDK 环境是否可用。单文件可使用 clangd 的默认解析，但完整项目体验需要真实编译参数。

Tree-sitter CLI 安装后，有 C 编译器时自动安装 C/C++、Lua、CMake、Markdown（`markdown` 和 `markdown_inline`）parser。parser 未就绪时保留基础高亮和 LSP 语义高亮；补齐编译器后运行 `:DevParsersInstall`。Windows 编译 parser 同样需要完整开发环境。更新 nvim-treesitter 后运行 `:TSUpdate`，上游要求 parser 与插件版本匹配，见 [Tree-sitter 文档](https://github.com/nvim-treesitter/nvim-treesitter)。

<a id="markdown"></a>

### Markdown 阅读与编辑

[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) 在 Neovim 内显示标题、代码块、表格、列表、任务框和引用的装饰效果，不修改文件内容。配置位于 [markdown.lua](nvim/lua/markdown.lua)，复用已有的 `nvim-web-devicons` 图标；建议使用 Nerd Font，以正常显示装饰图标。

更新这套配置后，重启 Neovim 并确认原生插件安装提示，再运行 `:DevParsersInstall` 安装新增的 Markdown parser。等待安装完成后重新打开 `.md` 文件。普通模式和命令行模式默认渲染，光标所在行按插件默认规则显示原始语法；插入及可视模式显示源码，方便修改和选择。

| 快捷键 / 命令 | 操作 |
| --- | --- |
| `<Space>mp` / `:RenderMarkdown toggle` | 全局开启 / 关闭 Markdown 渲染 |
| `:RenderMarkdown buf_toggle` | 单独切换当前缓冲区渲染 |
| `:RenderMarkdown preview` | 在 Neovim 内打开旁侧预览，使用 `:q` 关闭预览窗口 |
| `:checkhealth render-markdown` | 检查插件和 parser 环境 |

此配置不安装浏览器预览服务或外部转换工具。LaTeX 转换默认关闭，公式和 Mermaid 代码保留源码；图片链接不会转换成图片显示。若文件没有渲染，先检查 `:set filetype?` 是否为 `markdown`，再检查两个 Markdown parser 是否安装成功。公式转换若以后需要启用，还需安装 `latex` parser 和插件支持的转换工具，详见上游依赖说明。

HTML 标签（例如 `<a id="section"></a>`）默认保留源码。当前未加入 `html` parser 或自定义标签显示规则；插件也不提供浏览器式的完整 HTML 渲染。普通链接优先使用 `[文字](地址)` 的 Markdown 写法。

## 快捷键

Leader 是空格。按空格稍等会显示快捷键提示；`<Space>fk` 可搜索映射。Neovim 原生 `gcc` / `gc` 注释操作保持可用。调试快捷键集中在[调试指南](#debugging)，下表列出通用编辑和工程操作。

| 快捷键 | 操作 |
| --- | --- |
| `<Space>w` | 保存；文件浏览器内同步修改 |
| `<Space>v` | 块选择（visual block）；Windows Terminal 下替代 `Ctrl-V` |
| `<Space>e` / `<Space>E` | 当前文件目录 / 当前工作目录的文件浏览器 |
| `<Space>ff` / `<Space>fg` / `<Space>fb` / `<Space>fh` | 项目文件 / 搜索 / 缓冲区 / 帮助 |
| `<Space>fk` | 搜索快捷键映射 |
| `<Space>mp` | 开启 / 关闭 Markdown 渲染 |
| `<Space>fs` / `<Space>fS` | 文档符号 / 工作区符号 |
| `<Space>fd` | 搜索诊断 |
| `gd` / `gD` | 定义 / 声明 |
| `gri` / `grt` / `grr` | 实现 / 类型定义 / 引用（Neovim 原生映射） |
| `K` / 插入模式 `Ctrl-S` | 文档 / 函数签名 |
| `<Space>cr` / `<Space>ca` | 重命名 / 代码修复和操作 |
| `<Space>cf` / `<Space>cF` | 格式化 / 切换保存格式化 |
| `<Space>cs` / `<Space>ch` | 源文件与头文件切换 / 切换 inlay hints（默认开启） |
| `<Space>ct` / `<Space>cT` | 类型层次：子类型 / 父类型 |
| `[d` / `]d` | 上一个 / 下一个诊断，使用原生映射 |
| `<Space>ce` / `<Space>cl` | 诊断详情 / 全部诊断进入 quickfix |
| `<Space>q` / `[q` / `]q` | quickfix / 上一个 / 下一个编译错误 |
| `<Space>pc` / `<Space>pb` / `<Space>pt` | CMake 配置 / 构建 / 选择可执行目标 |
| `<Space>pr` / `<Space>pT` / `<Space>ps` | 运行 / CTest / 停止构建任务 |
| `F7` / `F6` | 构建 / 构建并运行 |

`<Space>v`（普通/可视模式）进入块选择，等价于原生 `Ctrl-V`；在 Windows Terminal 中即使 `Ctrl-V` 被终端粘贴占用也能使用。选中矩形区域后可用 `I` / `A` 在多行插入，`c` 修改，`d` 删除，`r` 替换字符，`>` / `<` 缩进，`~` 切换大小写。

文件浏览器用 h/l 进出目录、q 关闭、gs 同步文件变更、g. 切换隐藏文件、g? 查看帮助。mini.surround 提供 sa/sd/sr 包围操作，mini.ai 提供增强文本对象；mini.diff 显示 Git 修改，mini.statusline 显示状态。

## 文件结构和维护

| 文件 | 职责 |
| --- | --- |
| `init.lua` | 检查版本并按依赖顺序加载模块 |
| `plugins.lua` / `colorscheme.lua` | 原生插件声明 / Catppuccin Mocha |
| `basic.lua` / `editing.lua` | 基础选项 / 状态栏、文本对象、括号、Git、快捷键提示 |
| `mason-tools.lua` | 工具安装、失败提示、安装完成事件 |
| `lsp.lua` / `completion.lua` | 原生 LSP、诊断、clangd/clang-format 格式化 / 原生补全和 snippet |
| `project.lua` | 根目录、CMake File API、构建、运行、测试 |
| `dap-config.lua` | CodeLLDB、调试面板、快捷键 |
| `treesitter.lua` | parser 安装与高亮 |
| `markdown.lua` | Markdown 渲染和切换快捷键 |
| `fuzzy.lua` / `mini-files.lua` / `devicons.lua` | 搜索 / 文件管理 / 图标 |
| `cxx/health.lua` | `:checkhealth cxx` |

所有路径在本表中相对于 `nvim/lua`，`init.lua` 位于 `nvim`。每个 Lua 配置文件的首行保留一行仓库相对路径注释，例如 `-- nvim/lua/lsp.lua`；其余位置不放注释，设计和操作说明统一维护在本 README。

更新插件运行 `:lua vim.pack.update()`，查看原生确认缓冲区后保存以应用更新；Mason 工具在 `:Mason` 中更新。Neovim 自动维护 `nvim-pack-lock.json`，请将首次安装后实际生成的锁文件纳入版本控制，以固定经验证的插件版本；不要手写锁文件。插件或工具更新后，请重新验证关键流程。

可用 `vim.pack.get()` 检查已安装的插件，并按原生帮助处理不再使用的包。

`nvim-dap-view` 当前指定稳定发布版 `v1.3.0`。Neovim 的版本通配范围不会自动排除预发布标签，因此需要升级时，先确认上游最新稳定发布的标签，再修改 `plugins.lua` 中的版本号并运行 `:lua vim.pack.update({ 'nvim-dap-view' })`；已有锁文件不会仅因重启而自动升级。

`startup.lua` 检查真实插件模块加载、关键映射、Markdown 实际渲染、关闭后的装饰清理、源码保持不变及 F5 的交互流程；需要可用的 `markdown` 和 `markdown_inline` parser。`integration.lua` 使用 PATH 中的构建工具，覆盖含空格路径的配置/构建/CTest、多目标选择、引号参数、构建类型切换、首次运行和终端退出码；提供对应工具后，还测试 clangd、格式化，以及 CodeLLDB 的启动、源码断点、线程请求和终止。

缺少构建工具或 C++ 编译器时，集成测试会打印 `SKIP` 并以成功状态退出；没有提供可选工具时，对应测试也会跳过。评估结果时应检查实际的 `PASS` / `SKIP` 输出，不能仅凭退出码认定所有功能通过。真实编译与调试需要在目标操作系统和项目工具链上分别验证。
