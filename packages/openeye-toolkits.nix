{ autoPatchelfHook
, buildPythonPackage
, cairo
, fetchurl
, pytest
, scripttest
, stdenv
, zlib
}:
let
  version = "2022.2.2";
  mkUrl = pname: "https://pypi.anaconda.org/openeye/simple/${pname}/${version}/${pname}-${version}.tar.gz";

  oe-toolkits-bin = buildPythonPackage rec {
    pname = "OpenEye-toolkits-python3-linux-x64";
    inherit version;

    src = fetchurl {
      url = mkUrl pname;
      sha256 = "sha256-WPtjRaQfGj/pHrPrT2L1SDNbNSnPtDvJGaYD/Uhcztk=";
    };

    nativeBuildInputs = [ autoPatchelfHook ];

    buildInputs = [ cairo stdenv.cc.cc zlib ];

    nativeCheckInputs = [ pytest scripttest ];

    pythonImportsCheck = [ "openeye" ];

    doCheck = false; # tests broken due to issue with runtime library dependencies
  };
in
buildPythonPackage rec {
  pname = "OpenEye-toolkits";
  inherit version;

  propagatedBuildInputs = [ oe-toolkits-bin ];

  src = fetchurl {
    url = mkUrl pname;
    sha256 = "sha256-VGQmSyMJNODuyNcHTgD+xnFI1ylLIHWa21viw67aPvA=";
  };
}
