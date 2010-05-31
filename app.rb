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

  attr_accessor :params_list
  
  def initialize(params)
    @params = params
    @db = Sequel.connect(:adapter=>ADAPTER, :host=>HOST, :database=>@params[:db], :user=>USER, :password=>PASSWORD)
    @path = '/db/' + @params[:db].to_s + '/' + @params[:table].to_s
    @symbol = @params[:table].to_sym
    @params_list = Hash.new
    
    if @params[:l] and @params[:l] != ''
      @limit = @params[:l].to_i
    else
      @limit = 25
    end

    @params_list['l'] = "#{@limit}"    

    if @params[:o]
      @order = @params[:o].to_sym
      @params_list['o'] = "#{@order.to_s}"
    else
      @order = nil
    end
  end

  def to_s
    "#{params[:table]}"
  end

  def row_list
    qs = @db[@symbol].limit(@limit)
    qs = qs.order(@order) if !@order.nil?
    return qs
  end

  def schema
    @db.schema(@symbol)
  end
end

# Routes

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
  haml :table_detail
end
