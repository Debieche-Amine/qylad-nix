{
  pkgs,
  inputs,
  ...
}: {
  programs.nvf = {
    enable = true;
    enableManpages = true;

    settings = {
      vim = {
        undoFile.enable = true;

        options = {
          ignorecase = true;
          smartcase = true;
          wrap = true;
          foldmethod = "indent";
          foldlevel = 99;
          foldenable = true;

          cursorline = true;
        };
        theme = {
          enable = true;
          style = "warm"; #"dark", "darker", "cool", "deep", "warm", "warmer"
        };

        lineNumberMode = "relNumber";

        autocomplete.nvim-cmp.enable = true;
        statusline.lualine.enable = true;
        telescope = {
          enable = true;
          extensions = [
            {
              name = "fzf";
              packages = [pkgs.vimPlugins.telescope-fzf-native-nvim];
              setup = {fzf = {fuzzy = true;};};
            }
          ];
        };

        clipboard = {
          enable = true;
          registers = "unnamedplus";
        };

        binds = {
          whichKey = {
            enable = true;
          };
        };

        git = {
          enable = true;
          gitsigns = {
            enable = true;
            codeActions.enable = true;
          };
        };

        # Files are written as UTF-8, while the fallback list keeps older text
        # files readable.  Arabic input itself comes from the existing
        # fr/ara compositor keyboard layout.
        luaConfigRC.arabic = inputs.nvf.lib.nvim.dag.entryAfter ["basic"] ''
          vim.opt.encoding = "utf-8"
          vim.opt.fileencodings = { "utf-8", "ucs-bom", "latin1" }
          vim.opt.arabicshape = true
          vim.opt.termbidi = true

          -- Enable proper RTL cursor behaviour and Arabic letter shaping for the current buffer.
          -- Clears internal keymap so system Arabic keyboard layouts work seamlessly.
          local function enable_arabic()
            vim.opt_local.rightleft = true
            vim.opt_local.arabicshape = true
            vim.opt_local.keymap = ""
          end

          local function disable_arabic()
            vim.opt_local.rightleft = false
          end

          local function toggle_arabic()
            if vim.opt_local.rightleft:get() then
              disable_arabic()
            else
              enable_arabic()
            end
          end

          vim.api.nvim_create_user_command("ArabicMode", enable_arabic, { desc = "Enable Arabic RTL editing for this buffer" })
          vim.api.nvim_create_user_command("Arabic", enable_arabic, { desc = "Enable Arabic RTL editing for this buffer" })
          vim.api.nvim_create_user_command("RTL", enable_arabic, { desc = "Enable Arabic RTL editing for this buffer" })
          vim.api.nvim_create_user_command("LatinMode", disable_arabic, { desc = "Return this buffer to left-to-right editing" })
          vim.api.nvim_create_user_command("LTR", disable_arabic, { desc = "Return this buffer to left-to-right editing" })
          vim.api.nvim_create_user_command("ToggleArabic", toggle_arabic, { desc = "Toggle Arabic RTL editing for this buffer" })

          vim.keymap.set("n", "<leader>ar", enable_arabic, { desc = "Enable Arabic RTL mode" })
          vim.keymap.set("n", "<leader>al", disable_arabic, { desc = "Disable Arabic RTL mode (LTR)" })
          vim.keymap.set("n", "<leader>at", toggle_arabic, { desc = "Toggle Arabic RTL mode" })
        '';

        lsp = {
          enable = true;
          formatOnSave = true;
          # hover.enable = true;
          # harper-ls.enable = true;
          inlayHints.enable = true;
          lightbulb = {
            enable = true;
            autocmd.enable = true;
          };
          lspSignature.enable = true;
          # lspsaga.enable = true; # not seeing any deffirence
          # null-ls.enable = true; # idk what it do
        };

        languages = {
          enableDAP = true;
          # enableTreesitter = true;
          enableFormat = true;

          nix = {
            enable = true;
            # treesitter.enable = true;
            # treesitter.package = pkgs.vimPlugins.nvim-treesitter.grammarPlugins.nix;
          };
          rust = {
            enable = false;
            extensions.crates-nvim.enable = true;
            #   lsp.opts = ''
            #     ["rust-analyzer"] = {
            #       cargo = {
            #         allFeatures = true,
            #       },
            #       checkOnSave = false,
            #       procMacro = {
            #         enable = true,
            #       },
            #     }
            #   '';
            # };
          };
          python.enable = true;
          bash.enable = true;
          markdown.enable = true;

          clang.enable = true;
        };

        diagnostics = {
          enable = true;
          config = {
            enable = true;
            virtual_text = true;
            # virtual_lines = true;
            underline = true;
            signs = true;
            update_in_insert = false;
          };
        };
        # visuals = {
        #   blink-indent.enable = true;
        # };
      };
    };
  };
}
