local reg = require "better-copilot.region"

local eq = assert.are.same
local neq = assert.are_not.same

local function feed(keys)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, false, true),
    "x",
    false
  )
end

function select_visual(buf, start_line, end_line, reverse)
    vim.api.nvim_set_current_buf(buf)
    feed("<Esc><Esc>:" .. start_line .. "<CR>V" .. (end_line - start_line) .. "j")
    if reverse then
	feed("o")
    end
end

describe("region.cleanup", function()
    it("should call immediate cleanup on finish()", function()
	local region = reg.new(1, 1, 5, {without_extmarks = true})
	local called = 0

	region:add_immediate_cleanup(function()
	    called = called + 1
	end)

	eq(0, called)

	region:finish()

	eq(1, called)
    end)

    it("should call immediate cleanup on cancel()", function()
	local region = reg.new(1, 1, 5, {without_extmarks = true})
	local called = 0

	region:add_immediate_cleanup(function()
	    called = called + 1
	end)

	eq(0, called)

	region:cancel()
	eq(1, called)

	region:finish()
	eq(1, called)
    end)

    it("should call end cleanup on finish()", function()
	local region = reg.new(1, 1, 5, {without_extmarks = true})
	local called = 0

	region:add_end_cleanup(function()
	    called = called + 1
	end)

	eq(0, called)

	region:cancel()
	eq(0, called)

	region:finish()
	eq(1, called)
    end)
end)

describe("region.extmarks", function()
    local buf = 0

    before_each(function()
	-- create a scratch buffer
	buf = vim.api.nvim_create_buf(false, true)
	assert(buf ~= 0)

	-- put text into the buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
	    "line 1",
	    "line 2",
	    "line 3",
	    "line 4",
	    "line 5",
	    "line 6",
	    "line 7",
	    "line 8",
	})

	reg.region_register = {}
    end)

    after_each(function()
	while #reg.region_register > 0 do
	    reg.region_register[1]:finish()
	end

	if vim.api.nvim_buf_is_valid(buf) then
	    vim.api.nvim_buf_delete(buf, { force = true })
	end

	feed("<Esc><Esc>")
    end)

    it("should store state", function ()
	local region = reg.new(buf, 1, 3)

	eq(1, region:get_start_line())
	eq(3, region:get_end_line())
	eq({"line 1", "line 2", "line 3"}, region:get_lines())
	eq("line 1\nline 2\nline 3", region:get_text())
    end)

    it("should update state after replace", function()
	local region = reg.new(buf, 1, 3)

	eq({"line 1", "line 2", "line 3"}, region:get_lines())

	region:replace("test")

	eq(1, region:get_start_line())
	eq(1, region:get_end_line())
	eq("test", region:get_text())
    end)

    it("can trim replace text", function()
	local region = reg.new(buf, 1, 3)

	local replace_text = "\n\n\n\ntest\n\n\n\n"
	local replace_text_trim = "test"

	region:replace(replace_text)
	eq(1, region:get_start_line())
	eq(9, region:get_end_line())
	eq(replace_text, region:get_text())

	region:replace(replace_text, {trim = true})
	eq(1, region:get_start_line())
	eq(1, region:get_end_line())
	eq(replace_text_trim, region:get_text())
    end)

    it("can't create overlapping regions", function()
	local region1 = reg.new(buf, 1, 3)

	neq(nil, region1)

	local region2 = reg.new(buf, 2, 2)
	eq(nil, region2)
    end)

    it("can create from visual selection", function()
	vim.api.nvim_set_current_buf(buf)

	select_visual(buf, 2, 4)

	local region = reg.from_visual_selection()

	eq(2, region:get_start_line())
	eq(4, region:get_end_line())
    end)

    it("can create from visual selection (reverse)", function()
	vim.api.nvim_set_current_buf(buf)

	select_visual(buf, 2, 4, reverse)

	local region = reg.from_visual_selection()

	eq(2, region:get_start_line())
	eq(4, region:get_end_line())
    end)

    it("can get region at cursor", function()
	vim.api.nvim_set_current_buf(buf)

	local region = reg.new(buf, 3, 5)

	vim.fn.setpos('.',{buf,2,1})

	local region_at_cursor = reg.get_region_at_cursor()
	eq(nil, region_at_cursor)

	vim.fn.setpos('.',{buf,4,1})

	region_at_cursor = reg.get_region_at_cursor()
	eq(region, region_at_cursor)
    end)

    it("can get region at visual selection", function()
	local region = reg.new(buf, 3, 5)

	select_visual(buf, 1, 2)

	local region_at_cursor = reg.get_region_at_visual_selection()
	eq(nil, region_at_cursor)

	select_visual(buf, 1, 3)
	region_at_cursor = reg.get_region_at_visual_selection()
	eq(region, region_at_cursor)

	select_visual(buf, 4, 5)
	region_at_cursor = reg.get_region_at_visual_selection()
	eq(region, region_at_cursor)

	select_visual(buf, 5, 7)
	region_at_cursor = reg.get_region_at_visual_selection()
	eq(region, region_at_cursor)

	select_visual(buf, 6, 7)
	region_at_cursor = reg.get_region_at_visual_selection()
	eq(nil, region_at_cursor)
    end)
end)


describe("nvim", function()
    local buf = 0

    before_each(function()
	-- create a scratch buffer
	buf = vim.api.nvim_create_buf(false, true)
	assert(buf ~= 0)
    end)

    it("should set correct buf", function()
	
    end)
end)
