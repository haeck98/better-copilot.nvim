local M = {}

function M.fill_in_selection(ctx)
      return [[
The user selected code in their editor that you should edit/implement.
You are a deployed agent and your task is to take the selected code as
context, fullfill the request in the <UserMessage> and write the
updated code to <TempFile>
You should stay really close to the <UserMessage> and don't hallucinate.
The code you return should be scoped to the users selection,
meaning your are only allowed to work within the selection.
You should write the result to the <TempFile>. This file is used as a buffer,
and the selected text will later be replaced EXACTLY with the contents of <TempFile>.
The <TempFile> may contain content or not, but you can just overwrite it's content, it's
just a temporary buffer for your work.
<MustObey>
Your are only allowed to edit the <TempFile>. Your may read other files
but YOU CAN NEVER EDIT ANY OTHER FILE THEN <TempFile>.
Provide the updated code only, do not include any explanations or extra text in the <TempFile>.
Write only the updated code to the <TempFile>, don't wrap it in Markdown code blocks.
The code you write to <TempFile> will exactly replace the selected code in the user's editor.
All the lines the user selected will be exactly replaced with the code you return.
Please use the correct formatting and indentation as it's surrounding code.
</MustObey>
<Filename>]] .. ctx.filename .. [[</Filename>
<TempFile>]] .. ctx.tmp_file .. [[</TempFile>
<SelectedCode>]] .. ctx.selection_content .. [[</SelectedCode>
<UserMessage>]] .. ctx.user_message .. [[</UserMessage>
]]
end

return M
