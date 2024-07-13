{  pkgs,  lib,  ...}:

{
  environment.systemPackages = with pkgs; [
    yq-go
    mutagen
    rustic-rs
    duckdb
    vscode-fhs

    nodejs
    (python3.withPackages(px: with px; [
        virtualenv
        httpx aiofile aiostream fastapi uvicorn
        debugpy pytest pydantic pyparsing
        ipython typer pydantic-settings pyyaml
        boltons decorator deepmerge
        structlog python-json-logger
        polars
    ]))

    gcc
    cmake

    wasmtime
    rustc
    rust-analyzer
    rust-script
    cargo
  ];

  programs.neovim = {
    defaultEditor = true;
    withPython3 = true;
    withNodeJs = true;
  };
}
