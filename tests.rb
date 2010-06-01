require 'bangkok'
require 'rubygems'
require 'test/unit'
require 'rack/test'

set :environment, :test

class BangkokdbTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def text_db_list
    get '/db'
    assert last_response.ok?
  end
  
  def test_table_list
    get '/db/vurbmoto'
    assert last_response.ok?
  end

  def test_table_content
    get '/db/vurbmoto/articles_article/content'
    assert last_response.ok?
    assert last_response.body.include?("articles_article")
  end
  def test_table_schema
    get '/db/vurbmoto/articles_article/schema'
    assert last_response.ok?
    assert last_response.body.include?("articles_article")
  end

  def test_ordering
    get '/db/vurbmoto/articles_article/content', :o => 'title'
    assert last_response.ok?
  end
end
