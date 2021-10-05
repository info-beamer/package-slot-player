# Slot Player

[![Import](https://cdn.infobeamer.com/s/img/import.png)](https://info-beamer.com/use?url=https://github.com/info-beamer/package-slot-player)

This package allows you to schedule slot based content across multiple players.

Slot based means that content is organized within slots of, for example, 10 seconds. Those
slots fill a time range configured for each day. For example from 10am in the morning to
8pm in the evening. For the provided example values, this would result in a total play
time of 10 hours. Each hour has 3600 seconds resulting in a total time of 36000 seconds
each day. As each slot is 10 seconds, each day has 3600 playback slots available.

Each content added to the package has a target slots/day value that indicates how
often the slot should play within each day. If the total number of configured slots/day
matches the available slots/day the number of playbacks will match almost exactly the
configured amount. If more content is scheduled than slots available, the number playbacks
will be reduced proportionally. Similarly if more slots are available than configured
content, each content will get more playbacks propotionally to its configured number of slots.

Configuration of the package can be done within the normal info-beamer UI itself. Additionally
the package also provides its own specialized web app that makes configuration a lot easier.

Click on the "Companion web app available" link in the setup's configuration screen to
open the app.

## Versions

### beta1

First release
