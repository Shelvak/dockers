#!/bin/env ruby

# gem install parallel activesupport
require 'active_support/all'
require 'shellwords'
require 'parallel'
require 'cgi'
scrapper = 'https://manjaro.kurdy.org/stable'

# Clean existing dir
[
  "*.db*"    ,
  "*.tar.xz" ,
  "*.tar.gz" ,
  "*.tar.zst",
  "*.sig"
].each do |ext|
  `find volumes/manjaro-mirror/ -name "#{ext}" -type f -delete`
end

servers = [
  'https://manjaro.kurdy.org',
  'https://mirrors.manjaro.org/repo',
  'https://mirrors2.manjaro.org',
  'http://mirror.ibakerserver.pt/manjaro/',
  'https://mirrors.cicku.me/manjaro'
]

`mkdir -p volumes/manjaro-mirror/stable/`

puts "Downloading state"
`wget -q --no-check-certificate --inet4-only https://mirrors.manjaro.org/repo/stable/state -O volumes/manjaro-mirror/stable/state`

%w[core extra community multilib].each do |repo|
  `wget -q --no-check-certificate --inet4-only https://mirrors.manjaro.org/repo/stable/#{repo}/x86_64/#{repo}.db -O volumes/manjaro-mirror/stable/#{repo}/x86_64/#{repo}.db`
end

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
    files += raw_files.scan(/href="(\S+\.db\.\S+)">/).flatten

    i = 0
    files.map {|e| e&.gsub('./', '') }.compact.uniq.each do |e|
      # file already exists
      next if system("[ -f volumes/manjaro-mirror/stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(e))} ]")

      # Remove old version
      if pkg_name = e.match(/(\S+)-\d+\.\w+\.\d+/)&.captures&.first
        puts "rm volumes/manjaro-mirror/stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(pkg_name))}*"
        `rm -f volumes/manjaro-mirror/stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(pkg_name))}*`
      end

      full_files << "stable/#{repo}/x86_64/#{Shellwords.escape(CGI.unescape(e))}"
    end
  end
  finished = true
end

Parallel.each(-> { full_files.pop || (finished && Parallel::Stop) }, in_threads: 50) do |e|
  `wget --no-check-certificate --inet4-only -q -nc #{servers.sample}/#{e} -O volumes/manjaro-mirror/#{e}`
end
