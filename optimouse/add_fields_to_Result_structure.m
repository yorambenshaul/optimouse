 function Result = add_fields_to_Result_structure(Result)
 % Add fields in case they were not included in a user defined function
 % YBS 9/16
 
 if ~isfield(Result,'mouseCOM')
     Result.mouseCOM = [nan nan];
 end
 if ~isfield(Result,'nosePOS')
     Result.nosePOS  = [nan nan];
 end
 if ~isfield(Result,'GreyThresh')
     Result.GreyThresh = 0;
 end
 if ~isfield(Result,'TrimFact')
     Result.TrimFact =  nan;
 end
 if ~isfield(Result,'BB')
     Result.BB =         [];
 end
 if ~isfield(Result,'MouseArea')
     Result.MouseArea = nan;
 end
 if ~isfield(Result,'MousePerim')
     Result.MousePerim = nan;
 end
 if ~isfield(Result,'ThinMousePerim')
     Result.ThinMousePerim = nan;
 end
 if ~isfield(Result,'PerimInds')
     Result.PerimInds = [];
 end
 if ~isfield(Result,'tailCOM')
     Result.tailCOM = [nan nan];
 end
 if ~isfield(Result,'thinmouseCOM')
     Result.thinmouseCOM = [nan nan];
 end
 if ~isfield(Result,'tailbasePOS')
     Result.tailbasePOS = [nan nan];
 end
 if ~isfield(Result,'tailendPOS')
     Result.tailendPOS = [nan nan];
 end
 if ~isfield(Result,'BackGroundMean')
     Result.BackGroundMean = nan;
 end
 if ~isfield(Result,'ErrorMsg')
     Result.ErrorMsg = [];
 end
 if ~isfield(Result,'MouseMean')
     Result.MouseMean = nan;
 end
 if ~isfield(Result,'MouseRange')
     Result.MouseRange = nan;
 end
 if ~isfield(Result,'MouseVar')
    Result.MouseVar = nan;
 end
 
 
 