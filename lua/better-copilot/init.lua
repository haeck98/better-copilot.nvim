local Region = require "better-copilot/region"
local providers = require "better-copilot/providers"
local prompts = require "better-copilot/prompts"
local Status = require "better-copilot/status"
local input = require "better-copilot.input"

local M = {} -- M stands for module, a naming convention

function M.setup()
   vim.api.nvim_create_user_command("BetterCopilot", function (opts)
      if opts.args[1] == "fill-in" then
         M.fill_in_selection()
      elseif opts.args[1] == "cancel" then
         M.cancel()
      else
         vim.notify("Better Copilot: Unknown command. Available commands: fill-in", vim.log.levels.ERROR)
      end
   end, {nargs = "*", range = true})
end

function user_is_in_visual_mode()
   local mode = vim.fn.mode()
   return mode == "v" or mode == "V" or mode == "\22"
end

function user_is_in_normal_mode()
   local mode = vim.fn.mode()
   return mode == "n"
end

function M.cancel()
   local current_region = nil
   if user_is_in_visual_mode() then
      current_region = Region.get_region_at_visual_selection()
   elseif user_is_in_normal_mode() then
      current_region = Region.get_region_at_cursor()
   end

   if current_region then
      current_region:cancel()
      vim.notify("Better Copilot: Cancelled region in " .. current_region:get_filename(), vim.log.levels.INFO)
      return
   end

   local regions = Region.get_all_active_regions()
   if #regions == 0 then
      vim.notify("Better Copilot: No active regions to cancel", vim.log.levels.INFO)
      return
   end

   local inputlistOptions = {}
   for i, region in ipairs(regions) do
      table.insert(inputlistOptions, string.format("%d. %s (in %s:%d-%d)", i, region.message or "No message", region:get_filename(), region:get_start_line(), region:get_end_line()))
   end

   local choice = vim.fn.inputlist({"Better Copilot: Select a region to cancel:", unpack(inputlistOptions)})

   if choice < 1 or choice > #regions then
      return
   end

   local regionToCancel = regions[choice]

   regionToCancel:cancel()
end

function M.fill_in_selection()
   -- check if in visual selection mode
   if not user_is_in_visual_mode() then
      vim.notify("Better Copilot: Please select a region in visual mode to fill in", vim.log.levels.INFO)
      return
   end

   -- create marks at the start line and end line, so user can continue editing around the selected region
   local region = Region.from_visual_selection()

   if not region then
      return
   end

   input.input({
      title = "Describe your idea",
      on_result = function(message)
         region.message = message

         if not message or message == "" then
            region:finish()
            return
         end

         local prompt = prompts.fill_in_selection({
            user_message = message,
            filename = region:get_filename(),
            selection_content = region:get_text(),
         })

         -- TODO: select provider dynamically
         local provider = providers.Opencode;

         local status = Status.new_inline(region, "");
         status:set_spinner("Generating code...");
         status:set_max_lines(3);

         region:add_immediate_cleanup(function ()
            status:destroy()
         end)

         local stdout = ""

         -- call opencode using cli
         provider:run_prompt({prompt = prompt}, {
            stdout = function(err, data)
               if data == nil then
                  data = ""
               end

               stdout = stdout .. data

               vim.schedule(function()
                  status:set_text(stdout)
               end)
            end,
            cb = function (result, error)
               if result == nil or string.len(result) <= 0 then
                  result = stdout
               end

               if region:is_cancelled() then
                  region:finish()
                  return
               end

               if error then
                  vim.notify("Better Copilot Error: " .. error, vim.log.levels.ERROR)
               elseif result == nil or string.len(result) <= 0 then
                  vim.notify("Better Copilot Error: empty result", vim.log.levels.ERROR)
               else
                  -- replace selected text with output
                  region:replace(result)

                  -- if not current buffer, notify user
                  if not region:is_current_buffer() then
                     vim.notify("Better Copilot: Updated code in " .. region:get_filename())
                  end
               end

               region:finish()
            end
         })
      end
   })
end

local DEV = true

if DEV == true then

   vim.keymap.set("n", "<leader>x", function()
      -- Unload all better-copilot modules
      for k in pairs(package.loaded) do
         if k:match("^better%-copilot") then
            package.loaded[k] = nil
         end
      end

      vim.cmd("luafile %")
      vim.notify("reloaded")
   end, { noremap = true, silent = true })

   M.setup()

   vim.keymap.set({"n", "v"}, "<leader>bx", function ()
      M.cancel()
   end, { noremap = true, silent = true })

   vim.keymap.set({"n", "v"}, "<leader>bc", function ()
      M.fill_in_selection()
   end, { noremap = true, silent = true })

   function fibonacci(n)
   end

end

return M
