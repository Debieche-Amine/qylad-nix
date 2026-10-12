{
  lib,
  fetchurl,
  python3Packages,
}: let
  jupyter-mimetypes = python3Packages.buildPythonPackage rec {
    pname = "jupyter-mimetypes";
    version = "0.2.0";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/72/45/cb4671e13fed39f721066ad1a00714d4b607982b8d3e97a25f836198d1df/jupyter_mimetypes-0.2.0-py3-none-any.whl";
      hash = "sha256-5tzZiSWOP8lENltlbZFzGRUX4OOTvYeOl85QDls4hSc=";
    };

    dependencies = with python3Packages; [
      pyarrow
      typing-extensions
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;
  };

  jupyter-kernel-client = python3Packages.buildPythonPackage rec {
    pname = "jupyter-kernel-client";
    version = "0.9.0";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/7a/68/287315ba355aa93bda2e344de5febc45e6de1b47d8f4a5b69400b24cfdfd/jupyter_kernel_client-0.9.0-py3-none-any.whl";
      hash = "sha256-d6y48vc42XYl1r0B7ozyHE1ZeQt7pGQQhxLbOHBBbyA=";
    };

    dependencies = with python3Packages; [
      jupyter-client
      jupyter-core
      jupyter-mimetypes
      requests
      traitlets
      typing-extensions
      websocket-client
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;
  };
in
  python3Packages.buildPythonApplication rec {
    pname = "google-colab-cli";
    version = "0.7.4";
    format = "wheel";

    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/1c/b8/2621fba8c60c1c1c4cb8a13ad172e254d22bf3e8ceb80396668438e1d5ec/google_colab_cli-0.7.4-py3-none-any.whl";
      hash = "sha256-FDXzUzpwZPJ7i4ElLahTcEJ9bPk7lObDRze9HMaOwpI=";
    };

    dependencies = with python3Packages; [
      click
      filelock
      google-auth
      google-auth-oauthlib
      html2text
      jupyter-kernel-client
      nbformat
      packaging
      prompt-toolkit
      pydantic
      pygments
      requests
      rich
      typer
      typing-extensions
      websocket-client
    ];

    doCheck = false;
    dontCheckRuntimeDeps = true;

    meta = with lib; {
      description = "Command-line interface for Google Colab";
      homepage = "https://github.com/googlecolab/google-colab-cli";
      license = licenses.asl20;
      mainProgram = "colab";
      platforms = platforms.linux;
    };
  }
