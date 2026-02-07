local M = {}

local Window = {}

function Window.close(self)
   if vim.api.nvim_win_is_valid(self.win) then
      vim.api.nvim_win_close(self.win, true)
   end

   if vim.api.nvim_buf_is_valid(self.win) then
      vim.api.nvim_buf_delete(self.buf, {force = true})
   end
end

function Window.get_text(self)
   local lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)

   return table.concat(lines, "\n")
end

function create_window(opts)
   local buf = vim.api.nvim_create_buf(false, true)
   if buf == 0 then
      return nil
   end

   local win = vim.api.nvim_open_win(buf, true, {
      relative = 'cursor',
      row = 1,
      col = 0,
      anchor = "NW",
      width = 50,
      height = 8,
      style = "minimal",
      border = "rounded",
      title = opts.title,
   })

   return setmetatable({
      win = win,
      buf = buf,
   }, {__index = Window})
end

function M.input(opts)
   local win = create_window({
      title = opts.title,
   })

   if not win then
      vim.notify("can't create window")
      return
   end

   local end_input = function(cancelled)
      local response = nil

      if not cancelled then
         response = win:get_text()
         print(response)
      end

      opts.on_result(response)

      win:close()
   end

   vim.api.nvim_buf_set_keymap(win.buf, "n", "<CR>", "", {
      callback = function()
         end_input(false)
      end,
   })

   vim.api.nvim_buf_set_keymap(win.buf, "n", "q", "", {
      callback = function()
         end_input(true)
      end,
   })
end

return M
