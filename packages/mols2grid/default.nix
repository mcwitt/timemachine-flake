{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  jinja2,
  pandas,
  rdkit,
  setuptools,
  wheel,
}:

buildPythonPackage rec {
  pname = "mols2grid";
  version = "0.2.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "cbouy";
    repo = "mols2grid";
    rev = "v${version}";
    hash = "sha256-1vd2Lj952Dsr2JjlWYmAgyzKQT5Bl1sG7kxofFImUs8=";
  };

  build-system = [
    setuptools
    wheel
  ];

  nativeCheckInputs = [
    jinja2
    pandas
    rdkit
  ];

  pythonImportsCheck = [ "mols2grid" ];

  meta = with lib; {
    description = "Interactive molecule viewer for 2D structures";
    homepage = "https://github.com/cbouy/mols2grid";
    changelog = "https://github.com/cbouy/mols2grid/blob/${src.rev}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
  };
}
