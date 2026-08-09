function xini = extract_initial_design_value(com, options)
%extract_initial_design_value - 設計変数の初期値を抽出する
%
%   xini = extract_initial_design_value(com, options) は、入力CSVの
%   仮定断面を解析し、断面マネージャの設計変数形式へ変換する。
%
%   入力引数:
%     com     - 共通オブジェクト
%     options - 最適化オプション
%
%   出力引数:
%     xini - 設計変数の初期値ベクトル

% 共通定数
nsb = com.nsecb;          % ブレース断面グループ数

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
idsb2s = secb.idsec;                    % ブレース→断面マネージャID

if isempty(inisecc) || isempty(inisecg)
  xini = [];
  return
end

% 柱断面の初期値設定
% 入力テーブルの各行について、対応する柱断面グループを特定し寸法を設定
nc = size(inisecc,1);
for i=1:nc
  idsc = find_initial_section_id(secc, inisecc.full_name{i}, ...
    inisecc.idstory(i), '柱断面');
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
for i=1:ng
  idsg = find_initial_section_id(secg, inisecg.full_name{i}, ...
    inisecg.idstory(i), '梁断面');
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
% 入力テーブルの各行について、対応するブレース断面グループを特定し、
% 寸法を設定する。
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
      sss = textscan(inisecb.dimension{i}, '%s %f %f %f', ...
        'Delimiter', {'-', '(', ')'});
      ubb_type = PRM.get_id_ubb_type(sss{1});
      secdim(ids,1:4) = [ubb_type sss{2} sss{3} sss{4}];
    case {PRM.HSR, PRM.BHSR}
      % 円形鋼管: 記号-Dxt → [D, t] を抽出
      ch = inisecb.dimension{i};
      numstr = ch(find(ch == '-', 1)+1:end);
      sss = sscanf(numstr, '%fx%f');
      secdim(ids,1:2) = sss(1:2);
    case {PRM.HSS, PRM.BHSS}
      % 角形鋼管: 記号-DxDxtxr → [D, t] を抽出
      ch = inisecb.dimension{i};
      numstr = ch(find(ch == '-', 1)+1:end);
      sss = sscanf(numstr, '%fx%fx%fx%f');
      secdim(ids,1:2) = sss([1 3]);
    case {PRM.WFS, PRM.BWFS}
      % H形鋼: 記号-HxBxtwxtfxr → [H, B, tw, tf] を抽出
      ch = inisecb.dimension{i};
      numstr = ch(find(ch == '-', 1)+1:end);
      sss = sscanf(numstr, '%fx%fx%fx%fx%f');
      secdim(ids,1:4) = sss(1:4);
    case PRM.TB
      % 引張ブレース: 読み込み時に dimension 確定済み
  end
end

% 断面寸法を設計変数に変換
xini = com.secmgr.findNearestXvar(secdim, options);

return
end

function idsection = find_initial_section_id(section_table, full_name, ...
  idstory, section_kind)
%find_initial_section_id - 仮定断面に対応する断面行を取得する
%
%   idsection = find_initial_section_id(section_table, full_name, ...
%     idstory, section_kind) は、符号と階・層に対応する内部IDが
%   一致する行を返す。
%
%   入力引数:
%     section_table - full_nameとidstoryを持つ断面テーブル
%     full_name     - 仮定断面の符号
%     idstory       - 仮定断面の階・層に対応する内部ID
%     section_kind  - エラー表示用の断面種別
%
%   出力引数:
%     idsection - 対応する断面行番号

% (full_name, idstory)の一意性は断面表確定時に
% validate_section_identityが保証済みのため、未検出だけを検査する
is_match = strcmp(section_table.full_name, full_name) & ...
  section_table.idstory == idstory;
idsection = find(is_match, 1);
if isempty(idsection)
  error('YLAB:Input:InitialSectionNotFound', ...
    '%s%sが層番号%gに見つかりません', section_kind, ...
    full_name, idstory);
end

return
end
