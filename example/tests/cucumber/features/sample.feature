Feature: Map display

  As an anonymous user
  I want to see the map when I navigate to the application
  So that I can analyze it

  # The background will be run for every scenario
  Background:
    Given I am a new user

  # This scenario will run as part of the Meteor dev cycle because it has the @dev tag
  @watch
  Scenario: Check that we see the correct entry page
    When I navigate to "/"
    Then I should see the title "FLIRT"

  @watch
  Scenario: Clicking on module a should give us some paths
    When I navigate to "/"
    And I click on #moduleA
    Then I should see 4 map markers
    And I should see paths between them

  @watch
  Scenario: Entering an airport code should give us some paths
    When I navigate to "/"
    And I search for JFK
    Then I should see some map markers
    And I should see paths between them

  @watch
  Scenario: Entering an airport code and date range should give us some paths
    When I navigate to "/"
    And I search for JFK
    And I click on #dateTab
    And I enter 12/9/2015 into the startDate
    Then I should see some map markers
    And I should see paths between them

  @watch
  Scenario: Entering an airport code, and a minimum seat count should give us some paths with flight having at least that many seats
    When I navigate to "/"
    And I search for JFK
    And I enter 50 and 850 into the seat filter
    Then I should see some map markers
