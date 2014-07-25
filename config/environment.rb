# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Dpla::Application.initialize!

# Imortant: delayed job requires some attributes to be accessible - make sure they are
Delayed::Job.attr_accessible :priority, :payload_object, :handler, :run_at, :failed_at, :queue
