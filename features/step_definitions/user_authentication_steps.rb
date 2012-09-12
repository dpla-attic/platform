When /^I go to the homepage$/ do
    visit("/")
end

Then /^I should see "(.*?)"$/ do |arg1|
    page.should have_content("DP.LA")
end

Then /^I should not see "(.*?)"$/ do |arg1|
    page.should_not have_content(arg1)
end


When /^I follow "(.*?)"$/ do |arg1|
    click_link arg1
    page.should have_content "Email"
end



When /^I fill in the following:$/ do |table|
    fill_in "Email", :with => "mrtestuser@somedomain.com"
    fill_in "Password", :with => "testpass"
end

When /^I press "(.*?)"$/ do |arg1|

    click_on "Sign in"
    page.should_not have_content "Sign Out"
    
end


Given /^the following user exists:$/ do |table|
    table.hashes.each do |attributes|
        lambda{ User.create!(attributes)}.should change(User, :count).by(1)
    end
end

When /^I log in with the following:$/ do |table|
    visit "/"
    click_link "Log In"
    table.hashes.each do |hash|
        fill_in "Email", :with => hash["Email"]
        fill_in "Password", :with => hash["Password"]
    end
    click_button "Sign in"
end

Then /^I should see "(.*?)" link$/ do |arg1|
    page.should have_content arg1
end

Then /^I should not see "(.*?)" link$/ do |arg1|
    page.should_not have_content arg1
end
