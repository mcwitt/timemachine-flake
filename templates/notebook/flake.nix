{
  description = "timemachine notebook environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.timemachine-flake.url = "github:mcwitt/timemachine-flake";
  inputs.timemachine-flake.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixgl.url = "github:nix-community/nixGL";
  inputs.pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  inputs.pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    { self
    , nixpkgs
    , timemachine-flake
    , nixgl
    , pre-commit-hooks
    }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      getPkgs = system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true; # needed for openmm on non-Linux
          };
          overlays = [
            nixgl.overlays.default
            timemachine-flake.overlays.default
          ];
        };
    in
    {
      packages = forAllSystems (system:
        let pkgs = getPkgs system;
        in rec {
          default = python;

          python = pkgs.python312.withPackages (
            ps: with ps; [
              altair
              deeptime
              ipywidgets
              jupytext
              matplotlib
              mdtraj
              mols2grid
              nglview
              notebook
              pandas
              py3Dmol
              seaborn
              timemachine
              tqdm
            ]
          );
        });

      devShells = forAllSystems (system:
        let pkgs = getPkgs system;
        in {
          default =
            let
              impure = builtins ? currentSystem;
              useNixgl = impure && pkgs.stdenv.isLinux;
            in
            pkgs.mkShell {
              packages = [
                self.packages.${system}.python
              ]
              ++ self.checks.${system}.pre-commit-check.enabledPackages
              ++ nixpkgs.lib.optional useNixgl pkgs.nixgl.auto.nixGLDefault;

              # prepend nixGL library paths in impure mode
              shellHook = self.checks.${system}.pre-commit-check.shellHook + nixpkgs.lib.optionalString useNixgl ''
                export LD_LIBRARY_PATH=$(${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH
              '';
            };
        });


      checks = forAllSystems (system:
        let pkgs = getPkgs system;
        in {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;

              jupytext = {
                enable = true;
                name = "jupytext";
                description = "Runs jupytext on all notebooks and paired files.";
                language = "python";
                entry = ''
                  ${pkgs.python3Packages.jupytext}/bin/jupytext \
                    --pre-commit-mode \
                    --sync \
                    --pipe "bash -c 'ruff --fix $@ | ruff-format' --"
                '';
                require_serial = true;
                types_or = [ "jupyter" ];
              };

              check-nbconvert-html = {
                enable = true;
                name = "check-nbconvert-html";
                description = "Check that all ipynb files can be converted to html using nbconvert.";
                language = "python";
                entry = "${pkgs.python3Packages.nbconvert}/bin/jupyter-nbconvert --to html --stdout";
                require_serial = true;
                types_or = [ "jupyter" ];
              };

              ruff.enable = true;
            };
          };
        });
    };
}
