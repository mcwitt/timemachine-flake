{ autoPatchelfHook
, buildPythonPackage
, cairo
, fetchurl
, lib
, pytest
, scripttest
, stdenv
, zlib
}:
let
  version = "2022.2.2";

  mkUrl = pname: "https://pypi.anaconda.org/openeye/simple/${pname}/${version}/${pname}-${version}.tar.gz";

  packages = {
    x86_64-linux = rec {
      pname = "OpenEye-toolkits-python3-linux-x64";
      src = fetchurl {
        url = mkUrl pname;
        hash = "sha256-WPtjRaQfGj/pHrPrT2L1SDNbNSnPtDvJGaYD/Uhcztk=";
      };
    };

    x86_64-darwin = rec {
      pname = "OpenEye-toolkits-python3-osx-universal";
      src = fetchurl {
        url = mkUrl pname;
        hash = "sha256-EnDRZqdQR/o8wW3hiUaqQQ7b+sdIgSGMIgWK7qAmyVY=";
      };
    };
  };

  openeye-toolkits-bin = buildPythonPackage {
    inherit (builtins.getAttr stdenv.system packages) pname src;
    inherit version;

    nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

    buildInputs = [ cairo stdenv.cc.cc zlib ];

    nativeCheckInputs = [ pytest scripttest ];

    pythonImportsCheck = [ "openeye" ];

    doCheck = false; # tests broken due to issue with runtime library dependencies
  };
in
buildPythonPackage rec {
  pname = "OpenEye-toolkits";
  inherit version;

  propagatedBuildInputs = [ openeye-toolkits-bin ];

  src = fetchurl {
    url = mkUrl pname;
    hash = "sha256-VGQmSyMJNODuyNcHTgD+xnFI1ylLIHWa21viw67aPvA=";
  };
}
