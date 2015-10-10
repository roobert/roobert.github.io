---
layout:     post
title:      Columned Graphite Data in InfluxDB
date:       2015-10-10 21:15
type:       post
---

For a long time now graphite has been the defacto standard for use as a time-series database, recently I decided to try InfluxDB, this blog post is about what I've found.

Installation and configuration of InfluxDB is as about as simple as it can get:

{% highlight bash %}
mbp0 /home/rw 2> dpkg -c tmp/influxdb_0.9.4.2_amd64.deb
drwx------ 0/0               0 2015-09-29 18:52 ./
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./usr/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./usr/share/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./usr/share/doc/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./usr/share/doc/influxdb/
-rw-r--r-- 0/0             142 2015-09-29 18:52 ./usr/share/doc/influxdb/changelog.Debian.gz
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./opt/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./opt/influxdb/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./opt/influxdb/versions/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./opt/influxdb/versions/0.9.4.2/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./opt/influxdb/versions/0.9.4.2/scripts/
-rw-rw-r-- 0/0             483 2015-09-29 18:51 ./opt/influxdb/versions/0.9.4.2/scripts/influxdb.service
-rwxrwxr-x 0/0            5759 2015-09-29 18:51 ./opt/influxdb/versions/0.9.4.2/scripts/init.sh
-rwxr-xr-x 0/0        11796648 2015-09-29 18:51 ./opt/influxdb/versions/0.9.4.2/influx
-rwxr-xr-x 0/0        17886048 2015-09-29 18:51 ./opt/influxdb/versions/0.9.4.2/influxd
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./etc/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./etc/opt/
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./etc/opt/influxdb/
-rw-rw-r-- 0/0            8414 2015-09-29 18:51 ./etc/opt/influxdb/influxdb.conf
drwxrwxr-x 0/0               0 2015-09-29 18:52 ./etc/logrotate.d/
-rw-rw-r-- 0/0             113 2015-09-29 18:51 ./etc/logrotate.d/influxd
{% endhighlight %}

Two binaries (client and daemon), init configuration, a configuration file, and a changelog. Great!

The out of the box configuration is good enough to get going with, however, InfluxDB has various listeners that enable the use of more primitive metric protocols such as graphite and collectd. I enabled the graphite listener:

{% highlight ini %}
[[graphite]]
  enabled = true
  bind-address = ":2003"
  protocol = "tcp"
{% endhighlight %}

Then configured `carbon-relay-ng` to relay metrics to InfluxDB:

{% highlight ini %}
[routes.influxdb]
patt = ""
addr = "influxdb:2003"
spool = true
pickle = false
{% endhighlight %}

With metrics now being relayed into InfluxDB it's time to create some queries:

{% highlight bash %}
mbp0 /opt/influxdb > /opt/infuxdb/bin/influx -database graphite
InfluxDB shell 0.9.4.2
> show measurements
name: measurements
------------------
name
metrics.net.server0.eth0.rx_bytes
metrics.net.server0.eth0.rx_dropped
metrics.net.server0.eth0.rx_errors
metrics.net.server0.eth0.rx_packets
metrics.net.server0.eth0.tx_bytes
metrics.net.server0.eth0.tx_dropped
metrics.net.server0.eth0.tx_errors
metrics.net.server0.eth0.tx_packets
...

> select * from "metrics.net.server0.eth0.rx_bytes"
name: metrics.net.server0.eth0.rx_bytes
-----------------------------------------
time                   value
2015-10-10T16:22:00Z   2.6120917495e+10
2015-10-10T16:24:20Z   2.6121235774e+10
2015-10-10T16:24:46Z   2.6121281251e+10
2015-10-10T16:24:50Z   2.6121288143e+10
2015-10-10T16:26:04Z   2.612146782e+10
{% endhighlight %}

But wait a minute, isn't this supposed to be a columnar database?

Reading more of the docs shows I need to add a 'template' to graphite so that the graphite data can be converted into tagged data, my graphite config now looks like this:

{% highlight bash %}
[[graphite]]
  enabled = true
  bind-address = ":2003"
  protocol = "tcp"
  templates = [ "metrics.net.* .measurement.host.interface.measurement" ]
{% endhighlight %}

This time I manually run the check from my local machine to generate some data:

{% highlight bash %}
mbp0 /home/rw/git/sensu-plugins master ✓ > ./metrics-net.rb --scheme metrics.$(hostname) | grep \\.eth0
metrics.net.mbp0.eth0.tx_packets 12412227 1444494023
metrics.net.mbp0.eth0.rx_packets 20782213 1444494023
metrics.net.mbp0.eth0.tx_bytes 1928577400 1444494023
metrics.net.mbp0.eth0.rx_bytes 26120684821 1444494023
metrics.net.mbp0.eth0.tx_errors 0 1444494023
metrics.net.mbp0.eth0.rx_errors 60 1444494023
metrics.net.mbp0.eth0.tx_dropped 0 1444494023
metrics.net.mbp0.eth0.rx_dropped 0 1444494023
mbp0 /home/rw/git/sensu-plugins master ✓ > ./metrics-net.rb --scheme test_metrics.net.mbp0 | grep --color=never \\.eth0 | nc influxdb 2003
mbp0 /home/rw/git/sensu-plugins master ✓ > 
{% endhighlight %}

Check the data in InfluxDB:
{% highlight bash %}
mbp0 /opt/influxdb > ./influx -database graphite
Connected to http://localhost:8086 version 
InfluxDB shell 0.9.4.2
> show measurements
name: measurements
------------------
name
net.rx_bytes
net.rx_dropped
net.rx_errors
net.rx_packets
net.tx_bytes
net.tx_dropped
net.tx_errors
net.tx_packets
> select * from "net.rx_bytes" limit 1
name: net.rx_bytes
------------------
time                   host   interface   value
2015-10-10T16:32:14Z   mbp0   eth0        2.612265085e+10
{% endhighlight %}

This looks better but the query shows that each metric is being written to the database as its own measurement with a single column called `value`. The `host` and `interface` columns here are infact tags, rather than fields.

Lets enable the `udp` listener and write some data to the database using InfluxDBs native [line protocol](https://influxdb.com/docs/v0.9/write_protocols/line.html).

`influxdb.conf`:
{% highlight bash %}
[[udp]]
  enabled = true
  bind-address = ":8087"
  database = "udp"
{% endhighlight %}

{% highlight bash %}
mbp0 /opt/influxdb > ./influx -execute 'create database udp'
mbp0 /opt/influxdb > echo 'test_measurement,host=localhost field1=1,field2=2,field3=3' | nc -u localhost 8087
^C
mbp0 /opt/influxdb > ./influx -database udp
Connected to http://localhost:8086 version 
InfluxDB shell 0.9.4.2
> show measurements
name: measurements
------------------
name
test_measurement

> select * from test_measurement
name: test_measurement
----------------------
time                             field1   field2   field3   host
2015-10-10T16:10:12.102611995Z   1        2        3        localhost

{% endhighlight %}

This is what we want, data stored in named fields.

It turns out that with the original storage engine _BZ1_ it's not only inefficient to do lookups on multiple field data, it's also not possible to add fields to a metric once it's been written to.

Fortunately I had some luck as the InfluxDB team were about to release their [new storage engine](https://influxdb.com/blog/2015/10/07/the_new_influxdb_storage_engine_a_time_structured_merge_tree.html) entitled _TSM1_. The new storage engine allows fields to be added to existing metrics in a database.

My [patch](https://github.com/influxdb/influxdb/commit/6bfb1ff11be733bd4aa70b35f6ccff2a5f02ab12) to enable a special keyword `field` has been merged into `master` and will be part of the 0.9.5 release. For now it's possible to use a [nightly](https://influxdb.com/download/index.html) build.

From a clean system, to get columnar graphite data in InfluxDB, do the following:

Install nightly (or > 0.9.5) InfluxDB build:

{% highlight bash %}
mbp0 /home/rw > wget https://s3.amazonaws.com/influxdb/influxdb_nightly_amd64.deb
--2015-10-10 17:56:54--  https://s3.amazonaws.com/influxdb/influxdb_nightly_amd64.deb
Resolving s3.amazonaws.com (s3.amazonaws.com)... 54.231.80.203
Connecting to s3.amazonaws.com (s3.amazonaws.com)|54.231.80.203|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 14714390 (14M) [application/x-debian-package]
Saving to: ‘influxdb_nightly_amd64.deb’

influxdb_nightly_amd64.deb           100%[=====================================================================>]  14.03M  4.68MB/s   in 3.0s   

2015-10-10 17:56:57 (4.68 MB/s) - ‘influxdb_nightly_amd64.deb’ saved [14714390/14714390]

mbp0 /home/rw > sudo dpkg -i influxdb_nightly_amd64.deb
Selecting previously unselected package influxdb.
(Reading database ... 270013 files and directories currently installed.)
Preparing to unpack influxdb_nightly_amd64.deb ...
Unpacking influxdb (0.9.5-nightly-f1e0c59) ...
Setting up influxdb (0.9.5-nightly-f1e0c59) ...
mbp0 /home/rw > 
{% endhighlight %}

Enable graphite listener with templates for each of your metrics, including special `field` keyword:

{% highlight ini %}
[[graphite]]
  enabled = true
  database = "graphite"
  bind-address = ":2003"
  protocol = "tcp"
  templates = [
    "metrics.net.* .measurement.host.interface.field"
  ]
{% endhighlight %}

Change storage engine to _TSM1_:

{% highlight bash %}
[data]
  engine ="tsm1"
{% endhighlight %}

Write some test data to InfluxDB:

{% highlight bash %}
mbp0 /home/rw/git/sensu-plugins master ✓ > ./metrics-net.rb --scheme metrics.net.mbp0 | grep --color=never \\.eth0 | nc localhost 2003
mbp0 /home/rw/git/sensu-plugins master ✓ > 
{% endhighlight %}

Validate configuration:

{% highlight bash %}
mbp0 /opt/influxdb > ./influx -database graphite
Connected to http://localhost:8086 version 0.9.5-nightly-f1e0c59
InfluxDB shell 0.9.5-nightly-f1e0c59
> show measurements
name: measurements
------------------
name
net

> select * from net
name: net
---------
time                host  interface rx_bytes          rx_dropped  rx_errors  rx_packets     tx_bytes         tx_dropped  tx_errors  tx_packets
1444497867000000000 mbp0  eth0      2.6229759902e+10  0           60         2.0903486e+07  1.947292214e+09  0           0          1.2501794e+07
{% endhighlight %}

Cool!
