# SST Website Chat API

## Development Environment

This project uses [Nix](https://nixos.org/) and [direnv](https://direnv.net/) to provide a reproducible development environment. The flake provisions the Rust toolchain, Docker, and builds container images via [crane](https://crane.dev/) and `dockerTools` (replacing the old cargo-chef Dockerfiles).

1. Install **Nix** (with flakes enabled):

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. Install **direnv** and hook it into your shell.
3. Allow the environment by running `direnv allow` in the project root.

After the environment loads, the shell provides **`start`**, **`start debug`**, and **`stop`** commands for running the stack (see [How to Run](#how-to-run)).

### Editor Setup

To ensure your editor's LSP (`rust-analyzer`, etc.) picks up the tools from the Nix environment, you need to configure it to use `direnv`:

#### VSCode

Install [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer). This is the recommended Rust LSP.

Install the [direnv extension](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv). It will automatically load the environment when you open the project and automatically download required dependencies. This may take a while.

#### Neovim

Install a plugin like [direnv.nvim](https://github.com/NotAShelf/direnv.nvim) to automatically load the environment buffer-locally, or ensure you launch `nvim` from a shell where the environment is already loaded.

## Configuration

Copy the `.env.sample` file to `.env` and fill in the required keys (e.g., `CLICKUP_API_KEY`, `TURNSTILE_SECRET_KEY`):

```bash
cp .env.sample .env
```

You can get your Clickup API Key by clicking your profile icon in the top right corner, then Settings, then under Integrations & ClickApps, click ClickUp API and generate a key.

For turnstile, you will need a secret key for this API and a site key for your frontend.
See: <https://app.clickup.com/t/2403171/869e1q6m2>

Set `LLM_PROVIDER` in `.env` to either `ollama` or `openai`. When using OpenAI,
also set `OPENAI_API_KEY`. The default OpenAI model is `gpt-5.4-nano`; override
it with `OPENAI_MODEL` if needed.

The HTTP API and WebSocket listeners default to ports `8080` and `3000`.
Configure them with `API_PORT` and `WEBSOCKET_PORT` in `.env`.

## How to Run

The first run builds Nix container images and loads them into Docker (including the Ollama model). This can take a while.

The default model is `qwen2.5:3b` (~2 GB), chosen to run on machines with 8 GB RAM. If RAM is limited, you can test with a smaller model, set `OLLAMA_MODEL` in `.env` (e.g. `llama3.2:1b`).

After `direnv allow`, these commands are on your `PATH` in **any shell** (bash, zsh, fish, etc.):

```bash
start          # release (recommended)
start debug    # unoptimized API, faster Nix rebuilds
start-debug    # same as `start debug` (for shells that prefer a single command)
stop
logs           # follow all service logs
logs api       # release API only
logs debug api # debug API only
logs-api       # same as `logs api`
logs-debug-api # same as `logs debug api`
```

Without direnv, use the flake apps instead: `nix run .#start`, `nix run .#start-debug`, `nix run .#stop`, `nix run .#logs`, etc.

`start` builds and loads images if needed, then runs `docker compose up -d`.

## How to Test

Testing will include integration with Ollama and database, make sure you have enough RAM available. It will take a while.

Make sure no docker instance is already running (stop them with `stop`) or else it will conflict.

The integration test builds the Ollama image with `nix build .#docker-ollama` on first run if it is not already loaded.

```bash
cargo test --workspace
```

## Production

Build and push the API image from the flake:

```bash
nix build .#docker --print-out-paths --no-link | xargs -I{} sh -c 'docker load < {} && docker tag chat-summary:release $REGISTRY/chat-summary:$TAG && docker push $REGISTRY/chat-summary:$TAG'
```

Deploy with your orchestrator of choice; inject secrets via environment variables or secrets management (never bake them into the image).

## Debugging

Set `RUST_LOG=DEBUG`.

You can view logs at <http://localhost:16686>.

To view documentation, run `cargo doc --workspace --no-deps --document-private-items --open`.
