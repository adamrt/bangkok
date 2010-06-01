require 'rubygems'
require 'sinatra'
require 'haml'
require 'sequel'
require 'mysql'


# Settings
HOST = 'localhost'
USER = 'root'
PASSWORD = ''
ADAPTER = 'mysql'
set :haml, {:format => :html5 }

# Classes
class Table

  attr_accessor :db, :content_url, :schema_url, :db_url, :view, :schema, :params, :order_by, :order_type, :limit

  def initialize(params)
    @db = Sequel.connect(:adapter=>ADAPTER, :host=>HOST, :database=>params[:db], :user=>USER, :password=>PASSWORD)
    @symbol = params[:table].to_sym
    @schema = @db.schema(@symbol)
    @params = params

    # urls
    @content_url = '/db/' + params[:db] + '/' + params[:table] + '/content'
    @schema_url = '/db/' + params[:db]+ '/' + params[:table] + '/schema'
    @db_url = '/db/' + params[:db].to_s


    if params[:l] and !params[:l].empty?
      @limit = params[:l].to_i
    else
      @limit = 10
    end

    if params[:o]
      @order_by = params[:o]
      @order_type = params[:ot] if !params[:ot].nil?
    else
      @order_by = nil
    end
  end

  def to_s
    params[:table]
  end

  def row_list
    qs = @db[@symbol].limit(@limit)
    if @order_by
      if @order_type == 'desc'
        qs = qs.reverse_order(@order_by.to_sym)
      else
        qs = qs.order(@order_by.to_sym)
      end
    end
    return qs
  end

end

# Routes
get '/css/style.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

get '/' do
  redirect '/db'
end

get '/db' do
  begin
    dbh = Mysql.real_connect("localhost", "root", "")
    @rows = dbh.query("SHOW DATABASES")
  ensure
    dbh.close if dbh
  end
  haml :db_list
end

get '/db/:db' do
  @db = Sequel.connect(:adapter=>ADAPTER, :host=>HOST, :database=>params[:db], :user=>USER, :password=>PASSWORD)
  haml :table_list
end

get '/db/:db/:table/content' do
  @table = Table.new(params)
  haml :table_content
end

get '/db/:db/:table/schema' do
  @table = Table.new(params)
  haml :table_schema
end
