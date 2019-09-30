IMPORT util
IMPORT FGL fglgallery

DEFINE rec RECORD
               gallery_type INTEGER,
               gallery_size INTEGER,
               aspect_ratio DECIMAL(5,2),
               current INTEGER,
               gallery_wc STRING
           END RECORD

MAIN
    DEFINE id SMALLINT

    OPEN FORM f1 FROM "simple_gallery"
    DISPLAY FORM f1

    OPTIONS INPUT WRAP, FIELD ORDER FORM

    CALL fglgallery.initialize()
    LET id = fglgallery.create("formonly.gallery_wc")

    -- Image files on the server, to be handled with filenameToURI()/FGLIMAGEPATH
    -- From images-public dir:
    CALL fglgallery.addImage(id, image_path("image01.jpg"), "Lake in mountains")
    CALL fglgallery.addImage(id, image_path("image02.jpg"), NULL)
    CALL fglgallery.addImage(id, image_path("image03.jpg"), "Lightning")
    -- From images-private dir:
    CALL fglgallery.addImage(id, image_path("image10.jpg"), "Outdoor cat")
    CALL fglgallery.addImage(id, image_path("image11.jpg"), NULL)

    -- URLs
    CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/mountain-ridge.jpg", "Mountain ridge")
    CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/mountain-horse.jpg", "Horse in field")
    CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/forest-in-spring-646x433.jpg", "Forest in spring")
    CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/mountain-waterfall.jpg", "Montain waterfall" )
    CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/summer-river-646x432.jpg", "River in summer")
    CALL fglgallery.addImage(id, "http://freebigpictures.com/wp-content/uploads/2009/09/reservoir-lake.jpg", "Reservoir lake")

    LET rec.gallery_type = FGLGALLERY_TYPE_MOSAIC
    LET rec.gallery_size = FGLGALLERY_SIZE_NORMAL
    LET rec.aspect_ratio = 1.0
    CALL fglgallery.setCurrent(id,1)
    LET rec.current = 1
    LET rec.gallery_wc = fglgallery.display(id, rec.gallery_type, rec.gallery_size)
    DISPLAY rec.gallery_wc TO gallery_wc

    INPUT BY NAME rec.* ATTRIBUTES (UNBUFFERED, WITHOUT DEFAULTS)

    ON CHANGE gallery_type
        LET rec.gallery_wc = fglgallery.display(id, rec.gallery_type, rec.gallery_size)

    ON CHANGE gallery_size
        LET rec.gallery_wc = fglgallery.display(id, rec.gallery_type, rec.gallery_size)

    ON CHANGE aspect_ratio
        CALL fglgallery.setImageAspectRatio(id, rec.aspect_ratio)
        LET rec.gallery_wc = fglgallery.display(id, rec.gallery_type, rec.gallery_size)

    ON ACTION set_current ATTRIBUTES(TEXT="Set current")
        CALL fglgallery.setCurrent(id, rec.current)
        LET rec.gallery_wc = fglgallery.flush(id)

    ON ACTION image_selection ATTRIBUTES(DEFAULTVIEW=NO)
        CALL fglgallery.deserialize( id, rec.gallery_wc )
        LET rec.current = fglgallery.getCurrent(id)

    ON ACTION close
        EXIT INPUT

    END INPUT

    CALL fglgallery.destroy(id)
    CALL fglgallery.finalize()

END MAIN

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
