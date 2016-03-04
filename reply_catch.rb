#!/usr/bin/env ruby
#

def reply_catch(tweet, word_set, reply_pattern, redis)
  reply_keys = reply_pattern.keys.map { |e| Regexp.new(e) }
  reply = []
  reply_keys.each.with_index do |v, i|
    reply << "@#{tweet.user.screen_name}
    #{reply_pattern[0].values[i]}" <<
      { in_reply_to_status_id: tweet.id } if tweet.text =~ v && reply.empty?
  end
  reply << "@#{tweet.user.screen_name}
  #{build_tweet(redis, word_set[rand(word_set.length)] || '')}" <<
    { in_reply_to_status_id: tweet.id } if reply.empty?
  reply
rescue => e
  puts e
  return []
end
