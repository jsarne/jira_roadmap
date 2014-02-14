require 'bundler/setup'
require 'sinatra'
require 'net/https'
require 'json'
require 'haml'
require 'sinatra/config_file'

config_file 'config/config.yml'

# add in basic auth using env variables
helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV['ADMIN_USER'], ENV['ADMIN_PASS']]
  end
end

get '/' do
  protected!

  @jiras = get_roadmap 
  @r_items = []

  @jiras['issues'].each {|jira| 
    @r_item = {}

    if(jira['fields'])
      
      #puts 'JIRA: ' + jira.to_s

      @r_item['content'] = jira['fields']['summary']
      @r_item['start'] = Time.parse(jira['fields']['customfield_11950'])
      @r_item['end'] = Time.parse(jira['fields']['customfield_11951'])
      @r_item['group'] = jira['fields']['customfield_11850']['value']
      @r_item['jira_uri'] = 'https://' + settings.jira_host + '/browse/' + jira['key']
      @r_item['jira_description'] = jira['renderedFields']['description']

      @r_items.push(@r_item)
    end
  }

  haml :index, :locals => {:jiras => @r_items}
end

get '/roadmap' do
  protected!
  return JSON.pretty_generate(get_roadmap)
end

def get_roadmap

  @jira_epics = ''

  http = Net::HTTP.new(settings.jira_host, settings.jira_port)
  http.use_ssl = settings.use_ssl
  http.start do |http|
    req = Net::HTTP::Get.new(settings.jira_path)

    # we make an HTTP basic auth by passing the
    # username and password
    req.basic_auth ENV['JIRA_USER'], ENV['JIRA_PASS']
    resp, data = http.request(req)
    #print "Resp: " + resp.code.to_s + "\n"
    #print "Data: " +  JSON.pretty_generate(JSON.parse(resp.body.to_s))

    @jira_epics = JSON.parse(resp.body.to_s)
  end

  return @jira_epics
end
