# timemachine-flake

[Nix][] [Flake](https://nixos.wiki/wiki/Flakes) for the
[timemachine][] molecular dynamics and free energy package.

Supported platforms: Linux (x86_64), macOS (x86_64)

## Quick start

### Launch a Python session with timemachine

```console
nix run github:mcwitt/timemachine-flake
```

### Run a Python script using timemachine

```console
nix run github:mcwitt/timemachine-flake -- my_script.py
```


### Enter an environment with timemachine development dependencies

   ```console
   nix develop github:mcwitt/timemachine-flake#timemachine
   ```
   
## Templates for reproducible projects

### Create a reproducible notebook using timemachine

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

### Create a reproducible script using timemachine

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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    timemachine-flake.url = "github:mcwitt/timemachine-flake";
  };

  outputs = { nixpkgs, timemachine-flake, ... }:
    let
      pkgs = import nixpkgs { overlays = [ timemachine-flake.overlay ]; };
      pythonEnv = pkgs.python3.withPackages (ps: [ ps.timemachine ]);
    in
    {
      # …
    };
}
```

[Nix]: https://nixos.org/
[timemachine]: https://github.com/proteneer/timemachine
[nixGL]: https://github.com/guibou/nixGL
