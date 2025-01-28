{ inputs }:
final:
prev:
let
  overridePython3 = python3: python3.override (old: {
    packageOverrides = final.lib.composeExtensions (old.packageOverrides or (_: _: { }))
      (pyFinal: pyPrev:
        let inherit (pyFinal) callPackage; in {

          deeptime = callPackage ./packages/deeptime { };

          hilbertcurve = callPackage ./packages/hilbertcurve { };

          jupyter-packaging_0_7 = pyPrev.jupyter-packaging.overridePythonAttrs (old:
            let version = "0.7.9"; in {
              inherit version;
              name = "jupyter-packaging-${version}";

              src = final.fetchPypi {
                pname = "jupyter-packaging";
                inherit version;
                hash = "sha256-Le11cjNy5c7S4b4e6FUGyIiVUYiS8g6sw7OjRM9Zzjo=";
              };

              patches = [ ];
            });

          mda-xdrlib = callPackage ./packages/mda-xdrlib { };

          mdanalysis = callPackage ./packages/mdanalysis { };

          mdtraj =
            let
              # TODO: remove when https://github.com/NixOS/nixpkgs/pull/377454 merged
              nixpkgs = final.fetchFromGitHub {
                owner = "mcwitt";
                repo = "nixpkgs";
                rev = "753c00280353005f9d856d4509535f29f9980aea";
                hash = "sha256-3c0Tlblfhr2NQA3Yy99tMn8KmtOAbdznCHaiqphWJZ0=";
              };
            in
            pyFinal.callPackage "${nixpkgs}/pkgs/development/python-modules/mdtraj" { };

          mols2grid = callPackage ./packages/mols2grid { };

          nglview = callPackage ./packages/nglview { };

          openeye-toolkits = callPackage ./packages/openeye-toolkits { };

          py3Dmol = callPackage ./packages/py3Dmol { };

          pymbar = callPackage ./packages/pymbar { };

          pytest-resource-usage = callPackage ./packages/pytest-resource-usage { };

          timemachine = callPackage ./packages/timemachine { cudaSupport = final.stdenv.isLinux; };
        });
  });
in
{
  python311 = overridePython3 prev.python311;
  python312 = overridePython3 prev.python312;
}
