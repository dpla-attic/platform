When /^I go to the homepage$/ do
    visit("/")
end

Then /^I should see "(.*?)"$/ do |arg1|
    expect(page).to have_content("DP.LA")
end

Then /^I should not see "(.*?)"$/ do |arg1|
   expect(page).not_to have_content(arg1)
end


When /^I follow "(.*?)"$/ do |arg1|
    click_link arg1
    expect(page).to have_content "Email"
end



When /^I fill in the following:$/ do |table|
  table.hashes.each do |hash|
    fill_in "Email", :with => hash["Email"]
    fill_in "Password", :with => hash["Password"]
  end
end

When /^I press "(.*?)"$/ do |arg1|

    click_on "Sign in"
    
end


Given /^the following user exists:$/ do |table|
    table.hashes.each do |attributes|
      expect { User.create!(attributes)}.to change(User, :count).by(1)
    end
end

When /^I log in with the following:$/ do |table|
    visit "/"
    click_link "Sign In"
    table.hashes.each do |hash|
        fill_in "Email", :with => hash["Email"]
        fill_in "Password", :with => hash["Password"]
    end
    click_button "Sign in"
end

