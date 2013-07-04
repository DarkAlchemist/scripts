// Default MediaTomb import script.
// see MediaTomb scripting documentation for more information

/*MT_F*
    
    MediaTomb - http://www.mediatomb.cc/
    
    import.js - this file is part of MediaTomb.
    
    Copyright (C) 2006-2010 Gena Batyan <bgeradz@mediatomb.cc>,
                            Sergey 'Jin' Bostandzhyan <jin@mediatomb.cc>,
                            Leonhard Wimmer <leo@mediatomb.cc>
    
    This file is free software; the copyright owners give unlimited permission
    to copy and/or redistribute it; with or without modifications, as long as
    this notice is preserved.
    
    This file is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    
    $Id: import.js 2081 2010-03-23 20:18:00Z lww $
*/

function addAudio(obj)
{
    var desc = '';
    var artist_full;
    var album_full;
	var extension;
	var albumartist;
    
    // first gather data
    var title = obj.meta[M_TITLE];
    if (!title) title = obj.title;
   
   	// Grab artist, if emtpy, mark as unknown
    var artist = obj.meta[M_ARTIST];
    if (!artist) 
    {
        artist = 'Unknown';
        artist_full = null;
    }
    else
    {
        artist_full = artist;
        desc = artist;
    }

   	// Add retrieval of album artist object based on file type
	// Code be extended but I only need mp3 and flac
	extension = obj.title.split('.').pop().toUpperCase();
	if ( extension.indexOf("MP3") !== -1 ){
		albumartist = obj.aux['TPE2'];
    }
	else if ( extension.indexOf("FLAC") !== -1 ){
		albumartist = obj.aux['ALBUM ARTIST'];
    }
    var album = obj.meta[M_ALBUM];
    if (!album) 
    {
        album = 'Unknown';
        album_full = null;
    }
    else
    {
        desc = desc + ', ' + album;
        album_full = album;
    }
    
    if (desc)
        desc = desc + ', ';
    
    desc = desc + title;
    
    var date = obj.meta[M_DATE];
    if (!date)
    {
        date = 'Unknown';
    }
    else
    {
        date = getYear(date);
        desc = desc + ', ' + date;
    }
    
    var genre = obj.meta[M_GENRE];
    if (!genre)
    {
        genre = 'Unknown';
    }
    else
    {
        desc = desc + ', ' + genre;
    }
    
    var description = obj.meta[M_DESCRIPTION];
    if (!description) 
    {
        obj.meta[M_DESCRIPTION] = desc;
    }
       

	// Provides track number metadata
    var track = obj.meta[M_TRACKNUMBER];
	// Delimiter for tracks
	var trackDelimiter = '-';
    if (!track)
        track = '';
    else
	{
        if (track.length == 1)
        {
            track = '0' + track;
        }
        track = track + ' ' + trackDelimiter + ' ';
    }

    // Display track title as title alone, track may be useful later
	obj.title = title;
	var currTitle = obj.title;
    
	// for all music we want to display album then track details
	var chain = new Array('Music', 'All Music');
    obj.title = album + ' - ' + track + currTitle;
    addCdsObject(obj, createContainerChain(chain));
	// reset title
	obj.title = currTitle;
    
	// Artists with album subset
	if ( albumartist === '' || albumartist === null || albumartist == undefined ){
    	chain = new Array('Music', 'Artist/Album', abcbox(artist, '',''), artist, album + ' [' + extension + ']');
	}else{
    	chain = new Array('Music', 'Artist/Album', abcbox(albumartist, '',''), albumartist, album + ' [' + extension + ']');
	}
    addCdsObject(obj, createContainerChain(chain), UPNP_CLASS_CONTAINER_MUSIC_ALBUM);
    
	// Artists with all tracks by them
	if ( albumartist === '' || albumartist === null || albumartist == undefined ){
    	chain = new Array('Music', 'Artist/All Tracks', abcbox(artist, '',''), artist);
	}else{
    	chain = new Array('Music', 'Artist/All Tracks', abcbox(albumartist, '',''), albumartist);
	}
	// Before we add, we'll add the album to the title
	obj.title = album + ' - ' + track + currTitle;
    addCdsObject(obj, createContainerChain(chain), UPNP_CLASS_CONTAINER);
	obj.title = currTitle;

	// Albums by letter
    chain = new Array('Music', 'Albums', abcbox(album, '',''), album + ' [' + extension.toUpperCase() + ']' );
    addCdsObject(obj, createContainerChain(chain), UPNP_CLASS_CONTAINER_MUSIC_ALBUM);
    
	// Genres
    chain = new Array('Music', 'Genres', genre);
    addCdsObject(obj, createContainerChain(chain), UPNP_CLASS_CONTAINER_MUSIC_GENRE);
    
	// Music by year, album letter, album
    chain = new Array('Music', 'Year', date, abcbox(album, '',''), album + ' [' + extension.toUpperCase() + ']' );
    addCdsObject(obj, createContainerChain(chain));
}

function addVideo(obj)
{
    var chain = new Array('Video', 'All Video');
    addCdsObject(obj, createContainerChain(chain));

    var dir = getRootPath(object_root_path, obj.location);

    if (dir.length > 0)
    {
        chain = new Array('Video', 'Directories');
        chain = chain.concat(dir);

        addCdsObject(obj, createContainerChain(chain));
    }
}

function addWeborama(obj)
{
    var req_name = obj.aux[WEBORAMA_AUXDATA_REQUEST_NAME];
    if (req_name)
    {
        var chain = new Array('Online Services', 'Weborama', req_name);
        addCdsObject(obj, createContainerChain(chain), UPNP_CLASS_PLAYLIST_CONTAINER);
    }
}

function addImage(obj)
{
    var chain = new Array('Photos', 'All Photos');
    addCdsObject(obj, createContainerChain(chain), UPNP_CLASS_CONTAINER);

    var date = obj.meta[M_DATE];
    if (date)
    {
        var dateParts = date.split('-');
        if (dateParts.length > 1)
        {
            var year = dateParts[0];
            var month = dateParts[1];

            chain = new Array('Photos', 'Year', year, month);
            addCdsObject(obj, createContainerChain(chain), UPNP_CLASS_CONTAINER);
        }

        chain = new Array('Photos', 'Date', date);
        addCdsObject(obj, createContainerChain(chain), UPNP_CLASS_CONTAINER);
    }

    var dir = getRootPath(object_root_path, obj.location);

    if (dir.length > 0)
    {
        chain = new Array('Photos', 'Directories');
        chain = chain.concat(dir);

        addCdsObject(obj, createContainerChain(chain));
    }
}


function addYouTube(obj)
{
    var chain;

    var temp = parseInt(obj.aux[YOUTUBE_AUXDATA_AVG_RATING], 10);
    if (temp != Number.NaN)
    {
        temp = Math.round(temp);
        if (temp > 3)
        {
            chain = new Array('Online Services', 'YouTube', 'Rating', 
                                  temp.toString());
            addCdsObject(obj, createContainerChain(chain));
        }
    }

    temp = obj.aux[YOUTUBE_AUXDATA_REQUEST];
    if (temp)
    {
        var subName = (obj.aux[YOUTUBE_AUXDATA_SUBREQUEST_NAME]);
        var feedName = (obj.aux[YOUTUBE_AUXDATA_FEED]);
        var region = (obj.aux[YOUTUBE_AUXDATA_REGION]);

            
        chain = new Array('Online Services', 'YouTube', temp);

        if (subName)
            chain.push(subName);

        if (feedName)
            chain.push(feedName);

        if (region)
            chain.push(region);

        addCdsObject(obj, createContainerChain(chain));
    }
}

function addTrailer(obj)
{
    var chain;

    chain = new Array('Online Services', 'Apple Trailers', 'All Trailers');
    addCdsObject(obj, createContainerChain(chain));

    var genre = obj.meta[M_GENRE];
    if (genre)
    {
        genres = genre.split(', ');
        for (var i = 0; i < genres.length; i++)
        {
            chain = new Array('Online Services', 'Apple Trailers', 'Genres',
                              genres[i]);
            addCdsObject(obj, createContainerChain(chain));
        }
    }

    var reldate = obj.meta[M_DATE];
    if ((reldate) && (reldate.length >= 7))
    {
        chain = new Array('Online Services', 'Apple Trailers', 'Release Date',
                          reldate.slice(0, 7));
        addCdsObject(obj, createContainerChain(chain));
    }

    var postdate = obj.aux[APPLE_TRAILERS_AUXDATA_POST_DATE];
    if ((postdate) && (postdate.length >= 7))
    {
        chain = new Array('Online Services', 'Apple Trailers', 'Post Date',
                          postdate.slice(0, 7));
        addCdsObject(obj, createContainerChain(chain));
    }
}

// main script part

if (getPlaylistType(orig.mimetype) == '')
{
    var arr = orig.mimetype.split('/');
    var mime = arr[0];
    
    // var obj = copyObject(orig);
    
    var obj = orig; 
    obj.refID = orig.id;
    
    if (mime == 'audio')
    {
        if (obj.onlineservice == ONLINE_SERVICE_WEBORAMA)
            addWeborama(obj);
        else
            addAudio(obj);
    }
    
    if (mime == 'video')
    {
        if (obj.onlineservice == ONLINE_SERVICE_YOUTUBE)
            addYouTube(obj);
        else if (obj.onlineservice == ONLINE_SERVICE_APPLE_TRAILERS)
            addTrailer(obj);
        else
            addVideo(obj);
    }
    
    if (mime == 'image')
    {
		// Only add image if not in music folder!
		// This is a dirty hack though
		if ( obj.location.indexOf("/opt/Media/Music") == -1 ) {
        	addImage(obj);
		}
    }

    if (orig.mimetype == 'application/ogg')
    {
        if (orig.theora == 1)
            addVideo(obj);
        else
            addAudio(obj);
    }
}
