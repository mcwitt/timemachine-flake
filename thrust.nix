{ fetchFromGitHub, stdenv }:

stdenv.mkDerivation rec {
  pname = "thrust";
  version = "1.17.2";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "thrust";
    rev = version;
    hash = "sha256-4Ph/QBDFOOwqQN/LKL8v1dWfDbRnW+nK1qmVbWuzfYk=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/include
    mv thrust/ $out/include/
  '';
}

