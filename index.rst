===========
streamparse
===========

A Pythonista navigating Stormy waters.

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

Admin
=====

Again, **@amontalenti** on Twitter.

I've scheduled a few tweets to go out during my talk
with links to all the stuff related to my talk:

- http://parse.ly/code
- http://parse.ly/slides/streamparse
- http://parse.ly/slides/streamparse/notes

Agenda
======

* Why is time series data hard?
* How does Storm work?
* How does Python integrate with Storm?
* stremaparse design and internals
* Logs and Kafka (pykafka preview)

==========================
Time Series Data Challenge
==========================

Velocity
========

Average post has **<48-hour shelf life**.

.. image:: ./_static/pulse.png
    :width: 60%
    :align: center

Volume
======

Top publishers write **1000's of posts per day**.

.. image:: ./_static/sparklines_multiple.png
    :align: center

Timeline Aggregation
====================

.. image:: ./_static/sparklines_stacked.png
    :align: center

Rollups and Summaries
=====================

.. image:: ./_static/summary_viz.png
    :align: center

Rankings and Sparklines
=======================

.. image:: ./_static/comparative.png
    :align: center

Benchmarks
==========

.. image:: ./_static/benchmarked_viz.png
    :align: center

=======================
From "workers" to Storm
=======================

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

Organizing Around Logs
======================

.. image:: ./_static/streamparse_reference.png
    :width: 90%
    :align: center

What is this Storm thing?
=========================

We read:

"Storm is a **distributed real-time computation system**."

"Great," we thought. "But, what about Python support?"

Hmm...

Storm Concepts
==============

Storm provides an abstraction for cluster computing:

- Tuple
- Spout
- Bolt
- Stream
- Topology

Wired Topology
==============

.. rst-class:: spaced

    .. image:: ./_static/topology.png
        :width: 80%
        :align: center

WARNING
=======

All the code in the following 5 slides or so is pseudocode.

**Just meant to illustrate Storm ideas.**

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

A source of tuples emitted into a cluster.

.. sourcecode:: python

    # spout spec: "word-spout"
    while num_tuples < max_num_tuples:
        one_tuple = kafka.get()
        storm.emit(one_tuple, "word-count-bolt")
        time.sleep(1)

Bolt
====

A processing node in your cluster's computation.

.. sourcecode:: python

    # bolt spec: "first-bolt"
    while True:
        word = storm.recv("word-spout")
        word_count = word_count_bolt.process(word)
        storm.ack(word)
        storm.emit(word_count, "debug-print-bolt")
        time.sleep(1)

Stream
======

A flow of tuples between two components (Bolts or Spouts).

.. sourcecode:: python

    stream_spec = ["word", "count"]:
    stream_wiring = ("first-spout",
                     # =>
                     "first-bolt")
    stream_grouping = "word" # or, ":shuffle"

Topology
========

Directed Acyclic Graph (DAG) describing it all.

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
                      p=8)
            DebugPrint(name="debug-print-bolt",
                       from=WordCount,
                       p=1)
        ]

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

TODO: change blog post link

.. _Storm, The Big Reference: http://parse.ly


Network Transfer of Tuples
==========================

.. rst-class:: spaced

    .. image:: ./_static/storm_transfer.png
        :width: 90%
        :align: center

Finally, Persist Your Calculations
==================================

.. rst-class:: spaced

    .. image:: ./_static/storm_data.png
        :width: 80%
        :align: center


So, Storm is Sorta Amazing!
==========================

Storm will:

- allocate Python process slots on physical nodes
- map a computation DAG onto those slots automatically
- guarantee processing of tuples with an ack/fail model
- let us rebalance computation evenly among nodes

Beat the GIL and scale Python horizontally with ease!

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

===========================
Getting Pythonic with Storm
===========================

Python Processes
================

For a Python programmer, Storm provides a way to get **process-level
parallelism** while avoiding the perils of multi-threading.

Sweet!

This is like Celery, RQ, multiprocessing, joblib, but with the added benefit of
**data flows** and **reliability**.

We'll take it!

Multi-Lang Protocol (1)
=======================

Storm supports multiple languages through the **multi-lang protocol**.

JSON protocol that works via shell-based components that communicate over
``STDIN`` and ``STDOUT``.

Kinda quirky, but also relatively simple to implement.

Multi-Lang Protocol (2)
=======================

Each component of a Storm topology is either a ``ShellSpout`` or ``ShellBolt``.

Storm worker invokes **one sub-process per shell component per Storm task**.

If ``p = 8``, then 8 Python processes are spawned under a worker.

Multi-Lang Protocol (3)
=======================

Storm Tuples are serialized by Storm worker process into JSON, sent over
``STDIN`` to components.

Storm worker process also parses JSON output sent over ``STDOUT`` and then
sends it to appropriate downstream tasks via Netty/ZeroMQ mechanism.

All non-Trident mechanics supported: tuple tree, ack/fail.

Packaging for Multi-Lang
========================

Java topologies are simply added to the classpath and appropriate Storm
classes are instantiated.

Multi-Lang uses the ``/resources`` path in the JAR.

Storm will explode ``/resources`` into a scratch area and code will be run out
of there.

When using the bundled module, you **copy-paste** ``storm.py`` adapter in
your ``/resources`` directory and ``import storm`` to speak the protocol.

Very Javanonic.

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

80+ mailing list members and 4 new committers.

Two Parse.ly engineers maintaining it.

Major corporate and academic entities using it.

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

Word Stream Spout (Storm)
=========================

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

Word Count Bolt (Storm)
=======================

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

config.json
===========

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

But wait, there's more!
=======================

Got it into production in the summer of 2014.

The effort just snowballed from there.

Added a lot more functionality to the CLI tools.

IPC layer saw Pythonic improvements.

Better support for logging.

A solid ``BatchingBolt`` implementation.

Several ``auto_`` class options.

sparse options
==============

TODO: add sparse stats

.. sourcecode:: text

    $ sparse help

    Usage:
            sparse quickstart <project_name>
            sparse run [-o <option>]... [-p <par>] [-t <time>] [-dv]
            sparse submit [-o <option>]... [-p <par>] [-e <env>] [-dvf]
            sparse list [-e <env>] [-v]
            sparse kill [-e <env>] [-v]
            sparse tail [-e <env>] [--pattern <regex>]
            sparse visualize [--flip]
            sparse (-h | --help)
            sparse --version

sparse visualize
================

.. image:: ./_static/streamparse_visualize.png
    :width: 90%
    :align: center

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

``auto_`` properties
====================

============= ========================================
property      What it does
============= ========================================
auto_ack      ack tuple after ``process``
auto_fail     fail tuple when exception in ``process``
auto_anchor   anchor tuple via incoming tuple ID
============= ========================================

.. sourcecode:: python

    class WordCounter(Bolt):

        auto_fail = False
        auto_ack = False
        auto_anchor = False

        def process(self, tup):
            word = tup.values[0]
            self.emit([word])

======================
Organizing around logs
======================

Kafka and Multi-consumer
========================

Even if Kafka's availability and scalability story isn't interesting to you,
the **multi-consumer story should be**.

.. image:: ./_static/multiconsumer.png
    :width: 60%
    :align: center

Kafka Consumer Groups
=====================

Consumer groups let you consume a large stream in a partitioned and balanced way.

Leverage multi-core and multi-node parallelism in Storm Spouts.

.. image:: ./_static/consumer_groups.png
    :width: 60%
    :align: center

Kafka + Storm
=============

Good fit for at-least-once processing.

No need for out-of-order acks.

Community work is ongoing for at-most-once processing.

Able to keep up with Storm's high-throughput processing.

Great for handling backpressure during traffic spikes.

pykafka
=======

Resurrecting our own project, ``samsa``, renamed as ``pykafka``.

- For Kafka 0.8.2
- SimpleConsumer **and** BalancedConsumer (with consumer groups)
- Pure Python protocol implementation
- C protocol implementation (via librdkafka)

https://github.com/Parsely/pykafka

Kafka in future ``streamparse`` releases
========================================

Hope to bundle a ``KafkaSpout`` and ``KafkaBolt``, written in Python.

Add a soft dependency to ``pykafka``.

Clearly, Kafka Matters
======================

============= ========= ========
Company       Logs      Workers
============= ========= ========
LinkedIn      Kafka*    Samza
Twitter       Kafka     Storm*
Pinterest     Kafka     Storm
Spotify       Kafka     Storm
Wikipedia     Kafka     Storm
Yahoo         Kafka     Storm
Netflix       Kafka     ???
============= ========= ========

===================
Recent Developments
===================

Python Topology DSL?
====================

"What I'm proposing instead is to ditch the idea of specifying topologies via
configuration files and do it instead via an interpreted general purpose
programming language (like Python)."

"By using an interpreted language, you can construct and submit topologies
without having to do a compilation."

Comments recently by Nathan Marz in `STORM-561`_.

P. Taylor Goetz responded to it by creating `flux`_.

.. _STORM-561: https://issues.apache.org/jira/browse/STORM-561
.. _flux: https://github.com/ptgoetz/flux

pystorm
=======

...

Questions?
==========

Go forth and stream!

Looking for a job where you can work from home?

We're `hiring`_!

Parse.ly on Twitter: `@Parsely`_

Me on Twitter: `@amontalenti`_

========
Appendix
========

Multi-Lang Impl's in Python
===========================

- `storm.py`_ (Storm, XXX 2010)
- `Petrel`_ (AirSage, XXX 2010)
- `streamparse`_ (Parse.ly, Apr 2014)
- `pyleus`_ (Yelp, Oct 2014)

TODO: fix these links.

Plan to unify around pystorm.

.. _Petrel: http://github.com/AirSage/Petrel
.. _pyleus: http://engineeringblog.yelp.com/2014/10/introducing-pyleus.html
.. _streamparse: http://github.com/Parsely/streamparse
.. _flux: https://github.com/ptgoetz/flux

Other Projects
==============

- `flux`_ - YAML
- `pyleus`_ - YAML (Python-specific)
- `Petrel`_ - Python
- `Clojure DSL`_ - Bundled with Storm
- `Trident`_ - Java "high-level" DSL bundled with Storm

streamparse uses simplified Clojure DSL; will add Python DSL.

.. _hiring: http://parse.ly/jobs
.. _@Parsely: http://twitter.com/Parsely
.. _@amontalenti: http://twitter.com/amontalenti

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
