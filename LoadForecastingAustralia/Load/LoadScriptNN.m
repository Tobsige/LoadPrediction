%% Electricity Load Forecasting
% This example demonstrates building and validating a short term
% electricity load forecasting model with MATLAB. The models take into
% account multiple sources of information including temperatures and
% holidays in constructing a day-ahead load forecaster. The models compared
% include Neural Networks and Regression Trees.

%% Import Weather & Load Data
% The data set used is a table of historical hourly loads and temperature
% observations from the New England ISO for the years 2004 to 2008. The
% weather information includes the dry bulb temperature and the dew point.
% This data set is imported from an Access database using the
% auto-generated function _fetchDBLoadData_.

data = fetchDBLoadData('2004-01-01', '2008-12-31');
addpath ..\Util


%% Import list of holidays
% A list of New England holidays that span the historical date range is
% imported from an Excel spreadsheet

[num, text] = xlsread('..\Data\Holidays.xls');
holidays = text(2:end,1);


%% Generate Predictor Matrix
% The function *genPredictors* generates the predictor variables used as
% inputs for the model. For short-term forecasting these include
% 
% * Dry bulb temperature
% * Dew point
% * Hour of day
% * Day of the week
% * A flag indicating if it is a holiday/weekend
% * Previous day's average load
% * Load from the same hour the previous day
% * Load from the same hour and same day from the previous week
%
% If the goal is medium-term or long-term load forecasting, only the inputs
% hour of day, day of week, time of year and holidays can be used
% deterministically. The weather/load information would need to be
% specified as an average or a distribution

% Select forecast horizon
term = 'short';

[X, dates, labels] = genPredictors(data, term, holidays);

%% Split the dataset to create a Training and Test set
% The dataset is divided into two sets, a _training_ set which includes 
% data from 2004 to 2007 and a _test_ set with data from 2008. The training
% set is used for building the model (estimating its parameters). The test
% set is used only for forecasting to test the performance of the model on 
% out-of-sample data. 

% Create training set
trainInd = data.NumDate < datenum('2008-01-01');
trainX = X(trainInd,:);
trainY = data.SYSLoad(trainInd);

% Create test set and save for later
testInd = data.NumDate >= datenum('2008-01-01');
testX = X(testInd,:);
testY = data.SYSLoad(testInd);
testDates = dates(testInd);

save Data\testSet testDates testX testY
clear X data trainInd testInd term holidays dates ans num text

%% Build the Load Forecasting Model
% The next few cells builds a Neural Network regression model for day-ahead
% load forecasting given the training data. This model is then used on the
% test data to validate its accuracy. 

%% Initialize and Train Network
% Initialize a default network of two layers with 20 neurons. Use the "mean
% absolute error" (MAE) performance metric. Then, train the network with
% the default Levenburg-Marquardt algorithm. For efficiency a pre-trained
% network is loaded unless a retrain is specifically enforced.

reTrain = false;
if reTrain || ~exist('Models\NNModel.mat', 'file')
    net = newfit(trainX', trainY', 20);
    net.performFcn = 'mae';
    net = train(net, trainX', trainY');
    save Models\NNModel.mat net
else
    load Models\NNModel.mat
end
    
%% Forecast using Neural Network Model
% Once the model is built, perform a forecast on the independent test set. 
cd('Data')
load testSet
cd ..
forecastLoad = sim(net, testX')';

%% Compare Forecast Load and Actual Load
% Create a plot to compare the actual load and the predicted load as well
% as compute the forecast error. In addition to the visualization, quantify
% the performance of the forecaster using metrics such as mean average
% error (MAE), mean average percent error (MAPE) and daily peak forecast
% error.

err = testY-forecastLoad;
fitPlot(testDates, [testY forecastLoad], err);

errpct = abs(err)./testY*100;

fL = reshape(forecastLoad, 24, length(forecastLoad)/24)';
tY = reshape(testY, 24, length(testY)/24)';
% fL = reshape(forecastLoad(1:end-1), 48, (length(forecastLoad)-1)/48)';
% tY = reshape(testY(1:end-1), 48, (length(testY)-1)/48)';
peakerrpct = abs(max(tY,[],2) - max(fL,[],2))./max(tY,[],2) * 100;

MAE = mean(abs(err));
MAPE = mean(errpct(~isinf(errpct)));

fprintf('Mean Average Percent Error (MAPE): %0.2f%% \nMean Average Error (MAE): %0.2f MWh\nDaily Peak MAPE: %0.2f%%\n',...
    MAPE, MAE, mean(peakerrpct))


%% Examine Distribution of Errors
% In addition to reporting scalar error metrics such as MAE and MAPE, the
% plot of the distribution of the error and absolute error can help build
% intuition around the performance of the forecaster

figure;
subplot(3,1,1); hist(err,100); title('Error distribution');
subplot(3,1,2); hist(abs(err),100); title('Absolute error distribution');
line([MAE MAE], ylim); legend('Errors', 'MAE');
subplot(3,1,3); hist(errpct,100); title('Absolute percent error distribution');
line([MAPE MAPE], ylim); legend('Errors', 'MAPE');

%% Generate Weekly Chart
% Create a comparison of forecast and actual load for every week in the
% test set.
generateCharts = true;
if generateCharts
    step = 168*2;
%     for i = 0:step:length(testDates)-step
        for i = 0
        clf;
        fitPlot(testDates(i+1:i+step), [testY(i+1:i+step) forecastLoad(i+1:i+step)], err(i+1:i+step));
        title(sprintf('MAPE: %0.2f%%', mean(errpct(i+1:i+step))));
        snapnow
        
    %-- 16/08/10  9:56 AM --%
    end
end
    