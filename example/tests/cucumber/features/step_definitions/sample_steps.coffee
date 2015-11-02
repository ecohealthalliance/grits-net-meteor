do ->
  'use strict'
  _ = require('underscore')

  module.exports = ->
    url = require('url')

    @Given /^I am a new user$/, ->
      # no callbacks! DDP has been promisified so you can just return it
      @server.call 'reset'
      # this.ddp is a connection to the mirror

    @When /^I navigate to "([^"]*)"$/, (relativePath) ->
      # WebdriverIO supports Promises/A+ out the box, so you can return that too
      @client.url url.resolve(process.env.ROOT_URL, relativePath)
      # process.env.ROOT_URL always points to the mirror

    @Then /^I should see the title "([^"]*)"$/, (expectedTitle) ->
      # you can use chai-as-promised in step definitions also
      @client.waitForVisible('body *')
      title = @client.getTitle()
      expect(expectedTitle).toEqual(title)

    @When /^I click on module ([^"]*)$/, (module) ->
      @client.waitForExist('.a')
      @client.click('.a')

    @Then /^I should see ([^"]*) map markers$/, (numMarkers) ->
      @client.waitForVisible('.leaflet-marker-icon')
      elements = @client.elements('.leaflet-marker-icon')
      expect(elements.value.length).toEqual(parseInt(numMarkers, 10))

    @Then /^I should see paths between them$/, ->
      @client.waitForExist('path')
      elements = @client.elements('path')
      expect(elements.value.length).toBeGreaterThan(0)

    return

  return
