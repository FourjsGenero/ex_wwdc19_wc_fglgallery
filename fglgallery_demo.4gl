IMPORT util

IMPORT FGL fglgalleryX

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

    CALL fglgalleryX.initialize()
    LET id = fglgalleryX.create("formonly.gallery_wc")
    DISPLAY SFMT("formonly.gallery_wc received id %1.", id)

    -- Image files on the server
    CALL fglgalleryX.addImage(id, image_path("image01.jpg"), NULL)
    CALL fglgalleryX.addImage(id, image_path("image02.jpg"), NULL)
    CALL fglgalleryX.addImage(id, image_path("image03.jpg"), "Lightning.")
    CALL fglgalleryX.addImage(id, image_path("image04.jpg"), NULL)
    CALL fglgalleryX.addImage(id, image_path("image05.jpg"), "The road will be long. Really long.")
    CALL fglgalleryX.addImage(id, image_path("image06.jpg"), "Picture taken during the harvest time. This is a very long text to show how it renders with the different gallery types.")
    CALL fglgalleryX.addImage(id, image_path("image07.png"), NULL)
    CALL fglgalleryX.addImage(id, image_path("image08.jpg"), "A nice windmill in a field.")
    CALL fglgalleryX.addImage(id, image_path("image09.png"), "Big wheat field.")
    CALL fglgalleryX.addImage(id, image_path("image10.jpg"), NULL)
    CALL fglgalleryX.addImage(id, image_path("image11.jpg"), NULL)

    -- URLs
    --CALL fglgalleryX.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/mountain-ridge.jpg", "Mountain ridge")
    --CALL fglgalleryX.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/mountain-horse.jpg", "Horse in field")
    --CALL fglgalleryX.addImage(id, "http://freebigpictures.com/wp-content/uploads/forest-in-spring-646x433.jpg", "Forest in spring")

    DISPLAY "All images added. Displaying the gallery..."

    LET rec.gallery_type = FGLGALLERY_TYPE_MOSAIC
    LET rec.gallery_size = FGLGALLERY_SIZE_NORMAL
    LET rec.aspect_ratio = 1.0
    CALL fglgalleryX.setCurrent(id,1)
    LET rec.current = 1
    LET rec.path = fglgalleryX.getPath(id, fglgalleryX.getCurrent(id))
    LET rec.selected = util.JSON.stringify(selarr)
    LET rec.gallery_wc=fglgalleryX.display(id, rec.gallery_type, rec.gallery_size)
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
        CALL fglgalleryX.setCurrent(id, rec.current)
        LET rec.path = fglgalleryX.getCurrentPath(id)
        LET rec.gallery_wc = fglgalleryX.flush(id)

    ON ACTION select_all ATTRIBUTES(TEXT="Select all")
        LET rec.multiple_selection = TRUE
        CALL fglgalleryX.setMultipleSelection(id, rec.multiple_selection)
        CALL fglgalleryX.setSelectAll(id,TRUE)
        LET selarr=fglgalleryX.getSelectionArray(id)
        LET rec.selected = util.JSON.stringify( selarr )
        LET rec.gallery_wc = fglgalleryX.flush(id)
        CALL DIALOG.setActionActive("delete",selarr.getLength()>0)

    ON ACTION select_3_5 ATTRIBUTES(TEXT="Select 3 and 5")
        LET rec.multiple_selection = TRUE
        CALL fglgalleryX.setMultipleSelection(id, rec.multiple_selection)
        CALL fglgalleryX.setSelectAll(id,FALSE)
        CALL fglgalleryX.setSelected(id,3,TRUE)
        CALL fglgalleryX.setSelected(id,5,TRUE)
        LET selarr=fglgalleryX.getSelectionArray(id)
        LET rec.selected = util.JSON.stringify( selarr )
        LET rec.gallery_wc = fglgalleryX.flush(id)
        CALL DIALOG.setActionActive("delete",selarr.getLength()>0)

    ON ACTION deselect_all ATTRIBUTES(TEXT="Deselect all")
        LET rec.multiple_selection = TRUE
        CALL fglgalleryX.setMultipleSelection(id, rec.multiple_selection)
        CALL fglgalleryX.setSelectAll(id,FALSE)
        LET rec.selected = stringFromSelection(id)
        LET rec.gallery_wc = fglgalleryX.flush(id)
        CALL DIALOG.setActionActive("delete",FALSE)

    ON ACTION image_selection
        CALL fglgalleryX.deserialize( id, rec.gallery_wc )
        LET rec.current = fglgalleryX.getCurrent(id)
        LET rec.path = fglgalleryX.getCurrentPath(id)
        LET selarr=fglgalleryX.getSelectionArray(id)
        LET rec.selected = util.JSON.stringify( selarr )
        CALL DIALOG.setActionActive("delete",selarr.getLength()>0)

    ON CHANGE multiple_selection
        CALL fglgalleryX.setMultipleSelection(id, rec.multiple_selection)
        CALL fglgalleryX.setSelectAll(id,FALSE)
        LET rec.selected = NULL
        LET rec.gallery_wc = fglgalleryX.flush(id)

    ON CHANGE gallery_type
        LET rec.gallery_wc = fglgalleryX.display(id, rec.gallery_type, rec.gallery_size)

    ON CHANGE gallery_size
        LET rec.gallery_wc = fglgalleryX.display(id, rec.gallery_type, rec.gallery_size)

    ON CHANGE aspect_ratio
        CALL fglgalleryX.setImageAspectRatio(id, rec.aspect_ratio)
        LET rec.gallery_wc = fglgalleryX.display(id, rec.gallery_type, rec.gallery_size)

    ON ACTION delete ATTRIBUTES(TEXT="Delete selected")
        LET selarr=fglgalleryX.getSelectionArray(id)
        IF selarr.getLength()>0 THEN
            CALL fglgalleryX.deleteImages(id, selarr)
            LET rec.current = fglgalleryX.getCurrent(id)
            LET rec.path = fglgalleryX.getCurrentPath(id)
            LET rec.selected = stringFromSelection(id)
            LET rec.gallery_wc = fglgalleryX.flush(id)
        END IF

    ON ACTION delete_3_5 ATTRIBUTES(TEXT="Delete 3 and 5")
        IF fglgalleryX.getImageCount(id) >= 5 THEN
            CALL arr.clear()
            LET arr[1] = 3
            LET arr[2] = 5
            CALL fglgalleryX.deleteImages(id, arr)
            CALL fglgalleryX.setCurrent(id,1)
            LET rec.current = fglgalleryX.getCurrent(id)
            LET rec.path = fglgalleryX.getCurrentPath(id)
            LET rec.selected = stringFromSelection(id)
            LET rec.gallery_wc = fglgalleryX.flush(id)
        END IF

    ON ACTION delete_current ATTRIBUTES(TEXT="Delete current")
        IF rec.current>=1 AND rec.current<=fglgalleryX.getImageCount(id) THEN
           CALL arr.clear()
           LET arr[1] = rec.current
           CALL fglgalleryX.deleteImages(id, arr)
           LET rec.current=fglgalleryX.getCurrent(id)
           LET rec.path = fglgalleryX.getCurrentPath(id)
           LET selarr=fglgalleryX.getSelectionArray(id)
           LET rec.selected = util.JSON.stringify(selarr)
           LET rec.gallery_wc = fglgalleryX.flush(id)
        END IF

    ON ACTION clean ATTRIBUTES(TEXT="Clean")
        LET rec.current = NULL
        LET rec.path = NULL
        LET rec.selected = NULL
        CALL fglgalleryX.clean(id)
        LET rec.gallery_wc = fglgalleryX.flush(id)

    ON ACTION add_3 ATTRIBUTES(TEXT="Add 3 images")
        LET i = fglgalleryX.getImageCount(id)
        CALL fglgalleryX.addImage(id, image_path("image02.jpg"), SFMT("New image A %1", i:=i+1 ));
        CALL fglgalleryX.addImage(id, image_path("image05.jpg"), SFMT("New image B %1", i:=i+1 ));
        CALL fglgalleryX.addImage(id, image_path("image07.png"), SFMT("New image C %1", i:=i+1 ));
        LET rec.gallery_wc = fglgalleryX.flush(id)

    ON ACTION close
        DISPLAY "ON ACTION close ..."
        EXIT INPUT

    END INPUT

    DISPLAY "Dialog finished."

    CALL fglgalleryX.destroy(id)
    CALL fglgalleryX.finalize()

    DISPLAY "Goodbye."

END MAIN

FUNCTION stringFromSelection(id)
  DEFINE id INT
  DEFINE selarr DYNAMIC ARRAY OF INT
  LET selarr=fglgalleryX.getSelectionArray(id)
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
