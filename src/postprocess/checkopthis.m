function checkopthis
w = load('..\data\20250312_S4\S4bySS7\opt\S4_output-15252.mat');
% Case C
% w = load('..\doc\20230825\S4Rv3_model-45125-A100.mat');
% Case D
% w = load('out\S4Rv2_case1_model-173592.mat');
% w = load ('out\S4_model-4607.mat');
% w = load ('out\KU2_model-8672.mat');
% w = load ('out\KU2_model-23992.mat');
% w = load ('out\KU2_model-29400.mat');
% w = load ('out\KU3_model-97376.mat'); % KU3モデル（通常階高）
% w = load ('out\KU3A_model-86044.mat'); % KU3Aモデル（1F階高+500）
% w = load ('out\KU3J_model-19212.mat'); % KU3Jモデル（JFE高張力鋼）
% w = load ('out\T1_model-19212.mat');
% w = load ('out\S4_model-16956.mat');
% w = load ('out\KU3D1_model-68556.mat'); % 層間変形角≦0.9/200=1/222
% w = load ('out\KU3D2_model-42960.mat'); % 層間変形角≦0.8/200=1/250
% w = load ('data_project\KA01A\KA01A_model-12912.mat');
% w = load ('data_project\KA01A\out\KA01A_model-126204.mat');
% w = load ('../data/20231223_naka/JSC_BS_MATLABuse-47769.mat');
% w = load ('data_project\KA01B\KA01B_model-7268.mat');
% w = load ('data_project\KA01A\KA01A2_model-69904.mat');
% w = load ('data_project\KA01A\KA01A3_model-69904.mat');
% w = load ('data_project\KG01\CaseA\KG01_model-67164.mat');
% w = load ('data\KG01\CaseB\KG01_model-67164.mat');
% w = load ('data_project\UN01\CaseA\UN01_model-62868.mat');
% w = load ('out\S4_cost_model-180724.mat');
% w = load ('data_project\KA01A\out\KA01A2_model-370064.mat'); %コスト最小10回
% w = load ('data_project\KA02\out\KA02_model-30008.mat'); %コスト最小
% w = load ('data_project\KA02\out\KA02_model-370064.mat'); %コスト最小10回
% w = load ('data_project\KA02\out\KA02_model-32032.mat'); %重量最小
% w = load ('..\data\20240128_miura\out\KA01A2A_model-370064.mat');
% w = load ('..\data\20240128_miura\out\KA01A2B_model-370064.mat');
% w = load ('data_project\KA03\out\KA03_model-221736.mat');
% w = load ('..\data_project\KG01\コスト最小－耐力比0.75－フェーズあり\KG01_model-39940.mat');
% w = load ('..\data_project\KG01\コスト最小－耐力比0.75－フェーズなし\out\KG01_model-32596.mat');
% set(0, 'defaultAxesFontName', 'Yu Gothic UI Semibold')
% set(0, 'defaultTextFontName', 'Yu Gothic UI Semibold');
set(0, 'defaultAxesFontName', 'Yu Gothic UI')
set(0, 'defaultTextFontName', 'Yu Gothic UI');
set(0, 'defaultAxesFontSize', 10);
set(0, 'defaultTextFontSize', 10);
% figure; 
ax = gcf().Children();
for i=1:length(ax)
  cla(ax(i));
end
checkopthis_(w)
% checkopthis_(w,true)
% checkopthis_(w1)
% checkopthis_(w2)
end

%--------------------------------------------------------------------------
function checkopthis_(w, sorting)
if nargin==1
  sorting = false;
end
o = w.opthis;
r = w.opthis_refined;
n = sum(+(r.fval~=0));
rfval = r.fval(1:n)+1.d6*r.maxvio(1:n);
[frmin, idmin] = min(rfval)
[min(o.fval(1:n)) min(r.fval(1:n))]
[mean(o.fval(1:n)) mean(r.fval(1:n))]
fprintf('%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\n',r.xopt(idmin,:));
fprintf('\n');

if sorting
  [fo, idfo] = sort(o.fval(1:n));
  [fr, idfr] = sort(r.fval(1:n));
  otime = sort(o.time(1:n),'descend')';
  rtime = sort((o.time(1:n)+r.time(1:n)),'descend')';
else
  [~, idfo] = sort(o.fval(1:n));
  [~, idfr] = sort(r.fval(1:n));
  fo = o.fval(1:n);
  fr = r.fval(1:n);
  otime = o.time(1:n);
  rtime = o.time(1:n)+r.time(1:n);
end

subplot(2,1,1)
% cla;
if sorting
  % plot(flip(fo),'-.')
  % hold all
  plot(flip(fr),'-')
else
  % plot(fo,'s')
  % hold all
  plot(fr,'.', MarkerSize=15)
end
grid on
% plot(o.fval(1:n),'.', MarkerSize=10)
% plot(r.fval(1:n),'.', MarkerSize=10)
hold off; 
% legend({"Refineなし","Refineあり"},'Location','best')
% legend({"Refineなし","Refineあり"},'Location','best')
% xlabel("解析ケース数"); ylabel("鋼材量 [ton]")
xlabel("解析ケース番号"); ylabel("コスト [千円]")
if (n<10)
  xticks(1:n)
else
  xticks('auto') 
end
% [mean(fo) mean(fr)]

subplot(2,1,2)
hold all
grid on
if sorting
  % plot(o.time(1:n),'.', MarkerSize=10)
  % plot(r.time(1:n),'.', MarkerSize=10)
  % plot(flipud(otime),'-.')
  plot(flipud(rtime),'-')
else
  % plot(otime,'s')
  plot(rtime,'.', MarkerSize=15)
end
hold off; 
% legend({"Refineなし","Refineあり"},'Location','best')
xlabel("解析ケース数"); ylabel("計算時間 [秒]")
if (n<10)
  xticks(1:n)
else
  xticks('auto') 
end

[~,toid] = max(otime); 
[~,trid] = max(otime+rtime); 
% [toid otime(toid) trid rtime(trid)]
[mean(otime(1:n)) mean(rtime(1:n)) sum(rtime(1:n))]

% パターン書き出し
% idx = [1:4 65:67];
% idx = [1:10];
% idx = 1:6;
% [H, id] = unique(r.xopt(idfr,idx),'rows','stable');
% id = idfr(id); id = id(:)';
% for i=id
%   fprintf('%6G\t', i, r.fval(i), r.xopt(i,idx))
%   fprintf('\n');
% end
return
end


