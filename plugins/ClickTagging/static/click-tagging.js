jQuery(document).ready(function($) {
    $.ajax({
        url: ScriptURI + '?__mode=clicktagging_load_available_tags',
        data: 'id=' + $('input[name=id]').val() 
            + '&type=' + $('input[name=_type]').val()
            + '&blog_id=' + $('input[name=blog_id]').val(),
        success: function(data) {
            // Place all of the avaialable tag's HTML on the page.
            $('#click-tagging .available-tags').html(data);

            // Make sure that the first tag group is visible.
            $('#click-tagging .tag-group:first').show();
        }
    })

    // When the "display more tags" link is clicked, show another .tag-group.
    // Only show one more .tag-group at a time.
    $('#display-more-tags').live('click', function(){
        $('#click-tagging .tag-group').each(function(){
            if ( $(this).css('display') == 'none' ) {
                $(this).show(); // Show this tag group.

                // If this is the last .tag-group then hide the "display more 
                // tags" link.
                if ( $('#click-tagging .tag-group:last').css('display') == 'block' ) {
                    $('#display-more-tags').hide();
                }

                // Quit after marking a .tag-group as visible.
                return false;
            }
        });
    })

    $('#click-tagging span, #click-tagging-tag-placeholder').live('click', function(){
        handleClickTagging(this);
    });

    var typing_timer;
    $('#click-tagging-new-tag').keypress(function(event){
        // If the user hits enter while in this field, ignore it. We don't
        // want to save the page right now.
        if (event.keyCode == 13) {
            event.preventDefault();
            return false;
        }

        // Use a timer to give the user some time to type their tag or tags
        // without being rushed or falling into a case where the tag is 
        // created before they've finished typing. Clearing the timer before
        // setting it effectively causes the timer to be restarted after each
        // character typed.
        clearTimeout(typing_timer);
        typing_timer = setTimeout(processNewTags, 2000);
    });

    function processNewTags() {
        var new_tags = tagSplit( $('#click-tagging-new-tag').val() );

        // Grab the existing selected tags.
        var tags = tagSplit( $('input#tags').val() );


        for ( i=0; i < new_tags.length; i++) {

            // Search the array for the tag that has been clicked. Returns -1 if
            // not found, otherwise returns the position of the tag in the array.
            var result = $.inArray( new_tags[i], tags );
            
            // This tag was not found in the Selected Tags. Add it.
            if (result == -1) {
                tags.push( new_tags[i] );
                $('input#tags').val( tags.join(tag_delim) );

                // Look for the tag in the Available Tags section, and mark
                // it as used if it exists.
                $('#click-tagging span:contains('+new_tags[i]+')').hide();

                // Add the tag to the Selected Tags section, and hide the tag in 
                // the Available Tags section.
                $('#click-tagging-tag-placeholder')
                    .clone(true)
                    .removeAttr('id')
                    .text( new_tags[i] )
                    .appendTo('#click-tagging .selected-tags');
            }
            else {
                alert('The tag "' + new_tags[i] + '" is already selected.');
            }
        }

        // Remove tags entered in the field.
        $('#click-tagging-new-tag').val('');
    }

    function handleClickTagging(clicked_tag) {
        var tag_name = $(clicked_tag).text();

        // Grab the Tags text field and split the characters, making an array.
        // Use MT's tagSplit JS function to do this, which takes the tag
        // delimiter character into account and returns an array -- easy!
        var tags = tagSplit( $('input#tags').val() );

        // Search the array for the tag that has been clicked. Returns -1 if
        // not found, otherwise returns the position of the tag in the array.
        var result = $.inArray( tag_name, tags );

        // This tag was not found, which means it's not in the Tags field.
        // Use the existing Tags field contents and append the tag delimiter
        // and tag name.
        if (result == -1) {
            tags.push( tag_name );
            $('input#tags').val( tags.join(tag_delim) );

            // Add the tag to the Selected Tags section, and hide the tag in 
            // the Available Tags section.
            $('#click-tagging-tag-placeholder')
                .clone(true)
                .removeAttr('id')
                .text(tag_name)
                .appendTo('#click-tagging .selected-tags');
            $(clicked_tag).hide();
        }

        // This tag was found in the Tags field. Remove the specified tag from 
        // the tags array, then place the updated tags array back into the 
        // Tags field.
        else {
            // Update the Tags field
            var removed_tag = tags.splice( result, 1 );
            $('input#tags').val( tags.join(tag_delim) );

            // Remove from the Selected Tags section, and show the tag in the
            // Available Tags section.
            $(clicked_tag).remove();
            $('#click-tagging span:contains('+removed_tag+')').show();
        }
    }
});
