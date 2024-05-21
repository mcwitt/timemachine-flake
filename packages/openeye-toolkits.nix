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
  version = "2020.2.2";

  mkUrl = pname: "https://pypi.anaconda.org/openeye/simple/${pname}/${version}/${pname}-${version}.tar.gz";

  packages = {
    x86_64-linux = rec {
      pname = "OpenEye-toolkits-python3-linux-x64";
      src = fetchurl {
        url = mkUrl pname;
        hash = "sha256-DYhwD59IRiyE5HIkNrkaqE9aUAWn8oqSrXq6fx/vcaI=";
      };
    };

    x86_64-darwin = rec {
      pname = "OpenEye-toolkits-python3-osx-x64";
      src = fetchurl {
        url = mkUrl pname;
        hash = "sha256-MqR4n3a4xVTfUkP1rUtkdkoPC/Lx+pM7eT3fJHZX9Oo=";
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

  dependencies = [ openeye-toolkits-bin ];

  src = fetchurl {
    url = mkUrl pname;
    hash = "sha256-zBytId8O1ChPfK0n68b3+/fs7wNI0k08YKKQODMjMOM=";
  };
}
