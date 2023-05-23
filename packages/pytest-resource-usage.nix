{ buildPythonPackage
, fetchPypi
, flit-core
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "pytest-resource-usage";
  version = "1.0.0";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-OiAM7gB/w+dJb/NGILKEFJQ1bJIGOqb6eekgH9Hlg8w=";
  };

  propagatedBuildInputs = [
    flit-core
  ];

  nativeCheckInputs = [ pytestCheckHook ];
}
