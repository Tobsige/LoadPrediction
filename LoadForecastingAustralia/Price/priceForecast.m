function y = loadForecast(model, date, hour, temperature, isWorkingDay, histDate, histHour, histLoad)
% LOADFORECAST performs a day-ahead load forecast using a pre-trained
% Neural-Network or Bagged Regression Tree model
%
% USAGE:
% y = loadForecast(model, date, hour, temperature, isWorkingDay, ...
%                  histDate, histHour, histLoad)

% Process Historical loads
date = datenum(date);
histDate = datenum(histDate);
prevWeek = histLoad(histDate == date(1) - 7);
prevDay  = histLoad(histDate == date(1) - 1);
ave24 = filter(ones(24,1)/24, 1, histLoad);
prev24 = ave24(histDate == date(1) - 1);

% Create predictor matrix
% Drybulb, Dewpnt, Hour, Day, isWkDay, PrevWeek, PrevDay, Prev24
X = [temperature hour weekday(date) isWorkingDay*ones(size(date)) prevWeek prevDay prev24];

% Load model and perform prediction
switch lower(model(1))
    case 'n'
        s = load('Models\NNModel.mat');
        y = sim(s.net, X')';
    case 't'
        s = load('Models\TreeModel.mat');
        y = predict(s.model, X);
end

plot(hour, y); 
xlabel('Hour');
ylabel('Load (MW)');
grid on;
print -dmeta

%#function TreeBagger
%#function CompactTreeBagger
%#function network
%#function network\sim