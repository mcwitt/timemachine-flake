{ lib
, buildPythonPackage
, fetchPypi
, flit-core
, pytest
, psutil
}:

buildPythonPackage rec {
  pname = "pytest-resource-usage";
  version = "1.0.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-OiAM7gB/w+dJb/NGILKEFJQ1bJIGOqb6eekgH9Hlg8w=";
  };

  build-system = [
    flit-core
  ];

  dependencies = [
    pytest
  ];

  passthru.optional-dependencies = {
    report_uss = [
      psutil
    ];
  };

  pythonImportsCheck = [ "pytest_resource_usage" ];

  meta = with lib; {
    description = "Pytest plugin for reporting running time and peak memory usage";
    homepage = "https://pypi.org/project/pytest-resource-usage/";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
