---
layout:     post
title:      Sensu - Events and Graphite Graphs
date:       2014-11-08 11:05
type:       post
---

## Graphite

I learnt from jdixons [obfuscurity blog](http://obfuscurity.com/2014/01/Graphite-Tip-A-Better-Way-to-Store-Events) that Graphite has a little known feature called <strong><i>Events</i></strong> that can, unsurprisingly, be used to store events in Graphite.

Since Sensu/Uchiwa don't have any way to see event history, I thought it would be nice to be able to see check events on related graphs, for example: CPU {<span class='red'>WARN</span>,<span class='orange'>CRIT</span>,<span class='green'>OK</span>} on the CPU usage graph. 

In order to pipe Sensu events into Graphite, I wrote a simple handler plugin that POSTs all Sensu events to the Graphite Events URI.

The following is a short write-up of how to get going with Sensu events and Graphite.

### Graphite Events

First, test to see if it's possible to write to the Graphite Events URI. Unlike [writing data to carbon](http://graphite.readthedocs.org/en/latest/feeding-carbon.html), the Events URI expects `json`:

{% highlight bash %}
curl --insecure \
  -X POST \
  https://graphite.brandwatch.com:443/events/ \
  -d '{"what": "test", "tags" : "test"}'
{% endhighlight %}

The event should appear in the Graphite event list:

![graphite event test](https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/graphite_events0.png)

Next, test to see if the event is retrievable:

{% highlight bash %}
curl "https://graphite.brandwatch.com/render \
  ?from=-12hours \
  &until=now \
  &width=500 \
  &height=200 \
  &target=drawAsInfinite(events('test'))"
{% endhighlight %}

Note: Since the event has no Y value, `drawAsInfinite()` is used to extend the X value (time) vertically so that the event is displayed as a vertical bar on the graph:

![graphite event test](https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/sensu_events2.png)

## Sensu

Now to get Sensu check events into Graphite.

### Handler

Install the [handler](http://sensuapp.org/docs/0.14/adding_a_handler) on your Sensu server, adjusting the `graphite_event.json` config if necessary:
{% highlight bash %}
git clone \
  https://github.com/roobert/sensu_handler_graphite_event.git

cp sensu_handler_graphite_event/graphite_event.json \
  /etc/sensu/conf.d/

cp sensu_handler_graphite_event/graphite_event.rb \
  /etc/sensu/handlers/

sudo service sensu-server restart
{% endhighlight %}

### Events

In my [last post](http://roobert.github.io/2014/11/03/Sensu-with-Embedded-Graphite-Graphs/), I talked about how to embed Graphite graphs in the Uchiwa UI and used a CPU Graphite query as an example. This is the same query except that I've added the `events` targets:

{% highlight bash %}
curl "https://graphite.brandwatch.com/render \
  ?from=-12hours \
  &until=now \
  &width=500 \
  &height=200 \
  &target=collectd.<hostname>.aggregation-cpu-average.cpu-system.value \
  &target=drawAsInfinite(events('sugar', 'check-cpu', 'ok')) \
  &target=drawAsInfinite(events('sugar', 'check-cpu', 'warning')) \
  &target=drawAsInfinite(events('sugar', 'check-cpu', 'critical'))"
{% endhighlight %}

Here's the result of the above query, displaying two events at about 6pm. Note that the graph time period is such that the <span class='red'>CRITICAL</span> and <span class='green'>OK</span> events are practically overlapping:

![sensu events](https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/sensu_events4.png)

Here are the same two events displayed on a graph with a much lower query window (1 hour):

![sensu events](https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/sensu_events3.png)

Finally, update the Sensu `client.json` with the new query:

{% highlight json %}
{% raw %}
{
   "client": {
      "name": "{{ sensu_client_hostname }}",
      "address": "{{ sensu_client_address }}",
      "subscriptions": subscriptions,
      "graphite_cpu": "https://graphite.brandwatch.com/render?from=-12hours&until=now&width=500&height=200&target=collectd.{{ ansible_hostname }}.aggregation-cpu-average.cpu-system.value&target=drawAsInfinite(events(%27{{ ansible_hostname }}%27,%27check-cpu%27,%27ok%27))&target=drawAsInfinite(events(%27{{ ansible_hostname }}%27,%27check-cpu%27,%27warning%27))&target=drawAsInfinite(events(%27{{ ansible_hostname }}%27,%27check-cpu%27,%27critical%27))&uchiwa_force_image=.jpg"
   }
}
{% endraw %}
{% endhighlight %}

Result:

![graphite with events in uchiwa](https://raw.githubusercontent.com/roobert/roobert.github.io/master/images/sensu_events1.png)
