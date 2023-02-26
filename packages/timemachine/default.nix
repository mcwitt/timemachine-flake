{ addOpenGLRunpath
, black_21_12b0
, buildPythonPackage
, cmake
, cudaPackages
, eigen
, fetchFromGitHub
, flake8
, hilbertcurve
, hypothesis
, importlib-resources
, isort
, jax
, jaxlib
, lib
, matplotlib
, mypy
, networkx
, numpy
, openeye-toolkits
, openmm
, pybind11
, pymbar
, pytest
, pytest-cov
, pytest-xdist
, pytestCheckHook
, python
, pythonRelaxDepsHook
, pyyaml
, rdkit
, scipy
, substituteAll
}:

buildPythonPackage rec {
  pname = "timemachine";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "proteneer";
    repo = "timemachine";
    rev = "acd9692b66e6fd6a8b3a85a719e31a3716f5584d";
    hash = "sha256-BFn/zPAITXVrJesna2Ozy3HRxtVnOHisx/zxH7JnMco=";

    # work around hash instability due to use of export-subst
    postFetch = ''
      rm $out/timemachine/_version.py
    '';
  };

  format = "pyproject";

  patches =
    let
      update-cmake-build = substituteAll {
        src = ./0001-Update-cmake-build-for-nix.patch;
        pythonVersion = lib.versions.majorMinor python.version;
      };
      hardcode-version = substituteAll {
        src = ./0002-Hardcode-version.patch;
        inherit (src) rev;
        inherit version;
      };
    in
    [
      update-cmake-build
      hardcode-version
    ];

  nativeBuildInputs = [
    addOpenGLRunpath
    cmake
    cudaPackages.cuda_nvcc
    mypy
    pybind11
    pythonRelaxDepsHook
  ];

  buildInputs = [
    cudaPackages.cub
    cudaPackages.cuda_cudart
    cudaPackages.libcurand
    cudaPackages.thrust
    eigen
    jaxlib
  ];

  propagatedBuildInputs = [
    importlib-resources
    jax
    matplotlib
    networkx
    numpy
    openeye-toolkits
    openmm
    pymbar
    pyyaml
    rdkit
    scipy
  ];

  # setuptools doesn't recognize nixpkgs rdkit because it's missing
  # a dist-info directory. Remove rdkit from the requirements to
  # allow installation to succeed
  pythonRemoveDeps = [ "rdkit" ];

  # CMake is invoked by the setuptools build
  dontUseCmakeConfigure = true;

  CMAKE_ARGS = [ "-DCUDA_ARCH=61" ];

  # ensure we use a supported compiler
  CUDAHOSTCXX = "${cudaPackages.cudatoolkit.cc}/bin/cc";

  # Allow extension module to find NVIDIA drivers on NixOS
  postFixup = ''
    addOpenGLRunpath $out/${python.sitePackages}/timemachine/lib/custom_ops$(${python}/bin/python-config --extension-suffix)
  '';

  nativeCheckInputs = passthru.optional-dependencies.test ++ [
    pytestCheckHook
    pytest-xdist
  ];

  disabledTestPaths = [
    "tests/test_handlers.py" # many tests require OpenEye license
  ];

  disabledTests = [
    "test_bootstrap_bar" # nondeterministic timeout

    # require OpenEye license
    "test_get_strained_atoms"
    "test_hif2a_set"
    "test_write_single_topology_frame"
    "test_jax_transform_intermediate_potential"
  ];

  pytestFlagsArray = [
    "--hypothesis-profile=ci"
    "--numprocesses=auto"
    "-m"
    "'nogpu and not nightly'"
  ];

  pythonImportsCheck = [ "timemachine" ];

  passthru.optional-dependencies.dev = [
    black_21_12b0
    flake8
    isort
    mypy
  ];

  passthru.optional-dependencies.test = [
    pytest
    pytest-cov
    hilbertcurve
    hypothesis
  ];

  meta = {
    description = "A high-performance differentiable molecular dynamics, docking and optimization engine";
    homepage = "https://github.com/proteneer/timemachine";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.mcwitt ];
  };
}
