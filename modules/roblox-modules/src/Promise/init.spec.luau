local Promise = require(script.Parent)

return function()
	describe("Constructor", function()
		it("should create a promise", function()
			expect(Promise.new(function() end)).to.be.ok()
		end)
	end)

	describe("Resolve", function()
		it("should resolve a promise", function()
			local promise = Promise.new(function(resolve)
				resolve("foo")
			end)

			local success, res: string = promise:await()

			expect(success).to.equal(true)
			expect(res).to.equal("foo")
		end)
	end)

	describe("Reject", function()
		it("should reject a promise", function()
			local promise = Promise.new(function(_, reject)
				reject("foo")
			end)

			local success, res: string = promise:await()

			expect(success).to.equal(false)
			expect(res).to.equal("foo")
		end)
	end)

	describe("Crash", function()
		it("should crash a promise", function()
			local promise = Promise.new(function()
				error("foo")
			end)

			local success: boolean = promise:await()

			expect(success).to.equal(false)
		end)
	end)

	describe("Then", function()
		it("should chain promises", function()
			local promise = Promise.new(function(resolve)
				resolve("foo")
			end)

			local promise2 = promise:andThen(function(res)
				expect(res).to.equal("foo")
			end)

			local success: boolean = promise2:await()

			expect(success).to.equal(true)
		end)
	end)

	describe("Catch", function()
		it("should catch a rejection", function()
			local promise = Promise.new(function(_, reject)
				reject("foo")
			end)

			local promise2 = promise:catch(function(res)
				expect(res).to.equal("foo")
			end)

			local success: boolean = promise2:await()

			expect(success).to.equal(false)
		end)
	end)

	describe("All", function()
		it("should resolve all promises", function()
			local promise1 = Promise.new(function(resolve)
				resolve("foo")
			end)

			local promise2 = Promise.new(function(resolve)
				resolve("bar")
			end)

			local promise3 = Promise.new(function(resolve)
				resolve("baz")
			end)

			local allPromise = Promise.all({ promise1, promise2, promise3 })

			local success: boolean, res: { string } = allPromise:await()

			expect(success).to.equal(true)
			expect(res).to.be.ok()
			expect(res[1]).to.equal("foo")
			expect(res[2]).to.equal("bar")
			expect(res[3]).to.equal("baz")
		end)

		it("should fail on the second promise", function()
			local promise1 = Promise.new(function(resolve)
				resolve("foo")
			end)

			local promise2 = Promise.new(function(_, reject)
				reject("bar")
			end)

			local promise3 = Promise.new(function(resolve)
				resolve("baz")
			end)

			local promise4 = Promise.all({ promise1, promise2, promise3 })

			local success, res: string = promise4:await()

			expect(success).to.equal(false)
			expect(res).to.equal("bar")
		end)
	end)
end
