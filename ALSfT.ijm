//Automatic Liver Segmenation for Training

//--- DIRECTORIES ---

// Define folder from where you will access your data
dir = "C:/Users/giova/Desktop/LaureaMagistrale/ImageProcessing/Project5data/Training/";
testdir = "C:/Users/giova/Desktop/LaureaMagistrale/ImageProcessing/Project5data/Test/";
// Define folders from where you will save your data
saveDir = "C:/Users/giova/Desktop/RISULTATI/";

//--- FUNCTIONS ---------------------------------------------------------------------------------------------------------------------------------------------------------

// Asks what type of segmentation you want to do
// Whole Liver: uses the normal image in Weka and upload as a ROI the Liver
// Tumor: uses the normal image in Weka and uploads the ROI of the Tumor
// Tumor+Liver: uses just the Liver in Weka and uploads the ROI of the Tumor
// Testing: just opens a file in weka
function askSegmentationType() {
    Dialog.create("Segmentation Type");
    Dialog.addMessage("What would you like to segment?");
    Dialog.addChoice("Select:", newArray("Whole Liver", "Tumor", "Tumor+Liver","Testing"), "Whole Liver");
    Dialog.show();

    choice = Dialog.getChoice();

    flagTumorLiver = false;
    flagTest = false;
    thresholdMin = 1;

    if (choice == "Tumor") {
        thresholdMin = 2;
    } else if (choice == "Tumor+Liver") {
        thresholdMin = 2;
        flagTumorLiver = true;
    }else if (choice =="Testing"){
    	flagTest = true;
    }
    
    return newArray(choice, thresholdMin, flagTumorLiver,flagTest);
}

// Ask what method to use to select the training slices
// Border Search: looks for the first and the last slice != 0 (prone to syncronization issues) 
// Max > 0: Looks for the the slices with max > 0 (prone to spatial issues)
function askTrimm() {
    Dialog.create("Type of Trimming");
    Dialog.addMessage("How would you like to select your slices?");
    Dialog.addChoice("Select:", newArray("Border Search", "Max > 0"), "Border Search");
    Dialog.show();

    choice = Dialog.getChoice();
    
    flagTrimm = false;
    
    if (choice == "Max > 0") {
        flagTrimm = true;
    } 
    
    return flagTrimm;
}


// Asks the increment you want to use for slicekeeper (you can also set you default answer by changing the numbers below)
function askIncrement() {
    Dialog.create("Increment");
    Dialog.addMessage("Enter increment value (positive integer):");
    Dialog.addNumber("Increment:",5); //<---
    Dialog.show();

    inc = Dialog.getNumber();
    
    // check integer and positivity
    if (inc <= 0 || inc != floor(inc)) {
        showMessage("Error", "Increment must be a positive integer.");
        exit();
    }

    return inc;
}

// Asks the range of the images one wants to study (you can also set you default answer by changing the numbers below)
function askFirstLastImage() {

    Dialog.create("Image Range");
    Dialog.addMessage("Select image range to analyze:");
    Dialog.addNumber("First image:",26); //<---
    Dialog.addNumber("Last image:",26); //<---
    Dialog.show();

    firstImg = Dialog.getNumber();
    lastImg  = Dialog.getNumber();

    // Validate positive integers
    if (firstImg < 0 || lastImg < 0 ||
        firstImg != floor(firstImg) ||
        lastImg  != floor(lastImg)) {
        showMessage("Error", "Both values must be positive integers.");
        exit();
    }

    // Validate order
    if (firstImg > lastImg) {
        showMessage("Error", "First image must be smaller than last image.");
        exit();
    }

    return newArray(firstImg, lastImg);
}


// Opens the selected path
function open_file (path)
{
		run("Bio-Formats Importer","open=[" + path + "] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
}

// Closes the selected image without saving it
function close_silent (image_to_close)
{
		setBatchMode(true);
		selectImage(image_to_close);
		close();
		setBatchMode(false);
}

// Opens and resets ROI manager, closes all the images and Weka Segmentation windows
function startup ()
{
	
	if (!isOpen("ROI Manager")) {
    	run("ROI Manager...");
	}
	
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
}


// Check if the tumor exist by controlling if the maximum intensity of the semgnetation is = 2
function tumor_check (segmentation)
{
	selectImage(segmentation);
	numSlices = nSlices();
	maximum = 0;
	for (s = 1; s <= numSlices; s++) {
		setSlice(s);
		getStatistics(area, mean, min, max);
		if (max >= maximum) {
			maximum = max;	
		}
	}
	// if the maximum is != 2 it tells the user
	if (maximum != 2) {
		waitForUser("ERROR", "There is no tumor.\nClick OK to continue.");
		continue;
	}
}

// Removes all the slice that have maximum = 0 in the segmentation, both for volume and segmentation
// This resolves the Syncronization issue while breaking the space dimension
// (you have to feed the already thresholded mask for the tumor case)
function keep_full_double (seg_mask,vol)
{
	setBatchMode(true);
	
	selectImage(seg_mask);
	numSlices = nSlices();
	for(s=numSlices; s>=1; s--)
	{
		selectImage(seg_mask);
		setSlice(s);
		getStatistics(area, mean, min, max);
		
		if(max == 0)
		{
			run("Delete Slice");
			
			selectImage(vol);
			setSlice(s);
			run("Delete Slice");
		}
		
	}
	selectImage(seg_mask);
	trimsegID = getImageID();
	selectImage(vol);
	trimvolID = getImageID();
	
	setBatchMode(false);
	
	return newArray(segID, volID);
}

// Same as above but just for the mask
function keep_full (seg_mask)
{
	setBatchMode(true);
	selectImage(seg_mask);
	numSlices = nSlices();
	for(s=numSlices; s>=1; s--)
	{
		selectImage(seg_mask);
		setSlice(s);
		getStatistics(area, mean, min, max);
		
		if(max == 0)
		{
			run("Delete Slice");
		}
	}
	selectImage(seg_mask);
	trimsegID = getImageID();
	
	setBatchMode(false);
	
	return getImageID();
}

// Calculates the first and last slice of a mask that have maximum gray level != 0
function first_last (reference_mask)
{
	selectImage(reference_mask);
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
	    continue;
	}
	
	return newArray(firstSlice, lastSlice);
} 

// Runs slice keeper with the calculated settings
function slice_keep(full_image, first_slice, last_slice, increment)
{
	selectImage(full_image);
	run("Slice Keeper", "first=" + first_slice + " last=" + last_slice +  " increment=" + increment);
} 

// Thresholds the given image and binarizes it
function turn_to_mask (segmentation, threshold)
{
	selectImage(segmentation);
	setThreshold(threshold, 255);
	run("Convert to Mask", "background=Dark black");
}

// Calculates the minimum between the Liver mask and the orignal image
function calculate_minimum(original, liver) 
{
    selectImage(original);
    originalTitle = getTitle();
    selectImage(liver);
    liverTitle = getTitle();

    run("Image Calculator...", 
        "image1=[" + originalTitle + "] image2=[" + liverTitle + "] operation=Min create stack");
        
}

// Creates the ROI (IT HAS SYNCRONIZATION PROBLEMS)
function create_roi (segmentation_to_convert)
{
	selectImage(segmentation_to_convert);
	numSlices = nSlices();
	
	for (s = 1; s <= numSlices; s++) {
		
	    setSlice(s);
	    getStatistics(area, mean, min, max);
	    
        if (max > 0) {
            run("Create Selection");
            roiManager("Add");
        } else {
            run("Select None");
        }
    }
}


// Open Weka Trainable Segmentation 3D
function open_weka (volume_to_analize)
{
    selectImage(volume_to_analize);
    run("Trainable Weka Segmentation 3D");
    wait(5000);
    // select all the desired features
    call("trainableSegmentation.Weka_Segmentation.setFeature", "Hessian=true");
	call("trainableSegmentation.Weka_Segmentation.setFeature", "Laplacian=true");
	call("trainableSegmentation.Weka_Segmentation.setFeature", "Structure=true");
	call("trainableSegmentation.Weka_Segmentation.setFeature", "Edges=true");
}


// Add each ROI in ROI Manager to Weka Class 1
function add_roi ()
{
    nROI = roiManager("count");
    for (r = 0; r < nROI; r++) {
        roiManager("Select", r);
        call("trainableSegmentation.Weka_Segmentation.addTrace", "0", r+1);
	}
}

//--- LEO FUNCTIONS (TO BE ADAPTED OR IMPLEMENTED)---------------------------------------------------------------------------------------------------------------------------------------------------------

// Creates a ROI assigning to each a unique id
function create_ROI(segmentation_to_convert){
	roiManager("reset");
	selectImage(segmentation_to_convert);
	n_slices = nSlices();
	
	for (j = 1; j <= n_slices; j++){
		setSlice(j);
		getRawStatistics(nPixels, mean, min, max, std);
		if (max == 0){
			continue;
		}
	    run("Create Selection");
	    if (selectionType() == -1)
	    	continue;
	    roiManager("Add");
	    idx = roiManager("Count")-1;
	    roiManager("select", idx);
	    roiManager("Rename", "Slice_" + i + "_" + j);
	}
}

// Creates a copy of the given array, one cell longer and fills it with "value"

function append(arr, value) {
    n = arr.length;
    newArr = newArray(n + 1);
    if (n == 0){
    	newArr[0] = value;
    }
    else {
    for (k = 0; k < n; k++){
        newArr[k] = arr[k];
    	newArr[n] = value;
    }
    }
    return newArr;
}

// Adds the ROI in ROI manager to weka to a given class
function set_class(Indexes, class_number){
	for (z = 0; z < Indexes.length; z++){
		roiManager("Select", Indexes[z]);
		call("trainableSegmentation.Weka_Segmentation.addTrace", class_number , z+1);
	}
}


// --- CODE ---------------------------------------------------------------------------------------------------------------------------------------------------------

startup();

//This can be set manually by changing first and last to be what you want
range = askFirstLastImage();
first = range[0];
last  = range[1];
// Example: first = 0; last = 10;


flagTrimm = askTrimm();


//This can be set manually by changing Incr to be what you want
Incr = askIncrement();
// Example: Incr = 5;

result = askSegmentationType();

segType        = result[0];
thresholdMin   = result[1];
flagTumorLiver = result[2];
flagTest = result[3];

for (i = first; i <= last; i++)
{
	// Construct file paths
	volumeFile = dir + "volume-" + i + ".nii";
	segmentationFile = dir + "segmentation-" + i + ".nii";
	testFile = testdir + "test-volume-" + i + ".nii";

	if(flagTest == true)
	{
		// Opens the test path
		Incr = 1;
		open_file(testFile);
		testID = getImageID();
		run("8-bit");
		open_weka(testID);
		
	}else{
		// Opens the training part
		open_file(volumeFile);
		volID = getImageID();
		selectImage(volID);
		rename("volID");
	
		open_file(segmentationFile);
		segID = getImageID();
		selectImage(segID);
		rename("segID");
	
		if(thresholdMin == 2)
		{
			tumor_check(segID);
		}
		
		turn_to_mask(segID,thresholdMin);
		mask_keep = getImageID();
		selectImage(mask_keep);
		rename("mask_keep");
		
		if (!flagTumorLiver)
		{
			
			if(flagTrimm== true)
			{

				ids = keep_full_double(mask_keep, volID);
				trimsegID = ids[0];
				trimvolID = ids[1];

				
			}else {
				
				keep = first_last(mask_keep);
				firstSlice = keep[0];
				lastSlice  = keep[1];
				
				slice_keep(volID, firstSlice, lastSlice, Incr);
				trimvolID = getImageID();

				slice_keep(mask_keep, firstSlice, lastSlice, Incr);
				trimsegID = getImageID();

			
			}
	
			selectImage(trimvolID);
			rename("trimvolID");
			run("8-bit");

			selectImage(trimsegID);
			rename("trimsegID");
			
			turn_to_mask(trimsegID,thresholdMin);
			ROI = getImageID();
			selectImage(ROI);
			rename("ROI");
			run("8-bit");
			
			selectImage(trimvolID);
			Train = getImageID();
			selectImage(Train);
			rename("Train");
			
		}else{	
			
			if(flagTrimm == true)
			{
				
				ids = keep_full_double(mask_keep,volID);
				trimsegID = ids[0];
				
				trimvolID = ids[1];
				selectImage(trimvolID);
				run("8-bit");
				
				open_file(segmentationFile);
				segment = getImageID();
				selectImage(segment);
				rename("segment");
				
				turn_to_mask(segment,1);
				segment_mask = getImageID();
				selectImage(segment_mask);
				rename("segment_mask");
				
				open_file(segmentationFile);
				segmentID = getImageID();
				turn_to_mask(segmentID,thresholdMin);
				mask_keep_2 = getImageID();
				selectImage(mask_keep_2);
				rename("mask_keep_2");
				
				keep_full_double(mask_keep_2,segment_mask);
				
				turn_to_mask (segment_mask, thresholdMin);
				liver = getImageID();
				selectImage(liver);
				run("8-bit");
				rename("liver");
				
			}else{
				
				keep = first_last(mask_keep);
				firstSlice = keep[0];
				lastSlice  = keep[1];
				
				slice_keep(volID, firstSlice, lastSlice, Incr);
				trimvolID = getImageID();
				run("8-bit");
				
				open_file(segmentationFile);
				segment = getImageID();
				slice_keep(segment, firstSlice, lastSlice, Incr);
				trimsegID = getImageID();
				
				turn_to_mask (trimsegID, 1);
				liver = getImageID();

			}



			calculate_minimum(trimvolID, liver);
			Train = getImageID();
			
			open_file(segmentationFile);
			segm = getImageID();
			
			
			
			if(flagTrimm == true)
			{
				
				ROI = keep_full(segm);
				
			}else {
				
				slice_keep(segm, firstSlice, lastSlice, Incr);
				
			}

			ROI = getImageID();
			turn_to_mask(ROI,thresholdMin);
			run("8-bit");
		}
	
	//create_ROI(ROI);
	//number_slices = nSlices();
	//Idx_liv = newArray(0);
	//for (j = 0; j <= number_slices; j++){
	//    Idx_liv = append(Idx_liv, j);
	//}
	//open_weka(Train);
	//set_class(Idx_liv,0);
	
	create_roi (ROI);
	open_weka(Train);
	add_roi();
	
	}
	
// --- Prompt user to start the traning in Weka 3D ---
waitForUser("Manual step", "Click when you finished the training or testing on the current image.\nClick OK to continue.");

}