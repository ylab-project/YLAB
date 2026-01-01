function xini = extract_initial_design_value(com, options)
%extract_initial_design_value - 入力データから設計変数の初期値を抽出する
%
% 入力CSVで指定された初期断面寸法（柱・梁・ブレース）を解析し、
% 断面マネージャの設計変数形式に変換する。
%
% 入力:
%   com     - 共通オブジェクト
%   options - 最適化オプション
%
% 出力:
%   xini    - 設計変数の初期値ベクトル（断面が未定義の場合は空）

% 共通定数
nsc = com.nsecc;          % 柱断面グループ数
nsg = com.nsecg;          % 梁断面グループ数
nsb = com.nsecb;          % ブレース断面グループ数
nstory = com.nstory;      % 層数

% 共通配列
inisecg = com.section.initial.girder;   % 入力梁断面テーブル
inisecc = com.section.initial.column;   % 入力柱断面テーブル
inisecb = com.section.initial.brace;    % 入力ブレース断面テーブル
secg = com.section.girder;              % 梁断面グループ
secc = com.section.column;              % 柱断面グループ
secb = com.section.brace;               % ブレース断面グループ
secdim = com.secmgr.dimension;          % 断面寸法配列（出力用）
idsg2s = secg.idsec;                    % 梁グループ→断面マネージャID
idsc2s = secc.idsec;                    % 柱グループ→断面マネージャID
idsb2s = secb.idsec;                    % ブレースグループ→断面マネージャID

if isempty(inisecc) || isempty(inisecg)
  xini = [];
  return
end

% 柱断面の初期値設定
% 入力テーブルの各行について、対応する柱断面グループを特定し寸法を設定
nc = size(inisecc,1);
ininames = inisecc.full_name;
floor_names = inisecc.floor_name;
name = secc.full_name;
idstory = secc.idstory;
iddc = 1:nsc;
idds = 1:nstory;
for i=1:nc
  issc = matches(name, ininames{i});
  if sum(issc)>1
    % 該当断面が複数ある場合は層で判断
    idstory_ = idds(matches(com.story.floor_name, floor_names{i}));
    issc = issc&idstory==idstory_;
  end
  idsc = iddc(issc);
  ids = idsc2s(idsc);
  switch secc.type(idsc)
    case PRM.HSS
      % 角形鋼管: □-H×B×t1×t2 → [H, t1] を設計変数として抽出
      sss = sscanf(inisecc.dimension{i},'□-%fx%fx%fx%f');
      secdim(ids,1:2) = sss([1 3]);
  end
end

% 梁断面の初期値設定
% 入力テーブルの各行について、対応する梁断面グループを特定し寸法を設定
ng = size(inisecg,1);
ininames = inisecg.full_name;
story_names = inisecg.story_name;
name = secg.full_name;
idstory = secg.idstory;
iddg = 1:nsg;
idds = 1:nstory;
for i=1:ng
  issg = matches(name, ininames{i});
  if sum(issg)>1
    % 該当断面が複数ある場合は層で判断
    idstory_ = idds(matches(com.story.name, story_names{i}));
    issg = issg&idstory==idstory_;
  end
  idsg = iddg(issg);
  ids = idsg2s(idsg);
  switch secg.type(idsg)
    case PRM.WFS
      % H形鋼: SYMBOL-H×B×tw×tf(×tf2) → [H, B, tw, tf] を抽出
      % 任意のプレフィックス（H-, SH-, HY-, BH- 等）に対応
      ch = inisecg.dimension{i};
      tokens = regexp(ch, '^[A-Za-z]+-(.+)$', 'tokens');
      if isempty(tokens)
        throw_err('Input', 'InvalidSectionFormat', ch);
      end
      sss = sscanf(tokens{1}{1}, '%fx%fx%fx%fx%f');
      if numel(sss) < 4
        throw_err('Input', 'InvalidSectionDimension', ch);
      end
      secdim(ids,1:4) = sss(1:4);
  end
end

% ブレース断面の初期値設定
% 入力テーブルの各行について、対応するブレース断面グループを特定し寸法を設定
nb = size(inisecb,1);
ininames = inisecb.name;
name = secb.name;
iddb = 1:nsb;
for i=1:nb
  idsb = iddb(matches(name, ininames{i}));
  ids = idsb2s(idsb);
  switch secb.type(idsb)
    case PRM.BRB
      % 座屈拘束ブレース: TYPE-Aw(Ap/Aw) → [type, Aw, Ap, Aw] を抽出
      sss = textscan(inisecb.dimension{i}, ...
        '%s %f %f %f','Delimiter',{'-','(',')'});
      ubb_type = PRM.get_id_ubb_type(sss{1});
      secdim(ids,1:4) = [ubb_type sss{2} sss{3} sss{4}];
    case PRM.HSR
      % 円形鋼管: ○-D×t → [D, t] を抽出
      ch = inisecb.dimension{i};
      if contains(ch, '○-')
        sss = sscanf(ch, '○-%fx%f');
        secdim(ids,1:2) = sss(1:2);
      else
        % 数値x数値の形式を抽出（フォールバック）
        sss = regexp(ch, '([0-9.]+)x([0-9.]+)', 'tokens');
        if ~isempty(sss)
          secdim(ids,1) = str2double(sss{1}{1});
          secdim(ids,2) = str2double(sss{1}{2});
        end
      end
  end
end

% 断面寸法を設計変数に変換
xini = com.secmgr.findNearestXvar(secdim, options);

return
end

