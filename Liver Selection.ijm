// functions

function make_path(num,type,Batch){
	// type is either "segmentation" or "volume", Batch is either 1 or 2
	// insert your directory
	return "C:\\Users\\leona\\OneDrive\\Dokumente\\Leo\\Uni\\Semester 11\\Immage Processing\\Training_Batch"
	+ Batch + "\\media\\nas\\01_Datasets\\CT\\LITS\\Training Batch "
	+ Batch + "\\" + type + "-" + num + ".nii";
}

function open_file(path){
	run("Bio-Formats Importer",
    "open=[" + path + "] " +
    "autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
	run("8-bit");
}

function slicing(set_num_slices){
	n = nSlices();
	start = -1;
	end = -1;

	//finding first liver slice and last liver slice
	for (i = 1; i <= n; i++){
		setSlice(i);
		getStatistics(area, mean, min, max);
		if (max > 0){
			if (start == -1){
				start = i;
			}
		}
		if (max == 0){
			if (start > end){
				end = i-1;
			}
		}
	}
	
	if (end == -1){
		end = n;
	}
	step = floor((end - start)/set_num_slices);
	slice_string = "" + start + "-" + end + "-" + step;
	run("Make Substack...", "slices=" + slice_string );
	return newArray(start,end);
}

function slicing_CT(set_num_slices,lim){
	start = lim[0];
	end = lim[1];
	n = nSlices();
	step = floor((end - start)/set_num_slices);
	slice_string = "" + start + "-" + end + "-" + step;
	run("Make Substack...", "slices=" + slice_string );
}

function bin_liver() {
	setThreshold(1, 255);
	run("Convert to Mask", "background=Dark black");
}

function create_ROI(n_slices,CT_num){
	run("ROI Manager...");
	roiManager("reset");
	
	for (i = 1; i <= n_slices; i++){
		setSlice(i);
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
	    roiManager("Rename", "Slice_" + CT_num + "_" + i);
	}
}

function get_negative(thresh, CT_num){
	for (i = 1; i <= n_new; i++){
		getRawStatistics(nPixels, mean, min, max, std);
		setThreshold(thresh, max);
		run("Create Selection");
		
		if (selectionType() == -1)
	    	continue;
	    roiManager("Add");
	    idx = roiManager("Count")-1;
	    roiManager("Select", idx);
	    roiManager("Rename", "CT_Slice_" + CT_num + "_" + i);
	}
	
	for (i = 1; i <= n_new; i++){
		roiManager("Select", newArray(i-1,i+n_new-1));
		roiManager("XOR");
		roiManager("Add");
		idx = roiManager("Count")-1;
	    roiManager("Select", idx);
	    roiManager("Rename", "Anti_Slice_" + CT_num + "_" + i);
	}
}

function ROI_index_by_name(targetName) {
    imgTitle = getTitle();
	listTitle = "Overlay Elements of " + imgTitle;
	if(isOpen(listTitle)){
		selectWindow(listTitle);
		run("Close");
	}
	roiManager("List");
	nRows = Table.size(listTitle);
	if (nRows == 0){
		return -1
	}
	for (i = 0; i < nRows; i++){
		roiName = Table.getString("Name",i, listTitle);
		if (roiName == targetName){
			selectWindow(listTitle);
			run("Close");
			return i;
		}
	}
}

function append(arr, value) {
    n = arr.length;
    newArr = newArray(n + 1);
    if (n == 0){
    	newArr[0] = value;
    }
    else {
    for (i = 0; i < n; i++){
        newArr[i] = arr[i];
    	newArr[n] = value;
    }
    }
    return newArr;
}

function cut_liver(Indexes_liver,Indexes_bg,CT_num,type,lvl,width){
	C2_Indexes = newArray(0);
	n = Indexes_liver.length;
	for (i = 1; i <= n; i++){
		roiManager("Select", newArray(Indexes_liver[i-1],Indexes_bg[i-1]));
		roiManager("OR");
		roiManager("Add");
		idx_temp = roiManager("Count")-1;
		roiManager("Select", newArray(Indexes_liver[i-1],idx_temp));
		roiManager("XOR");
		roiManager("Add");
		idx = roiManager("Count")-1;
	    roiManager("Select", idx);
		roiManager("Rename", "C2_" + CT_num + "_Slice_" + i + "_" + type + "_"+ lvl + "_" + width);
		C2_Indexes = append(C2_Indexes, idx);
	}
	return C2_Indexes;
}

function get_class2_ROIs(type,width,lvl,CT_num){
	//type is either "GL" (Greylevel) or "dist" (Distance to liver GL in std's), width is measured in std's of the liver GL for "dist" and in GL for "GL", lvl is either a GL or a number for dist
	Class2Indexes = newArray(0);
	//C2_Indexes = newArray(0);
	if (type == "dist"){
		for (i = 1; i <= n_new; i++){
			roiManager("Select",Idx_liv[i-1]);
			getRawStatistics(nPixels, mean, min, max, std);
			bot = mean + (lvl-width)*std;
			top = mean + (lvl+width)*std;
			setThreshold(bot, top);
			run("Create Selection");
			
			if (selectionType() == -1)
		    	continue;
		    roiManager("Add");
		    idx = roiManager("Count")-1;
		    roiManager("Select", idx);
		    roiManager("Rename", "CT_" + CT_num + "_Slice_" + i + "_" + type + "_"+ lvl + "_" + width);
		    Class2Indexes = append(Class2Indexes,idx);
		}
	}
	if (type == "GL"){
		for (i = 1; i <= n_new; i++){
			setSlice(i);
			bot = lvl-width;
			top = lvl+width;
			setThreshold(bot, top);
			run("Create Selection");
			
			if (selectionType() == -1)
		    	continue;
		    roiManager("Add");
		    idx = roiManager("Count")-1;
		    roiManager("Select", idx);
		    roiManager("Rename", "CT_" + CT_num + "_Slice_" + i + "_" + type + "_"+ lvl + "_" + width);
		    Class2Indexes = append(Class2Indexes,idx);
		}
	}
	C2_Indexes = cut_liver(Idx_liv,Class2Indexes,CT_num,type,lvl,width);
	return C2_Indexes;
}

function set_C1(Indexes){
	for (i = 0; i < Indexes.length; i++){
		roiManager("Select", Indexes[i]);
		call("trainableSegmentation.Weka_Segmentation.addTrace", "0", i+1);
	}
}

function set_C2(Indexes){
	for (i = 0; i < Indexes.length; i++){
		roiManager("Select", Indexes[i]);
		call("trainableSegmentation.Weka_Segmentation.addTrace", "1", i+1);
	}
}

// code to run

CT_num = 17; // CT of interest
num_slices = 20; // approximate number of slices

open_file(make_path(CT_num,"segmentation",1)); // opening profesional segmentation and setting it to 8-bit
range = slicing(num_slices); // cutting non liver images and resampling the segmentation
n_new = nSlices(); // setting number of slices
bin_liver(); // binarization (background = 0; liver = 255)
create_ROI(n_new,CT_num); // creating ROIs of liver for each slice
Idx_liv = newArray(0); // creating an array carrying the indexes of the liver ROIs
for (i = 1; i <= n_new; i++){
    Idx_liv = append(Idx_liv, i-1);
}

open_file(make_path(CT_num,"volume",1)); // opening CT and setting it to 8-bit
slicing_CT(num_slices,range); // cutting and resampling analogue to the professional segmentation
C2_Indexes = get_class2_ROIs("dist",1,2,CT_num); // creating ROIs for the background 

run("Trainable Weka Segmentation 3D"); // open weka
wait(1000); // wait because weka needs a moment to open
call("trainableSegmentation.Weka_Segmentation.setFeature", "Hessian=true"); // set settings of interest
call("trainableSegmentation.Weka_Segmentation.setFeature", "Laplacian=true");
call("trainableSegmentation.Weka_Segmentation.setFeature", "Structure=true");
call("trainableSegmentation.Weka_Segmentation.setFeature", "Edges=true");

set_C1(Idx_liv); // set liver ROIs as class 1
set_C2(C2_Indexes); // set background ROIs as class 2

call("trainableSegmentation.Weka_Segmentation.trainClassifier"); // train model