{ buildPythonPackage
, jinja2
, pandas
, mols2grid-src
, rdkit
}:

buildPythonPackage {
  name = "mols2grid";
  src = mols2grid-src;
  buildInputs = [ jinja2 pandas rdkit ];
  doCheck = false;
}
