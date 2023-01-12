# timemachine-flake

[Nix][] [Flake](https://nixos.wiki/wiki/Flakes) for the
[timemachine][] molecular dynamics and free energy package.

## Quick start

*Note: only Linux is supported. For distributions other than NixOS, you
might need to prefix `nix` commands with [nixGL][] to run with the
correct NVIDIA driver.*

1. To enter an environment with timemachine development dependencies installed

   ```console
   nix develop github:mcwitt/timemachine-flake
   ```

1. To create a reproducible notebook using timemachine

    ```console
    mkdir my-project
    cd my-project
    nix flake init -t github:mcwitt/timemachine-flake#notebook
    ```

    Optionally edit `flake.nix` to configure, then enter the
    environment with

    ```console
    nix develop
    ```

1. To create a reproducible script using timemachine

    ```console
    mkdir my-project
    cd my-project
    nix flake init -t github:mcwitt/timemachine-flake#script
    ```

    Edit `flake.nix` to configure the environment and entry points.
    Then run (for example)

    ```console
    nix run .#rbfe
    ```

    to run the example RBFE script.

## Using as a  nixpkgs overlay

Example:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    timemachine-flake.url = "github:mcwitt/timemachine-flake";
  };

  outputs = { nixpkgs, timemachine-flake, ... }:
    let
      pkgs = import nixpkgs { overlays = [ timemachine-flake.overlay ]; };
      pythonEnv = pkgs.python3.withPackages (ps: [ ps.jaxlib ps.timemachine ]);
    in
    {
      # …
    };
}
```

[Nix]: https://nixos.org/
[timemachine]: https://github.com/proteneer/timemachine
[nixGL]: https://github.com/guibou/nixGL
