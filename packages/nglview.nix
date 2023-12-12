{ lib
, buildPythonPackage
, fetchFromGitHub
, ipywidgets
, jupyter-packaging
, numpy
, setuptools
, versioneer
, wheel
}:

buildPythonPackage rec {
  pname = "nglview";
  version = "3.0.8";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "nglviewer";
    repo = "nglview";
    rev = "v${version}";
    hash = "sha256-woy0N2tLwRvqFC9njwrQ4LH+Xf61WcefClQmZ57SDzQ=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace '"versioneer-518"' '"versioneer"' \
      --replace '"jupyter_packaging~=0.7.9"' '"jupyter_packaging"'
  '';

  nativeBuildInputs = [
    jupyter-packaging
    setuptools
    versioneer
    wheel
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
