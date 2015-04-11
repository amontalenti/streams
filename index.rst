===========
streamparse
===========

*Defeat the Python GIL with Apache Storm.*

Andrew Montalenti, CTO

.. rst-class:: logo

    .. image:: ./_static/parsely.png
        :width: 40%
        :align: right

==========
Background
==========

Me
==

- Hacking in Python for over a decade
- Exile of Wall Street programming in Java
- CTO/co-founder of Parse.ly
- Fully distributed team
- Python all the things

**@amontalenti** on Twitter:

http://twitter.com/amontalenti

What is Parse.ly?
=================

Web content analytics for digital storytellers.

Some of our customers:

.. image:: ./_static/parsely_customers.png
    :width: 98%
    :align: center

Elegant data dashboards
=======================

Informing thousands of editors and writers every day:

.. image:: ./_static/glimpse.png
    :width: 98%
    :align: center

Powerful data APIs
==================

Powering billions of site visits every month:

.. image:: ./_static/newyorker_related.png
    :width: 98%
    :align: center

What is Storm?
==============

.. image:: ./_static/storm_applied.png
    :width: 90%
    :align: center

Why should I care?
==================

- Defeat the GIL!
- Avoid Threads
- Horizontally Scale CPUs
- Built-in Data Reliability
- Log-Oriented Architecture
- Impress Your Friends

Python Can't Scale?
===================

Eat that:

.. image:: ./_static/cpu_cores.png
    :width: 90%
    :align: center

Motivating for streamparse
==========================

.. image:: ./_static/streamparse_logo.png

streamparse lets you parse real-time streams of data.

It smoothly integrates Python code with Apache Storm.

Easy quickstart, good CLI/tooling, production tested.

Good for: Analytics, Logs, Sensors, Low-Latency Stuff.

Agenda
======

* Why is time series data hard?
* How does Storm work?
* How does Python integrate with Storm?
* streamparse design
* pykafka preview

Admin
=====

Again, **@amontalenti** on Twitter.

I've scheduled a few tweets to go out during my talk
with links to all the stuff related to my talk:

- http://parse.ly/code
- http://parse.ly/slides/streamparse
- http://parse.ly/slides/streamparse/notes

========================
Time Series Data is Hard
========================

Velocity
========

Many posts get **millions of page views per hour**.

.. image:: ./_static/pulse.png
    :width: 60%
    :align: center

Volume
======

Top publishers write **1000's of posts per day**.

.. image:: ./_static/sparklines_multiple.png
    :width: 90%
    :align: center

Veracity
========

People need to **make decisions** based on our data:

.. image:: ./_static/comparative.png
    :width: 90%
    :align: center

=======================
From "workers" to Storm
=======================

Python GIL
==========

Python's GIL does not allow true multi-thread parallelism:

.. image:: _static/python_gil_new.png
    :align: center
    :width: 80%

And on multi-core, it even leads to lock contention:

.. image:: _static/python_gil.png
    :align: center
    :width: 80%

`@dabeaz`_ discussed this in a Friday talk on concurrency.

.. _@dabeaz: http://twitter.com/dabeaz

Queues and workers
==================

.. rst-class:: spaced

    .. image:: /_static/queues_and_workers.png
        :width: 70%
        :align: center

Standard way to solve GIL woes.

**Queues**: ZeroMQ => Redis => RabbitMQ

**Workers**: Cron Jobs => RQ => Celery

Parse.ly Architecture, 2012
===========================

.. image:: /_static/tech_stack.png
    :width: 90%
    :align: center


It started to get messy
=======================

.. image:: ./_static/monitors.jpg
    :width: 90%
    :align: center

As Hettinger Says...
====================

"There must be a better way..."

What is this Storm thing?
=========================

We read:

"Storm is a **distributed real-time computation system**."

"Great," we thought. "But, what about Python support?"

Hmm... we'll get there.

First, Some Storm Concepts
==========================

Storm provides an abstraction for cluster computing:

- Tuple
- Spout
- Bolt
- Topology
- Stream
- Grouping
- Parallelism

Wired Topology
==============

.. rst-class:: spaced

    .. image:: ./_static/topology.png
        :width: 80%
        :align: center

WARNING
=======

All the code in the following 7 slides is pseudocode.

"Mock" version of Storm using Python coroutines.

**It's just meant to illustrate Storm ideas.**

Tuple
=====

A single data record that flows through your cluster.

.. sourcecode:: python

    # tuple spec: ["word"]
    word = ("dog",)
    # tuple spec: ["word", "count"]
    word_count = ("dog", 4)

Spout
=====

A component that emits raw data into cluster.

.. sourcecode:: python

    class Spout(object):
        def next_tuple():
            """Called repeatedly to emit tuples."""

    @coroutine
    def spout_coroutine(spout, target):
        """Get tuple from spout and send it to target."""
        while True:
            tup = spout.next_tuple()
            if tup is None:
                time.sleep(10)
                continue
            if target is not None:
                target.send(tup)

Bolt
====

A component that implements one processing stage.

.. sourcecode:: python

    class Bolt(object):
        def process(tuple):
            """Called repeatedly to process tuples."""

    @coroutine
    def bolt_coroutine(bolt, target):
        """Get tuple from input, process it in Bolt.
           Then send it to next bolt target, if it exists."""
        while True:
            tup = (yield)
            if tup is None:
                time.sleep(10)
                continue
            to_emit = bolt.process(tup)
            if target is not None:
                target.send(to_emit)

Topology
========

Directed Acyclic Graph (DAG) describing it all.

.. sourcecode:: python

    # lay out topology
    spout = Words
    bolts = [WordCount, DebugPrint]

    # init components
    spout = init(spout)
    bolts = [init(bolt) for bolt in bolts]

    # wire topology
    topology = wire(spout=spout, bolts=bolts)

    # start the topology
    next(topology)

Streams, Grouping, Parallelism
==============================

(still pseudocode)

.. sourcecode:: python

    class WordCount(Topology):
        name = "word-count-topology"
        spouts = [
            Words(name="word-spout", out=["word"], p=4)
        ]
        bolts = [
            WordCount(name="word-count-bolt",
                      from=Words,
                      group_on="word",
                      out=["word", "count"],
                      p=8),
            DebugPrint(name="debug-print-bolt",
                       from=WordCount,
                       p=1)
        ]

Wired Topology
==============

.. rst-class:: spaced

    .. image:: ./_static/topology.png
        :width: 80%
        :align: center

Tuple Tree
==========

.. rst-class:: spaced

    .. image:: ./_static/wordcount.png
        :width: 70%
        :align: center

Running in Storm UI
===================

.. rst-class:: spaced

    .. image:: ./_static/storm_ui.png
        :width: 98%
        :align: center

Running in Storm Cluster
========================

.. rst-class:: spaced

    .. image:: ./_static/storm_cluster.png
        :width: 80%
        :align: center

Workers and Empty Slots
=======================

.. rst-class:: spaced

    .. image:: ./_static/storm_slots_empty.png
        :width: 90%
        :align: center

Filled Slots and Rebalancing
============================

.. rst-class:: spaced

    .. image:: ./_static/storm_slots_filled.png
        :width: 90%
        :align: center

BTW, Buy This Book!
===================

Storm Applied, by Manning Press.

Reviewed in `Storm, The Big Reference`_.

.. image:: ./_static/storm_applied.png
    :width: 50%
    :align: center

.. _Storm, The Big Reference: http://blog.parsely.com/post/1271/storm/

Network Transfer of Tuples
==========================

.. rst-class:: spaced

    .. image:: ./_static/storm_transfer.png
        :width: 90%
        :align: center

Bolts May Have Side Effects
===========================

.. rst-class:: spaced

    .. image:: ./_static/storm_data.png
        :width: 80%
        :align: center

So, Storm is Sorta Amazing!
==========================

Storm...

- allocates **Python process slots** on physical nodes
- handles **lightweight queuing automatically**
- does **tuneable parallelism** per component
- will **guarantee processing** of tuples with ack/fail
- implements a **high availability** model
- helps us **rebalance computation** across cluster

And, it **beats the GIL**!

Let's Do This!
==============

.. image:: ./_static/cpu_cores.png
    :width: 90%
    :align: center

================
Java: Womp, Womp
================

Storm is "Javanonic"
====================

Ironic term one of my engineers came up with for a project that feels very
Java-like, and not very "Pythonic".

Storm Java Quirks
=================

- Topologies specified using a Java builder interface (eek).
- Topologies built from CLI using Maven tasks (yuck).
- Topology submission needs a JAR of your code (ugh).
- No simple interactive or local dev workflow built-in (boo).
- Talking to the Storm cluster uses Thrift interfaces (shrug).

Java Projects Need Not Stink
============================

Consider Cassandra, Zookeeper, or Elasticsearch.

These aren't "projects for Java developers".

They are "cross-language system infrastructure..."

"... that happens to be written in Java."

Storm as Infrastructure
=======================

One would hope that Storm could attain this same status.

That is: **multi-lang real-time computation infrastructure.**

Not: **Java real-time computation (some multi-lang support).**

Where Python is a **first-class citizen**.

(Storm can solve the GIL at the system level!)

===========================
Getting Pythonic with Storm
===========================

Python Processes
================

For a Python programmer, Storm provides a way to get **process-level
parallelism**, while...

- avoiding perils of multi-threading
- escaping single-node limit of process pools
- dodging the complexity of workers-and-queues

Multi-Lang Protocol (1)
=======================

Storm supports Python through the **multi-lang protocol**.

- JSON protocol
- Works via shell-based components
- Communicate over ``STDIN`` and ``STDOUT``

Kinda quirky, but also relatively simple to implement.

Multi-Lang Protocol (2)
=======================

Each component of a "Python" Storm topology is either:

- ``ShellSpout``
- ``ShellBolt``

Java implementations speak to Python via light JSON.

There's **one sub-process per Storm task**.

If ``p = 8``, then **8 Python processes** are spawned.

Multi-Lang Protocol (3)
=======================

- Tuples serialized by Storm worker into JSON
- Sent over ``STDIN`` to components
- Storm worker parses JSON sent over ``STDOUT``
- Then sends it to appropriate downstream tasks
- This is the Netty/ZeroMQ mechanism

Multi-Lang Protocol (4)
=======================

All "core" Storm mechanics supported:

- ack
- fail
- emit
- anchor
- log
- heartbeat
- tuple tree

Packaging for Multi-Lang
========================

Uses JARs.

"Copy 'storm.py' into your CLASSPATH."

Ugh.

"Javanonic."

streamparse fixes this.

Biggest storm.py issues
=======================

- No unit tests
- No documentation
- No local dev workflow
- ``print`` statement breaks topology
- Cannot ``pip install``
- Packaging is a nightmare

"What if we had a Pythonic Storm lib?"
======================================

- Idea was brewing on Parse.ly team in Jan 2014.
- Backend team had just grown up, new engineers.
- New engineers had trouble with Storm.
- I discovered ``storm-test`` and ``Clojure DSL``.
- Colleague started a clean-house IPC layer.

Enter streamparse
=================

0.1 release at PyData Silicon Valley 2014 in Apr 2014.

Talk, `"Real-Time Streams and Logs"`_, introduced it.

600+ stars `on Github`_, was a trending repo in May 2014.

90+ mailing list members and 5 new committers.

3 Parse.ly engineers started maintaining it.

Funding `from DARPA`_ to continue developing it. (Yes, really!)

.. _"Real-Time Streams and Logs": https://www.youtube.com/watch?v=od8U-XijzlQ
.. _on Github: https://github.com/Parsely/streamparse
.. _from DARPA: http://www.fastcompany.com/3040363/the-future-of-search-brought-to-you-by-the-pentagon

streamparse CLI
===============

``sparse`` provides a CLI front-end to ``streamparse``, a framework for
creating Python projects for running, debugging, and submitting Storm
topologies for data processing.

After installing the ``lein`` (only dependency), you can run::

    pip install streamparse

This will offer a command-line tool, ``sparse``. Use::

    sparse quickstart

Running and debugging
=====================

You can then run the local Storm topology using::

    $ sparse run
    Running wordcount topology...
    Options: {:spec "topologies/wordcount.clj", ...}
    #<StormTopology StormTopology(spouts:{word-spout=...
    storm.daemon.nimbus - Starting Nimbus with conf {...
    storm.daemon.supervisor - Starting supervisor with id 4960ac74...
    storm.daemon.nimbus - Received topology submission with conf {...
    ... lots of output as topology runs...

streamparse vs storm.py
=======================

.. image:: _static/streamparse_comp.png
    :align: center
    :width: 80%

Word Stream Spout (Storm DSL)
=============================

.. sourcecode:: clojure

    {"word-spout" (python-spout-spec
          options
          "spouts.words.WordSpout"
          ["word"]
          )
    }

Word Stream Spout in Python
===========================

.. sourcecode:: python

    import itertools

    from streamparse.spout import Spout

    class WordSpout(Spout):

        def initialize(self, conf, ctx):
            self.words = itertools.cycle(['dog', 'cat',
                                          'zebra', 'elephant'])

        def next_tuple(self):
            word = next(self.words)
            self.emit([word])

Word Count Bolt (Storm DSL)
===========================

.. sourcecode:: clojure

    {"count-bolt" (python-bolt-spec
            options
            {"word-spout" :shuffle}
            "bolts.wordcount.WordCount"
             ["word" "count"]
             :p 2
           )
    }

Word Count Bolt in Python
=========================

.. sourcecode:: python

    from collections import Counter

    from streamparse.bolt import Bolt

    class WordCounter(Bolt):

        def initialize(self, conf, ctx):
            self.counts = Counter()

        def process(self, tup):
            word = tup.values[0]
            self.counts[word] += 1
            self.emit([word, self.counts[word]])
            self.log('%s: %d' % (word, self.counts[word]))

streamparse config.json
=======================

.. sourcecode:: javascript

    {
        "topology_specs": "topologies/",
        "envs": {
            "0.8": {
                "user": "ubuntu",
                "nimbus": "storm-head.ec2-ubuntu.com",
                "workers": ["storm1.ec2-ubuntu.com",
                            "storm2.ec2-ubuntu.com"],
                "log_path": "/var/log/ubuntu/storm",
                "virtualenv_root": "/data/virtualenvs"
            },
            "vagrant": {
                "user": "ubuntu",
                "nimbus": "vagrant.local",
                "workers": ["vagrant.local"],
                "log_path": "/home/ubuntu/storm/logs",
                "virtualenv_root": "/home/ubuntu/virtualenvs"
            }
        }
    }

streamparse projects
====================

.. image:: ./_static/streamparse_project.png
    :width: 90%
    :align: center

sparse options
==============

.. sourcecode:: text

    $ sparse help

    Usage:
            sparse quickstart <project_name>
            sparse run [-o <option>]... [-p <par>] [-t <time>] [-dv]
            sparse submit [-o <option>]... [-p <par>] [-e <env>] [-dvf]
            sparse list [-e <env>] [-v]
            sparse kill [-e <env>] [-v]
            sparse tail [-e <env>] [--pattern <regex>]
            sparse (-h | --help)
            sparse --version

BatchingBolt
============

.. sourcecode:: python

    from streamparse.bolt import BatchingBolt

    class WordCounterBolt(BatchingBolt):

        secs_between_batches = 5

        def group_key(self, tup):
            # collect batches of words
            word = tup.values[0]
            return word

        def process_batch(self, key, tups):
            # emit the count of words we had per 5s batch
            self.emit([key, len(tups)])

Use cases for BatchingBolt
==========================

We use for writing to data stores:

- Cassandra
- Elasticsearch
- Redis
- MongoDB

Background thread handles tuple grouping and timer thread for flushing batches.

Adds **reliable micro-batching** to Storm.

===============
pykafka preview
===============

Apache Kafka
============

"Messaging rethought as a commit log."

Distributed ``tail -f``.

Perfect fit for Storm Spouts.

Able to keep up with Storm's high-throughput processing.

Great for handling backpressure during traffic spikes.

Kafka and Multi-consumer
========================

.. image:: ./_static/multiconsumer.png
    :width: 60%
    :align: center

Kafka Consumer Groups
=====================

.. image:: ./_static/consumer_groups.png
    :width: 60%
    :align: center

pykafka
=======

We have released ``pykafka``.

NOT to be confused with ``kafka-python``.

Upgraded internal Kafka 0.7 driver to 0.8.2:

- SimpleConsumer **and** BalancedConsumer
- Consumer Groups with Zookeeper
- Pure Python protocol implementation
- C protocol implementation in works (via librdkafka)

https://github.com/Parsely/pykafka

========================
Sprinting on streamparse
========================

Python Topology DSL?
====================

"What I'm proposing instead is to ditch the idea of specifying topologies via
configuration files and do it instead via an interpreted general purpose
programming language (like Python)."

Comments recently by Nathan Marz in `STORM-561`_.

.. _STORM-561: https://issues.apache.org/jira/browse/STORM-561

I really want to build this...
==============================

and, you can help!

Questions?
==========

Check out streamparse on Github.

I'm here at sprints Monday and Tuesday.

Parse.ly's hiring: http://parse.ly/jobs

Find me on Twitter: http://twitter.com/amontalenti

Fin
===

.. image:: ./_static/big_diagram.png
    :width: 80%
    :align: center

========
Appendix
========

Organizing Around Logs
======================

.. image:: ./_static/streamparse_reference.png
    :width: 90%
    :align: center

Multi-Lang Impl's in Python
===========================

- `storm.py`_ (Storm, 2010)
- `Petrel`_ (AirSage, Dec 2012)
- `streamparse`_ (Parse.ly, Apr 2014)
- `pyleus`_ (Yelp, Oct 2014)

Plans to unify IPC implementations around **pystorm**.

.. _storm.py: https://github.com/apache/storm/blob/master/storm-core/src/multilang/py/storm.py
.. _Petrel: https://github.com/AirSage/Petrel
.. _pyleus: https://github.com/Yelp/pyleus
.. _streamparse: http://github.com/Parsely/streamparse

Other Related Projects
======================

- `lein`_ - Clojure dependency manager used by streamparse
- `flux`_ - YAML Topology runner
- `Clojure DSL`_ - Topology DSL, bundled with Storm
- `Trident`_ - Java "high-level" DSL, bundled with Storm

streamparse uses lein and a simplified Clojure DSL.

Will add a Python DSL in 2.x.

.. _lein: http://leiningen.org/
.. _flux: https://github.com/ptgoetz/flux
.. _Clojure DSL: http://storm.apache.org/documentation/Clojure-DSL.html
.. _Trident: https://storm.apache.org/documentation/Trident-tutorial.html
.. _marceline: https://github.com/yieldbot/marceline
.. _@Parsely: http://twitter.com/Parsely
.. _@amontalenti: http://twitter.com/amontalenti

Topology Wiring
===============

.. sourcecode:: python

    def wire(spout, bolts=[]):
        """Wire the components together in a pipeline.
        Return the spout coroutine that kicks it off."""
        last, target = None, None
        for bolt in reversed(bolts):
            step = bolt_coroutine(bolt)
            if last is None:
                last = step
                continue
            else:
                step = bolt_coroutine(bolt, target=last)
                last = step
        return spout_coroutine(spout, target=last)


.. raw:: html

    <script type="text/javascript">
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-5989141-8']);
    _gaq.push(['_setDomainName', '.parsely.com']);
    _gaq.push(['_trackPageview']);

    (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        //ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        ga.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'stats.g.doubleclick.net/dc.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
    </script>

.. ifnotslides::

    .. raw:: html

        <script>
        $(function() {
            $("body").css("width", "1080px");
            $(".sphinxsidebar").css({"width": "200px", "font-size": "12px"});
            $(".bodywrapper").css("margin", "auto");
            $(".documentwrapper").css("width", "880px");
            $(".logo").removeClass("align-right");
        });
        </script>

.. ifslides::

    .. raw:: html

        <script>
        $("tr").each(function() {
            $(this).find("td:first").css("background-color", "#eee");
        });
        </script>
