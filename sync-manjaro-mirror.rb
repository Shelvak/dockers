#!/bin/env ruby

# gem install parallel activesupport
require 'active_support/all'
require 'shellwords'
require 'parallel'
require 'cgi'
scrapper = 'https://manjaro.kurdy.org/stable'

# Clean existing dir
# [
#   "*.db*"    ,
#   "*.tar.xz" ,
#   "*.tar.gz" ,
#   "*.tar.zst",
#   "*.sig"
# ].each do |ext|
#   `find volumes/manjaro-mirror/ -name "#{ext}" -type f -delete`
# end

servers = [
  'http://mirror.ibakerserver.pt/manjaro',
  'https://manjaro.kurdy.org',
  'https://mirror.komelt.dev/manjaro',
  'https://mirrors.aliyun.com/manjaro',
  'https://mirrors.cicku.me/manjaro',
  'https://mirrors.manjaro.org/repo',
  'https://mirrors2.manjaro.org',
]

`mkdir -p volumes/manjaro-mirror/stable/`

puts "Downloading state"
`wget -q --no-check-certificate --inet4-only https://mirrors.manjaro.org/repo/stable/state -O volumes/manjaro-mirror/stable/state`

%w[core extra community multilib].each do |repo|
  `wget -q --no-check-certificate --inet4-only https://mirrors.manjaro.org/repo/stable/#{repo}/x86_64/#{repo}.db -O volumes/manjaro-mirror/stable/#{repo}/x86_64/#{repo}.db`
end

full_files = []
finished = false

threads = %w[core extra community multilib].map do |repo|
  Thread.new do
    puts "Downloading #{repo}"
    `mkdir -p volumes/manjaro-mirror/stable/#{repo}/x86_64/`
    raw_files = `curl -s #{scrapper}/#{repo}/x86_64/`

    files = raw_files.scan(/href="(\S+\.tar\.\S+)">/).flatten
    files += raw_files.scan(/href="(\S+\.tar.\S+\.sig)">/).flatten
    files += raw_files.scan(/href="(\S+\.db)">/).flatten
    files += raw_files.scan(/href="(\S+\.db\.\S+)">/).flatten

    i = 0
    files.map {|e| e&.gsub('./', '') }.compact.uniq.each do |e|
      # file already exists
      if !e.match?(/\.db/) && system("[ -f volumes/manjaro-mirror/stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(e))} ]")
        # puts "Skipping #{e}"
        next
      end

      # Remove old version
      if pkg_name = e.match(/(\S+)-\d+\.\w+\.\d+/)&.captures&.first
        # puts "rm volumes/manjaro-mirror/stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(pkg_name))}*"
        `rm -f volumes/manjaro-mirror/stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(pkg_name))}*`
      end

      full_files << "stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(e))}"
    end
  end
end

Thread.new do
  threads.each(&:join)
  finished = true
end

Parallel.each(-> { full_files.pop || (finished && Parallel::Stop) }, in_threads: 100) do |e|
  `wget --no-check-certificate --inet4-only -q -nc #{servers.sample}/#{e} -O volumes/manjaro-mirror/#{e}`
end
