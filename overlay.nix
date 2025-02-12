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

          mda-xdrlib = callPackage ./packages/mda-xdrlib { };

          mdanalysis = callPackage ./packages/mdanalysis { };

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
