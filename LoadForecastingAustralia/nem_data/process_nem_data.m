function [dates,dates2, demand, rrp] = process_nem_data
cd('C:\Seminars\Load Forecasting\nem_data');
list = dir('*.csv');
list = {list.name};

for i = 1:length(list)
    fid = fopen(list{i});
    data{i} = textscan(fid,'%*s %q %f %f %*s','headerlines',1,'delimiter',',');
    fclose(fid);
end

dates =[];
demand = [];
rrp = [];
for i = 1:length(data)
    dates = [dates;data{i}{1}];
    demand = [demand;data{i}{2}];
    rrp = [rrp;data{i}{3}];
end
dates2 = datenum(dates,'yyyy/mm/dd HH:MM:SS');
cd('..')