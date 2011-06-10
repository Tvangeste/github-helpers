#!/usr/bin/env ruby

require 'optparse'

# Change these defaults if you don't want to enter them
# over and over via command line arguments:
DEFAULT_USER="_YOUR_GITHUB_LOGIN_"
DEFAULT_PASS="_YOUR_GITHUB_PASS_"

# These are the defaults for the GoldenDict pulls
DEFAULT_TARGET_REPO="goldendict/goldendict"
DEFAULT_TARGET_BRANCH="master"

# No need to change anything below this line
$user = DEFAULT_USER
$pass = DEFAULT_PASS
$target_repo = DEFAULT_TARGET_REPO
$target_branch = DEFAULT_TARGET_BRANCH

opts = OptionParser.new do |o|
  o.separator ""
  o.separator "Mandatory:"
  o.on('-f', '--from BRANCH_NAME', "Source Branch") { |sb| $source_branch = sb }
  o.on('-n', '--name SUBJECT', "Short name of the pull request") { |title| $title = title }
  o.on('-i', '--issue ISSUE_NO', "Existing Issue Number") { |i| $issue = i }
  o.separator ""
  o.separator "Optional:"
  o.on('-d', '--description TEXT', "Short description of the pull request") { |d| $description = d }
  o.on('-r', '--tr REPO_NAME', "Target Repo [Default: #{DEFAULT_TARGET_REPO}]") { |tr| $target_repo = tr }
  o.on('-t', '--to BRANCH_NAME', "Target Branch [Default: #{DEFAULT_TARGET_BRANCH}]") { |tb| $target_branch = tb }
  o.on('-u', '--user LOGIN', "Github login [Default: #{DEFAULT_USER}]") { |login| $user = login }
  o.on('-p', '--pass PASS', "Github pass") { |pass| $pass = pass }
  o.on('-v', '--verbose', 'Only show the command') { |v| $verbose = v }
  o.on_tail('-h', 'Help') { puts o; exit }
  begin
    o.parse!
  rescue OptionParser::ParseError => inv_option
    puts "*** ERROR: #{inv_option}"
    puts o
    exit 1
  end
end

if ($source_branch && $source_branch !~ /:/)
  $source_branch = "#{$user}:#{$source_branch}"
end

puts
puts "User: #{$user}"
puts "Pass: #{ ($pass.nil? || $pass.empty?) ? 'Not set' : $pass.gsub(/./, '*') }"
puts
puts "Target Repo: #{$target_repo}"
puts "#{$source_branch} --> #{$target_branch}"
puts "Pull request's title: #{$title}" if $title
puts "Pull request's description: #{$description}" if $description
puts "Pull request's issue: #{$issue}" if $issue
puts

unless ($source_branch)
  $stderr.puts "*** ERROR: Source Branch is not specified."
  puts
  puts opts
  exit 1
end

if ($title.nil? && $issue.nil?)
  $stderr.puts "*** ERROR: Name or issue must be specified."
  puts
  puts opts
  exit 2
end

if (!$title.nil? && !$issue.nil?)
  $stderr.puts "*** ERROR: Both title and issue may not be defined at the same time."
  puts
  puts opts
  exit 3
end

if (!$verbose)
  print "OK(y/n)? "
  answer = gets.strip
  puts
end

issue_clause = ""
if ($issue)
  issue_clause = %Q{-d "pull[issue]=#{$issue}"}
end

description_clause = ""
if ($description)
  description_clause = %Q{-d "pull[body]=#{$description}"}
end

creds = $user
if (!$pass.empty?)
  creds += ":#{$pass}"
end

cmd = %Q{curl1 -i --user #{creds} \
  -d "pull[title]=#{$title}"            \
  -d "pull[base]=#{$target_branch}"     \
  -d "pull[head]=#{$source_branch}"     \
  #{description_clause}                 \
  #{issue_clause}                       \
  https://github.com/api/v2/json/pulls/#{$target_repo}
}


if (answer != 'y' || $verbose)
  puts cmd.gsub(/\s+/, ' ')
else
  unless (system cmd)
    puts "*** ERROR: cannot execute curl, make sure it's in the path!"
    puts
    puts "Command to execute:\n#{cmd.gsub(/\s+/, ' ')}"
  end
end
