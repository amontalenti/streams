========================
Real-time Streams & Logs 
========================

Andrew Montalenti, CTO

.. rst-class:: logo

    .. image:: ./_static/parsely.png
        :width: 40%
        :align: right

Agenda
======

* Parse.ly technical overview
* Architecture evolution
* Organizing around logs (Kafka)
* Aggregating the stream (Storm)
* Real-time vs Batch tensions

=============
Parse.ly Tech
=============

What is Parse.ly?
=================

Analytics for digital storytellers.

    .. image:: ./_static/banner_01.png
        :align: center
    .. image:: ./_static/banner_02.png
        :align: center
    .. image:: ./_static/banner_03.png
        :align: center
    .. image:: ./_static/banner_04.png
        :align: center

Variety
=======

Audience data:
    * visits
    * sessions

Engagement data:
    * views / time spent
    * social shares

Crawl data:
    * keywords / topics
    * author / section / tag


Velocity
========

* average post <48h shelf life
* many posts get most traffic in first few hours
* major news events can cause bursty traffic

.. image:: ./_static/pulse.png
    :width: 60%
    :align: center

Volume
======

* top publishers write 1000's of posts per day
* millions of posts in archive still getting traffic
* Parse.ly tracks **8 billion pageviews per month**
* Data from **over 250 million monthly unique browsers**

Time series data
================

.. image:: ./_static/sparklines_multiple.png
    :align: center

.. image:: ./_static/sparklines_stacked.png
    :align: center

Summary data
============

.. rst-class:: spaced

    .. image:: ./_static/summary_viz.png
        :align: center

Benchmark data
==============

.. rst-class:: spaced

    .. image:: ./_static/benchmarked_viz.png
        :align: center

Information radiators
=====================

.. rst-class:: spaced

    .. image:: ./_static/glimpse.png
        :width: 100%
        :align: center

======================
Architecture evolution
======================

Stack Overview
==============

.. rst-class:: spaced

    .. image:: ./_static/oss_logos.png
        :width: 90%
        :align: center

Queues and workers
==================

.. rst-class:: spaced

    .. image:: /_static/queues_and_workers.png
        :width: 90%
        :align: center

**Queues**: RabbitMQ => Redis => ZeroMQ

**Workers**: Cron Jobs => Celery

Queue problems
==============

Traditional queues (e.g. RabbitMQ / Redis):

* not distributed / highly available at core
* not persistent ("overflows" easily)
* more consumers mean more queue server load

(Hint: ZeroMQ trades these problems for another: unreliability.)

Lots of moving parts
====================

.. rst-class:: spaced

    .. image:: /_static/tech_stack.png
        :width: 90%
        :align: center


To add more features...
=======================

... we had to add more workers and queues!

Got harder and harder to develop on "the entire stack".

More code devoted to ops, rather than business logic.

And, it had big hardware demands
================================

* **Scaling Out**: From 2010-2012, went from 3 to 80 nodes running in Rackspace Cloud
* **Scaling Up**: From 2012-2013, ran a custom data center with 1 terabyte of RAM
* **Scaling In**: From 2013-2014, started building support for more nuanced metrics

(Through all of this, heavy user of Amazon ELB and S3 for data collection
and archiving, and EMR for Hadoop jobs.)

And, data management challenges
===============================

* Running multiple redundant data centers.
* Need to ship real-time data everywhere.
* Including data-identical production, staging, beta.
* New schema designs and new DB technologies, too.

In short: it started to get messy
=================================

.. rst-class:: spaced

    .. image:: ./_static/monitors.jpg
        :width: 90%
        :align: center

======================
Organizing around logs
======================

LinkedIn's lattice problem
==========================

.. rst-class:: spaced

    .. image:: ./_static/lattice.png
        :width: 100%
        :align: center

Enter the unified log
=====================

.. rst-class:: spaced

    .. image:: ./_static/unified_log.png
        :width: 100%
        :align: center

Log-centric is simpler
======================

.. rst-class:: spaced

    .. image:: ./_static/log_centric.png
        :width: 65%
        :align: center

Parse.ly is log-centric, too
============================

.. rst-class:: spaced

    .. image:: ./_static/parsely_log_arch.png
        :width: 80%
        :align: center

Introducing Kafka
=================

=============== ==================================================================
Feature         Description
=============== ==================================================================
Speed           100's of megabytes of reads/writes per sec from 1000's of clients
Durability      Can use your entire disk to create a massive message backlog
Availability    Cluster-oriented design allows for node failures without data loss
Multi-consumer  Many clients can read the same stream with no penalty
=============== ==================================================================

Kafka concepts
==============

=============== ==================================================================
Concept         Description
=============== ==================================================================
Topic           A group of related messages (a stream)
Producer        Procs that publish msgs to stream
Consumer        Procs that subscribe to msgs from stream
Broker          A cluster of Kafka machines that coordinates client/server comms
=============== ==================================================================

Kafka is a "distributed log"
============================

Topics are **logs**, not queues.

Consumers **read into offsets of the log**.

Consumers **do not "eat" messages**.

Logs are **maintained for a configurable period of time**.

Messages can be **"replayed"**.

Consumers can **share identical logs easily**.

Multi-consumer
==============

.. rst-class:: spaced

    .. image:: ./_static/multiconsumer.png
        :width: 60%
        :align: center

Even if Kafka's availability and scalability story isn't interesting to you,
the **multi-consumer story should be**.

Queue problems, revisited
=========================

Traditional queues (e.g. RabbitMQ / Redis):

* not distributed / highly available at core
* not persistent ("overflows" easily)
* more consumers mean more queue server load

**Kafka solves all of these problems.**

======================
Aggregating the stream
======================

So, what about Workers?
=======================

Kafka solves my Queue problem, but what about Workers?

How do I transform streams with **streaming computation**?

Worker data transforms
======================

Even with a unified log, workers will proliferate data transformations.

These transformations often have complex dependencies:

* pixel request is cleaned
* referenced URL is crawled
* crawled URL's text is analyzed by topic extractor
* repeated requests at identical URL rolled up by topic
* top performing topics are snapshotted for rankings

Worker problems
===============

* no control for parallelism and load distribution
* no guaranteed processing for multi-stage pipelines
* no fault tolerance for individual stages
* difficult to do local / beta / staging environments
* dependencies between worker stages are unclear

Meanwhile, in Batch land...
===========================

... everything is peachy!

When I have all my data available, I can just run Map/Reduce jobs.

We use Apache Pig, and I can get all the gurantees I need, and scale up on EMR.

... but, no ability to do this in real-time against the stream.

Introducing Storm
=================

Storm is a **distributed real-time computation system**.

Hadoop provides a set of general primitives for doing batch processing.

Storm provides a set of **general primitives** for doing **real-time computation**.

Hadoop primitives
=================

**Durable** Data Set, typically in **S3** or **HDFS**.

**Mappers** and **Reducers** in a **job flow**.

**JobTracker** and **TaskTracker** manage execution.

**Tuneable parallelism** + built-in **fault tolerance**.

Storm primitives
================

**Streaming Data** via **Spouts**, typically from **Kafka**.

**Bolts** assembled in a **Directed Acyclic Graph**.

**Nimbus** & **Workers** handle execution.

**Tuneable parallelism** + built-in **fault tolerance**.

Storm features
==============

=============== ====================================================================
Feature         Description
=============== ====================================================================
Speed           1,000,000 tuples per second per node, using Thrift and ZeroMQ
Fault Tolerance Workers and Storm mgmt daemons self-heal in face of failure
Parallelism     Computations run over a cluster, and parallelism is tuneable
Guaranteed Msgs Tracks lineage of data tuples, providing an at-least-once guarantee
Easy Code Mgmt  Several versions of code in a cluster; multiple languages supported
Local Dev       Entire system can run in "local mode" for end-to-end testing
=============== ====================================================================

Storm core concepts
===================

=============== =======================================================================
Concept         Description
=============== =======================================================================
Stream          Unbounded sequence of data tuples with named fields
Spout           A source of a Stream of tuples; typically reading from Kafka
Bolt            Computation steps that consume Streams and emits new Streams
Grouping        A way of partitioning data into a Bolt; for example: field vs shuffle
Topology        Directed Acyclic Graph (DAG) describing Spouts, Bolts, & Groupings
=============== =======================================================================

Wired Topology
==============

.. rst-class:: spaced

    .. image:: ./_static/topology.png
        :width: 80%
        :align: center


Storm cluster concepts
======================

=============== =======================================================================
Concept         Description
=============== =======================================================================
Tasks           The process/thread corresponding to a running Bolt/Spout in a cluster
Workers         The JVM process managing work for a given physical node in the cluster
Supervisor      The process monitoring the Worker processes on a single machine
Nimbus          Coordinates work among Workers/Supervisors; maintains cluster stats
=============== =======================================================================

Running Cluster
===============

.. rst-class:: spaced

    .. image:: ./_static/cluster.png
        :width: 80%
        :align: center

Real-time Word Count
====================

...

Word Count Tuple Tree
=====================

.. rst-class:: spaced

    .. image:: ./_static/wordcount.png
        :width: 70%
        :align: center


========
Appendix
========

Other Companies
===============

    ============= ========= ========
    Company       Logs      Workers
    ============= ========= ========
    Twitter       Kafka     Storm
    Spotify       Kafka     Storm
    Wikipedia     Kafka     Storm
    Outbrain      Kafka     Storm
    Loggly        Kafka     Storm
    LinkedIn      Kafka     Samza
    Amazon        Kinesis   ???
    Github        Kestrel   ???
    Google        ???       Dremel*
    UC Berkeley   RDDs*     Spark*
    Facebook      Scribe*   HBase*
    ============= ========= ========

Backend Stack
=============

    ============= ==========================================
    Tool          Usage
    ============= ==========================================
    ELB + nginx   scalable data collection across web
    S3            cheap, redundant storage of logs
    Scrapy        customizable crawling & scraping
    MongoDB       sharded, replicated historical data
    Redis         real-time data; past 24h, minutely
    SolrCloud     content indexing & trends 
    hll           memory-stable estimated cardinality
    Storm\*       **real-time** distributed task queue
    Kafka\*       **multi-consumer** data integration
    Pig\*         **batch** network data analysis
    ============= ==========================================

Moving to AWS
=============

In early 2014, Amazon launched their i2 instance types:

    =========== ======== ======== =========
    Instance    RAM      SSD      Cores
    =========== ======== ======== =========
    i2.8xlarge  244 GB   6.4 TB   32
    i2.4xlarge  122 GB   3.2 TB   16
    i2.2xlarge  61 GB    1.6 TB   8
    =========== ======== ======== =========

* $20/GB of RAM per month on-demand
* 1/2 the price of Rackspace Cloud
* Only 3X the fully-baked price of running your own colo
* Big memory, performant CPU, and fast I/O: all three!
* The golden age of analytics.


Contact Us
==========

Get in touch. We're hiring :)

* http://parse.ly
* http://twitter.com/parsely

And me:

* http://pixelmonkey.org
* http://twitter.com/amontalenti

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
