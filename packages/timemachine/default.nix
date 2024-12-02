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
, cudaSupport ? true
}:

buildPythonPackage rec {
  pname = "timemachine";
  version = "0+${builtins.substring 0 7 src.rev}";

  src = fetchFromGitHub {
    owner = "proteneer";
    repo = "timemachine";
    rev = "49a13585ae8b76ec521df4242d8c13ce1c62ad2d";
    hash = "sha256-NPcVR1LYJ7YMjDR+9bVV5bfzpcER6SHEk+RxGGylmuA=";

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
  ] ++ lib.optionals cudaSupport [
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

  buildInputs = lib.optionals cudaSupport [
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

  CMAKE_ARGS = lib.optionals cudaSupport [ "-DCUDA_ARCH=all-major" ];

  # ensure we use a supported compiler
  CUDAHOSTCXX = lib.optionalString cudaSupport "${cudaPackages.cudatoolkit.cc}/bin/cc";

  # allow extension module to find NVIDIA drivers on NixOS
  postFixup = lib.optionalString cudaSupport ''
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
    "tests/test_interpolate.py" # usage of resources.path incompatible with 3.12
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
  ] ++ lib.optionals (!cudaSupport) [
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
