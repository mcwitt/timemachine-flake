{ fetchFromGitHub, stdenv }:

stdenv.mkDerivation rec {
  pname = "cub";
  version = "1.17.2";

  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "cub";
    rev = version;
    hash = "sha256-4xzC8yBgq6IW+w1d4KbQ16XzmjDCI9blJWIpT3WOqgI=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/include
    mv cub/ $out/include/
  '';
}

