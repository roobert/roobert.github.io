---
layout:     post
title:      Sensu - Embedded Graphite Graphs
date:       2014-11-03 21:15
type:       post
---

Earlier this year I saw a [great talk](http://www.youtube.com/watch?v=Q9BagdHGopg) entitled <i>Please stop using Nagios (so it can die peacefully)</i>. After I'd finished laughing and picked myself up off the floor, I deployed [Sensu](http://sensuapp.com) and immediately loved it.

Months later and I'm now experimenting with replacing the existing nagios monitoring system we use at [my new job](http://brandwatch.com) with Sensu.

## Uchiwa

One of the things I thought would be useful would be to have graphs embedded in the wonderful [Uchiwa](http://uchiwa.io) dashboard. It turns out I'm not alone because the author of Uchiwa ([Simon Palourde](http://github.com/palourde)) has plans to add support for embedding graphite graphs into Uchiwa natively. Until then, it's still possible to get some lovely graph action going on by taking advantage of the fact Uchiwa will:

0. display any extra properties you add to the client config JSON or check config JSON in the UI
0. render images

Uchiwa decides what to display as an image depending on file extension type. Adding a fake argument to our graphite query tricks Uchiwa into displaying the image returned by the query inline, instead of as a link to the graph:

{% highlight bash %}
&uchiwa_force_display_as_image=.jpg
{% endhighlight %}

## Graphite

I want to be able to see CPU and Memory usage for each machine when I click on the machine view. My graphite queries look like:

{% highlight bash %}
https://graphite.brandwatch.com/render \
  ?from=-12hours \
  &until=now \
  &width=500 \
  &height=200 \
  &target=collectd.<hostname>.aggregation-cpu-average.cpu-system.value

https://graphite.brandwatch.com/render \
  ?from=-12hours \
  &until=now \
  &width=500 \
  &height=200 \
  &target=collectd.<hostname>.memory.memory-used.value \
  &target=collectd.<hostname>.memory.memory-cached.value \
  &target=collectd.<hostname>.memory.memory-free.value \
  &target=collectd.<hostname>.memory.memory-buffered.value
{% endhighlight %}

## Putting it Together..

{% assign ansible_hostname = '{{ ansible_hostname }}' %}

Add the queries to the client config. It's necessary to encode the single quotes (%27) and since I'm using [Ansible](http://ansible.com) to distribute the Sensu configuration, I've used `{{ ansible_hostname }}` in place of the `hostname` in each metric key.

{% highlight json %}
{% raw %}
{
   "client": {
      "name": "{{ sensu_client_hostname }}",
      "address": "{{ sensu_client_address }}",
      "subscriptions": subscriptions,
      "graphite_cpu": "https://graphite.brandwatch.com/render?from=-12hours&until=now&width=500&height=200&target=collectd.{{ ansible_hostname }}.aggregation-cpu-average.cpu-system.value&uchiwa_force_image=.jpg",
      "graphite_mem": "https://graphite.brandwatch.com/render?from=-12hours&until=now&width=500&height=200&target=collectd.{{ ansible_hostname }}.memory.memory-used.value&target=collectd.{{ ansible_hostname }}.memory.memory-cached.value&target=collectd.{{ ansible_hostname }}.memory.memory-free.value&target=collectd.{{ ansible_hostname }}.memory.memory-buffered.value&uchiwa_force_image=.jpg"
   }
}
{% endraw %}
{% endhighlight %}

## The Result

![sensu_embedded_graph0](https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/sensu_embedded_graph0.png)

## Going Further..

Checks can also have arbitrary properties so it's also possible to add queries to the check definitions and have them appear in the check view of Uchiwa.

Next up: [adding events to graphite graphs with Sensu.](http://roobert.github.io/2014/11/08/Sensu-Events-and-Graphite-Graphs/)
