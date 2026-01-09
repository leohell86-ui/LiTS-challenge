// Define folders
dir = "C:/Users/giova/Desktop/LaureaMagistrale/ImageProcessing/Project5data/Training/";
saveDir = "C:/Users/giova/Desktop/RISULTATI/";

// Ask user using a choice dropdown
Dialog.create("Segmentation Type");
Dialog.addMessage("What would you like to segment?");
Dialog.addChoice("Select:", newArray("Whole Liver", "Tumor", "Tumor+Liver"), "Whole Liver");
Dialog.show();
button = Dialog.getChoice();
	
// Check the answer
flagTumorLiver = false;
thresholdMin = 1;
if (button == "Tumor") {thresholdMin = 2;}
else if (button == "Tumor+Liver") {flagTumorLiver = true; thresholdMin = 2;}

////////////////////////////////////
// SET WICH FILE YOU WANT TO OPEN //
////////////////////////////////////
for (i = 4; i <= 4; i++) { 

	// Make sure ROI Manager is open
	if (!isOpen("ROI Manager")) {
    	run("ROI Manager...");
	}

	// Reset everything
	roiManager("Reset");
	run("Close All");

	// Close Weka Segmentation windows if any are open
	list = getList("window.titles");
	for (j = 0; j < list.length; j++) {
    	title = list[j];
    	if (startsWith(title, "Trainable Weka Segmentation")) {
        	selectWindow(title);
        	close();
    		}
	}

	// Construct file paths
	volumeFile = dir + "volume-" + i + ".nii";
	segmentationFile = dir + "segmentation-" + i + ".nii";
	
	// Open volume via Bio-Formats and convert to 8-bit 
	run("Bio-Formats Importer",
	    "open=[" + volumeFile + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
	volumeID = getImageID();
	run("8-bit");
	
	// Open segmentation via Bio-Formats and convert to 8-bit
	run("Bio-Formats Importer",
	    "open=[" + segmentationFile + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
	segID = getImageID();

	// Threshold segmentation BEFORE converting to 8-bit

	if (!flagTumorLiver) {
	    // Single threshold
	    selectImage(segID);
	    setThreshold(thresholdMin, 255);
	    run("Convert to Mask");
	    rename("mask");
	    
	    // Remove empty slices
		numSlices = nSlices();

		firstSlice = 0;
		for (s = 1; s <= numSlices; s++) {
		    setSlice(s);
		    getStatistics(area, mean, min, max);
		    if (max != 0) { firstSlice = s; break; }
		}
		

		lastSlice = 0;
		for (s = numSlices; s >= 1; s--) {
		    setSlice(s);
		    getStatistics(area, mean, min, max);
		    if (max != 0) { lastSlice = s; break; }
		}
	    
	    if (firstSlice == 0 || lastSlice == 0 || firstSlice > lastSlice) {
		    showMessage("Warning", "The ROI is empty.");
		} else {
			
			// --- Keep only slices between firstSlice and lastSlice using Slice Keeper ---
			selectImage(segID);
			run("Slice Keeper", "first=" + firstSlice + " last=" + lastSlice + " increment=5");
			trimmedsegID = getImageID();
			
			selectImage(volumeID);
			run("Slice Keeper", "first=" + firstSlice + " last=" + lastSlice + " increment=5");
			trimmedvolumeID = getImageID();
			}
		
			// --- Re-convert segmentation to mask after trimming ---
			selectImage(trimmedsegID);
			run("Convert to Mask");
		
			// --- Create ROIs from the 8-bit mask ---
			roiManager("Reset");
			numSlices = nSlices();
			for (s = 1; s <= numSlices; s++) {
			    setSlice(s);
			    getStatistics(area, mean, min, max);
			    if (max == 0) {
			        // Empty slice: skip ROI but still maintain alignment
			        continue;
			    }
			    run("Create Selection");
			    roiManager("Add");
			}
		    
		    // --- Open Weka Trainable Segmentation 3D ---
		    selectImage(trimmedvolumeID);
		    run("Trainable Weka Segmentation 3D");
		    wait(2000);   // allow time to initialize
		
		    // --- Add each ROI in ROI Manager to Weka Class 1 (class index 0) ---
		    nROI = roiManager("count");
		    for (r = 0; r < nROI; r++) {
		        roiManager("Select", r);
		        call("trainableSegmentation.Weka_Segmentation.addTrace", "0", r+1);
	    }
	    
	    
	} else {
	
		// --- Select the Segmentation and convert it to mask ---
		selectImage(segID);
		setThreshold(1, 255);
		run("Convert to Mask");
		
		// Remove empty slices
		numSlices = nSlices();

		firstSlice = 0;
		for (s = 1; s <= numSlices; s++) {
		    setSlice(s);
		    getStatistics(area, mean, min, max);
		    if (max != 0) { firstSlice = s; break; }
		}
		

		lastSlice = 0;
		for (s = numSlices; s >= 1; s--) {
		    setSlice(s);
		    getStatistics(area, mean, min, max);
		    if (max != 0) { lastSlice = s; break; }
		}
	    
	    if (firstSlice == 0 || lastSlice == 0 || firstSlice > lastSlice) {
		    showMessage("Warning", "The ROI is empty.");
		} else {
			
			// --- Keep only slices between firstSlice and lastSlice using Slice Keeper ---
			selectImage(segID);
			run("Slice Keeper", "first=" + firstSlice + " last=" + lastSlice + " increment=1");
			trimmedsegID = getImageID();
			
			selectImage(volumeID);
			run("Slice Keeper", "first=" + firstSlice + " last=" + lastSlice + " increment=1");
			trimmedvolumeID = getImageID();
			}
		
			
		selectImage(trimmedvolumeID);
		volTitle = getTitle();
		selectImage(trimmedsegID);
		segTitle = getTitle();
		
		run("Image Calculator...",
		    "image1=[" + volTitle + "] image2=[" + segTitle + "] operation=Min create stack");
		
		resultID = getImageID();
		
		// --- Closes the Segmentation Mask without saving ---
		setBatchMode(true);
		selectImage(segID);
		close();
		setBatchMode(false);
			
		// --- Open the Segmentation again ---
		run("Bio-Formats Importer",
	    "open=[" + segmentationFile + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
		segID = getImageID();			
			
		// --- Select the Segmentation and convert it to mask ---
		selectImage(segID);
	    setThreshold(thresholdMin, 255);
	    run("Convert to Mask");
	    rename("mask");	
	    
	    	// Remove empty slices
		numSlices = nSlices();

		firstSlice = 0;
		for (s = 1; s <= numSlices; s++) {
		    setSlice(s);
		    getStatistics(area, mean, min, max);
		    if (max != 0) { firstSlice = s; break; }
		}
		

		lastSlice = 0;
		for (s = numSlices; s >= 1; s--) {
		    setSlice(s);
		    getStatistics(area, mean, min, max);
		    if (max != 0) { lastSlice = s; break; }
		}
	    
	    if (firstSlice == 0 || lastSlice == 0 || firstSlice > lastSlice) {
		    showMessage("Warning", "The ROI is empty.");
		} else {
			
			// --- Keep only slices between firstSlice and lastSlice using Slice Keeper ---
			selectImage(segID);
			run("Slice Keeper", "first=" + firstSlice + " last=" + lastSlice + " increment=1");
			trimmedsegID = getImageID();
		
		// 
		selectImage(trimmedsegID);
		run("Convert to Mask");
		
		// --- Create ROIs from the 8-bit mask ---
		numSlices = nSlices();
		for (s = 1; s <= numSlices; s++) {
		    setSlice(s);
		    getStatistics(area, mean, min, max);
		    if (max == 0) {
		        // Empty slice: skip ROI but still maintain alignment
		        continue;
		    }
		    run("Create Selection");
		    roiManager("Add");
		}	
			
		// --- Open Weka Trainable Segmentation 3D ---
		selectImage(resultID);
		run("Trainable Weka Segmentation 3D");
		wait(2000);
	
	    // --- Add each ROI in ROI Manager to Weka Class 1 (class index 0) ---
	    nROI = roiManager("count");
	    for (r = 0; r < nROI; r++) {
	        roiManager("Select", r);
	        call("trainableSegmentation.Weka_Segmentation.addTrace", "0", r+1);
    	}

	}
	// --- Prompt user to load ROI in Weka 3D ---
    waitForUser("Manual step", "Click when you finished the training.\nClick OK to continue.");
	
}