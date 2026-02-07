local M = {}

function M.fill_in_selection(ctx)
      return [[
The user selected code in their editor that you should edit/implement.
This is the filename: ]] .. ctx.filename .. [[
Here is the selected code:
]] .. ctx.selection_content .. [[
This is there request message:
]] .. ctx.user_message .. [[
Provide the updated code only, do not include any explanations or extra text.
Return only the updated code block.
The code you return will exactly replace the selected code in the user's editor.
All the lines the user selected will be exactly replaced with the code you return.
Please use the correct formatting and indentation, as you can see from the surrounding code.
Please use include indentation in the first line as well.
]]
end

return M
