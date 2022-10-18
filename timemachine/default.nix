{ lib
, python
, buildPythonPackage
, addOpenGLRunpath
, substituteAll

, cmake
, cudatoolkit
, eigen

, hilbertcurve
, importlib-resources
, jax
, jaxlib
, matplotlib
, mypy
, networkx
, numpy
, openeye-toolkits
, openmm
, pybind11
, pymbar
, pyyaml
, rdkit
, scipy

, hypothesis
, pytest

, timemachine-src
}:

let
  timemachine = buildPythonPackage rec {
    name = "timemachine";
    version = timemachine-src.rev or "dirty";
    src = timemachine-src;

    patches =
      let
        update-cmake-build = substituteAll {
          src = ./patches/update-cmake-build.patch;
          pythonVersion = lib.versions.majorMinor python.version;
        };
        hardcode-version = substituteAll {
          src = ./patches/hardcode-version.patch;
          inherit version;
        };
      in
      [
        update-cmake-build
        hardcode-version
      ];

    nativeBuildInputs = [ addOpenGLRunpath cmake mypy pybind11 ];

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

    dontUseCmakeConfigure = true;

    CMAKE_ARGS = "-DCUDA_ARCH=61";

    postFixup = ''
      find $out -type f \( -name '*.so' -or -name '*.so.*' \) | while read lib; do
        echo "setting opengl runpath for $lib"
        addOpenGLRunpath "$lib"
      done
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
          "tests/test_absolute_hydration.py"
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

    passthru.optional-dependencies.test = [ pytest hilbertcurve hypothesis ];

    meta = with lib; {
      description = "A high-performance differentiable molecular dynamics, docking and optimization engine";
      homepage = "https://github.com/proteneer/timemachine";
      license = licenses.asl20;
      maintainers = with maintainers; [ mcwitt ];
    };
  };
in
timemachine
