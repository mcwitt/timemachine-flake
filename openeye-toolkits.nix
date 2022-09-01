{ buildPythonPackage, fetchurl }:
let
  version = "2020.2.0";
  mkUrl = pname: "https://pypi.anaconda.org/openeye/simple/${pname}/${version}/${pname}-${version}.tar.gz";

  subpackage =
    let pname = "OpenEye-toolkits-python3-linux-x64";
    in buildPythonPackage {
      inherit pname version;
      src = fetchurl {
        url = mkUrl pname;
        sha256 = "sha256-bz+i2rX8g/QVPR30fK1m8KRb/iXz9etCKVD9DO3bVnM=";
      };
      doCheck = false;
      pythonImportsCheck = [ "openeye" ];
    };

  pname = "OpenEye-toolkits";
in
buildPythonPackage {
  inherit pname version;
  propagatedBuildInputs = [ subpackage ];
  src = fetchurl {
    url = mkUrl pname;
    sha256 = "sha256-c7boNOV4oeJwJmQgsSoCN/tsSUcIruj97FzsFS/PRb8=";
  };
}
