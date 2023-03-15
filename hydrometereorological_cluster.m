% During cluster installation, laser distance range finders (single beam lidars)
% were named as follows:
    % L1, L3: Minturn River
    % L2: Fox Canyon River
    % L4: North River


%% ING
%%%%%%%%%%%%%%% CWMS Data %%%%%%%%%%%%%%%
% Import 2019-2020
ing = readtable("..\data\ing_current.csv");

% Switch dates from cell to datetime
ing.DateTime = datetime(ing.DateTime, 'InputFormat', 'dd MM yyyy HH:mm:ss');

% % Remove blank winter rows so that all years are same increment of 4 
ing(52075,:) = [];
ing(52076,:) = [];
ing(52077,:) = [];

% Clip raw distance values to physically realistic bounds: Remove laser distances below 6m, above 20m
ing_L1_clip = ing(:,9:11);
ing_L1_clip{:,1:3}(ing_L1_clip{:,1:3} >= 0.02) = NaN;
ing_L1_clip{:,1:3}(ing_L1_clip{:,1:3} < 0.006) = NaN;
% Name columns
ing_L1_clip.Properties.VariableNames = {'L1_F_clip','L1_L_clip','L1_S_clip'};

% Clip raw distance values to physically realistic bounds: Remove laser distances below 5m, above 15m
ing_L3_clip = ing(:,12:14);
ing_L3_clip{:,1:3}(ing_L3_clip{:,1:3} > .015) = NaN;
ing_L3_clip{:,1:3}(ing_L3_clip{:,1:3} < 0.005) = NaN;
% Name columns
ing_L3_clip.Properties.VariableNames = {'L3_F_clip','L3_L_clip','L3_S_clip'};

% Append to ing table
ing = [ing ing_L1_clip ing_L3_clip];

% L1 Median, mean, and std of clipped laser returns 
ing.L1_median = median(ing{:,30:32},2,'omitnan');
ing.L1_mean = mean(ing{:,30:32},2,'omitnan');
ing.L1_med_std = std(ing{:,30:32},0,2,'omitnan');

% L3 Median, mean, and std of laser returns
ing.L3_median = median(ing{:,33:35},2,'omitnan');
ing.L3_mean = mean(ing{:,33:35},2,'omitnan');
ing.L3_med_std = std(ing{:,33:35},0,2,'omitnan');


%%% Realign offset data with primary trendline
% L1: Breaks in the anomalies (2019 Aug 30 02:00 - Sept 1, 12:00 and 2020
% Aug 19 08:00 to Aug 22, 2020 10:00)
% copy new row to fill
ing.L1_median_force = ing.L1_median;

% 2019: Cutoff values are slightly different before/after gap (offset
% values remain constant, but all flows have increased)
for row = 1535:2895
    if ing{row, 42} < 0.0105
        ing{row, 42} = ing{row,42} + .0047;  % Add 4.7 to offset
    end
end
for row = 3499:5067
    if ing{row, 42} < 0.0096
        ing{row, 42} = ing{row,42} + .009;  % Add 9 to lower offset
    elseif ing{row, 42} < 0.014
        ing{row, 42} = ing{row, 42} + .006; % Add 6 to upper offset
    end
end
for row = 5131:6090
    if ing{row, 42} < 0.0102
        ing{row, 42} = ing{row,42} + .009;  % Add 9 to lower offset
    elseif ing{row, 42} < 0.014
        ing{row, 42} = ing{row, 42} + .006; % Add 6 to upper offset
    end
end
% 2020: Cutoff values slightly different in earlier melt season (offset
% values remain constant, but only one offset present in early season, 
% and all flows increase in later melt season)
for row = 33515:35939
    if ing{row, 42} < 0.0115
        ing{row, 42} = ing{row,42} + .006;
    end
end
for row = 36791:37480
    if ing{row, 42} < 0.0105
        ing{row, 42} = ing{row, 42} + .006; % Add 6 to upper offset
    end
end

row_L1_2020 = [37579:39195, 39491:40746];
for row = row_L1_2020
    if ing{row, 42} < 0.0105
        ing{row, 42} = ing{row,42} + .009;  % Add 9 to lower offset
    elseif ing{row, 42} < 0.014
        ing{row, 42} = ing{row, 42} + .006; % Add 6 to upper offset
    end
end

% 2021: 
% Lower offset: Jun 26 2021 09:00 - Jul 22, 2021 14:00, if <9, +9
% Aug 16 2021 13:00 - Aug 23 0:00, if <9, + 9
row_L1_2021 = [58583:60111, 62139:62755];
for row = row_L1_2021
    if ing{row, 42} < 0.0087
        ing{row, 42} = ing{row,42} + .003;  % Add 9 (total) to offset
    end
end

% June 15 2021 18:00 - Jul 27 2021 08:00 and Aug 06 2021 15:00 - Sep
% 03 2021 16:00, + 0.006 when less than 0.013
row_L1_2021 = [57971:60555, 61291:63823];
for row = row_L1_2021
    if ing{row, 42} < 0.01225
        ing{row, 42} = ing{row,42} + .006;  % Add 6 to offset
    end
end

%%% Realign offset data with primary trendline
% L3: Aug 3 - Aug 6 
% copy new row to fill
ing.L3_median_force = ing.L3_median;

for row = 37579:37962
    ing{row, 43} = ing{row,43} + .00415; 
end


%%% Figure A1
% Plot L1 median, forced median
% Every 4th 15-min increment has data: plot every fourth 
figure(1)
plot(ing.DateTime(3:4:end),ing.L1_median(3:4:end)*1000)
hold on
plot(ing.DateTime(3:4:end),ing.L1_median_force(3:4:end)*1000)
title('Laser 1 Before and After Correction')
ylabel('Lidar Return Distance (m)') 
legend('Raw L1 Median', 'Corrected L1 Median', 'Location', 'northwest')
hold off
 

%%% Convert laser return to stage (using arbitrary datum from optical survey)
% Calculate river height from laser distance
% When bank is empty, L1 = 0.01193 km, L3 = 0.00814 km, convert to m
% Laser angle correction: multiply by 2  
h_L1 = 323.280;     % WSE of L1 eyes (ellipsoid height, m)
h_L3 = 320.984;     % WSE of L3 eyes
ing.L1_h_air = ing.L1_median_force.*sind(ing{:,6}*2)*1000;     % vertical height (m) from laserbox to water surface
ing.L3_h_air = ing.L3_median_force.*sind(ing{:,7}*2)*1000;     % both L1 and L3 using median laser return
ing.L1_stage = h_L1 - ing.L1_h_air;      % stage (m) = mount height - dist to water
ing.L3_stage = h_L3 - ing.L3_h_air;

% Clean bubbler data
% Set to optical survey level
ing.bubbler = ing{:,19};
% Remove 0 values and values >6m
ing.bubbler(ing.bubbler(1:end) <=0.06) = NaN;  % Bubbler can't read below 0.06m
ing.bubbler(ing.bubbler >6) = NaN;
ing.bubbler = ing.bubbler+83.451+232.394;   % Offset from concurrent measurements from optical survey and bubbler, adjust to WSE
% Bubbler thought to have frozen by September 2, 2020: remove anomalous
% values from 9/2/2020-9/12/2020
ing.bubbler(40459:41514)=NaN;
% To fix bubbler (bumped down ~0.5m July 29, 2021 by 3:30am, row 60729)
ing.bubbler(60729:end) = ing.bubbler(60729:end) + 0.5;


%%% Convert stage to WSE
% Stage and ellipsoid height measured at same time in the field:
% WSE = Stage +  313.67m
ing.L1_stage2 = ing.L1_stage + 313.67;
ing.L3_stage2 = ing.L3_stage + 313.67;

% Interpolate missing validation data: experimental comparison
[ing.bubbler_interp,ing.interp_TF] = fillmissing(ing.bubbler,'linear');

%% Add new 2021 PT
ing_pt = readtable('..\data\ing_newpt_04202022.csv');
ing = outerjoin(ing,ing_pt,'Keys',{'DateTime','DateTime'});
% Fix names after merge 
ing.Properties.VariableNames{29} = 'DateTime';
ing.PT = ing.PT + 314.8;    % Bubbler datum, aligned 7/25/2021 02:00


%% Hybrid Bubbler/SSL Product
% 2019-2020: Linear regression: Bubbler = m*SSL + b. For L1 and L3
mdl_bub_L1 = fitlm(ing.L1_stage,ing.bubbler);
ing.pred_bub_L1 = predict(mdl_bub_L1,ing.L1_stage);

%%% L1
% L1 was more complete and more accurate as compared to the CF Bubbler than
% L3, so it was used for the hybrid product. Inclusion of L3 did not
% improve the predictive capability of the hybrid product.
% Robust linear model to minimize outlier impact
mdl_bub_L1r = fitlm(ing.L1_stage,ing.bubbler,'RobustOpts','on');
ing.pred_bub_L1r = predict(mdl_bub_L1r,ing.L1_stage);

% Robust linear model with outliers (> +/- 0.25m) removed
b_L1r = mdl_bub_L1r.Coefficients.Estimate(1);
b_L1r_hi = b_L1r+0.25;  % Upper threshold
b_L1r_lo = b_L1r-0.25;  % Lower threshold
m_L1r = mdl_bub_L1r.Coefficients.Estimate(2);

% If robust linear model estimate is outside thresholds, remove outlier
ing.pred_bub_L1r_no_outlier = ing.pred_bub_L1r; % copy values with outliers
for row = 1:length(ing.pred_bub_L1r_no_outlier)
    if ing.bubbler(row) > m_L1r*ing.L1_stage+b_L1r_hi
        ing.pred_bub_L1r_no_outlier(row) = [];
    elseif ing.bubbler(row) < m_L1r*ing.L1_stage+b_L1r_lo
        ing.bubbler(row) = [];
    end
end

% If when bubbler is available, use it, otherwise use linear relationship
% to calculate the estimate of bubbler from lidar 1
ing.pred_bub_L1 = ing.bubbler;  % If have bubbler data, use it
% If bubbler is NaN, use L1 estimate
ing.pred_bub_L1(isnan(ing.pred_bub_L1)) = ing.pred_bub_L1r_no_outlier(isnan(ing.pred_bub_L1));

% 2021: Pressure transducer introduced. The single beam lidar did not
% improve the final hybrid product this year (due to spottiness of data and
% high accuracy of the PT). If bubbler is available, use it, otherwise use
% linear relationship to calculate estimate of bubbler from PT. Record can
% be combined because of closeness of accuracy 
mdl_bub_PT = fitlm(ing.PT,ing.bubbler);
ing.temp_pred_bub_PT = predict(mdl_bub_L1,ing.PT);  % predict bubbler from PT

ing.pred_bub_PT = ing.bubbler;  % If have bubbler data, use it
% If bubbler is NaN, use PT estimate
ing.pred_bub_PT(isnan(ing.pred_bub_PT)) = ing.temp_pred_bub_PT(isnan(ing.pred_bub_PT));

% Merge 2019-2020 and 2021 into final hybrid product
ing.hybrid = ing.pred_bub_L1;
ing.hybrid(58016:end) = ing.pred_bub_PT(58016:end);

%% Camera Detection
% Import camera data
cam = readtable('..\data\cam_stage.csv');

% % Remove blank winter rows so that all years are same increment of 4 
ing(52075,:) = [];
ing(52076,:) = [];
ing(52077,:) = [];

% Denormalize camera to bubbler datum (add bubbler mean)
% Arbitrarily align with PT during low/~0 flow day 9/2/21 09:00
cam.stage_filtered = cam.stage_filtered;%+234.48;
cam.z_normalized = cam.z_normalized*0.3046;%+234.48; % Camera stage = cam.z_normalized (unit conversion)

% Date to day of year
d = datevec(ing.Dates);
v = datenum(d);                
[Y, M, D, H, MN, S] = datevec(ing.Times);
ing.doy = v - datenum(d(:,1),1,0) + H/24+MN/24/60+S/24/60/60;  % day of year + fraction of day

% Merge camera and ing tables by date
cam_ing = outerjoin(ing,cam,'Keys',{'DateTime','DateTime'});
cam_ing.Properties.VariableNames(29) = {'DateTime'};
% Camera to WSE
% Don't have absolute elevation of camera stage datum, so match
% to PT low/no flow on 9/2/21 09:00 (PT = 314.806m, camera = 82.5106m -->
% 234.48m datum correction)
% cam_ing.z_normalized = cam_ing.z_normalized+234.48;

% Want to plot over gaps during the water year (because data only collected
% every 3 hours, rather than every 15 min)
% Pull date and camera columns
cam_nonan = cam_ing(:,["DateTime", "z"]);
cam_nonan((~isfinite(cam_nonan.z)),:)=[];
% Gaps during empty winter measurements to 3 hour increment constant
% between years
cam_nonan([415 944],2) = table(NaN); 

%% Error metrics
% R2
mld_L1 = fitlm(ing.bubbler,ing.L1_stage);
mld_L3 = fitlm(ing.bubbler,ing.L3_stage);
mld_pt = fitlm(cam_ing.bubbler,cam_ing.PT);
mld_cam = fitlm(cam_ing.bubbler,cam_ing.z);
mld_hybrid = fitlm(ing.bubbler,ing.hybrid);
% mld_linL3 = fitlm(ing.bubbler,ing.pred_bub_L3);
% mld_linL3r = fitlm(ing.bubbler,ing.pred_bub_L3r);
% mld_linL3r_no_outlier = fitlm(ing.bubbler,ing.pred_bub_L3r_no_outlier);

R2_L1 = mld_L1.Rsquared.Ordinary;
R2_L3 = mld_L3.Rsquared.Ordinary;
R2_pt = mld_pt.Rsquared.Ordinary;
R2_cam = mld_cam.Rsquared.Ordinary;
R2_hybrid = mld_hybrid.Rsquared.Ordinary;
% R2_linL3 = mld_linL3.Rsquared.Ordinary;
% R2_linL3r = mld_linL3r.Rsquared.Ordinary;
% R2_linL3r_no_outlier = mld_linL3r_no_outlier.Rsquared.Ordinary;
 
% RMSE
RMSE_L1 = mld_L1.RMSE;
RMSE_L3 = mld_L3.RMSE;
RMSE_pt = mld_pt.RMSE;
RMSE_cam = mld_cam.RMSE;
RMSE_hybrid = mld_hybrid.RMSE;

%% Remote Sensing Datasets
% Retime data to daily: take median, omit nan values
ing_daily = table2timetable(ing);
ing_daily = retime(ing_daily, 'daily', @(x) median(x,'omitnan'));

% Precipitation (NASA Giovanni)
rs_daily = readtable('..\data\daily_rs.csv');
% Join
ing_daily = outerjoin(ing_daily, rs_daily,'Keys',{'Dates','Dates'});

%% Plots of all records (stage, AWS, RS)
% Add Inglefield columns for statistics
% Net radiation = downward - upward radiation
ing_daily.INGIrrad_net = ing_daily.INGIrrad_SOLARUPDCP_raw-ing_daily.INGIrrad_SOLARDNDCP_raw;
% Calculate cumulative positive degree days
ing_daily.PDD = ing_daily.INGTemp_AIR1DCP_raw*0;
ing_daily.PDD(ing_daily.INGTemp_AIR1DCP_raw > 0) = 1;
ing_daily.PDDcum = cumsum(ing_daily.PDD, 'omitnan');
% Subtract previous years total PDDs to restart each year. Subtract
% previous year total if the date is after the start of the next year
ing_daily.PDDcum = ing_daily.PDDcum - ing_daily.PDDcum(find(ing_daily.Dates=='12/31/2019')).*(ing_daily.Dates > '12/31/2019');
ing_daily.PDDcum = ing_daily.PDDcum - ing_daily.PDDcum(find(ing_daily.Dates=='12/31/2020')).*(ing_daily.Dates > '12/31/2020');

% Calculate cumulative negative degree days
ing_daily.NDD = ing_daily.INGTemp_AIR1DCP_raw*0;
ing_daily.NDD(ing_daily.INGTemp_AIR1DCP_raw < 0) = 1;
ing_daily.NDDcum = cumsum(ing_daily.NDD, 'omitnan');
% Subtract previous years total PDDs to restart each year. Subtract
% previous year total if the date is after the start of the next year
ing_daily.NDDcum = ing_daily.NDDcum - ing_daily.NDDcum(find(ing_daily.Dates=='12/31/2019')).*(ing_daily.Dates > '12/31/2019');
ing_daily.NDDcum = ing_daily.NDDcum - ing_daily.NDDcum(find(ing_daily.Dates=='12/31/2020')).*(ing_daily.Dates > '12/31/2020');

% Export
writetimetable(ing_daily,'..\data\ing_daily.csv');

%%% Calculate missing data
% retime data to hourly: take median, omit nan values
cam_sum = table2timetable(cam_ing(:,[29 46 47 48 54 60 65]));
cam_hourly = retime(cam_sum, 'hourly', @(x) median(x,'omitnan'));
% retime data to daily: take median, omit nan values
cam_daily = retime(cam_sum, 'daily', @(x) median(x,'omitnan'));

% calculate AWS albedo: reflected radation/incoming radiation
aws_albedo = ing_daily.INGIrrad_SOLARDNDCP_raw./ing_daily.INGIrrad_SOLARUPDCP_raw;

%% FIGURE 8: Weather Data Plots
% Air Temp
figure (2)
plot(ing_daily.doy(2:1:177), ing_daily.INGTemp_AIR1DCP_raw(2:1:177),'-','color',[0 0.4470 0.7410],'LineWidth',2.0)
hold on
plot(ing_daily.doy(269:1:542), ing_daily.INGTemp_AIR1DCP_raw(269:1:542),'-','color',[0.8500 0.3250 0.0980],'LineWidth',2.0)
hold on 
plot(ing_daily.doy(581:1:end), ing_daily.INGTemp_AIR1DCP_raw(581:1:end),'-','color',[0.9290 0.6940 0.1250],'LineWidth',2.0)
xlim([160 275])
ylim([-20 15])
legend('2019','2020','2021')
xlabel('Day of Year')
ylabel('Daily Average Air Temperature (C)')
fontsize(gcf,scale=1.5)
hold off 
% Net radiation
figure (3)
plot(ing_daily.doy(2:1:177), ing_daily.INGIrrad_net(2:1:177),'-','color',[0 0.4470 0.7410],'LineWidth',2.0)
hold on
plot(ing_daily.doy(269:1:542), ing_daily.INGIrrad_net(269:1:542),'-','color',[0.8500 0.3250 0.0980],'LineWidth',2.0)
hold on 
plot(ing_daily.doy(581:1:end), ing_daily.INGIrrad_net(581:1:end),'-','color',[0.9290 0.6940 0.1250],'LineWidth',2.0)
xlim([167 275])
ylim([0 450])
legend('2019','2020','2021')
xlabel('Day of Year')
ylabel('Daily Average Net Radiation (W/m2)')
fontsize(gcf,scale=1.5)
hold off 
% Albedo
figure (4)
plot(ing_daily.doy(2:1:177), ing_daily.AIng_is(2:1:177),'-','color',[0 0.4470 0.7410],'LineWidth',2.0)
hold on
plot(ing_daily.doy(269:1:542), ing_daily.AIng_is(269:1:542),'-','color',[0.8500 0.3250 0.0980],'LineWidth',2.0)
hold on 
plot(ing_daily.doy(581:1:945), ing_daily.AIng_is(581:1:945),'-','color',[0.9290 0.6940 0.1250],'LineWidth',2.0)
xlim([160 275])
legend('2019','2020','2021','Location','southeast')
xlabel('Day of Year')
ylabel('Daily Average MODIS Albedo over the Ice Sheet')
fontsize(gcf,scale=1.5)
hold off 
% Precipitation
figure (5)
plot(ing_daily.doy(2:1:177), ing_daily.precip(2:1:177),'-','color',[0 0.4470 0.7410],'LineWidth',2.0)
hold on
plot(ing_daily.doy(269:1:542), ing_daily.precip(269:1:542),'-','color',[0.8500 0.3250 0.0980],'LineWidth',2.0)
hold on 
plot(ing_daily.doy(581:1:945), ing_daily.precip(581:1:945),'-','color',[0.9290 0.6940 0.1250],'LineWidth',2.0)
xlim([160 275])
%ylim([-20 15])
legend('2019','2020','2021','Location','northeast')
xlabel('Day of Year')
ylabel('Daily Average Remotely Sensed Precipitation (mm)')
fontsize(gcf,scale=1.5)
hold off 

% Irregular NaNs in hybrid dataset
hybrid.y = cam_ing.hybrid(isfinite(cam_ing.hybrid));
hybrid.x = cam_ing.DateTime(isfinite(cam_ing.hybrid));
% 2019: rows 1:5070
% 2020: rows 5071:11029. 5305 is first day in xlim (day >160)
% 2021: rows 11030:14293

%% FIGURE 5: Minturn WSE
% 2019: 3:4:16938  cam: 1:1:415
figure(6)
title('Inglefield Single Beam Lidar Stage')
plot(cam_nonan.DateTime(1:1:415), cam_nonan.z(1:1:415),'-','color',[0.8500 0.3250 0.0980],'LineWidth',1.1) 
hold on
plot(cam_ing.DateTime(3:4:16938),cam_ing.L1_stage(3:4:16938),'-','color',[0 0.4470 0.7410],'LineWidth',1.1)
hold on
plot(cam_ing.DateTime(3:4:16938),cam_ing.L3_stage(3:4:16938),'-','color',[0.9290 0.6940 0.1250],'LineWidth',1.1)
hold on
plot(hybrid.x(1:5070),hybrid.y(1:5070),'-','color',[0.4660 0.6740 0.1880],'LineWidth',1.1)
hold on 
plot(cam_ing.DateTime(isfinite(cam_ing.bubbler(3:1:16938))), cam_ing.bubbler(isfinite(cam_ing.bubbler(3:1:16938))),'-','color','k','LineWidth',1.1) % bubbler stage in m
legend('Camera','Lidar M1','Lidar M2','Hybrid Product','CF Bubbler','Location','southwest')
ylabel('2019 Minturn River WSE (m)')
ylim([310 320])
xlim([datetime('09-June-2019') datetime('17-September-2019')])
fontsize(gcf,scale=1.4)
hold off
% 2020: 16939:4:52074   cam: 416:1:944
figure(7)
title('Inglefield Single Beam Lidar Stage')
plot(cam_nonan.DateTime(416:1:944), cam_nonan.z(416:1:944),'-','color',[0.8500 0.3250 0.0980],'LineWidth',1.1) 
hold on
plot(cam_ing.DateTime(16939:4:52074),cam_ing.L1_stage(16939:4:52074),'-','color',[0 0.4470 0.7410],'LineWidth',1.1)
hold on
plot(cam_ing.DateTime(16939:4:52074),cam_ing.L3_stage(16939:4:52074),'-','color',[0.9290 0.6940 0.1250],'LineWidth',1.1)
hold on
plot(hybrid.x(5305:11029),hybrid.y(5305:11029),'-','color',[0.4660 0.6740 0.1880],'LineWidth',1.1)
hold on
plot(cam_ing.DateTime(16939:4:52074),cam_ing.bubbler(16939:4:52074),'-','color','k','LineWidth',1.2)  % bubbler stage in m
legend('Camera','Lidar M1','Lidar M2','Hybrid Product','CF Bubbler','Location','southwest')
ylabel('2020 Minturn River WSE (m)')
ylim([310 320])
xlim([datetime('09-June-2020') datetime('17-September-2020')])
fontsize(gcf,scale=1.4)
hold off
% 2021: 52075:4:end   cam: 946:1:end
figure(8)
title('Inglefield Single Beam Lidar Stage')
plot(cam_nonan.DateTime(946:1:end), cam_nonan.z(946:1:end),'-','color',[0.8500 0.3250 0.0980],'LineWidth',1.1) 
hold on
plot(cam_ing.DateTime(52075:4:end),cam_ing.L1_stage(52075:4:end),'-','color',[0 0.4470 0.7410],'LineWidth',1.1)
hold on
plot(cam_ing.DateTime(52075:4:end),cam_ing.L3_stage(52075:4:end),'-','color',[0.9290 0.6940 0.1250],'LineWidth',1.1)
hold on
plot(cam_ing.DateTime(isfinite(cam_ing.PT)),cam_ing.PT(isfinite(cam_ing.PT)),'-','color',[0.4940 0.1840 0.5560],'LineWidth',1.1)  % PT stage in m
hold on
plot(hybrid.x(11030:14293),hybrid.y(11030:14293),'-','color',[0.4660 0.6740 0.1880],'LineWidth',1.1)
hold on
plot(cam_ing.DateTime(52075:1:end),cam_ing.bubbler(52075:1:end),'-','color','k','LineWidth',1.2)  % bubbler stage in m
ylabel('2021 Minturn River WSE (m)')
ylim([310 320])
xlim([datetime('09-June-2021') datetime('17-September-2021')])
fontsize(gcf,scale=1.4)
legend('Camera','Lidar M1','Lidar M2','Level TROLL PT','Hybrid Product','CF Bubbler','Location','southwest')
hold off

%% Temperature and Albedo ANOVA
% Is there a significant difference between temperature and albedo over the
% ice sheet in each year?
temp = [ing_daily.INGTemp_AIR1DCP_raw(38:54), ing_daily.INGTemp_AIR1DCP_raw(403:419), ing_daily.INGTemp_AIR1DCP_raw(769:785)];
albedo = [ing_daily.AIng_is(38:54), ing_daily.AIng_is(403:419), ing_daily.AIng_is(769:785)];
stage = [ing_daily.hybrid(38:54), ing_daily.hybrid(403:419), ing_daily.hybrid(769:785)];

% Temp anova
[pt,tblt,statst] = anova1(temp);
multcompare(statst)
% Albedo anova
[pa,tbla,statsa] = anova1(albedo);
multcompare(statsa)
% Stage anova
[ps,tbls,statss] = anova1(stage);
multcompare(statss)

%% North River, Fox Canyon River
% Arbitrary datums: 100 for Fox SSL height, 250 for North River SSL height
north_ssl = readtable("..\data\north_ssl_2019_2020_2021.csv");
fox_ssl = readtable("..\data\fox_ssl_2019_2020_2021.csv");

% Add 2019-2021 PTs
north_pt = readtable("..\data\comped_pts2019-2020_sn2084756.csv");
north_pt2 = readtable("..\data\north_pt_transmitting_2020_2021.csv");
north = outerjoin(north_ssl,north_pt,'Keys',{'DateTime','DateTime'});
%north = outerjoin(north, north_pt2,'Keys',{'DateTime_north_ssl',north_pt2.Properties.VariableNames{2}});
north.LEVEL = north.LEVEL + 55.6575;     % convert PT level to wse using optical survey 

% Filter North River data
% Clip to realistic bounds (20 to 40m)
north.north_clip = north.Length;
idx = north.north_clip < 27.5;
idx2 = north.north_clip >= 38;
north.north_clip(idx) = NaN;
north.north_clip(idx2) = NaN;

% Correct anomalies in single beam record
for row = 7719:10247 % 2019
    if north{row, 11} < 27.5
        north{row, 11} = north{row, 11} + 9;  % Add 9 to lower offset
    elseif north{row, 11} < 31
        north{row, 11} = north{row, 11} + 6; % Add 6 to upper offset
    end
end
for row = 24054:24778 % 2020 offset 1
    if north{row, 11} < 28
        north{row, 11} = north{row, 11} + 9;  % Add 9 to lower offset
    elseif north{row, 11} < 32
        north{row, 11} = north{row, 11} + 6; % Add 6 to upper offset
    end
end
for row = 27874:30018 % 2020 offset 2
    if north{row, 11} < 27.5
        north{row, 11} = north{row, 11} + 9;  % Add 9 to lower offset
    elseif north{row, 11} < 30.3
        north{row, 11} = north{row, 11} + 6; % Add 6 to upper offset
    end
end
for row = 30482:32042 % 2020 offset 3
    if north{row, 11} < 27.5
        north{row, 11} = north{row, 11} + 9;  % Add 9 to lower offset
    elseif north{row, 11} < 30.3
        north{row, 11} = north{row, 11} + 6; % Add 6 to upper offset
    end
end
for row = 31486:31954 % 2020 offset 3 or 6      % Note: this is more precise correstion for large correction above
    if north{row, 11} < 31
        north{row, 11} = north{row, 11} + 6;  % Add 6 to lower offset
    elseif north{row, 11} < 34
        north{row, 11} = north{row, 11} + 3; % Add 3 to upper offset
    end
end
for row = 57125:58079 % 2021 offset 1
    if north{row, 11} < 28.1
        north{row, 11} = north{row, 11} + 9;  % Add 9 to lower offset
    elseif north{row, 11} < 31.5
        north{row, 11} = north{row, 11} + 6; % Add 6 to upper offset
    end
end
for row = 58729:59134 % 2021 offset 2
    if north{row, 11} < 28.1
        north{row, 11} = north{row, 11} + 9;  % Add 9 to lower offset
    elseif north{row, 11} < 31.5
        north{row, 11} = north{row, 11} + 6; % Add 6 to upper offset
    end
end

% Clip new pt to realistic bounds
north_pt2.north_pt2_clip = north_pt2.Value;
idx = north_pt2.north_pt2_clip < 0;
idx2 = north_pt2.north_pt2_clip >= 1.5;
north_pt2.north_pt2_clip(idx) = NaN;
north_pt2.north_pt2_clip(idx2) = NaN;
north_pt2.north_pt2_clip = north_pt2.north_pt2_clip + 55.658;     % convert PT level to wse

% Filter Fox River data
% Clip to realistic bounds (20m to 120m)
fox_ssl.fox_clip = fox_ssl.FilterStage;
idx = fox_ssl.fox_clip < 64.5;
idx2 = fox_ssl.fox_clip >= 73;
fox_ssl.fox_clip(idx) = NaN;
fox_ssl.fox_clip(idx2) = NaN;

% Convert dist to stage, then WSE
h_L4 = 62.279-0.5192;     % z of L4 eyes (ellipsoid height, m) in WSE datum from PT (arbitraril aligned at no flow condition 9/19/2019 05:00)
north.L4_air = north.north_clip.*sin(north.AvgAngle); % vertical height (m) from laserbox to water surface 
north.wse = h_L4 - north.L4_air;      % stage (m) = mount height - dist to water, convert to wse 
% No WSE survey from Fox: convert to stage only (arbitrary datum)
fox_ssl.Stage = 100-fox_ssl.fox_clip.*sind(fox_ssl.AvgAngle);

%Plot data
% Want to plot over gaps during the water year (because data only collected
% every 3 hours, rather than every 15 min)
% % North River single beam lidar
% Pull date and camera columns
nr_ssl_nonan = north(:,[2 13]);
nr_ssl_nonan((~isfinite(nr_ssl_nonan.wse)),:)=[];
% Add gaps for winter
nr_ssl_nonan([2186 4374],2) = table(NaN); 

% % North River downloaded PT
% Pull date and camera columns
nr_pt_nonan = north(:,[8 9]);
nr_pt_nonan((~isfinite(nr_pt_nonan.LEVEL)),:)=[];
% Add gaps for winter
nr_pt_nonan([7693 34093],2) = table(NaN); 

% % North River transmitting PT
% Pull date and camera columns
nr_pt2_nonan = north_pt2(:,[2 5]);
nr_pt2_nonan((~isfinite(nr_pt2_nonan.north_pt2_clip)),:)=[];
% Add gaps for winter
nr_pt2_nonan(2689,2) = table(NaN); 


%% FIGURE 6: North River WSE
%2019
figure(9)
plot(nr_ssl_nonan.DateTime_north_ssl(1:2186), nr_ssl_nonan.wse(1:2186), 'color',[0 0.4470 0.7410],'LineWidth',1.2)
ylabel('2019 North River WSE (m)')
hold on
plot(nr_pt_nonan.DateTime_north_pt(1:7692), nr_pt_nonan.LEVEL(1:7692),'color',[0.8500 0.3250 0.0980],'LineWidth',1.2)
legend('Lidar N1','Levelogger PT')
ylim([55.4 57.2])
xlim([datetime('01-June-2019') datetime('01-October-2019')])
fontsize(gcf,scale=1.5)
hold off
%2020
figure(10)
plot(nr_ssl_nonan.DateTime_north_ssl(2187:4375), nr_ssl_nonan.wse(2187:4375), 'color',[0 0.4470 0.7410],'LineWidth',1.2)
ylabel('2020 North River WSE (m)')
hold on
plot(nr_pt_nonan.DateTime_north_pt(7693:34092), nr_pt_nonan.LEVEL(7693:34092),'color',[0.8500 0.3250 0.0980],'LineWidth',1.2)
legend('Lidar N1','Levelogger PT')
ylim([55.4 57.2])
xlim([datetime('01-June-2020') datetime('01-October-2020')])
fontsize(gcf,scale=1.5)
hold off
%2021
figure(11)
plot(nr_ssl_nonan.DateTime_north_ssl(4376:end), nr_ssl_nonan.wse(4376:end),'color',[0 0.4470 0.7410],'LineWidth',1.2)
ylabel('2021 North River WSE (m)')
% hold on
% plot(nr_pt_nonan.DateTime_north_pt(34093:end), nr_pt_nonan.LEVEL(34093:end),'color',[0.8500 0.3250 0.0980])
hold on
plot(nr_pt2_nonan.DateTime(1:2688), nr_pt2_nonan.north_pt2_clip(1:2688),'color',[0.9290 0.6940 0.1250],'LineWidth',1.2)
legend('Lidar N1','Level TROLL PT')
ylim([55.4 57.2])
xlim([datetime('01-June-2021') datetime('01-October-2021')])
fontsize(gcf,scale=1.5)
hold off

%% FIGURE 7: Fox Canyon River stage
% 2019
figure(12)
plot(fox_ssl.DateTime(1:8736), fox_ssl.Stage(1:8736),'LineWidth',1.2)
ylabel('2019 Fox River Stage (m)')
legend('Lidar F1')
ylim([75.5 79])
xlim([datetime('01-June-2019') datetime('01-October-2019')])
fontsize(gcf,scale=1.5)
% 2020
figure(13)
plot(fox_ssl.DateTime(8737:17496), fox_ssl.Stage(8737:17496),'LineWidth',1.2)
ylabel('2020 Fox River Stage (m)')
legend('Lidar F1')
ylim([75.5 79])
xlim([datetime('01-June-2020') datetime('01-October-2020')])
fontsize(gcf,scale=1.5)
% 2021
figure(14)
plot(fox_ssl.DateTime(17497:end), fox_ssl.Stage(17497:end),'LineWidth',1.2)
ylabel('2021 Fox River Stage (m)')
legend('Lidar F1')
ylim([75.5 79])
xlim([datetime('01-June-2021') datetime('01-October-2021')])
fontsize(gcf,scale=1.5)

