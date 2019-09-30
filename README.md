# ex_wwdc19_wc_fglgallery
WWDC2019 fglgallery webcomponent sample ( modifying the  stock fglgallery  implementation to avoid additional network round trips caused by frontcalls and unwanted side effects )

This example focuses on removing webcomponent frontcalls internally and replaces it
by a complete serialization/deserialization the gallery model via JSON.
Why ?
This is eliminating unwanted unforeseeable flicker side effects (see WWDC19 talk)
Ensures best performance in all network configurations
Enables the browser to draw the whole DOM en bloc (with frontcalls after each frontcall the browser recomputes and draws the DOM in addition to the value changes)

It needs adaptation of the current fglgallery API (No 100% compatible replacement ), because the original implementation already uses the webcomponents value for the selection model.
Result:
All features are working with roughly the same number of code lines.
The fglgallery model is synced along all other UI changes "en bloc".
Multiple galleries in one form do not cause the multiplication of network roundtrips.

Note the implementation could be further enhanced by not exchanging the whole gallery model at once.
But the limiting factor for fglgallery is not the model itself, the pure amount of image data which is needed to be transferred is the limiting factor.

To compare the code with the stock fglgallery code just do
    vimdiff fglgallery.4gl fglgallery.4gl.orig
    vimdiff simple_gallery.4gl simple_gallery.4gl.orig
    vimdiff fglgallery_demo.4gl fglgallery_demo.4gl.orig
    vimdiff webcomponents/fglgallery/js/fglgallery.js webcomponents/fglgallery/js/fglgallery.js.orig
