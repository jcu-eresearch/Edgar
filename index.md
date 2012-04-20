---
layout: page
title: Edgar
tagline: 
---
{% include JB/setup %}


Welcome to the Edgar project site! This project aims to build a site for diseminating species distribution information for both current and future projected distributions under climate change scenarios.

This site will contain:
* developers' blog;
* user guides;
* installation guides;
and other project documentation.


## Developer  Posts

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>



