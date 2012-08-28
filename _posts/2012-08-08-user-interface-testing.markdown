---
title:   Refining our interface with real users
layout:  post
author:  daniel
summary: ''
excerpt: 
categories: [Development]
tags:    [testing, user, UI, learning]
---

# DRAFT

Early in August we tested the almost complete site on some real users.  In this probably rather long post I will describe our test users, go through the testing outcomes that most users agreed on, and then point out some specific things we learned from individual users.  Here I'm focusing on quite fine-grained aspects of the Edgar user interface; [Lauren]({{ site.JB.BASE_PATH }}/2012/03/22/the-team/#lauren)'s [user testing post]({{ site.JB.BASE_PATH }}/Development/2012/08/09/user-tests/) describes our user testing results with respect to Edgar's overall usefulness.

### Our test users

**User 1** was a postdoc at JCU who has worked in wildlife conservation and climate change areas, particularly with birds.  We expected this user to represent researchers interested in species survival in the face of climate change.

**User 2** was an administrator in a university department.  We expected this user to represent the general public exploring the information Edgar has on offer.

**User 3** was a bird watcher and internationally respected environmental scientist with broad ranging expertise including conservation managment, biodiversity, the tropical environment, and the knowledge economy.  We expected this user to represent birdwatchers, researchers, users who could supply vetting information, and policymaking site users.

**User 4** was a bird watcher, bird ecologist, wildlife researcher and wildlife photographer.  We expected this user to represent birdwatching and users who could supply vetting information.

**User 5** was a bird watcher and author of a bird atlas, also representing bird watchers and users who could supply vetting information.

## Common testing outcomes

Our test users interacted with almost every user-facing element of the Edgar product.  Mostly the user interface worked as designed, and the team enjoyed seeing our system being operated by real users.

Users also experienced some failures of the Edgar interface to work as they expected.  Particularly when these experiences were shared across several users, we addressed the issue as soon as possible.

### Users couldn't close tabs

We briefly described the site, and asked users to find more information about Edgar.  Every user found the "about" tab easily; almost every user had trouble closing the tab after opening it.

_What succeeded:_

Users easily found the general information tabs across the top of the window.  Positioning general navigation across the top of a web site is very common.

_What we learned:_ 

Clicking on a tab causes a panel of text to slide down into view, partially covering the map.  The tabs included a [disclosure triangle](http://en.wikipedia.org/wiki/Disclosure_widget) that points to the right when the info panel is closed, and rotates to point down when the tab is clicked and the info panel is opened.  I had expected this to indicate that clicking the tab a second time would slide away the info panel; instead it appears that users thought of the info panel as a transient element and clicked outside the panel, which works to cancel [dropdowns](http://en.wikipedia.org/wiki/Drop-down_list) and menus.

### Users could find the species they wanted

Some users immediately started searching for their favourite species; we suggested species for those that didn't.  All users immediately grasped that they should start typing the species name into the text box; most users expected the automatic suggestions that appear when they've typed a few characters.

_What succeeded:_

We used an [input prompt](http://ui-patterns.com/patterns/InputPrompt/) of "Type species common/scientific name here" inside a very large text box; this technique is common particularly for login and password entry boxes and is therefore very familiar to most web users.

_What we learned:_

The auto-suggest was a little too picky for our first test users; they needed to correctly enter the hyphens in names like "Blue-breasted Fairy-wren" for the species to show up.  We tweaked the suggestion mechanism between users and the end results were successful.

### Implications of the occurrence cluster dots were understood

Once users were looking at a species in current mode, we asked them what they thought the cluster dots represented, and what they would do to find out more about observations in a given area.

_What succeeded:_

All users described the grid of dots as summarising the observations in that region, and correctly guessed that the dot size was related to the observation count.  They also identified that the colour of the dot indicated the classification of the observations there.  Most users spontaneously discovered the pop-up info box that appears when clicking a cluster dot, and all users correctly anticipated finer-grained clustering when zooming in.  When we pointed out that the dot could represent observations across several classifications, users were okay with the dot colour being taken from the most common classification.

_What we learned:_

Some users didn't like the simplified classifications we used in current mode.  Our full set of seven classifications [described earlier]({{ site.JB.BASE_PATH }}/Development/2012/05/29/classifying-occurrences/) were being merged into four: unknown, invalid, core (breeding, non-breeding and introduced merged) and other (historic, vagrant, and irruptive merged).

We explained the merges but most users were uncomfortable with our merge groupings.  We resolved this by abandoning the merge-based simplification, instead using a different set of classifications that I will describe later in the vetting section.

### Climate suitability colours were sometimes confusing

In current mode Edgar uses pixel colour to convey several layers of information -- observation classifications, climate suitability and various geographic features -- so we expected this to come up.

_What succeeded:_

Users immediately grasped the colour scale we chose, with yellow indicating marginally suitable areas through to dark green indicating the most suitable.  Our domain experts have told us that using yellow (or tan)-to-green is the standard convention for showing suitability and distribution data.

_What we learned:_

Several users thought the suitability colours mixed with the map background too much.  We reduced the transparency of the suitability layer to reduce this effect.  Also, we added a third map background, the mostly-blank [VMAP0](http://en.wikipedia.org/wiki/Vector_map#Level_Zero_.28VMAP0.29), for when Google's physical terrain or satellite map backgrounds are too busy.

Additionally, in the original five-step colour scale, the climate suitability maps for broad-range species like [magpies](http://spatialecology.jcu.edu.au/Edgar/species/map/1103) showed wide bands of colour.  One user thought those bands could be mistaken for species distribution areas (such as core, vagrant, etc).  No users tested actually made that mistake, but we thought it plausible given adjacent suitability bands had large colour differences, e.g. yellow - tan.  We tried a seven-step scale, making adjacent bands' colours closer to each other, reinforcing the visual effect of the bands as steps along a scale.

## Future mode

We asked users if they could view future climate suitability for the species they were looking at.  All users were able to switch from current mode into future mode.  This reveals a new tool that allows the user to choose a climate change scenario, and (after loading the required future suitability maps) a play button and slider control.  Clicking play starts a 5 second animated transition from the 2015 projection through to the 2085 projection.

### Everyone understood future mode, and liked the future animation

_What succeeded:_

Everyone understood the scenarios and year slider, and when watching the animation most users immediately expressed their enjoyment of that effect.  Several users replayed the animation multiple times.

All users showed a good understanding of the implications of the future projections.

_What we learned:_

Not everyone noticed the play button immediately.  The default button styling was rather subtle; we have given the button a green edge to increase its visual weight.

In addition, after the first load of the projected maps, the loading indicator wouldn't show up even when reloads were required as the user panned and zoomed the map.  We now update the loading indicator whenever required.

## Vetting mode

We asked users to log in to the site to try vetting observations.  All users found the login button and were able to connect.  Some users already had ALA accounts, but no-one remembered their passwords.  Once logged in all users were able to switch into vetting mode, which revealed a vetting toolbox.

To select observations to vet, users were expected to browse observations on the map until they found some that were classified incorrectly.  The user would then drag a selection box over one or more cluster dots.  This would surround each of the selected clusters with a rectangular highlight box.  The vetting toolbox included a drop-down to select a new classification, a comment box to enter a comment, and a save button to record the vetting opinion.

### We got the colours for "invalid/doubtful" and "unclassified" the wrong way around

We tried using black to represent known-bad observations, and red for unclassified.  Our idea was to draw the eye to the unclassified observations, in order to collect vetting information about those.

_What succeeded:_

The red colour did catch vetting users' eyes.

_What we learned:_

Every user assumed that red meant "known to be bad", despite a legend telling them the opposite.  (This was true in current mode too, but it wasn't until the vetting section of our user test that it became obvious.)

We switched the colours to match people's expectations.

### Everyone preferred "doughnut" cluster dots when vetting

In current mode we drew cluster dots in a single colour according to the majority classification in that cluster.  However we were concerned that when vetting, this majority colouring might hide "interesting" classifications from the vetting user.

To help vetting users notice interesting observations, we ranked our classifications in order of "interestingness", and coloured cluster dots according to the most interesting classification contained therein.  A single unclassified observation would always draw its cluster dot in the unclassified colour, trumping any number of other classifications present in the same cluster.  We expected that this would keep the visual complexity down whilst still surfacing important information.

After demonstrating the trump technique, we also demonstrated an additional way of drawing cluster dots.  This alternative drew the dot in the colour of the most common classification, then drew a second smaller dot in the centre in the colour of the second most common classification.

_What we learned:_

The trump technique succeeded in surfacing interesting observations, but every user strongly preferred the two-colour "doughnut" technique.  We switched to using that as the default for vetting mode.

### Dragging over clusters isn't enough; users also want to click a single cluster

_What succeeded:_

When users wanted to select multiple clusters, they attempted a click-and-drag selection, which worked as expected.

_What we learned:_

When users wanted to select a single cluster, they clicked directly on the cluster.  This didn't select the cluster, but it did open a pop-up box describing the observations in the cluster (just as it would when clicking on a cluster in current mode).  Users assumed that cluster would be included in their vetting.

We adjusted our mouse handling so that when selecting observations to vet, a click inside a cluster would select that cluster.

### Panning the map vs. selecting observation clusters

Clicking on the map and dragging usually pans the map around.  The vetting tool included a "Select Observations" [toggle button](http://docs.oracle.com/javafx/2/ui_controls/toggle-button.htm) to switch into and out of selection mode, where clicking and dragging draws a selection box that can select observation clusters.

_What succeeded:_

When vetting, most users understood that dragging would select observations.

_What we learned:_

Most users didn't discover they could switch out of selection mode by clicking the "Select Observations" button a second time.

Rather than use a single button to toggle selection on and off, we [plan](https://github.com/jcu-eresearch/Edgar/issues/48) to add a second button labeled something like "Move map" to make it clearer how to get back to map panning.

### Users felt compelled to add a comment

_What succeeded:_

All users we able to perform trial vettings and understood how to select a new classification, enter a comment, and save their vetting.

_What we learned:_

We [expected commenting to be rare]({{ site.JB.BASE_PATH }}/Development/2012/05/29/classifying-occurrences/#commentsmeasure), but most users wrote something in the comment box every time.  In this situation it's possible users were simply testing the field, but my sense is that users would still feel the need to add a comment in normal usage.

We altered the comment field name to read "Optional comment" to reduce the number of unnecessary comments.

## Individual User Experiences

Some issues that arose during testing were specific to individual users.  We have considered these issues carefully and incorporated some of them into the final product.

### User 1

User 1 suggested a generic classification of "valid", to allow a vetting user to confirm an observation without specifying a more specific classification.  We opted not to implement this suggestion as it would add complexity without affecting the accuracy of modelling.

User 1 also suggested requiring a [confirmation](http://msdn.microsoft.com/en-us/library/windows/desktop/aa511273.aspx) if users applied vetting decisions at a coarse zoom level.  We liked this idea but there are situations where coarse vetting should be okay (for example, when vetting a single distant observation).

### User 2

User 2 suggested links from the climate change scenarios shown in future mode to full descriptions of those scenarios.  We agree and hope to link them to definitions in our glossary.

### User 3

User 3 wanted to explore individual observations, and expected to see details such as the observation date in the cluster dot's pop-up info box.  We agree with this and plan to [add further detail](https://github.com/jcu-eresearch/Edgar/issues/6) soon.

User 3 also wanted their mouse cursor to change when in vetting selection mode; they suggested using a "hand" cursor.  We plan to  to [alter the mouse cursor](https://github.com/jcu-eresearch/Edgar/issues/49).

### User 4

User 4 commented on our classification scheme.  They pointed out that using the name "core" to describe a merged classification that includes "introduced" would be surprising to birdwatchers.  In addition, distinguishing between breeding and non-breeding ranges can be problematic.  This user suggested we discuss classifications with User 5.

User 4 also suggested making certain classifications un-selectable for certain species, for example [malleefowl](http://spatialecology.jcu.edu.au/Edgar/species/map/113) aren't ever vagrant.  This idea is interesting but we decided against implementing it.

### User 5

User 5 provided lots of advice for our classification scheme.  Based on their comments, we made the following changes to Edgar's classification scheme:
* change the name of the "invalid" classification to "doubtful"
* merge breeding and non-breeding ranges into a new classification, "core"
* merge introduced ranges into a new classification, "introduced"
* include escapee observations in our definition of vagrant
* stop using the simplified set of classifications in current mode; instead, always use the new set, but hide "doubtful" when in current mode.

This user also suggested preventing vetting completely at coarse zoom levels.

















