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

          mols2grid = callPackage ./packages/mols2grid { };

          mypy_1_5 = pyFinal.mypy.overridePythonAttrs (old:
            let version = "1.5.1";
            in {
              inherit version;
              name = "${old.pname}-${version}";
              src = final.fetchFromGitHub {
                owner = "python";
                repo = "mypy";
                rev = "refs/tags/v${version}";
                hash = "sha256-qs+axm2+UWNuWzLW8CI4qBV7k7Ra8gBajid8mYKDsso=";
              };
              doCheck = false; # slow
            });

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
