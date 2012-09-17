---
layout: page
title: Edgar - Australian Bird Distributions &amp; Climate Change
tagline: 
---
{% include JB/setup %}

Welcome to the Edgar project site! Edgar is a site for diseminating species distribution information for both current and future projected distributions under climate change scenarios.

<style>
    .fancylinks {
        text-align: center;
    }
    a.fancylink {
        display: inline-block;
        text-decoration: none;
        vertical-align: middle;
        width: 150px;
        height: 150px;
        font-size: 20px;
        line-height: 25px;
        margin: 15px;
        padding: 35px 15px 0 15px;
        box-sizing: border-box;
        color: white;

        text-shadow: 0 -1px 0 rgba(0,0,0,0.33);

        opacity: 0.9;

        background: rgb(181,189,200); /* Old browsers */
        background: -moz-linear-gradient(top, rgba(181,189,200,1) 0%, rgba(130,140,149,1) 36%, rgba(40,52,59,1) 100%); /* FF3.6+ */
        background: -webkit-linear-gradient(top, rgba(181,189,200,1) 0%,rgba(130,140,149,1) 36%,rgba(40,52,59,1) 100%); /* Chrome10+,Safari5.1+ */
        background: -o-linear-gradient(top, rgba(181,189,200,1) 0%,rgba(130,140,149,1) 36%,rgba(40,52,59,1) 100%); /* Opera 11.10+ */
        background: -ms-linear-gradient(top, rgba(181,189,200,1) 0%,rgba(130,140,149,1) 36%,rgba(40,52,59,1) 100%); /* IE10+ */
        background: linear-gradient(to bottom, rgba(181,189,200,1) 0%,rgba(130,140,149,1) 36%,rgba(40,52,59,1) 100%); /* W3C */

        -webkit-border-radius: 5px;
        -moz-border-radius: 5px;
        border-radius: 5px;
    }

    a.fancylink.edgar {
        font-weight: bold;
        background: rgb(169,3,41); /* Old browsers */
        background: -moz-linear-gradient(top, rgba(169,3,41,1) 0%, rgba(143,2,34,1) 44%, rgba(109,0,25,1) 100%); /* FF3.6+ */
        background: -webkit-linear-gradient(top, rgba(169,3,41,1) 0%,rgba(143,2,34,1) 44%,rgba(109,0,25,1) 100%); /* Chrome10+,Safari5.1+ */
        background: -o-linear-gradient(top, rgba(169,3,41,1) 0%,rgba(143,2,34,1) 44%,rgba(109,0,25,1) 100%); /* Opera 11.10+ */
        background: -ms-linear-gradient(top, rgba(169,3,41,1) 0%,rgba(143,2,34,1) 44%,rgba(109,0,25,1) 100%); /* IE10+ */
        background: linear-gradient(to bottom, rgba(169,3,41,1) 0%,rgba(143,2,34,1) 44%,rgba(109,0,25,1) 100%); /* W3C */
    }

    a.fancylink:hover {
        opacity: 1;
    }
</style>

<div class="fancylinks">
<a class="fancylink edgar" href="http://tropicaldatahub.org/goto/edgar"><br>Edgar</a>
<a class="fancylink userguide" href="{{ BASE_PATH }}/userguide.html"><br>User Guide</a>
<a class="fancylink devmanual" href="{{ BASE_PATH }}/developermanual.html">Develop &amp; Deployment Manual</a>
<a class="fancylink github" href="https://github.com/jcu-eresearch/Edgar">Edgar's Source at Github</a>
</div>

### Edgar's Development Blog

<ul class="posts">
  {% for post in site.posts %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

### Finding the Source Code

All source code is available on our <a href="http://github.com/jcu-eresearch/Edgar">github site</a>.
