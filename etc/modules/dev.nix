{  pkgs,  lib,  ...}:

{
  environment.systemPackages = with pkgs; [
    yq-go
    mutagen
    rustic-rs
    duckdb
    nodejs
    (python3.withPackages(ps: with ps; [
        httpx aiofile aiostream fastapi uvicorn
        debugpy pytest pydantic pyparsing
        ipython typer pydantic-settings pyyaml
        boltons decorator deepmerge
        structlog python-json-logger
        polars
    ]))

    gcc
    cmake

    vscode-fhs
  ];

  programs.neovim = {
    defaultEditor = true;
    withPython3 = true;
    withNodeJs = true;
  };
}
