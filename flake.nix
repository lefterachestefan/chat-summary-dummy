{
  description = "chat-summary development and container builds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    ollama-models-nix = {
      url = "github:dzmitry-lahoda-forks/ollama-models-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    rust-overlay,
    crane,
    ollama-models-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        overlays = [
          (import rust-overlay)
          ollama-models-nix.overlays.default
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        src = ./.;

        rust = import ./nix/rust.nix {
          inherit pkgs crane src;
        };

        ollamaModel = "qwen2.5:3b";
        ollamaModels = pkgs.ollama-models.override {
          models = [ollamaModel];
        };

        dockerImages = import ./nix/docker.nix {
          inherit pkgs ollamaModel ollamaModels;
          inherit (rust) chat-summary;
          inherit (rust) chat-summary-debug;
        };

        shellCommands = import ./nix/shell-commands.nix {
          inherit pkgs;
        };

        inherit (shellCommands) loadImages start start-debug stop logs logs-api logs-debug-api;

        ciPackages = with pkgs; [
          rustToolchain
          pkg-config
          openssl
          onnxruntime
          cargo-audit
          sccache
        ];

        shellEnv = {
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
          OPENSSL_NO_VENDOR = "1";
          ORT_SKIP_DOWNLOAD = "1";
          ORT_LIB_LOCATION = "${pkgs.onnxruntime}/lib";
          ORT_PREFER_DYNAMIC_LINK = "true";
          LD_LIBRARY_PATH = "${pkgs.onnxruntime}/lib";
        };
      in {
        packages = {
          default = rust.chat-summary;
          inherit (rust) chat-summary;
          inherit (rust) chat-summary-debug;
          inherit (dockerImages) docker;
          inherit (dockerImages) docker-debug;
          inherit (dockerImages) docker-ollama;
        };

        apps = {
          start = flake-utils.lib.mkApp {
            drv = start;
          };
          start-debug = flake-utils.lib.mkApp {
            drv = start-debug;
          };
          stop = flake-utils.lib.mkApp {
            drv = stop;
          };
          logs = flake-utils.lib.mkApp {
            drv = logs;
          };
          logs-api = flake-utils.lib.mkApp {
            drv = logs-api;
          };
          logs-debug-api = flake-utils.lib.mkApp {
            drv = logs-debug-api;
          };
        };

        checks = {
          inherit (rust) chat-summary chat-summary-debug;
        };

        devShells = {
          default = pkgs.mkShell {
            # `packages` puts commands on PATH for bash, zsh, fish, etc. (via direnv)
            packages =
              ciPackages
              ++ (with pkgs; [
                docker
                docker-compose
                ollama
                loadImages
                start
                start-debug
                stop
                logs
                logs-api
                logs-debug-api
              ]);

            env = shellEnv;
          };

          ci = pkgs.mkShell {
            packages = ciPackages;
            env = shellEnv;
          };
        };
      }
    );
}
