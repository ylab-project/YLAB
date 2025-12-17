function [nominal_brace, idnominal_brace] = countup_nominal_brace(com)
%COUNTUP_NOMINAL_BRACE 名目ブレースの束ね情報を作成
% 概要: 左下りと右下りのブレースペアを名目ブレースとして束ねる。
%       片側のみのブレースも単独の名目ブレースとして扱う。
% 構文: [nominal_brace, idnominal_brace] = countup_nominal_brace(com)
% 入力:
%   com - 共通データ構造体（member.braceテーブルを含む）
% 出力:
%   nominal_brace    - table型、名目ブレース情報
%                      変数: idmeb, idsub, coord_name, floor_name,
%                            frame_name, idstory, idir, idx, idy, type
%   idnominal_brace  - [nb×2] 配列、各ブレースの名目ブレース番号と
%                      サブ番号（[名目ブレース番号, サブ番号]）
% 備考: ブレースペア情報はPRM.BRACE_MEMBER_PAIR_*定数で判定
% See also: countup_nominal_property, countup_nominal_girder

% ブレースデータを取得
brace = com.member.brace;
nb = size(brace, 1);

% 配列の初期化
used = false(nb,1);      % 処理済みフラグ [nb×1]
idmeb = zeros(nb,2);     % ペア情報 [nb×2]（左ブレースID, 右ブレースID）
idsub = zeros(nb,2);     % サブブレース番号 [nb×2]（1 or 2）
idnominal_brace = zeros(nb,1);  % 各ブレースの名目ブレース番号 [nb×1]
idn = 0;                  % 名目ブレース数のカウンタ（スカラー）

% 全ブレースを走査して名目ブレースに集約
for ib=1:nb
  if used(ib)
    continue    % 既に処理済みの場合はスキップ
  end

  % 新規名目ブレースとして登録
  used(ib) = true;
  idn = idn+1;              % 名目ブレース番号をインクリメント
  idmeb(idn) = ib;          % 1番目のブレースとして登録
  idsub(idn,1) = 1;         % サブ番号1を設定
  idnominal_brace(ib) = idn;

  % ペアがある場合の処理
  switch brace.pair(ib)
    case {PRM.BRACE_MEMBER_PAIR_L, PRM.BRACE_MEMBER_PAIR_R}
      % 片側のみのブレース（ペアなし）
      continue
    case {PRM.BRACE_MEMBER_PAIR_BOTH_L, PRM.BRACE_MEMBER_PAIR_BOTH_R}
      % ペアのブレースも同じ名目ブレースに登録
      ib2 = brace.idpair(ib);
      used(ib2) = true;       % ペアも処理済みとしてマーク
      idmeb(idn,2)= ib2;      % 2番目のブレースとして登録
      idsub(idn,2) = 2;       % サブ番号2を設定（バグ修正：idn追加）
      idnominal_brace(ib2) = idn;
  end
end

% 名目ブレース数を確定し、配列をトリミング
nnb = idn;
idmeb = idmeb(1:nnb,:);
idsub = idsub(1:nnb,:);

% 名目ブレース属性配列の初期化
coord_name = cell(nnb,2);     % 座標名 {nnb×2} cell配列（開始座標, 終了座標）
floor_name = cell(nnb,1);     % 階名 {nnb×1} cell配列
frame_name = cell(nnb,1);     % フレーム名 {nnb×1} cell配列
idstory = zeros(nnb,1);       % 層番号 [nnb×1]
idir = zeros(nnb,1);          % 方向 [nnb×1]（1:X方向, 2:Y方向）
idx = zeros(nnb,2);           % X方向グリッド番号 [nnb×2]
idy = zeros(nnb,2);           % Y方向グリッド番号 [nnb×2]
type = zeros(nnb,1);          % ブレースタイプ [nnb×1]

% 各名目ブレースの属性を設定
for k = 1:nnb
  ib1 = idmeb(k,1);           % 1番目のブレース番号を取得
  ib2 = idmeb(k,2);           % 2番目のブレース番号を取得（ペアがない場合は0）

  % サブインデックスの設定
  idsub(k,1) = 1;
  if ib2>0
    idsub(k,2) = 2;           % ペアがある場合のみサブ番号2を設定
  end

  % 属性情報を1番目のブレースから取得
  % （ペアがある場合でも代表として1番目の属性を使用）
  coord_name(k,:) = brace.coord_name(ib1,:);
  floor_name{k,1} = brace.floor_name{ib1,1};
  frame_name{k,1} = brace.frame_name{ib1,1};
  idstory(k,1) = brace.idstory(ib1);
  idir(k,1) = brace.idir(ib1);
  idx(k,:) = brace.idx(ib1,:);
  idy(k,:) = brace.idy(ib1,:);
  type(k,1) = brace.type(ib1);
end

% 逆引きテーブルの作成 [nb×2]
% 各ブレースから名目ブレース番号とサブ番号を検索できるようにする
idnominal_brace = zeros(nb,2);
for inb = 1:nnb
  for j = 1:2
    ib = idmeb(inb,j);
    if ib>0
      % [名目ブレース番号, サブ番号]の形式で保存
      idnominal_brace(ib,:) = [inb j];
    end
  end
end

% 名目ブレーステーブルの作成
% 各名目ブレースの全属性を含むテーブルを構築
nominal_brace = table(...
  idmeb, idsub, coord_name, floor_name, frame_name, ...
  idstory, idir, idx, idy, type, ...
  'VariableNames', {...
  'idmeb','idsub','coord_name','floor_name','frame_name', ...
  'idstory','idir','idx','idy','type'});

return
end
