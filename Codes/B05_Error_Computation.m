% -------------------------------------------------------------------------
% B05_Error_Computation.m
%
% Generated/revised by: Seyed Mohammadali Rahmati
% Affiliation        : Comparative Neuromechanics Lab,
%                      School of Biological Sciences,
%                      Georgia Institute of Technology, Atlanta, GA, USA
% Email              : smarahmati@gmail.com
%
% Purpose:
%   Compute registration error between:
%       1) transformed STL anatomical landmarks, and
%       2) filtered/labeled XROMM marker points.
%
%   The error is first computed in cm, then converted to mm for reporting
%   and plotting.
%
% Run after:
%   B01_Registration_WithoutFlow_3DScale_WithMWF.m
%
% Main outputs:
%   *_Err            : point-wise error for each landmark, in cm
%   rightMarkersData : right-side errors, in mm
%   leftMarkersData  : left-side errors, in mm
%   independentData  : pubic symphysis error, in mm
%   meanTotalError   : mean error over all landmarks, in mm
%   stdTotalError    : standard deviation of error, in mm
%   maxTotalError    : largest marker-mean error, in mm
% -------------------------------------------------------------------------

%% -------------------------- User parameters -----------------------------

plotResults = true;                         % true = create diagnostic plots
saveFigures = false;                        % true = save figures as PNG/PDF
figureFolder = 'B05_Error_Figures';         % folder used if saveFigures = true

unitScale = 10;                             % cm to mm conversion

% Colors used in plots.
registeredColor = [0.85 0.10 0.10];         % red: transformed STL landmark
labeledColor    = [0.00 0.00 0.00];         % black: labeled/tracked point
rightColor      = [0.00 0.00 0.00];         % black: right side
leftColor       = [0.35 0.55 0.85];         % soft blue: left side
psColor         = [0.45 0.45 0.45];         % gray: pubic symphysis

lineWidth = 1.5;
markerSize = 5;
fontSize = 10;

%% ------------------------ Check required inputs --------------------------
% These variables are created mainly by B01.

requiredVars = { ...
    'CS', 'time', ...
    'PS_transformed', 'F_PS_S', ...
    'RFH_transformed', 'RFT_transformed', 'RFE_transformed', ...
    'LFH_transformed', 'LFT_transformed', 'LFE_transformed', ...
    'RTP_transformed', 'RTH_transformed', 'RTD_transformed', ...
    'LTP_transformed', 'LTH_transformed', 'LTD_transformed', ...
    'RCal_transformed', 'RMet_transformed', ...
    'LCal_transformed', 'LMet_transformed', ...
    'F_FRH_S', 'F_FRT_S', 'F_FRC_S', ...
    'F_FLH_S', 'F_FLT_S', 'F_FLC_S', ...
    'F_TRP_S', 'F_TRH_S', 'F_TRD_S', ...
    'F_TLP_S', 'F_TLH_S', 'F_TLD_S', ...
    'F_CR_S', 'F_MR_S', 'F_CL_S', 'F_ML_S'};

for k = 1:numel(requiredVars)
    if ~exist(requiredVars{k}, 'var')
        error('Missing variable "%s". Run B01 before running B05.', requiredVars{k});
    end
end

if isempty(CS)
    error('CS is empty. No cycle frames are available for error computation.');
end

%% ----------------------- Compute landmark errors -------------------------
% Each error is Euclidean distance:
%
%       error = sqrt((X_registered - X_labeled)^2 +
%                    (Y_registered - Y_labeled)^2 +
%                    (Z_registered - Z_labeled)^2)
%
% Errors are computed for all frames first, then restricted to CS frames.

% Pelvis / independent landmark
PS_Err = computePointError(PS_transformed, F_PS_S);

% Femur landmarks
RFH_Err = computePointError(RFH_transformed, F_FRH_S);
RFT_Err = computePointError(RFT_transformed, F_FRT_S);
RFE_Err = computePointError(RFE_transformed, F_FRC_S);

LFH_Err = computePointError(LFH_transformed, F_FLH_S);
LFT_Err = computePointError(LFT_transformed, F_FLT_S);
LFE_Err = computePointError(LFE_transformed, F_FLC_S);

% Tibia landmarks
RTP_Err = computePointError(RTP_transformed, F_TRP_S);
RTH_Err = computePointError(RTH_transformed, F_TRH_S);
RTD_Err = computePointError(RTD_transformed, F_TRD_S);

LTP_Err = computePointError(LTP_transformed, F_TLP_S);
LTH_Err = computePointError(LTH_transformed, F_TLH_S);
LTD_Err = computePointError(LTD_transformed, F_TLD_S);

% Foot landmarks
RCal_Err = computePointError(RCal_transformed, F_CR_S);
RMet_Err = computePointError(RMet_transformed, F_MR_S);

LCal_Err = computePointError(LCal_transformed, F_CL_S);
LMet_Err = computePointError(LMet_transformed, F_ML_S);

% Keep only cycle frames.
PS_Err = PS_Err(CS);

RFH_Err = RFH_Err(CS);
RFT_Err = RFT_Err(CS);
RFE_Err = RFE_Err(CS);

LFH_Err = LFH_Err(CS);
LFT_Err = LFT_Err(CS);
LFE_Err = LFE_Err(CS);

RTP_Err = RTP_Err(CS);
RTH_Err = RTH_Err(CS);
RTD_Err = RTD_Err(CS);

LTP_Err = LTP_Err(CS);
LTH_Err = LTH_Err(CS);
LTD_Err = LTD_Err(CS);

RCal_Err = RCal_Err(CS);
RMet_Err = RMet_Err(CS);

LCal_Err = LCal_Err(CS);
LMet_Err = LMet_Err(CS);

%% ----------------------- Group errors and summarize ----------------------
% Convert all plotted/reported errors from cm to mm.

rightMarkerNames = {'RFH', 'RFT', 'RFE', 'RTP', 'RTH', 'RTD', 'RCal', 'RMet'};
leftMarkerNames  = {'LFH', 'LFT', 'LFE', 'LTP', 'LTH', 'LTD', 'LCal', 'LMet'};

rightMarkersData = [RFH_Err, RFT_Err, RFE_Err, RTP_Err, RTH_Err, RTD_Err, RCal_Err, RMet_Err] * unitScale;
leftMarkersData  = [LFH_Err, LFT_Err, LFE_Err, LTP_Err, LTH_Err, LTD_Err, LCal_Err, LMet_Err] * unitScale;
independentData  = PS_Err * unitScale;

% Kept for compatibility with older scripts.
timeSeriesData = {rightMarkersData, leftMarkersData, independentData};

% Mean and standard deviation per landmark.
meansRight = mean(rightMarkersData, 1, 'omitnan');
stdsRight  = std(rightMarkersData, 0, 1, 'omitnan');

meansLeft = mean(leftMarkersData, 1, 'omitnan');
stdsLeft  = std(leftMarkersData, 0, 1, 'omitnan');

meansIndep = mean(independentData, 1, 'omitnan');
stdsIndep  = std(independentData, 0, 1, 'omitnan');

% Total error over all landmarks and all cycle frames.
totalError = [rightMarkersData, leftMarkersData, independentData];

maxTotalError  = max(mean(totalError, 1, 'omitnan'));
meanTotalError = mean(totalError(:), 'omitnan');
stdTotalError  = std(totalError(:), 0, 'omitnan');

% Kept for compatibility. In older versions this was NaN.
total_Err = meanTotalError;

T_ErrorSummary = table(meanTotalError, stdTotalError, maxTotalError, ...
    'VariableNames', {'MeanError_mm', 'StdError_mm', 'MaxMarkerMeanError_mm'});

T_RightMarkerError = table(rightMarkerNames', meansRight', stdsRight', ...
    'VariableNames', {'Marker', 'MeanError_mm', 'StdError_mm'});

T_LeftMarkerError = table(leftMarkerNames', meansLeft', stdsLeft', ...
    'VariableNames', {'Marker', 'MeanError_mm', 'StdError_mm'});

T_PubisError = table({'PS'}, meansIndep, stdsIndep, ...
    'VariableNames', {'Marker', 'MeanError_mm', 'StdError_mm'});

fprintf('\nB05 error summary\n');
fprintf('Mean total error : %.3f mm\n', meanTotalError);
fprintf('Std total error  : %.3f mm\n', stdTotalError);
fprintf('Max marker mean  : %.3f mm\n\n', maxTotalError);

%% ----------------------------- Plot results ------------------------------

if plotResults

    timeCS = time(CS);

    if saveFigures && ~exist(figureFolder, 'dir')
        mkdir(figureFolder);
    end

    %% Figure 1: Femur landmarks

    femurData = { ...
        'Femoral head', ...
            RFH_transformed, F_FRH_S, RFH_Err, ...
            LFH_transformed, F_FLH_S, LFH_Err; ...
        'Greater trochanter', ...
            RFT_transformed, F_FRT_S, RFT_Err, ...
            LFT_transformed, F_FLT_S, LFT_Err; ...
        'Femoral lateral epicondyle', ...
            RFE_transformed, F_FRC_S, RFE_Err, ...
            LFE_transformed, F_FLC_S, LFE_Err};

    figure(1); clf;
    set(gcf, 'Color', 'w');

    for row = 1:size(femurData, 1)

        pointName = femurData{row, 1};

        % Right 3D comparison
        subplot(3, 3, (row-1)*3 + 1);
        plot3(femurData{row,2}(CS,1)*unitScale, femurData{row,2}(CS,2)*unitScale, femurData{row,2}(CS,3)*unitScale, ...
              '-', 'Color', registeredColor, 'LineWidth', lineWidth);
        hold on;
        plot3(femurData{row,3}(CS,1)*unitScale, femurData{row,3}(CS,2)*unitScale, femurData{row,3}(CS,3)*unitScale, ...
              '-', 'Color', labeledColor, 'LineWidth', lineWidth);
        xlabel('X, mm'); ylabel('Y, mm'); zlabel('Z, mm');
        title(['Right ', pointName]);
        legend({'Registered', 'Labeled'}, 'Location', 'best');
        axis equal; box on;

        % Left 3D comparison
        subplot(3, 3, (row-1)*3 + 2);
        plot3(femurData{row,5}(CS,1)*unitScale, femurData{row,5}(CS,2)*unitScale, femurData{row,5}(CS,3)*unitScale, ...
              '-', 'Color', registeredColor, 'LineWidth', lineWidth);
        hold on;
        plot3(femurData{row,6}(CS,1)*unitScale, femurData{row,6}(CS,2)*unitScale, femurData{row,6}(CS,3)*unitScale, ...
              '-', 'Color', labeledColor, 'LineWidth', lineWidth);
        xlabel('X, mm'); ylabel('Y, mm'); zlabel('Z, mm');
        title(['Left ', pointName]);
        legend({'Registered', 'Labeled'}, 'Location', 'best');
        axis equal; box on;

        % Right vs left error
        subplot(3, 3, (row-1)*3 + 3);
        plot(timeCS, femurData{row,4}*unitScale, '-', 'Color', rightColor, 'LineWidth', lineWidth);
        hold on;
        plot(timeCS, femurData{row,7}*unitScale, '-', 'Color', leftColor, 'LineWidth', lineWidth);
        xlabel('Time, s'); ylabel('Error, mm');
        title(['Right vs Left ', pointName]);
        legend({'Right', 'Left'}, 'Location', 'best');
        box on; grid on;
    end

    if exist('sgtitle', 'file')
        sgtitle('Femur landmark registration errors');
    end

    if saveFigures
        saveas(gcf, fullfile(figureFolder, 'Figure1_Femur_Errors.png'));
    end

    %% Figure 2: Tibia landmarks

    tibiaData = { ...
        'Tibia proximal condyle', ...
            RTP_transformed, F_TRP_S, RTP_Err, ...
            LTP_transformed, F_TLP_S, LTP_Err; ...
        'Tibia harp / distal fusion', ...
            RTH_transformed, F_TRH_S, RTH_Err, ...
            LTH_transformed, F_TLH_S, LTH_Err; ...
        'Tibia distal condyle', ...
            RTD_transformed, F_TRD_S, RTD_Err, ...
            LTD_transformed, F_TLD_S, LTD_Err};

    figure(2); clf;
    set(gcf, 'Color', 'w');

    for row = 1:size(tibiaData, 1)

        pointName = tibiaData{row, 1};

        % Right 3D comparison
        subplot(3, 3, (row-1)*3 + 1);
        plot3(tibiaData{row,2}(CS,1)*unitScale, tibiaData{row,2}(CS,2)*unitScale, tibiaData{row,2}(CS,3)*unitScale, ...
              '-', 'Color', registeredColor, 'LineWidth', lineWidth);
        hold on;
        plot3(tibiaData{row,3}(CS,1)*unitScale, tibiaData{row,3}(CS,2)*unitScale, tibiaData{row,3}(CS,3)*unitScale, ...
              '-', 'Color', labeledColor, 'LineWidth', lineWidth);
        xlabel('X, mm'); ylabel('Y, mm'); zlabel('Z, mm');
        title(['Right ', pointName]);
        legend({'Registered', 'Labeled'}, 'Location', 'best');
        axis equal; box on;

        % Left 3D comparison
        subplot(3, 3, (row-1)*3 + 2);
        plot3(tibiaData{row,5}(CS,1)*unitScale, tibiaData{row,5}(CS,2)*unitScale, tibiaData{row,5}(CS,3)*unitScale, ...
              '-', 'Color', registeredColor, 'LineWidth', lineWidth);
        hold on;
        plot3(tibiaData{row,6}(CS,1)*unitScale, tibiaData{row,6}(CS,2)*unitScale, tibiaData{row,6}(CS,3)*unitScale, ...
              '-', 'Color', labeledColor, 'LineWidth', lineWidth);
        xlabel('X, mm'); ylabel('Y, mm'); zlabel('Z, mm');
        title(['Left ', pointName]);
        legend({'Registered', 'Labeled'}, 'Location', 'best');
        axis equal; box on;

        % Right vs left error
        subplot(3, 3, (row-1)*3 + 3);
        plot(timeCS, tibiaData{row,4}*unitScale, '-', 'Color', rightColor, 'LineWidth', lineWidth);
        hold on;
        plot(timeCS, tibiaData{row,7}*unitScale, '-', 'Color', leftColor, 'LineWidth', lineWidth);
        xlabel('Time, s'); ylabel('Error, mm');
        title(['Right vs Left ', pointName]);
        legend({'Right', 'Left'}, 'Location', 'best');
        box on; grid on;
    end

    if exist('sgtitle', 'file')
        sgtitle('Tibia landmark registration errors');
    end

    if saveFigures
        saveas(gcf, fullfile(figureFolder, 'Figure2_Tibia_Errors.png'));
    end

    %% Figure 3: Foot and pubic symphysis

    footData = { ...
        'Calcaneus', ...
            RCal_transformed, F_CR_S, RCal_Err, ...
            LCal_transformed, F_CL_S, LCal_Err; ...
        'Distal first metatarsal', ...
            RMet_transformed, F_MR_S, RMet_Err, ...
            LMet_transformed, F_ML_S, LMet_Err};

    figure(3); clf;
    set(gcf, 'Color', 'w');

    for row = 1:size(footData, 1)

        pointName = footData{row, 1};

        % Right 3D comparison
        subplot(3, 3, (row-1)*3 + 1);
        plot3(footData{row,2}(CS,1)*unitScale, footData{row,2}(CS,2)*unitScale, footData{row,2}(CS,3)*unitScale, ...
              '-', 'Color', registeredColor, 'LineWidth', lineWidth);
        hold on;
        plot3(footData{row,3}(CS,1)*unitScale, footData{row,3}(CS,2)*unitScale, footData{row,3}(CS,3)*unitScale, ...
              '-', 'Color', labeledColor, 'LineWidth', lineWidth);
        xlabel('X, mm'); ylabel('Y, mm'); zlabel('Z, mm');
        title(['Right ', pointName]);
        legend({'Registered', 'Labeled'}, 'Location', 'best');
        axis equal; box on;

        % Left 3D comparison
        subplot(3, 3, (row-1)*3 + 2);
        plot3(footData{row,5}(CS,1)*unitScale, footData{row,5}(CS,2)*unitScale, footData{row,5}(CS,3)*unitScale, ...
              '-', 'Color', registeredColor, 'LineWidth', lineWidth);
        hold on;
        plot3(footData{row,6}(CS,1)*unitScale, footData{row,6}(CS,2)*unitScale, footData{row,6}(CS,3)*unitScale, ...
              '-', 'Color', labeledColor, 'LineWidth', lineWidth);
        xlabel('X, mm'); ylabel('Y, mm'); zlabel('Z, mm');
        title(['Left ', pointName]);
        legend({'Registered', 'Labeled'}, 'Location', 'best');
        axis equal; box on;

        % Right vs left error
        subplot(3, 3, (row-1)*3 + 3);
        plot(timeCS, footData{row,4}*unitScale, '-', 'Color', rightColor, 'LineWidth', lineWidth);
        hold on;
        plot(timeCS, footData{row,7}*unitScale, '-', 'Color', leftColor, 'LineWidth', lineWidth);
        xlabel('Time, s'); ylabel('Error, mm');
        title(['Right vs Left ', pointName]);
        legend({'Right', 'Left'}, 'Location', 'best');
        box on; grid on;
    end

    % Pubic symphysis 3D comparison
    subplot(3, 3, 7);
    plot3(PS_transformed(CS,1)*unitScale, PS_transformed(CS,2)*unitScale, PS_transformed(CS,3)*unitScale, ...
          '-', 'Color', registeredColor, 'LineWidth', lineWidth);
    hold on;
    plot3(F_PS_S(CS,1)*unitScale, F_PS_S(CS,2)*unitScale, F_PS_S(CS,3)*unitScale, ...
          '-', 'Color', labeledColor, 'LineWidth', lineWidth);
    xlabel('X, mm'); ylabel('Y, mm'); zlabel('Z, mm');
    title('Pubic symphysis');
    legend({'Registered', 'Labeled'}, 'Location', 'best');
    axis equal; box on;

    % Pubic symphysis error
    subplot(3, 3, 8);
    plot(timeCS, PS_Err*unitScale, '-', 'Color', psColor, 'LineWidth', lineWidth);
    xlabel('Time, s'); ylabel('Error, mm');
    title('Pubic symphysis error');
    legend({'PS'}, 'Location', 'best');
    box on; grid on;

    if exist('sgtitle', 'file')
        sgtitle('Foot and pelvis landmark registration errors');
    end

    if saveFigures
        saveas(gcf, fullfile(figureFolder, 'Figure3_Foot_Pelvis_Errors.png'));
    end

    %% Figure 4: Summary bar plot

    figure(4); clf;
    set(gcf, 'Color', 'w');

    br = bar(1:8, meansRight, 'FaceColor', rightColor, 'FaceAlpha', 0.65);
    hold on;
    er = errorbar(1:8, meansRight, stdsRight, '.', 'Color', rightColor, 'LineWidth', lineWidth);

    bl = bar(9:16, meansLeft, 'FaceColor', leftColor, 'FaceAlpha', 0.70);
    el = errorbar(9:16, meansLeft, stdsLeft, '.', 'Color', leftColor, 'LineWidth', lineWidth);

    bps = bar(17, meansIndep, 'FaceColor', psColor, 'FaceAlpha', 0.70);
    epsPlot = errorbar(17, meansIndep, stdsIndep, '.', 'Color', psColor, 'LineWidth', lineWidth);

    xticks(1:17);
    xticklabels([rightMarkerNames, leftMarkerNames, {'PS'}]);
    xtickangle(45);

    xlabel('Bone landmarks');
    ylabel('Mean error, mm');
    title('Mean registration error by landmark');
    legend([br, bl, bps], {'Right markers', 'Left markers', 'Pubic symphysis'}, 'Location', 'best');
    grid on; box on;

    if saveFigures
        saveas(gcf, fullfile(figureFolder, 'Figure4_Error_Bars.png'));
    end
end

%% ----------------------------- Local function ----------------------------
% Main calculation helper. Kept local so this script can still be run
% directly after B01 without requiring a separate file.

function err = computePointError(transformedPoint, labeledPoint)
%COMPUTEPOINTERROR Euclidean distance between two Nx3 trajectories.
%
%   transformedPoint : Nx3 registered STL landmark trajectory
%   labeledPoint     : Nx3 labeled/tracked marker trajectory
%   err              : Nx1 distance, in the same unit as the inputs

    if size(transformedPoint, 2) ~= 3 || size(labeledPoint, 2) ~= 3
        error('Both inputs must be Nx3 matrices.');
    end

    if size(transformedPoint, 1) ~= size(labeledPoint, 1)
        error('The two input trajectories must have the same number of rows.');
    end

    err = sqrt(sum((transformedPoint - labeledPoint).^2, 2));
end
