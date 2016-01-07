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
      @client.url process.env.ROOT_URL
      # process.env.ROOT_URL always points to the mirror

    @When /^I should see the title "([^"]*)"$/, (expectedTitle) ->
      # you can use chai-as-promised in step definitions also
      @client.waitForVisible('body *')
      title = @client.getTitle()
      expect(title).toEqual(expectedTitle)

    @When /^I search for ([^"]*)$/, (airportCode) ->
      @client.waitForVisible('#departureSearchMain-tokenfield')
      @client.addValue('#departureSearchMain-tokenfield', airportCode)
      @client.keys('Enter')

    @When /^I search for ([^"]*)$/, (airportCode) ->
      @client.waitForVisible('#departureSearchMain-tokenfield')
      @client.addValue('#departureSearchMain-tokenfield', airportCode)
      @client.keys('Enter')

    @When /^I enter ([^"]*) into the seat filter$/, (seats) ->
      @client.waitForVisible('#seatsInput')
      @client.addValue('#seatsInput', seats)

    @When /^I enter ([^"]*) into the startDate$/, (startDate) ->
      @client.waitForVisible('#discontinuedDate')
      @client.addValue('#discontinuedDate .form-control', startDate)

    @When /^I click on module ([^"]*)$/, (module) ->
      @client.waitForVisible('#moduleA').click('#moduleA')

    @When /^I click on ([^"]*)$/, (id) ->
      @client.waitForVisible id
      @client.click id

    @Then /^I should see ([^"]*) map markers$/, (numMarkers) ->
      @client.waitForVisible('.marker-icon')
      elements = @client.elements('.marker-icon')
      expect(elements.value.length).toEqual(parseInt(numMarkers, 10))

    @Then /^I should see some map markers$/, ->
      @client.waitForVisible('.marker-icon', 10000)
      elements = @client.elements('.marker-icon')
      expect(elements.value.length > 0).toEqual(true)

    @Then /^I should see paths between them$/, ->
      @client.waitForExist('path')
      elements = @client.elements('path')
      expect(elements.value.length).toBeGreaterThan(0)

    @Then /^true$/, ->
      expect(true).toEqual(true)
    return
  return
