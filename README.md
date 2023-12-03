# PromptAI Coding Challenge

A media album iOS app. I think I hit all the essential and secondary features, so here I'll just talk a little bit about the components that made this work.

The magic behind the scenes is the Many-to-Many Core Data relationship I set up between photos and folders. Working out the logic for photo-folder relationships was a mess before I found this feature; I think I spent a day just building the Folder view and half of the InsideFolder view (while manually handling relationships), and after I found CD relationships I spent the next day building everything else. Core Data is also just a really good framework to use for building scalable apps, since it focuses on the Object Graph while abstracting away the database layer, which = maintainable code even with complex relationships (plus persistence is built in). 

Also, I used an AVPlayer to handle videos, which is fine since it plays the video and is easy to implement, but I think it might be slowing things down. Would look into alternatives if this app were to be expanded upon.

Lastly, I decided to sprinkle on an image classification model using CoreML, as I'm guessing PromptAI is gonna use AI. You can try it out by going into the individual image views by tapping on an image in the Gallery, and clicking 'Run Object Detection'. Not super hard to implement once you know how to use CoreML - this was just a proof of concept for future models.

To run this, download the repo and open it in Xcode. You can either use the ContentView.swift Preview or run the simulator. If the ML model isn't downloading properly, you can download it from here: https://developer.apple.com/machine-learning/models/
