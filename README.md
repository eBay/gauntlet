What is the eBay Gauntlet?

It’s a new solution for managing systems. It’s more than an application; it’s a sophisticated, user-extensible system which is designed for helping to solve complex issues in large environments.

Over time, Operations teams have been required to manage an increasing number of systems with the same number of people. The Gauntlet provides a means to help automate repetitive tasks and save valuable time. It’s with tools like this, that we will be able to scale our business while keeping costs under control.

Components

There are several Gauntlet components in different stages of completion

The Gauntlet utilizes a powerful collection of technology to do what it does. Each of these may range from the simplicity of a tiny script to a full fledged application. Obviously at the early stage, there will be more of the former than the latter. Some components may only be in the concept/planning stages. Others may have a working first generation prototype, but will be completely reimplemented at a later point using a different language or technology stack in a future version.

Gauntlet Components at a Glance

    server process – responsible for kicking off all new tasks. Should always be running. Many can be run in parallel to boost performance. Currently implemented as a custom Perl server process. May be replaced or augmented by a full featured message queuing technology such as ActiveMQ, RabbitMQ, etc. Generally runs on a single server, but multiple servers could share the same task queue in an HA configuration.
    web service – provides a pleasant interface for both mobile and desktop users for navigating through the various views provided to everything else the Gauntlet does. Currently implemented as an Apache/CGI/Perl application on Ubuntu Linux. Would benefit from a complete rewrite using a more sophisticated solution such as PHP, Django, Java, eBox? Raptor?
    CLI tool set – provides a command line interface to essential functions of the Gauntlet, and may be be called upon at times by other components such as the web service. This  allows for advanced tasks to be performed interactively,  invoked from scripts, scheduled via crontab, or initiated via automated processes (perhaps on other systems) that in turn have access to the Gauntlet.
    task framework – provides an object-oriented set of classes for you to build your own custom features for the Gauntlet. The classes provide helpful functions and interfaces to other parts of the Gauntlet, to both empower and simplify the tasks and the process of creating them.
    task library - each instance of the Gauntlet will over time develop a library of previously authored tasks. These can serve as a starting point for new ones, and can be written in any language which the Gauntlet host server can run.
    database - tracks essential information about hosts, groups, jobs, previous results, users, and other frequently-need data. Currently MySQL.
    file system – provides a repository for storing larger volumes of data collected from systems  over an extended period of time. Currently a simple ext4 file system on a VM. Could be replaced by enterprise NAS, ZFS, HDFS, NoSQL… desired future features include snapshots, deduplication, access to extended historical data.
    access - the Gauntlet has no power unless it can access your environment in some way. It currently has an SSH key repository and a mechanism for selecting the correct SSH key to use for a specific host or domain. Future interfaces to  other enterprise applications (examples: Puppet, Nagios, Cacti, TRACE, Git, Testsites) will open up the doors to give the Gauntlet even greater power to operate with.
    reporting/analytics - The Gauntlet is designed to collect data, it’s only natural that it be given the power to help you analyze, report, and act on that data. Currently it’s able to produce simple web pages, CSV files, and text reports suitable for email. Future improvements would include a feature-rich web interface, XML, RESTful interfaces, etc.



Docs

Web Interface help

The web interface offers access to the following functions:

1. Host Groups

    Allows you to manage groups of fully-qualified host names. The host groups are stored in a simple database table and could be populated from other data sources quite easily.
    Hosts can be added and removed from host groups either via web or by CLI.

2. Schedule Tasks – has two sections, group tasks or batch jobs.

    The main difference between these is that group tasks require a specific hostgroup to be assigned to the task, and a batch job is only a single process started without any arguements. A backup script is a good example; you only need one instance of it.
    You can schedule a task to run either immediately or on a schedule. If you choose to put something on a schedule, it will get added to a list of reccurring tasks and a fresh job will be generated at each scheduled time.
    The tasks and batch commands available are found directly by reading the file system of the Gauntlet application area. Tasks can be found in $gauntlet_base/audits and batch jobs can be found in $gauntlet_base/batch. Information about them is read directly from the tasks’ own README.txt file.

3. View Results

    This area will benefit from more advanced data visualization technology in future releases. For now it offers a simple view into the SQL database of prior results.
    You can find your results either by Job ID or by hostname (see the bottom of the page).
    Click the job ID button to get the results. Click the CSV text to download the results for that job as a CSV (comma separated values) file, easily imported into Excel or the like.
    When viewing results for a job, there is a button that allows you to delete all of the results for the job. As expected, it will remove the results for that job and the job will no longer show up in the list.
    Repeating scheduled jobs will probably fill up the list of jobs quite fast, so it will soon be necessary to implement better presentation of past results. It currently shows all the jobs on record, sorted by most recent, first.

4. Server Status

    Displays a small amount of information about the server: uptime, load average, current time, number of tasks still in the unassigned or running queues.

5. View Schedule

    Provides you with a list of previously scheduled tasks which are setup for recurring execution.
    You can delete them from this page. Return to the Schedule Tasks page to schedule new ones. (You can’t edit an existing scheduled task… just delete it and make a new one).


