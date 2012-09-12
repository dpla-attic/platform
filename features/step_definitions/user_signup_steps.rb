When /I sign in/ do
  visit('/')
  page.should have_content("DP.LA")
  click_link 'Sign Up'
end
