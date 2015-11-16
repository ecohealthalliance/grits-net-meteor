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
    Then I should see the title "example"

  @dev
  Scenario: Minimize the filter
    When I navigate to "/"
    And I click on toggleFilter

  @dev
  Scenario: Clicking on module a should give us some paths
    When I navigate to "/"
    And I click on toggleFilter
    And I click on module A
    Then I should see 4 map markers
    And I should see paths between them

  @watch
  Scenario: Clicking on module a should give us some paths
    When I navigate to "/"
    And I click on #toggleFilter
    And I click on #moduleA
    Then I should see 4 map markers
    And I should see paths between them
