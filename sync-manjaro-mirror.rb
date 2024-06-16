#!/bin/env ruby

# gem install parallel activesupport
require 'active_support/all'
require 'shellwords'
require 'parallel'
require 'cgi'
scrapper = 'https://manjaro.kurdy.org/stable'

servers = [
  'https://manjaro.kurdy.org',
  'https://mirrors.manjaro.org/repo',
  'https://mirrors2.manjaro.org',
  'http://mirror.ibakerserver.pt/manjaro/',
  'https://mirrors.cicku.me/manjaro'
]

`mkdir -p volumes/manjaro-mirror/stable/`

puts "Downloading state"
`wget -q --no-check-certificate --inet4-only #{scrapper}/state -O volumes/manjaro-mirror/stable/state`

full_files = []
finished = false

Thread.new do
  %w[core extra community multilib].each do |repo|
    puts "Downloading #{repo}"
    `mkdir -p volumes/manjaro-mirror/stable/#{repo}/x86_64/`
    raw_files = `curl -s #{scrapper}/#{repo}/x86_64/`

    files = raw_files.scan(/href="(\S+\.tar\.\S+)">/).flatten
    files += raw_files.scan(/href="(\S+\.tar.\S+\.sig)">/).flatten
    files += raw_files.scan(/href="(\S+\.db)">/).flatten
    files += raw_files.scan(/href="(\S+\.db\.sig)">/).flatten

    files.map {|e| e&.gsub('./', '') }.compact.uniq.each do |e|
      full_files << "stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(e))}"
    end
  end
  finished = true
end


Parallel.each(-> { full_files.pop || (finished && Parallel::Stop) }, in_threads: 50) do |e|
  `wget --no-check-certificate --inet4-only -q -nc #{servers.sample}/#{e} -O volumes/manjaro-mirror/#{e}`
end
