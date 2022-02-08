#!/usr/bin/env ruby

require 'cocoapods'
require 'colorize'
require 'mail'
require 'open3'
require 'yaml'

PODSPECS = YAML.load_file("modules.yaml")['pod_push_order']

USAGE =
"#{"Usage:".underline}\n"\
"\n"\
"\t$ #{"#{__FILE__} COMMAND".green}\n"\
"\n"\
"#{"Commands:".underline}\n"\
"\n"\
"\t#{"push".green}\n"\
"\n"\
"\t\tPushes all podspecs to `trunk` in order by dependencies.\n"\
"\n"\
"\n"\
"\t#{"add-all-owners".green} [#{"POD".magenta}]\n"\
"\n"\
"\t\tAdds all the owners of the `Stripe` pod as owners of #{"`POD`".magenta}.\n"\
"\t\tIf no pod is specified, adds all owners to all pods other than `Stripe`.\n"\
"\n"\
"\n"\
"\t#{"add-owner".green} #{"OWNER-EMAIL".magenta}\n"\
"\n"\
"\t\tAdds the registered user specified with #{"`OWNER-EMAIL`".magenta} as an\n"\
"\t\towner of all pods in this repo.\n"\
"\n"\
"\n"\
"\t#{"remove-owner".green} #{"OWNER-EMAIL".magenta}\n"\
"\n"\
"\t\tRemoves the user specified with #{"`OWNER-EMAIL`".magenta} from being\n"\
"\t\towner of all pods in this repo.\n"

# Pushes all podspecs to `trunk` in order by dependencies.
def push
  puts "If this is your first time running this command, it's going to take a while."
  puts "Go for a 🚶 or take a ☕️ break."
  puts ""
  puts "Pushing the following podspecs to #{"`trunk`".bold.magenta}: "\
  "#{PODSPECS.map { |s| s.underline }.join(" ")}"

  PODSPECS.each do |podspec|
    system "pod trunk push #{podspec} --synchronous"
  end
end

# Adds all the owners of the `Stripe` pod as owners of the given pod.
def add_all_owners(pod)
  if pod == "Stripe"
    abort("Specify a different pod other than #{"`Stripe`".magenta}.".red)
  end

  puts "Looking up owners of `Stripe` pod..."

  # Get a list of all the owners for the `Stripe` pod
  stdout, stderr, status = Open3.capture3("pod trunk info Stripe")

  unless status.success?
    abort(stderr)
  end

  # Parse output and extract emails
  yaml = YAML.load(stdout.lines[2..-1].join)
  owners = yaml[1]["Owners"]
  owner_emails = owners.map { |owner| Mail::Address.new(owner).address }

  # Add owners for all pods in repo
  updated_owners=""
  owner_emails.each do |ownerEmail|
    puts "Adding #{ownerEmail.magenta} to #{pod.magenta} owners."
    updated_owners=`pod trunk add-owner #{pod} #{ownerEmail}`
  end

  puts "Done updating owners:"
  puts updated_owners
end

# Adds all the owners of the `Stripe` pod as owners of the given pod.
def add_all_owners_all_pods()
  pods = all_pods_in_repo - ["Stripe"]
  pods.each do |pod|
    add_all_owners(pod)
  end
end

# Adds the specified registered user as an owner of all pods in this repo.
def add_owner(ownerEmail)
  all_pods_in_repo.each do |pod|
    puts "Adding #{ownerEmail.magenta} to #{pod.magenta} owners."
    system "pod trunk add-owner #{pod} #{ownerEmail}"
  end
end

# Removes the specified user from being an owner of all pods in this repo.
def remove_owner(ownerEmail)
  all_pods_in_repo.each do |pod|
    puts "Removing #{ownerEmail.magenta} from #{pod.magenta} owners."
    system "pod trunk remove-owner #{pod} #{ownerEmail}"
  end
end

# -- Helpers

# Returns a list of all the pods in this repo
def all_pods_in_repo
  return Dir.glob("./*.podspec").map { |file| Pod::Specification.from_file(file).root.name }
end

# -- Command Line

if ARGV.empty?
  abort("#{"Please specify a command.".red}\n\n#{USAGE}")
elsif ARGV[0] == "push"
  push
elsif ARGV[0] == "add-all-owners"
  if ARGV.length < 2
    add_all_owners_all_pods()
  else
    add_all_owners(ARGV[1])
  end
elsif ARGV[0] == "add-owner"
  if ARGV.length < 2
    abort("#{"Please specify an owner email to add.".red}\n\n#{USAGE}")
  else
    add_owner(ARGV[1])
  end
elsif ARGV[0] == "remove-owner"
  if ARGV.length < 2
    abort("#{"Please specify an owner email to remove.".red}\n\n#{USAGE}")
  else
    remove_owner(ARGV[1])
  end
else
  abort("#{"#{"'trunk #{ARGV[0]}'".green} is not a recognized command.".red}\n\n#{USAGE}")
end
