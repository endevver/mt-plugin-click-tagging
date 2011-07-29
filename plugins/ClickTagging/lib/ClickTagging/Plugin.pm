package ClickTagging::Plugin;

use strict;
use warnings;

# This is responsible for loading jQuery in the head of the site.
sub update_template_jquery {
    my ($cb, $app, $template) = @_;

    # Check if jQuery has already been loaded. If it has, just skip this.
    unless ( $$template =~ m/jquery/) {
        # Include jQuery as part of the js_include, used on the 
        # include/header.tmpl, which is used on all pages.
        my $old = q{<mt:setvarblock name="js_include" append="1">};
        my $new = <<'END';
    <script type="text/javascript" src="<mt:StaticWebPath>jquery/jquery.js"></script>
</head>
END
        $$template =~ s/$old/$old$new/;
    }
}

sub edit_entry_template_param {
    my ($cb, $app, $params, $template) = @_;
    my $plugin = MT->component('clicktagging');
    my $blog_id = $params->{blog_id};
    my $obj_type = $params->{object_type};

    # Proceed only if Click Tagging was enabled on this blog.
    return 1 unless $plugin->get_config_value(
        'enable_click_tagging', 
        'blog:'.$blog_id
    );

    my $clickable;
    $clickable .= '<h4>Selected Tags</h4><div class="selected-tags">';

    # Grab the Tags field contents and any tags associated with this Entry or
    # Page object. Use these later to properly highlight clickable tags to 
    # visually flag their use.
    my @obj_tags = split( /\s*,\s*/, $params->{tags} ) if $params->{tags};
    if ( @obj_tags ) {
        foreach my $tag (@obj_tags) {
            $clickable .= "<span>$tag</span>";
        }
    }
    $clickable .= '</div>';
    $clickable .= '<h4>Available Tags</h4><div class="available-tags">';

    # The available tags are loaded in an AJAX call. This way, whatever number 
    # of tags gets loaded doesn't slow down the initial page load.
    $clickable .= '<div style="display: inline-block; padding-top: 4px">Loading...</div>';

    $clickable .= '</div>';

    # Now that we've assembled the clickable tagging interface HTML, insert it
    # into a container and also include the CSS and JS needed to make it all 
    # work properly.
    my $new_html = '<div id="click-tagging">';

    $new_html .= $clickable;

    # The following HTML allows users to create new tags. Should it be 
    # displayed? Check below.
    my $create_new_tag_hint = ''; # Set below, if used.
    my $create_new_tag_html .= '<div class="click-tagging-new-tag-container">'
        . '<h4>Add a New Tag</h4>'
        . '<input type="text" id="click-tagging-new-tag" autocomplete="off" />'
        . '</div>';

    # Is tag creation restricted?
    if ( $plugin->get_config_value('restrict_tag_creation', 'blog:'.$blog_id) ) {

        # Tag cration is restricted. Show the tag creation HTML only if the 
        # user is a System Administrator or Blog Administrator.
        if (
            $app->user->is_superuser() 
            || (
                $app->blog 
                && $app->user->permissions($blog_id)->can_administer_blog()
            )
        ) {
            $new_html .= $create_new_tag_html;
            $create_new_tag_hint = 'Create a tag by typing it in the Add a '
                . 'New Tag field; pause typing and it will be created.';
        }
    }
    else { # Tag creation is unrestricted. Allow any user to add new tags.
        $new_html .= $create_new_tag_html;
        $create_new_tag_hint = 'Create a tag by typing it in the Add a '
            . 'New Tag field; pause typing and it will be created.';
    }

    # Add a hint about how to use the tags.
    $new_html .= '<div class="hint">'
        . 'Click a tag name to add or remove it from this '
        . '<mt:Var name="object_type">. ' . $create_new_tag_hint . '</div>';

    $new_html .= <<'HTML';
</div>
<mt:Ignore>
    The #click-tagging-tag-placeholder is used to add new tags to the Selected 
    Tags area. jQuery can clone this tag and use it in that section.
</mt:Ignore>
<span id="click-tagging-tag-placeholder"></span>

<link rel="stylesheet" href="<mt:PluginStaticWebPath component="clicktagging">click-tagging.css" />
<script type="text/javascript" src="<mt:PluginStaticWebPath component="clicktagging">click-tagging.js"></script>
HTML


    my $tags_field = $template->getElementById( 'tags' );

    # Hide the Tags label/field title, effectively making the Selected Tags 
    # and Avaialble Tags headers the title.
    $tags_field->setAttribute('label','');

    my $tags_html = $tags_field->innerHTML;
    # Remove the border around the Tags input field.
    $tags_html =~ s/textarea-wrapper//;
    # Make the Tags input field hidden.
    $tags_html =~ s/input name/input type=\"hidden\" name/;

    # Update the tags field with all this new info!
    $tags_field->innerHTML($tags_html . $new_html);
}

# This is responsible for loading the available tags. It's called in an AJAX
# request, after the Edit Entry page has loaded.
sub load_available_tags {
    my ($app) = shift;
    my $q     = $app->param;
    
    # If tags have been assigned to this entry already, we want to load them
    # and include them in the available tags list. (They'll be hidden by 
    # default, but shown if removed from Selected Tags.)
    my @obj_tags;
    if ( defined $q->param('id') ) {
        my $iter = MT->model('objecttag')->load_iter({
            object_id => $q->param('id'),
        });
        while ( my $objecttag = $iter->() ) {
            my $tag = MT->model('tag')->load($objecttag->tag_id)
                or next;
            push @obj_tags, $tag->name;
        }
    }
    
    # This is responsible for pulling together the available tags that can be
    # clicked.
    my $available_tags = _build_available_tags_list({
        blog_id  => $q->param('blog_id'),
        obj_type => $q->param('type'),
        obj_tags => \@obj_tags,
    });

    return $available_tags;
}

# Build the list of Available Tags, and return the HTML that comprises them.
sub _build_available_tags_list {
    my ($arg_ref) = @_;
    my $blog_id  = $arg_ref->{blog_id};
    my $obj_type = $arg_ref->{obj_type};
    my @obj_tags = @{ $arg_ref->{obj_tags} };
    my $plugin   = MT->component('clicktagging');

    # We want to build a list of the most-used tags in this blog. Using the
    # mt:Tags block simply doesn't work correctly in the admin interface to
    # generate this, so we do it ourselves. Grab the tags used in this blog 
    # only.
    require MT::ObjectTag;
    my $iter = MT->model('tag')->load_iter(
        undef,
        {
            join => MT::ObjectTag->join_on(
                'tag_id',
                {
                    blog_id           => $blog_id,
                    object_datasource => 'entry',
                },
                {
                    unique => 1,
                },
            ),
        }
    );

    # Assemble the tags into some HTML.
    my @html;
    while ( my $tag = $iter->() ) {

        # Was this tag already selected? If so, it appears in the Selected 
        # Tags section. Keep this tag in the list, but hide it. If the tag is
        # removed from Selected Tags, this will be used in the Available Tags
        # list, displayed and ready to go.
        my $already_selected = (grep $_ eq $tag->name, @obj_tags)
            ? ' class="already-selected"'
            : '';

        push @html, {
            tag  => $tag->name, # Used to sort by tag name
            html => '<span'. $already_selected . '>' . $tag->name . '</span>',
        };
    }

    # The tags are currently unsorted. Sorting alphabetically will create a 
    # more useful list to pick Available Tags from. Plus, jumping from 
    # entry-to-entry, this will display tags in a consistent order, making it 
    # easier to find what you want.
    @html = sort { lc($a->{tag}) cmp lc($b->{tag}) } @html;

    # We want to return the number of tags that were specified in the Initial
    # Tag Count plugin setting for this blog.
    my $size = $plugin->get_config_value('tag_group_size', 'blog:'.$blog_id);
    my $count = 1;
    my $html_string;
    foreach my $html_tag (@html) {
        if ($count == 1) {
            $html_string .= '<div class="tag-group">';
        }

        $html_string .= $html_tag->{html};

        if ($count == $size) {
            $html_string .= "</div>\n";
            $count = 1;
        }
        else {
            $count++;
            $html_string .= "</div>\n" if $html_tag->{tag} eq $html[-1]->{tag};
        }
    }

    if ( scalar @html > $size ) {
        $html_string .= '<a href="javascript:void(0)" id="display-more-tags">'
            . 'Display more tags &raquo;</a>';
    }

    return $html_string;
}

1;

__END__
