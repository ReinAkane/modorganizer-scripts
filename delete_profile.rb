require "./config.rb"

STEP_ARG_BARRIER = ": "
DELETE_PROFILE_STEP = "delete_profile"
DELETE_MOD_STEP_PREFIX = "delete_mod#{STEP_ARG_BARRIER}"
RENAME_MOD_STEP_PREFIX = "rename_mod#{STEP_ARG_BARRIER}"
CHANGE_SELECTED_PROFILE = "change_selected_profile"

print "Delete what profile? > "
profile = gets.strip

require "fileutils"

todo_steps = []

puts "Gathering status of #{profile}..."

profile_dir = File.join(PROFILES, profile)
puts "  Checking for #{profile_dir}..."
if File.exist?(profile_dir) then
  todo_steps << DELETE_PROFILE_STEP
end

puts "  Checking if #{profile} is active profile..."
ini_contents = File.read(MO_INI)
if ini_contents.include?("selected_profile=#{profile}") then
  todo_steps << CHANGE_SELECTED_PROFILE
end

puts "  Checking for mods..."
Dir.glob(File.join(MODS, "*")) do |path|
  if File.basename(path) =~ /\A#{profile}[^_]/ then
    todo_steps << "#{DELETE_MOD_STEP_PREFIX}#{path}"
  elsif File.basename(path) =~ /\A[^ ]*#{profile}/ then
    todo_steps << "#{RENAME_MOD_STEP_PREFIX}#{path}"
  end
end

puts "Information gathered... Please review todo list:"
todo_steps.each do |todo|
  puts "  #{todo}"
end

print "Todo steps reviewed and good to go? (yN) > "
response = gets.strip
unless response =~ /\Ay/i then
  puts "  delete cancelled."
  exit
end

def rename_mod(path, profile)
  # Rename mod folder
  basename = File.basename(path)
  target_basename = basename.sub(profile, "").sub("__", "_").sub(/\A_/, "").sub(/\A([^ ]+)_ /, '\1')
  puts "    Renaming #{basename} to #{target_basename}"
  File.rename(path, File.join(MODS, target_basename))
  # FileUtils.mv(path, File.join(MODS, target_basename))
  # Go through all profiles and rename the mod in their respective modlists.
  Dir.glob(File.join(PROFILES, "*")) do |prof_dir|
    prof_contents = File.read(File.join(prof_dir, "modlist.txt"))
    prof_contents.gsub!(basename, target_basename)
    File.open(File.join(prof_dir, "modlist.txt"), "w") do |handle|
      handle.write(prof_contents)
    end
  end
end

todo_steps.each do |step|
  if step == DELETE_PROFILE_STEP then
    puts "Deleting #{profile_dir}..."
    FileUtils.rm_rf(profile_dir)
  elsif step.start_with?(DELETE_MOD_STEP_PREFIX) then
    mod = step.split(STEP_ARG_BARRIER)
    mod.shift
    mod = mod.join
    puts "Deleting #{mod}..."
    FileUtils.rm_rf(mod)
  elsif step == CHANGE_SELECTED_PROFILE then
    puts "Changing selected mod in #{MO_INI}..."
    ini_contents.sub!("selected_profile=#{profile}", "selected_profile=#{DEFAULT_PROFILE}")
    File.rename(MO_INI, BACKUP_MO_INI)
    begin
      File.open(MO_INI, "w") do |handle|
        handle.write(ini_contents)
      end
    rescue Exception => e
      FileUtils.rm(MO_INI) if File.exist?(MO_INI)
      File.rename(BACKUP_MO_INI, MO_INI)
    end
  elsif step.start_with?(RENAME_MOD_STEP_PREFIX) then
    mod = step.split(STEP_ARG_BARRIER)
    mod.shift
    mod = mod.join
    rename_mod(mod, profile)
  else
    raise "Unknown step #{step}"
  end
end

puts
puts "Profile #{profile} deleted."
