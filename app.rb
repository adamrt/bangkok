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
  @row_list = db[table].limit(20)
  @schema_list = db.schema(table)
  haml :table_detail
end
