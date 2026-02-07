local M = {}

local namespaceId = nil

local getNamespaceId = function()
   if not namespaceId then
      namespaceId = vim.api.nvim_create_namespace("BetterCopilot")
   end
   return namespaceId
end

local InlineStatus = {}

function InlineStatus.update_display(self)
   self:destroy_extmark()

   local virt_lines = {}

   if self.spinner_timer then
      table.insert(virt_lines, {{self.spinner_frame .. " " .. self.spinner_title, "Comment"}})
   end

   if self.text ~= nil and string.len(self.text) > 0 then
      local lines = vim.split(self.text, "\n")

      for i, line in ipairs(lines) do
         table.insert(virt_lines, {{line, "Comment"}})
      end
   end

   local extMarkId = vim.api.nvim_buf_set_extmark(
      self.region.bufnr,
      namespaceId,
      self.region:get_start_line() - 1,
      0,
      {
         end_row = self.region:get_end_line(),
         end_col = 0,
         hl_group = "Visual",
         virt_lines = virt_lines,
         virt_lines_above = true,
      }
   )

   self.extMarkId = extMarkId
end

function InlineStatus.set_spinner(self, title)
   self.spinner_title = title

   if self.spinner_timer then
      self:update_display()
   else
      local timer = vim.loop.new_timer()

      local spinner_frames = {'⣷','⣯','⣟','⡿','⢿','⣻','⣽','⣾'}
      local frame_index = 1

      timer:start(0, 200, vim.schedule_wrap(function()
         self.spinner_frame = spinner_frames[frame_index]

         self:update_display()

         frame_index = frame_index + 1
         if frame_index > #spinner_frames then
            frame_index = 1
         end
      end))

      self.spinner_timer = timer
   end
end

function InlineStatus.set_text(self, text)
   self.text = text
   self:update_display()
end

function InlineStatus.destroy_extmark(self)
   if self.extMarkId then
      vim.api.nvim_buf_del_extmark(self.region.bufnr, self.namespaceId, self.extMarkId)
      self.extMarkId = nil
   end
end

function InlineStatus.destroy_timer(self)
   self.spinner_frame = nil
   self.spinner_title = nil
   if self.spinner_timer then
      self.spinner_timer:stop()
      self.spinner_timer:close()
      self.spinner_timer = nil
   end
end

function InlineStatus.destroy(self)
   self:destroy_timer()

   vim.schedule(function()
      self:destroy_extmark()
   end)
end

function M.new_inline(region, text)
   local status = setmetatable({
      region = region,
      namespaceId = getNamespaceId(),
      extMarkId = nil,
      text = text,
   }, {__index = InlineStatus})

   status:update_display()

   return status
end

-- local reg = require "better-copilot.region"
--
-- local buf = vim.api.nvim_get_current_buf()
-- local region = reg.new(buf, 80, 84, true)
--
-- if region then
--    local status = M.new_inline(region)
--    status:display_spinner({"test", "test", "test"})
--
--    vim.defer_fn(function()
--       status:display_spinner({"new"})
--    end, 2000)
--
--    vim.defer_fn(function()
--       status:destroy()
--       region:finish()
--    end, 5000)
-- end

return M
