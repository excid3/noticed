require 'erb'
require 'yaml'
require 'sinatra/base'

require 'noticed/web/helpers'
require 'noticed/web/paginator'

module Noticed
  class Web < Sinatra::Base
    enable :sessions
    use Rack::Protection, :use => :authenticity_token unless ENV['RACK_ENV'] == 'test'

    set :root, File.expand_path(File.dirname(__FILE__) + "/../../web")
    set :public_folder, proc { "#{root}/assets" }
    set :views, proc { "#{root}/views" }
    set :locales, ["#{root}/locales"]

    helpers WebHelpers

    DEFAULT_TABS = {
      "Dashboard" => '',
      "Database" => 'database',
    }

    class << self
      def default_tabs
        DEFAULT_TABS
      end
    end

    get '/' do
      erb :dashboard
    end

    get '/database' do
      @paginator, @notifications = Noticed::Paginator.paginate(Notification.newest_first, page: params[:page])
      erb :database
    end
  end
end