// --- Define folders --- 
dir = "C:/Users/giova/Desktop/LaureaMagistrale/ImageProcessing/Project5data/Training/";
saveDir = "C:/Users/giova/Desktop/RISULTATI/";

// Make sure ROI Manager is open
if (!isOpen("ROI Manager")) {
    run("ROI Manager...");
}

// --- Loop over volumes ---
for (i = 0; i <= 0; i++) {  // change 0 to 129 for full batch

    // --- Construct file paths ---
    volumeFile = dir + "volume-" + i + ".nii";
    segmentationFile = dir + "segmentation-" + i + ".nii";

    // --- Open volume and convert to 8-bit ---
    open(volumeFile);
    volumeID = getImageID();
    run("8-bit");

    // --- Open segmentation and convert to 8-bit ---
    open(segmentationFile);
    segID = getImageID();
    run("8-bit");

    // --- Remove empty slices ---
    selectImage(segID);
    numSlices = nSlices();
    for (s = numSlices; s >= 1; s--) {
        setSlice(s);
        getStatistics(area, mean, min, max, std, histogram);
        if (max == 0) {
            run("Delete Slice"); 
            selectImage(volumeID);
            setSlice(s);
            run("Delete Slice"); 
            selectImage(segID);
        }
    }

	// --- Ask user for percentage of slices to keep ---
	percentage = 20;
	if (percentage < 1) percentage = 1;
	if (percentage > 100) percentage = 100;

	// --- Calculate step ---
	step = round(100 / percentage); // e.g., 20% -> step = 5 (keep 1 in 5 slices)

	// --- Downsample slices in volume ---
	selectImage(volumeID);
	numSlices = nSlices();
	for (s = numSlices; s >= 1; s--) {
    	if ((s % step) != 1) {  // keeps 1 slice every 'step'
        	setSlice(s);
        	run("Delete Slice");
    	}
	}

	// --- Downsample slices in segmentation ---
	selectImage(segID);
	numSlices = nSlices();
	for (s = numSlices; s >= 1; s--) {
    	if ((s % step) != 1) {
        	setSlice(s);
        	run("Delete Slice");
    	}
	}




    // --- Threshold segmentation (>=1) and create ROIs ---
    selectImage(segID);
    setThreshold(1, 255);
    run("Convert to Mask");
    roiManager("Reset");
    numSlices = nSlices();
    for (s = 1; s <= numSlices; s++) {
        setSlice(s);
        run("Create Selection");
        roiManager("Add");
    }

    // --- Open Weka Trainable Segmentation 3D ---
    selectImage(volumeID);
    run("Trainable Weka Segmentation 3D");
    waitForUser("Confirm", "Check that Weka 3D opened correctly.\nClick OK to continue.");

    // --- Prompt user to load ROI in Weka 3D ---
    waitForUser("Manual step", "Now load all the ROI as class 1 in Weka 3D.\nClick OK to continue.");

    // --- Optional: save processed images ---
    // selectImage(volumeID);
    // saveAs("NIfTI", saveDir + "volume-" + i + "-processed.nii");
    // selectImage(segID);
    // saveAs("NIfTI", saveDir + "segmentation-" + i + "-processed.nii");

    // --- Optional: cleanup ---
    // close(volumeID);
    // close(segID);
    // close(maskID);
}
