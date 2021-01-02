function [dates3,airtemp2,wetbulb2,dewpnt2,humidity2] = process_temp_data

fid = fopen('HM01X_Data_066062_32826586401242.txt');
data = textscan(fid,'%*s %*s %*s %*s %s %s %*s %*s %f %*s %f %*s %f %*s %f %*s %*f %*s','headerlines',1,'delimiter',',');
fclose(fid);

dates = cellstr([cell2mat(data{1}),repmat(' ',length(data{1}),1),cell2mat(data{2})]);
airtemp = data{3};
wetbulb = data{4};
dewpnt = data{5};
humidity = data{6};


de = '01/01/2011 00:00';
i = find(strcmp(dates,de));
dates = dates(1:i);
airtemp = airtemp(1:i);
wetbulb = wetbulb(1:i);
dewpnt = dewpnt(1:i);
humidity = humidity(1:i);

dates2 = datenum(dates,'dd/mm/yyyy HH:MM');
dates3 = [dates2(1)+1/48:1/48:dates2(end)]';

atnan = find(isnan(airtemp));
dates2at = dates2;
dates2at(atnan) = [];
airtemp(atnan) = [];

wbnan = find(isnan(wetbulb));
wetbulb(wbnan) = [];
dates2wb = dates2;
dates2wb(wbnan) = [];

dpnan = find(isnan(dewpnt));
dewpnt(dpnan) = [];
dates2dp = dates2;
dates2dp(dpnan) = [];

humnan = find(isnan(humidity));
humidity(humnan) = [];
dates2hum = dates2;
dates2hum(humnan) = [];

airtemp2 = interp1(dates2at,airtemp,dates3,'linear');
wetbulb2 = interp1(dates2wb,wetbulb,dates3,'linear');
dewpnt2 = interp1(dates2dp,dewpnt,dates3,'linear');
humidity2 = interp1(dates2hum,humidity,dates3,'linear');




% temp = unique(dates2at);
% for i = 1:length(temp)
%     count(i) = sum(dates2at==temp(i));
% end
% r = find(count>1)