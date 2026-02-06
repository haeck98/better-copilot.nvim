local M = {}

-- array or region objects
M.region_register = {}

-- @class Region
-- @field bufnr integer
-- @field cancelled boolean: if true the user cancelled the request
-- @field finished boolean: if true the request is finished (either with success or error)
-- @field immediate_cleanup function[]: function that will be called immediately after the request is finished or cancelled, used for cleaning up any resources related to the region (e.g. status messages)
-- @field end_cleanup function[]: function that will be called after the request is finished or cancelled and the user has seen the result, used for cleaning up any resources related to the region (e.g. status messages)
local Region = {}

-- Namespace for all region extmarks
local REGION_NS = vim.api.nvim_create_namespace("better-copilot-region")

function Region.get_start_line(self)
   local pos = vim.api.nvim_buf_get_extmark_by_id(self.bufnr, REGION_NS, self.start_extmark, {})
   return pos and pos[1] and (pos[1] + 1) or nil
end

function Region.get_end_line(self)
   local pos = vim.api.nvim_buf_get_extmark_by_id(self.bufnr, REGION_NS, self.end_extmark, {})
   return pos and pos[1] and (pos[1] + 1) or nil
end

function Region.is_current_buffer(self)
   return vim.api.nvim_get_current_buf() == self.bufnr
end

function Region.add_immediate_cleanup(self, cleanup_fn)
   self.immediate_cleanup = self.immediate_cleanup or {}
   table.insert(self.immediate_cleanup, cleanup_fn)
end

function Region.add_end_cleanup(self, cleanup_fn)
   self.end_cleanup = self.end_cleanup or {}
   table.insert(self.end_cleanup, cleanup_fn)
end

function Region.run_immediate_cleanup(self)
   for _, cleanup_fn in ipairs(self.immediate_cleanup or {}) do
      cleanup_fn()
   end
end

function Region.run_end_cleanup(self)
   for _, cleanup_fn in ipairs(self.end_cleanup or {}) do
      cleanup_fn()
   end
end

function Region.cancel(self)
   self:run_immediate_cleanup()
   self.cancelled = true
end

function Region.is_cancelled(self)
   return self.cancelled == true
end

function get_index_of(tbl, item)
   for i, v in ipairs(tbl) do
      if v == item then
         return i
      end
   end
   return nil
end

function Region.finish(self)
   if not self:is_cancelled() then
      self:run_immediate_cleanup()
   end
   self:run_end_cleanup()

   if self.start_extmark then
      vim.api.nvim_buf_del_extmark(self.bufnr, REGION_NS, self.start_extmark)
   end
   if self.end_extmark then
      vim.api.nvim_buf_del_extmark(self.bufnr, REGION_NS, self.end_extmark)
   end

   table.remove(M.region_register, get_index_of(M.region_register, self))
   self.finished = true
end

function Region.is_finished(self)
   return self.finished == true
end

function Region.replace(self, new_text)
   if self.cancelled then
      return
   end

   local new_lines = vim.split(new_text, "\n")

   -- remove all lines from the start until a non empty line is found
   for i, line in ipairs(new_lines) do
      if line:match("%S") then
         break
      else
         table.remove(new_lines, i)
      end
   end

   -- and now from the end
   for i = #new_lines, 1, -1 do
      if new_lines[i]:match("%S") then
         break
      else
         table.remove(new_lines, i)
      end
   end

   local bufnr = self.bufnr
   local start_line = self:get_start_line()
   local end_line = self:get_end_line()

   vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, new_lines)

   vim.api.nvim_buf_call(bufnr, function()
      vim.cmd((start_line - 1) .. "," .. end_line .. "normal! ==")
   end)

   local new_start_line = start_line
   local new_end_line = start_line + #new_lines - 1

   self:set_extmarks(new_start_line, new_end_line)
end

function Region:set_extmarks(line_start, line_end)
   -- Remove old extmarks if they exist
   if self.start_extmark then
      vim.api.nvim_buf_del_extmark(self.bufnr, REGION_NS, self.start_extmark)
   end
   if self.end_extmark then
      vim.api.nvim_buf_del_extmark(self.bufnr, REGION_NS, self.end_extmark)
   end
   vim.print("Setting extmarks for region: " .. line_start .. " to " .. line_end)
   self.start_extmark = vim.api.nvim_buf_set_extmark(self.bufnr, REGION_NS, line_start - 1, 0, {})
   self.end_extmark = vim.api.nvim_buf_set_extmark(self.bufnr, REGION_NS, line_end - 1, 0, {})
end

function M.get_first_overlapping_region(bufnr, line_start, line_end)
   for _, region in ipairs(M.region_register) do
      if not region:is_finished() and not region:is_cancelled() and region.bufnr == bufnr then
         local region_start = region:get_start_line()
         local region_end = region:get_end_line()

         if not (line_end < region_start or line_start > region_end) then
            return region
         end
      end
   end

   return nil
end

function Region.new(bufnr, line_start, line_end, opts)
   if opts == nil then
      opts = {}
   end

   if M.get_first_overlapping_region(bufnr, line_start, line_end) then
      vim.notify("Better Copilot: Cannot create region with overlapping lines", vim.log.levels.ERROR)
      return nil
   end

   local self = setmetatable({bufnr = bufnr}, {__index = Region})
   if not opts.without_extmarks then
      self:set_extmarks(line_start, line_end)
   end

   table.insert(M.region_register, self)

   return self
end

function M.get_visual_selection()
   local bufnr = vim.api.nvim_get_current_buf()
   local start_line = vim.fn.line("'<")
   local end_line = vim.fn.line("'>")

   if start_line == 0 or end_line == 0 then
      local cur = vim.api.nvim_win_get_cursor(0)
      return bufnr, cur[1], cur[1]
   end

   if start_line > end_line then
      start_line, end_line = end_line, start_line
   end

   return bufnr, start_line, end_line
end

function M.get_region_at_visual_selection()
   local bufnr, start_line, end_line = M.get_visual_selection()

   return M.get_first_overlapping_region(bufnr, start_line, end_line)
end

function M.get_region_at_cursor()
   local bufnr = vim.api.nvim_get_current_buf()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local line = cursor_pos[1]

   return M.get_first_overlapping_region(bufnr, line, line)
end

function M.get_all_active_regions()
   local active_regions = {}

   for _, region in ipairs(M.region_register) do
      if not region:is_finished() and not region:is_cancelled() then
         table.insert(active_regions, region)
      end
   end

   return active_regions
end

function M.from_visual_selection()
   local bufnr, start_line, end_line = M.get_visual_selection()
   return Region.new(bufnr, start_line, end_line)
end

M.new = Region.new

return M

