function gapjoint = countup_column_gapjoint(com)
%countup_column_gapjoint - 柱外径差制限のペアテーブル生成
%
%   gapjoint = countup_column_gapjoint(com) は、xy通りごとに柱を階順に
%   並べ、除外柱・RC柱を除いた残りの柱の隣接ペアを生成して、節点番号・
%   xy通り番号・変数番号の対応テーブルを返す。除外指定の柱やRC柱を
%   挟んだS柱同士も跨ぎ比較される。両方が固定変数のペアは対象外と
%   する（段差ペアは少なくとも一方が動かせること）。
%
%   入力引数:
%     com - 共通オブジェクト (struct)
%             member.column, section.column, node, exclusion を参照
%
%   出力引数:
%     gapjoint - 柱外径差ペアテーブル (table)
%                  idnode (n×1), idxy (n×2), idvar (n×2)

% 柱総数
nmec = com.nmec;

% 柱・節点の参照配列
idmec2var = com.member.column.idvar;
idmec2x   = com.member.column.idx(:,1);   % 柱は始終端で同じ
idmec2y   = com.member.column.idy(:,1);
idmec2z   = com.member.column.idz;        % [下端節点idz, 上端節点idz]
idmec2n1  = com.member.column.idnode1;
idn2xy    = [com.node.idx com.node.idy];
column_type = com.section.column.type(com.member.column.idsecc);
isv = com.design.variable.isvar;

% 除外柱のmask生成
idexclude = com.exclusion.column_diameter_gap.idme;
is_excluded = false(nmec,1);
is_excluded(idexclude) = true;

% xy通りごとに柱をグループ化
[~, ~, ig] = unique([idmec2x idmec2y], 'rows');
nxy = max(ig);

% 結果格納用を事前確保（最大ペア数はvalid柱数-1の総和、上限はnmec）
nmax = nmec;
result_idnode = zeros(nmax,1);
result_idvar  = zeros(nmax,2);
np = 0;

immm = (1:nmec)';
for ixy = 1:nxy
  % このxy通りの柱を階順に並べる（下端節点のz順）
  idcols = immm(ig==ixy);
  [~, iord] = sort(idmec2z(idcols,1));
  idcols = idcols(iord);

  % 除外柱・RC柱を落としてvalidな柱のみ残す
  valid = ~is_excluded(idcols) & column_type(idcols) ~= PRM.RCRS;
  idcols_valid = idcols(valid);

  % 残った柱の隣接ペアを生成
  for k = 1:length(idcols_valid)-1
    mc2 = idcols_valid(k);       % 下階柱
    mc1 = idcols_valid(k+1);     % 上階柱

    % 同じ変数のペア・両方固定のペアは除外
    % （段差ペアは少なくとも一方が動かせること）
    var1 = idmec2var(mc1,1);
    var2 = idmec2var(mc2,1);
    if var1 == var2 || (~isv(var1) && ~isv(var2))
      continue
    end

    % ペアを追加（節点はmc2の上端=mc1の下端）
    np = np + 1;
    result_idnode(np)   = idmec2n1(mc1);
    result_idvar(np, :) = [var1 var2];
  end
end
result_idnode = result_idnode(1:np);
result_idvar  = result_idvar(1:np, :);

% 結果が空の場合は空テーブルを返す
if isempty(result_idnode)
  idnode = zeros(0,1);
  idxy   = zeros(0,2);
  idvar  = zeros(0,2);
  gapjoint = table(idnode, idxy, idvar);
  return
end

% 重複を除去
[idvar, ia] = unique(result_idvar,'rows');
idnode = result_idnode(ia);
idxy   = idn2xy(idnode,:);
gapjoint = table(idnode, idxy, idvar);
gapjoint = sortrows(gapjoint,[2 3]);
return
end
