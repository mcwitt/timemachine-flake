{ buildPythonPackage
, fetchPypi
, jinja2
, pandas
, rdkit
}:

buildPythonPackage rec {
  pname = "mols2grid";
  version = "0.2.4";
  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-Rnd3nuch7N6Frbk3MEuEEc9CRklsSKUmRMhiKd2x/y4=";
  };
  buildInputs = [ jinja2 pandas rdkit ];
  doCheck = false;
  pythonImportsCheck = [ "mols2grid" ];
}
