#!/usr/bin/env ruby

require 'os'
require 'inifile'
require 'yaml'
require 'fileutils'
require 'selenium/webdriver'
require 'httparty'
require 'shellwords'
require 'benchmark'

case ARGV[0][0].downcase
  when 'j'
    $zotero = 'jurism'
  when 'z'
    $zotero = 'zotero'
  else
    raise "Don't know what to do with #{ARGV[0]}"
end

puts "Getting #{$zotero}"

if OS.linux?
  PROFILES_DIR = File.expand_path("~/.#{$zotero}/zotero")
elsif OS.mac?
  PROFILES_DIR = File.expand_path('~/Library/Application Support/Zotero')
else
  puts OS.report
  exit 1
end

puts PROFILES_DIR
PROFILES = IniFile.load(File.join(PROFILES_DIR, 'profiles.ini'))

PROFILE = 'BBTZ5TEMPLATE'
profile = PROFILES[PROFILES.sections.select{|name| PROFILES[name]['Name'] == PROFILE}[0]]
raise "Profile #{PROFILE} not found in #{File.join(PROFILES_DIR, 'profiles.ini')}" unless profile
puts profile.inspect
PROFILE_DIR = File.expand_path(profile['IsRelative'] == 1 ? File.join(PROFILES_DIR, profile['Path']) : profile['Path'])

dataDir = nil
useDataDir = false
IO.readlines(File.join(PROFILE_DIR, 'prefs.js')).each{|pref|
  if pref =~ /^user_pref\("extensions.zotero.dataDir", "([^"]+)"\);$/
    dataDir = $1
  end

  if pref =~ /^user_pref\("extensions.zotero.useDataDir", true\);$/
    useDataDir = true
  end
}

TEMPLATE_STASH = File.expand_path(File.join(File.dirname(__FILE__), "../test/fixtures/profile/fetched-#{$zotero}"))
DATA_DIR = File.join(TEMPLATE_STASH, $zotero)

if !File.file?(File.join(DATA_DIR, 'translators', 'Scannable Cite.js'))
  raise "Scannable Cite is missing from the translators"
end

puts "#{PROFILE_DIR} => #{TEMPLATE_STASH}"

FileUtils.rm_rf(TEMPLATE_STASH)
FileUtils.cp_r(PROFILE_DIR, TEMPLATE_STASH)
FileUtils.cp_r(dataDir, DATA_DIR) if dataDir

puts "WARNING: #{$zotero} has dataDir but does not use it" if dataDir && !useDataDir
puts "WARNING: #{$zotero} uses dataDir" if dataDir
