require 'rubygems'
require 'sinatra'
require 'haml'
require 'sequel'
require 'mysql'

Sequel.extension :pagination

# Settings
HOST = 'localhost'
USER = 'root'
PASSWORD = ''
ADAPTER = 'mysql'
set :haml, {:format => :html5 }

# Classes
class Table

  attr_reader :db, :symbol, :schema, :url, :db_url
  attr_accessor :view

  def initialize(params)
    @params = params
    @db = Sequel.connect(:adapter=>ADAPTER, :host=>HOST, :database=>params[:db], :user=>USER, :password=>PASSWORD)
    @symbol = params[:table].to_sym
    @schema = @db.schema(@symbol)
    @url = '/db/' + params[:db] + '/' + params[:table]
    @db_url = '/db/' + params[:db]
  end

  def to_s
    return @params[:table]
  end
  
  def page
    if @params[:page].to_i > 0
      return @params[:page].to_i
    end
    return 1
  end

  def order_type
    if @params[:ot] != 'asc' or @params[:ot] != 'desc'
      return 'asc'
    end
    return @params[:ot]
  end

  def pk
    @schema.each do |c|
      if c.last[:primary_key] == true
        return c.first.to_s
      end
    end
  end

  def limit
    if @params[:l].to_i > 0
      return @params[:l].to_i
    else
      return 10
    end
  end
    
  def order_by
    if @params[:o] and !@params[:o].nil? and !@params[:o].empty? 
      return @params[:o]
    end
    return pk
  end
  
  def dataset
    qs = @db[@symbol].paginate(page, limit)
    if order_by
      if order_type == 'desc'
        qs = qs.reverse_order(order_by.to_sym)
      else
        qs = qs.order(order_by.to_sym)
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

get '/db/:db/:table' do
  @table = Table.new(params)
  @table.view = 'content'
  haml :table_detail
end

get '/db/:db/:table/schema' do
  @table = Table.new(params)
  @table.view = 'schema'
  haml :table_schema
end

get '/db/:db/:table/:pk' do
  @table = Table.new(params)
  @object = @table.db[@table.symbol].filter(@table.pk.to_sym => params[:pk])
  @table.view = 'edit'
  haml :row_edit
end

post '/db/:db/:table/:pk' do
  @table = Table.new(params)
  post = {}
  @table.schema.each do |s|
    post[s.first.to_s] = params[s.first.to_s]
  end
  @table.db[@table.symbol].filter(@table.pk.to_sym => params[:pk]).update(post)
  @object = @table.db[@table.symbol].filter(@table.pk.to_sym => params[:pk])
  @table.view = 'edit'
  haml :row_edit
end
