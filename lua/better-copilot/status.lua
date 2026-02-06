local M = {}

local namespaceId = nil

local getNamespaceId = function()
   if not namespaceId then
      namespaceId = vim.api.nvim_create_namespace("BetterCopilot")
   end
   return namespaceId
end

local InlineStatus = {}

function InlineStatus.display(self, message)
   self:destroy_extmark()

   local extMarkId = vim.api.nvim_buf_set_extmark(
      self.region.bufnr,
      namespaceId,
      self.region:get_start_line() - 1,
      0,
      {
         virt_lines = {
            {
               {message, "Comment"},
            },
         },
      }
   )

   self.extMarkId = extMarkId
end

function InlineStatus.display_spinner(self, message)
   local timer = vim.loop.new_timer()

   local spinner_frames = {'⣷','⣯','⣟','⡿','⢿','⣻','⣽','⣾'}
   local frame_index = 1

   timer:start(0, 200, vim.schedule_wrap(function()
      local frame = spinner_frames[frame_index]
      self:display(frame .. " " .. message)

      frame_index = frame_index + 1
      if frame_index > #spinner_frames then
         frame_index = 1
      end
   end))

   self.spinner_timer = timer
end

function InlineStatus.destroy_extmark(self)
   if self.extMarkId then
      vim.api.nvim_buf_del_extmark(self.region.bufnr, self.namespaceId, self.extMarkId)
      self.extMarkId = nil
   end
end

function InlineStatus.destroy(self)
   if self.spinner_timer then
      self.spinner_timer:stop()
      self.spinner_timer:close()
      self.spinner_timer = nil
   end

   vim.schedule(function()
      self:destroy_extmark()
   end)
end

function M.new_inline(region)
   return setmetatable({
      region = region,
      namespaceId = getNamespaceId(),
      extMarkId = nil,
   }, {__index = InlineStatus})
end

return M
