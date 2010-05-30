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

# Routes
get '/' do
  begin
    dbh = Mysql.real_connect("localhost", "root", "")
    @res = dbh.query("SHOW DATABASES")
  ensure
    dbh.close if dbh
  end
  haml :index
end

get '/:db' do
  @db = Sequel.connect(:adapter=>ADAPTER, :host=>HOST, :database=>params[:db], :user=>USER, :password=>PASSWORD)
  haml :table_list
end

get '/:db/:table' do
  db = Sequel.connect(:adapter=>ADAPTER, :host=>HOST, :database=>params[:db], :user=>USER, :password=>PASSWORD)
  table = params[:table].to_sym
  @path = '/' + params[:db].to_s + '/' + params[:table].to_s
  qs = db[table].limit(20)
  if params[:o]
    qs = qs.order(params[:o].to_sym)
  end
  @row_list = qs
  @schema_list = db.schema(table)
  haml :table_detail
end
