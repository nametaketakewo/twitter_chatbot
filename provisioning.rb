#!/usr/bin/env ruby
#

require 'yaml'
require 'twitter'
require 'redis'
require 'hiredis'

def provisioning
  begin
    unless File.exist?('catch_pattern.yml')
      File.open('catch_pattern.yml', 'w') do |file|
        file.puts '---'
      end
    end
    reply_pattern = YAML.load_file('reply_pattern.yml')
  rescue
    File.open('catch_pattern.yml', 'w') do |file|
      file.puts '---'
    end
  end

  begin
    unless File.exist?('reply_pattern.yml')
      File.open('reply_pattern.yml', 'w') do |file|
        file.puts '---'
      end
    end
    catch_pattern = YAML.load_file('catch_pattern.yml')
  rescue
    File.open('reply_pattern.yml', 'w') do |file|
      file.puts '---'
    end
  end

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
    raise unless rest.class == Twitter::REST::Client
    raise unless streaming.class == Twitter::Streaming::Client
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
    raise unless redis.class == Redis
  rescue
    redis = Redis.new
  end
  return rest, streaming, redis, catch_pattern, reply_pattern
end
