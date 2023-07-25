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
, py3Dmol
, pybind11
, pymbar
, pytest
, pytest-cov
, pytest-xdist
, pytestCheckHook
, python
, pythonRelaxDepsHook
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
    rev = "af72d6b95e57d95b36bcfdc58a11b9307f8f97f8";
    hash = "sha256-JEach3Cr8QoWtDvxzjT4TqZpP9d+FUx++cPRA1KbA5Q=";

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

  buildInputs = lib.optionals enableCuda [
    cudaPackages.cub
    cudaPackages.cuda_cudart
    cudaPackages.libcurand
    cudaPackages.thrust
    eigen
  ];

  propagatedBuildInputs = [
    jax
    jaxlib
    matplotlib
    networkx
    numpy
    openeye-toolkits
    openmm
    pymbar
    rdkit
    scipy
  ];

  # setuptools doesn't recognize nixpkgs rdkit because it's missing
  # a dist-info directory. Remove rdkit from the requirements to
  # allow installation to succeed
  pythonRemoveDeps = [ "rdkit" ];

  # CMake is invoked by the setuptools build
  dontUseCmakeConfigure = true;

  CMAKE_ARGS = lib.optionals enableCuda [ "-DCUDA_ARCH=all-major" ];

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
    "tests/test_rmsd_align.py" # marked nogpu but requires custom_ops
  ];

  disabledTests = [
    # nondeterministic timeout
    "test_bootstrap_bar"

    # require OpenEye license
    "test_get_strained_atoms"
    "test_hif2a_set"
    "test_write_single_topology_frame"
    "test_jax_transform_intermediate_potential"

    # high resource usage
    "test_jax_nonbonded_waterbox"
    "test_batched_neighbor_inds"
    "test_interpret_as_mixture_potential"
    "test_mixture_reweighting_1d"
    "test_reference_langevin_integrator"
  ];

  pytestFlagsArray = [
    "--hypothesis-profile=no-deadline"
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
      py3Dmol
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
