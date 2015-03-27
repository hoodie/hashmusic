#!/usr/bin/env ruby

require 'yaml'
require 'twitter'
require 'youtube-dl.rb'
require 'soundcloud'
require 'hashr'
require 'open-uri'
require 'rss'

@HASHTAG = "hashmusic"

$KEYS = Hashr.new YAML::load File.open File.expand_path "API_KEYS.yml"
@USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:36.0) Gecko/20100101 Firefox/36.0"
@STORATE_PATH = File.join Dir.home, "hashmusic"

fail "#{@STORATE_PATH} does not exist, please create it" unless File.exists? @STORATE_PATH

@twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key    = $KEYS.TWITTER.API_KEY
  config.consumer_secret = $KEYS.TWITTER.SECRET
  config.bearer_token = $KEYS.TWITTER.BEARER_TOKEN
end

@soundcloud_client = Soundcloud.new(:client_id =>  $KEYS.SOUNDCLOUD.CLIENT_ID)

def search_soundcloud terms, results = 1
  terms = terms.join " " if terms.class == Array
  tracks = @soundcloud_client.get('/tracks', :q => terms).take(results)
  urls = tracks.map{|track| track.permalink_url }
end

def search_youtube terms, results = 1
  terms = terms.split " " if terms.class == String
  terms = terms.join 
  url = "http://gdata.youtube.com/feeds/api/videos?q=#{terms}&max-results=#{results}&v=2"
  urls = load_items(url).map{|item| item.link.href}
  urls.map{|url| url}
end

def load_items url
  tmp = open(url, "User-Agent" => @USER_AGENT).read
  @items = RSS::Parser.parse(tmp, false).items
end

def get_the_music terms, user, id = "00000"
  puts "searching soundcloud"
  url = search_soundcloud(terms).first
  name = "#{terms} - #{user}"
  YoutubeDL.download url, {:"extract-audio"=>true, :"no-overwrites"=>true, output:"#{@STORATE_PATH}/#{name}.%(ext)s"}
  puts url
  puts Dir.glob "#{@STORATE_PATH}/#{name}.*"
end

#get_the_music "rick astley never gonna give you up", "testuser"

@twitter_client.search(@HASHTAG).take(5).each{|tweet|
  text = tweet.text.split(" ")
  text.delete(@HASHTAG)
  text.delete(?#+@HASHTAG)
  text = text.join(" ")
  puts "#{tweet.user.name}: #{text}"
  get_the_music text, ?@+tweet.user.screen_name
}

