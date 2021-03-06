require 'test_helper'
require "active_support/log_subscriber/test_helper"

class LogSubscriberTest < Test::Unit::TestCase
  include ActiveSupport::LogSubscriber::TestHelper

  def setup
    super
    @page = { :page => { :id => 1, :title => 'Haravan API' } }.to_json
    @ua_header = "\"User-Agent\"=>\"HaravanAPI/#{HaravanAPI::VERSION} ActiveResource/#{ActiveResource::VERSION::STRING} Ruby/#{RUBY_VERSION}\""

    HaravanAPI::Base.clear_session
    HaravanAPI::Base.site = "https://this-is-my-test-shop.myharavan.com/admin"

    ActiveResource::LogSubscriber.attach_to :active_resource
    ActiveResource::DetailedLogSubscriber.attach_to :active_resource_detailed
  end

  def set_logger(logger)
    ActiveResource::Base.logger = logger
  end

  test "logging on #find" do
    fake "pages/1", :method => :get, :body => @page

    HaravanAPI::Page.find(1)

    assert_equal 4, @logger.logged(:info).size
    assert_equal "GET https://this-is-my-test-shop.myharavan.com:443/admin/pages/1.json", @logger.logged(:info)[0]
    assert_match /\-\-\> 200/, @logger.logged(:info)[1]
    assert_equal "Headers: {\"Accept\"=>\"application/json\", #{@ua_header}}", @logger.logged(:info)[2]
    assert_match /Response:\n\{\"page\"\:\{((\"id\"\:1)|(\"title\"\:\"Haravan API\")),((\"id\"\:1)|(\"title\"\:\"Haravan API\"))\}\}/,  @logger.logged(:info)[3]

  end

  test "logging on #find with an error" do
    fake "pages/2", :method => :get, :body => nil, :status => 404

    assert_raise ActiveResource::ResourceNotFound do
      HaravanAPI::Page.find(2)
    end

    assert_equal 4, @logger.logged(:info).size
    assert_equal "GET https://this-is-my-test-shop.myharavan.com:443/admin/pages/2.json", @logger.logged(:info)[0]
    assert_match /\-\-\> 404/, @logger.logged(:info)[1]
    assert_equal "Headers: {\"Accept\"=>\"application/json\", #{@ua_header}}", @logger.logged(:info)[2]
    assert_equal "Response:", @logger.logged(:info)[3]
  end
end
