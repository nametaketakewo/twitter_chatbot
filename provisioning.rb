#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'
require 'twitter'
require 'redis'
require 'hiredis'

def provisioning
  begin
    unless File.exist?('reply_pattern.yml')
      File.open('reply_pattern.yml', 'w') do |file|
        file.puts '---'
      end
    end
    reply_pattern = YAML.load_file('reply_pattern.yml')
  rescue
    File.open('reply_pattern.yml', 'w') do |file|
      file.puts '---'
    end
  end

  pattern_set = reply_pattern

  unless File.exist?('userconf.yml')
    twitter_conf_sample = { twitter:
    { ConsumerKey: '',
      ConsumerSecret: '',
      AccessToken: '',
      AccessTokenSecret: '' }
    }
    File.open('userconf.yml', 'w') do |file|
      file.puts '---'
      file.puts YAML.dump(twitter_conf_sample)
    end
  end

  begin
    twitter_conf = YAML.load_file('userconf.yml')['twitter']
    rest = Twitter::REST::Client.new(twitter_conf)
    streaming = Twitter::Streaming::Client.new(twitter_conf)
    raise unless rest.is_a?(Twitter::REST::Client)
    raise unless streaming.is_a?(Twitter::Streaming::Client)
  rescue
    puts 'Twitterの設定に失敗しました。userconf.ymlの設定を確認してください。'
    puts '設定ファイルの雛形をuserconf.ymlに出力しますか?[y/N]'
    File.open('userconf.yml', 'w') do |file|
      file.puts '---'
      file.puts YAML.dump(twitter_conf_sample)
    end if gets.chomp == 'y'
    retry
  end

  begin
    redis_conf = YAML.load_file('userconf.yml')['redis']
    redis = redis_conf ? Redis.new(redis_conf) : Redis.new
    raise unless redis.is_a?(Redis)
  rescue
    puts 'Redisの設定に失敗しました。RedisServerが起動しているか確認してください。'
  end
  return rest, streaming, redis, pattern_set
end
