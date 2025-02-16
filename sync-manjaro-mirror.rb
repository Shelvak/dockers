#!/bin/env ruby

require 'debug'

# gem install parallel activesupport
require 'active_support/all'
require 'shellwords'
require 'parallel'
require 'cgi'
require 'open-uri'
require 'debug'

scrapper = 'https://manjaro.kurdy.org/stable'

puts `echo "executing from: $PWD"`

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
  # 'https://mirrors.manjaro.org/repo',
  # 'https://mirrors2.manjaro.org',
]

`mkdir -p volumes/manjaro-mirror/stable/`

puts "Downloading state"
`wget -q --no-check-certificate --inet4-only https://mirrors.manjaro.org/repo/stable/state -O volumes/manjaro-mirror/stable/state`

%w[core extra community multilib].each do |repo|
  `mkdir -p volumes/manjaro-mirror/stable/#{repo}/x86_64/`
  `wget -q --no-check-certificate --inet4-only https://mirrors.manjaro.org/repo/stable/#{repo}/x86_64/#{repo}.db -O volumes/manjaro-mirror/stable/#{repo}/x86_64/#{repo}.db`
end

@full_files = []
@finished = false

Thread.new do
  %w[core extra community multilib].each do |repo|
    puts "Curling #{repo}"
    raw_files = URI.open("#{scrapper}/#{repo}/x86_64/").read

    puts "Building #{repo} list"
    repo_files = raw_files.split("\n").map do |line|
      line.start_with?("<a href") ? line.match(/href="(\S+)"/)&.captures&.first : nil
    end.compact.map do |file|
      CGI.unescape(file)
    end

    puts "Building #{repo} existing files"
    existing_files = `ls volumes/manjaro-mirror/stable/#{repo}/x86_64/`.split("\n")

    files_to_download = repo_files - existing_files

    puts "Downloading #{files_to_download.uniq.size} files from #{repo}"

    files_to_remove = (existing_files - repo_files) - ["#{repo}.db"] # repo.db just in case
    puts "Removing #{files_to_remove.size} files from #{repo}"

    files_to_remove.each_slice(10) do |group|
      # debugger
      `cd volumes/manjaro-mirror/stable/#{repo}/x86_64/ && rm #{group.map {|e| Shellwords.escape(e) }.join(' ')}`
    end

    files_to_download.uniq.each do |e|
    # repo_files.uniq.each do |e|
      @full_files << "stable/#{repo}/x86_64/#{Shellwords.escape(e)}"
    end

    puts "Done with #{repo}"
  end

  @finished = true
end

Parallel.each(-> { @full_files.pop || (@finished && Parallel::Stop) }, in_threads: 100) do |e|
  next unless e
  # puts "Downloading #{e}"
  r = `wget --no-check-certificate --inet4-only -q #{servers.sample}/#{e} -O volumes/manjaro-mirror/#{e}`
  if r.strip != ""
    puts "WGET: #{e}"
  end
end
