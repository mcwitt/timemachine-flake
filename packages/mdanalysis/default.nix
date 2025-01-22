{ lib
, buildPythonPackage
, fetchFromGitHub
, cython
, numpy
, packaging
, setuptools
, wheel
, mmtf-python
, joblib
, scipy
, matplotlib
, mda-xdrlib
, tqdm
, threadpoolctl
, fasteners
, pytestCheckHook
, hypothesis
}:

let
  version = "2.7.0";

  src = fetchFromGitHub {
    owner = "MDAnalysis";
    repo = "mdanalysis";
    rev = "aaa4456db50e237cf580c8c986c00d7c5fbe3075";
    hash = "sha256-jgc4syq3j6e00qr5xUH1Dqjs1HQEvDN6zcRwD/D52zs=";
  };

  mdanalysis-notests = buildPythonPackage {
    pname = "mdanalysis";
    inherit version src;

    sourceRoot = "${src.name}/package";

    build-system = [
      cython
      packaging
      numpy
      setuptools
      wheel
    ];

    dependencies = [
      numpy
      # GridDataFormats
      mmtf-python
      joblib
      scipy
      matplotlib
      tqdm
      threadpoolctl
      fasteners
      mda-xdrlib
      # waterdynamics
      # pathsimanalysis
      # mdahole2
    ];


    env.NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";

    doCheck = false; # test suite has its own pyproject.toml

    pythonImportsCheck = [ "MDAnalysis" ];

    meta = with lib; {
      description = "MDAnalysis is a Python library to analyze molecular dynamics simulations";
      homepage = "https://github.com/MDAnalysis/mdanalysis";
      license = licenses.gpl3;
      maintainers = with maintainers; [ ];
      mainProgram = "mdanalysis";
      platforms = platforms.all;
    };
  };

  # TODO: test suite
  tests = buildPythonPackage {
    pname = "mdanalysis-testsuite";
    inherit version src;

    sourceRoot = "${src.name}/testsuite";

    nativeCheckInputs = [
      pytestCheckHook
      mdanalysis-notests
      hypothesis
    ];

    disabledTestPaths = [
      "MDAnalysisTests/analysis/test_density.py"
    ];
  };
in
# builtins.seq tests mdanalysis-notests
mdanalysis-notests
