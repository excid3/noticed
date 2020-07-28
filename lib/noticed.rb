require "noticed/railtie"
require "noticed/base"
require "noticed/database"
require "noticed/email"
require "noticed/slack"
require "noticed/twilio"
require "noticed/vonage"
require "noticed/websocket"

module Noticed
  autoload :Base, 'noticed/base'
  autoload :Database, 'noticed/database'
  autoload :Email, 'noticed/email'
  autoload :Slack, 'noticed/slack'
  autoload :Twilio, 'noticed/twilio'
  autoload :Vonage, 'noticed/vonage'
  autoload :Websocket, 'noticed/websocket'
end
