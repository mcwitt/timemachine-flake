{ addOpenGLRunpath
, buildPythonPackage
, cmake
, cudatoolkit
, eigen
, hilbertcurve
, hypothesis
, importlib-resources
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
, python
, pyyaml
, pythonRelaxDepsHook
, rdkit
, scipy
, substituteAll
, timemachine-src
}:

let
  timemachine = buildPythonPackage rec {
    pname = "timemachine";
    version = "0.1";

    src = timemachine-src;

    format = "pyproject";

    patches =
      let
        update-cmake-build = substituteAll {
          src = ./patches/update-cmake-build.patch;
          pythonVersion = lib.versions.majorMinor python.version;
        };
        hardcode-version = substituteAll {
          src = ./patches/hardcode-version.patch;
          commit = timemachine-src.rev;
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
      mypy
      pybind11
      pythonRelaxDepsHook
    ];

    buildInputs = [ eigen jaxlib ];

    propagatedBuildInputs = [
      cudatoolkit
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

    checkInputs = timemachine.optional-dependencies.test;

    # Work around issue where Python loads stub module from the
    # build directory instead of the C extension
    preCheck = ''
      rm -r timemachine/lib
    '';

    checkPhase =
      let
        mkDisabledTestFiles = files: lib.concatStringsSep " " (map (f: "--ignore ${f}") files);
        mkDisabledTests = names: "-k '${lib.concatStringsSep " and " (map (n: "not ${n}") names)}'";

        disabledTestFiles = [
          # many tests in these files require an OpenEye license
          "tests/test_align.py"
          "tests/test_handlers.py"
        ];

        disabledTests = [
          # require OpenEye license
          "test_get_strained_atoms"
          "test_hif2a_set"
          "test_write_single_topology_frame"
          "test_jax_transform_intermediate_potential"
        ];
      in
      ''
        # validate disabledTestFiles
        for path in ${lib.concatStringsSep " " disabledTestFiles}; do
            if [ ! -e $path ]; then
                echo "Disabled tests path \"$path\" does not exist. Aborting"
                exit 1
            fi
        done

        pytest --hypothesis-profile ci -m nogpu \
            ${mkDisabledTestFiles disabledTestFiles} \
            ${mkDisabledTests disabledTests}
      '';

    pythonImportsCheck = [ "timemachine" ];

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
