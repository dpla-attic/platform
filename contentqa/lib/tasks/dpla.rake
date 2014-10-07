namespace :contentqa do 
    desc "Delete generated report files"
    task :delete_reports do
        FileUtils.rm_rf(Dir['tmp/qa_reports/[^.]*'])
    end
end