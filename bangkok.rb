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

  attr_reader :db, :schema, :order_by, :order_type, :limit, :content_url, :content_edit_url, :schema_url, :db_url, :to_s, :symbol
  attr_accessor :view

  def initialize(params)
    # db related
    @db = Sequel.connect(:adapter=>ADAPTER, :host=>HOST, :database=>params[:db], :user=>USER, :password=>PASSWORD)
    @symbol = params[:table].to_sym
    @schema = @db.schema(@symbol)

    # get params
    @limit = params[:l].to_i ? (params[:l] and !params[:l].empty?) : 10
    @order_by = params[:o]  ? params[:o] : nil
    @order_type = params[:ot] if !params[:ot].nil?

    # urls
    base_url = '/db/' + params[:db] + '/' + params[:table]
    @content_url = base_url + '/content'
    @content_edit_url = @content_url + '/edit/' #plus a pk
    @schema_url = base_url + '/schema'
    @db_url = '/db/' + params[:db]

    #is this appropriate? should i be using a method?
    @to_s = params[:table]
  end

  def pk
    @schema.each do |c|
      if c.last[:primary_key] == true
        return c.first.to_s
      end
    end
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
  @table.view = 'content'
  haml :table_content
end

get '/db/:db/:table/content/edit/:pk' do
  @table = Table.new(params)
  @object = @table.db[@table.symbol].filter(@table.pk.to_sym => params[:pk])
  haml :row_edit
end

post '/db/:db/:table/content/edit/:pk' do
  @table = Table.new(params)
  post = {}
  @table.schema.each do |s|
    post[s.first.to_s] = params[s.first.to_s]
  end
  @table.db[@table.symbol].filter(@table.pk.to_sym => params[:pk]).update(post)
  @object = @table.db[@table.symbol].filter(@table.pk.to_sym => params[:pk])
  haml :row_edit
end

get '/db/:db/:table/schema' do
  @table = Table.new(params)
  @table.view = 'schema'
  haml :table_schema
end
