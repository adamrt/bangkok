require 'rubygems'
require 'sinatra'
require 'haml'
require 'sequel'
require "mysql"

# Settings
HOST = 'localhost'
USER = 'root'
PASSWORD = ''
ADAPTER = 'mysql'
set :haml, {:format => :html5 }

# Classes
class Table

  attr_accessor :params_list, :db, :content_url, :schema_url, :db_url, :view

  def initialize(params)
    @db = Sequel.connect(:adapter=>ADAPTER, :host=>HOST, :database=>params[:db], :user=>USER, :password=>PASSWORD)
    @symbol = params[:table].to_sym
    @schema = @db.schema(@symbol)
    @params_list = Hash.new
    @view = params[:view]

    # urls
    @content_url = '/db/' + params[:db] + '/' + params[:table] + '/content'
    @schema_url = '/db/' + params[:db]+ '/' + params[:table] + '/schema'
    @db_url = '/db/' + params[:db].to_s


    if params[:l] and params[:l] != ''
      @params_list['l'] = @limit = params[:l].to_i
    else
      @params_list['l'] = @limit = 25
    end

    if params[:o]
      @order = params[:o].to_sym
      @params_list['o'] = params[:o]
      @params_list['ot'] = params[:ot] if !params[:ot].nil?
    else
      @order = nil
    end
  end

  def to_s
    params[:table]
  end

  def row_list
    qs = @db[@symbol].limit(@limit)
    if @order
      if params[:ot] == 'd'
        qs = qs.reverse_order(@order)
      else
        qs = qs.order(@order)
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
  redirect '/db/#{params[:db}/#{params[:table]}/content'
end

get '/db/:db/:table/:view' do
  @table = Table.new(params)
  haml :"table_#{@table.view}"
end
