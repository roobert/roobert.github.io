---
layout:     post
title:      Sensu - Host Masquerading
date:       2015-01-08 21:15
type:       post
---

A key part of monitoring infrastructure involves having the ability to monitor things that we can't necessarily install a monitoring client on: switches and other network devices, external services and websites, etc..

In Nagios it's pretty common to group active checks under virtual hosts that don't really exist to create logical sets of checks. Sensu doesn't yet have this ability.

There has been some discussion about the possibility of [adding a masquerade feature](https://github.com/sensu/sensu/pull/531) and changing event data to [drop the client info requirement](https://github.com/sensu/sensu/issues/541) in order to be able to craft event data with a custom source address. In the latter issue [Kyle Anderson](https://github.com/solarkennedy) proposes a [solution](https://github.com/sensu/sensu/issues/541#issuecomment-52221429) which was at one point [implemented](https://github.com/portertech/sensu/commit/335f83aae646753a517dcba1a7dcbc22d7a47aa8) but then later [reverted](https://github.com/sensu/sensu/pull/794).

I applied Kyles patch to my Sensu `server.rb` and configured a set of checks with the `:source` attribute. My check data then contained a modified source and my handlers sent messages with the modified event data. Great! Unfortunately though, the new event data wasn't accessible through the API. I emailed Kyle for advice and he kindly created [this issue](https://github.com/Yelp/sensu/issues/1).

In order for clients to be visible in the Uchiwa frontend we need to fix `sensu-api`. After looking at the [API code](https://github.com/sensu/sensu/blob/master/lib/sensu/api.rb#L306) and trying a few things I eventually decided to try simply [duplicating the original client data](https://github.com/roobert/sensu/commit/f50ceffb82fc1c3be9ac7b29df06e53af34c83c6#diff-b1352d95ed2d2b3454a9cbf22e47a38aR385) in Redis.

Duplicating the client data works well since it will get updated each time an event is processed. Each event includes a `timestamp` property that `sensu-server` uses to [calculate the keepalive](https://github.com/sensu/sensu/blob/master/lib/sensu/server.rb#L585) for each server. What this means is that our masqueraded host behaves exactly like a real host and all functionality in the `sensu-api` (and as a result, the Uchiwa frontend) behaves as expected.
