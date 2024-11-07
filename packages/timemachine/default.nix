{ addDriverRunpath
, black_23
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
, mypy_1_5
, networkx
, numpy
, openeye-toolkits
, openmm
, psutil
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
, setuptools
, substituteAll
, versioneer
, enableCuda ? true
}:

buildPythonPackage rec {
  pname = "timemachine";
  version = "0+${builtins.substring 0 7 src.rev}";

  src = fetchFromGitHub {
    owner = "proteneer";
    repo = "timemachine";
    rev = "344f11caf98e7fc91204e695fb7d1cb7178eb041";
    hash = "sha256-3E5EK4DU7EeVaYrUVSmbNJbLBh0GMXu94GOAxWNoR3k=";

    # work around hash instability due to use of export-subst
    postFetch = ''
      rm $out/timemachine/_version.py
    '';
  };

  pyproject = true;

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
    ./0003-Fix-jax-config-import.patch
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace "cmake==3.24.3" "cmake" \
      --replace "setuptools >= 43.0.0, < 64.0.0" "setuptools" \
      --replace "versioneer-518" "versioneer"
  '';

  nativeBuildInputs = [
    pythonRelaxDepsHook
  ] ++ lib.optionals enableCuda [
    addDriverRunpath
    cmake
    cudaPackages.cuda_nvcc
    pybind11
  ];

  build-system = [
    mypy_1_5
    setuptools
    versioneer
  ];

  buildInputs = lib.optionals enableCuda [
    cudaPackages.cuda_cccl.dev
    cudaPackages.cuda_cudart
    cudaPackages.libcurand
    eigen
  ];

  dependencies = [
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
    addDriverRunpath $out/${python.sitePackages}/timemachine/lib/custom_ops$(${python}/bin/python-config --extension-suffix)
  '';

  nativeCheckInputs = passthru.optional-dependencies.test ++ [
    pytestCheckHook
    pytest-xdist
  ];

  # Ensure we run tests against the installed package and not the
  # build dir so that the compiled extension is available
  preCheck = ''
    rm -r timemachine
  '';

  disabledTestPaths = [
    "tests/test_handlers.py" # many tests require OpenEye license
  ];

  disabledTests = [
    # require OpenEye license
    "test_assert_potentials_compatible"
    "test_get_strained_atoms"
    "test_hif2a_set"
    "test_on_methane"
    "test_write_single_topology_frame"
    "test_jax_transform_intermediate_potential"
    "test_st_mol"

    # high resource usage
    "test_jax_nonbonded_waterbox"
    "test_batched_neighbor_inds"
    "test_interpret_as_mixture_potential"
    "test_mixture_reweighting_1d"
    "test_reference_langevin_integrator"
  ] ++ lib.optionals (!enableCuda) [
    "test_reversibility_with_jax_potentials"
    "test_rmsd_align_proper"
    "test_rmsd_align_improper"
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
      black_23
      flake8
      isort
      mypy_1_5
    ];

    test = [
      psutil
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
    maintainers = with lib.maintainers; [ mcwitt ];
  };
}
