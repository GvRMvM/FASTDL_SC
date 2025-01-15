# What are the Angelscript guidelines?

The majority of guidelines from last year's Ragemap 2022 will apply. If you do not require any scripting for your map you can ignore this section.

Your part should have one main script at path "scripts/maps/ragemap2023/`{mapperTag}`.as". The `{mapperTag}` is your mapper tag name, so for example Hezus would have `hezus`, and `I_ka` would be `i_ka`.

Absolutely ***everything*** in your script must be in a namespace specific for you to avoid conflicting with other mappers and the core map scripts. Take a copy of the included "example.as" to get a stub of how your script file should look like this to begin with, doing a bulk replacement of "Example" to your own alias.

Include your map script within the script specific to the part of Ragemap 2023 you're working on, so if you're in map A you would edit file "scripts/maps/ragemap2023/ragemap2023a.as" as follows:

```as
/*
 * -------------------------------------------------------------------------
 * Includes
 * -------------------------------------------------------------------------
 */

#include "ragemap2023"
#include "example"
```

(The last `#include "example"` line would be your mapper tag instead.)

If your script requires use of the `MapInit` or `MapActivate` hooks you must include these in the map part's script as follows, after the shared script's call:

```as
/**
 * Map initialisation handler.
 * @return void
 */
void MapInit()
{
    // Shared script
    Ragemap2023::MapInit();

    // Example's part
    Ragemap2023Example::MapInit();
}

/**
 * Map activation handler.
 * @return void
 */
void MapActivate()
{
    // Shared script
    Ragemap2023::MapActivate();

    // Example's part
    Ragemap2023Example::MapActivate();
}
```

If you require multiple script files for your part additional parts should be included in **your** main script. Please try to keep your other scripts named so they are prefixed with your mapper tag. Do this just after the opening comment and before the namespace declaration:

```as
/**
 * Ragemap 2023: Example's part
 */

#include "example_misc"
#include "example_sound"

namespace Ragemap2023Example
{
    // ...
}
```

If you require one of the common/public scripts (e.g. custom weapons or Slogger weapon) include it in a nameless way as it may need to be used by more than one mapper as we did for Ragemap 2022.
