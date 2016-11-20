## Intro ##
When I had ten or so profiles in Mod Organizer of all the different characters
I played in Skryim I noticed a little problem. Some of the programs that one
runs to setup mods (FNIS, ReProccer, etc) were affecting mods other than
overwrite. This meant that profiles other than the one I had most recently ran
everything for had stange issues.

To solve the problem I created a Ruby script that would copy all the mods from a
base profile to my new profiles, allowing me to run FNIS and the like on other
profiles without causing issues. Great, right? Well it turns out you can fill
your HDD pretty quickly that way (300GB of Skyrim mods...) so I needed to cut
that space requirement down. Enter condense_mods....

The condense_mods script checks all mods in all of your profiles and merges
duplicates. Have three profiles that all share the same Bodyslide preset?
condense_mods will merge the mods affected by Bodyslide for those profiles. Be
careful, as this is NOT REVERSABLE.

Once I had my HDD back I realized another problem: condense_mods had made it
difficult to delete an entire profile. In comes the delete_profile script. It
will delete a profile and clean up all the merged mods for that profile.

## Provisioning a profile ##
Start by making a BASE profile in Mod Organizer. Every mod that you install
there should be prefixed with "BASE - ". Any mods that should be shared between
profiles should be prefixed with "SHARED - " (ex. Race Menu Presets). Make sure
you fully set up the profile and test it out. Once you're happy with the profile
copy the BASE profile in Mod Organizer (we'll call your new profile "Fred").
Close Mod Organizer and run `ruby provision_char.rb`. Here's a sample run:

```
Use what source? (BASE) > BASE		// The base profile you are copying from

Provision what profile? > Fred		// The new profile you want to create

Checking for C:\Program Files (x86)\Mod Organizer\Profiles\Fred...

Fred exists

Provision mods from BASE to Fred? (yN) > y		// Enter N if you had a typo in your source or profile

Temp touched

Copying BASE to temp...

Copying C:\Program Files (x86)\Mod Organizer\mods\BASE - Some crazy mod...

Copying C:\Program Files (x86)\Mod Organizer\mods\BASE - Some OTHER crazy mod...

BASE copied

Renaming BASE files...

Renaming to Fred - Some crazy mod...

Renaming to Fred - Some OTHER crazy mod...

BASE mods renamed to Fred

Reviewed C:\Program Files (x86)\Mod Organizer\temp for final move? (yN) > y // You can enter N here to cancel the operation.

Moving Fred to mods...

Moving C:\Program Files (x86)\Mod Organizer\temp\Fred - Some crazy mod...

Moving C:\Program Files (x86)\Mod Organizer\temp\Fred - Some OTHER crazy mod...

Please open ModOrganizer and reload the modlist

ModOrganizer opened and closed? (yN) > y		// Here you need to open Mod Organizer and select the new profile (Fred), then close Mod Organizer again

Correcting modlist...

Modlist corrected



Fred provisioned.
```

Congratulations, you have provisioned the Fred profile. Feel free to start it up
in Mod Organizer!

## Deleting a profile ##
Close Mod Organizer then run `ruby delete_profile.rb`. It will ask what profile
to delete. Once you enter a profile it will generate a TODO list. Check the list
to make sure it isn't doing anything crazy, then enter "y" and it will delete
the profile.

## Condensing mods ##
To condense mods you can simply run `ruby condense_mods.rb`. You can also run
`ruby condense_mods.rb -dry` to have it output what it would do without actually
condensing the mods. If possible, I recommend backing up before condensing.
