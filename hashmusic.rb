#!/usr/bin/env ruby

require 'yaml'
require 'twitter'
require 'youtube-dl.rb'
require 'soundcloud'
require 'hashr'
require 'open-uri'
require 'rss'

$KEYS = Hashr.new YAML::load File.open File.expand_path "API_KEYS.yml"
@USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0"
@STORATE_PATH = File.join Dir.home, "hashmusic"

fail "#{@STORATE_PATH} does not exist, please create it" unless File.exists? @STORATE_PATH

@twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key    = $KEYS.TWITTER.API_KEY
  config.consumer_secret = $KEYS.TWITTER.SECRET
  config.bearer_token = $KEYS.TWITTER.BEARER_TOKEN
end

#@twitter_client.search("hashmusic").take(5).each{|tweet|
#  puts "#{tweet.user.name}: #{tweet.text}"
#  #  tweet.hashtags.each{|ht| puts ht.text}
#}

@soundcloud_client = Soundcloud.new(:client_id =>  $KEYS.SOUNDCLOUD.CLIENT_ID)

def search_soundcloud terms, results = 5
  terms = terms.join " " if terms.class == Array
  tracks = @soundcloud_client.get('/tracks', :q => terms, :licence => 'cc-by-sa')
  tracks.take(results).map{|track| track.permalink_url }
end

def search_youtube terms, results = 5
  terms = terms.split " " if terms.class == String
  terms = terms.join 
  url = "http://gdata.youtube.com/feeds/api/videos?q=#{terms}&max-results=#{results}&v=2"
  load_items(url).map{|item| item.link.href}
end

def load_items url
  tmp = open(url, "User-Agent" => @USER_AGENT).read
  @items = RSS::Parser.parse(tmp, false).items
end

def download_the_music url
  YoutubeDL.download url, {"extract-audio":true, "no-overwrites":true, output:@STORATE_PATH}
end

puts "searching youtube"
search_youtube("rick astley never gonna give you up").each{|url| puts url}

puts 

puts "searching soundcloud"
search_soundcloud("rick astley never gonna give you up").each{|url| puts url}
puts "downloading first track from soundcloud"
download_the_music search_soundcloud("rick astley never gonna give you up").first

