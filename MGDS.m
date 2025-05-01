% 1/2017 MATLAB GDS Generator.  R Miyakawa.
%
% Here is a class to mimic the hierarchical structure of the GDS file and
% create each component separately and programmatically, rendering the GDS
% file at the end.  Uses gdt2gds.Darwin as file generation engine.
%
% Instantiate a MGDS instance and use methods: 
%
% init(cName, varargin): Initializes MGDS with project name and properties
% 
% makeGDS(): Renders current MGDS structure to GDS
%
% import(MGDS): imports structures and macros from another
% MGDS instance
% 
% makeStructure(mName): Creates a structure.  May pass a name string or a
% cell array of names
%
% makeShape(cHomeStructureName, dCoordsX, dCoordsY, dLayer): Creates a
% polygon boundary using the specified coordinates.  
%
% makeRef(cHomeStructureName, mTargetStructure, dPositions): Creates a
% reference in CHOMESTRUCTURE to target structure MTARGETSTRUCTURE.
% MTARGETSTRUCTURE  can be either a structure name or a MGDS structure node
%
% makeARef(cHomeStructureName, mTargetStructure, dNx, dNy, dTx, dTy,
% dOriginX, dOriginY): Makes an AREF to target structure.  DNX,Y are the
% number of elements along the x- and y-directions, and DTX,Y are the
% periods.  Can only make rectangular arrays at the moment.
%
% makeRefFromXLS(cXLSName, cHomeStructureName):  Creates reference cells as
% described in an XLS file.  See Template.xls for details
%
% makeCircle(cHomeStructureName, dRadius, dOffset, dNPoints, dLayer):
% creates a circular boundary.  Origin is referenced to center of circle
%
% makeEllipse(cHomeStructureName, dSemiAxes, dOffset, dNPoints, dLayer)
%
% makeRect(cHomeStructureName, dLen, dHeight, mBLCoord, dLayer): Creates a
% rectangular boundary.  MBLCOORD is the BL origin coordinate, or can be
% 'center', which centers the rectangle on [0,0]
%
% makePolygonText(cHomeStructureName, dCoordsX, dCoordsY, dAngle, cText, 
% dHeight_um, cJustification, bFlipText, dLayer): Creates a text label.
% BFLIPTEXT can be set to do a vertical flip of text to print on wafer
% correctly.  CJUSTIFICATION can be 'left', 'center', or 'right'
%
% makeHGrating(cHomeStructureName, dPitch, dDutyCucle, dLen, dHeight, mBLCoord, dLayer)
% makeVGrating(cHomeStructureName, dPitch, dDutyCucle, dLen, dHeight, mBLCoord, dLayer)
% makeBoundedGrating(this, cHomeStructureName, dPitch, dDC, dLen, dHeight, dAng,
% mBLCoord, bAddPitchLabel, dLayer): Makes a 1D grating bounded by a
% rectangle.  BADDPITCHLABEL labels pitch and angle of the grating.  
%
% scheduleBinaryOperation(cHomeStructureName, cStructureA, cStructureB, cBinaryOperation)
% Schedules a layout editor macro on two structures.  CBINARYOPERATION can
% be AND, OR, or XOR.
%
% TODO:
% addPitchLabel(MGDSNode): adds pitch label to any mgds structure
% importGDS: creates a macro to import a GDS
% makeBinaryOpMacro(mgdsStructure1, mgdsStructure2, cBinaryOp)



classdef MGDS < MGDSSuper
    
    properties
        sStructures = struct;
        sMacroList = struct;
        
    end
    
    methods
        
        function this = MGDS()
            this.cType = 'master';
        end
        
        function init(this, cName, varargin)
            this.clearStructures();
            this.clearMacros();
            this.cName = cName;
            
            for k = 1:length(varargin)
                switch varargin{k}
                    case 'dLayer'
                        this.dLayer = varargin{k+1};
                    case 'unit'
                        this.cDbflag = varargin{k+1};
                    case 'deleteGDT'
                        this.bDeleteFlag = varargin{k+1};
                    case 'keepMacros'
                        this.bKeepMacros = varargin{k+1};
                    case 'autogen structures'
                        this.bAutogenStructures = varargin{k+1};
                    case 'hide grating labels'
                        this.bGratingLabelsOff = varargin{k+1};
                    case 'layer override'
                        this.bLayerOverride = varargin{k+1};
                end
            end
        end
        
        % Imports fields from another MGDS object.  Overwrites original
        % fields and macros
        function import(this, oMGDS2)
            cStructureNames2 = fieldnames(oMGDS2.sStructures);
            cMacroNames2 = fieldnames(oMGDS2.sMacroList);
            for k = 1:length(cStructureNames2)
                this.sStructures.(cStructureNames2{k}) = ...
                    oMGDS2.sStructures.(cStructureNames2{k});
            end
            
            for k = 1:length(cMacroNames2)
                this.sMacroList.(cMacroNames2{k}) = ...
                    oMGDS2.sMacroList.(cMacroNames2{k});
            end
            
            fprintf('Imported %d structures and %d macros from MGDS object %s\n', ...
                length(cStructureNames2), length(cMacroNames2), oMGDS2.cName);
        end
        
        
        % Imports structures from a GDS file
        function importGDS(this, cGDSPath, ceStructureList)
            if exist('cGDSPath', 'var') ~= 1
                [p, d] = uigetfile();
                cGDSPath = [d p];
            end
            
            [~, p, ~] = fileparts(cGDSPath);
            cMacroName = sprintf('%s_import', p);
            this.sMacroList.(cMacroName) = MGDS.importMacro(cGDSPath, ceStructureList);
            
            % Create structure placeholders for all structures in list
            this.makeStructure(ceStructureList);
            
            
        end
        
        function clearStructures(this)
            this.sStructures = struct;
        end
        

        function clearMacros(this)
            this.sMacroList = struct;
        end
        
        function clearAll(this)
            this.clearStructures();
            this.clearMacros();
        end
        
        
        
        function gdsName = makeGDS(this)
            
            if isempty(this.getStructureNames)
                fprintf('There are no structures in this GDS file\n');
                return;
            end
            
            
            
            gdtName = sprintf('%s.gdt', this.cName);
            gdsName = sprintf('%s.gds', this.cName);
            
            if ~isempty(fieldnames(this.sMacroList))
                fprintf('Creating macro file for %d instructions\n', length(fieldnames(this.sMacroList)));
                cMacroName = sprintf('%s_macro', this.cName);
                this.renderMacro(cMacroName);

            end
            
            this.render(gdtName);
            gdt2gds(gdtName, gdsName, this.bDeleteFlag);
            
   
        end
        
        
        
        
        function mgdsStruct = makeStructure(this, mName)
            % check Max char len:
            
            if iscell(mName)
                % recursively call each name:
                for k = 1:length(mName)
                    if length(mName{k}) > this.dMaxStructureLen
                        error('Structure %s excceds the max structure length of %d (len = %d)', mName{k}, this.dMaxStructureLen, length(mName{k}));
                    end
                    if this.hasStructure(mName{k})
                        error('Structure %s already exists', mName{k});
                    end
                    this.makeStructure(mName{k});
                end
                return;
            else
                if length(mName) > this.dMaxStructureLen
                    error('Structure %s excceds the max structure length of %d (len = %d)', mName, this.dMaxStructureLen, length(mName));
                end
                if this.hasStructure(mName)
                    error('Structure %s already exists', mName);
                end
                mgdsStruct = MGDSStructure(mName);
            end
            
            this.attachChild(mgdsStruct);
        end
        
        function mgdsShape = makeShape(this, cHomeStructureName, dCoordsX, dCoordsY, dLayer)
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            
            if this.bLayerOverride
                dLayer = this.dMasterLayer;
            end
            
            mgdsShape = MGDSShape(dCoordsX, dCoordsY, dLayer);
            this.bindToStructure(cHomeStructureName, mgdsShape);
        end
        
        
        
        
        function mgdsRef = makeRef(this, cHomeStructureName, mTargetStructure, dPositions, dAng)
            % Mixed variable mTargetStructure can be either a structure
            % name or a structure node itself
            if isa(mTargetStructure, 'MGDSSuper')
                if isa(mTargetStructure, 'MGDSStructure') % then use its name
                    cTargetStructureName = mTargetStructure.cName;
                else % this is a shape or text, use parent structure name
                cTargetStructureName = mTargetStructure.cStructureName;
                end
            else
                cTargetStructureName = mTargetStructure;
            end
            
            if exist('dAng', 'var') ~= 1
                dAng = 0;
            end
            
            if ~this.hasStructure(cTargetStructureName)
                warning ('Cannot create ref: Invalid target structure name %s, reference will not be made \n', cTargetStructureName);
                mgdsRef = [];
                return
            end
            
            mgdsRef = MGDSRef(this.sStructures.(cTargetStructureName), dPositions, dAng);
            this.bindToStructure(cHomeStructureName, mgdsRef);
        end
        
        function mgdsARef = makeARef(this, cHomeStructureName, mTargetStructure, ...
                                        dNx, dNy, dTx, dTy, dOriginX, dOriginY)
            
            if exist('dOriginY', 'var') ~= 1
                dOriginY = dOriginX(2);
                dOriginX = dOriginX(1);
            end
            
            % Mixed variable mTargetStructure can be either a structure
            % name or a structure node itself
            if isa(mTargetStructure, 'MGDSSuper')
                cTargetStructureName = mTargetStructure.cStructureName;
            else
                cTargetStructureName = mTargetStructure;
            end
            
            if ~this.hasStructure(cTargetStructureName)
                error ('Cannot create ref: Invalid target structure name %s\n', cTargetStructureName);
            end
            
            mgdsARef = MGDSMRef(this.sStructures.(cTargetStructureName),...
                                        dNx, dNy, dTx, dTy, dOriginX, dOriginY);
                                    
            this.bindToStructure(cHomeStructureName, mgdsARef);
        end
        
        % Creates references from XLS template. See refFromXLSTemplate.xlsx
        % for details
        function mgdsRef = makeRefFromXLS(this, cXLSName, cHomeStructureName, dAng, dOffset)
            if exist('dAng', 'var') ~= 1
                dAng = 0;
            end
            if exist('dOffset', 'var') ~= 1
                dOffset = [0, 0];
            end
            
            mData = xlsread(cXLSName, cHomeStructureName, 'B2:B7');
            % Make search range:
            dNx = mData(1);
            dNy = mData(2);
            dOriginX = mData(5);
            dOriginY = mData(6);
            dTx = mData(3);
            dTy = mData(4);
            
            cRange = sprintf('%c%d:%c%d', 68, 10, 67 + dNx, 9 + dNy);
            
            [~, ceFieldLayout] = xlsread(cXLSName, cHomeStructureName, cRange);
            for k = 1:size(ceFieldLayout, 1)
                for m = 1:size(ceFieldLayout, 2)
                    if isempty(ceFieldLayout{k,m})
                        continue
                    end
                    
                    % Invert rows and Y:
                    dPos = [(m - 1)*dTx + dOriginX, (dNy - k)*dTy + dOriginY] + dOffset;
                    fprintf('Making reference at location [%d, %d] for field %s\n', dPos(1), dPos(2),ceFieldLayout{k,m}); 
                    mgdsRef = makeRef(this, cHomeStructureName, ceFieldLayout{k,m}, dPos, dAng);
                end
            end
            
        end
        
         % Creates references from google spreadsheet.  See
         % https://docs.google.com/spreadsheets/d/1nsCwYA44dyhfpMGb0WniDc_VPJcJF1jznnSZ4sWJICU/edit?gid=1861203091#gid=1861203091
         % For example
        function mgdsRef = makeRefFromGSheet(this, cGID, dSheetID, cHomeStructureName, dAng, dOffset)
            if exist('dAng', 'var') ~= 1
                dAng = 0;
            end
            if exist('dOffset', 'var') ~= 1
                dOffset = [0, 0];
            end
            
            mData = getGSheet(cGID, dSheetID);
            
            % Make search range:
            dNx         = str2double(mData{2,2});
            dNy         = str2double(mData{3,2});
            dOriginX    = str2double(mData{6,2});
            dOriginY    = str2double(mData{7,2});
            dTx         = str2double(mData{4,2});
            dTy         = str2double(mData{5,2});
                                    
            ceFieldLayout = mData(10: 10+dNy-1, 3:3+dNx - 1);
            
            for k = 1:size(ceFieldLayout, 1)
                for m = 1:size(ceFieldLayout, 2)
                    if isempty(ceFieldLayout{k,m})
                        continue
                    end
                    
                    % Invert rows and Y:
                    dPos = [(m - 1)*dTx + dOriginX, (dNy - k)*dTy + dOriginY] + dOffset;
                    fprintf('Making reference at location [%d, %d] for field %s\n', dPos(1), dPos(2),ceFieldLayout{k,m});
                    mgdsRef = makeRef(this, cHomeStructureName, ceFieldLayout{k,m}, dPos, dAng);
                end
            end
        end
        
        
        %%%% ------------- Helper functions for custom shapes ----- %%%
        function mgdsShape = makeText(this, cHomeStructureName, dCoordsX, dCoordsY, dAngle, cText, dWidth, cJustification, dLayer)
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            if this.bLayerOverride
                dLayer = this.dMasterLayer;
            end
            
            mgdsShape = MGDSText(dCoordsX, dCoordsY, dAngle, cText, dWidth, cJustification, dLayer);
            this.bindToStructure(cHomeStructureName, mgdsShape);
        end
        
        % Rectangle: for centered about origin use mBLCoord = 'center'
        function mgdsShape = makeRect(this, cHomeStructureName, dLen, dHeight, mBLCoord, dLayer)
            X = [0, 1, 1, 0, 0]*dLen;
            Y = [0, 0, 1, 1, 0]*dHeight;
            
            if strcmp(mBLCoord, 'center')
                X = X - dLen/2;
                Y = Y - dHeight/2;
            else
                X = X + mBLCoord(1);
                Y = Y + mBLCoord(2);
            end
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            mgdsShape = this.makeShape(cHomeStructureName, X, Y, dLayer);
        end
        
        % Circle: for centered about origin use mBLCoord = 'center'
        function mgdsShape = makeCircle(this, cHomeStructureName, dRadius, dOffset, dNPoints, dLayer)
            dTh = linspace(0, 2*pi, dNPoints);
            
            dX = dRadius*cos(dTh) + dOffset(1);
            dY = dRadius*sin(dTh) + dOffset(2);
            
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            mgdsShape = this.makeShape(cHomeStructureName, dX, dY, dLayer);
        end
        
        % Circle: for centered about origin use mBLCoord = 'center'
        function mgdsShape = makeEllipse(this, cHomeStructureName, dSemiAxes, dOffset, dNPoints, dLayer)
            dTh = linspace(0, 2*pi, dNPoints);
            
            dX = dSemiAxes(1)*cos(dTh) + dOffset(1);
            dY = dSemiAxes(2)*sin(dTh) + dOffset(2);
            
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            mgdsShape = this.makeShape(cHomeStructureName, dX, dY, dLayer);
        end
        
        function mgdsNode = makePolygonText(this, cHomeStructureName, ...
                dCoordsX, dCoordsY, dAngle, cText, dWidth, cJustification, ...
                bFlipText, dLayer)
            
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            mgdsNode = this.makeText(cHomeStructureName, dCoordsX, dCoordsY, dAngle, cText, dWidth, cJustification, dLayer);
            
            this.sMacroList.(sprintf('%s_polyText', cHomeStructureName)) = MGDS.text2boundaryMacro(cHomeStructureName);
            if bFlipText
                this.sMacroList.(sprintf('%s_polyText_flip', cHomeStructureName)) = MGDS.mirrorText(cHomeStructureName);
            end
        end
        
        function scheduleBinaryOperation(this, cHomeStructureName, cStructureA, cStructureB, cBinaryOperation)
            
            if ~this.hasStructure(cHomeStructureName)
                if this.bAutogenStructures
                    this.makeStructure(cHomeStructureName);
                else
                    error('Structure %s does not exist!  Turn on "Autogen Structures" if you would like structures to be automatically created', cHomeStructureName);
                end
                
            end
            
            this.sMacroList.(sprintf('%s_binaryOp', cHomeStructureName)) = ...
                MGDS.flattenAndBinaryOp(cHomeStructureName, cStructureA, cStructureB, cBinaryOperation);
        end
        
        function mgdsNode = makeHGrating(this, cHomeStructureName, dPitch, dDC, dLen, dHeight, mBLCoord, dLayer)
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            dNy = round(dHeight/dPitch);
            
            % Make atom:
            cAtomName = [cHomeStructureName '_atm'];
            mgdsAtom = this.makeRect(cAtomName,  dLen, dPitch*dDC, [0, 0], dLayer);
            if strcmp(mBLCoord, 'center')
                dX = -dLen/2;
                dY = -dHeight/2;
            else
                dX = mBLCoord(1);
                dY = mBLCoord(2);
            end 
            mgdsNode = this.makeARef(cHomeStructureName, mgdsAtom, ...
                             1, dNy, 0, dPitch, dX, dY);
        end
        
        function mgdsNode = makeVGrating(this, cHomeStructureName, dPitch, dDC, dLen, dHeight, mBLCoord, dLayer)
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            dNx = round(dLen/dPitch);
            
            % Make atom:
            cAtomName = [cHomeStructureName '_atm'];
            mgdsAtom = this.makeRect(cAtomName,  dPitch*dDC,  dHeight, [0, 0], dLayer);
            if strcmp(mBLCoord, 'center')
                dX = -dLen/2;
                dY = -dHeight/2;
            else
                dX = mBLCoord(1);
                dY = mBLCoord(2);
            end 
            mgdsNode = this.makeARef(cHomeStructureName, mgdsAtom, ...
                              dNx, 1, dPitch, 0, dX, dY);
        end
        
        
        
        
        
        % Makes grating at an angle with a rectangular grating mask
        function mgdsNode = makeBoundedGrating(this, cHomeStructureName, ...
                dPitch, dDC, dLen, dHeight, dAng, mBLCoord, ...
                bAddPitchLabel, dLayer)
            
            % Put grating angle into [0, pi)
            dAng = mod(dAng, pi);
            
            % See if there are pitch label options:
            if isstruct(bAddPitchLabel)
                dLabelMag = bAddPitchLabel.dLabelMag;
                dLabelSize = bAddPitchLabel.dLabelSize;
                bFlipText = bAddPitchLabel.bFlipText;
                bAddPitchLabel = true;
            else
                dLabelSize = 1; % default to 1-um label size
                dLabelMag = 1;
                bFlipText = false;
            end
            
            % Check text label override:
            if this.bGratingLabelsOff
                bAddPitchLabel = false;
            end
            
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            
            % Insert extra dX space due to angle if angle is positive and
            % not = 0 or 90
            if (cot(dAng) < 0) || mod(dAng, pi/2) == 0
                dXOffset = 0;
            else
                dXOffset = dHeight*cot(dAng);
            end
            
            if strcmp(mBLCoord, 'center')
                dX = -dLen/2 - dXOffset;
                dY = -dHeight/2;
            else
                dX = mBLCoord(1) - dXOffset;
                dY = mBLCoord(2);
            end
                
            cPitchLabelName = sprintf('tl_%s', cHomeStructureName);
            if mod(dAng, pi) == 0 % H grating
                mgdsNode = this.makeHGrating(cHomeStructureName, dPitch, dDC, dLen, dHeight, mBLCoord, dLayer);
                if (bAddPitchLabel)
                    cLabel = sprintf('%g%s', round(dPitch*1000*dLabelMag, 1), 'H');
                    this.makeRef(cHomeStructureName, ...
                        this.makePolygonText(cPitchLabelName, ...
                        0, 0, 0, cLabel, dLabelSize, 'left', bFlipText, dLayer), ...
                        [dX, dY - 1.5*dLabelSize]);
                    
                end
            
            elseif mod(dAng, pi) == pi/2 % V grating
                mgdsNode = this.makeVGrating(cHomeStructureName, dPitch, dDC, dLen, dHeight, mBLCoord, dLayer);
                if (bAddPitchLabel)
                    cLabel = sprintf('%g%s', round(dPitch*1000*dLabelMag, 1), 'V');
                    this.makeRef(cHomeStructureName, ...
                        this.makePolygonText(cPitchLabelName, ...
                        0, 0, 0, cLabel, dLabelSize, 'left', bFlipText, dLayer), ...
                        [dX, dY - 1.5*dLabelSize]);
                end
                
            else % non-HV grating:
                
                % Make atom:
                dCD = dPitch * dDC;
                dXatom = [0, dCD*csc(dAng), dCD*csc(dAng) + dHeight*cot(dAng), dHeight*cot(dAng)];
                dYatom = [0, 0, dHeight, dHeight];
                
                cAtomStructureName = [cHomeStructureName '_atm'];
                mgdsAtom = this.makeShape(cAtomStructureName, dXatom, dYatom, dLayer);
                
                dAdjPitch = csc(dAng)*dPitch;
                dNx = round((dLen + abs(dHeight*cot(dAng)))/dAdjPitch);

                mgdsNode = this.makeARef(cHomeStructureName, mgdsAtom, ...
                    dNx, 1, dAdjPitch, 0, dX, dY);
                
                % Make grating label
                if (bAddPitchLabel)
                    cLabel = sprintf('%g%s', round(dPitch*1000*dLabelMag, 1),...
                        sprintf(' @ %gº', round(mod(dAng/pi*180, 180), 1)   ));
                    this.makeRef(cHomeStructureName, ...
                        this.makePolygonText(cPitchLabelName, ...
                        0, 0, 0, cLabel, dLabelSize, 'left', bFlipText, dLayer), ...
                        [dX + dXOffset, dY - 1.5*dLabelSize]);
                end
                % Make grating mask
                cMaskStructureName = [cHomeStructureName '_mask'];
                this.makeRect(cMaskStructureName, dLen, dHeight + 6, mBLCoord, 2); % add 6 to not cut off label
                
                % Make masking macro:
                this.sMacroList.(sprintf('%s_masking', cMaskStructureName)) = MGDS.makeMaskMacro(cHomeStructureName, cMaskStructureName, dLayer);
                this.sMacroList.(sprintf('%s_deleteCell', cAtomStructureName)) = MGDS.removeCellMacro(cAtomStructureName);
                
            end % end non-HV grating
            
            
            
        end
        
        
        function mgdsNode = makeBoundedRef2(this, cHomeStructureName, ...
                mgdsAtom, dTx, dTy, dLen, dHeight, dAng, mBLCoord)

            
            % Create grid of points 1.5 times bigger than max bound:
            dMxBnd = max(dLen, dHeight)*1.2;
            dMxBndX = ceil(dMxBnd/dTx)*dTx;
            dMxBndY = ceil(dMxBnd/dTy)*dTy;
            
            dIdxX = -dMxBndX:dTx:dMxBndX;
            dIdxY = -dMxBndY:dTy:dMxBndY;
            [dGridX, dGridY] = meshgrid(dIdxX, dIdxY);
            
            dRCoords = [cos(dAng), -sin(dAng); sin(dAng), cos(dAng)]*...
                            [dGridX(:)'; dGridY(:)'];
            
            dRoeTh = 1e-10;
            % Bind to rectangle:
            bIdx = dRCoords(1,:) < -dRoeTh | dRCoords(1,:) > dLen + dRoeTh | ...
                dRCoords(2,:) < -dRoeTh | dRCoords(2,:) > dHeight + dRoeTh;
             
            dRCoords(:, bIdx) = [];
            dRCoords = dRCoords';
            if strcmp(mBLCoord, 'center')
                dX = -dLen/2;
                dY = -dHeight/2;
            else
                dX = mBLCoord(1);
                dY = mBLCoord(2);
            end
            
            % Apply offset:
            dRCoords(:,1) = dRCoords(:,1) + dX;
            dRCoords(:,2) = dRCoords(:,2) + dY;
                
           
                        
            mgdsNode = this.makeRef(cHomeStructureName, mgdsAtom, ...
                            dRCoords);
        end
        
        
        % Makes grating at an angle with a rectangular grating mask
        function mgdsNode = makeBoundedGrating2(this, cHomeStructureName, ...
                dTx, dTy, dDC, dLen, dHeight, dAng, mBLCoord, ...
                bAddPitchLabel, dLayer)
            
            % Check text label override:
            if this.bGratingLabelsOff
                bAddPitchLabel = false;
            end
            
            % Pass in fliptext as a bool array
            if length(bAddPitchLabel) == 2
                bFlipText = bAddPitchLabel(2);
                bAddPitchLabel = bAddPitchLabel(1);
            else
                bFlipText = false;
            end
            
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            
            % Make atom:
            dCDX = dTx * dDC;
            dCDY = dTy * dDC;
            dXatom = [0, dCDX, dCDX, 0];
            dYatom = [0, 0, dCDY, dCDY];
            
            cAtomStructureName = [cHomeStructureName '_atm'];
            mgdsAtom = this.makeShape(cAtomStructureName, dXatom, dYatom, dLayer);
            
            if strcmp(mBLCoord, 'center')
                dX = -dLen/2;
                dY = -dHeight/2;
            else
                dX = mBLCoord(1);
                dY = mBLCoord(2);
            end
            
            if (mod(dAng, pi/2) == 0)
                dNx = round(dLen/dTx);
                dNy = round(dHeight/dTy);
                mgdsNode = this.makeARef(cHomeStructureName, mgdsAtom, ...
                    dNx, dNy, dTx, dTy, dX, dY);
                return
            end
            
            mgdsNode = this.makeBoundedRef2(cHomeStructureName, ...
                mgdsAtom, dTx, dTy, dLen, dHeight, dAng, mBLCoord);
            
            
            
            % Make grating label
            if (bAddPitchLabel)
                this.makePolygonText(cHomeStructureName, dX, dY - 1.5, 0, ...
                    sprintf('Tx%g:Ty%g%s', round(dTx*1000, 1), round(dTy*1000, 1), ...
                    sprintf(' @ %gº', mod(dAng/pi*180, 180))),...
                    1, 'left', bFlipText, dLayer);
            end
               
            
            
        end
        
        
        function mgdsNode = make2DGrating(this, cHomeStructureName, dPitches, dDCs, dLen, dHeight, mBLCoord, dLayer)
            if exist('dLayer', 'var') ~= 1
                dLayer = this.dLayer;
            end
            
            if length(dPitches) == 1
                dPitches = dPitches * [1, 1];
            end
            if length(dDCs) == 1
                dDCs = dDCs * [1, 1];
            end
            
            dNx = round(dLen/dPitches(1));
            dNy = round(dHeight/dPitches(2));
            
            % Make atom:
            cAtomName = [cHomeStructureName '_atm'];
            mgdsAtom = this.makeRect(cAtomName,  dPitches(1)*dDCs(1), dPitches(2)*dDCs(2), [0, 0], dLayer);
            if strcmp(mBLCoord, 'center')
                dX = -dLen/2;
                dY = -dHeight/2;
            else
                dX = mBLCoord(1);
                dY = mBLCoord(2);
            end 
            mgdsNode = this.makeARef(cHomeStructureName, mgdsAtom, ...
                             dNx, dNy, dPitches(1), dPitches(2), dX, dY);
        end
        
        
        
    end
    
    %%% --- PRIVATE FUNCTIONS --- %%%
    methods (Access = private)
        
        function ceStructNames = getStructureNames(this)
            ceStructNames = fieldnames(this.sStructures);
        end
        
        function bContainsStruct = hasStructure(this, cStructName)
            bContainsStruct =  any(strcmp(this.getStructureNames, cStructName));
        end
        
        
        function attachChild(this, mgdsNode)
            switch mgdsNode.cType
                case 'structure'
                    % Check if this structure already exists:
                    
                    if this.hasStructure(mgdsNode.cName)
                        error('Cannot create structure %s, structure already exists!!\n', mgdsNode.cName);
                    end
                    
                    this.sStructures.(mgdsNode.cName) = mgdsNode;
                otherwise
                    fprintf('MGDSNode type "%s" cannot accept children of type "%s"\n', this.cType, mgdsNode.cType);
                    return
            end
        end
        
        function bindToStructure(this, cHomeStructureName, mgdsNode)
            if ~this.hasStructure(cHomeStructureName)
                if this.bAutogenStructures
                    this.makeStructure(cHomeStructureName);
                else
                    error('Structure %s does not exist!  Turn on "Autogen Structures" if you would like structures to be automatically created', cHomeStructureName);
                end
                
            end
            this.sStructures.(cHomeStructureName).attachChild(mgdsNode);
        end
        
        
        function render(this, gdtName)
            fid = fopen(gdtName, 'w');
            switch this.cDbflag
                case 'a'
                    fprintf(fid, 'gds2{7\nm=-4713-01-01 00:00:00 a=-4713-01-01 00:00:00\nlib ''noname'' 0.0001 1e-10\n');
                case 'nm'
                    fprintf(fid, 'gds2{7\nm=-4713-01-01 00:00:00 a=-4713-01-01 00:00:00\nlib ''noname'' .001 1e-9\n');
                case '1.25'                
                    fprintf(fid, 'gds2{7\nm=2813-01-01 00:00:00 a=2813-01-01 00:00:00\nlib ''noname'' 0.000125 1.25e-10\n');
            end
            
            ceStructures = this.getStructureNames();
            for k = 1:length(ceStructures)
                this.sStructures.(ceStructures{k}).render(fid);
            end
            
            fprintf(fid, '}');
            fclose(fid);
        end
        
        
        
        function renderMacro(this, macroName)
            fid = fopen(macroName, 'w');
            fprintf(fid, '#!/usr/bin/layout\n#name=Macro: %s\n#help=Recorded Mon Jan 23 2017\n\n', macroName);
            fprintf(fid, 'int main(){\n');
            ceMacroList = fieldnames(this.sMacroList);
            for k = 1:length(ceMacroList)
                fprintf(fid, [this.sMacroList.(ceMacroList{k}), '\n']);
            end
            fprintf(fid, '}');
            
            if length(macroName) < 7 || ~strcmp(macroName(end - 6:end), '.layout')
                newMacroName = [macroName '.layout']; % add layout extension
                movefile(macroName, newMacroName);
            end
            
%             if this.bKeepMacros
%                 copyfile(macroName, '/Applications/layout.app/macros/');
%             else
%                 movefile(macroName, '/Applications/layout.app/macros/');
%             end
            
            
        end
        
        
        
    end
    
    methods (Static, Access = private)
        
        function sMacroInstructions = makeOpenAndRunMacro(cFileName, cMacroName)
            cPath = pwd;
            cMacroPath = '/Applications/layout.app/macros';
            sMacroInstructions = [...
                sprintf('layout->drawing->openFile("%s/%s");\n', cPath, cFileName) ...
                sprintf('layout->executeMacro("%s/%s");\n', cMacroPath, cMacroName) ...
                sprintf('layout->drawing->saveFile("%s/%s");\n', cPath, cFileName) ...
                ];
        end
        
        % Structures listed in ceStructureList will already be defined as
        % empty structures as placeholders.  We need to rename these, then reference the
        % nontrivial versions from the imported file
        function sMacroInstructions =  importMacro(cGDSPath, ceStructureList)
            sMacroInstructions = [];
            for k = 1:length(ceStructureList)
                cStructure = ceStructureList{k};
                
                % Go to the structure placeholder
                sMacroInstructions = sprintf('%slayout->drawing->setCell("%s");\n', sMacroInstructions, cStructure);
                % Rename it:
                sMacroInstructions = sprintf('%slayout->drawing->currentCell->cellName="%s_ph";\n', sMacroInstructions, cStructure);
            end
            
            % Now import the real structures
            sMacroInstructions = sprintf('layout->drawing->importFile("%s");\n', cGDSPath);
            
            % Then loop back and place a reference to the true structures
            % from the placeholders:
            for k = 1:length(ceStructureList)
                cStructure = ceStructureList{k};
                
                % Go to the structure placeholder
                sMacroInstructions = sprintf('%slayout->drawing->setCell("%s_ph");\n', sMacroInstructions, cStructure);
                sMacroInstructions = sprintf('%slayout->drawing->point(0,0);\n', sMacroInstructions);
                sMacroInstructions = sprintf('%slayout->drawing>cellref("%s");\n', sMacroInstructions, cStructure);
            end
            
               
        end
        
        function sMacroInstructions = makeMaskMacro(cHomeStructureName, cMaskStructureName, dLayer)
            sMacroInstructions = [...
                sprintf('layout->drawing->activeLayer=%d;\n', dLayer)...
                sprintf('layout->drawing->setCell("%s");\n', cHomeStructureName) ...
                'layout->drawing->selectAll();\n' ...
                'layout->drawing->flatAll();\n' ...
                'layout->drawing->selectAll();\n' ...
                'layout->booleanTool->setA();\n' ...
                sprintf('layout->drawing->setCell("%s");\n', cMaskStructureName) ...
                'layout->drawing->selectAll();\n' ...
                'layout->booleanTool->setB();\n' ...
                sprintf('layout->drawing->setCell("%s");\n', cHomeStructureName) ...
                'layout->drawing->selectAll();\n' ...
                'layout->drawing->deleteSelect();\n' ...
                'layout->booleanTool->aMultiB();\n' ...
                'layout->drawing->deselectAll();\n' ...
                sprintf('layout->drawing->setCell("%s");\n', cMaskStructureName) ...
                'layout->drawing->deleteActuellCell();\n'];
        end
        
        function sMacroInstructions = removeCellMacro(cTargetCell)
            sMacroInstructions = [...
                sprintf('layout->drawing->setCell("%s");\n', cTargetCell) ...
                'layout->drawing->deleteActuellCell();\n'];
        end
        function sMacroInstructions = text2boundaryMacro(cTargetCell)
            sMacroInstructions = [...
                sprintf('layout->drawing->setCell("%s");\n', cTargetCell) ...
                'layout->drawing->selectAll();\n' ...
                'layout->drawing->toPolygon();\n'];
        end
        function sMacroInstructions = mirrorText(cTargetCell)
            sMacroInstructions = [...
                sprintf('layout->drawing->setCell("%s");\n', cTargetCell) ...
                'layout->drawing->selectAll();\n' ...
                'layout->drawing->point(-5000,0);\n' ...
                'layout->drawing->point(5000,0);\n' ...
                'layout->drawing->mirror();\n'];
        end
        
        function sMacroInstructions = flattenAndBinaryOp(cTargetCell, cCellA, cCellB, cOperationType)
            switch cOperationType
                case 'XOR'
                    cOpString = 'aExorB';
                case 'AND'
                    cOpString = 'aMultiB';
                case 'OR'
                    cOpString = 'aPlusB';
            end
            sMacroInstructions = [...
                sprintf('layout->drawing->setCell("%s");\n', cCellA) ...
                'layout->drawing->selectAll();\n' ...
                'layout->drawing->flatAll();\n' ...
                'layout->drawing->selectAll();\n' ...
                'layout->booleanTool->setA();\n' ...
                sprintf('layout->drawing->setCell("%s");\n', cCellB) ...
                'layout->drawing->selectAll();\n' ...
                'layout->drawing->flatAll();\n' ...
                'layout->drawing->selectAll();\n' ...
                'layout->booleanTool->setB();\n' ...
                sprintf('layout->drawing->setCell("%s");\n', cTargetCell) ...
                sprintf('layout->booleanTool->%s();\n', cOpString) ];
        end
        
        
        
    end
    
    
end