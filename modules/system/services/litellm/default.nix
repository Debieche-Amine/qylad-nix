{
  config,
  lib,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};
  litellmConfigFile = yamlFormat.generate "litellm-config.yaml" {
    model_list = [
      # =========================
      # GPT-5.5 (4-key chain)
      # =========================
      {
        model_name = "gpt-5.5";
        litellm_params = {
          model = "openai/gpt-5.5";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_1";
          reasoning_effort = "high";
        };
        model_info = {
          input_cost_per_token = 0.0; # Example: 1.75qt per 1M input tokens
          output_cost_per_token = 0.0000105; # Example: $10.50 per 1M output tokens
        };
      }
      {
        model_name = "gpt-5.5-lv2";
        litellm_params = {
          model = "openai/gpt-5.5";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_2";
          reasoning_effort = "high";
        };
      }
      {
        model_name = "gpt-5.5-lv3";
        litellm_params = {
          model = "openai/gpt-5.5";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_3";
          reasoning_effort = "high";
        };
      }
      {
        model_name = "gpt-5.5-lv4";
        litellm_params = {
          model = "openai/gpt-5.5";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_4";
          reasoning_effort = "high";
        };
      }
      {
        model_name = "gpt-5.5-lv5";
        litellm_params = {
          model = "openai/gpt-5.5";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_5";
          reasoning_effort = "high";
        };
      }
      {
        model_name = "gpt-5.5-lv6";
        litellm_params = {
          model = "openai/gpt-5.5";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_6";
          reasoning_effort = "high";
        };
      }

      # =========================
      # GPT-5.4 (4-key chain)
      # =========================
      {
        model_name = "gpt-5.4";
        litellm_params = {
          model = "openai/gpt-5.4";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_1";
        };
        model_info = {
          input_cost_per_token = 0.0; # 0.875qt per 1M input tokens
          output_cost_per_token = 0.00000525; # 5.25qt per 1M output tokens
        };
      }
      {
        model_name = "gpt-5.4-lv2";
        litellm_params = {
          model = "openai/gpt-5.4";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_2";
        };
      }
      {
        model_name = "gpt-5.4-lv3";
        litellm_params = {
          model = "openai/gpt-5.4";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_3";
        };
      }
      {
        model_name = "gpt-5.4-lv4";
        litellm_params = {
          model = "openai/gpt-5.4";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_4";
        };
      }
      {
        model_name = "gpt-5.4-lv5";
        litellm_params = {
          model = "openai/gpt-5.4";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_5";
        };
      }
      {
        model_name = "gpt-5.4-lv6";
        litellm_params = {
          model = "openai/gpt-5.4";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_6";
        };
      }

      # =========================
      # GPT-5.4-mini (4-key chain)
      # =========================
      {
        model_name = "gpt-5.4-mini";
        litellm_params = {
          model = "openai/gpt-5.4-mini";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_1";
        };
        model_info = {
          input_cost_per_token = 0.0;
          output_cost_per_token = 0.000001575; # 1.575qt per 1M output tokens
        };
      }
      {
        model_name = "gpt-5.4-mini-lv2";
        litellm_params = {
          model = "openai/gpt-5.4-mini";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_2";
        };
      }
      {
        model_name = "gpt-5.4-mini-lv3";
        litellm_params = {
          model = "openai/gpt-5.4-mini";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_3";
        };
      }
      {
        model_name = "gpt-5.4-mini-lv4";
        litellm_params = {
          model = "openai/gpt-5.4-mini";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_4";
        };
      }
      {
        model_name = "gpt-5.4-mini-lv5";
        litellm_params = {
          model = "openai/gpt-5.4-mini";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_5";
        };
      }
      {
        model_name = "gpt-5.4-mini-lv6";
        litellm_params = {
          model = "openai/gpt-5.4-mini";
          api_base = "os.environ/UPSTREAM_API_BASE";
          api_key = "os.environ/UPSTREAM_API_KEY_6";
        };
      }

      {
        model_name = "local-slow";
        litellm_params = {
          model = "ollama/llama3.1:8b";
        };
      }
      {
        model_name = "local-fast";
        litellm_params = {
          model = "ollama/llama3.2:3b";
        };
      }
      {
        model_name = "glm-5.2";
        litellm_params = {
          model = "nvidia_nim/z-ai/glm-5.2";
          api_key = "os.environ/NVIDIA_API_KEY";
        };
      }
      {
        model_name = "minimax-m2.7";
        litellm_params = {
          model = "nvidia_nim/minimaxai/minimax-m2.7";
          api_key = "os.environ/NVIDIA_API_KEY";
        };
      }
      {
        model_name = "llama-70b";
        litellm_params = {
          model = "nvidia_nim/meta/llama-3.3-70b-instruct";
          api_key = "os.environ/NVIDIA_API_KEY";
        };
      }
      {
        model_name = "qwen-coder";
        litellm_params = {
          model = "nvidia_nim/qwen/qwen-2.5-coder-32b-instruct";
          api_key = "os.environ/NVIDIA_API_KEY";
        };
      }
      {
        model_name = "deepseek-pro";
        litellm_params = {
          model = "nvidia_nim/deepseek-ai/deepseek-v4-pro";
          api_key = "os.environ/NVIDIA_API_KEY";
        };
      }
      {
        model_name = "llama-8b";
        litellm_params = {
          model = "nvidia_nim/meta/llama-3.1-8b-instruct";
          api_key = "os.environ/NVIDIA_API_KEY";
        };
      }
      {
        model_name = "mistral-nemo";
        litellm_params = {
          model = "nvidia_nim/mistralai/mistral-nemo-12b-instruct";
          api_key = "os.environ/NVIDIA_API_KEY";
        };
      }
    ];

    litellm_settings = {
      fallbacks = [
        {"gpt-5.5" = ["gpt-5.5-lv2" "gpt-5.5-lv3" "gpt-5.5-lv4" "gpt-5.5-lv5" "gpt-5.5-lv6"];}
        {"gpt-5.4" = ["gpt-5.4-lv2" "gpt-5.4-lv3" "gpt-5.4-lv4" "gpt-5.4-lv5" "gpt-5.4-lv6"];}
        {"gpt-5.4-mini" = ["gpt-5.4-mini-lv2" "gpt-5.4-mini-lv3" "gpt-5.4-mini-lv4" "gpt-5.4-mini-lv5" "gpt-5.4-mini-lv6"];}
      ];
      enable_responses_api = true;
      drop_params = true;
    };
  };
in {
  networking.firewall.allowedTCPPorts = [4000];

  virtualisation.oci-containers.containers = {
    litellm = {
      autoStart = true;
      image = "ghcr.io/berriai/litellm:main-stable";

      # Mount the generated Nix config into the container
      volumes = [
        "${litellmConfigFile}:/app/config.yaml"
      ];

      cmd = [
        "--config"
        "/app/config.yaml"
        "--port"
        "4000"
        "--host"
        "0.0.0.0"
      ];

      # environment = {
      #   "DATABASE_URL" = "postgresql://litellm@localhost:5432/litellm";
      # };

      environmentFiles = [
        "${config.secrets.dir}/litellm/env"
      ];

      extraOptions = [
        "--network=host"
      ];
    };
  };

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "litellm";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [
      "litellm"
    ];
  };
}
