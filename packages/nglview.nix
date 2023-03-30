{ ase
, buildPythonPackage
, fetchFromGitHub
, ipywidgets
, jupyter-packaging
, mock
, notebook
, numpy
, pytestCheckHook
, versioneer
}:

buildPythonPackage rec {
  pname = "nglview";
  version = "3.0.3";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "nglviewer";
    repo = "nglview";
    rev = "a529733626a7de3a82813aec48d741198ac5e509";
    hash = "sha256-XTLDU+P3ZTRY9hm91SvHTcgICo316g3zmN/DZMySVFA=";
  };

  nativeBuildInputs = [ versioneer ];

  propagatedBuildInputs = [
    ipywidgets
    jupyter-packaging
    numpy
  ];

  nativeCheckInputs = [
    ase
    mock
    notebook
    pytestCheckHook
  ];

  disabledTests = [
    # require simpletraj
    "test_API_promise_to_have"
    "test_handling_n_components_changed"
    "test_coordinates_dict"
    "test_load_data"
    "test_representations"
    "test_add_repr_shortcut"
    "test_remote_call"
    "test_download_image"
    "test_component_for_duck_typing"
    "test_trajectory_show_hide_sending_cooridnates"
    "test_add_struture_then_trajectory"
    "test_loaded_attribute"
    "test_player_simple"
    "test_player_link_to_ipywidgets"
    "test_player_interpolation"
    "test_interpolate"
    "test_write_html"

    "test_show_schrodinger" # requires parmed
    "test_nglview_show_module" # AssertionError: assert not 14
    "test_nglview_widget" # AssertionError: assert not 3
  ];

  disabledTestPaths = [
    "nglview/tests/test_movie_maker.py" # imports pytraj
  ];
}
