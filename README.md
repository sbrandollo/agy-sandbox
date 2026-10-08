# Antigravity CLI Isolated Docker Sandbox

This setup lets you run the **Antigravity CLI (`agy`)** inside an isolated Docker container with **YOLO mode** (`--dangerously-skip-permissions`), operating strictly inside a designated workspace folder mounted into the container.

## Security & Isolation

- **Host Safety**: The container cannot touch files or directories on your host machine outside the directory you explicitly provide.
- **YOLO Mode**: Runs `agy` with `--dangerously-skip-permissions` so the agent executes operations autonomously without interactive approval prompts.
- **Dedicated User**: Runs with non-root user matching your host's UID/GID to avoid root ownership conflicts on your mounted files.
- **Hardened Container**: Starts with `--security-opt=no-new-privileges:true`.

---

## Directory Structure

```
agy-sandbox/
├── Dockerfile           # Debian-based image with dev tools + Antigravity CLI
├── bin/
│   └── agy-box          # Convenient runner script
└── README.md
```

---

## Quick Start

### 1. Build the image

From this repository directory:

```bash
docker build -t agy-sandbox:latest .
```

*(Note: `bin/agy-box` will automatically build the image if it is not found on your system).*

### 2. Run on a folder

Pass any directory path as the first argument:

```bash
./bin/agy-box /path/to/your/project
```

Or pass additional `agy` CLI flags:

```bash
./bin/agy-box /path/to/your/project --model "Gemini 3.8 Flash (Medium)"
```

### 3. Add to your PATH (Optional)

Add `agy-sandbox/bin` to your `PATH` in `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="/path/to/agy-sandbox/bin:$PATH"
```

Then run it from anywhere:

```bash
agy-box ~/Developer/my-app
```

---

## Configuration & Credentials

The launcher script mounts your existing CLI config directory (`~/.gemini/antigravity-cli`) into the container so your API keys, base URLs, and settings are preserved.

You can also pass environment variables directly:
```bash
AGY_API_KEY="your-api-key" AGY_BASE_URL="https://your-api.endpoint/v1" agy-box /path/to/folder
```
