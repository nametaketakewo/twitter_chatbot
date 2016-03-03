#!/usr/bin/env ruby
#

require 'twitter'
require 'mecab'
require 'yaml'
require 'redis'
require 'hiredis'
require './provisioning'
require './acquire'
require './build_tweet'

Signal.trap(:INT) do
  exit!
end

begin

  rest, streaming, redis, reply_pattern, catch_pattern = provisioning
  screen_name = rest.user.screen_name
  tweetqueue = Queue.new

  Thread.new do
    acquire(streaming, redis, reply_pattern, catch_pattern, screen_name, tweetqueue)
  end

  Thread.new do
    puts 'ツイートする間隔を入力してください(分)'
    n = gets.chomp.to_i
    n = n > 1 ? n : 1
    loop do
      sleep(n * 30)
      tweetqueue.push(build_tweet(redis))
      sleep(n * 30)
    end
  end

  loop do
    unless tweetqueue.empty?
      tweetqueue.size.times do
        tweet = tweetqueue.pop
        if tweet.class == String
          rest.update(tweet)
        else
          rest.update(tweet[0], tweet[1])
        end
      end
    end
    sleep(5)
  end

rescue => e
  puts 'error...'
  puts e
  exit!
end
