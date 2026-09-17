{
  config,
  lib,
  pkgs,
  ...
}: {
  services.litellm = {
    enable = true;
    environmentFile = "${config.secrets.dir}/litellm/env";
    host = "0.0.0.0";
    port = 4000;
    openFirewall = true;
    settings = {
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
          {
            "gpt-5.5" = [
              "gpt-5.5-lv2"
              "gpt-5.5-lv3"
              "gpt-5.5-lv4"
            ];
          }

          {
            "gpt-5.4" = [
              "gpt-5.4-lv2"
              "gpt-5.4-lv3"
              "gpt-5.4-lv4"
            ];
          }

          {
            "gpt-5.4-mini" = [
              "gpt-5.4-mini-lv2"
              "gpt-5.4-mini-lv3"
              "gpt-5.4-mini-lv4"
            ];
          }
        ];
        enable_responses_api = true;
        drop_params = true;
      };
    };
  };
}
