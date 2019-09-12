local tea = require('tea')

describe("tea", function()
  it("getBackoffTime should ok", function()
    local time = tea.getBackoffTime({
      policy = "no"
    }, 1)
    assert.equal(0, time)
  end)

  it("allowRetry should ok", function()
    local allowed = tea.allowRetry({
      policy = "no"
    }, 0)
    assert.equal(true, allowed)

    allowed = tea.allowRetry({
      retryable = false
    }, 1)
    assert.equal(false, allowed)

    allowed = tea.allowRetry({
      retryable = true,
      maxAttempts = 3
    }, 1)
    assert.equal(true, allowed)

    allowed = tea.allowRetry({
      retryable = true,
      maxAttempts = 3
    }, 3)
    assert.equal(false, allowed)
  end)

  it("newError should ok", function()
    local err = tea.newError({
      code = "InvalidKey",
      message = "The key is invalid"
    })
    assert.equal("InvalidKey", err.code)
    assert.equal("The key is invalid", err.message)
    -- assert.equal("", err.stack)
  end)

  it("merge should ok", function()
    local obj = tea.merge({
      code = "InvalidKey",
      message = "The key is invalid"
    }, {})
    assert.are.same({
      code = "InvalidKey",
      message = "The key is invalid"
    }, obj)
  end)
end)