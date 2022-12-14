{ addOpenGLRunpath
, black_21_12b0
, buildPythonPackage
, cmake
, cub
, cuda_cudart
, cuda_nvcc
, eigen
, flake8
, hilbertcurve
, hypothesis
, importlib-resources
, isort
, jax
, jaxlib
, lib
, libcurand
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
, src
, substituteAll
, thrust
}:

let
  timemachine = buildPythonPackage rec {
    pname = "timemachine";
    version = "0.1";

    inherit src;

    format = "pyproject";

    patches =
      let
        update-cmake-build = substituteAll {
          src = ./patches/update-cmake-build.patch;
          pythonVersion = lib.versions.majorMinor python.version;
        };
        hardcode-version = substituteAll {
          src = ./patches/hardcode-version.patch;
          commit = src.rev;
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
      cuda_nvcc
      mypy
      pybind11
      pytestCheckHook
      pythonRelaxDepsHook
    ];

    buildInputs = [
      cub
      cuda_cudart
      eigen
      jaxlib
      libcurand
      thrust
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

    CMAKE_ARGS = "-DCUDA_ARCH=61";

    # Allow extension module to find NVIDIA drivers on NixOS
    postFixup = ''
      addOpenGLRunpath $out/${python.sitePackages}/timemachine/lib/custom_ops$(${python}/bin/python-config --extension-suffix)
    '';

    checkInputs = timemachine.optional-dependencies.test ++ [ pytest-xdist ];

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

    pytestFlagsArray = [ "--hypothesis-profile=ci" "--numprocesses=auto" "-m" "nogpu" ];

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
  };
in
timemachine
