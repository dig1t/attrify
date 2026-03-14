local TableUtil = require(script.Parent.TableUtil)

return function()
	describe("Deep Merge", function()
		it("should deep merge", function(_context)
			local testCase = {
				stats = {
					level = 1,
					new = true,
				},
				player = "player1",
			}

			local testCase2 = {
				stats = {
					level = 5,
				},
				player = "player1",
			}

			-- This should only shallow merge
			-- local result = TableUtil.extend(testCase, testCase2)

			-- expect(result.stats.new).to.be.a("nil")

			-- This should deep merge
			local result2 = TableUtil.deepMerge(testCase, testCase2)

			expect(result2.stats.level).to.equal(5)
		end)

		it("should deep merge again", function(_context)
			local testCase = {
				foo = {
					bar = "baz",
					qux = "quux",
				},
				qux = "quux",
			}

			local testCase2 = {
				foo = {
					bar = "qux",
				},
				qux = "quux",
			}

			local result = TableUtil.deepMerge(testCase, testCase2)

			expect(result.foo.bar).to.equal("qux")
		end)
	end)

	describe("Extend", function()
		it("should shallow merge", function(_context)
			local testCase = {
				stats = {
					level = 1,
					new = true,
				},
				player = "player1",
			}

			local testCase2 = {
				stats = {
					level = 5,
				},
				player = "player1",
			}

			-- This should only shallow merge
			local result = TableUtil.extend(testCase, testCase2)

			expect(result.stats.new).to.be.a("nil")
		end)

		it("should not deep merge if the first argument is a table", function(_context)
			local testCase = {
				foo = {
					bar = "baz",
					qux = "quux",
				},
				qux = "quux",
			}

			local testCase2 = {
				foo = {
					bar = "qux",
				},
				qux = "quux",
			}

			local result = TableUtil.extend(testCase, testCase2)

			expect(result.foo.bar).to.equal("qux")
		end)
	end)

	describe("Waterfall", function()
		it("should waterfall", function(_context)
			local testCase = {
				function(callback: any)
					callback("foo")
				end,
				function(res: any, callback: any)
					callback(res .. "baz")
				end,
			}

			TableUtil.waterfall(testCase, function(_err, result: string)
				expect(result).to.equal("foobaz")
			end)
		end)

		it("should error", function(_context)
			local testCase = {
				function(callback: any)
					callback("foo")
				end,
				function(_callback)
					error("bar")
				end,
			}

			TableUtil.waterfall(testCase, function(err: string)
				expect(err).to.be.ok()
			end)
		end)
	end)
end
