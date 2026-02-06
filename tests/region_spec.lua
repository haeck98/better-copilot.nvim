local reg = require "better-copilot.region"

local eq = assert.are.same

describe("region.Region", function()
    it("immediate cleanup called on finish()", function()
	local region = reg.new(1, 1, 5, {without_extmarks = true})
	local called = false

	region:add_immediate_cleanup(function()
	    called = true
	end)

	eq(false, called)

	region:finish()

	eq(true, called)
    end)
end)
