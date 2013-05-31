Feature: User Authentication

    Scenario: un-successful DPLA authentication
      When I go to the homepage
      Then I should see "Sign In"
      But I should not see "Sign Out"
      When I follow "Sign In"
      And I fill in the following:
        | Email    | mrtestuser@somedomain.com |
        | Password | test                   |
      And I press "Sign in"
      Then I should see "Invalid email or password."

    Scenario: successful DPLA sign up
      When I go to the homepage
      Then I should see "Sign Up"
      But I should not see "Sign Out"
      When I follow "Sign Up"
      And I fill in the following:
        | Email    | mrtestuser1@somedomain.com |
        | Password | testpass                   |
        | Password confirmation | testpass      |
      And I press "Sign up"
      Then I should see "Sign Out"
   
    Scenario: successful DPLA authentication
      Given the following user exists:
        | email                    | password | password_confirmation |
        | mrtestuser@somedomain.com | testpass   | testpass                  |
      When I go to the homepage
      Then I should see "Sign In"
      But I should not see "Sign Out"
      When I follow "Sign In"
      And I log in with the following:
        | Email    | Password |
        | mrtestuser@somedomain.com | testpass                  |
      Then I should see "Sign Out" 
      But I should not see "Sign In" 
