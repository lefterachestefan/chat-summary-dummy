{
  pkgs,
  chat-summary,
  chat-summary-debug,
  ollamaModels,
  ollamaModel ? "qwen2.5:3b",
}: let
  mkApiImage = {
    name,
    tag,
    package,
  }:
    pkgs.dockerTools.buildLayeredImage {
      inherit name tag;
      contents = with pkgs; [cacert openssl onnxruntime package];
      config = {
        Cmd = ["${package}/bin/chat-summary"];
        Env = [
          "API_PORT=8080"
          "WEBSOCKET_PORT=3000"
        ];
        ExposedPorts = {
          "8080" = {};
          "3000" = {};
        };
      };
    };

  ollamaEntrypoint = pkgs.writeShellScriptBin "ollama-entrypoint" ''
    export OLLAMA_MODELS="${ollamaModels}"
    export OLLAMA_HOST="''${OLLAMA_HOST:-0.0.0.0:11434}"
    exec ${pkgs.ollama}/bin/ollama serve
  '';
in {
  docker = mkApiImage {
    name = "chat-summary";
    tag = "release";
    package = chat-summary;
  };

  docker-debug = mkApiImage {
    name = "chat-summary";
    tag = "debug";
    package = chat-summary-debug;
  };

  docker-ollama = pkgs.dockerTools.buildLayeredImage {
    name = "chat-summary-ollama";
    tag = "latest";
    contents = with pkgs; [cacert ollama ollamaEntrypoint ollamaModels];
    config = {
      Cmd = ["${ollamaEntrypoint}/bin/ollama-entrypoint"];
      Env = [
        "OLLAMA_MODELS=${ollamaModels}"
        "OLLAMA_HOST=0.0.0.0:11434"
        "OLLAMA_MODEL=${ollamaModel}"
      ];
      ExposedPorts = {
        "11434" = {};
      };
    };
  };
}
