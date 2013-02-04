Modelling
==========

Applicable Machine: climatebird3.qern.qcif.edu.au


The modelling is running as a set of parallel processes. These processes are
managed via [supervisord](http://supervisord.org/).

Signs that there's a problem
------------------------------

* Many of the species's appear to have a modelling status of "not yet modelled".
* The modelling status of "not yet modelled" isn't changing to "up to date" within
    a reasonable time frame.
* The modelling machine has low load, yet there are many species to be modelled.

Diagnosing the problem
-------------------------

You can view the logs for the modelling processes at:

    /var/log/supervisord/Local_Modeld_py_%N%.log

    (where %N% is 0 to numprocs-1)
    (numprocs is defined in your supervisord.conf file)

If the modelling is running correctly, you should find that the modelling logs
are reporting:

    Reported job status (FINISHED_SUCCESS), response: 200 - OK

If the modelling is failing due to an error with the website,
you will find logs with the following:

    Failed to queue job: HTTP Error %...%

or

    Error reporting job status: HTTP Error 500 %...%

If the modelling is failing due to an error with the actual modelling process,
you will find logs with the following:

    Reported job status (FINISHED_FAILURE), %...%

You should find std_out and std_err dumps available in the logs in the case
of a job failure.

