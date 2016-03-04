#!/usr/bin/env ruby
#

def tl_catch(tweet, tl_pattern)
  tl_keys = tl_pattern.keys.map { |e| Regexp.new(e) }
  reply = []
  tl_keys.each.with_index do |v, i|
    reply << "@#{tweet.user.screen_name}
    #{tl_pattern[1].values[i]}" <<
      { in_reply_to_status_id: tweet.id } if tweet.text =~ v && reply.empty?
  end
  reply
rescue => e
  puts e
  return []
end
