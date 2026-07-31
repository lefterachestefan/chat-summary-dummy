{
  pkgs,
}: let
  loadImages = pkgs.writeShellScriptBin "chat-summary-load-images" ''
    set -euo pipefail

    state_dir=".direnv/chat-summary-images"
    mkdir -p "$state_dir"

    build_and_load() {
      local attribute="$1"
      local tag="$2"
      local output
      local state_file="$state_dir/$attribute"

      output="$(${pkgs.nix}/bin/nix build ".#$attribute" --no-link --print-out-paths)"

      if ${pkgs.docker}/bin/docker image inspect "$tag" >/dev/null 2>&1 \
        && [ -f "$state_file" ] \
        && [ "$(cat "$state_file")" = "$output" ]; then
        echo "Image $tag is up to date"
        return 0
      fi

      echo "Loading $tag from $output"
      ${pkgs.docker}/bin/docker load < "$output"
      printf '%s\n' "$output" > "$state_file"
    }

    build_and_load "docker" "chat-summary:release"
    build_and_load "docker-debug" "chat-summary:debug"
    build_and_load "docker-ollama" "chat-summary-ollama:latest"
  '';

  start = pkgs.writeShellScriptBin "start" ''
    set -euo pipefail
    profile="''${1:-release}"
    ${loadImages}/bin/chat-summary-load-images
    exec ${pkgs.docker}/bin/docker compose --profile "$profile" up -d
  '';

  stop = pkgs.writeShellScriptBin "stop" ''
    set -euo pipefail
    exec ${pkgs.docker}/bin/docker compose --profile "*" stop
  '';

  start-debug = pkgs.writeShellScriptBin "start-debug" ''
    exec ${start}/bin/start debug
  '';

  logs = pkgs.writeShellScriptBin "logs" ''
    set -euo pipefail

    docker="${pkgs.docker}/bin/docker"

    if [ "$#" -eq 0 ]; then
      exec "$docker" compose --profile "*" logs -f
    fi

    if [ "$1" = "api" ]; then
      shift
      exec "$docker" compose --profile release logs -f api "$@"
    fi

    if [ "$1" = "debug" ] && [ "''${2:-}" = "api" ]; then
      shift 2
      exec "$docker" compose --profile debug logs -f api-debug "$@"
    fi

    echo "usage: logs | logs api | logs debug api" >&2
    exit 1
  '';

  logs-api = pkgs.writeShellScriptBin "logs-api" ''
    exec ${logs}/bin/logs api "$@"
  '';

  logs-debug-api = pkgs.writeShellScriptBin "logs-debug-api" ''
    exec ${logs}/bin/logs debug api "$@"
  '';
in {
  inherit loadImages start start-debug stop logs logs-api logs-debug-api;
}
