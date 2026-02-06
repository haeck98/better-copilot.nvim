local M = {}

-- @class Request
-- @field prompt string

local BaseProvider = {}

-- @param request Request
function BaseProvider.run_prompt(self, request, cb)
   local cmd = self:create_cmd(request)
   self:run_cmd(cmd, function(response, error)
      -- TODO: maybe do something with response?
      cb(response, error)
   end)

end

function BaseProvider.run_cmd(_, cmd, cb)
   vim.system(cmd, {
      stdout = true,
      stderr = true,
   }, function (result)
      vim.schedule(function ()
         if result.code ~= 0 then
            cb(nil, result.stderr)
         else
            cb(result.stdout, nil)
         end
      end)
   end)
end

M.Opencode = setmetatable({}, {__index = BaseProvider})

-- @param request Request
function M.Opencode.create_cmd(self, request)
   return {"opencode", "run", "--model", "github-copilot/gpt-5-mini", request.prompt}
end

return M

