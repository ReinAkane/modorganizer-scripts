require "./config.rb"

if !COPY_IF_NEEDED then
  puts "Forcing copy of mods, may take a while."
else
  puts "Will attempt to determine if we need to copy mods."
  puts "This may cause issues."
end

print "Use what source? (#{DEFAULT_SOURCE}) > "
source = gets.strip
if source.to_s == "" then
  source = DEFAULT_SOURCE
end

print "Provision what profile? > "
profile = gets.strip

require "fileutils"

profile_dir = File.join(PROFILES, profile)
puts "Checking for #{profile_dir}..."
unless File.exist?(profile_dir) then
  raise "Profile does not exist. Please copy it from #{source}"
end
puts "#{profile} exists"

print "Provision mods from #{source} to #{profile}? (yN) > "
response = gets.strip
unless response =~ /\Ay/i then
  exit
end

FileUtils.mkdir(TEMP) unless File.exist?(TEMP)
puts "Temp touched"

puts "Copying #{source} to temp..."
Dir.glob(File.join(MODS, "#{source}*")) do |path|
  need_to_copy = true

  target_path = File.join(TEMP, File.basename(path))
  if File.exists?(target_path) then
    if COPY_IF_NEEDED && File.mtime(target_path) > File.mtime(path) then
      need_to_copy = false
    else
      FileUtils.rm_rf(target_path)
    end
  end
  
  if need_to_copy then
    puts "Copying #{path}..."
    FileUtils.cp_r(path, File.join(TEMP, File.basename(path)))
  else
    puts "Skipping up to date mod #{File.basename(path)}"
  end
end
puts "#{source} copied"

sleep(1)

puts "Renaming #{source} files..."
mod_paths = []
Dir.glob(File.join(TEMP, "#{source}*")) do |path|
  mod_paths << path
end
mod_paths.each do |path|
  name = File.basename(path)
  dir = File.dirname(path)
  name.sub!("#{source}", profile)
  puts "Renaming to #{name}..."
  target_path = File.join(dir, name)
  if File.exists?(target_path) then
    FileUtils.rm_rf(target_path)
  end
  if COPY_IF_NEEDED then
    FileUtils.cp_r path, target_path
  else
    FileUtils.mv(path, target_path)
  end
end
puts "#{source} mods renamed to #{profile}"

print "Reviewed \"#{TEMP}\" for final move? (yN) > "
response = gets.strip
unless response =~ /\Ay/i then
  puts "Cancelling provision"
  exit
end

puts "Moving #{profile} to mods..."
mod_paths = []
Dir.glob(File.join(TEMP, "#{profile}*")) do |path|
  mod_paths << path
end
mod_paths.each do |path|
  puts "Moving #{path}..."
  FileUtils.mv(path, File.join(MODS, File.basename(path)))
end
puts "#{profile} moved"

puts "Please open ModOrganizer and reload the modlist"
print "ModOrganizer opened and closed? (yN) > "
response = gets.strip
unless response =~ /\Ay/i then
  puts "Cancelling provision"
  puts "Mods for #{profile} not deleted"
  exit
end
sleep(1)

puts "Correcting modlist..."
modlist_file = File.join(profile_dir, "modlist.txt")
modlist_text = File.read(modlist_file)
modlist = modlist_text.split("\n")
(0...modlist.size).each do |i|
  modlist[i].sub!("#{source}", profile) if modlist[i].sub!(profile, "#{source}").nil?
end
File.open(modlist_file, "w") do |out|
  out.puts modlist.join("\n")
end
puts "Modlist corrected"
puts "\n"
puts "#{profile} provisioned."