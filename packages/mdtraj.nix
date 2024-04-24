# Adapted from
# https://github.com/mdtraj/mdtraj/blob/287770b9fc61d01efed2f76c4ce26124e98fedac/default.nix
# (removed upstream)
{ lib
, buildPythonPackage
, fetchFromGitHub
, fetchPypi
, setuptools
, cython_0
, numpy
, zlib
, pyparsing
, astunparse
, scipy
, networkx
, matplotlib
, scikitlearn
, pandas
, tables
, psutil
, gsd
, numpydoc
, nbformat
, nbconvert
, sphinx_rtd_theme
, sphinx
, pytestCheckHook
, buildDocs
, enableNativeVectorIntrinsics ? true
}:

let
  msmb-theme = buildPythonPackage rec {
    pname = "msmb_theme";
    version = "1.2.0";
    src = fetchPypi {
      inherit pname version;
      sha256 = "0b77yjk5q8kdp7bdlqlwi33hjirzp7bbblpqi4a2gy1an3ijzp4v";
    };
    propagatedBuildInputs = [
      numpydoc
      sphinx
      sphinx_rtd_theme
    ];
    # no tests
    doCheck = false;
  };

in
buildPythonPackage rec {
  pname = "mdtraj";
  version = "1.9.8";

  src = fetchFromGitHub {
    owner = "mdtraj";
    repo = "mdtraj";
    rev = "refs/tags/${version}";
    hash = "sha256-qw8kWrIPKhNtxoTtjmjdlzpZDMfrQASfPKzBZ3AnIm0=";
  };

  preBuild = lib.optionalString (!enableNativeVectorIntrinsics) ''
    export MDTRAJ_BUILD_DISABLE_INTRINSICS=1
  '';

  buildInputs = [
    setuptools
    cython_0
    numpy
    zlib
  ];

  propagatedBuildInputs = [
    pyparsing
    astunparse
    scipy
    networkx
  ];

  nativeCheckInputs = [
    pytestCheckHook

    matplotlib
    scikitlearn
    pandas
    tables
    psutil
    gsd
  ] ++ lib.optionals buildDocs [
    # for docs
    nbformat
    nbconvert
    sphinx
    msmb-theme
  ];

  disabledTests = [
    # These tests require network access
    "test_pdb_from_url"
    "test_1vii_url_and_gz"

    "test_example_notebook" # jupyter_client.kernelspec.NoSuchKernel: No such kernel named python3

    # ValueError: Invalid mode: rb
    "test_read"
    "test_read_start"
    "test_read_frame"
    "test_read_stride"
    "test_read_variable_top_error"
    "test_write"
    "test_write_frame"

    "test_superpose_refinds" # assert not True
  ];

  # 1. Ensure mdconvert is on the PATH and don't let us import from the src directory
  # 2. If compiling without native intrisics, which is a rare configuration mostly for ppc64le,
  #    don't run some tests that are slow.
  preCheck = ''
    export PATH=$out/bin:$PATH
    rm -rf mdtraj/

    if [ "$MDTRAJ_BUILD_DISABLE_INTRINSICS" = "1" ]; then
      rm tests/test_mdconvert.py tests/test_trajectory.py
    fi
  '';

  postInstall = lib.optionalString buildDocs ''
    mkdir -p $out/share/docs/root
    (cd docs && make html && cp -r _build/html $out/share/docs)
  '';
}
