#!/usr/bin/env ruby
# coding: utf-8

def reply_catch(tweet, set, reply_pattern, redis)
  if !reply_pattern.nil?
    reply_keys = reply_pattern.keys.map { |e| Regexp.new(e) }
    reply_keys.each.with_index do |v, i|
      if tweet.text =~ v
        reply = ["@#{tweet.user.screen_name}
        #{reply_pattern.values[i]}", { in_reply_to_status_id: tweet.id }]
        return reply
      end
    end
  end

  a = set.select { |item| item[1].split(',')[0] == '動詞' } .map { |item| item[0] } .sample || set.sample[0]
  b = set.select { |item| item[1].split(',')[0] == '名詞' } .map { |item| item[0] } .sample || set.sample[0]
  sample = (redis.hkeys(a) & redis.hkeys(b)) .sample || ''
  reply = ["@#{tweet.user.screen_name}
  #{build_tweet(redis, sample)}", { in_reply_to_status_id: tweet.id }]
  reply
rescue => e
  puts e
  retry
end
