require "./config.rb"
require "pathname"
require "fileutils"

MOD_FOLDER_REGEX = /\A(?<profiles>[^-]+) - (?<name>.*)\Z/

class Mod
  attr_reader :profiles
  attr_reader :name
  attr_reader :old_path
  attr_reader :old_names

  def initialize(old_path, path, profiles, name)
    @old_path = old_path
    @path = path
    @profiles = profiles
    @name = name
    @old_names = ["+#{folder}"]
  end

  # Creates a new Mod from the passed path to a mod folder.
  def self.from_path(path)
    # Path fun
    n_old_path = path
    path_parts = path.split(/\/|\\/)
    folder_name = path_parts.pop
    n_path = File.join(*path_parts)

    # Figure out name and profiles
    match = folder_name.match(MOD_FOLDER_REGEX)
    return nil if match.nil?

    n_name = match[:name]

    n_profiles = match[:profiles].split("_").select do |prof|
      !BASE_PROFILES.include?(prof)
    end
    return nil if n_profiles.empty?

    # Alllllll done
    return Mod.new(n_old_path, n_path, n_profiles, n_name)
  end

  # Returns the folder name this Mod should be under (but may not currently be
  # under)
  def folder
    "#{profiles.join("_")} - #{name}"
  end

  # Returns the path this Mod should be under (but may not currently be under)
  def path
    File.join(@path, folder)
  end

  # Saves changes made on this Mod object to the filesystem.
  def save_changes
    return old_path if $flags[:dry]
    return old_path if old_path == path
    puts "Renaming #{old_path} to #{path}..."
    FileUtils.mv(old_path, path)
    @old_path = path
  end
  
  def to_s
    folder
  end

  # Returns true if the files in this mod are identical to the files in omod.
  def compare(omod)
    return true if omod == self
    return false unless omod.name == name

    oldpathname = Pathname.new(old_path)
    Dir.glob(File.join(old_path, "**", "*")) do |full_path|
      relative_path = Pathname.new(full_path).relative_path_from(oldpathname)
      ofull_path = File.join(omod.old_path, relative_path)
      return false unless File.exist?(ofull_path)
      return false unless File.directory?(ofull_path) == File.directory?(full_path)
      next if File.directory?(full_path)
      return false unless FileUtils.identical?(full_path, ofull_path)
    end
    
    return true
  end

  # Merges this mod with the passed mod. This will delete the other mod.
  def merge!(omod)
    return self if omod == self
    omod.profiles.each do |prof|
      profiles << prof
    end

    old_names << "+#{folder}"

    unless $flags[:dry] then
      profiles.each do |prof|
        # Update that profile's modlist
        modlist_file = File.join(PROFILES, prof, "modlist.txt")
        modlist_text = File.read(modlist_file)
        modlist = modlist_text.split("\n")
        (0...modlist.size).each do |i|
          modlist[i] = "+#{folder}" if old_names.include?(modlist[i]) || omod.old_names.include?(modlist[i])
        end
        File.open(modlist_file, "w") do |out|
          out.puts modlist.join("\n")
        end
      end
    end

    omod.delete
    self
  end

  # Deletes this mod. Should only be called after this is merged with another
  # mod.
  def delete
    return nil if $flags[:dry]
    FileUtils.rm_rf(old_path)
    old_path = ''
    name = ''
    profiles = []
    nil
  end
end

$flags = { dry: false }

# Parse args
ARGV.each do |arg|
  match = arg.match(/\A(?:\/|-)(?<flag>\w*)\Z/)
  raise "Unknown parameter #{arg}" if match.nil?
  flag = match[:flag].to_sym
  if $flags.key?(flag) then
    puts "Switching #{flag} on"
    $flags[flag] = true
  else
    raise "No flag #{flag}."
  end
end

# Generate list of mods (independent of profiles)
modlist = []
Dir.glob(File.join(MODS, "*")) do |mod_folder|
  mod = Mod.from_path(mod_folder)
  next if mod.nil?
  modlist << mod
end

# Turn into hash relating mods and profiles
modhash = {}
modlist.each do |mod|
  modhash[mod.name] ||= []
  modhash[mod.name] << mod
end

final_mods = {}
# Each mod...
modhash.each do |name, prof_hash|
  profiles = modhash[name].dup
  print "Condensing #{name}... (#{profiles.count} profiles to"

  # Compare all versions of mod
  i = 0
  while i + 1 < profiles.count do
    j = i + 1
    # For all ones we haven't compared yet...
    while j < profiles.count do
      # If they match...
      if profiles[i].compare(profiles[j]) then
        # Merge em and delete from the profiles hash
        profiles[i].merge!(profiles[j])
        profiles.delete_at(j)
      else
        j = j + 1
      end
    end
    
    print(" #{profiles[i].profiles.join("_")}")
    i = i + 1
  end
  
  print("\n")
  final_mods[name] = profiles
end

puts "\n\n=========================================\n\n"

final_mods.each do |_k, ary|
  ary.each do |mod|
    mod.save_changes
    puts mod.name
  end
end
