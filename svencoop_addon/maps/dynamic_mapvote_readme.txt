Instructions
Modify the File to add/delete maps:

/scripts/maps/store/mapvote_maps.txt

The first line should contain the timelimit in seconds.
Example:

Time: 20

The other lines should contains the map-data.
Example:

Half-Life Campaign|hl_c00

The character '|' splits the text.
The text infront of the Pipe-Character it the title that appears on the Vote-Screen.
The text after the Pipe-Character is the name of the map.

You can also add a breakline in the title by adding "\n".
Example:

Half-Life\nCampaign|hl_c00

It is possible to add a second map to the map-data.
Example:

Half-Life Campaign|hl_c00|hl_c02_a1

If people decided to vote for a campaign,
a Vote-Window will appear that allows the people to skip the intro (goto 2nd map).

If you want to add a Pipe-Character to the title, then use "\|".

Vote-Screen doesn't support Unicode-Characters.

If you want to change the music for the lobby, go to the directory: /sound/dynamic_mapvote/, add your own music file then edit the file dynamic_mapvote.gsr.
You will see the lines:

"dynamic_mapvote/dynamic_mapvote.ogg" "dynamic_mapvote/dynamic_mapvote.ogg"

Simply change the path of the second line of code to your desired music.
Example:

"dynamic_mapvote/dynamic_mapvote.ogg" "dynamic_mapvote/mymusic.mp3"

You are allowed to use mp3, wav and ogg formats.
After finishing you must add this custom sound to the dynamic_mapvote.res file.

Design
A picture is worth a thousand words.
Add a path to a sprite to the line like this:

sprites/dynamic_mapvote/half-life.spr|Half-Life Campaign|hl_c00

Then this sprite will appear on the votescreen.

Be sure that everybody can see the sprite (Add sprite-path into dynamic_mapvote.res as it is a custom sprite).

Be sure that the resolution of the sprite is 352x160 or else it wont fit into the Vote-Screen.

Note: use the HL/CS Sprite editor tool (.spr file) you can edit it and to make your own vote-screen.

The map will be built automatically using the text file.
If the Text-File is missing or contains invalid data, then the error will be shown as title on the Vote-Screen and Half-Life Campaign will be started after the vote.

If an invalid map gets voted, an Error-Message appears on your Screen and the Vote-Timer will reset, so the people can vote for a different map.

Special Event modes

This map features a Halloween and Christmas mode, which will allow you to use a special mapvote file to host theme-related maps, which will automatically load during Halloween or Christmas.
mapvote_maps_halloween.txt
mapvote_maps_xmas.txt

You can edit these to customise the maps just as you would for the default mapvote_maps.txt file.
If you want to just use the default mapvote file for the events, just simply remove one or all the above files.