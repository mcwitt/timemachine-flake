{
  addDriverRunpath,
  buildPythonPackage,
  clang-tools,
  cmake,
  cudaPackages,
  eigen,
  fetchFromGitHub,
  hilbertcurve,
  hypothesis,
  jax,
  jaxlib,
  lib,
  matplotlib,
  mypy,
  networkx,
  numpy,
  openeye-toolkits,
  openmm,
  psutil,
  py3Dmol,
  pybind11,
  pymbar,
  pytest,
  pytest-cov,
  pytest-xdist,
  pytestCheckHook,
  python,
  rdkit,
  ruff,
  scipy,
  setuptools,
  substituteAll,
  cudaSupport ? true,
}:

buildPythonPackage rec {
  pname = "timemachine";
  version = "0.1.0+${builtins.substring 0 7 src.rev}";

  src = fetchFromGitHub {
    owner = "proteneer";
    repo = "timemachine";
    rev = "bed474f8b396e264903ac7ff623e7bf34f50a381";
    hash = "sha256-4Cr7alWLkPA/21sIPTP3XoPGy4a2ttqLzgZE5cVfVvk=";
  };

  pyproject = true;

  patches = [
    (substituteAll {
      src = ./0001-Adapt-cmake-build.patch;
      pythonVersion = lib.versions.majorMinor python.version;
    })
  ];

  postPatch = ''
    substituteInPlace pyproject.toml --replace-fail "cmake==3.24.3" "cmake"
  '';

  nativeBuildInputs = lib.optionals cudaSupport [
    addDriverRunpath
    cmake
    cudaPackages.cuda_nvcc
    pybind11
  ];

  build-system = [
    mypy
    setuptools
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

  disabledTests =
    [
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

      # flaky
      "test_hrex_gaussian_mixture"
    ]
    ++ lib.optionals (!cudaSupport) [
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
      clang-tools
      mypy
      ruff
    ];

    test = [
      psutil
      py3Dmol
      pytest
      pytest-cov
      pytest-xdist
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
