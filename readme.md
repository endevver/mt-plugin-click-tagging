# Click Tagging Overview

The Click Tagging plugin for Movable Type and Melody provides an alternate tagging interface: click-to-tag.

* Enable Click Tagging on a per-blog basis.
* Click a tag to include it ("Selected Tags") or exclude it ("Available Tags") 
  from your Entry or Page.
* Display Available Tags in "groups" so that the Edit interface isn't 
  overwhelmed with a large list of tags. Select the size of the group in 
  Plugin Settings.
* Create new Tags by typing them in, just as with the traditional interface.
* Restrict tag creation to System and Blog Administrators only, thereby 
  forcing authors to choose from a set number of tags
* Available Tags are loaded through an AJAX-style request after the initial 
  Edit page has loaded. The benefit of this is that it doesn't slow down the 
  initial page load, allowing users to begin writing or editing immediately.

A picture is worth a thousand words:
![Click Tagging Screenshot](https://github.com/endevver/mt-plugin-click-tagging/blob/master/click-tagging.png?raw=true)

# Prerequisites

* Movable Type 4.x or Melody 1.x
* [Melody Compatibility Layer](https://github.com/endevver/mt-plugin-melody-compat/downloads) (for users of Movable Type)

# Installation

To install this plugin follow the instructions found here:

http://tinyurl.com/easy-plugin-install

Notice that an updated version of jQuery is included in `mt-static/jquery/`. Movable Type includes jQuery version 1.2.6; version 1.4.3+ is required. Overwrite the existing copy of jQuery with the included version, or newer.

# Configuration

Configure the Click Tagging plugin at the blog level by visiting Tools > Plugins > Click Tagging > Settings.

By default, Click Tagging is *not* enabled on a blog. Check the **Enable Click Tagging** checkbox to enable it.

The number of Available Tags displayed in a group can be specified with the **Tag Group Size** drop-down. Larger groups will take more space to display, of course.

Restrict which users can create tags by checking the **Restrict Tag Creation** checkbox. This will allow only System and Blog Administrators to create new tags.

# Use and Potential Issues

The interface is quite self-explanatory: visit the Edit Entry page and click a Selected Tag to remove it, or an Available Tag to add it. If available, click the "Display more tags" link to show more Available Tags. This link will be available until there are no more Tags to show. Use the "Add a New Tag" text input field to create a new tag or tags: just type your tag. The new tag will be added to Selected Tags automatically.

The initial use case for this plugin was straight-forward: a small, limited number of tags are in use on a specific blog and Authors should be using those tags only.

Both Selected Tags and Available Tags are sorted alphabetically. Sorting in a way that allows a tag to be found easily is essential to making the interface fast to work with.

This plugin has a potentially significant issue for some users and blogs: is displays tags for clicking. If your blog has thousands of tags, for example, a click-tagging interface is not going to be an improved experience over the traditional tagging interface. Click Tagging is best suited to blogs that have a small number of tags.

# License

This plugin is licensed under the same terms as Perl itself.

#Copyright

Copyright 2011, Endevver LLC. All rights reserved.
