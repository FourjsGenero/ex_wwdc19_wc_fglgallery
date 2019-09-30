// FOURJS_START_COPYRIGHT(P,2017)
// Property of Four Js*
// (c) Copyright Four Js 2017, 2019. All Rights Reserved.
// * Trademark of Four Js Development Tools Europe Ltd
//   in the United States and elsewhere
// FOURJS_END_COPYRIGHT

var myLazyLoad = new LazyLoad();

var FGLGALLERY_TYPE_MOSAIC        = 1;
var FGLGALLERY_TYPE_LIST          = 2;
var FGLGALLERY_TYPE_THUMBNAILS    = 3;

var hasFocus = false;
var clickedIndex = -1;
var imageDefs = [];
var imgHash = {};
var isDisplayed = false;
var isMultipleSelection = false;
var isActive = false;
var currentDisplayType = 0;
var currentDisplaySize = 0;
var currentAspectRatio = 0;
var currentIndex = -1;
var pictureSize = 0;
var galleryOptions = { selection: "fglgallery_selection" };
var componentValue={};

var onICHostReady = function(version) {

    hasFocus = false;
    clickedIndex = -1;

    galleryOptions.selection = null;

    catchKeys();

    gICAPI.onFocus = function(polarity) {
        hasFocus = polarity;
        if (hasFocus === true && clickedIndex > -1) {
            sendSelectionByIndex(clickedIndex, true, false);
        }
        toggleFocusRendering(hasFocus);
    };

    gICAPI.onProperty = function(properties) {
        try{
            var ps = JSON.parse(properties);
            if (ps.selection !== undefined) {
                galleryOptions.selection = ps.selection;
            }
        }
        catch (err){
            console.error("onProperty(): Invalid JSON string");
        }
    };

    gICAPI.onStateChanged = function(ps) {
        var params = JSON.parse(ps);
        isActive = (params.active === 1);
        toggleActivationRendering(isActive);
    };

    gICAPI.onData = function(content) {
        var index = -1;
        var selected = [];
        if (content && content.length > 0) {
            try {
                componentValue = JSON.parse(content);
                if (componentValue.current > 0) {
                    index = componentValue.current - 1;
                }
            } catch(e) {
                componentValue.current = 0;
                componentValue.images=[];
                componentValue.deletedImages=[];
                index=0;
                alert(e);
                console.error(e);
            }
        }
        if (componentValue.deletedImages.length>0) {
          deleteImages(componentValue.deletedImages);
        }
        flush(componentValue.images);
        display(componentValue.displayType,
                componentValue.displaySize,
                componentValue.imageAspectRatio);
        checkMultipleSelection(componentValue.multipleSelection);
        showSelection();
        setNewCurrent(index);
    };

    gICAPI.onFlushData = function() {
        gICAPI.SetData(JSON.stringify(componentValue));
    }

};

function toggleFocusRendering(f) {
    var e = document.getElementById("main");
    if (f) {
        e.classList.remove("main-unfocused");
        e.classList.add("main-focused");
    } else {
        e.classList.remove("main-focused");
        e.classList.add("main-unfocused");
    }
}

function toggleActivationRendering(a) {
    var e = document.getElementById("main");
    if (a) {
        e.classList.remove("main-disabled");
        e.classList.add("main-enabled");
    } else {
        e.classList.remove("main-enabled");
        e.classList.add("main-disabled");
    }
}

function setFieldValue() {
    componentValue.current = currentIndex + 1;
    //sync back the selection
    for( var i=0;i<componentValue.images.length;i++) {
      var img=componentValue.images[i];
      var idp=getPictureId(img.id);
      var imgDef=imgHash[idp];
      if (imgDef===undefined) {
        console.log("setFieldValue: no imgDef for:"+imageDebugStr(img));
        continue;
      }
      img.selected=imgDef.selected;
    }
}

function getPictureId(id) {
    return "picture" + id;
}

function getPictureElement(id) {
    return document.getElementById(getPictureId(id));
}

function setNewCurrent(index,makeVisible)
{
    var elts=document.getElementsByClassName("image-current");
    while (elts.length>0) {
      var el=elts[0];
      el.classList.remove("image-current");
    }
    if (index > -1 && index < imageDefs.length) {
        var id=imageDefs[index].id;
        var el = getPictureElement(id);
        if (el!==null) {
            el.classList.add("image-current");
        }
        if (el!==null && (index!=currentIndex || makeVisible===true)) {
            el.scrollIntoView();
            if (currentDisplayType === FGLGALLERY_TYPE_THUMBNAILS
                || index === 0) {
                window.scrollTo(0,0);
            }
        }
        if (currentDisplayType === FGLGALLERY_TYPE_THUMBNAILS) {
            setThumbnailsCurrentImage(imageDefs[index].src,
                                      imageDefs[index].title);
        }
        currentIndex = index;
    } else {
        if (currentDisplayType === FGLGALLERY_TYPE_THUMBNAILS) {
            setThumbnailsCurrentImage(null, null);
        }
        currentIndex = -1;
    }
}

function imageDebugStr(img) {
  return img.path+",id:"+img.id+",sel:"+img.selected;
}

function flush(imagesArray)
{
    var i = 0;
    var imageAttr = {};
    for (i = 0; i < imagesArray.length; i+=1 ) {
        var img=imagesArray[i];
        console.log("i:"+i+" "+imageDebugStr(imagesArray[i]));
        var idp=getPictureId(img.id);
        console.log("idp:",idp);
        var imgDef=imgHash[idp];
        if (imgDef!==undefined) {
          console.log("already there:"+imageDebugStr(imagesArray[i]));
          imgDef.selected=img.selected;
          continue;
        }
        if (true) {
            imageAttr = {
               title      : img.title,
               src        : img.path,
               id         : img.id,
               selected   : img.selected
               };
            if (imageAttr.title === undefined) {
                imageAttr.title = null;
            }
            imageDefs.push(imageAttr);
            //link the array entry into the hash
            imgHash[idp]=imageAttr;
        }
    }
}

function setThumbnailsCurrentImage(source, title) {
    var imageCurrentImage = document.getElementById("imageCurrentImage");
    if (source === null) {
        imageCurrentImage.removeAttribute("src");
    } else {
        imageCurrentImage.setAttribute("src", source);
    }
    var imageCurrentTitle = document.getElementById("imageCurrentTitle");
    if (title === null) {
        imageCurrentTitle.innerText = "";
    } else {
        imageCurrentTitle.innerText = title;
    }
}

function imageTitleFontSize(r) {
    var s = (pictureSize / 15) * r;
    if (s < 0.8) {
        s = 0.8;
    }
    return s + "em";
}

function imageSizeAttributes(h, w) {
    if (currentAspectRatio > 0.0) {
        h = h / currentAspectRatio;
    }
    return " height:" + h + "em; "
         + " width:" + w + "em; ";
}

function addToDisplay(displayType, imageDefsToAdd)
{
    var main = document.getElementById("main");
    main.classList.remove("unstyled-main");
    main.classList.remove("mosaic-main");
    main.classList.remove("list-main");
    main.classList.remove("thumbnails-main");

    var imageSet = document.getElementById("imageSet");
    imageSet.classList.remove("unstyled-imgset");
    imageSet.classList.remove("mosaic-imgset");
    imageSet.classList.remove("list-imgset");
    imageSet.classList.remove("thumbnails-imgset");
    imageSet.style.display = "none";

    var imageCurrent = document.getElementById("imageCurrent");
    imageCurrent.style.display = "none";

    var imageCurrentImage = document.getElementById("imageCurrentImage");

    var imageCurrentTitle = document.getElementById("imageCurrentTitle");
    imageCurrentTitle.classList.remove("thumbnails-current-image-text");

    var fs;
    var i;
    var length = imageDefsToAdd.length;
    var ei;
    var eii;
    var eit;

    if (displayType === FGLGALLERY_TYPE_MOSAIC) {
        main.classList.add("mosaic-main");
        imageSet.classList.add("mosaic-imgset");
        imageSet.style.display = "block";
        fs = imageTitleFontSize(1);
        for( i = 0; i < length; i+=1 ) {
            var id=imageDefsToAdd[i].id;
            var idp=getPictureId(id);
            if ( getPictureElement(id) === null) {
                ei = document.createElement("li");
                ei.setAttribute("class", "mosaic-image-li");
                ei.setAttribute("id", idp);
                ei.setAttribute("data-src", imageDefsToAdd[i].src);
                ei.setAttribute("onclick", "imageClicked(this.id)");
                ei.setAttribute("style", "width:" + pictureSize + "em;");
                imageSet.appendChild(ei);
                eii = document.createElement("div");
                eii.setAttribute("class", "mosaic-image-div");
                eii.setAttribute("style", imageSizeAttributes(pictureSize - 1.5, pictureSize)
                                        + " background-image: url(" + imageDefsToAdd[i].src + ");" );
                ei.appendChild(eii);
                eit = document.createElement("div");
                eit.setAttribute("class", "mosaic-image-text text-ellipsis");
                eit.setAttribute("style", "font-size: " + fs + ";"
                                        + visibilityAttribute(imageDefsToAdd[i].title) );
                eit.appendChild( document.createTextNode(imageDefsToAdd[i].title) );
                ei.appendChild(eit);
            }
        }
    } else if (displayType === FGLGALLERY_TYPE_LIST) {
        main.classList.add("list-main");
        imageSet.classList.add("list-imgset");
        imageSet.style.display = "block";
        fs = imageTitleFontSize(1.2);
        for( i = 0; i < length; i+=1 ) {
            var id=imageDefsToAdd[i].id;
            var idp=getPictureId(id);
            if ( getPictureElement(id) === null) {
                ei = document.createElement("li");
                ei.setAttribute("class", "list-image-li");
                ei.setAttribute("id", idp);
                ei.setAttribute("data-src", imageDefsToAdd[i].src);
                ei.setAttribute("onclick", "imageClicked(this.id)");
                imageSet.appendChild(ei);
                eii = document.createElement("div");
                eii.setAttribute("class", "list-image-div");
                eii.setAttribute("style", imageSizeAttributes(pictureSize, pictureSize)
                                      + " background-image: url(" + imageDefsToAdd[i].src + ");" );
                ei.appendChild(eii);
                eit = document.createElement("div");
                eit.setAttribute("class", "list-image-text text-wrap");
                eit.setAttribute("style", "font-size: " + fs + ";"
                                        + visibilityAttribute(imageDefsToAdd[i].title) );
                eit.appendChild( document.createTextNode(imageDefsToAdd[i].title) );
                ei.appendChild(eit);
            }
        }
    } else if (displayType === FGLGALLERY_TYPE_THUMBNAILS) {
        main.classList.add("thumbnails-main");
        imageSet.classList.add("thumbnails-imgset");
        imageSet.style.display = "block";
        var sci = (pictureSize * 1.2) + "em";
        var sii = (pictureSize * 0.3);
        fs = imageTitleFontSize(1);
        imageCurrent.style.display = "block";
        imageCurrentImage.style.height = sci;
        imageCurrentImage.style.maxHeight = sci;
        imageCurrentTitle.style.fontSize = fs;
        imageCurrentTitle.classList.add("thumbnails-current-image-text");
        for( i = 0; i < length; i+=1 ) {
            var id=imageDefsToAdd[i].id;
            var idp=getPictureId(id);
            if ( getPictureElement(id) === null) {
                ei = document.createElement("li");
                ei.setAttribute("class", "thumbnails-image-li");
                ei.setAttribute("id", getPictureId(i));
                ei.setAttribute("data-src", imageDefsToAdd[i].src);
                ei.setAttribute("onclick", "imageClicked(this.id)");
                imageSet.appendChild(ei);
                eii = document.createElement("div");
                eii.setAttribute("class", "thumbnails-image-div");
                eii.setAttribute("style", imageSizeAttributes(sii, sii)
                                      + " background-image: url(" + imageDefsToAdd[i].src + ");" );
                ei.appendChild(eii);
            }
        }
    }

    if (myLazyLoad !== null) {
        myLazyLoad.update();
    }
}

function display(displayType, displaySize, aspectRatio)
{
    if (displayType !== currentDisplayType
        || displaySize !== currentDisplaySize
        || aspectRatio !== currentAspectRatio
    ) {
        destroyDisplay(currentDisplayType);
    }

    if (displaySize === null) {
        currentDisplaySize = 2;
    } else {
        currentDisplaySize = displaySize;
    }
    pictureSize = displaySize * 3;

    currentDisplayType = displayType;

    if (aspectRatio === null) {
        currentAspectRatio = 0;
    } else {
        currentAspectRatio = aspectRatio;
    }

    addToDisplay(displayType, imageDefs);

    isDisplayed = true;
}

function toggleSelection(index) {
    if (index <0 || index >= imageDefs.length) {
        return;
    }
    var id=imageDefs[index].id;
    var el=getPictureElement(id);
    if (el===null) {
        console.log("toggleSelection:no el for:"+imageDebugStr(imageDefs[index]) );
        return;
    }
    if (imageDefs[index].selected === false) {
        imageDefs[index].selected = true;
        el.classList.add("image-selected");
    } else {
        imageDefs[index].selected = false;
        el.classList.remove("image-selected");
    }
    console.log("toggled:"+imageDebugStr(imageDefs[index]));
}

function sendSelectionByIndex(index, toggle, makeVisible)
{
    setNewCurrent(index, makeVisible);
    if (toggle === true && isMultipleSelection === true) {
        toggleSelection(index);
    }
    if (currentDisplayType === FGLGALLERY_TYPE_THUMBNAILS) {
        setThumbnailsCurrentImage(imageDefs[index].src, imageDefs[index].title);
    }
    if (galleryOptions.selection !== null) {
        setFieldValue();
        gICAPI.Action(galleryOptions.selection);
    }
    clickedIndex = -1;
}

function imageClicked(imageId)
{
    if (isActive) {
        clickedIndex=-1;
        for(var i=0;i<imageDefs.length;i++) { 
          if (imageId==getPictureId(imageDefs[i].id)) {
            clickedIndex=i;
            break;
          }
        }
        if (hasFocus === true) {
            sendSelectionByIndex(clickedIndex, true, false);
        } else {
            gICAPI.SetFocus();
        }
    }
}

function visibilityAttribute(text)
{
    if (text === null) {
        return "visibility: hidden;";
    } else {
        return "";
    }
}

function destroyDisplay(type)
{
    var imageCurrent = document.getElementById("imageCurrent");
    imageCurrent.style.display = "none";
    var imageSet = document.getElementById("imageSet");
    imageSet.style.display = "none";
    while (imageSet.firstChild) { imageSet.removeChild(imageSet.firstChild); }
    isDisplayed = false;
}

function catchKeys()
{
    document.addEventListener("keydown",function(e) {
        if (isActive) {
            var k_next = undefined;
            var k_prev = undefined;
            if (currentDisplayType === FGLGALLERY_TYPE_MOSAIC
             || currentDisplayType === FGLGALLERY_TYPE_THUMBNAILS) {
                k_prev = "ArrowLeft";
                k_next = "ArrowRight";
            } else {
                k_prev = "ArrowUp";
                k_next = "ArrowDown";
            }
            if (e.key === k_next && currentIndex < imageDefs.length - 1) {
                e.preventDefault();
                sendSelectionByIndex(currentIndex + 1, false, true);
            } else if (e.key === k_prev && currentIndex > 0) {
                e.preventDefault();
                sendSelectionByIndex(currentIndex - 1, false, true);
            } else if (e.key === " ") {
                e.preventDefault();
                if (currentIndex > -1 && isMultipleSelection) {
                    sendSelectionByIndex(currentIndex, true, true);
                }
            }
        } else {
            e.preventDefault();
        }
    });
}

function deleteImages(ids)
{
    // go thru the ids and delete them
    for ( var i=0; i<ids.length; i+=1 ) {
       var id=ids[i].id;
       var idp=getPictureId(id);
       var e = getPictureElement(id);
       if (e!==null) {
         console.log("remove el:"+idp);
         e.parentNode.removeChild(e);
       }
       var imgDef = imgHash[idp];
       imgHash[idp]=undefined;
       for (var j=0;j<imageDefs.length;j++) {
         var arrDef=imageDefs[j];
         if (arrDef.id==id) {
           if (imgDef!=arrDef) {
             console.log("bummer");
           }
           console.log("remove imageDef:"+imageDebugStr(arrDef));
           imageDefs.splice(j, 1);
           break; 
         }
       }
    }
    // Adjust currentIndex
    if (currentIndex > -1) {
        if (currentIndex >= imageDefs.length) {
            currentIndex = (imageDefs.length - 1);
            console.log("adjust currentIndex to:"+currentIndex+" after delete");
        }
    }
    // Load images that were not yet visible
    if (myLazyLoad !== null) {
        myLazyLoad.update();
    }
}

function checkMultipleSelection(sel)
{
  if (sel==isMultipleSelection) {
    return;
  }
  setMultipleSelection(sel);
}

function setMultipleSelection(ms)
{
    if (ms) {
        isMultipleSelection = true;
    } else {
        isMultipleSelection = false;
        cleanSelection();
    }
}

function cleanSelection() {
    var i = 0;
    for ( var i=0; i<imageDefs.length; i+=1 ) {
        imageDefs[i].selected = false;
    }
}

function showSelection() {
    var i = 0;
    for ( i=0; i<imageDefs.length; i+=1 ) {
        var id=imageDefs[i].id;
        var el=getPictureElement(id);
        if (el===null) {
          continue;
        }
        if (isMultipleSelection && imageDefs[i].selected === true) {
            el.classList.add("image-selected");
        } else {
            el.classList.remove("image-selected");
        }
    }
}
