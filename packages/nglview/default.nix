{ lib
, buildPythonPackage
, fetchFromGitHub
, ipywidgets
, jupyter-packaging_0_7
, jupyterlab-widgets
, notebook
, numpy
, setuptools
, versioneer
, wheel
}:

buildPythonPackage rec {
  pname = "nglview";
  version = "3.1.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "nglviewer";
    repo = "nglview";
    rev = "v${version}";
    hash = "sha256-VEhTzOMob8TAu0xoD6+ArqXxSSUbMRE+gCEiV/kIkww=";

    # work around hash instability due to use of export-subst
    postFetch = ''
      rm $out/nglview/_version.py
    '';
  };

  postPatch = ''
    substituteInPlace pyproject.toml --replace '"versioneer-518"' '"versioneer"'
  '';

  build-system = [
    jupyter-packaging_0_7
    setuptools
    versioneer
    wheel
  ];

  dependencies = [
    ipywidgets
    notebook
    jupyterlab-widgets
    numpy
  ];

  nativeCheckInputs = [
    ipywidgets
    numpy
  ];

  pythonImportsCheck = [ "nglview" ];

  meta = with lib; {
    description = "Jupyter widget to interactively view molecular structures and trajectories";
    homepage = "https://github.com/nglviewer/nglview";
    changelog = "https://github.com/nglviewer/nglview/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
