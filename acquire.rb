#!/usr/bin/env ruby
#

require 'mecab'

def acquire(streaming, redis, pattern_set, screen_name, tweetqueue)
  mecab = MeCab::Tagger.new
  streaming.user do |tweet|
    if tweet.class == Twitter::Tweet
      all_words = []
      text = tweet.retweet? ? tweet.retweeted_tweet.text : text = tweet.text
      text = text.gsub(/(@\w+)/,'@ ').gsub(/https?:(\w|\/|\.)+/,'').gsub(/\s/,'\n').gsub(/　/,'\n')
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
        reply = tweet.in_reply_to_screen_name == screen_name ?
        reply_catch(tweet, all_words, pattern_set[0], redis) :
        tl_catch(tweet, pattern_set[1])
        tweetqueue.push(reply) unless reply.empty?
      end
    end
  end
rescue => e
  puts e
  retry
end
