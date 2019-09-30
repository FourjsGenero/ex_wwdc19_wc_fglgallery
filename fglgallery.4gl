#+ Genero Image Gallery library
#+
#+ This library implements a set of functions to create an image gallery
#+ in a WEBCOMPONENT field.
#+
#+ The content of the WEBCOMPONENT field must be handled for
#+ direction 4GL->webcomponent with the flush() or display() function
#+ direction webcomponent->4GL with the deserialize() function
#+
#+ @code
#+ DEFINE gallery_id INT
#+ DEFINE wc_gallery STRING
#+ LET gallery_id=fglgallery.create("formonly.gallery")
#+ CALL fglgallery.setSelected(gallery_id,3,TRUE)
#+ CALL fglgallery.setSelected(gallery_id,5,TRUE)
#+ ...
#+ LET wc_gallery=fglgallery.flush(gallery_id)
#+ --DISPLAY wc_gallery TO wc_gallery
#+
#+ The WEBCOMPONENT value is sent with an action event. The name of the
#+ action can be defined in the PROPERTY attribute in the .per file:
#+
#+ @code
#+ WEBCOMPONENT ...
#+    PROPERTIES=(selection="image_selection"),
#+
#+ It is then possible to detect image selection in the program with an
#+ ON ACTION handler:
#+
#+ @code
#+ INPUT BY NAME wc_gallery...ATTRIBUTES(UNBUFFERED)
#+ ...
#+   ON ACTION image_selection
#+        CALL fglgallery.deserialize( gallery_id, wc_gallery )
#+        DISPLAY util.JSON.stringify( fglgallery.getSelectionArray() )
#+

IMPORT util

PRIVATE TYPE t_image RECORD
                 path STRING,
                 title STRING,
                 flushed BOOLEAN,
                 selected BOOLEAN,
                 id INT
             END RECORD

PRIVATE TYPE t_gallery RECORD
               field STRING,
               displayType SMALLINT,
               displaySize SMALLINT,
               imageAspectRatio DECIMAL(5,2),
               images DYNAMIC ARRAY OF t_image,
               multipleSelection BOOLEAN,
               current INT,
               serialId INT,
               deletedImages DYNAMIC ARRAY OF RECORD
                 id INT,
                 serialId INT
               END RECORD
             END RECORD

PRIVATE DEFINE initCount SMALLINT
PRIVATE DEFINE galleries DYNAMIC ARRAY OF t_gallery
PRIVATE DEFINE m_ImageId INT

PUBLIC CONSTANT
  FGLGALLERY_TYPE_MOSAIC        = 1,
  FGLGALLERY_TYPE_LIST          = 2,
  FGLGALLERY_TYPE_THUMBNAILS    = 3

PUBLIC CONSTANT
  FGLGALLERY_SIZE_XSMALL  =  1,
  FGLGALLERY_SIZE_SMALL   =  2,
  FGLGALLERY_SIZE_NORMAL  =  4,
  FGLGALLERY_SIZE_LARGE   =  7,
  FGLGALLERY_SIZE_XLARGE  = 11

#+ Library initialization function.
#+
#+ This function has to be called before using other functions of this module.
#+
PUBLIC FUNCTION initialize()
    WHENEVER ERROR RAISE
    IF initCount == 0 THEN
       -- prepare resources
    END IF
    LET initCount = initCount + 1
    LET m_ImageId=1
END FUNCTION


#+ Library finalization function.
#+
#+ This function has to be called when the library is not longer used.
#+
PUBLIC FUNCTION finalize()
    IF initCount>0 THEN
       LET initCount = initCount - 1
       IF initCount == 0 THEN
          CALL galleries.clear()
       END IF
    END IF
END FUNCTION

PRIVATE FUNCTION _check_initialized()
    IF initCount==0 THEN
       CALL _display_error("fglgallery library is not initialized")
       OPEN FORM _dummy_ FROM NULL
    END IF
END FUNCTION

PRIVATE FUNCTION _display_error(msg STRING)
    DISPLAY "FGLGALLERY ERROR: ", msg
END FUNCTION

#+ Create a new gallery and return an ID
#+
#+ This function creates a new gallery object and returns its ID.
#+ The gallery ID will be used in other functions to identify a
#+ gallery object.
#+ The function requires the name of the form field defining
#+ the WEBCOMPONENT form item.
#+
#+ @code
#+ DEFINE id SMALLINT
#+ LET id = fglgallery.create("formonly.galley")
#+
#+ @param name The name of the WEBCOMPONENT form field.
#+
#+ @returnType SMALLINT
#+ @return The gallery object ID
#+
PUBLIC FUNCTION create(name)
    DEFINE name STRING
    DEFINE id, i SMALLINT
    CALL _check_initialized()
    FOR i=1 TO galleries.getLength()
        IF galleries[i].field IS NULL THEN
           LET id = i
        END IF
    END FOR
    IF id==0 THEN
       LET id = galleries.getLength() + 1
    END IF
    LET galleries[id].field = name
    LET galleries[id].imageAspectRatio = 1.0
    LET galleries[id].serialId = 0
    RETURN id
END FUNCTION

#+ Destroy a gallery object
#+
#+ This function releases all resources allocated for the gallery.
#+
#+ @param id      The gallery id
PUBLIC FUNCTION destroy(id)
    DEFINE id SMALLINT
    CALL _check_id(id)
    INITIALIZE galleries[id].* TO NULL
END FUNCTION

-- Raises an error that can be trapped in callers because of WHENEVER ERROR RAISE
PRIVATE FUNCTION _check_id(id)
    DEFINE id SMALLINT
    CALL _check_initialized()
    IF id>=1 AND id<=galleries.getLength() THEN
       IF galleries[id].field IS NOT NULL THEN
          RETURN
       END IF
    END IF
    CALL _display_error(SFMT("Invalid fglgallery id %1",id))
    OPEN FORM _dummy_ FROM NULL
END FUNCTION
PRIVATE FUNCTION _check_image_index(id, index)
    DEFINE id, index SMALLINT
    IF index<1 OR index>galleries[id].images.getLength() THEN
       CALL _display_error(SFMT("Invalid fglgallery image index %1",index))
       OPEN FORM _dummy_ FROM NULL
    END IF
END FUNCTION

#+ Add a new image to the web component gallery.
#+
#+ The function requires the gallery id, the path to the image file, which
#+ can be an URL or a local relative path, and a title/description of the
#+ picture. Leave title NULL if you don't want to add a description.
#+
#+ The function only registers the image resource for the gallery.
#+ In order to display the added images, you must call the flush() or the
#+ display() function.
#+
#+ @code
#+ CALL fglgallery.addImage(id, ui.Interface.filenameToURI("landscape.jpg"), "A nice landscape.")
#+
#+ @param id      The gallery id
#+ @param path    The path of the image file (on the server).
#+ @param title   The title or short description of the image.
#+
PUBLIC FUNCTION addImage(id, path, title)
    DEFINE id SMALLINT,
           path, title STRING
    DEFINE x INTEGER

    CALL _check_id(id)
    CALL galleries[id].images.appendElement()
    LET x = galleries[id].images.getLength()
    LET galleries[id].images[x].path = path
    LET galleries[id].images[x].title = title
    LET galleries[id].images[x].flushed = false
    LET galleries[id].images[x].id = m_ImageId
    LET galleries[id].images[x].selected = false
    LET m_ImageId=m_ImageId+1

END FUNCTION


#+ Returns the current number of images in a gallery.
#+
#+ @param id      The gallery id
#+
#+ @returnType INTEGER
#+ @return The number of images in the gallery.
#+
PUBLIC FUNCTION getImageCount(id)
    DEFINE id SMALLINT
    CALL _check_id(id)
    RETURN galleries[id].images.getLength()
END FUNCTION

#+ Sets the current index (highlight) in the image list
#+
#+ @param id      The gallery id
#+ @param index   The new highlighted index in the image list
#+ doesn't affect the selection
PUBLIC FUNCTION setCurrent(id, index)
    DEFINE id SMALLINT
    DEFINE index INT
    CALL _check_id(id)
    CALL _check_image_index(id, index)
    LET galleries[id].current=index
END FUNCTION

#+ Gets the current index (highlight) in the image list
#+
#+ @param id      The gallery id
#+
#+ @returnType INTEGER
#+ @return The index of the highlighted(clicked) image
#+
PUBLIC FUNCTION getCurrent(id)
    DEFINE id SMALLINT
    CALL _check_id(id)
    RETURN galleries[id].current
END FUNCTION

#+ Flushes the whole gallery to the Webcomponent side
#+
#+ This function takes the image gallery id as parameter, and serializes
#+ the gallery structure 
#+ Note that the display() function will do an automatic flush():
#+ The flush() function is typically used before you return to
#+ interactive state: don't call it twice during one interaction cycle!
#+ The function could be also named: serialize()
#+
#+ @param id    The gallery id
#+
#+ @returnType STRING
#+ @return The JSON serialization of the gallery: to be set as webcomponent variable value
PUBLIC FUNCTION flush(id)
    DEFINE id SMALLINT
    DEFINE i INT
    CALL _check_id(id)
    FOR i=1 TO galleries[id].images.getLength()
      --indicate that we synced once to the remote side
      LET galleries[id].images[i].flushed=TRUE
    END FOR
    --check for images deleted in a previous cycle
    FOR i=galleries[id].deletedImages.getLength() TO 1 STEP -1
      IF galleries[id].deletedImages[i].serialId<>galleries[id].serialId THEN
        --DISPLAY "remove image id:",galleries[id].deletedImages[i].id
        CALL galleries[id].deletedImages.deleteElement(i)
      END IF
    END FOR
    LET galleries[id].serialId=galleries[id].serialId+1
    RETURN util.JSON.stringify(galleries[id])
END FUNCTION

#+ Deserializes from a webcomponent INPUT variable
#+
#+ This function takes the image gallery id as parameter, 
#+ and the string value of a gallery webcomponent variable
#+ and syncs to the internal gallery structure
#+ call this function directly in response to the fglgallery selection action
#+ of the gallery webcomponent before you call other fglgallery API functions
#+
#+ @param id    The gallery id
#+ @param content value of a gallery webcomponent variable
#+
PUBLIC FUNCTION deserialize(id, content)
    DEFINE id SMALLINT
    DEFINE content STRING
    CALL _check_id(id)
    CALL util.JSON.parse(content,galleries[id])
END FUNCTION

#+ Define the aspect ratio for image items.
#+
#+ Call this function to define how images are sized relatively to others.
#+
#+ @code
#+ CALL fglgallery.setImageAspectRatio(id, 1.77) -- 16:9
#+ CALL fglgallery.display(id, ...)
#+
#+ @param id     The gallery id
#+ @param ratio  The image aspect ratio.
#+
PUBLIC FUNCTION setImageAspectRatio(id, ratio)
    DEFINE id SMALLINT, ratio DECIMAL(5,2)
    CALL _check_id(id)
    LET galleries[id].imageAspectRatio = ratio
END FUNCTION

#+ Display the gallery in your web component.
#+
#+ Call this function to show the image gallery in your form.
#+ This function requires two arguments: the gallery id and the gallery type.
#+ If the added images have not been flushed with the flush() function, the
#+ display() function will do an automatic flush().
#+
#+ @code
#+ CALL fglgallery.display(id, FGLGALLERY_TYPE_MOSAIC, FGLGALLERY_SIZE_NORMAL)
#+
#+ @param id     The gallery id
#+ @param type   The display type of the gallery, can be: FGLGALLERY_TYPE_MOSAIC, FGLGALLERY_TYPE_LIST, FGLGALLERY_THUMBNAILS
#+ @param size   The size of the images, can be: FGLGALLERY_SIZE_XSMALL, FGLGALLERY_SIZE_SMALL, FGLGALLERY_SIZE_NORMAL, FGLGALLERY_SIZE_LARGE, FGLGALLERY_SIZE_XLARGE
#+
PUBLIC FUNCTION display(id, type, size)
    DEFINE id SMALLINT, type SMALLINT, size SMALLINT
    DEFINE ret STRING

    CALL _check_id(id)
    LET galleries[id].displayType = type
    LET galleries[id].displaySize = size
    LET ret=flush(id)
    RETURN ret
END FUNCTION

#+ Enable or disable multiple image selection
#+
#+ Call this function to activate or deactivate multiple image selection.
#+ Note that this feature may not work with all sort of display types.
#+
#+ @param id  The gallery id
#+ @param on  TRUE or FALSE
#+
PUBLIC FUNCTION setMultipleSelection(id, on)
    DEFINE id SMALLINT,
           on BOOLEAN
    CALL _check_id(id)
    LET galleries[id].multipleSelection=on
END FUNCTION

#+ Sets the selection for a particular array index
#+
#+ Works only if multiple selection is activated
#+ Note that this feature may not work with all sort of display types.
#+
#+ @param id  The gallery id
#+ @param index  image index
#+ @param on  selection on or off
#+
PUBLIC FUNCTION setSelected(id, index, on)
    DEFINE id SMALLINT,
           index INT,
           on BOOLEAN
    CALL _check_id(id)
    CALL _check_image_index(id, index)
    LET galleries[id].images[index].selected=on
END FUNCTION

#+ Gets the selection for all images
#+
#+ Works only if multiple selection is activated
#+
#+ @param id  The gallery id
#+
#+ @returnType DYNAMIC ARRAY OF INT
#+ @return The selected indexes as an array
#+
PUBLIC FUNCTION getSelectionArray(id)
    DEFINE id SMALLINT,
           i,len INT,
           selarr DYNAMIC ARRAY OF INTEGER
    CALL _check_id(id)
    LET len=galleries[id].images.getLength()
    FOR i=1 TO len
      IF galleries[id].images[i].selected THEN
        LET selarr[selarr.getLength()+1]=i
      END IF
    END FOR
    RETURN selarr
END FUNCTION

#+ Convenience function to select all images
#+
#+ @param id  The gallery id
#+ @param on  selection on or off
#+
PUBLIC FUNCTION setSelectAll(id, on)
    DEFINE id SMALLINT,
           on BOOLEAN
    DEFINE i,len INT
    CALL _check_id(id)
    LET len=galleries[id].images.getLength()
    FOR i=1 TO len
      LET galleries[id].images[i].selected=on
    END FOR
END FUNCTION

#+ Return the path of the image identified by the index given as parameter
#+
#+ Call this function to get the image path correspondong to the index in the gallery.
#+ This function requires two arguments : the gallery id and the image index.
#+
#+ @code
#+ CALL fglgallery.getPath(id, index)
#+
#+ @param id     The gallery id
#+ @param index  The index of your image
#+
#+ @returnType STRING
#+ @return The image path of the given index
#+
PUBLIC FUNCTION getPath(id, index)
    DEFINE id SMALLINT, index INTEGER

    CALL _check_id(id)
    CALL _check_image_index(id, index)

    RETURN galleries[id].images[index].path

END FUNCTION

#+ Convenience fuction to return the image path of the current image
#+
#+
#+ @code
#+ CALL fglgallery.getPath(id, index)
#+
#+ @param id     The gallery id
#+ @param index  The index of your image
#+
#+ @returnType STRING
#+ @return The image path of the current image
#+
FUNCTION getCurrentPath(id)
    DEFINE id SMALLINT, curr INTEGER
    CALL _check_id(id)
    LET curr=galleries[id].current
    IF curr>=1 AND curr<=galleries[id].images.getLength() THEN
      RETURN galleries[id].images[curr].path
    END IF
    RETURN "<no path>"
END FUNCTION


#+ Return the title of the image identified by the index given as parameter
#+
#+ Call this function to get your image title (according to the index given) of your gallery in your web component.
#+ This function requires two arguments : the gallery id and the image index.
#+
#+ @code
#+ CALL fglgallery.getTitle(id, index)
#+
#+ @param id     The gallery id
#+ @param index  The index of your image
#+
PUBLIC FUNCTION getTitle(id, index)
    DEFINE id SMALLINT, index INTEGER

    CALL _check_id(id)
    CALL _check_image_index(id, index)

    RETURN galleries[id].images[index].title

END FUNCTION


#+ Delete images in the gallery
#+
#+ Call this function to delete images (according to the list of image indexes) in your gallery.
#+ This function requires two arguments : the gallery id and a dynamic array of image indexes.
#+
#+ @code
#+ CALL fglgallery.deleteImages(id, indexes)
#+
#+ @param id       The gallery id
#+ @param indexes  The dynamic array of image indexes
#+
PUBLIC FUNCTION deleteImages(id, indexes)
    DEFINE id SMALLINT,
           indexes DYNAMIC ARRAY OF INTEGER
    DEFINE i,len INTEGER
    DEFINE x t_image
    DEFINE todel DYNAMIC ARRAY OF BOOLEAN

    CALL _check_id(id)
    FOR i=1 TO indexes.getLength()
        CALL _check_image_index(id, indexes[i])
        LET todel[indexes[i]] = TRUE
    END FOR

    FOR i=todel.getLength() TO 1 STEP -1
        IF todel[i] THEN
           LET x=galleries[id].images[i]
           CALL addToDeleted(id,x.*)
           CALL galleries[id].images.deleteElement(i)
           CALL todel.deleteElement(i)
        END IF
    END FOR
    LET len=galleries[id].images.getLength()
    IF galleries[id].current > len THEN
      LET galleries[id].current=len
    END IF
END FUNCTION

PRIVATE FUNCTION addToDeleted(id,img)
  DEFINE id SMALLINT
  DEFINE img t_image
  DEFINE i,len INT
  IF NOT img.flushed THEN
    RETURN --not on the remote side
  END IF
  LET len=galleries[id].deletedImages.getLength()
  FOR i=1 TO len
    IF img.id==galleries[id].deletedImages[i].id THEN
      RETURN
    END IF
  END FOR
  LET galleries[id].deletedImages[len+1].id=img.id
  LET galleries[id].deletedImages[len+1].serialId=galleries[id].serialId
END FUNCTION


#+ Remove all images from the list.
#+
#+ Call this function to clean the gallery.
#+ This function takes the gallery id as parameter.
#+
#+ @code
#+ CALL fglgallery.clean(id)
#+
#+ @param id     The gallery id
#+
PUBLIC FUNCTION clean(id)
    DEFINE id SMALLINT
    DEFINE i, len INT
    DEFINE indexes DYNAMIC ARRAY OF INT
    CALL _check_id(id)
    LET len=galleries[id].images.getLength()
    FOR i=1 TO len
      LET indexes[i]=i
    END FOR
    CALL deleteImages(id,indexes)
END FUNCTION
