---
title:   Classifying occurrences
layout:  post
author:  daniel
summary: 'Making the vetting interface: developing the classification dimensions for occurrences'
excerpt: 
categories: [Development]
tags:    [progress, vetting, classification, dimensions, occurrences]
---

One of the two major pillars of the Edgar project is vetting bird records.

The selfish reason for doing vetting is because modelling
the climatological suitability of an area for a given species of bird -- the
other pillar of the Edgar project -- 
is sensitive to inaccurate occurrence records.  The model assumes that
the occurrence of a bird in an area is evidence that the bird can 
survive in that area.  So for our modelling to be accurate, we need to
identify occurrence records that aren't evidence that a bird can
survive somewhere.

The unselfish reason for doing vetting is to pool the vetted data and make
it available to other researchers who need clean data.  To this end, we
will make our vetted data available for download and list it in metadata 
repositories, and also feed back vetting contributions to data sources, wherever
that's possible.

There are several reasons that recorded occurrences might not be evidence of
survival.  The obvious one is that the occurrence was recorded in error
-- the species was mis-identified by the observer, or observation details
were altered when written down or copied.

However a recorded observation can be true, but still unsuitable for 
modelling.  A valid observation from decades ago might not show that 
current conditions in that area are suitable.  A rainforest bird may have
been caught in severe weather and blown off the coast.  What the
modelling process really needs to know is if an occurrence does or 
doesn't demonstrate that an area can sustain a population of the bird 
species.

So, occurrence records need cleaning.  For our purposes we want them
classified into "suitable for modelling" and "unsuitable for modelling",
but that's the language 
[nerdy modellers](http://www.jjvanderwal.com/publications) use; the 
bird experts who actually have the knowledge to differentiate between 
those two categories don't use that terminology.

In situations where you are paying people to interact with your system,
or there's some other reason that your system has more power than your
users, you can just give the users a manual to read, and you're done.  In
our case, the vetting users are volunteers with valuable knowledge, so
we want to treat them pretty well.[^1]  We need to collect vetting
information in the language spoken by the users.

[^1]: Plus, our mums told us we should always treat everyone well.

### Bird watcher's classification - the habitat dimension

One of the dimensions a recorded occurrence can be classified onto is
the nature of the habitat.

After a bit of cultural immersion and a long discussion with 
[Lauren]({{ BASE_PATH }}/2012/04/20/the-team#lauren), I think this is
a reasonable classification for an occurrence's habitat.

<style>
    table.occurrenceclassification {
        border-spacing: 0.666em;
        border-collapse: separate;
        margin: 0;
    }

    table.occurrenceclassification table {
        border-collapse: separate;
        border-spacing: 0.666em;
        margin: 0 0 -5.666em;
    }

    .occurrenceclassification td { 
        position: relative;
        vertical-align: top;
        text-align: center;
        padding: 0.5em 0 5em;
        -webkit-border-top-left-radius: 1em;
        -webkit-border-top-right-radius: 1em;
        -moz-border-radius-topleft: 1em;
        -moz-border-radius-topright: 1em;
        border-top-left-radius: 1em;
        border-top-right-radius: 1em;
    }
/* grey levels
    .occurrenceclassification td { background-color: #eee; }
    .occurrenceclassification td td { background-color: #ddd; }
    .occurrenceclassification td td td { background-color: #ccc; }
    .occurrenceclassification td td td td { background-color: #bbb; }
*/

/* alternating grey
    .occurrenceclassification td { background-color: #eee; }
    .occurrenceclassification td td { background-color: #ccc; }
    .occurrenceclassification td td td { background-color: #eee; }
    .occurrenceclassification td td td td { background-color: #ccc; }
*/

    .occurrenceclassification td { background-color: #ff9; }
    .occurrenceclassification td td { background-color: #9bf; }
    .occurrenceclassification td td td { background-color: #afb; }
    .occurrenceclassification td td td td { background-color: #eae; }

    .occurrenceclassification h1, .occurrenceclassification p {
        margin: 0;
        padding: 0.666em;
        line-height: 1.4em;
        font-size: inherit;
        font-weight: inherit;
    }
    .occurrenceclassification h1 {
        line-height: 1.2em;
    }

    .occurrenceclassification p {
        font-size: 80%;
        opacity: 0.66;
    }

    .occurrenceclassification span.category {
        position: absolute;
        font-size: 150%;
        line-height: 1.5em;
        font-weight: bold;
        width: 1.5em;
        height: 1.5em;
        background: #333;
        color: #ddd;
        bottom: 1em;
        left: 50%;
        margin: 0 0 0 -0.75em;
        -webkit-border-radius: 50%;
        -moz-border-radius: 50%;
        border-radius: 50%;        
    }
</style>
<table class="occurrenceclassification">
    <tr>
        <td>
            <h1>not yet classified</h1>
            <p>
                We haven't yet put this occurrence record into a proper classification.
            </p>
            <span class="category">0</span>
        </td><td>
            <h1>invalid</h1>
            <p>
                The occurrence record is incorrect, the bird could not have been seen there.
            </p>
            <span class="category">1</span>
        </td><td>
            <h1>valid</h1>
            <p>
                The occurence record is correct &ndash; the bird really was seen in that spot.
            </p>
            <table><tr>
                <td>
                    <h1>historic</h1>
                    <p>
                        The observation was correct on the date it was
                        made, but the bird no longer occurs there.
                    </p>
                    <span class="category">2</span>
                </td><td>
                    <h1>current</h1>
                    <p>
                        The bird really was seen in that spot, and still
                        occurs there today.
                    </p>
                    <table><tr>
                        <td>
                            <h1>vagrant</h1>
                            <p>
                                This occurrence record is in an area where 
                                the bird cannot survive.
                            </p>
                            <span class="category">3</span>
                        </td><td>
                            <h1>irruptive</h1>
                            <p>
                                The observation is in an area where the 
                                species only occurs as a result of 
                                an erratic migration, for example due to 
                                overpopulation.
                            </p>
                            <span class="category">4</span>
                        </td><td>
                            <h1>core</h1>
                            <p>
                                This occurrence record is in an area where 
                                the bird can survive and the species persist.
                            </p>
                            <table><tr>
                                <td>
                                    <h1>non-breeding</h1>
                                    <p>
                                        The bird is a migratory species that does
                                        not breed in the area.
                                    </p>
                                    <span class="category">5</span>
                                </td><td>
                                    <h1>breeding (and non-migratory)</h1>
                                    <p>
                                        The bird breeds in this area.  If it is a
                                        non-migratory species, it lives here all
                                        year round.
                                    </p>
                                    <span class="category">7</span>
                                </td><td>
                                    <h1>introduced breeding (and non-migratory)</h1>
                                    <p>
                                        The bird breeds in this area, but was introduced
                                        and did not occur here naturally.
                                    </p>
                                    <span class="category">8</span>
                                </td>
                            </tr></table>
                        </td>
                    </tr></table>
                </td>

            </tr></table>
        </td>
    </tr>
</table>

Not all of these points are strictly about the habitat, but I've
sacrificed the pleasure of seeing a nice clean classification for 
the convenience of having a single dimension for our volunteers
to interact with.

I only _think_ this is a good list.  The true test is if our 
volunteer bird experts feel like they can choose the right 
classification without feeling constrained 
by the list they have to choose from.  Conversely, it's a bad 
list if none of the offered classifications match the expert's
opinion.

I can detect that by offering the vetting users a comments box 
as well as a classification selector.  If a user feels like none
of the classifications offered are suitable, they're more likely
to write an explanatory comment; if they can select a completely
suitable classification, they're less likely to comment.  So a
high frequency of comments could mean we need to rework our
classifications.

Note that I've left classification 6 off my diagram.  The last
three pinkish ones are combinations of two bi-valued dimensions,
{ breeding | non-breeding } and { introduced | natural }, which
should give four results.  The one I've left out is the 
'introduced non-breeding' combination, which Lauren suggested
was an unreasonable combination given that a non-breeding core
area implies a migratory bird, and migratory birds are unlikely
to stay in an area even once they've been "introduced".

### How we arrive at an initial classification

Edgar will launch with about eighteen million occurrences.
That's too many to rely on volunteer vettings that classify 
each one.  We need to have some way to auto-classify 
occurrences.

Here's how we plan to do it:

1. When importing occurrences from ALA or some other source,
examine the metadata for that occurrence.  ALA attach 
"assertions" to each recorded observation, some of which 
refer to apparent validity, for example <code>DETECTED_OUTLIER_ENVIRONMENTAL</code>
which is attached to an observation that is outside the normal
environmental range of the species.  We can apply an initial
guess at validity using those assertions.

1. [BirdLife Australia](http://www.birdlife.org.au/) have
provided Edgar with the accepted ranges for bird species as
geographic regions, with separate region polygons differentiating
ranges that are core, irruptive, etc.  Incoming observations
will be compared against those regions to suggest 
classifications.

1. When we record a vetting decision to apply to a observation,
we will assume the vetting classification applies to a circle
around the observation.  So a new occurrence may fall into a
previously vetted area, in which case we can apply the 
classification given in the vetting.

That gives us three opportunities to get a classification 
before we ask a volunteer bird expert to look at the 
observation record.  But now we are a
[man with two watches](http://en.wikipedia.org/wiki/Segal's_law);
if we get differing classifications from our various sources,
we have some ambiguity to resolve.

### Certainty classification

Each observation record gets a primary classification 
about the observation's validity and habitat.  We will also
track a measure of our certainty in that classification.
Later we may use certainty to draw the attention of vetting
users to classifications we aren't sure of.

We can achieve a classification by allocating each classifying
mechanism a certainty level, then collecting the votes for
a given occurrence, and choosing the classification with the
highest certainty level.

Certainty ranges from 0 to 6.

- "Not yet classified" starts at certainty level 1 (I'm 
reserving 0 for some future
"[wtf!?](http://google.com/search?q=%22why+the+face%22+%22modern+family%22)"
situation).

- A classification of "invalid" determined by metadata about
the occurrence may be 2 or higher, depending on the metadata.
Invalid at certainty levels 4 and 5 might not be shown on 
the map.

- A classification from BirdLife polygons gives a certainty
level of 2.

- A classification from vetting by a normal user will give
certainty level 3.  If there are multiple vettings, the most
recent one wins.

- If our project schedule allows, we will give admin users the
ability to mark some users are "recognised experts".  If we
do so, then a vetting by an expert user will give certainty
level 4.

- A classification from a vetting entered by an admin user
gives a certainty level of 6.

### Contention classification

Sources of classification can disagree.  We need a single 
primary classification to serve our modelling needs &mdash; 
an occurrence is either included in the modelling or not
&mdash; so our classification strategy enforces a precise
priority of classification, but where there is disagreement
we want an admin user to investigate further, and resolve the
conflict.

Contention levels range from 0 to 3 and is calculated by
looking at the classification votes.

- disagreement between two classification votes where both
are at the highest level of certainty is a level 3 contention.

- disagreement between the highest certainty vote and a 
certainty vote one point lower is a level 2 contention.

- disagreement between the highest certainty vote and a 
vote two certainty points lower is a level 1 contention.

- any other disagreement is considered uncontentious.

