local M = {}

-- @class Request
-- @field prompt string

local BaseProvider = {}

-- @param request Request
function BaseProvider.run_prompt(self, request, opts)
   local cmd = self:create_cmd(request)
   self:run_cmd(cmd, opts)

end

function BaseProvider.run_cmd(_, cmd, opts)
   vim.system(cmd, {
      stdout = opts.stdout or true,
      stderr = opts.stderr or true,
   }, function (result)
      vim.schedule(function ()
         if result.code ~= 0 then
            opts.cb(nil, result.stderr)
         else
            opts.cb(result.stdout, nil)
         end
      end)
   end)
end

M.Opencode = setmetatable({}, {__index = BaseProvider})

-- @param request Request
function M.Opencode.create_cmd(self, request)
   return {"opencode", "run", "--model", "github-copilot/gpt-5-mini", "--agent", "build", request.prompt}
end

return M

