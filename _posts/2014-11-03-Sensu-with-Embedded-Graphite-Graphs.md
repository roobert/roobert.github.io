---
layout:     post
title:      Sensu - Embedded Graphite Graphs
date:       2014-11-03 21:15
summary:
categories: sensu monitoring graphite graphing events
---

Earlier this year I saw a [great talk](with://www.youtube.com/watch?v=Q9BagdHGopg) entitled "Please stop using Nagios (so it can die peacefully)". After I'd picked myself up off the floor and finished laughing, I deployed [Sensu](http://sensuapp.com) and immediately loved it.

Months later and I'm now experimenting with replacing the existing nagios monitoring system we use at [my new job](http://brandwatch.com) with Sensu.

One of the things I thought would be useful would be having graphs embedded in the wonderful [Uchiwa](http://uchiwa.io) dashboard. It turns out I'm not alone. The author of Uchiwa ([Simon Palourde](http://github.com/palourde)) plans to add support for embedding graphite graphs into Uchiwa natively. Until then, it's still possible to get some lovely graph action going on by taking advantage of the fact Uchiwa will 1) display any extra properties you add to the client config JSON or check config JSON in the UI, and 2) will render images.

# CPU and Memory Queries

I want to be able to see CPU and Memory usage for each machine when I click on the machine view. My graphite queries look like:

{% highlight json %}
https://graphite.brandwatch.com/render?from=-12hours&until=now&width=500&height=200&target=collectd.<hostname>.aggregation-cpu-average.cpu-system.value
https://graphite.brandwatch.com/render?from=-12hours&until=now&width=500&height=200&target=collectd.<hostname>.memory.memory-used.value&target=collectd.<hostname>.memory.memory-cached.value&target=collectd.<hostname>.memory.memory-free.value&target=collectd.<hostname>.memory.memory-buffered.value
{% endhighlight %}

Uchiwa decides what to display as an image depending on file extension type. Simply adding a fake argument to our graphite query tricks Uchiwa into displaying our image inline instead of a link to the graph:

{% highlight json %}
&uchiwa_force_display_as_image=.jpg
{% endhighlight %}

Now we can add this to the client config. It's necessary to encode the single quotes (%27) and since I'm using ansible to distribute the Sensu configuration, I've used `{{ ansible_hostname }}` in place of the `hostname` in the metric key.

{% highlight json %}
{
   "client": {
      "name": "{{ sensu_client_hostname }}",
      "address": "{{ sensu_client_address }}",
      "subscriptions": [ "{{ "\",\"".join(sensu_client_subscription_names) }}" ],
      "graphite_cpu": "https://graphite.brandwatch.com/render?from=-12hours&until=now&width=500&height=200&target=collectd.{{ ansible_hostname }}.aggregation-cpu-average.cpu-system.value&target=drawAsInfinite(events(%27{{ ansible_hostname }}%27,%27check-cpu%27,%27ok%27))&target=drawAsInfinite(events(%27{{ ansible_hostname }}%27,%27check-cpu%27,%27warning%27))&target=drawAsInfinite(events(%27{{ ansible_hostname }}%27,%27check-cpu%27,%27critical%27))&uchiwa_force_image=.jpg",
      "graphite_mem": "https://graphite.brandwatch.com/render?from=-12hours&until=now&width=500&height=200&target=collectd.{{ ansible_hostname }}.memory.memory-used.value&target=collectd.{{ ansible_hostname }}.memory.memory-cached.value&target=collectd.{{ ansible_hostname }}.memory.memory-free.value&target=collectd.{{ ansible_hostname }}.memory.memory-buffered.value&uchiwa_force_image=.jpg"
   }
}
{% endhighlight %}

And see the result:

..image..

It's also possible to add properties to checks so we can embed graphs in the check ection view of the UI:

..image..