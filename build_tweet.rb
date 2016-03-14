#!/usr/bin/env ruby
#

def build_tweet(redis, keyword = '')
  keyword = '' if redis.hkeys(keyword) == [] || keyword.nil?
  tweet = ''
  25.times do
    words = redis.hkeys(keyword)
    frequency = redis.hvals(keyword).map(&:to_i)
    candidates = ([] << words << frequency).transpose.map do |e|
      r = []
      e[1].times do
        r << e[0]
      end
      r
    end.flatten
    keyword = candidates.sample
    tweet << keyword if !keyword.nil?
    break if keyword == '' || keyword.nil?
  end
  tweet[0..120]
end
