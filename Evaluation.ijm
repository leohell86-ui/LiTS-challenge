// functions

function make_path(num,type,Batch){
	// type is either "segmentation" or "volume", Batch is either 1 or 2
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
	return -1;
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

function create_ROI_res(n_slices,CT_num){
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
	    roiManager("Rename", "Slice_" + CT_num + "_res_" + i);
	}
}

function norm(idx){
	//idx = ROI_index_by_name(ROI_name);
	if (idx == -1){
		return 0;
	}
	roiManager("select", idx);
	roiManager("Measure");
	row = nResults - 1;
	area = getResult("Area", row);
return area
}

function calc_inter(n) {
	num = 0;
	for (i = 0; i < n; i++) {
		roiManager("Select", newArray(i,i+n));
		roiManager("and");
		if (selectionType() == -1) {
            run("Select None");
            continue;
        }
		roiManager("Add");
		idx = roiManager("Count")-1;
		num = num + norm(idx);
	}
	return num;
}

function calc_union(n) {
	num = 0;
	for (i = 0; i < n; i++) {
		roiManager("Select", newArray(i,i+n));
		roiManager("OR");
		if (selectionType() == -1) {
            run("Select None");
            continue;
        }
		roiManager("Add");
		idx = roiManager("Count")-1;
		num = num + norm(idx);
	}
	return num;
}

function evaluation(img_1, img_2, n){
	//img_1 should be the name of the true ROIs, img_2 should be the name of the predicted ROIs, n is the number of slices
	area_hat = 0;
	area_true = 0;
	for (i = 1; i <= n; i++) {
		idx_1 = ROI_index_by_name(img_1 + i);
		idx_2 = ROI_index_by_name(img_2 + i);
		if(idx_1 == -1){
			if(idx_2 == -1){
				continue;
			}
			area_hat = area_hat + norm(idx_2);
		}
		if(idx_2 == -1){
			area_true = area_true + norm(idx_1);
		}
		else {
			area_true = area_true + norm(idx_1);
			area_hat = area_hat + norm(idx_2);
	}
	}
	intersection = calc_inter(n_new);
	union = calc_union(n_new);
	IoU = intersection/union;
	Dice = (2*intersection/(area_hat+area_true));
	VOE = 1-(intersection/union);
	RDV = (area_hat-area_true)/area_hat;
	print("CT number ",CT_num);
	print("IoU is ",IoU);
	print("Dice is ", Dice);
	print("VOE is ",VOE);
	print("RDV is ", RDV);
	//return res;
}

function clean_ROIs(n_new){
	id = roiManager("count")-1;
	for(i = id; i >= 2*n_new ; i--){
		roiManager("select", i);
		roiManager("delete");
	}
}

function RDV_func(img_1, img_2, n){
	area_hat = 0;
	area_true = 0;
	for (i = 1; i <= n; i++) {
		idx_1 = ROI_index_by_name(img_1 + i);
		idx_2 = ROI_index_by_name(img_2 + i);
		if(idx_1 == -1){
			if(idx_2 == -1){
				continue;
			}
			area_hat = area_hat + norm(idx_2);
			print("case 1, area_hat = " + area_hat); 
		}
		if(idx_2 == -1){
			area_true = area_true + norm(idx_1);
			print("case 2, area_true = " + area_true); 
		}
		else {
			area_true = area_true + norm(idx_1);
			area_hat = area_hat + norm(idx_2);
			print("case 3, area_hat = " + area_hat + "area_true = " + area_true); 
	}
	}
	RDV_ = ((area_hat-area_true)/area_hat);
	print(area_hat,area_true);
	return RDV_;
}

// code to run

num_slices = 20; // approximate number of slices
counting = IoUs = Dices = RDVs = newArray(0); // creating arrays to collect results
IoU = Dice = VOE = RDV = 0; //creating variables to assign values

for (i = 17; i <= 48; i++){
	CT_num = i; // going through all evaluated CTs
	if (CT_num < 28){ // opening the true segmentations
		open_file(make_path(CT_num,"segmentation",1));
	}
	else{
		open_file(make_path(CT_num,"segmentation",2));
	}
	range = slicing(num_slices); // cutting and resampling
	n_new = nSlices(); // new slicing parameter
	bin_liver(); // binarization
	create_ROI(n_new,CT_num); // creation of liver ROIs
	run("Set Scale...", "distance=0.0013 known=1 unit=pixel"); // deleting scale/ setting it to pixels for later analysis

	//Open the slices of the liver that weka gave you
	open_file("C:\\Users\\leona\\OneDrive\\Dokumente\\Leo\\Uni\\Semester 11\\Immage Processing\\Results\\res_" + CT_num + ".tif");
	
	//Run Code to eliminate scale
	run("Set Scale...", "distance=0.0013 known=1 unit=pixel");
	
	//Binarise and Invert if necessary (segmentation = 0, bg = 1)
	bin_liver();
	//run("Invert");
	
	//Run Code to create ROIs
	create_ROI_res(n_new,CT_num);
	
	//Run Code to get results
	evaluation("Slice_"+CT_num+"_", "Slice_" + CT_num + "_res_", n_new);
	counting = append(counting, CT_num);
	IoUs = append(IoUs, IoU);
	Dices = append(Dices, Dice);
	VOEs = append(VOEs, VOE);
	RDVs = append(RDVs, RDV);
	roiManager("reset");
	run("Close All");
}

min = max = mean = std = Iou_mean = IoU_std = Dice_mean = Dice_std = VOE_mean = VOE_std = RDV_mean = RDV_std = 0;

// averaging and calculating standard deviation
Array.getStatistics(IoUs, min, max, IoU_mean, IoU_std);
Array.getStatistics(Dices, min, max, Dice_mean, Dice_std);
Array.getStatistics(VOEs, min, max, VOE_mean, VOE_std);
Array.getStatistics(RDVs, min, max, RDV_mean, RDV_std);
print("IoU = " + IoU_mean + " +- " + IoU_std);
print("Dice = " + Dice_mean + " +- " + Dice_std);
print("VOE = " + VOE_mean + " +- " + VOE_std);
print("RDV = " + RDV_mean + " +- " + RDV_std);