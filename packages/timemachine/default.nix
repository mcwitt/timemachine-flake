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
, enableCuda ? true
}:

buildPythonPackage rec {
  pname = "timemachine";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "proteneer";
    repo = "timemachine";
    rev = "34c5bfa927ac3be9332de6f6cd17cff4f231cc8f";
    hash = "sha256-UEOUDn+PZM92u9ylr0jjLF7zeGV8pCQHJ9c9ynxZ0UQ=";

    # work around hash instability due to use of export-subst
    postFetch = ''
      rm $out/timemachine/_version.py
    '';
  };

  format = "pyproject";

  patches = [
    (substituteAll {
      src = ./0001-Remove-versioneer.patch;
      inherit (src) rev;
      inherit version;
    })
    (substituteAll {
      src = ./0002-Adapt-cmake-build.patch;
      pythonVersion = lib.versions.majorMinor python.version;
    })
  ];

  nativeBuildInputs = [
    mypy
    pythonRelaxDepsHook
  ] ++ lib.optionals enableCuda [
    addOpenGLRunpath
    cmake
    cudaPackages.cuda_nvcc
    pybind11
  ];

  buildInputs = [
    jaxlib
  ] ++ lib.optionals enableCuda [
    cudaPackages.cub
    cudaPackages.cuda_cudart
    cudaPackages.libcurand
    cudaPackages.thrust
    eigen
  ];

  propagatedBuildInputs = [
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

  CMAKE_ARGS = lib.optionals enableCuda [ "-DCUDA_ARCH=61" ];

  # ensure we use a supported compiler
  CUDAHOSTCXX = lib.optionalString enableCuda "${cudaPackages.cudatoolkit.cc}/bin/cc";

  # allow extension module to find NVIDIA drivers on NixOS
  postFixup = lib.optionalString enableCuda ''
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

  passthru.optional-dependencies = {
    dev = [
      black_21_12b0
      flake8
      isort
      mypy
    ];

    test = [
      pytest
      pytest-cov
      hilbertcurve
      hypothesis
    ];
  };

  meta = {
    description = "A high-performance differentiable molecular dynamics, docking and optimization engine";
    homepage = "https://github.com/proteneer/timemachine";
    changelog = "https://github.com/proteneer/timemachine/releases/tag/${version}";
    license = lib.licenses.asl20;
    maintainers = [ lib.maintainers.mcwitt ];
  };
}
