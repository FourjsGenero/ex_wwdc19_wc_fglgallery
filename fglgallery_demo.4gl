IMPORT util

IMPORT FGL fglgallery

DEFINE arr DYNAMIC ARRAY OF INTEGER

DEFINE rec RECORD
               gallery_type INTEGER,
               gallery_size INTEGER,
               aspect_ratio DECIMAL(5,2),
               multiple_selection BOOLEAN,
               current INTEGER,
               path STRING,
               selected STRING,
               gallery_wc STRING
           END RECORD

MAIN
    DEFINE id, i SMALLINT
    DEFINE selarr DYNAMIC ARRAY OF INT

{
    DISPLAY "FGLIMAGEPATH              = ", fgl_getenv("FGLIMAGEPATH")
    DISPLAY "FGL_PRIVATE_DIR           = ", fgl_getenv("FGL_PRIVATE_DIR")
    DISPLAY "FGL_PRIVATE_URL_PREFIX    = ", fgl_getenv("FGL_PRIVATE_URL_PREFIX")

    DISPLAY "FGL_PUBLIC_DIR            = ", fgl_getenv("FGL_PUBLIC_DIR")
    DISPLAY "FGL_PUBLIC_IMAGEPATH      = ", fgl_getenv("FGL_PUBLIC_IMAGEPATH")
    DISPLAY "FGL_PUBLIC_URL_PREFIX     = ", fgl_getenv("FGL_PUBLIC_URL_PREFIX")
}

    OPEN FORM f1 FROM "fglgallery_demo"
    DISPLAY FORM f1

    OPTIONS INPUT WRAP, FIELD ORDER FORM

    DISPLAY "Initializing fglgallery ..."

    CALL fglgallery.initialize()
    LET id = fglgallery.create("formonly.gallery_wc")
    DISPLAY SFMT("formonly.gallery_wc received id %1.", id)

    -- Image files on the server
    CALL fglgallery.addImage(id, image_path("image01.jpg"), NULL)
    CALL fglgallery.addImage(id, image_path("image02.jpg"), NULL)
    CALL fglgallery.addImage(id, image_path("image03.jpg"), "Lightning.")
    CALL fglgallery.addImage(id, image_path("image04.jpg"), NULL)
    CALL fglgallery.addImage(id, image_path("image05.jpg"), "The road will be long. Really long.")
    CALL fglgallery.addImage(id, image_path("image06.jpg"), "Picture taken during the harvest time. This is a very long text to show how it renders with the different gallery types.")
    CALL fglgallery.addImage(id, image_path("image07.png"), NULL)
    CALL fglgallery.addImage(id, image_path("image08.jpg"), "A nice windmill in a field.")
    CALL fglgallery.addImage(id, image_path("image09.png"), "Big wheat field.")
    CALL fglgallery.addImage(id, image_path("image10.jpg"), NULL)
    CALL fglgallery.addImage(id, image_path("image11.jpg"), NULL)

    -- URLs
    --CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/mountain-ridge.jpg", "Mountain ridge")
    --CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/mountain-horse.jpg", "Horse in field")
    --CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/forest-in-spring-646x433.jpg", "Forest in spring")

    DISPLAY "All images added. Displaying the gallery..."

    LET rec.gallery_type = FGLGALLERY_TYPE_MOSAIC
    LET rec.gallery_size = FGLGALLERY_SIZE_NORMAL
    LET rec.aspect_ratio = 1.0
    CALL fglgallery.setCurrent(id,1)
    LET rec.current = 1
    LET rec.path = fglgallery.getPath(id, fglgallery.getCurrent(id))
    LET rec.selected = util.JSON.stringify(selarr)
    LET rec.gallery_wc=fglgallery.display(id, rec.gallery_type, rec.gallery_size)
    DISPLAY rec.gallery_wc TO gallery_wc

    DISPLAY "Starting dialog ..."

    INPUT BY NAME rec.* ATTRIBUTES (UNBUFFERED, WITHOUT DEFAULTS)

    BEFORE INPUT
        DISPLAY "Input initialized"
        CALL DIALOG.setActionActive("delete",selarr.getLength()>0)

    ON ACTION wc_enable ATTRIBUTES(TEXT="Enable WC")
        CALL DIALOG.setFieldActive("gallery_wc", TRUE)
    ON ACTION wc_disable ATTRIBUTES(TEXT="Disable WC")
        CALL DIALOG.setFieldActive("gallery_wc", FALSE)

    ON ACTION set_current ATTRIBUTES(TEXT="Set current")
        CALL fglgallery.setCurrent(id, rec.current)
        LET rec.path = fglgallery.getCurrentPath(id)
        LET rec.gallery_wc = fglgallery.flush(id)

    ON ACTION select_all ATTRIBUTES(TEXT="Select all")
        LET rec.multiple_selection = TRUE
        CALL fglgallery.setMultipleSelection(id, rec.multiple_selection)
        CALL fglgallery.setSelectAll(id,TRUE)
        LET selarr=fglgallery.getSelectionArray(id)
        LET rec.selected = util.JSON.stringify( selarr )
        LET rec.gallery_wc = fglgallery.flush(id)
        CALL DIALOG.setActionActive("delete",selarr.getLength()>0)

    ON ACTION select_3_5 ATTRIBUTES(TEXT="Select 3 and 5")
        LET rec.multiple_selection = TRUE
        CALL fglgallery.setMultipleSelection(id, rec.multiple_selection)
        CALL fglgallery.setSelectAll(id,FALSE)
        CALL fglgallery.setSelected(id,3,TRUE)
        CALL fglgallery.setSelected(id,5,TRUE)
        LET selarr=fglgallery.getSelectionArray(id)
        LET rec.selected = util.JSON.stringify( selarr )
        LET rec.gallery_wc = fglgallery.flush(id)
        CALL DIALOG.setActionActive("delete",selarr.getLength()>0)

    ON ACTION deselect_all ATTRIBUTES(TEXT="Deselect all")
        LET rec.multiple_selection = TRUE
        CALL fglgallery.setMultipleSelection(id, rec.multiple_selection)
        CALL fglgallery.setSelectAll(id,FALSE)
        LET rec.selected = stringFromSelection(id)
        LET rec.gallery_wc = fglgallery.flush(id)
        CALL DIALOG.setActionActive("delete",FALSE)

    ON ACTION image_selection
        CALL fglgallery.deserialize( id, rec.gallery_wc )
        LET rec.current = fglgallery.getCurrent(id)
        LET rec.path = fglgallery.getCurrentPath(id)
        LET selarr=fglgallery.getSelectionArray(id)
        LET rec.selected = util.JSON.stringify( selarr )
        CALL DIALOG.setActionActive("delete",selarr.getLength()>0)

    ON CHANGE multiple_selection
        CALL fglgallery.setMultipleSelection(id, rec.multiple_selection)
        CALL fglgallery.setSelectAll(id,FALSE)
        LET rec.selected = NULL
        LET rec.gallery_wc = fglgallery.flush(id)

    ON CHANGE gallery_type
        LET rec.gallery_wc = fglgallery.display(id, rec.gallery_type, rec.gallery_size)

    ON CHANGE gallery_size
        LET rec.gallery_wc = fglgallery.display(id, rec.gallery_type, rec.gallery_size)

    ON CHANGE aspect_ratio
        CALL fglgallery.setImageAspectRatio(id, rec.aspect_ratio)
        LET rec.gallery_wc = fglgallery.display(id, rec.gallery_type, rec.gallery_size)

    ON ACTION delete ATTRIBUTES(TEXT="Delete selected")
        LET selarr=fglgallery.getSelectionArray(id)
        IF selarr.getLength()>0 THEN
            CALL fglgallery.deleteImages(id, selarr)
            LET rec.current = fglgallery.getCurrent(id)
            LET rec.path = fglgallery.getCurrentPath(id)
            LET rec.selected = stringFromSelection(id)
            LET rec.gallery_wc = fglgallery.flush(id)
        END IF

    ON ACTION delete_3_5 ATTRIBUTES(TEXT="Delete 3 and 5")
        IF fglgallery.getImageCount(id) >= 5 THEN
            CALL arr.clear()
            LET arr[1] = 3
            LET arr[2] = 5
            CALL fglgallery.deleteImages(id, arr)
            CALL fglgallery.setCurrent(id,1)
            LET rec.current = fglgallery.getCurrent(id)
            LET rec.path = fglgallery.getCurrentPath(id)
            LET rec.selected = stringFromSelection(id)
            LET rec.gallery_wc = fglgallery.flush(id)
        END IF

    ON ACTION delete_current ATTRIBUTES(TEXT="Delete current")
        IF rec.current>=1 AND rec.current<=fglgallery.getImageCount(id) THEN
           CALL arr.clear()
           LET arr[1] = rec.current
           CALL fglgallery.deleteImages(id, arr)
           LET rec.current=fglgallery.getCurrent(id)
           LET rec.path = fglgallery.getCurrentPath(id)
           LET selarr=fglgallery.getSelectionArray(id)
           LET rec.selected = util.JSON.stringify(selarr)
           LET rec.gallery_wc = fglgallery.flush(id)
        END IF

    ON ACTION clean ATTRIBUTES(TEXT="Clean")
        LET rec.current = NULL
        LET rec.path = NULL
        LET rec.selected = NULL
        CALL fglgallery.clean(id)
        LET rec.gallery_wc = fglgallery.flush(id)

    ON ACTION add_3 ATTRIBUTES(TEXT="Add 3 images")
        LET i = fglgallery.getImageCount(id)
        CALL fglgallery.addImage(id, image_path("image02.jpg"), SFMT("New image A %1", i:=i+1 ));
        CALL fglgallery.addImage(id, image_path("image05.jpg"), SFMT("New image B %1", i:=i+1 ));
        CALL fglgallery.addImage(id, image_path("image07.png"), SFMT("New image C %1", i:=i+1 ));
        LET rec.gallery_wc = fglgallery.flush(id)

    ON ACTION close
        DISPLAY "ON ACTION close ..."
        EXIT INPUT

    END INPUT

    DISPLAY "Dialog finished."

    CALL fglgallery.destroy(id)
    CALL fglgallery.finalize()

    DISPLAY "Goodbye."

END MAIN

FUNCTION stringFromSelection(id)
  DEFINE id INT
  DEFINE selarr DYNAMIC ARRAY OF INT
  LET selarr=fglgallery.getSelectionArray(id)
  RETURN util.JSON.stringify( selarr )
END FUNCTION

FUNCTION image_path(path)
    DEFINE path STRING
    RETURN ui.Interface.filenameToURI(path)
END FUNCTION

FUNCTION display_type_init(cb)
    DEFINE cb ui.ComboBox
    CALL cb.addItem(FGLGALLERY_TYPE_MOSAIC,        "Mosaic")
    CALL cb.addItem(FGLGALLERY_TYPE_LIST,          "List")
    CALL cb.addItem(FGLGALLERY_TYPE_THUMBNAILS,    "Thumbnails")
END FUNCTION

FUNCTION display_size_init(cb)
    DEFINE cb ui.ComboBox
    CALL cb.addItem(FGLGALLERY_SIZE_XSMALL, "X-Small")
    CALL cb.addItem(FGLGALLERY_SIZE_SMALL,  "Small")
    CALL cb.addItem(FGLGALLERY_SIZE_NORMAL, "Normal")
    CALL cb.addItem(FGLGALLERY_SIZE_LARGE,  "Large")
    CALL cb.addItem(FGLGALLERY_SIZE_XLARGE, "X-Large")
END FUNCTION

FUNCTION aspect_ratio_init(cb)
    DEFINE cb ui.ComboBox
    -- Use strings for value to match DECIMAL(5,2) formatting
    CALL cb.addItem("1.00",  "1:1")
    CALL cb.addItem("1.77",  "16:9")
    CALL cb.addItem("1.50",  "3:2")
    CALL cb.addItem("1.33",  "4:3")
    CALL cb.addItem("1.25",  "5:4")
    CALL cb.addItem("0.56",  "9:16")
    CALL cb.addItem("0.80",  "4:5")
END FUNCTION
