Modelling
==========

This section of the repository includes scripts necessary for generating the
bird species climate suitability models.

URL ROUTES
===========

These are the routes I expect the HPC modelling daemon to interact with:

    GET /species/next_job.txt
        Something to do:
            200: plain_text: The species id to run next, and nothing else.
        Nothing to run:
            503: plain_text: "No available jobs"

        I'm asking for this interface to be in plain text to make it easy to work with in bash.
        Feel free to make it support other formats if that tickles your fancy.

    PUT&POST /species/update_job_status/_species_id
        Why PUT & POST? Because it seems to be the accepted way to do
        it in Cake. Anytime you want to use a PUT, you also support POST.

        params: job_status
                     job_status_message
                     dirty_occurrences

        job_status:
            A string representing the new job status.
            For now, the following are the different job statuses I will send:

                Our custom statuses:
                    * QUEUED - I have queued the job
                    * FINISHED_SUCCESS - I successfully ran the model
                    * FINISHED_FAILURE - I failed to run the model

                HPC specific statuses:
                    * C -  Job is completed after having run.
                    * E -  Job is exiting after having run.
                    * H -  Job is held.
                    * Q -  job is queued, eligible to run or routed.
                    * R -  job is running.
                    * T -  job is being moved to new location.
                    * W -  job is waiting for its execution time
                           (-a option) to be reached.
                    * S -  (Unicos only) job is suspend.

            This implies that I will announce that I am starting a job by
            sending a status of QUEUED.
            I will then send a series of HPC statuses. These statuses
            don't need to be understood by the cake app. These are the
            statuses that are reported by the HPC job queue (qstat).
            Then I will send either FINISHED_SUCCESS or FINISHED_FAILURE.

            I suggest recording when you received QUEUED for a job.
            If you do this, you can the detect if a job doesn't go to finished
            after X time, where X is for example a day, and then you can
            log an error and clear the job status.

        job_status_message;
            A human readable description of the job status. This is purely
            for logging purposes. For now, I will use it explain
            why a job is being updated with FINISHED_FAILURE.

        dirty_occurrences:
            When the HPC started modelling the job, this was the number
            of occurrences that were marked as dirty.

        Once a job_status of QUEUED has been sent for a species id, it should
        no longer be returned by the next_job route.

