#!/usr/bin/env ruby
#

require 'mecab'

def acquire(streaming, rest, redis, pattern_set, screen_name, tweetqueue)
  mecab = MeCab::Tagger.new
  streaming.user do |object|
    if object.is_a?(Twitter::Tweet) && !object.retweet?
      set = []
      tweet = object.text
      tweet = tweet.gsub(%r{@\w+|https?:[\w\.\$\?\(\)\+\-:%&~=/#]+}, '')
      .gsub(/\w+\s/){|w| w.delete(' ')}
      .gsub(/\s|　|\\n/, "\n")
      lines = tweet.split("\n")
      lines.each do |line|
        word = []
        node = mecab.parseToNode(line)
        while node do
          word << node.surface
          set << [node.surface, node.feature] if !node.surface.empty?
          node = node.next
        end
        (word.length - 1).times do |i|
          redis.hincrby(word[i], word[i + 1], 2)
          if !word[i].empty? && !word[i + 1].nil? && !word[i + 1].empty?
            redis.hincrby(word[i] + word[i + 1], word[i + 2], 1)
          end
          if !word[i + 2].nil? && !word[i + 2].empty?
            redis.hincrby(word[i], word[i + 1] + word[i + 2], 1)
          end
        end
      end

      tweetqueue.push(reply_catch(object, set, pattern_set, redis)) if object.in_reply_to_screen_name == screen_name

    elsif object.is_a?(Twitter::Streaming::Event) && object.target_object.nil?
      rest.follow(object.source.id) if !ARGV.include?('--debug')
    end
  end
rescue => e
  puts e
  retry
end
