final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (
      pyFinal: pyPrev:
      let
        inherit (pyFinal) callPackage;
      in
      {
        deeptime = callPackage ./packages/deeptime { };

        hilbertcurve = callPackage ./packages/hilbertcurve { };

        mda-xdrlib = callPackage ./packages/mda-xdrlib { };

        mdanalysis = callPackage ./packages/mdanalysis { };

        mols2grid = callPackage ./packages/mols2grid { };

        nglview = callPackage ./packages/nglview { };

        openeye-toolkits = callPackage ./packages/openeye-toolkits { };

        py3Dmol = callPackage ./packages/py3Dmol { };

        pymbar = callPackage ./packages/pymbar { };

        pymbar_3 = callPackage ./packages/pymbar/3 { };

        pytest-resource-usage = callPackage ./packages/pytest-resource-usage { };

        timemachine = callPackage ./packages/timemachine { cudaSupport = final.stdenv.isLinux; };
      }
    )
  ];
}
