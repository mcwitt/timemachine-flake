{ buildPythonPackage
, jax
, jaxlib
, numexpr
, pymbar-src
}:

buildPythonPackage {
  name = "pymbar";
  src = pymbar-src;
  buildInputs = [ jaxlib ];
  propagatedBuildInputs = [ jax numexpr ];
  doCheck = false;
}
