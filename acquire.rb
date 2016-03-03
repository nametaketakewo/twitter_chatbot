#!/usr/bin/env ruby
#

require 'mecab'

def acquire(streaming, redis, reply_pattern, catch_pattern, screen_name, tweetqueue)
  mecab = MeCab::Tagger.new
  catch_keys = catch_pattern.keys.map { |e| Regexp.new(e) }
  reply_keys = reply_pattern.keys.map { |e| Regexp.new(e) }

  streaming.user do |tweet|
    if tweet.class == Twitter::Tweet

      reply = []
      all_words = []
      text = tweet.retweet? ? tweet.retweeted_tweet.text : text = tweet.text

      text = text.gsub(/(@\w+)/,'@ ').
      gsub(/https?:(\w|\/|\.)+/,'').
      gsub(/\s/,'\n').gsub(/　/,'\n')

      lines = text.split('\n')
      lines.each do |line|
        node = mecab.parseToNode(line)
        words = []
        while node do
          words << node.surface
          all_words << node.surface
          node = node.next
        end
        words.each.with_index do |word, i|
          if i < words.length - 1
            if redis.hkeys(word) != []
              redis.hset(word, words[i + 1], 1)
            else
              redis.hset(word, words[i + 1],redis.hget(word, words[i + 1]).to_i + 1)
            end
          end
        end
      end

      unless tweet.retweet?
        if tweet.in_reply_to_screen_name == screen_name
          reply_keys.each.with_index do |v, i|
            reply << "@#{tweet.user.screen_name} #{reply_pattern.values[i]}" <<
              {in_reply_to_status_id: tweet.id} if text =~ v && reply.empty?
          end
          reply << "@#{tweet.user.screen_name} #{build_tweet(redis, all_words[rand(all_words.length)] || '')}" <<
            {in_reply_to_status_id: tweet.id} if reply.empty?
        else
          catch_keys.each.with_index do |v, i|
            reply << "@#{tweet.user.screen_name} #{catch_pattern.values[i]}" <<
              {in_reply_to_status_id: tweet.id} if text =~ v && reply.empty?
          end
        end
      end

      tweetqueue.push(reply)

    end
  end
end
