require 'bundler/setup'
require 'sinatra'
Sinatra::Application.environment = :test
Bundler.require :default, Sinatra::Application.environment
require 'rspec'
# require 'machinist'
# require 'machinist/mongoid'
require File.join(File.dirname(__FILE__), "..", "app")

RSpec.configure do |config|

end
