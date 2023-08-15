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
  version = "3.0.6";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "nglviewer";
    repo = "nglview";
    rev = "refs/tags/v${version}";
    hash = "sha256-2q3s34FdugkxNlXw2v3e3K0qvHTZrx/ings8iIGJkpk=";
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
    "test_get_port" # ModuleNotFoundError: No module named 'notebook.notebookapp'
  ];

  disabledTestPaths = [
    "nglview/tests/test_movie_maker.py" # imports pytraj
  ];
}
