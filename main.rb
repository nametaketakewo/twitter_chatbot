#!/usr/bin/env ruby
# coding: utf-8

require 'twitter'
require 'mecab'
require 'yaml'
require 'redis'
require 'hiredis'
require 'nkf'
require './provisioning'
require './acquire'
require './build_tweet'
require './reply_catch'

Signal.trap(:INT) do
  exit!
end

rest, streaming, redis, pattern_set = provisioning
screen_name = rest.user.screen_name
tweetqueue = Queue.new

Thread.new do
  acquire(streaming, rest, redis, pattern_set, screen_name, tweetqueue)
end

Thread.new do
  n = 0
  ARGV.each do |e|
    n = e.to_i if e.to_i > 0
  end
  if n < 1
    puts 'ツイートする間隔を入力してください(分)'
    n = gets.chomp.to_i
    n = n > 1 ? n : 1
  end
  puts "#{n}分ごとにツイートを出力します。"
  loop do
    sleep(n * 30)
    tweetqueue.push(build_tweet(redis))
    sleep(n * 30)
  end
end

begin
  loop do
    tweet = tweetqueue.pop || break
    if ARGV.include?('--debug')
      puts tweet
    else
      tweet.is_a?(String) ? rest.update(tweet) : rest.update(tweet[0], tweet[1])
    end
  end
rescue => e
  puts "ERROR! #{e}"
  retry
end
