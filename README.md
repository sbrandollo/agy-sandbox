# Antigravity CLI Isolated Docker Sandbox

Run the **Antigravity CLI (`agy`)** inside an isolated Docker container with **YOLO mode** (`--dangerously-skip-permissions`), operating strictly inside a dedicated workspace folder mounted into the container.

---

## Architecture Overview

GitHub renders Mermaid diagrams natively. The diagram below illustrates how isolation and mounts work:

```mermaid
flowchart TD
    subgraph Host["Host Machine (macOS / Linux)"]
        User["Developer / CLI"]
        HomeDir["Host Home Dir (~/.gemini)"]
        HostFS["Protected Host Filesystem (/Users, /etc, ~/.ssh)"]
        TargetDir["Target Project Directory (/path/to/project)"]
    end

    subgraph Container["Docker Sandbox Container (agy-box)"]
        AgyCLI["Antigravity CLI (agy)"]
        YoloMode["YOLO Mode (--dangerously-skip-permissions)"]
        ContainerFS["Isolated Container Root (ephemeral)"]
        WorkDir["Mounted Workspace (/workspace)"]
    end

    User -->|"agy-box /path/to/project"| Container
    TargetDir <-->|"Read / Write Mount"| WorkDir
    HomeDir -.->|"Mount Settings & Auth"| Container
    HostFS x-.-x|"STRICTLY BLOCKED - Inaccessible"| Container
    AgyCLI --- YoloMode
    AgyCLI -->|"Executes edits & commands safely inside"| WorkDir
```

---

## Security & Isolation Highlights

- **Host Safety**: The container cannot touch files, system libraries, SSH keys, or environment settings outside the target folder you explicitly mount.
- **YOLO Mode**: Runs `agy` with `--dangerously-skip-permissions` so the agent executes operations autonomously without interactive approval prompts.
- **Non-Root User / UID Matching**: Runs with your host user UID and GID (`--user $(id -u):$(id -g)`) to avoid root ownership conflicts on your host files.
- **Hardened Execution**: Starts with `--security-opt=no-new-privileges:true` to prevent privilege escalation.

---

## Directory Structure

```
agy-sandbox/
├── Dockerfile           # Debian-based image with dev tools + Antigravity CLI
├── bin/
│   └── agy-box          # Convenient runner script
├── .gitignore
└── README.md
```

---

## Quick Start

### 1. Build the Image

From this repository directory:

```bash
docker build -t agy-sandbox:latest .
```

*(Note: `bin/agy-box` will build the image automatically if it is not present on your system).*

### 2. Run on a Workspace Folder

Pass any directory path as the first argument:

```bash
./bin/agy-box /path/to/your/project
```

Or pass additional `agy` CLI flags:

```bash
./bin/agy-box /path/to/your/project --model "Gemini 3.8 Flash (Medium)"
```

### 3. Add to your `PATH` (Optional)

Add `agy-sandbox/bin` to your `PATH` in `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="/path/to/agy-sandbox/bin:$PATH"
```

Then invoke it anywhere:

```bash
agy-box ~/Developer/my-app
```

---

## Key Use Cases

### Use Case 1: Unattended Autonomous Refactoring & Code Generation in YOLO Mode

When running large automated tasks (e.g. repo-wide refactorings, test migrations, lint fixes), Antigravity in normal mode asks for interactive confirmation for file modifications and terminal commands. YOLO mode bypasses these prompts, but running YOLO mode directly on your primary host machine risks accidental modifications to critical parent folders or configuration files.

`agy-box` provides a protective sandbox: `agy` runs completely hands-free with full YOLO privileges, but any tool execution or command is strictly confined to the mounted workspace.

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant Script as agy-box Runner
    participant Docker as Docker Container
    participant CLI as agy (YOLO Mode)
    participant WS as /workspace (Mounted Project)
    participant Host as Host Filesystem

    Dev->>Script: agy-box /repos/my-app -p "Refactor API client & run tests"
    Script->>Docker: Launch container with -v /repos/my-app:/workspace
    Docker->>CLI: agy --dangerously-skip-permissions -p "..."
    CLI->>WS: Read / Write project files autonomously
    CLI->>WS: Run build and test suite
    CLI--xHost: Attempt access outside /workspace (BLOCKED)
    Docker-->>Dev: Execution completed safely
```

---

### Use Case 2: Untrusted Code Inspection & Vulnerability Analysis

When inspecting third-party open-source repositories, candidate submissions, or legacy services with unknown build scripts, running them directly on your host machine poses supply-chain risks (e.g., malicious `npm postinstall` scripts, unauthorized network connections, or credential scrapers looking for `~/.ssh` or `~/.aws`).

With `agy-box`, the agent can inspect, unpack, compile, and run diagnostics on untrusted source code inside a sealed container that has no access to your host environment or private credentials.

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Security / Code Reviewer
    participant Container as agy-box Container
    participant Repo as Untrusted Target Repo
    participant HostSecrets as Host Secrets (~/.ssh, ~/.aws)

    Dev->>Container: agy-box /tmp/untrusted-repo -p "Audit dependencies & run build"
    Container->>Repo: Inspect code & run install scripts
    Note over Container,Repo: Untrusted scripts execute within container boundaries only
    Container--xHostSecrets: Cannot view or read host files
    Container-->>Dev: Audit report & suggestions
```

---

### Use Case 3: Clean Multi-Language Prototyping Without Host Toolchain Pollution

Developers frequently work on repositories requiring different runtimes, compiler versions, or system packages (e.g., Python dependencies, build essentials, tmux, jq). Instead of polluting your host OS or configuring virtual environments across machines:

The Docker container acts as a clean, disposable workstation where the Antigravity agent can install dependencies, run code, and create artifacts that persist cleanly in the mounted folder, leaving the host operating system completely pristine.

```mermaid
flowchart LR
    subgraph HostOS["Host System"]
        CleanHost["Clean OS (No dependency pollution)"]
        MountTarget["Target Project Folder"]
    end

    subgraph ContainerEnv["Docker Container (Disposable)"]
        DevTools["CLI Tools (git, curl, jq, vim, tmux)"]
        AgyAgent["Antigravity Agent"]
        TempBins["Container-local temp dependencies"]
    end

    MountTarget <-->|"Bidirectional Code Sync"| ContainerEnv
    AgyAgent --> DevTools
    DevTools --> TempBins
    ContainerEnv -.->|"Container exits: temp packages wiped"| CleanHost
```

---

## Configuration & Credentials

The launcher automatically mounts your existing CLI config directory (`~/.gemini/antigravity-cli` and `~/.gemini/config`) and host OAuth tokens (in read-only mode) so your API keys, base URLs, and project states persist across container runs without requiring re-authentication.

You can also provide custom environment variables directly:
```bash
AGY_API_KEY="your-api-key" AGY_BASE_URL="https://your-api.endpoint/v1" agy-box /path/to/folder
```
