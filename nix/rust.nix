{
  pkgs,
  crane,
  src,
}: let
  craneLib = (crane.mkLib pkgs).overrideToolchain (_: pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml);

  cargoSrc = pkgs.lib.cleanSourceWith {
    inherit src;
    filter = path: type:
      (craneLib.filterCargoSources path type)
      || builtins.elem (baseNameOf path) [
        ".env.sample"
        "index.html"
        "README.md"
        "SYSTEM_PROMPT.txt"
      ];
  };

  baseArgs = {
    src = cargoSrc;
    strictDeps = true;
    nativeBuildInputs = with pkgs; [pkg-config];
    buildInputs = with pkgs; [openssl onnxruntime];
    OPENSSL_NO_VENDOR = "1";
    ORT_SKIP_DOWNLOAD = "1";
    ORT_LIB_LOCATION = "${pkgs.onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "true";
    cargoExtraArgs = "--workspace";
  };

  cargoArtifacts = craneLib.buildDepsOnly baseArgs;

  chat-summary = craneLib.buildPackage (
    baseArgs
    // {
      inherit cargoArtifacts;
      doCheck = false;
    }
  );

  chat-summary-debug = craneLib.buildPackage (
    baseArgs
    // {
      inherit cargoArtifacts;
      cargoExtraArgs = "";
      cargoBuildCommand = "cargo build --workspace";
      doCheck = false;
    }
  );
in {
  inherit chat-summary chat-summary-debug;
}
